import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/models/jellyfin_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/external_player.dart';
import '../../shared/widgets/media_card.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final resumeProvider = FutureProvider<List<JellyItem>>((ref) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  return ref.read(jellyfinClientProvider).getResume(server.userId);
});

final _latestByLibraryProvider =
    FutureProvider.family<List<JellyItem>, String>((ref, libraryId) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  final items =
      await ref.read(jellyfinClientProvider).getLatest(server.userId, parentId: libraryId);
  return items.where((i) => i.type != 'Episode' && i.type != 'Season').toList();
});

final libraryViewsProvider = FutureProvider<List<LibraryView>>((ref) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  return ref.read(jellyfinClientProvider).getLibraryViews(server.userId);
});

final _heroBannerItemsProvider = FutureProvider<List<JellyItem>>((ref) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  final resp = await ref.read(jellyfinClientProvider).getItems(
    userId: server.userId,
    includeItemTypes: 'Movie,Series',
    sortBy: 'DateCreated',
    sortOrder: 'Descending',
    recursive: true,
    limit: 20,
    fields: 'Overview,Genres,UserData,MediaStreams',
  );
  final list = [...resp.items]..shuffle();
  return list;
});

final _heroBannerIndexProvider = StateProvider<int>((ref) => 0);

final _topGenresProvider = FutureProvider<List<String>>((ref) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  return ref.read(jellyfinClientProvider).getGlobalGenres(server.userId);
});

final _top10Provider = FutureProvider<List<JellyItem>>((ref) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  final resp = await ref.read(jellyfinClientProvider).getItems(
    userId: server.userId,
    includeItemTypes: 'Movie',
    sortBy: 'DateCreated',
    sortOrder: 'Descending',
    recursive: true,
    limit: 10,
    fields: 'Overview,UserData,MediaStreams',
  );
  return resp.items;
});

final _genreItemsProvider =
    FutureProvider.family<List<JellyItem>, String>((ref, genre) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  final resp = await ref.read(jellyfinClientProvider).getItems(
    userId: server.userId,
    genres: genre,
    includeItemTypes: 'Movie,Series',
    sortBy: 'Random',
    recursive: true,
    limit: 15,
    fields: 'Overview,UserData,MediaStreams',
  );
  return resp.items;
});

final _activeSessionsProvider = FutureProvider<List<JellySession>>((ref) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  return ref.read(jellyfinClientProvider).getSessions();
});

const _cardWidths = [110.0, 138.0, 175.0];

