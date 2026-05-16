import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/models/jellyfin_models.dart';

class CastSection extends StatelessWidget {
  final List<JellyPerson> people;
  final dynamic client;

  const CastSection({super.key, required this.people, required this.client});

  static const _roleOrder = ['Director', 'Writer', 'Producer', 'Actor', 'GuestStar'];

  static String _roleLabel(String? type) => switch (type) {
    'Director'  => 'Réalisateur',
    'Writer'    => 'Scénariste',
    'Producer'  => 'Producteur',
    'Actor'     => 'Acteur',
    'GuestStar' => 'Guest',
    _           => type ?? 'Autre',
  };

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<JellyPerson>>{};
    for (final p in people) {
      final type = p.type ?? 'Autre';
      grouped.putIfAbsent(type, () => []).add(p);
    }

    final orderedKeys = [
      ..._roleOrder.where(grouped.containsKey),
      ...grouped.keys.where((k) => !_roleOrder.contains(k)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Color(0xFF2A2A2A)),
        const SizedBox(height: 8),
        const Text('Casting & Équipe',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        ...orderedKeys.map((type) {
          final members = grouped[type]!;
          final isActors = type == 'Actor' || type == 'GuestStar';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _roleLabel(type),
                style: const TextStyle(
                    color: Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              isActors
                  ? ActorRow(actors: members.take(15).toList(), client: client)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: members
                            .map((p) => GestureDetector(
                                  onTap: p.id != null
                                      ? () => context.go('/person/${p.id}',
                                          extra: {'name': p.name, 'role': p.role})
                                      : null,
                                  child: Text(
                                    p.name,
                                    style: TextStyle(
                                      color: p.id != null
                                          ? Colors.white
                                          : const Color(0xFF888888),
                                      fontSize: 15,
                                      decoration: p.id != null
                                          ? TextDecoration.underline
                                          : null,
                                      decorationColor: const Color(0xFF555555),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }
}

class ActorRow extends StatelessWidget {
  final List<JellyPerson> actors;
  final dynamic client;

  const ActorRow({super.key, required this.actors, required this.client});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        padding: const EdgeInsets.only(bottom: 8),
        itemBuilder: (_, i) {
          final actor = actors[i];
          final photoUrl = actor.id != null
              ? client.getImageUrl(itemId: actor.id!, type: 'Primary', maxWidth: 180)
              : null;
          return GestureDetector(
            onTap: actor.id != null
                ? () => context.go('/person/${actor.id}',
                    extra: {'name': actor.name, 'role': actor.role})
                : null,
            child: SizedBox(
              width: 94,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(46),
                    child: photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    actor.name,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (actor.role?.isNotEmpty == true)
                    Text(
                      actor.role!,
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 88,
        height: 88,
        color: const Color(0xFF2A2A2A),
        child: const Icon(Icons.person_outline, color: Color(0xFF555555), size: 40),
      );
}
