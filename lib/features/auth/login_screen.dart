import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/jellyfin_client.dart';
import '../../core/api/models/jellyfin_models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/storage/server_storage.dart';

// Utilisateurs publics d'un serveur (par URL) — sans authentification.
final _publicUsersProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, url) => JellyfinClient(baseUrl: url).getPublicUsers(),
);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  KnownServer? _server;

  @override
  void initState() {
    super.initState();
    _server = ref.read(serverStorageProvider).getLastOrFirstKnownServer();
  }

  // ─── Connexion ──────────────────────────────────────────────────────────

  // Active le compte sans navigation (l'appelant navigue ensuite).
  Future<void> _activateProfile(ServerProfile profile, KnownServer server) async {
    final storage = ref.read(serverStorageProvider);
    await storage.markLogin(profile.id);
    await storage.setActiveServer(profile.id);
    await storage.setLastServerId(server.id);
    ref.read(serversProvider.notifier).state = storage.getServers();
    ref.read(activeServerProvider.notifier).state = profile;
  }

  // Authentifie (login + mot de passe) sans navigation. Lève en cas d'échec.
  Future<void> _authenticate(
      KnownServer server, String username, String password) async {
    final client = JellyfinClient(baseUrl: server.url);
    final auth = await client.authenticate(username: username, password: password);
    final profile = ServerProfile(
      id: '${normalizeServerUrl(server.url)}::${auth.userId}',
      name: server.name,
      url: server.url,
      userId: auth.userId,
      accessToken: auth.accessToken,
      username: auth.username,
    );
    await _activateProfile(profile, server);
  }

  Future<void> _onAvatarTap(
      KnownServer server, String userId, String username) async {
    final storage = ref.read(serverStorageProvider);
    final existing = storage
        .getProfilesForServer(server.url)
        .where((p) => p.userId == userId)
        .firstOrNull;
    if (existing != null && storage.hasValidSession(existing.id)) {
      await _activateProfile(existing, server); // < 24 h → entrée directe
      if (mounted) context.go('/home');
    } else {
      await _showLoginDialog(server, presetUsername: username);
    }
  }

  // ─── Dialogue connexion (mot de passe avatar OU connexion manuelle) ───────

  Future<void> _showLoginDialog(KnownServer server,
      {String? presetUsername}) async {
    final manual = presetUsername == null;
    final success = await showDialog<bool>(
      context: context,
      builder: (dctx) => _LoginDialog(
        server: server,
        presetUsername: presetUsername,
        manual: manual,
        onSubmit: (u, p) async {
          await _authenticate(server, u, p); // lève si échec
          if (dctx.mounted) Navigator.pop(dctx, true); // succès → ferme
        },
      ),
    );
    if (success == true && mounted) context.go('/home');
  }

  // ─── Changer de serveur ───────────────────────────────────────────────────

  Future<void> _showServerPicker() async {
    final storage = ref.read(serverStorageProvider);
    final servers = storage.getKnownServers();
    final chosen = await showDialog<KnownServer>(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Choisir un serveur',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        children: [
          ...servers.map((s) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, s),
                child: Row(
                  children: [
                    Icon(Icons.dns_outlined,
                        size: 18,
                        color: s.id == _server?.id
                            ? const Color(0xFFE50914)
                            : Colors.white54),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _hostOf(s.name),
                        style: TextStyle(
                            color: s.id == _server?.id
                                ? Colors.white
                                : Colors.white70),
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(color: Color(0xFF333333)),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              context.go('/add-server');
            },
            child: const Row(
              children: [
                Icon(Icons.add, size: 18, color: Color(0xFFE50914)),
                SizedBox(width: 10),
                Text('Ajouter un serveur',
                    style: TextStyle(color: Color(0xFFE50914))),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen != null && mounted) {
      setState(() => _server = chosen);
      ref.read(serverStorageProvider).setLastServerId(chosen.id);
    }
  }

  static String _hostOf(String s) =>
      s.contains('://') ? (Uri.tryParse(s)?.host ?? s) : s;

  @override
  Widget build(BuildContext context) {
    final server = _server;
    if (server == null) {
      // Aucun serveur connu → renvoyer vers l'ajout de serveur.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/add-server');
      });
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D0D),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final usersAsync = ref.watch(_publicUsersProvider(server.url));

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
            const Text('Qui se connecte ?',
                style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 6),
            // Nom du serveur, cliquable pour changer
            TextButton.icon(
              onPressed: _showServerPicker,
              icon: const Icon(Icons.dns_outlined,
                  size: 14, color: Color(0xFF777777)),
              label: Text(
                _hostOf(server.name),
                style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _emptyOrError(server),
                data: (users) {
                  final visible = users
                      .where((u) => (u['Id'] as String?) != null)
                      .toList();
                  if (visible.isEmpty) return _emptyOrError(server);
                  return _UsersGrid(
                    users: visible,
                    server: server,
                    storage: ref.read(serverStorageProvider),
                    onTap: _onAvatarTap,
                  );
                },
              ),
            ),
            // Bouton connexion manuelle (comptes cachés)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: TextButton.icon(
                onPressed: () => _showLoginDialog(server),
                icon: const Icon(Icons.password_rounded,
                    size: 18, color: Colors.white60),
                label: const Text('Connexion manuelle',
                    style: TextStyle(color: Colors.white60, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Serveur sans utilisateur public (ou injoignable) → formulaire manuel direct.
  Widget _emptyOrError(KnownServer server) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _ManualForm(
            onSubmit: (u, p) async {
              await _authenticate(server, u, p);
              if (mounted) context.go('/home');
            },
            title: 'Connexion',
          ),
        ),
      ),
    );
  }
}

