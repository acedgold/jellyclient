import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/watchlist_providers.dart';
import '../../core/storage/watchlist_storage.dart';

// ─── Providers locaux ─────────────────────────────────────────────────────────

enum _SortMode { recent, alpha, type }

final _sortModeProvider = StateProvider<_SortMode>((ref) => _SortMode.recent);
final _gridModeProvider = StateProvider<bool>((ref) => false);

// ─── WatchlistScreen ──────────────────────────────────────────────────────────

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);
    final seen = ref.watch(seenProvider);
    final isGrid = ref.watch(_gridModeProvider);
    final sortMode = ref.watch(_sortModeProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          elevation: 0,
          title: const Text('Mes listes',
              style: TextStyle(fontWeight: FontWeight.w700)),
          leading: BackButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          actions: [
            IconButton(
              icon: Icon(isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
              tooltip: isGrid ? 'Vue liste' : 'Vue grille',
              onPressed: () =>
                  ref.read(_gridModeProvider.notifier).state = !isGrid,
            ),
            PopupMenuButton<_SortMode>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Trier',
              initialValue: sortMode,
              onSelected: (m) => ref.read(_sortModeProvider.notifier).state = m,
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: _SortMode.recent, child: Text('Récent d\'abord')),
                PopupMenuItem(
                    value: _SortMode.alpha, child: Text('Alphabétique')),
                PopupMenuItem(
                    value: _SortMode.type, child: Text('Par type')),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.bookmark_rounded),
                text: watchlist.isEmpty
                    ? 'À regarder'
                    : 'À regarder (${watchlist.length})',
              ),
              Tab(
                icon: const Icon(Icons.check_circle_rounded),
                text: seen.isEmpty ? 'Déjà vu' : 'Déjà vu (${seen.length})',
              ),
            ],
            indicatorColor: const Color(0xFFE50914),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF888888),
          ),
        ),
        body: TabBarView(
          children: [
            _ItemList(
              items: watchlist,
              emptyMsg:
                  'Aucun média dans ta liste.\nAppuie sur ♥ sur une fiche pour en ajouter.',
              isWatchlist: true,
              isGrid: isGrid,
              sortMode: sortMode,
            ),
            _ItemList(
              items: seen,
              emptyMsg:
                  'Aucun média marqué comme vu.\nAppuie sur ✓ sur une fiche.',
              isWatchlist: false,
              isGrid: isGrid,
              sortMode: sortMode,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Liste / Grille ───────────────────────────────────────────────────────────

class _ItemList extends ConsumerWidget {
  final List<WatchlistItem> items;
  final String emptyMsg;
  final bool isWatchlist;
  final bool isGrid;
  final _SortMode sortMode;

  const _ItemList({
    required this.items,
    required this.emptyMsg,
    required this.isWatchlist,
    required this.isGrid,
    required this.sortMode,
  });

  List<WatchlistItem> _sorted(List<WatchlistItem> src) {
    final list = [...src];
    switch (sortMode) {
      case _SortMode.alpha:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _SortMode.type:
        list.sort((a, b) => a.type.compareTo(b.type));
      case _SortMode.recent:
        list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    }
    return list;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWatchlist
                      ? Icons.bookmark_border_rounded
                      : Icons.check_circle_outline_rounded,
                  color: const Color(0xFF555555),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF777777), fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
      );
    }

    final client = ref.read(jellyfinClientProvider);
    final sorted = _sorted(items);

    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: sorted.length,
        itemBuilder: (_, i) => _WatchlistGridCard(
          item: sorted[i],
          isWatchlist: isWatchlist,
          imageUrl: client.getImageUrl(itemId: sorted[i].id, maxWidth: 300),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _WatchlistTile(
        item: sorted[i],
        isWatchlist: isWatchlist,
        imageUrl: client.getImageUrl(itemId: sorted[i].id, maxWidth: 160),
      ),
    );
  }
}

// ─── Helpers partagés ─────────────────────────────────────────────────────────

Future<void> _removeItem(WidgetRef ref, WatchlistItem item, bool isWatchlist) async {
  final storage = ref.read(watchlistStorageProvider);
  final srv = ref.read(activeServerProvider);
  if (srv == null) return;
  if (isWatchlist) {
    await storage.toggleWatchlist(srv.userId, item);
    ref.read(watchlistProvider.notifier).state = storage.getWatchlist(srv.userId);
  } else {
    await storage.toggleSeen(srv.userId, item);
    ref.read(seenProvider.notifier).state = storage.getSeen(srv.userId);
  }
}

String _formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

// ─── Tile liste ───────────────────────────────────────────────────────────────

class _WatchlistTile extends ConsumerWidget {
  final WatchlistItem item;
  final bool isWatchlist;
  final String imageUrl;

  const _WatchlistTile({
    required this.item,
    required this.isWatchlist,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[900],
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _removeItem(ref, item, isWatchlist),
      child: Material(
        color: const Color(0xFF161616),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF242424)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (item.type == 'Series') {
              context.go('/series/${item.id}');
            } else {
              context.go('/detail/${item.id}');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Miniature
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 60,
                    height: 90,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 60,
                      height: 90,
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(Icons.movie_outlined,
                          color: Color(0xFF555555), size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            item.type == 'Series'
                                ? Icons.tv_outlined
                                : Icons.movie_outlined,
                            size: 13,
                            color: const Color(0xFF888888),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.type == 'Series' ? 'Série' : 'Film',
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(item.addedAt),
                            style: const TextStyle(
                                color: Color(0xFF555555), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Bouton retirer
                IconButton(
                  icon: Icon(
                    isWatchlist
                        ? Icons.bookmark_remove_rounded
                        : Icons.remove_circle_outline_rounded,
                    color: const Color(0xFF555555),
                    size: 20,
                  ),
                  tooltip: 'Retirer',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _removeItem(ref, item, isWatchlist),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Carte grille ─────────────────────────────────────────────────────────────

class _WatchlistGridCard extends ConsumerWidget {
  final WatchlistItem item;
  final bool isWatchlist;
  final String imageUrl;

  const _WatchlistGridCard({
    required this.item,
    required this.isWatchlist,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (item.type == 'Series') {
          context.go('/series/${item.id}');
        } else {
          context.go('/detail/${item.id}');
        }
      },
      onLongPress: () => _removeItem(ref, item, isWatchlist),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF242424)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: const Color(0xFF1A1A1A),
                child: const Icon(Icons.movie_outlined,
                    color: Color(0xFF555555), size: 40),
              ),
            ),
            // Gradient bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 64,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xEE000000), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Titre
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Text(
                item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Badge type
            Positioned(
              top: 5,
              left: 5,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.type == 'Series' ? 'SÉRIE' : 'FILM',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
