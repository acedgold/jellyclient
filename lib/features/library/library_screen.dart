import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/models/jellyfin_models.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/media_card.dart';

const _kPageSize = 100;

class _LibraryArgs {
  final String libraryId;
  final String sortBy;
  final String sortOrder;
  final int startIndex;
  final String? genre;

  const _LibraryArgs({
    required this.libraryId,
    required this.sortBy,
    this.sortOrder = 'Ascending',
    this.startIndex = 0,
    this.genre,
  });

  @override
  bool operator ==(Object other) =>
      other is _LibraryArgs &&
      libraryId == other.libraryId &&
      sortBy == other.sortBy &&
      sortOrder == other.sortOrder &&
      startIndex == other.startIndex &&
      genre == other.genre;

  @override
  int get hashCode => Object.hash(libraryId, sortBy, sortOrder, startIndex, genre);
}

final _genresProvider =
    FutureProvider.autoDispose.family<List<String>, String>((ref, libraryId) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return [];
  return ref.read(jellyfinClientProvider).getGenres(server.userId, libraryId);
});

final _libraryItemsProvider =
    FutureProvider.autoDispose.family<ItemsResponse, _LibraryArgs>(
  (ref, args) async {
    final server = ref.watch(activeServerProvider);
    if (server == null) return const ItemsResponse(items: [], totalRecordCount: 0);

    // Avec filtre genre : recursive=true obligatoire pour que Jellyfin filtre correctement
    return ref.read(jellyfinClientProvider).getItems(
      userId: server.userId,
      parentId: args.libraryId,
      sortBy: args.sortBy,
      sortOrder: args.sortOrder,
      recursive: args.genre != null ? true : false,
      limit: _kPageSize,
      startIndex: args.startIndex,
      genres: args.genre,
    );
  },
);

class LibraryScreen extends ConsumerStatefulWidget {
  final String libraryId;
  final String libraryName;
  final String? collectionType;

  const LibraryScreen({
    super.key,
    required this.libraryId,
    required this.libraryName,
    this.collectionType,
  });

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _sortBy = 'SortName';
  bool _ascending = true;
  int _page = 0;
  String? _genre;

  final List<JellyItem> _allItems = [];
  // startIndex des pages déjà intégrées à _allItems → évite les doublons et
  // les boucles de fusion (la population se fait dans build, pas via ref.listen).
  final Set<int> _mergedStarts = {};
  int _totalCount = 0;
  bool _isLoadingMore = false;
  late final ScrollController _scrollController;

