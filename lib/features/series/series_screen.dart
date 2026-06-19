import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/models/jellyfin_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/external_player.dart';
import '../../core/services/platform_utils.dart';
import '../../core/providers/watchlist_providers.dart';
import '../../core/storage/watchlist_storage.dart';
import '../../shared/widgets/cast_section.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final _seriesDetailProvider = FutureProvider.family<JellyItem, String>((ref, id) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) throw Exception('Aucun serveur');
  return ref.read(jellyfinClientProvider).getItem(server.userId, id);
});

final _seasonsProvider = FutureProvider.family<List<JellyItem>, String>((ref, seriesId) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  return ref.read(jellyfinClientProvider).getSeasons(server.userId, seriesId);
});

final _episodesProvider = FutureProvider.family<List<JellyItem>, String>((ref, seasonId) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  return ref.read(jellyfinClientProvider).getEpisodes(server.userId, seasonId);
});

final _introTimestampsProvider =
    FutureProvider.family<(double, double)?, String>((ref, episodeId) async {
  return ref.read(jellyfinClientProvider).getIntroTimestamps(episodeId);
});

final _nextEpisodeProvider = FutureProvider.family<JellyItem?, String>((ref, seriesId) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return null;
  return ref.read(jellyfinClientProvider).getNextUp(server.userId, seriesId: seriesId);
});

// ─── SeriesScreen ─────────────────────────────────────────────────────────────

class SeriesScreen extends ConsumerWidget {
  final String seriesId;

  const SeriesScreen({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(_seriesDetailProvider(seriesId));
    final seasons = ref.watch(_seasonsProvider(seriesId));

    return series.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Erreur : $err'))),
      data: (item) => seasons.when(
        loading: () => _SeriesShell(item: item, child: const Center(child: CircularProgressIndicator())),
        error: (err, _) => _SeriesShell(item: item, child: Center(child: Text('Erreur saisons : $err'))),
        data: (seasonList) => seasonList.isEmpty
            ? _SeriesShell(item: item, child: const Center(child: Text('Aucune saison')))
            : _SeriesWithTabs(item: item, seasons: seasonList),
      ),
    );
  }
}

// ─── Shell (backdrop + header) ────────────────────────────────────────────────

class _SeriesShell extends StatelessWidget {
  final JellyItem item;
  final Widget child;

  const _SeriesShell({required this.item, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _SeriesHeader(item: item),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Vue avec onglets ────────────────────────────────────────────────────────

class _SeriesWithTabs extends ConsumerWidget {
  final JellyItem item;
  final List<JellyItem> seasons;

  const _SeriesWithTabs({required this.item, required this.seasons});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: seasons.length,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _SeriesHeader(item: item, seasonCount: seasons.length)),
            if (item.people.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: CastSection(
                    people: item.people,
                    client: ref.read(jellyfinClientProvider),
                  ),
                ),
              ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: const Color(0xFF888888),
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: seasons
                      .map((s) => Tab(
                            text: s.indexNumber != null
                                ? 'Saison ${s.indexNumber}'
                                : s.name,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: seasons.map((s) => _EpisodeList(season: s)).toList(),
          ),
        ),
      ),
    );
  }
}

// ─── Header série ─────────────────────────────────────────────────────────────

class _SeriesHeader extends ConsumerWidget {
  final JellyItem item;
  final int? seasonCount;

