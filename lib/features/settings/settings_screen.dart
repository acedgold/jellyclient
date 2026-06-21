import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/external_player.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerCtrl = useTextEditingController();
    final saved = useState(false);
    final langSaved = useState(false);
    final audioLang = useState<String?>(null);
    final subLang = useState<String?>(null);

    useEffect(() {
      // Lire userId ici pour garantir la valeur à jour au montage
      final uid = ref.read(activeServerProvider)?.userId ?? '';
      getExternalPlayer().then((v) => playerCtrl.text = v);
      if (uid.isNotEmpty) {
        getPreferredAudioLang(uid).then((v) => audioLang.value = v);
        getPreferredSubLang(uid).then((v) => subLang.value = v);
      }
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ─── Préférences de lecture ───────────────────────────────
          Text('Préférences de lecture',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Sélectionné automatiquement à chaque lancement. Si la langue est absente du fichier, la piste par défaut est utilisée (audio) ou aucun sous-titre n\'est affiché.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),

          // Audio
          const Text('Langue audio',
              style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // "Aucune préférence" = null
              _LangChip(
                label: 'Automatique',
                selected: audioLang.value == null,
                onTap: () {
                  audioLang.value = null;
                  langSaved.value = false;
                },
              ),
              ...kLanguages.map((l) => _LangChip(
                    label: l.$1,
                    selected: audioLang.value == l.$2,
                    onTap: () {
                      audioLang.value = l.$2;
                      langSaved.value = false;
                    },
                  )),
            ],
          ),
          const SizedBox(height: 24),

          // Sous-titres
          const Text('Sous-titres',
              style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _LangChip(
                label: 'Aucun',
                selected: subLang.value == null,
                color: const Color(0xFF444444),
                onTap: () {
                  subLang.value = null;
                  langSaved.value = false;
                },
              ),
              ...kLanguages.map((l) => _LangChip(
                    label: l.$1,
                    selected: subLang.value == l.$2,
                    onTap: () {
                      subLang.value = l.$2;
                      langSaved.value = false;
                    },
                  )),
            ],
          ),

          // ─── Bouton enregistrer les préférences ───────────────────
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final uid = ref.read(activeServerProvider)?.userId ?? '';
              if (uid.isEmpty) return;
              await setPreferredAudioLang(uid, audioLang.value);
              await setPreferredSubLang(uid, subLang.value);
              langSaved.value = true;
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Enregistrer les préférences'),
          ),
          if (langSaved.value) ...[
            const SizedBox(height: 10),
            Builder(builder: (context) {
              final aLabel = audioLang.value == null
                  ? 'Automatique'
                  : kLanguages
                      .firstWhere((l) => l.$2 == audioLang.value,
                          orElse: () => ('?', ''))
                      .$1;
              final sLabel = subLang.value == null
                  ? 'Aucun'
                  : kLanguages
                      .firstWhere((l) => l.$2 == subLang.value,
                          orElse: () => ('?', ''))
                      .$1;
              return Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Enregistré · Audio : $aLabel · ST : $sLabel',
                    style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12),
                  ),
                ],
              );
            }),
          ],

          // ─── Lecteur externe ──────────────────────────────────────
          const SizedBox(height: 40),
          const Divider(color: Color(0xFF2A2A2A)),
          const SizedBox(height: 20),
          Text('Lecteur externe',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Commande ou chemin complet du lecteur utilisé pour lire les vidéos.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              // Raccourcis selon la plateforme
              if (Platform.isLinux) ...['vlc', 'mpv', 'celluloid', 'totem'],
              if (Platform.isWindows) ...[
                r'C:\Program Files\VideoLAN\VLC\vlc.exe',
                r'vlc\vlc.exe',
              ],
              if (Platform.isMacOS) ...['vlc', 'iina', 'mpv'],
            ].map((p) {
              final label = Platform.isWindows
                  ? p.split(r'\').last  // affiche juste 'vlc.exe'
                  : p;
              return ActionChip(
                label: Text(label),
                tooltip: p,
                backgroundColor: const Color(0xFF2A2A2A),
                labelStyle:
                    const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12),
                side: BorderSide.none,
                onPressed: () {
                  playerCtrl.text = p;
                  saved.value = false;
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: playerCtrl,
            decoration: InputDecoration(
              labelText: 'Lecteur',
              hintText: Platform.isWindows
                  ? r'C:\Program Files\VideoLAN\VLC\vlc.exe'
                  : 'vlc',
              prefixIcon: const Icon(Icons.play_circle_outline),
            ),
            autocorrect: false,
            onChanged: (_) => saved.value = false,
          ),
          const SizedBox(height: 8),
          Text(
            Platform.isWindows
                ? r'Chemin complet requis — ex: C:\Program Files\VideoLAN\VLC\vlc.exe'
                    '\nOu VLC portable : vlc\vlc.exe (relatif à l\'exe)'
                : 'Exemples : vlc · mpv · /usr/bin/vlc · /snap/bin/vlc',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final val = playerCtrl.text.trim();
              if (val.isEmpty) return;
              await setExternalPlayer(val);
              saved.value = true;
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Enregistrer'),
          ),
          if (saved.value) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                SizedBox(width: 6),
                Text('Enregistré',
                    style: TextStyle(color: Color(0xFF4CAF50), fontSize: 13)),
              ],
            ),
          ],

          // ─── Application ──────────────────────────────────────────
          const SizedBox(height: 40),
          const Divider(color: Color(0xFF2A2A2A)),
          const SizedBox(height: 20),
          Text('Application', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (!Platform.isIOS)
            OutlinedButton.icon(
              onPressed: () async {
                if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
                  final exe = Platform.resolvedExecutable;
                  await Process.start(exe, [], mode: ProcessStartMode.detached);
                  exit(0);
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Redémarrer JellyClient'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Color(0xFF444444)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Chip langue ──────────────────────────────────────────────────────────────

class _LangChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (color ?? Theme.of(context).colorScheme.primary)
              : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? null
              : Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFAAAAAA),
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
