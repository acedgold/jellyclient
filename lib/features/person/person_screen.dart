import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/models/jellyfin_models.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/media_card.dart';

final _personItemsProvider =
    FutureProvider.family<ItemsResponse, String>((ref, personId) async {
  final server = ref.watch(activeServerProvider);
  if (server == null) return const ItemsResponse(items: [], totalRecordCount: 0);
  return ref.read(jellyfinClientProvider).getPersonItems(server.userId, personId);
});

class PersonScreen extends ConsumerWidget {
  final String personId;
  final String personName;
  final String? personRole;

  const PersonScreen({
    super.key,
    required this.personId,
    required this.personName,
    this.personRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(_personItemsProvider(personId));
    final client = ref.read(jellyfinClientProvider);
    final photoUrl = client.getImageUrl(itemId: personId, type: 'Primary', maxWidth: 300);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            leading: BackButton(
              onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo de la personne en fond flouté
                  CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(color: const Color(0xFF1A1A1A)),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x44000000), Color(0xDD0D0D0D)],
                      ),
                    ),
                  ),
                  // Nom + rôle en bas
                  Positioned(
                    bottom: 16,
                    left: 72,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          personName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (personRole != null && personRole!.isNotEmpty)
                          Text(
                            personRole!,
                            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  // Portrait rond
                  Positioned(
                    bottom: 12,
                    left: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: CachedNetworkImage(
                        imageUrl: photoUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xFF2A2A2A),
                          child: const Icon(Icons.person_outline, color: Color(0xFF666666), size: 28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          result.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(child: Text('Erreur : $err')),
            ),
            data: (data) {
              if (data.items.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Aucun résultat')),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final item = data.items[i];
                      return MediaCard(
                        item: item,
                        imageUrl: client.getImageUrl(itemId: item.id),
                        onTap: () => navigateToItem(context, item),
                      );
                    },
                    childCount: data.items.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 2 / 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