// ─── Grille des utilisateurs publics ──────────────────────────────────────

class _UsersGrid extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final KnownServer server;
  final ServerStorage storage;
  final void Function(KnownServer, String userId, String username) onTap;

  const _UsersGrid({
    required this.users,
    required this.server,
    required this.storage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: 0.78,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final u = users[i];
        final userId = u['Id'] as String;
        final name = (u['Name'] as String?) ?? '';
        final profile = storage
            .getProfilesForServer(server.url)
            .where((p) => p.userId == userId)
            .firstOrNull;
        final remembered =
            profile != null && storage.hasValidSession(profile.id);
        return _UserAvatar(
          name: name,
          avatarUrl: '${server.url}/Users/$userId/Images/Primary?maxWidth=200',
          remembered: remembered,
          onTap: () => onTap(server, userId, name),
        );
      },
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final bool remembered;
  final VoidCallback onTap;

  const _UserAvatar({
    required this.name,
    required this.avatarUrl,
    required this.remembered,
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: remembered
                      ? Border.all(color: const Color(0xFFE50914), width: 2)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(remembered ? 6 : 8),
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
                              fontSize: 38,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Pastille "session active" (connexion 1 clic)
              if (remembered)
                const Positioned(
                  right: 4,
                  top: 4,
                  child: Icon(Icons.flash_on_rounded,
                      color: Color(0xFFE50914), size: 16),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Dialogue de connexion (mot de passe seul, ou login + mot de passe) ─────

class _LoginDialog extends StatelessWidget {
  final KnownServer server;
  final String? presetUsername; // non-null = clic avatar (mot de passe seul)
  final bool manual; // true = login + mot de passe
  final Future<void> Function(String username, String password) onSubmit;

  const _LoginDialog({
    required this.server,
    required this.presetUsername,
    required this.manual,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Text(
        manual ? 'Connexion manuelle' : 'Connexion — ${presetUsername!}',
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      content: _ManualForm(
        presetUsername: presetUsername,
        lockUsername: !manual,
        onSubmit: (u, p) async {
          await onSubmit(u, p);
          // _authenticate navigue vers /home en cas de succès ; en cas d'échec
          // _ManualForm affiche l'erreur et la boîte reste ouverte.
        },
      ),
    );
  }
}

// ─── Formulaire (login + mot de passe), réutilisé inline et en dialogue ─────

class _ManualForm extends StatefulWidget {
  final String? presetUsername;
  final bool lockUsername;
  final String? title;
  final Future<void> Function(String username, String password) onSubmit;

  const _ManualForm({
    required this.onSubmit,
    this.presetUsername,
    this.lockUsername = false,
    this.title,
  });

  @override
  State<_ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<_ManualForm> {
  late final TextEditingController _userCtrl;
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _userCtrl = TextEditingController(text: widget.presetUsername ?? '');
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Identifiant et mot de passe requis');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_userCtrl.text.trim(), _passCtrl.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Connexion échouée — vérifiez vos identifiants';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const enabled = UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF444444)));
    const focused = UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFE50914)));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null) ...[
          Text(widget.title!,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 16),
        ],
        if (!widget.lockUsername)
          TextField(
            controller: _userCtrl,
            autocorrect: false,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Nom d\'utilisateur',
              labelStyle: TextStyle(color: Color(0xFF888888)),
              enabledBorder: enabled,
              focusedBorder: focused,
            ),
          ),
        TextField(
          controller: _passCtrl,
          obscureText: true,
          autofocus: widget.lockUsername,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Mot de passe',
            labelStyle: TextStyle(color: Color(0xFF888888)),
            enabledBorder: enabled,
            focusedBorder: focused,
          ),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!,
              style: const TextStyle(color: Color(0xFFE57373), fontSize: 13)),
        ],
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE50914),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Se connecter',
                  style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
