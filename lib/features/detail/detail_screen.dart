import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:palette_generator/palette_generator.dart';
import '../../shared/widgets/cast_section.dart';
import '../../shared/widgets/media_card.dart';
import '../../core/providers/watchlist_providers.dart';
import '../../core/storage/watchlist_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/models/jellyfin_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/external_player.dart';
import '../../core/services/platform_utils.dart';

final _itemDetailProvider = FutureProvider.family<JellyItem, String>((ref, id) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) throw Exception('Aucun serveur actif');
  return ref.read(jellyfinClientProvider).getItem(server.userId, id);
});

final _paletteProvider = FutureProvider.family<Color?, String>((ref, imageUrl) async {
  try {
    final generator = await PaletteGenerator.fromImageProvider(
      NetworkImage(imageUrl),
      maximumColorCount: 8,
    );
    return generator.dominantColor?.color ??
        generator.vibrantColor?.color ??
        generator.mutedColor?.color;
  } catch (_) {
    return null;
  }
});

final _moreLikeThisProvider =
    FutureProvider.family<List<JellyItem>, (String, String)>((ref, args) async {
  final (itemId, genre) = args;
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  final resp = await ref.read(jellyfinClientProvider).getItems(
    userId: server.userId,
    genres: genre,
    sortBy: 'Random',
    recursive: true,
    limit: 12,
    fields: 'Overview,UserData',
  );
  return resp.items.where((i) => i.id != itemId).take(10).toList();
});

class DetailScreen extends ConsumerWidget {
  final String itemId;

  const DetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(_itemDetailProvider(itemId));
    final client = ref.read(jellyfinClientProvider);

    return Scaffold(
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (item) => _DetailContent(item: item, client: client),
      ),
    );
  }
}

class _DetailContent extends HookConsumerWidget {
  final JellyItem item;
  final dynamic client;

  const _DetailContent({required this.item, required this.client});

  List<MediaStream> _streams(String type) =>
      item.mediaStreams?.where((s) => s.type == type).toList() ?? [];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioStreams = _streams('Audio');
    final subStreams = _streams('Subtitle');

