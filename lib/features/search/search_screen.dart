import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/models/jellyfin_models.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/widgets/media_card.dart';

class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = useState('');
    final mediaResults = useState<List<JellyItem>>([]);
    final personResults = useState<List<JellyItem>>([]);
    final loading = useState(false);

    useEffect(() {
      if (query.value.length < 2) {
        mediaResults.value = [];
        personResults.value = [];
        return null;
      }
      loading.value = true;
      Future.delayed(const Duration(milliseconds: 400), () async {
        try {
          final server = ref.read(activeServerProvider);
          if (server == null) return;
          final client = ref.read(jellyfinClientProvider);

          // Médias
          final mediaResp = await client.getItems(
            userId: server.userId,
            searchTerm: query.value,
            recursive: true,
            includeItemTypes: 'Movie,Series',
            limit: 40,
          );

          // Personnes via l'endpoint dédié /Persons
          final persons = await client.searchPersons(query.value);

          mediaResults.value = mediaResp.items;
          personResults.value = persons;
        } finally {
          loading.value = false;
        }
      });
      return null;
    }, [query.value]);

    final client = ref.read(jellyfinClientProvider);
    final hasResults = mediaResults.value.isNotEmpty || personResults.value.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Titre, acteur, réalisateur...',
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (v) => query.value = v,
        ),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: loading.value
          ? const Center(child: CircularProgressIndicator())
          : !hasResults
              ? Center(
                  child: Text(
                    query.value.length < 2 ? 'Entrez 2 caractères minimum' : 'Aucun résultat',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView(
                  children: [
                    // ─── Personnes ─────────────────────────────────────
                    if (personResults.value.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('Personnes', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: personResults.value.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 14),
                          itemBuilder: (_, i) {
                            final p = personResults.value[i];
                            final photoUrl = client.getImageUrl(
                              itemId: p.id, type: 'Primary', maxWidth: 120);
                            return GestureDetector(
                              onTap: () => context.go('/person/${p.id}',
                                  extra: {'name': p.name}),
                              child: SizedBox(
                                width: 72,
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(32),
                                      child: CachedNetworkImage(
                                        imageUrl: photoUrl,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(
                                          width: 64, height: 64,
                                          color: const Color(0xFF2A2A2A),
                                          child: const Icon(Icons.person_outline,
                                              color: Color(0xFF666666), size: 28),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11,
                                          fontWeight: FontWeight.w500),
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // ─── Médias ────────────────────────────────────────
                    if (mediaResults.value.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('Médias', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      LayoutBuilder(builder: (context, constraints) {
                        final cols = (constraints.maxWidth / 160).floor().clamp(3, 8);
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            childAspectRatio: 2 / 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: mediaResults.value.length,
                          itemBuilder: (ctx, i) {
                            final item = mediaResults.value[i];
                            return MediaCard(
                              item: item,
                              imageUrl: client.getImageUrl(itemId: item.id),
                              onTap: () => navigateToItem(context, item),
                            );
                          },
                        );
                      }),
                    ],
                  ],
                ),
    );
  }
}
