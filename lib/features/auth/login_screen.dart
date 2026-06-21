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
    // Persiste le profil + le token frais (coffre sécurisé). Sans ça, le token
    // ne vivait qu'en mémoire et la session « 24 h » réutilisait un token périmé
    // au relaunch → /home vide.
    await storage.saveServer(profile);
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
    if (existing != null &&
        storage.hasValidSession(existing.id) &&
        existing.accessToken.isNotEmpty) {
      // Session < 24 h : on vérifie d'abord que le token est toujours accepté
      // (il a pu être révoqué côté serveur), sinon /home s'ouvrirait vide.
      final client = JellyfinClient(baseUrl: server.url)
        ..setToken(existing.accessToken);
      if (await client.validateToken()) {
        await _activateProfile(existing, server); // entrée directe
        if (mounted) context.go('/home');
        return;
      }
      // Token mort → on oublie la session et on redemande le mot de passe.
      await storage.clearLogin(existing.id);
    }
    // Toujours passer par la fenêtre de connexion — jamais de connexion
    // silencieuse, même si le compte n'a pas de mot de passe côté serveur.
    // (Un compte sans mot de passe valide quand même avec un champ vide :
    // la sécurité réelle de ces comptes doit être posée côté serveur.)
    if (mounted) await _showLoginDialog(server, presetUsername: username);
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
    // Échelle responsive : tout (police, espacements, avatars) se met à
    // l'échelle selon la largeur de la fenêtre.
    final scale =
        (MediaQuery.sizeOf(context).width / 1100).clamp(0.72, 1.55);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 40 * scale),
            Text(
              'JellyClient',
              style: TextStyle(
                color: const Color(0xFFE50914),
                fontSize: 32 * scale,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text('Qui se connecte ?',
                style: TextStyle(color: Colors.white70, fontSize: 18 * scale)),
            SizedBox(height: 10 * scale),
            // Nom du serveur courant (information)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dns_outlined,
                    size: 18 * scale, color: const Color(0xFFAAAAAA)),
                SizedBox(width: 8 * scale),
                Text(
                  _hostOf(server.name),
                  style: TextStyle(
                    color: const Color(0xFFDDDDDD),
                    fontSize: 17 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            // Bouton explicite pour changer de serveur (ouvre le pop-up)
            TextButton.icon(
              onPressed: _showServerPicker,
              icon: Icon(Icons.swap_horiz_rounded,
                  size: 18 * scale, color: const Color(0xFFE50914)),
              label: Text('Changer de serveur',
                  style: TextStyle(
                      color: const Color(0xFFE50914), fontSize: 13 * scale)),
            ),
            SizedBox(height: 16 * scale),
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
                    scale: scale,
                    onTap: _onAvatarTap,
                  );
                },
              ),
            ),
            // Bouton connexion manuelle (comptes cachés)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 18 * scale),
              child: TextButton.icon(
                onPressed: () => _showLoginDialog(server),
                icon: Icon(Icons.password_rounded,
                    size: 18 * scale, color: Colors.white60),
                label: Text('Connexion manuelle',
                    style:
                        TextStyle(color: Colors.white60, fontSize: 14 * scale)),
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
  final double scale;
  final void Function(KnownServer, String userId, String username) onTap;

  const _UsersGrid({
    required this.users,
    required this.server,
    required this.storage,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final n = users.length;
      // Taille de tuile cible : plus il y a d'utilisateurs, plus elles sont
      // compactes. Mise à l'échelle selon l'écran, et bornée par la largeur
      // (toujours ≥ 2 colonnes).
      final pad = 32 * scale;
      final width = constraints.maxWidth - pad * 2;
      double extent = (n <= 4
              ? 170
              : n <= 12
                  ? 145
                  : n <= 24
                      ? 120
                      : 100) *
          scale;
      final maxExtent = width > 0 ? (width / 2) : extent;
      extent = extent.clamp(78.0, maxExtent < 78.0 ? 78.0 : maxExtent);

      return GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: pad),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: extent,
          childAspectRatio: 0.78,
          crossAxisSpacing: 18 * scale,
          mainAxisSpacing: 18 * scale,
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
            avatarUrl:
                '${server.url}/Users/$userId/Images/Primary?maxWidth=200',
            remembered: remembered,
            onTap: () => onTap(server, userId, name),
          );
        },
      );
    });
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
    // Tout est relatif à la largeur de la cellule → l'avatar et le nom
    // grossissent/rétrécissent avec la grille.
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final labelSize = (w * 0.14).clamp(10.0, 18.0);
      final radius = (w * 0.08).clamp(6.0, 14.0);
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: remembered
                          ? Border.all(
                              color: const Color(0xFFE50914),
                              width: (w * 0.025).clamp(2.0, 4.0))
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radius),
                      child: CachedNetworkImage(
                        imageUrl: avatarUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: _colorFromName(name),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: w * 0.4,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Pastille "session active" (connexion 1 clic)
                if (remembered)
                  Positioned(
                    right: w * 0.05,
                    top: w * 0.05,
                    child: Icon(Icons.flash_on_rounded,
                        color: const Color(0xFFE50914),
                        size: (w * 0.17).clamp(14.0, 24.0)),
                  ),
              ],
            ),
            SizedBox(height: w * 0.07),
            Flexible(
              child: Text(
                name,
                style: TextStyle(color: Colors.white70, fontSize: labelSize),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    });
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
    final host = server.name.contains('://')
        ? (Uri.tryParse(server.name)?.host ?? server.name)
        : server.name;
    final initial =
        (presetUsername != null && presetUsername!.isNotEmpty)
            ? presetUsername![0].toUpperCase()
            : '';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF181818),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2C2C2C)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête : avatar (initiale) ou cadenas
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: manual
                      ? const LinearGradient(
                          colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            _colorFromName(presetUsername ?? ''),
                            _colorFromName(presetUsername ?? '')
                                .withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: Border.all(
                      color: const Color(0xFFE50914).withValues(alpha: 0.4),
                      width: 1.5),
                ),
                child: manual
                    ? const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFFE50914), size: 30)
                    : Text(
                        initial.isEmpty ? '?' : initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                manual ? 'Connexion manuelle' : presetUsername!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.dns_outlined,
                      size: 13, color: Color(0xFF777777)),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF999999), fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _ManualForm(
                presetUsername: presetUsername,
                lockUsername: !manual,
                showCancel: true,
                onSubmit: (u, p) async {
                  await onSubmit(u, p);
                  // _authenticate navigue vers /home en cas de succès ; en
                  // cas d'échec, _ManualForm affiche l'erreur et la boîte
                  // reste ouverte.
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Formulaire (login + mot de passe), réutilisé inline et en dialogue ─────

class _ManualForm extends StatefulWidget {
  final String? presetUsername;
  final bool lockUsername;
  final String? title;
  final bool showCancel; // affiche un bouton « Annuler » (contexte dialogue)
  final Future<void> Function(String username, String password) onSubmit;

  const _ManualForm({
    required this.onSubmit,
    this.presetUsername,
    this.lockUsername = false,
    this.title,
    this.showCancel = false,
  });

  @override
  State<_ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<_ManualForm> {
  late final TextEditingController _userCtrl;
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
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
    if (_userCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nom d\'utilisateur requis');
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

  InputDecoration _dec(String label, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF888888)),
      prefixIcon: Icon(icon, color: const Color(0xFF888888), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF222222),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: border(const Color(0xFF333333)),
      focusedBorder: border(const Color(0xFFE50914), 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.title != null) ...[
          Text(widget.title!,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
        ],
        if (!widget.lockUsername) ...[
          TextField(
            controller: _userCtrl,
            autocorrect: false,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Nom d\'utilisateur', Icons.person_outline),
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _passCtrl,
          obscureText: _obscure,
          autofocus: widget.lockUsername,
          style: const TextStyle(color: Colors.white),
          decoration: _dec(
            'Mot de passe',
            Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF888888),
                size: 20,
              ),
              splashRadius: 20,
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFE53935).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFE57373), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!,
                      style: const TextStyle(
                          color: Color(0xFFE57373), fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            if (widget.showCancel) ...[
              Expanded(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFAAAAAA),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: widget.showCancel ? 2 : 1,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  disabledBackgroundColor:
                      const Color(0xFFE50914).withValues(alpha: 0.5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Se connecter',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
