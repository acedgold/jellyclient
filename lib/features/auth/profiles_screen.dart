import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/models/jellyfin_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/storage/server_storage.dart';

// ─── Provider : users du serveur actif ───────────────────────────────────────

final _serverUsersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // ref.read (pas watch) — évite la cascade de rebuilds au changement d'utilisateur
  final server = ref.read(activeServerProvider);
  if (server == null) return [];
  return ref.read(jellyfinClientProvider).getServerUsers();
});

// ─── ProfilesScreen ───────────────────────────────────────────────────────────

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeServerProvider);
    final usersAsync = ref.watch(_serverUsersProvider);
    final storage = ref.read(serverStorageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Text(
              'JellyClient',
              style: TextStyle(
                color: Color(0xFFE50914),
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Qui regarde ?',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            if (active != null) ...[
              const SizedBox(height: 6),
              Text(
                active.name.contains('://')
                    ? Uri.tryParse(active.name)?.host ?? active.name
                    : active.name,
                style: const TextStyle(color: Color(0xFF555555), fontSize: 12),
              ),
            ],
            const SizedBox(height: 40),

            // Grille des profils serveur
            Expanded(
              child: usersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => _LocalProfiles(
                    storage: storage,
                    active: active,
                    ref: ref),
                data: (users) {
                  if (users.isEmpty) {
                    return _LocalProfiles(
                        storage: storage, active: active, ref: ref);
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 160,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final user = users[i];
                      final userId = user['Id'] as String? ?? '';
                      final name = user['Name'] as String? ?? '';
                      final isActive = active?.userId == userId;
                      final stored = storage
                          .getServers()
                          .where((p) => p.userId == userId)
                          .firstOrNull;

                      return _ServerUserCard(
                        userId: userId,
                        name: name,
                        serverUrl: active?.url ?? '',
                        isActive: isActive,
                        onTap: () async {
                          if (stored != null) {
                            ref.invalidate(_serverUsersProvider);
                            ref.read(activeServerProvider.notifier).state = stored;
                            await storage.setActiveServer(stored.id);
                            if (context.mounted) context.go('/home');
                          } else {
                            // Pas de credentials → demander le mot de passe
                            if (!context.mounted) return;
                            await _showPasswordDialog(
                                context, ref, storage, active, name, userId);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.go('/servers'),
                    child: const Text('Gérer les comptes',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 14)),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => context.go('/add-server'),
                    child: const Text('+ Ajouter un compte',
                        style:
                            TextStyle(color: Color(0xFFE50914), fontSize: 14)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPasswordDialog(
    BuildContext context,
    WidgetRef ref,
    ServerStorage storage,
    ServerProfile? active,
    String username,
    String userId,
  ) async {
    if (active == null) return;
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Connexion — $username',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Mot de passe',
            hintStyle: TextStyle(color: Color(0xFF666666)),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF444444))),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE50914))),
          ),
          onSubmitted: (_) => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Connexion',
                style: TextStyle(color: Color(0xFFE50914))),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final client = ref.read(jellyfinClientProvider);
      final result = await client.authenticate(
          username: username, password: ctrl.text);
      final profile = ServerProfile(
        id: '${active.url}_${result.userId}',
        name: active.name,
        url: active.url,
        userId: result.userId,
        accessToken: result.accessToken,
        username: result.username,
      );
      await storage.saveServer(profile);
      await storage.setActiveServer(profile.id);
      ref.read(activeServerProvider.notifier).state = profile;
      if (context.mounted) context.go('/home');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red[900],
        ));
      }
    }
  }
}

// ─── Carte user serveur ───────────────────────────────────────────────────────

class _ServerUserCard extends StatelessWidget {
  final String userId;
  final String name;
  final String serverUrl;
  final bool isActive;
  final VoidCallback onTap;

  const _ServerUserCard({
    required this.userId,
    required this.name,
    required this.serverUrl,
    required this.isActive,
    required this.onTap,
  });

  Color _colorFromName(String n) {
    const colors = [
      Color(0xFF1565C0), Color(0xFF2E7D32), Color(0xFF6A1B9A),
      Color(0xFFAD1457), Color(0xFF00695C), Color(0xFFE65100),
    ];
    if (n.isEmpty) return colors[0];
    return colors[n.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = '$serverUrl/Users/$userId/Images/Primary?maxWidth=200';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isActive ? 5 : 8),
              child: CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: _colorFromName(name),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFE50914),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Fallback : profils locaux si serveur inaccessible ───────────────────────

class _LocalProfiles extends StatelessWidget {
  final ServerStorage storage;
  final ServerProfile? active;
  final WidgetRef ref;

  const _LocalProfiles(
      {required this.storage, required this.active, required this.ref});

  @override
  Widget build(BuildContext context) {
    final profiles = storage.getServers();
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 0.75,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: profiles.length,
      itemBuilder: (context, i) {
        final p = profiles[i];
        return _ServerUserCard(
          userId: p.userId,
          name: p.username,
          serverUrl: p.url,
          isActive: active?.id == p.id,
          onTap: () async {
            ref.read(activeServerProvider.notifier).state = p;
            await storage.setActiveServer(p.id);
            if (context.mounted) context.go('/home');
          },
        );
      },
    );
  }
}