    final backdropUrl = client.getImageUrl(itemId: item.id, type: 'Backdrop', maxWidth: 1280);
    final posterUrl = client.getImageUrl(itemId: item.id);
    final palette = ref.watch(_paletteProvider(posterUrl));
    final accentColor = palette.whenOrNull(data: (c) => c);
    final headerBg = accentColor != null
        ? HSLColor.fromColor(accentColor)
            .withLightness(0.12)
            .withSaturation(0.6)
            .toColor()
        : const Color(0xFF0D0D0D);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: headerBg,
          leading: BackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined, color: Colors.white),
              tooltip: 'Accueil',
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: _PosterHeader(
            item: item,
            backdropUrl: backdropUrl,
            posterUrl: posterUrl,
            fallbackColor: headerBg,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Bouton Lire (style Netflix) ──────────────────────
                // ─── Bouton Lire → sheet sélection pistes ─────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final server = ref.read(activeServerProvider);
                      if (server == null) return;
                      final hasProgress =
                          (item.userData?.playbackPositionTicks ?? 0) > 0;

                      int? audioPos;
                      int subPos = -1;

                      if (audioStreams.isNotEmpty || subStreams.isNotEmpty) {
                        if (!context.mounted) return;
                        final result =
                            await showModalBottomSheet<(int?, int)>(
                          context: context,
                          backgroundColor: const Color(0xFF1A1A1A),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(16)),
                          ),
                          builder: (_) => _FilmPlaySheet(
                            audioStreams: audioStreams,
                            subStreams: subStreams,
                            hasProgress: hasProgress,
                            userId: server.userId,
                          ),
                        );
                        if (result == null || !context.mounted) return;
                        (audioPos, subPos) = result;
                      }

                      try {
                        final url = client.getStreamUrl(
                            itemId: item.id, userId: server.userId);
                        final capturedClient = client;
                        final capturedItemId = item.id;
                        final capturedRuntime = item.runTimeTicks;
                        final capturedUserId = server.userId;
                        int? relAudio;
                        if (audioPos != null) relAudio = audioPos;
                        await launchWithExternalPlayer(
                          url: url,
                          title: item.name,
                          startTicks:
                              item.userData?.playbackPositionTicks ?? 0,
                          audioTrackPos: relAudio,
                          subtitleTrackPos: subPos,
                          onStopped: (estimatedTicks) async {
                            await capturedClient.reportPlaybackStop(
                              itemId: capturedItemId,
                              positionTicks: estimatedTicks,
                            );
                            if (capturedRuntime != null &&
                                estimatedTicks >= capturedRuntime * 0.9) {
                              await capturedClient.markPlayed(
                                  capturedUserId, capturedItemId);
                            }
                          },
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Erreur : $e'),
                            backgroundColor: Colors.red[900],
                          ));
                        }
                      }
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 24),
                    label: Text(
                      (item.userData?.playbackPositionTicks ?? 0) > 0
                          ? 'Reprendre'
                          : 'Lire',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),

                // ─── Actions secondaires ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _WatchlistButton(item: item),
                    _SeenButton(item: item),
                    _FavoriteButton(item: item),
                    if (item.providerIds['Imdb'] != null)
                      GestureDetector(
                        onTap: () async {
                          final imdbId = item.providerIds['Imdb']!;
                          final url = 'https://www.imdb.com/title/$imdbId';
                          await openUrl(url);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      color: const Color(0xFF666666),
                      tooltip: 'Rafraîchir métadonnées',
                      onPressed: () async {
                        try {
                          await client.refreshItem(item.id);
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

                // ─── Synopsis ─────────────────────────────────────────
                if (item.overview != null && item.overview!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(item.overview!,
                      style: const TextStyle(
                          color: Color(0xFFCCCCCC), fontSize: 17, height: 1.65)),
                ],

                // ─── Casting & Équipe ─────────────────────────────────
                if (item.people.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  CastSection(people: item.people, client: client),
                ],

                // ─── More Like This ───────────────────────────────────
                if (item.genres?.isNotEmpty == true) ...[
                  const SizedBox(height: 20),
                  _MoreLikeThis(item: item),
                ],

                // Autres provider IDs (TMDb, TVDb) en bas si présents
                if (item.providerIds.entries.any((e) => e.key != 'Imdb' && e.value.isNotEmpty)) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: item.providerIds.entries
                        .where((e) => e.key != 'Imdb' && e.value.isNotEmpty)
                        .map((e) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF444444)),
                              ),
                              child: Text(
                                '${e.key}  ${e.value}',
                                style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends ConsumerWidget {
  final JellyItem item;
  final dynamic client;
  final int? audioIndex;
  final int? subtitleIndex;
  final bool transparent;

  const _PlayButton({
    required this.item,
    required this.client,
    this.audioIndex,
    this.subtitleIndex,
    this.transparent = false,
  });

  // Convertit l'index Jellyfin absolu en position relative par type de piste (0-based)
  int? _relativePos(List<MediaStream> streams, String type, int? jellyfinIndex) {
    if (jellyfinIndex == null) return null;
    final list = streams.where((s) => s.type == type).toList();
    final pos = list.indexWhere((s) => s.index == jellyfinIndex);
    return pos >= 0 ? pos : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final server = ref.read(activeServerProvider);
    if (server == null) return const SizedBox.shrink();

    final resumeTicks = item.userData?.playbackPositionTicks;
    final hasProgress = resumeTicks != null && resumeTicks > 0;
    final streams = item.mediaStreams ?? [];

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            final url = client.getStreamUrl(itemId: item.id, userId: server.userId);
            final audioPos = _relativePos(streams, 'Audio', audioIndex);
            final subPos = subtitleIndex == null
                ? -1
                : (_relativePos(streams, 'Subtitle', subtitleIndex) ?? -1);
            await launchWithExternalPlayer(
              url: url,
              title: item.name,
              startTicks: resumeTicks ?? 0,
              audioTrackPos: audioPos,
              subtitleTrackPos: subPos,
            );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur lecture : $e'),
                  backgroundColor: Colors.red[900],
                  duration: const Duration(seconds: 6),
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.play_arrow_rounded, size: 24),
        label: Text(
          hasProgress ? 'Reprendre' : 'Lire',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

// ─── Bandeau Audio / Sous-titres ─────────────────────────────────────────────

class _AudioSubBadge extends StatelessWidget {
  final List<MediaStream> audioStreams;
  final List<MediaStream> subStreams;
  final ValueNotifier<int?> selectedAudio;
  final ValueNotifier<int?> selectedSub;

  const _AudioSubBadge({
    required this.audioStreams,
    required this.subStreams,
    required this.selectedAudio,
    required this.selectedSub,
  });

  String _audioLabel() {
    if (audioStreams.isEmpty) return '—';
    final s = audioStreams.firstWhere(
      (s) => s.index == selectedAudio.value,
      orElse: () => audioStreams.first,
    );
    return s.displayTitle ?? s.language ?? 'Piste';
  }

  String _subLabel() {
    if (selectedSub.value == -1) return 'Aucun';
    if (subStreams.isEmpty) return 'Aucun';
    final s = subStreams.firstWhere(
      (s) => s.index == selectedSub.value,
      orElse: () => subStreams.first,
    );
    return s.displayTitle ?? s.language ?? 'Sub';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1A1A1A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _AudioSubSheet(
          audioStreams: audioStreams,
          subStreams: subStreams,
          selectedAudio: selectedAudio,
          selectedSub: selectedSub,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, color: Color(0xFF888888), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: selectedAudio,
                builder: (_, __, ___) => ValueListenableBuilder(
                  valueListenable: selectedSub,
                  builder: (_, __, ___) => Text(
                    '${_audioLabel()}  •  CC ${_subLabel()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFF555555), size: 20),
          ],
        ),
      ),
    );
  }
}

class _AudioSubSheet extends StatelessWidget {
  final List<MediaStream> audioStreams;
  final List<MediaStream> subStreams;
  final ValueNotifier<int?> selectedAudio;
  final ValueNotifier<int?> selectedSub;

  const _AudioSubSheet({
    required this.audioStreams,
    required this.subStreams,
    required this.selectedAudio,
    required this.selectedSub,
  });

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
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF444444),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Audio & Sous-titres',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            if (audioStreams.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Piste audio',
                  style:
                      TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const SizedBox(height: 10),
              ValueListenableBuilder(
                valueListenable: selectedAudio,
                builder: (context, val, _) => Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: audioStreams.map((s) {
                    final label =
                        s.displayTitle ?? s.language ?? 'Piste ${s.index}';
                    final sel = val == s.index;
                    return ChoiceChip(
                      label: Text(label),
                      selected: sel,
                      selectedColor:
                          Theme.of(context).colorScheme.primary,
                      backgroundColor: const Color(0xFF2A2A2A),
                      labelStyle: TextStyle(
                        color: sel
                            ? Colors.white
                            : const Color(0xFFCCCCCC),
                        fontSize: 12,
                      ),
                      side: BorderSide.none,
                      onSelected: (_) => selectedAudio.value = s.index,
                    );
                  }).toList(),
                ),
              ),
            ],
            if (subStreams.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Sous-titres',
                  style:
                      TextStyle(color: Color(0xFF888888), fontSize: 12)),
              const SizedBox(height: 10),
              ValueListenableBuilder(
                valueListenable: selectedSub,
                builder: (context, val, _) => Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('Aucun'),
                      selected: val == -1,
                      selectedColor:
                          Theme.of(context).colorScheme.primary,
                      backgroundColor: const Color(0xFF2A2A2A),
                      labelStyle: TextStyle(
                        color: val == -1
                            ? Colors.white
                            : const Color(0xFFCCCCCC),
                        fontSize: 12,
                      ),
                      side: BorderSide.none,
                      onSelected: (_) => selectedSub.value = -1,
                    ),
                    ...subStreams.map((s) {
                      final label =
                          s.displayTitle ?? s.language ?? 'Sub ${s.index}';
                      final sel = val == s.index;
                      return ChoiceChip(
                        label: Text(label),
                        selected: sel,
                        selectedColor:
                            Theme.of(context).colorScheme.primary,
                        backgroundColor: const Color(0xFF2A2A2A),
                        labelStyle: TextStyle(
                          color: sel
                              ? Colors.white
                              : const Color(0xFFCCCCCC),
                          fontSize: 12,
                        ),
                        side: BorderSide.none,
                        onSelected: (_) => selectedSub.value = s.index,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Sheet sélection pistes (film) ───────────────────────────────────────────

class _FilmPlaySheet extends StatefulWidget {
  final List<MediaStream> audioStreams;
  final List<MediaStream> subStreams;
  final bool hasProgress;
  final String userId;

  const _FilmPlaySheet({
    required this.audioStreams,
    required this.subStreams,
    required this.hasProgress,
    required this.userId,
  });

  @override
  State<_FilmPlaySheet> createState() => _FilmPlaySheetState();
}

class _FilmPlaySheetState extends State<_FilmPlaySheet> {
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
            if (widget.audioStreams.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Piste audio',
                  style:
                      TextStyle(color: Color(0xFF888888), fontSize: 12)),
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
                  style:
                      TextStyle(color: Color(0xFF888888), fontSize: 12)),
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
                          color: sel
                              ? Colors.white
                              : const Color(0xFFCCCCCC),
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
                label: Text(
                  widget.hasProgress ? 'Reprendre' : 'Lire',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
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

// ─── Favori Jellyfin ─────────────────────────────────────────────────────────

class _FavoriteButton extends ConsumerWidget {
  final JellyItem item;
  const _FavoriteButton({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = item.userData?.isFavorite ?? false;
    return IconButton(
      icon: Icon(
        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFav ? const Color(0xFFE50914) : Colors.white70,
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
          ref.invalidate(_itemDetailProvider(item.id));
        } catch (_) {}
      },
    );
  }
}

// ─── More Like This ───────────────────────────────────────────────────────────

class _MoreLikeThis extends ConsumerWidget {
  final JellyItem item;
  const _MoreLikeThis({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genre = item.genres!.first;
    final similar = ref.watch(_moreLikeThisProvider((item.id, genre)));

    return similar.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final client = ref.read(jellyfinClientProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dans le même genre', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final it = items[i];
                  return SizedBox(
                    width: 133,
                    child: MediaCard(
                      item: it,
                      imageUrl: client.getImageUrl(itemId: it.id),
                      onTap: () => navigateToItem(context, it),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Boutons watchlist / déjà vu ──────────────────────────────────────────────

class _WatchlistButton extends ConsumerWidget {
  final JellyItem item;
  const _WatchlistButton({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wl = ref.watch(watchlistProvider);
    final inList = wl.any((i) => i.id == item.id);
    return IconButton(
      icon: Icon(
        inList ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        color: inList ? const Color(0xFFE50914) : Colors.white70,
      ),
      tooltip: inList ? 'Retirer de ma liste' : 'Ajouter à ma liste',
      onPressed: () async {
        await toggleWatchlist(
          ref,
          WatchlistItem(
            id: item.id,
            name: item.name,
            type: item.type ?? 'Movie',
            addedAt: DateTime.now(),
          ),
        );
      },
    );
  }
}

class _SeenButton extends ConsumerWidget {
  final JellyItem item;
  const _SeenButton({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(seenProvider);
    final isSeen = seen.any((i) => i.id == item.id);
    return IconButton(
      icon: Icon(
        isSeen ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
        color: isSeen ? const Color(0xFF4CAF50) : Colors.white70,
      ),
      tooltip: isSeen ? 'Retirer des vus' : 'Marquer comme vu',
      onPressed: () async {
        await toggleSeen(
          ref,
          WatchlistItem(
            id: item.id,
            name: item.name,
            type: item.type ?? 'Movie',
            addedAt: DateTime.now(),
          ),
        );
      },
    );
  }
}

String _formatRuntime(int? ticks) {
  if (ticks == null) return '';
  final minutes = ticks ~/ 600000000;
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h > 0 ? '${h}h ${m}min' : '${m}min';
}

/// En-tête de fiche détail : affiche (poster portrait complète) + infos
/// (titre, métadonnées, genres) posées sur le backdrop flouté et assombri.
class _PosterHeader extends StatelessWidget {
  final JellyItem item;
  final String backdropUrl;
  final String posterUrl;
  final Color fallbackColor;

  const _PosterHeader({
    required this.item,
    required this.backdropUrl,
    required this.posterUrl,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    const posterW = 150.0;
    return LayoutBuilder(
      builder: (context, c) {
        // Grande image hero au ratio 16:9, plafonnée pour ne pas remplir l'écran.
        final heroH = (c.maxWidth * 9 / 16).clamp(300.0, 460.0);
        return SizedBox(
          height: heroH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ─── Grande image backdrop ───────────────────────────
              CachedNetworkImage(
                imageUrl: backdropUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorWidget: (_, __, ___) => Container(color: fallbackColor),
              ),
              // ─── Dégradé : fond lisible + fondu vers le contenu ──
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
              // ─── Affiche + infos, à cheval sur le bas de l'image ─
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
                          width: posterW,
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: CachedNetworkImage(
                              imageUrl: posterUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  Container(color: const Color(0xFF1A1A1A)),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFF1A1A1A),
                                child: const Icon(Icons.movie_outlined,
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
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (item.productionYear != null)
                                  _Chip(label: '${item.productionYear}'),
                                if (item.runTimeTicks != null)
                                  _Chip(
                                      label:
                                          _formatRuntime(item.runTimeTicks)),
                                if (item.communityRating != null)
                                  _Chip(
                                    label:
                                        '★ ${item.communityRating!.toStringAsFixed(1)}',
                                    color: const Color(0xFFFFB800),
                                  ),
                                if (item.officialRating != null)
                                  _Chip(
                                      label: item.officialRating!,
                                      outlined: true),
                                if (item.userData?.played == true)
                                  _Chip(
                                      label: '✓ Vu',
                                      color: const Color(0xFF46D369)),
                              ],
                            ),
                            if (item.genres?.isNotEmpty == true) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: item.genres!
                                    .map((g) => GestureDetector(
                                          onTap: () => context.go(
                                              '/genre/${Uri.encodeComponent(g)}'),
                                          child: _Chip(
                                              label: g,
                                              outlined: true,
                                              clickable: true),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool outlined;
  final bool clickable;

  const _Chip({required this.label, this.color, this.outlined = false, this.clickable = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // Fond toujours neutre ; `color` ne teinte que le texte (cohérent avec _Badge série).
        color: outlined ? Colors.transparent : const Color(0xFF2A2A2A),
        border: outlined ? Border.all(color: clickable ? const Color(0xFF666666) : const Color(0xFF444444)) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: clickable ? Colors.white : (color ?? const Color(0xFFCCCCCC)),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
