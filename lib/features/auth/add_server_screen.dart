import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/jellyfin_client.dart';
import '../../core/api/models/jellyfin_models.dart';
import '../../core/providers/app_providers.dart';

class AddServerScreen extends HookConsumerWidget {
  const AddServerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlCtrl = useTextEditingController(text: 'https://');
    final userCtrl = useTextEditingController();
    final passCtrl = useTextEditingController();
    final loading = useState(false);
    final error = useState<String?>(null);

    Future<void> connect() async {
      error.value = null;
      final url = urlCtrl.text.trim().replaceAll(RegExp(r'/$'), '');
      if (url.isEmpty || userCtrl.text.isEmpty || passCtrl.text.isEmpty) {
        error.value = 'Tous les champs sont requis';
        return;
      }
      loading.value = true;
      try {
        final tmpClient = JellyfinClient(baseUrl: url);
        final auth = await tmpClient.authenticate(
          username: userCtrl.text.trim(),
          password: passCtrl.text,
        );
        final server = ServerProfile(
          id: auth.serverId,
          name: auth.serverName,
          url: url,
          userId: auth.userId,
          accessToken: auth.accessToken,
          username: auth.username,
        );
        final storage = ref.read(serverStorageProvider);
        await storage.saveServer(server);
        await storage.setActiveServer(server.id);
        ref.read(serversProvider.notifier).state = storage.getServers();
        ref.read(activeServerProvider.notifier).state = server;
        if (context.mounted) context.go('/home');
      } on Exception catch (e) {
        error.value = 'Connexion échouée : ${e.toString()}';
      } finally {
        loading.value = false;
      }
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Logo(),
                const SizedBox(height: 48),
                Text(
                  'Ajouter un serveur',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL du serveur',
                    hintText: 'https://jellyfin.example.com',
                    prefixIcon: Icon(Icons.dns_outlined),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom d\'utilisateur',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  onSubmitted: (_) => connect(),
                ),
                if (error.value != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error.value!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: loading.value ? null : connect,
                  child: loading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Se connecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 12),
        Text(
          'JellyClient',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                letterSpacing: -0.5,
              ),
        ),
      ],
    );
  }
}
