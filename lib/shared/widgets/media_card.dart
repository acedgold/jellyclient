import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/models/jellyfin_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/watchlist_providers.dart';
import '../../core/services/external_player.dart';
import '../../core/storage/watchlist_storage.dart';

// ─── Provider streams 1er épisode série ──────────────────────────────────────

final _seriesStreamsProvider =
    FutureProvider.family<List<MediaStream>, String>((ref, seriesId) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  return ref
      .read(jellyfinClientProvider)
      .getFirstEpisodeStreams(server.userId, seriesId);
});

// ─── Mapping langue ISO → code pays affiché ───────────────────────────────────

String _langToCode(String? lang) {
  if (lang == null || lang.isEmpty) return '';
  return switch (lang.toLowerCase()) {
    'fre' || 'fra' || 'fr' => 'FR',
    'eng' || 'en' => 'EN',
    'ita' || 'it' => 'IT',
    'kor' || 'ko' => 'KR',
    'jpn' || 'ja' => 'JA',
    'spa' || 'es' => 'ES',
    'deu' || 'ger' || 'de' => 'DE',
    'por' || 'pt' => 'PT',
    'chi' || 'zho' || 'zh' => 'ZH',
    'ara' || 'ar' => 'AR',
    'rus' || 'ru' => 'RU',
    'pol' || 'pl' => 'PL',
    'nld' || 'dut' || 'nl' => 'NL',
    'swe' || 'sv' => 'SV',
    'nor' || 'nb' || 'no' => 'NO',
    'dan' || 'da' => 'DA',
    'fin' || 'fi' => 'FI',
    'tur' || 'tr' => 'TR',
    'hin' || 'hi' => 'HI',
    'tha' || 'th' => 'TH',
    'vie' || 'vi' => 'VI',
    'und' || 'zxx' => '',
    _ => lang.substring(0, lang.length.clamp(0, 2)).toUpperCase(),
  };
}

// Récupère un code langue depuis le DisplayTitle quand le champ Language est
// vide (certaines releases écrivent la langue dans le titre de la piste, ex.
// « VFF - AC3 », « Japanese - AAC »). Mots-clés distinctifs uniquement.
String _langFromDisplayTitle(String? dt) {
  if (dt == null || dt.isEmpty) return '';
  final t = dt.toLowerCase();
  const map = {
    'french': 'FR', 'francais': 'FR', 'français': 'FR',
    'vff': 'FR', 'vfq': 'FR', 'vfi': 'FR', 'truefrench': 'FR',
    'english': 'EN', 'anglais': 'EN',
    'japanese': 'JA', 'japonais': 'JA',
    'italian': 'IT', 'korean': 'KR',
    'spanish': 'ES', 'espanol': 'ES', 'español': 'ES',
    'german': 'DE', 'deutsch': 'DE', 'allemand': 'DE',
    'portuguese': 'PT', 'chinese': 'ZH', 'mandarin': 'ZH',
    'arabic': 'AR', 'russian': 'RU',
  };
  for (final e in map.entries) {
    if (t.contains(e.key)) return e.value;
  }
  return '';
}

/// Code langue d'une piste : champ Language d'abord, sinon déduit du titre.
String _streamLangCode(MediaStream s) {
  final l = _langToCode(s.language);
  return l.isNotEmpty ? l : _langFromDisplayTitle(s.displayTitle);
}

/// Badge langue audio d'une vignette :
///   ≥2 langues distinctes → MULTI ; 1 langue → son code ; 0 → aucun badge.
/// On n'affiche JAMAIS le codec (MP3/AAC…) : ce n'est pas une langue.
String? _audioLabelFromStreams(List<MediaStream> streams) {
  final codes = <String>{};
  for (final s in streams.where((s) => s.type == 'Audio')) {
    final c = _streamLangCode(s);
    if (c.isNotEmpty) codes.add(c);
  }
  if (codes.length >= 2) return 'MULTI';
  if (codes.length == 1) return codes.first;
  return null;
}

/// Route vers la bonne vue selon le type Jellyfin de l'item.
void navigateToItem(BuildContext context, JellyItem item) {
  switch (item.type) {
    case 'Series':
      context.go('/series/${item.id}');
    case 'Episode':
      if (item.seriesId != null) {
        context.go('/series/${item.seriesId}');
      } else {
        context.go('/detail/${item.id}');
      }
    default:
      context.go('/detail/${item.id}');
  }
}

bool _isNew(JellyItem item) {
  if (item.dateCreated == null) return false;
  final created = DateTime.tryParse(item.dateCreated!);
  if (created == null) return false;
  return DateTime.now().difference(created).inDays <= 7;
}

// ─── MediaCard ────────────────────────────────────────────────────────────────

class MediaCard extends ConsumerStatefulWidget {
  final JellyItem item;
  final String imageUrl;
  final VoidCallback onTap;
  final double aspectRatio;

  const MediaCard({
    super.key,
    required this.item,
    required this.imageUrl,
    required this.onTap,
    this.aspectRatio = 2 / 3,
  });

  @override
  ConsumerState<MediaCard> createState() => _MediaCardState();
}

class _MediaCardState extends ConsumerState<MediaCard> {
  bool _hovered = false;