  const _SeriesHeader({required this.item, this.seasonCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(jellyfinClientProvider);
    final backdropUrl =
        client.getImageUrl(itemId: item.id, type: 'Backdrop', maxWidth: 1280);
    final posterUrl = client.getImageUrl(itemId: item.id);
    final topInset = MediaQuery.of(context).padding.top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── En-tête : grande image hero + affiche/infos en bas ─────
        LayoutBuilder(
          builder: (context, c) {
            final heroH = (c.maxWidth * 9 / 16).clamp(300.0, 460.0);
            return SizedBox(
              height: heroH,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: backdropUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorWidget: (_, __, ___) =>
                        Container(color: const Color(0xFF1A1A1A)),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x00000000),
                          Color(0x99000000),
                          Color(0xF20D0D0D),
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 150,
                              child: AspectRatio(
                                aspectRatio: 2 / 3,
                                child: CachedNetworkImage(
                                  imageUrl: posterUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                      color: const Color(0xFF1A1A1A)),
                                  errorWidget: (_, __, ___) => Container(
                                    color: const Color(0xFF1A1A1A),
                                    child: const Icon(Icons.tv_outlined,
                                        color: Color(0xFF555555), size: 40),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        shadows: const [
                                          Shadow(
                                              color: Colors.black87,
                                              blurRadius: 8),
                                        ],
                                      ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    if (item.productionYear != null)
                                      _Badge('${item.productionYear}'),
                                    if (seasonCount != null)
                                      _Badge(
                                          '$seasonCount saison${seasonCount! > 1 ? 's' : ''}'),
                                    if (item.communityRating != null)
                                      _Badge(
                                          '★ ${item.communityRating!.toStringAsFixed(1)}',
                                          color: const Color(0xFFFFB800)),
                                    if (item.officialRating != null)
                                      _Badge(item.officialRating!),
                                    if ((item.userData?.unplayedItemCount ??
                                            0) >
                                        0)
                                      _Badge(
                                        '${item.userData!.unplayedItemCount} non vu${item.userData!.unplayedItemCount! > 1 ? 's' : ''}',
                                        color: const Color(0xFFE50914),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: topInset + 4,
                    left: 0,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                    ),
                  ),
                  Positioned(
                    top: topInset + 4,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.home_outlined,
                          color: Colors.white),
                      tooltip: 'Accueil',
                      onPressed: () => context.go('/home'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // ─── Contenu sous l'en-tête ───────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bouton Lire prochain épisode (style Netflix)
              _NextEpisodeButtonLarge(seriesId: item.id),
              const SizedBox(height: 8),

              // Actions secondaires
              Row(
                children: [
                  _SeriesWatchlistButton(item: item),
                  _SeriesSeenButton(item: item),
                  _SeriesFavoriteButton(item: item),
                  if (item.providerIds['Imdb'] != null)
                    GestureDetector(
                      onTap: () async {
                        final imdbId = item.providerIds['Imdb']!;
                        final url = 'https://www.imdb.com/title/$imdbId';
                        await openUrl(url);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF666666)),
                        ),
                        child: const Text('IMDb',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white54, size: 20),
                    tooltip: 'Rafraîchir métadonnées',
                    onPressed: () async {
                      try {
                        await ref
                            .read(jellyfinClientProvider)
                            .refreshItem(item.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rafraîchissement lancé'),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF1A1A1A),
                            ),
                          );
                        }
                      } catch (_) {}
                    },
                  ),
                ],
              ),

              // Synopsis
              if (item.overview != null && item.overview!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.overview!,
                  style: const TextStyle(
                      color: Color(0xFFAAAAAA), fontSize: 15, height: 1.6),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Liste épisodes d'une saison ──────────────────────────────────────────────

class _EpisodeList extends ConsumerWidget {
  final JellyItem season;

  const _EpisodeList({required this.season});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodes = ref.watch(_episodesProvider(season.id));

    return episodes.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur : $err')),
      data: (list) => list.isEmpty
          ? const Center(child: Text('Aucun épisode'))
          : Column(
              children: [
                // Bouton lire toute la saison
                _PlaySeasonButton(season: season, episodes: list),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _EpisodeCard(episode: list[i], seasonId: season.id),
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Bouton lecture saison entière ────────────────────────────────────────────

class _PlaySeasonButton extends ConsumerWidget {
  final JellyItem season;
  final List<JellyItem> episodes;

  const _PlaySeasonButton({required this.season, required this.episodes});

  Future<void> _playSeason(BuildContext context, WidgetRef ref) async {
    await _playEpisodes(context, ref, episodes);
  }

  Future<void> _playSelection(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<List<JellyItem>>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EpisodeSelectionSheet(season: season, episodes: episodes),
    );
    if (selected == null || selected.isEmpty || !context.mounted) return;
    await _playEpisodes(context, ref, selected);
  }

  Future<void> _playEpisodes(BuildContext context, WidgetRef ref, List<JellyItem> eps) async {
    if (eps.isEmpty) return;

    // Pistes du premier épisode comme référence pour la playlist
    final firstEp = eps.first;
    final audioStreams =
        (firstEp.mediaStreams ?? []).where((s) => s.type == 'Audio').toList();
    final subStreams =
        (firstEp.mediaStreams ?? []).where((s) => s.type == 'Subtitle').toList();

    final client = ref.read(jellyfinClientProvider);
    final server = ref.read(activeServerProvider);
    if (server == null) return;

    // Sélection audio/sous-titres avant lancement
    int? audioPos;
    int subPos = -1;
    if (audioStreams.isNotEmpty || subStreams.isNotEmpty) {
      if (!context.mounted) return;
      final result = await showModalBottomSheet<(int?, int)>(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _SeasonTrackSheet(
          audioStreams: audioStreams,
          subStreams: subStreams,
          userId: server.userId,
        ),
      );
      if (result == null || !context.mounted) return;
      (audioPos, subPos) = result;
    }
    final player = await getExternalPlayer();

    try {
      final m3u = StringBuffer('#EXTM3U\n');
      for (final ep in eps) {
        final label = ep.indexNumber != null
            ? 'E${ep.indexNumber.toString().padLeft(2, '0')} — ${ep.name}'
            : ep.name;
        final url = client.getStreamUrl(itemId: ep.id, userId: server.userId);
        m3u.writeln('#EXTINF:-1,$label');
        m3u.writeln(url);
      }
      final tmpDir = await getTemporaryDirectory();
      final playlist = File('${tmpDir.path}/jellyclient_season.m3u');
      playlist.writeAsStringSync(m3u.toString());

      final env = Map<String, String>.from(Platform.environment);
      if (!Platform.isWindows && !env.containsKey('DISPLAY')) env['DISPLAY'] = ':0';

      final name = player.replaceAll('\\', '/').split('/').last.toLowerCase();
      final List<String> args;
      if (name.contains('vlc')) {
        args = [
          playlist.path,
          '--fullscreen',
          if (audioPos != null) '--audio-track=$audioPos',
          if (subPos >= 0) '--sub-track=$subPos' else '--sub-track=-1',
        ];
      } else if (name.contains('mpv')) {
        args = [
          playlist.path,
          '--fs',
          '--hwdec=no',
          if (audioPos != null) '--aid=${audioPos + 1}',
          if (subPos >= 0) '--sid=${subPos + 1}' else '--no-sub',
        ];
      } else {
        args = [playlist.path];
      }
      await Process.start(player, args, environment: env, mode: ProcessStartMode.detached);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red[900]),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonLabel = season.indexNumber != null ? 'Saison ${season.indexNumber}' : 'la saison';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          // Bouton principal — lire toute la saison (style Netflix)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _playSeason(context, ref),
              icon: const Icon(Icons.playlist_play_rounded, size: 22),
              label: Text(
                'Lire $seasonLabel (${episodes.length} ép.)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton sélection épisodes (style secondaire assorti)
          ElevatedButton(
            onPressed: () => _playSelection(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A2A2A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              minimumSize: Size.zero,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.checklist_rounded, size: 18),
                SizedBox(width: 6),
                Text('Choisir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sheet sélection pistes (saison entière / sélection) ─────────────────────

class _SeasonTrackSheet extends StatefulWidget {
  final List<MediaStream> audioStreams;
  final List<MediaStream> subStreams;
  final String userId;

  const _SeasonTrackSheet({
    required this.audioStreams,
    required this.subStreams,
    required this.userId,
  });

  @override
  State<_SeasonTrackSheet> createState() => _SeasonTrackSheetState();
}

class _SeasonTrackSheetState extends State<_SeasonTrackSheet> {
  late int? _audioPos;
  late int _subPos;

  @override
  void initState() {
    super.initState();
    final defIdx = widget.audioStreams.indexWhere((s) => s.isDefault == true);
    _audioPos = widget.audioStreams.isEmpty ? null : (defIdx >= 0 ? defIdx : 0);
    _subPos = -1;
    _applyPreferences();
  }

  Future<void> _applyPreferences() async {
    final audioLang = await getPreferredAudioLang(widget.userId);
    final subLang = await getPreferredSubLang(widget.userId);
    if (!mounted) return;
    setState(() {
      if (audioLang != null) {
        final idx = widget.audioStreams.indexWhere(
            (s) => matchesLang(s.language, audioLang));
        if (idx >= 0) _audioPos = idx;
      }
      if (subLang != null) {
        final idx = widget.subStreams.indexWhere(
            (s) => matchesLang(s.language, subLang));
        _subPos = idx >= 0 ? idx : -1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: const Color(0xFF444444),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Audio & Sous-titres',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Appliqué à tous les épisodes de la playlist',
              style: TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
            if (widget.audioStreams.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Piste audio',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: widget.audioStreams.asMap().entries.map((e) {
                  final label = e.value.displayTitle ??
                      e.value.language ??
                      'Piste ${e.key}';
                  final sel = _audioPos == e.key;
                  return ChoiceChip(
                    label: Text(label),
                    selected: sel,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: const Color(0xFF2A2A2A),
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : const Color(0xFFCCCCCC),
                        fontSize: 12),
                    side: BorderSide.none,
                    onSelected: (_) => setState(() => _audioPos = e.key),
                  );
                }).toList(),
              ),
            ],
            if (widget.subStreams.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Sous-titres',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Aucun'),
                    selected: _subPos == -1,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: const Color(0xFF2A2A2A),
                    labelStyle: TextStyle(
                        color: _subPos == -1
                            ? Colors.white
                            : const Color(0xFFCCCCCC),
                        fontSize: 12),
                    side: BorderSide.none,
                    onSelected: (_) => setState(() => _subPos = -1),
                  ),
                  ...widget.subStreams.asMap().entries.map((e) {
                    final label = e.value.displayTitle ??
                        e.value.language ??
                        'Sub ${e.key}';
                    final sel = _subPos == e.key;
                    return ChoiceChip(
                      label: Text(label),
                      selected: sel,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      backgroundColor: const Color(0xFF2A2A2A),
                      labelStyle: TextStyle(
                          color: sel ? Colors.white : const Color(0xFFCCCCCC),
                          fontSize: 12),
                      side: BorderSide.none,
                      onSelected: (_) => setState(() => _subPos = e.key),
                    );
                  }),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop((_audioPos, _subPos)),
                icon: const Icon(Icons.play_arrow_rounded, size: 22),
                label: const Text('Lire',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sheet sélection épisodes ─────────────────────────────────────────────────

class _EpisodeSelectionSheet extends StatefulWidget {
  final JellyItem season;
  final List<JellyItem> episodes;

  const _EpisodeSelectionSheet({required this.season, required this.episodes});

  @override
  State<_EpisodeSelectionSheet> createState() => _EpisodeSelectionSheetState();
}

class _EpisodeSelectionSheetState extends State<_EpisodeSelectionSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    // Par défaut : tous les épisodes non vus sont cochés
    _selected = widget.episodes
        .where((e) => e.userData?.played != true)
        .map((e) => e.id)
        .toSet();
    // Si tout est vu, tout cocher quand même
    if (_selected.isEmpty) _selected = widget.episodes.map((e) => e.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final seasonLabel = widget.season.indexNumber != null
        ? 'Saison ${widget.season.indexNumber}'
        : 'Saison';
    final selectedEpisodes =
        widget.episodes.where((e) => _selected.contains(e.id)).toList();

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF444444),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Choisir les épisodes — $seasonLabel',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  // Tout / Rien
                  TextButton(
                    onPressed: () => setState(() {
                      if (_selected.length == widget.episodes.length) {
                        _selected = {};
                      } else {
                        _selected = widget.episodes.map((e) => e.id).toSet();
                      }
                    }),
                    child: Text(
                      _selected.length == widget.episodes.length ? 'Aucun' : 'Tous',
                      style: const TextStyle(color: Color(0xFFE50914)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2A2A2A), height: 1),
            // Liste épisodes avec cases
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: widget.episodes.length,
                itemBuilder: (_, i) {
                  final ep = widget.episodes[i];
                  final sel = _selected.contains(ep.id);
                  final progress = ep.userData?.playedPercentage;
                  final played = ep.userData?.played ?? false;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: Checkbox(
                      value: sel,
                      activeColor: const Color(0xFFE50914),
                      side: const BorderSide(color: Color(0xFF666666)),
                      onChanged: (_) => setState(() {
                        if (sel) _selected.remove(ep.id); else _selected.add(ep.id);
                      }),
                    ),
                    title: Text(
                      ep.indexNumber != null
                          ? 'E${ep.indexNumber.toString().padLeft(2, '0')} — ${ep.name}'
                          : ep.name,
                      style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFF888888),
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    trailing: played
                        ? const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16)
                        : progress != null && progress > 0
                            ? Text('${progress.toInt()}%',
                                style: const TextStyle(color: Color(0xFFE50914), fontSize: 12))
                            : null,
                    onTap: () => setState(() {
                      if (sel) _selected.remove(ep.id); else _selected.add(ep.id);
                    }),
                  );
                },
              ),
            ),
            // Bouton lire sélection
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: selectedEpisodes.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(selectedEpisodes),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    selectedEpisodes.isEmpty
                        ? 'Aucun épisode sélectionné'
                        : 'Lire ${selectedEpisodes.length} épisode${selectedEpisodes.length > 1 ? 's' : ''}',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Carte épisode ────────────────────────────────────────────────────────────

class _EpisodeCard extends ConsumerWidget {
  final JellyItem episode;
  final String seasonId;

  const _EpisodeCard({required this.episode, required this.seasonId});

  String _duration(int? ticks) {
    if (ticks == null) return '';
    final m = ticks ~/ 600000000;
    return '${m}min';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(jellyfinClientProvider);
    final server = ref.read(activeServerProvider);
    final thumbUrl = client.getImageUrl(itemId: episode.id, type: 'Primary', maxWidth: 400);
    final progress = episode.userData?.playedPercentage;
    final played = episode.userData?.played ?? false;

    return InkWell(
      onTap: () async {
        if (server == null) return;
        await showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1A1A1A),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => _EpisodePlaySheet(
            episode: episode,
            client: client,
            server: server,
            seasonId: seasonId,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniature 16:9
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: thumbUrl,
                    width: 160,
                    height: 90,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 160,
                      height: 90,
                      color: const Color(0xFF1A1A1A),
                      child: const Icon(Icons.tv_outlined, color: Color(0xFF555555), size: 32),
                    ),
                  ),
                ),
                // Barre de progression
                if (progress != null && progress > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.only(bottomLeft: Radius.circular(6), bottomRight: Radius.circular(6)),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                        minHeight: 3,
                      ),
                    ),
                  ),
                // Badge vu
                if (played)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          color: Colors.black54, borderRadius: BorderRadius.circular(3)),
                      child: const Icon(Icons.check, color: Colors.white70, size: 10),
                    ),
                  ),
                // Icône play au centre
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.black45, borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (episode.indexNumber != null)
                    Text(
                      'Épisode ${episode.indexNumber}',
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    episode.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (episode.runTimeTicks != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _duration(episode.runTimeTicks),
                      style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
                    ),
                  ],
                  if (episode.overview != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      episode.overview!,
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Bouton marquer vu/non vu
            _MarkPlayedButton(episode: episode, seasonId: seasonId),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _formatTimestamp(double seconds) {
  final m = seconds ~/ 60;
  final s = (seconds % 60).toInt();
  return '$m:${s.toString().padLeft(2, '0')}';
}

// ─── Boutons Lire / Passer l'intro (épisode) ─────────────────────────────────

class _EpisodePlayButtons extends ConsumerWidget {
  final JellyItem episode;
  final dynamic client;
  final dynamic server;
  final int? audioPos;
  final int subPos;

  const _EpisodePlayButtons({
    required this.episode,
    required this.client,
    required this.server,
    required this.audioPos,
    required this.subPos,
  });

  Future<void> _launch(BuildContext context, int startTicks) async {
    final capturedClient = client;
    final capturedServer = server;
    final capturedEpisodeId = episode.id;
    final capturedRuntime = episode.runTimeTicks;

    if (!context.mounted) return;
    Navigator.of(context).pop();
    try {
      final url = capturedClient.getStreamUrl(
        itemId: capturedEpisodeId,
        userId: capturedServer.userId,
      );
      await launchWithExternalPlayer(
        url: url,
        title: '${episode.seriesName ?? ""} — ${episode.name}',
        startTicks: startTicks,
        audioTrackPos: audioPos,
        subtitleTrackPos: subPos,
        onStopped: (estimatedTicks) async {
          await capturedClient.reportPlaybackStop(
            itemId: capturedEpisodeId,
            positionTicks: estimatedTicks,
          );
          if (capturedRuntime != null &&
              estimatedTicks >= capturedRuntime * 0.9) {
            await capturedClient.markPlayed(
                capturedServer.userId, capturedEpisodeId);
          }
        },
      );
    } catch (e) {
      // Sheet déjà fermée — pas de ScaffoldMessenger disponible
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final introAsync = ref.watch(_introTimestampsProvider(episode.id));
    final resumeTicks = episode.userData?.playbackPositionTicks ?? 0;
    final introEnd = introAsync.whenOrNull(data: (v) => v?.$2);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _launch(context, resumeTicks),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(resumeTicks > 0 ? 'Reprendre' : 'Lire'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
        ),
        if (introEnd != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _launch(context, (introEnd * 10000000).toInt()),
              icon: const Icon(Icons.fast_forward_rounded, size: 18),
              label:
                  Text('Passer l\'intro (→ ${_formatTimestamp(introEnd)})'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Color(0xFF444444)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Bottom sheet sélection pistes épisode ────────────────────────────────────

class _EpisodePlaySheet extends ConsumerStatefulWidget {
  final JellyItem episode;
  final dynamic client;
  final dynamic server;
  final String seasonId;

  const _EpisodePlaySheet({
    required this.episode,
    required this.client,
    required this.server,
    required this.seasonId,
  });

  @override
  ConsumerState<_EpisodePlaySheet> createState() => _EpisodePlaySheetState();
}

class _EpisodePlaySheetState extends ConsumerState<_EpisodePlaySheet> {
  late int? _audioPos;
  late int _subPos;

  List<MediaStream> get _audioStreams =>
      (widget.episode.mediaStreams ?? []).where((s) => s.type == 'Audio').toList();
  List<MediaStream> get _subStreams =>
      (widget.episode.mediaStreams ?? []).where((s) => s.type == 'Subtitle').toList();

  @override
  void initState() {
    super.initState();
    final audio = _audioStreams;
    final defIdx = audio.indexWhere((s) => s.isDefault == true);
    _audioPos = audio.isEmpty ? null : (defIdx >= 0 ? defIdx : 0);
    _subPos = -1;
    _applyPreferences();
  }

  Future<void> _applyPreferences() async {
    final userId = (widget.server?.userId as String?) ?? '';
    if (userId.isEmpty) return;
    final audioLang = await getPreferredAudioLang(userId);
    final subLang = await getPreferredSubLang(userId);
    if (!mounted) return;
    setState(() {
      if (audioLang != null) {
        final idx = _audioStreams.indexWhere(
            (s) => matchesLang(s.language, audioLang));
        if (idx >= 0) _audioPos = idx;
      }
      if (subLang != null) {
        final idx = _subStreams.indexWhere(
            (s) => matchesLang(s.language, subLang));
        _subPos = idx >= 0 ? idx : -1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre épisode
          Text(
            widget.episode.name,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (widget.episode.indexNumber != null)
            Text(
              'Épisode ${widget.episode.indexNumber}',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
          const SizedBox(height: 16),

          // Piste audio
          if (_audioStreams.isNotEmpty) ...[
            const Text('Piste audio',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _audioStreams.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final label = s.displayTitle ?? s.language ?? 'Piste $i';
                final sel = _audioPos == i;
                return ChoiceChip(
                  label: Text(label),
                  selected: sel,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: const Color(0xFF2A2A2A),
                  labelStyle: TextStyle(color: sel ? Colors.white : const Color(0xFFCCCCCC), fontSize: 12),
                  side: BorderSide.none,
                  onSelected: (_) => setState(() => _audioPos = i),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Sous-titres
          if (_subStreams.isNotEmpty) ...[
            const Text('Sous-titres',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('Aucun'),
                  selected: _subPos == -1,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: const Color(0xFF2A2A2A),
                  labelStyle: TextStyle(color: _subPos == -1 ? Colors.white : const Color(0xFFCCCCCC), fontSize: 12),
                  side: BorderSide.none,
                  onSelected: (_) => setState(() => _subPos = -1),
                ),
                ..._subStreams.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  final label = s.displayTitle ?? s.language ?? 'Sub $i';
                  final sel = _subPos == i;
                  return ChoiceChip(
                    label: Text(label),
                    selected: sel,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: const Color(0xFF2A2A2A),
                    labelStyle: TextStyle(color: sel ? Colors.white : const Color(0xFFCCCCCC), fontSize: 12),
                    side: BorderSide.none,
                    onSelected: (_) => setState(() => _subPos = i),
                  );
                }),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Bouton Lire
          _EpisodePlayButtons(
            episode: widget.episode,
            client: widget.client,
            server: widget.server,
            audioPos: _audioPos,
            subPos: _subPos,
          ),
          const SizedBox(height: 8),
          // Bouton marquer vu / non vu
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                final server = ref.read(activeServerProvider);
                if (server == null) return;
                final client = ref.read(jellyfinClientProvider);
                final played = widget.episode.userData?.played ?? false;
                try {
                  if (played) {
                    await client.markUnplayed(server.userId, widget.episode.id);
                  } else {
                    await client.markPlayed(server.userId, widget.episode.id);
                  }
                  ref.invalidate(_episodesProvider(widget.seasonId));
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red[900]),
                    );
                  }
                }
              },
              icon: Icon(
                (widget.episode.userData?.played ?? false)
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              label: Text(
                (widget.episode.userData?.played ?? false)
                    ? 'Marquer comme non vu'
                    : 'Marquer comme vu',
              ),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Boutons watchlist / déjà vu série ────────────────────────────────────────

class _SeriesWatchlistButton extends ConsumerWidget {
  final JellyItem item;
  const _SeriesWatchlistButton({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wl = ref.watch(watchlistProvider);
    final inList = wl.any((i) => i.id == item.id);
    return IconButton(
      icon: Icon(
        inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        color: inList ? const Color(0xFFE50914) : Colors.white70,
        size: 22,
      ),
      tooltip: inList ? 'Retirer de ma liste' : 'Ajouter à ma liste',
      onPressed: () => toggleWatchlist(
        ref,
        WatchlistItem(id: item.id, name: item.name, type: 'Series', addedAt: DateTime.now()),
      ),
    );
  }
}

class _SeriesSeenButton extends ConsumerWidget {
  final JellyItem item;
  const _SeriesSeenButton({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(seenProvider);
    final isSeen = seen.any((i) => i.id == item.id);
    return IconButton(
      icon: Icon(
        isSeen ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
        color: isSeen ? const Color(0xFF4CAF50) : Colors.white70,
        size: 22,
      ),
      tooltip: isSeen ? 'Retirer des vus' : 'Marquer comme vu',
      onPressed: () => toggleSeen(
        ref,
        WatchlistItem(id: item.id, name: item.name, type: 'Series', addedAt: DateTime.now()),
      ),
    );
  }
}

// ─── Prochain épisode — bouton large style Netflix ────────────────────────────

class _NextEpisodeButtonLarge extends ConsumerWidget {
  final String seriesId;
  const _NextEpisodeButtonLarge({required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(_nextEpisodeProvider(seriesId));
    return next.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (ep) {
        if (ep == null) return const SizedBox.shrink();
        final s = ep.parentIndexNumber?.toString().padLeft(2, '0') ?? '?';
        final e = ep.indexNumber?.toString().padLeft(2, '0') ?? '?';
        final server = ref.read(activeServerProvider);
        final client = ref.read(jellyfinClientProvider);
        final hasProgress = (ep.userData?.playbackPositionTicks ?? 0) > 0;
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              if (server == null) return;
              final capturedClient = client;
              final capturedServer = server;
              final capturedEpId = ep.id;
              final capturedRuntime = ep.runTimeTicks;
              final audioLang = await getPreferredAudioLang(server.userId);
              final subLang = await getPreferredSubLang(server.userId);
              final url =
                  client.getStreamUrl(itemId: ep.id, userId: server.userId);
              await launchWithExternalPlayer(
                url: url,
                title: '${ep.seriesName ?? ''} — ${ep.name}',
                startTicks: ep.userData?.playbackPositionTicks ?? 0,
                audioLang: audioLang,
                subLang: subLang,
                onStopped: (estimatedTicks) async {
                  await capturedClient.reportPlaybackStop(
                    itemId: capturedEpId,
                    positionTicks: estimatedTicks,
                  );
                  if (capturedRuntime != null &&
                      estimatedTicks >= capturedRuntime * 0.9) {
                    await capturedClient.markPlayed(
                        capturedServer.userId, capturedEpId);
                  }
                },
              );
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: Text(
              hasProgress
                  ? 'Reprendre S${s}E$e'
                  : 'Lire S${s}E$e — ${ep.name}',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
          ),
        );
      },
    );
  }
}

// ─── Prochain épisode — bandeau compact ───────────────────────────────────────

class _NextEpisodeButton extends ConsumerWidget {
  final String seriesId;
  const _NextEpisodeButton({required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(_nextEpisodeProvider(seriesId));
    return next.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (ep) {
        if (ep == null) return const SizedBox.shrink();
        final s = ep.parentIndexNumber?.toString().padLeft(2, '0') ?? '?';
        final e = ep.indexNumber?.toString().padLeft(2, '0') ?? '?';
        final server = ref.read(activeServerProvider);
        final client = ref.read(jellyfinClientProvider);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () async {
              if (server == null) return;
              final capturedClient = client;
              final capturedServer = server;
              final capturedEpId = ep.id;
              final capturedRuntime = ep.runTimeTicks;
              final audioLang = await getPreferredAudioLang(server.userId);
              final subLang = await getPreferredSubLang(server.userId);
              final url = client.getStreamUrl(itemId: ep.id, userId: server.userId);
              await launchWithExternalPlayer(
                url: url,
                title: '${ep.seriesName ?? ''} — ${ep.name}',
                startTicks: ep.userData?.playbackPositionTicks ?? 0,
                audioLang: audioLang,
                subLang: subLang,
                onStopped: (estimatedTicks) async {
                  await capturedClient.reportPlaybackStop(
                    itemId: capturedEpId,
                    positionTicks: estimatedTicks,
                  );
                  if (capturedRuntime != null &&
                      estimatedTicks >= capturedRuntime * 0.9) {
                    await capturedClient.markPlayed(
                        capturedServer.userId, capturedEpId);
                  }
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE50914).withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_outline_rounded,
                      color: Color(0xFFE50914), size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'S${s}E$e — ${ep.name}',
                      style: const TextStyle(
                          color: Color(0xFFE50914), fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Favori Jellyfin (série) ──────────────────────────────────────────────────

class _SeriesFavoriteButton extends ConsumerWidget {
  final JellyItem item;
  const _SeriesFavoriteButton({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = item.userData?.isFavorite ?? false;
    return IconButton(
      icon: Icon(
        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFav ? const Color(0xFFE50914) : Colors.white70,
        size: 22,
      ),
      tooltip: isFav ? 'Retirer des favoris Jellyfin' : 'Ajouter aux favoris Jellyfin',
      onPressed: () async {
        final server = ref.read(activeServerProvider);
        if (server == null) return;
        try {
          await ref.read(jellyfinClientProvider).toggleFavorite(
            userId: server.userId,
            itemId: item.id,
            favorite: !isFav,
          );
          ref.invalidate(_seriesDetailProvider(item.id));
        } catch (_) {}
      },
    );
  }
}

class _MarkPlayedButton extends ConsumerWidget {
  final JellyItem episode;
  final String seasonId;

  const _MarkPlayedButton({required this.episode, required this.seasonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final played = episode.userData?.played ?? false;
    final server = ref.read(activeServerProvider);

    return IconButton(
      icon: Icon(
        played ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
        color: played ? const Color(0xFF4CAF50) : const Color(0xFF444444),
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      tooltip: played ? 'Marquer comme non vu' : 'Marquer comme vu',
      onPressed: server == null
          ? null
          : () async {
              final client = ref.read(jellyfinClientProvider);
              try {
                if (played) {
                  await client.markUnplayed(server.userId, episode.id);
                } else {
                  await client.markPlayed(server.userId, episode.id);
                }
                ref.invalidate(_episodesProvider(seasonId));
              } catch (_) {}
            },
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? color;
  const _Badge(this.label, {this.color});

  @override
  Widget build(BuildContext context) => Container(
        // Style aligné sur _Chip (fiche film) : même padding/taille/poids.
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(
                color: color ?? const Color(0xFFCCCCCC),
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      );
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: const Color(0xFF0D0D0D), child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
