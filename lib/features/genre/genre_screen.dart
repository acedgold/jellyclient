import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/models/jellyfin_models.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/media_card.dart';

final _genreItemsProvider =
    FutureProvider.family<ItemsResponse, String>((ref, genre) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return const ItemsResponse(items: [], totalRecordCount: 0);
  return ref.read(jellyfinClientProvider).getItems(
    userId: server.userId,
    genres: genre,
    includeItemTypes: 'Movie,Series',
    recursive: true,
    sortBy: 'SortName',
    sortOrder: 'Ascending',
    limit: 150,
  );
});

class GenreScreen extends ConsumerWidget {
  final String genre;

  const GenreScreen({super.key, required this.genre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(_genreItemsProvider(genre));
    final client = ref.read(jellyfinClientProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(genre),
            result.whenOrNull(
              data: (d) => Text(
                '${d.totalRecordCount} médias',
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.normal),
              ),
            ) ?? const SizedBox.shrink(),
          ],
        ),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (data) => data.items.isEmpty
            ? const Center(child: Text('Aucun résultat'))
            : LayoutBuilder(builder: (context, constraints) {
                final cols = (constraints.maxWidth / 160).floor().clamp(3, 10);
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    childAspectRatio: 2 / 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: data.items.length,
                  itemBuilder: (context, i) {
                    final item = data.items[i];
                    return MediaCard(
                      item: item,
                      imageUrl: client.getImageUrl(itemId: item.id),
                      onTap: () => navigateToItem(context, item),
                    );
                  },
                );
              }),
      ),
    );
  }
}