  String? _formatRemaining() {
    final pos = widget.item.userData?.playbackPositionTicks;
    final total = widget.item.runTimeTicks;
    if (pos == null || total == null || pos <= 0) return null;
    final remaining = total - pos;
    if (remaining <= 0) return null;
    final minutes = remaining ~/ 600000000;
    if (minutes < 1) return null;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}min' : '${m}min';
  }

  Future<void> _quickPlay() async {
    if (widget.item.type == 'Series') {
      if (mounted) context.go('/series/${widget.item.id}');
      return;
    }
    final server = ref.read(activeServerProvider);
    final client = ref.read(jellyfinClientProvider);
    if (server == null) return;

    final capturedClient = client;
    final capturedServer = server;
    final capturedItemId = widget.item.id;
    final capturedRuntime = widget.item.runTimeTicks;

    try {
      final audioLang = await getPreferredAudioLang(server.userId);
      final subLang = await getPreferredSubLang(server.userId);
      final url =
          client.getStreamUrl(itemId: widget.item.id, userId: server.userId);
      await launchWithExternalPlayer(
        url: url,
        title: widget.item.name,
        startTicks: widget.item.userData?.playbackPositionTicks ?? 0,
        audioLang: audioLang,
        subLang: subLang,
        mediaStreams: widget.item.mediaStreams,
        onStopped: (estimatedTicks) async {
          await capturedClient.reportPlaybackStop(
            itemId: capturedItemId,
            positionTicks: estimatedTicks,
          );
          if (capturedRuntime != null &&
              estimatedTicks >= capturedRuntime * 0.9) {
            await capturedClient.markPlayed(
                capturedServer.userId, capturedItemId);
          }
        },
      );
    } catch (_) {}
  }

  Future<void> _toggleWatchlist() async {
    await toggleWatchlist(
      ref,
      WatchlistItem(
        id: widget.item.id,
        name: widget.item.name,
        type: widget.item.type ?? 'Movie',
        addedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.item.userData?.playedPercentage;

    // Badge audio : pour les séries, fetch le 1er épisode S1 ; sinon streams directs
    final isSeries = widget.item.type == 'Series';
    final directStreams = widget.item.mediaStreams ?? [];
    final seriesStreamsAsync = isSeries
        ? ref.watch(_seriesStreamsProvider(widget.item.id))
        : null;
    final audioStreams = isSeries
        ? (seriesStreamsAsync?.valueOrNull ?? directStreams)
        : directStreams;
    final audioLabel = _audioLabelFromStreams(audioStreams);

    // select() : rebuild uniquement si le statut de CET item change (pas toute la liste)
    final inWatchlist = ref.watch(
      watchlistProvider.select((wl) => wl.any((i) => i.id == widget.item.id)),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 150),
                  memCacheWidth: 200,
                  placeholder: (_, __) =>
                      Container(color: const Color(0xFF1A1A1A)),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Icon(Icons.movie_outlined,
                        color: Color(0xFF555555), size: 48),
                  ),
                ),
                // Gradient bas
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xDD000000), Colors.transparent],
                      ),
                    ),
                  ),
                ),
                // Barre de progression + temps restant
                if (progress != null && progress > 0) ...[
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).colorScheme.primary),
                      minHeight: 3,
                    ),
                  ),
                  if (_formatRemaining() != null)
                    Positioned(
                      bottom: 6,
                      right: 8,
                      child: Text(
                        _formatRemaining()!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ),
                ],
                // Titre
                Positioned(
                  bottom: progress != null ? 14 : 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    widget.item.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Badge audio (haut-droit, prioritaire)
                if (audioLabel != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.70),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        audioLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                // Badge vu (sous le badge audio si présent)
                if (widget.item.userData?.played == true)
                  Positioned(
                    top: audioLabel != null ? 28 : 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          const Icon(Icons.check, color: Colors.white70, size: 12),
                    ),
                  ),
                // Badge NOUVEAU / SÉRIE (top-left)
                if (_isNew(widget.item))
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('NOUVEAU',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  )
                else if (widget.item.type == 'Series')
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('SÉRIE',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),

                // ─── Hover overlay ─────────────────────────────────────────
                RepaintBoundary(
                 child: AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !_hovered,
                    child: Container(
                      color: Colors.black.withOpacity(0.72),
                      child: Stack(
                        children: [
                          // Infos synopsis + note (haut)
                          Positioned(
                            top: 8,
                            left: 8,
                            right: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (widget.item.communityRating != null)
                                      Text(
                                        '★ ${widget.item.communityRating!.toStringAsFixed(1)}',
                                        style: const TextStyle(
                                            color: Color(0xFFFFB800),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    if (widget.item.communityRating != null &&
                                        widget.item.productionYear != null)
                                      const SizedBox(width: 6),
                                    if (widget.item.productionYear != null)
                                      Text(
                                        '${widget.item.productionYear}',
                                        style: const TextStyle(
                                            color: Color(0xFFAAAAAA),
                                            fontSize: 11),
                                      ),
                                    if (_formatRemaining() != null) ...[
                                      const Spacer(),
                                      Text(
                                        '${_formatRemaining()} restant',
                                        style: const TextStyle(
                                            color: Color(0xFFE50914),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ],
                                ),
                                if (widget.item.overview != null &&
                                    widget.item.overview!.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    widget.item.overview!,
                                    style: const TextStyle(
                                        color: Color(0xFFCCCCCC),
                                        fontSize: 12,
                                        height: 1.4),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // ▶ Play (centre)
                          Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _quickPlay,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black45, blurRadius: 8)
                                  ],
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.black,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          // ♥ Watchlist (bas gauche)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _toggleWatchlist,
                              child: Icon(
                                inWatchlist
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: inWatchlist
                                    ? const Color(0xFFE50914)
                                    : Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          // ℹ Info (bas droite)
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.onTap,
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                 ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class MediaCardSkeleton extends StatelessWidget {
  final double aspectRatio;
  const MediaCardSkeleton({super.key, this.aspectRatio = 2 / 3});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(color: const Color(0xFF1A1A1A)),
      ),
    );
  }
}