  int get _startIndex => _page * _kPageSize;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
            _scrollController.position.maxScrollExtent * 0.85 &&
        !_isLoadingMore &&
        _allItems.length < _totalCount) {
      setState(() {
        _page++;
        _isLoadingMore = true;
      });
    }
  }

  void _resetAndReload() {
    setState(() {
      _page = 0;
      _allItems.clear();
      _mergedStarts.clear();
      _totalCount = 0;
      _isLoadingMore = false;
    });
  }

  static String _sortLabel(String sortBy) => switch (sortBy) {
    'DateCreated'     => 'Date',
    'CommunityRating' => 'Note',
    'ProductionYear'  => 'Année',
    _                 => 'A–Z',
  };

  Widget _sortBtn(String value, String label) {
    final active = _sortBy == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () { _sortBy = value; _resetAndReload(); },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2A2A2A) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              color: active ? Colors.white : const Color(0xFF888888),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _sortItem(String value, IconData icon, String label) =>
      PopupMenuItem(
        value: value,
        child: Row(children: [
          Icon(icon, size: 18, color: _sortBy == value
              ? Theme.of(context).colorScheme.primary : null),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(
            color: _sortBy == value ? Theme.of(context).colorScheme.primary : null,
            fontWeight: _sortBy == value ? FontWeight.w600 : FontWeight.normal,
          )),
          if (_sortBy == value) ...[
            const Spacer(),
            Icon(
              _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ]),
      );

  List<JellyItem> _applyFilter(List<JellyItem> items) {
    // Dans une vue Library (parentId), un Episode signifie un fichier mal
    // classé côté serveur (film indexé comme Episode). On les masque pour
    // éviter les faux "films d'autres bibliothèques".
    return items.where((i) => i.type != 'Episode').toList();
  }

  @override
  Widget build(BuildContext context) {
    final args = _LibraryArgs(
      libraryId: widget.libraryId,
      sortBy: _sortBy,
      sortOrder: _ascending ? 'Ascending' : 'Descending',
      startIndex: _startIndex,
      genre: _genre,
    );
    final genres = ref.watch(_genresProvider(widget.libraryId));
    final result = ref.watch(_libraryItemsProvider(args));

    // Population fiable : on intègre la donnée OBSERVÉE (pas un "changement").
    // Indispensable car au retour sur l'écran le provider est déjà résolu
    // (aucun ref.listen ne se déclencherait → bibliothèque vide).
    // Idempotent grâce à _mergedStarts : pas de boucle ni de doublon.
    result.whenData((data) {
      if (_mergedStarts.contains(args.startIndex)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _mergedStarts.contains(args.startIndex)) return;
        setState(() {
          _mergedStarts.add(args.startIndex);
          _totalCount = data.totalRecordCount;
          final newItems = _applyFilter(data.items);
          if (args.startIndex == 0) {
            _allItems
              ..clear()
              ..addAll(newItems);
          } else {
            final existingIds = _allItems.map((i) => i.id).toSet();
            _allItems.addAll(newItems.where((i) => !existingIds.contains(i.id)));
          }
          _isLoadingMore = false;
        });
      });
    });

    final rawTotal = _totalCount;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.libraryName),
            if (_totalCount > 0)
              Text(
                '${_allItems.length}${_allItems.length < _totalCount ? ' / $_totalCount' : ''} médias',
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.normal),
              ),
          ],
        ),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(genres.maybeWhen(data: (g) => g.isNotEmpty ? 96.0 : 50.0, orElse: () => 50.0)),
          child: Column(
            children: [
              // ── Barre tri ────────────────────────────────────────────
              Container(
                color: const Color(0xFF111111),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    const Text('Tri :', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                    const SizedBox(width: 8),
                    // Critères
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _sortBtn('SortName',        'A–Z'),
                            _sortBtn('DateCreated',     'Date'),
                            _sortBtn('CommunityRating', 'Note'),
                            _sortBtn('ProductionYear',  'Année'),
                          ],
                        ),
                      ),
                    ),
                    // Toggle ↑↓ bien visible
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () { _ascending = !_ascending; _resetAndReload(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _ascending ? 'A→Z' : 'Z→A',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Chips genres ──────────────────────────────────────────
              genres.maybeWhen(
                data: (list) => list.isEmpty
                    ? const SizedBox(height: 4)
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: Row(
                          children: [
                            // Chip "Tous genres"
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('Tous genres'),
                                selected: _genre == null,
                                selectedColor: Theme.of(context).colorScheme.primary,
                                backgroundColor: const Color(0xFF1A1A1A),
                                labelStyle: TextStyle(
                                  color: _genre == null ? Colors.white : const Color(0xFFAAAAAA),
                                  fontSize: 11,
                                ),
                                side: BorderSide.none,
                                onSelected: (_) { _genre = null; _resetAndReload(); },
                              ),
                            ),
                            ...list.map((g) {
                              final sel = _genre == g;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(g),
                                  selected: sel,
                                  selectedColor: Theme.of(context).colorScheme.primary,
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  labelStyle: TextStyle(
                                    color: sel ? Colors.white : const Color(0xFFAAAAAA),
                                    fontSize: 11,
                                  ),
                                  side: BorderSide.none,
                                  onSelected: (_) { _genre = g; _resetAndReload(); },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                orElse: () => const SizedBox(height: 4),
              ),
            ],
          ),
        ),
      ),
      body: _allItems.isEmpty
          ? result.when(
              loading: () => const _GridSkeleton(),
              error: (err, _) => Center(child: Text('Erreur : $err')),
              data: (_) => const Center(child: Text('Aucun contenu')),
            )
          : _MediaGrid(
              items: _allItems,
              client: ref.read(jellyfinClientProvider),
              scrollController: _scrollController,
              isLoadingMore: _isLoadingMore,
              hasMore: _allItems.length < rawTotal,
            ),
    );
  }
}

class _Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final from = currentPage * _kPageSize + 1;
    final to = ((currentPage + 1) * _kPageSize).clamp(0, total);

    return Container(
      color: const Color(0xFF0D0D0D),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            onPressed: onPrev,
            color: onPrev != null ? Colors.white : const Color(0xFF444444),
          ),
          Expanded(
            child: Text(
              '$from–$to sur $total',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            onPressed: onNext,
            color: onNext != null ? Colors.white : const Color(0xFF444444),
          ),
        ],
      ),
    );
  }
}

// Largeur cible d'une colonne de grille selon la taille de vignette choisie
// (cardSizeProvider : 0=petit 1=moyen 2=grand). Valeurs espacées pour que les
// 3 tailles donnent un nombre de colonnes distinct même sur écran large
// (les valeurs de l'accueil saturaient le clamp → aucune variation visible).
const _gridColWidths = [168.0, 220.0, 288.0];

class _MediaGrid extends ConsumerWidget {
  final List<JellyItem> items;
  final dynamic client;
  final ScrollController? scrollController;
  final bool isLoadingMore;
  final bool hasMore;

  const _MediaGrid({
    required this.items,
    required this.client,
    this.scrollController,
    this.isLoadingMore = false,
    this.hasMore = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colWidth = _gridColWidths[ref.watch(cardSizeProvider)];
    return GridView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: colWidth,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final item = items[i];
          return MediaCard(
            item: item,
            imageUrl: client.getImageUrl(itemId: item.id),
            onTap: () => navigateToItem(context, item),
          );
        },
      );
  }
}

class _GridSkeleton extends ConsumerWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colWidth = _gridColWidths[ref.watch(cardSizeProvider)];
    return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: colWidth,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 20,
        itemBuilder: (_, __) => const MediaCardSkeleton(),
      );
  }
}
