import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/jellyfin_client.dart';
import '../../core/providers/app_providers.dart';
import '../../core/storage/server_storage.dart';

class AddServerScreen extends HookConsumerWidget {
  const AddServerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlCtrl = useTextEditingController(text: 'https://');
    final loading = useState(false);
    final error = useState<String?>(null);

    Future<void> connect() async {
      error.value = null;
      final url = normalizeServerUrl(urlCtrl.text);
      if (url.isEmpty || url == 'https:' || url == 'http:') {
        error.value = 'Saisissez l\'adresse du serveur';
        return;
      }
      loading.value = true;
      try {
        // Vérifie que le serveur répond (endpoint public, sans authentification).
        await JellyfinClient(baseUrl: url).getPublicUsers();
        final storage = ref.read(serverStorageProvider);
        final known = KnownServer.fromUrl(url);
        await storage.saveKnownServer(known);
        await storage.setLastServerId(known.id);
        if (context.mounted) context.go('/login');
      } on Exception catch (_) {
        error.value = 'Serveur injoignable — vérifiez l\'adresse';
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
                const SizedBox(height: 8),
                const Text(
                  'Saisissez l\'adresse de votre serveur Jellyfin. '
                  'Vous choisirez ensuite votre utilisateur.',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 13),
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
                      : const Text('Continuer'),
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