// ─── HomeScreen ───────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  // ValueNotifier : seul l'AppBar se rebuild au scroll, pas toute la page
  final _appBarAlpha = ValueNotifier<double>(0.0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final alpha = (_scrollController.offset / 320).clamp(0.0, 1.0);
    if ((alpha - _appBarAlpha.value).abs() > 0.01) {
      _appBarAlpha.value = alpha; // pas de setState → pas de rebuild de la page
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _appBarAlpha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(activeServerProvider);
    final resume = ref.watch(resumeProvider);
    final libraries = ref.watch(libraryViewsProvider);
    final cardSize = ref.watch(cardSizeProvider);
    final sessionCount =
        ref.watch(_activeSessionsProvider).valueOrNull?.length ?? 0;

    // Nom du serveur calculé une fois (utilisé dans ListenableBuilder)
    final serverName = server != null
        ? (Uri.tryParse(server.name)?.host.isNotEmpty == true
            ? Uri.parse(server.name).host
            : server.name)
        : 'JellyClient';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        // ListenableBuilder : seul l'AppBar se rebuild quand alpha change
        child: ListenableBuilder(
          listenable: _appBarAlpha,
          builder: (context, _) {
            final alpha = _appBarAlpha.value;
            return AppBar(
              backgroundColor: Color.lerp(
                Colors.transparent,
                const Color(0xF20D0D0D),
                alpha,
              ),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.home_filled,
                    color: Color(0xFFE50914), size: 26),
                tooltip: 'Haut de page',
                onPressed: () => _scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut),
              ),
              title: Opacity(
                opacity: alpha,
                child: Text(serverName),
              ),
              actions: [
                Opacity(
                  // Opacité min 0.85 — icônes toujours bien visibles
                  opacity: (0.85 + alpha * 0.15).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge live : personnage + chiffre vert
                      _LiveBadgeButton(
                        count: sessionCount,
                        onTap: () {
                          ref.invalidate(_activeSessionsProvider);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => ProviderScope(
                              parent: ProviderScope.containerOf(context),
                              child: const _LiveSessionsSheet(),
                            ),
                          );
                        },
                      ),
                      // 3 boutons taille vignettes
                      _CardSizeButtons(
                        current: cardSize,
                        onSelect: (i) async {
                          ref.read(cardSizeProvider.notifier).state = i;
                          await ref.read(serverStorageProvider).setCardSize(i);
                        },
                      ),
                      IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => context.go('/search')),
                      IconButton(
                          icon: const Icon(Icons.bookmark_rounded),
                          onPressed: () => context.go('/watchlist')),
                      // Sélection serveur
                      IconButton(
                          icon: const Icon(Icons.dns_outlined),
                          tooltip: 'Serveurs',
                          onPressed: () => context.go('/servers')),
                      IconButton(
                          icon: const Icon(Icons.switch_account_outlined),
                          tooltip: 'Profils',
                          onPressed: () => context.go('/profiles')),
                      IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () => context.go('/settings')),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(resumeProvider);
          ref.invalidate(_latestByLibraryProvider);
          ref.invalidate(libraryViewsProvider);
          ref.invalidate(_heroBannerItemsProvider);
          ref.invalidate(_topGenresProvider);
          ref.invalidate(_top10Provider);
          ref.invalidate(_activeSessionsProvider);
        },
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.zero,
          // Précharge 400px au-delà du viewport (images + layouts)
          cacheExtent: 400,
          children: [
            // ─── Hero Banner ──────────────────────────────────────────────
            const _HeroBanner(),

            // ─── Bibliothèques ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 10),
              child: Text('Bibliothèques',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            libraries.when(
              data: (views) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: views.map((v) => _LibraryChip(view: v)).toList(),
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ─── Top 10 ───────────────────────────────────────────────────
            const _Top10Section(),

            // ─── Continuer à regarder ─────────────────────────────────────
            resume.when(
              data: (items) => items.isEmpty
                  ? const SizedBox.shrink()
                  : _HorizontalSection(
                      title: 'Continuer à regarder',
                      items: items,
                      client: ref.read(jellyfinClientProvider),
                    ),
              loading: () =>
                  const _SectionSkeleton(title: 'Continuer à regarder'),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ─── Ajouts récents par bibliothèque ──────────────────────────
            libraries.when(
              data: (views) => Column(
                children: views.map((v) => _LatestSection(library: v)).toList(),
              ),
              loading: () => const _SectionSkeleton(title: 'Chargement…'),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ─── Sections par genre ───────────────────────────────────────
            const _GenreSections(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Banner ──────────────────────────────────────────────────────────────

class _HeroBanner extends ConsumerWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(_heroBannerItemsProvider);
    final idx = ref.watch(_heroBannerIndexProvider);

    return itemsAsync.when(
      loading: () => const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final item = items[idx % items.length];
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _HeroBannerContent(
            key: ValueKey(item.id),
            item: item,
            onNext: () =>
                ref.read(_heroBannerIndexProvider.notifier).update((s) => s + 1),
          ),
        );
      },
    );
  }
}

class _HeroBannerContent extends ConsumerWidget {
  final JellyItem item;
  final VoidCallback onNext;

  const _HeroBannerContent({super.key, required this.item, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.read(jellyfinClientProvider);
    final server = ref.read(activeServerProvider);
    final backdropUrl =
        client.getImageUrl(itemId: item.id, type: 'Backdrop', maxWidth: 1280);
    final hasProgress = (item.userData?.playbackPositionTicks ?? 0) > 0;

    final bannerHeight = (MediaQuery.of(context).size.height * 0.50).clamp(360.0, 520.0);

    return SizedBox(
      height: bannerHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Backdrop — ancré en haut pour ne pas couper le sujet principal
          CachedNetworkImage(
            imageUrl: backdropUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            placeholder: (_, __) => Container(color: const Color(0xFF111111)),
            errorWidget: (_, __, ___) => CachedNetworkImage(
              imageUrl: client.getImageUrl(itemId: item.id, maxWidth: 900),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorWidget: (_, __, ___) =>
                  Container(color: const Color(0xFF111111)),
            ),
          ),
          // Gradient vertical (transparent → noir)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.45, 1.0],
                colors: [Colors.transparent, Color(0x880D0D0D), Color(0xFF0D0D0D)],
              ),
            ),
          ),
          // Gradient latéral gauche
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xBB0D0D0D), Colors.transparent],
              ),
            ),
          ),
          // Bouton suivant (haut droite)
          Positioned(
            top: 56,
            right: 12,
            child: IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.shuffle_rounded, color: Colors.white70),
              tooltip: 'Autre suggestion',
              style: IconButton.styleFrom(backgroundColor: Colors.black38),
            ),
          ),
          // Contenu (bas gauche)
          Positioned(
            bottom: 28,
            left: 24,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge type
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.type == 'Series' ? 'SÉRIE' : 'FILM',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Logo ou titre texte (fallback)
                SizedBox(
                  height: 72,
                  child: CachedNetworkImage(
                    imageUrl: client.getImageUrl(
                        itemId: item.id, type: 'Logo', maxWidth: 500),
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) => Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                      ),
                      maxLines: 2,
                    ),
                  ),
                ),
                // Année + genres
                if ((item.genres?.isNotEmpty == true) ||
                    item.productionYear != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (item.productionYear != null)
                        _BannerPill('${item.productionYear}'),
                      ...?item.genres?.take(3).map((g) => _BannerPill(g)),
                    ],
                  ),
                ],
                // Synopsis
                if (item.overview != null && item.overview!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.overview!,
                    style: const TextStyle(
                      color: Color(0xCCFFFFFF),
                      fontSize: 13,
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 18),
                // Boutons d'action
                Row(
                  children: [
                    // ▶ Lire / Reprendre
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (item.type == 'Series') {
                          context.go('/series/${item.id}');
                        } else if (server != null) {
                          final audioLang = await getPreferredAudioLang(server.userId);
                          final subLang = await getPreferredSubLang(server.userId);
                          final url = client.getStreamUrl(
                            itemId: item.id,
                            userId: server.userId,
                          );
                          await launchWithExternalPlayer(
                            url: url,
                            title: item.name,
                            startTicks:
                                item.userData?.playbackPositionTicks ?? 0,
                            audioLang: audioLang,
                            subLang: subLang,
                          );
                        }
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: Text(hasProgress ? 'Reprendre' : 'Lire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ℹ Détails
                    OutlinedButton.icon(
                      onPressed: () => navigateToItem(context, item),
                      icon: const Icon(Icons.info_outline_rounded, size: 20),
                      label: const Text('Détails'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerPill extends StatelessWidget {
  final String label;
  const _BannerPill(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      );
}

// ─── Top 10 ───────────────────────────────────────────────────────────────────

class _Top10Section extends ConsumerStatefulWidget {
  const _Top10Section();

  @override
  ConsumerState<_Top10Section> createState() => _Top10SectionState();
}

class _Top10SectionState extends ConsumerState<_Top10Section> {
  final _scrollCtrl = ScrollController();
  final _canLeft = ValueNotifier<bool>(false);
  final _canRight = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    _canLeft.value = _scrollCtrl.offset > 0;
    _canRight.value =
        _scrollCtrl.offset < _scrollCtrl.position.maxScrollExtent - 1;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _canLeft.dispose();
    _canRight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(_top10Provider);
    final client = ref.read(jellyfinClientProvider);

    return items.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();

        // Taille alignée sur le sélecteur global (même base que les autres sections)
        final cardSize = ref.watch(cardSizeProvider);
        final posterW = _cardWidths[cardSize]; // largeur du poster (2/3 ratio)
        const numberOffset = 42.0;
        final cardW = posterW + numberOffset;  // largeur totale = numéro + poster
        final sectionH = posterW * 1.5;        // hauteur = hauteur du poster
        final scrollStep = cardW * 2.5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 4, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Top 10 — Derniers ajouts',
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  // Flèches de navigation (ValueListenableBuilder = pas de setState)
                  _ScrollArrow(
                    left: true,
                    canScroll: _canLeft,
                    onPressed: () => _scrollCtrl.animateTo(
                      (_scrollCtrl.offset - scrollStep)
                          .clamp(0, _scrollCtrl.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    ),
                  ),
                  _ScrollArrow(
                    left: false,
                    canScroll: _canRight,
                    onPressed: () => _scrollCtrl.animateTo(
                      (_scrollCtrl.offset + scrollStep)
                          .clamp(0, _scrollCtrl.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            SizedBox(
              height: sectionH,
              child: ListView.separated(
                controller: _scrollCtrl,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 2),
                itemBuilder: (context, i) => _Top10Card(
                  rank: i + 1,
                  item: list[i],
                  imageUrl: client.getImageUrl(itemId: list[i].id),
                  cardWidth: cardW,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Top10Card extends StatelessWidget {
  final int rank;
  final JellyItem item;
  final String imageUrl;
  final double cardWidth;

  const _Top10Card({
    required this.rank,
    required this.item,
    required this.imageUrl,
    required this.cardWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Taille de la police proportionnelle à la largeur de card (pas de clamp serré)
    final fontSize = cardWidth * 0.38;
    const numberOffset = 42.0;

    return SizedBox(
      width: cardWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomLeft,
        children: [
          // Numéro style Netflix (grand, contouré)
          Positioned(
            left: 0,
            bottom: 0,
            child: Stack(
              children: [
                Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 5
                      ..color = const Color(0xFF444444),
                  ),
                ),
                Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: const Color(0xFF0D0D0D),
                  ),
                ),
              ],
            ),
          ),
          // Poster décalé à droite
          Padding(
            padding: const EdgeInsets.only(left: numberOffset),
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: MediaCard(
                item: item,
                imageUrl: imageUrl,
                onTap: () => navigateToItem(context, item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sections par genre ───────────────────────────────────────────────────────

class _GenreSections extends ConsumerWidget {
  const _GenreSections();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = ref.watch(_topGenresProvider);
    return genres.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) => Column(
        children: list.take(4).map((g) => _GenreSection(genre: g)).toList(),
      ),
    );
  }
}

class _GenreSection extends ConsumerWidget {
  final String genre;
  const _GenreSection({required this.genre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(_genreItemsProvider(genre));
    final client = ref.read(jellyfinClientProvider);
    return items.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) => list.length < 4
          ? const SizedBox.shrink()
          : _HorizontalSection(title: genre, items: list, client: client),
    );
  }
}

// ─── Flèche de navigation partagée ───────────────────────────────────────────

class _ScrollArrow extends StatelessWidget {
  final bool left;
  final ValueNotifier<bool> canScroll;
  final VoidCallback onPressed;

  const _ScrollArrow({
    required this.left,
    required this.canScroll,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: canScroll,
      builder: (_, can, __) => IconButton(
        icon: Icon(
            left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
        color: can ? Colors.white70 : const Color(0xFF333333),
        onPressed: can ? onPressed : null,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }
}

// ─── Section horizontale ──────────────────────────────────────────────────────

class _LatestSection extends ConsumerWidget {
  final LibraryView library;
  const _LatestSection({required this.library});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(_latestByLibraryProvider(library.id));
    final client = ref.read(jellyfinClientProvider);

    return latest.when(
      loading: () => _SectionSkeleton(title: 'Récents — ${library.name}'),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : _HorizontalSection(
              title: 'Récents — ${library.name}',
              items: items,
              client: client,
            ),
    );
  }
}

class _HorizontalSection extends ConsumerStatefulWidget {
  final String title;
  final List<JellyItem> items;
  final dynamic client;

  const _HorizontalSection({
    required this.title,
    required this.items,
    required this.client,
  });

  @override
  ConsumerState<_HorizontalSection> createState() => _HorizontalSectionState();
}

class _HorizontalSectionState extends ConsumerState<_HorizontalSection> {
  final _scrollCtrl = ScrollController();
  final _canLeft = ValueNotifier<bool>(false);
  final _canRight = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    _canLeft.value = _scrollCtrl.offset > 0;
    _canRight.value =
        _scrollCtrl.offset < _scrollCtrl.position.maxScrollExtent - 1;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _canLeft.dispose();
    _canRight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardSize = ref.watch(cardSizeProvider);
    final cardWidth = _cardWidths[cardSize];
    const gap = 10.0;
    final scrollStep = cardWidth * 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 4, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.title,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              _ScrollArrow(
                left: true,
                canScroll: _canLeft,
                onPressed: () => _scrollCtrl.animateTo(
                  (_scrollCtrl.offset - scrollStep)
                      .clamp(0, _scrollCtrl.position.maxScrollExtent),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                ),
              ),
              _ScrollArrow(
                left: false,
                canScroll: _canRight,
                onPressed: () => _scrollCtrl.animateTo(
                  (_scrollCtrl.offset + scrollStep)
                      .clamp(0, _scrollCtrl.position.maxScrollExtent),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        SizedBox(
          height: cardWidth * 1.5,
          child: ListView.builder(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.items.length,
            // itemExtent fixe = Flutter précalcule les positions sans mesurer chaque item
            itemExtent: cardWidth + gap,
            itemBuilder: (context, i) {
              final item = widget.items[i];
              final isEpisode = item.type == 'Episode';
              final displayId =
                  isEpisode && item.seriesId != null ? item.seriesId! : item.id;
              return Padding(
                padding: const EdgeInsets.only(right: gap),
                child: RepaintBoundary(
                  child: SizedBox(
                    width: cardWidth,
                    child: MediaCard(
                      item: isEpisode && item.seriesId != null
                          ? item.copyWith(name: item.seriesName ?? item.name)
                          : item,
                      imageUrl: widget.client.getImageUrl(itemId: displayId),
                      onTap: () {
                        if (isEpisode && item.seriesId != null) {
                          context.go('/series/${item.seriesId}');
                        } else {
                          navigateToItem(context, item);
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  final String title;
  const _SectionSkeleton({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 207,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) =>
                const SizedBox(width: 138, child: MediaCardSkeleton()),
          ),
        ),
      ],
    );
  }
}

// ─── 3 boutons taille vignettes ──────────────────────────────────────────────

class _CardSizeButtons extends StatelessWidget {
  final int current;
  final Future<void> Function(int) onSelect;

  const _CardSizeButtons({required this.current, required this.onSelect});

  // Icônes représentant les 3 tailles de grille (petit=dense, grand=large)
  static const _icons = [
    Icons.apps,          // petit : 3×3 grille dense
    Icons.grid_view,     // moyen : 2×2 grille standard
    Icons.view_module,   // grand : 2×2 grandes tuiles
  ];
  static const _labels = ['Petites vignettes', 'Vignettes moyennes', 'Grandes vignettes'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final isActive = i == current;
        return Tooltip(
          message: _labels[i],
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => onSelect(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Icon(
                _icons[i],
                size: 22,
                color: isActive
                    ? const Color(0xFFE50914)
                    : const Color(0xFF888888),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Bouton badge live ────────────────────────────────────────────────────────

class _LiveBadgeButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  const _LiveBadgeButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.people_outline_rounded),
          tooltip: 'En ligne',
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            top: 6,
            right: 4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16),
              height: 16,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Panel sessions actives (bottom sheet) ────────────────────────────────────

class _LiveSessionsSheet extends ConsumerWidget {
  const _LiveSessionsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_activeSessionsProvider);
    final client = ref.read(jellyfinClientProvider);
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ─── Poignée ──────────────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ─── En-tête ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.monitor_rounded,
                    color: Color(0xFF4CAF50), size: 22),
                const SizedBox(width: 10),
                const Text(
                  'En ligne',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                sessionsAsync.when(
                  data: (s) => Text(
                    '${s.length} utilisateur${s.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF222222), height: 1),
          // ─── Liste ────────────────────────────────────────────────
          Expanded(
            child: sessionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                  child: Text('Impossible de charger les sessions')),
              data: (sessions) => sessions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded,
                              size: 48, color: Color(0xFF333333)),
                          SizedBox(height: 12),
                          Text(
                            'Personne ne regarde en ce moment',
                            style: TextStyle(
                                color: Color(0xFF666666), fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) => _SessionTile(
                          session: sessions[i], client: client),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final JellySession session;
  final dynamic client;
  const _SessionTile({required this.session, required this.client});

  @override
  Widget build(BuildContext context) {
    final posMins = session.positionTicks != null
        ? session.positionTicks! ~/ 600000000
        : null;
    final totalMins = session.runTimeTicks != null
        ? session.runTimeTicks! ~/ 600000000
        : null;
    final progress = (session.positionTicks != null &&
            session.runTimeTicks != null &&
            session.runTimeTicks! > 0)
        ? (session.positionTicks! / session.runTimeTicks!).clamp(0.0, 1.0)
        : null;
    final posterUrl = session.nowPlayingItemId != null
        ? (client.getImageUrl(
            itemId: session.nowPlayingItemId,
            type: 'Primary',
            maxWidth: 120) as String)
        : null;
    final initial =
        (session.userName ?? '?').isNotEmpty ? session.userName![0].toUpperCase() : '?';
    final clientInfo = [session.deviceName, session.client]
        .where((s) => s != null && s.isNotEmpty)
        .join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A3A1A), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Avatar lettre ────────────────────────────────────────
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // ─── Infos centre ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom utilisateur
                Text(
                  session.userName ?? '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                // Client / appareil
                if (clientInfo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    clientInfo,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                // Titre en cours
                Row(
                  children: [
                    Icon(
                      session.isPaused
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 14,
                      color: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        session.nowPlayingItemName ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Barre de progression + durée
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF2A2A2A),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${posMins ?? '?'}min / ${totalMins ?? '?'}min',
                    style: const TextStyle(
                        color: Color(0xFF666666), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          // ─── Poster ───────────────────────────────────────────────
          if (posterUrl != null) ...[
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                posterUrl,
                width: 54,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Image aléatoire par bibliothèque ────────────────────────────────────────

final _libraryRandomImageProvider =
    FutureProvider.family<String?, String>((ref, libraryId) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return null;
  final resp = await ref.read(jellyfinClientProvider).getItems(
    userId: server.userId,
    parentId: libraryId,
    sortBy: 'Random',
    recursive: false,
    limit: 1,
  );
  if (resp.items.isEmpty) return null;
  final item = resp.items.first;
  return ref
      .read(jellyfinClientProvider)
      .getImageUrl(itemId: item.id, type: 'Backdrop', maxWidth: 500);
});

// ─── Carte bibliothèque ───────────────────────────────────────────────────────

class _LibraryChip extends ConsumerWidget {
  final LibraryView view;
  const _LibraryChip({required this.view});

  IconData _icon(String? type) => switch (type) {
        'movies' => Icons.movie_outlined,
        'tvshows' => Icons.tv_outlined,
        'music' => Icons.music_note_outlined,
        'books' => Icons.menu_book_outlined,
        _ => Icons.folder_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageAsync = ref.watch(_libraryRandomImageProvider(view.id));
    final cardSize = ref.watch(cardSizeProvider);
    // Largeur 200 / 260 / 320 · Hauteur = largeur × 145/260
    const baseW = 260.0;
    const baseH = 145.0;
    final sizeScale = [0.77, 1.0, 1.23][cardSize];
    final chipW = baseW * sizeScale;
    final chipH = baseH * sizeScale;

    return GestureDetector(
      onTap: () {
        final name = Uri.encodeQueryComponent(view.name);
        final type = view.collectionType != null
            ? '&type=${Uri.encodeQueryComponent(view.collectionType!)}'
            : '';
        context.go(
            '/library/${Uri.encodeComponent(view.id)}?name=$name$type');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: chipW,
          height: chipH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageAsync.when(
                data: (url) => url != null
                    ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: const Color(0xFF1A1A1A)),
                        errorWidget: (_, __, ___) =>
                            Container(color: const Color(0xFF1A1A1A)),
                      )
                    : Container(color: const Color(0xFF1A1A1A)),
                loading: () => Container(color: const Color(0xFF1A1A1A)),
                error: (_, __) => Container(color: const Color(0xFF1A1A1A)),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x44000000), Color(0xCC000000)],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Icon(_icon(view.collectionType),
                        size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        view.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black)
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
