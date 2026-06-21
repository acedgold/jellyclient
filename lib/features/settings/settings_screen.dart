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

    final version = ref.watch(appVersionProvider).valueOrNull;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: const Text('Paramètres',
            style: TextStyle(fontWeight: FontWeight.w700)),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          // ─── Préférences de lecture ───────────────────────────────
          _SettingsSection(
            icon: Icons.tune_rounded,
            title: 'Préférences de lecture',
            subtitle:
                'Pistes choisies automatiquement à chaque lecture. Si la langue '
                'est absente du fichier, la piste par défaut est utilisée (audio) '
                'ou aucun sous-titre n\'est affiché.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Langue audio'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
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
                const SizedBox(height: 22),
                const _FieldLabel('Sous-titres'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                const SizedBox(height: 22),
                _SaveButton(
                  onPressed: () async {
                    final uid = ref.read(activeServerProvider)?.userId ?? '';
                    if (uid.isEmpty) return;
                    await setPreferredAudioLang(uid, audioLang.value);
                    await setPreferredSubLang(uid, subLang.value);
                    langSaved.value = true;
                  },
                ),
                if (langSaved.value) ...[
                  const SizedBox(height: 12),
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
                    return _SavedHint('Enregistré · Audio : $aLabel · ST : $sLabel');
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── Lecteur externe ──────────────────────────────────────
          _SettingsSection(
            icon: Icons.play_circle_outline_rounded,
            title: 'Lecteur externe',
            subtitle:
                'Commande ou chemin complet du lecteur utilisé pour lire les vidéos.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (Platform.isLinux) ...['vlc', 'mpv', 'celluloid', 'totem'],
                    if (Platform.isWindows) ...[
                      r'C:\Program Files\VideoLAN\VLC\vlc.exe',
                      r'vlc\vlc.exe',
                    ],
                    if (Platform.isMacOS) ...['vlc', 'iina', 'mpv'],
                  ].map((p) {
                    final label = Platform.isWindows ? p.split(r'\').last : p;
                    return ActionChip(
                      label: Text(label),
                      tooltip: p,
                      backgroundColor: const Color(0xFF222222),
                      labelStyle: const TextStyle(
                          color: Color(0xFFCCCCCC), fontSize: 12),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      onPressed: () {
                        playerCtrl.text = p;
                        saved.value = false;
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: playerCtrl,
                  decoration: InputDecoration(
                    labelText: 'Lecteur',
                    hintText: Platform.isWindows
                        ? r'C:\Program Files\VideoLAN\VLC\vlc.exe'
                        : 'vlc',
                    prefixIcon: const Icon(Icons.play_circle_outline),
                    filled: true,
                    fillColor: const Color(0xFF222222),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFFE50914), width: 1.5),
                    ),
                  ),
                  autocorrect: false,
                  onChanged: (_) => saved.value = false,
                ),
                const SizedBox(height: 10),
                Text(
                  Platform.isWindows
                      ? r'Chemin complet requis — ex: C:\Program Files\VideoLAN\VLC\vlc.exe'
                          '\nOu VLC portable : vlc\vlc.exe (relatif à l\'exe)'
                      : 'Exemples : vlc · mpv · /usr/bin/vlc · /snap/bin/vlc',
                  style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
                ),
                const SizedBox(height: 18),
                _SaveButton(
                  label: 'Enregistrer',
                  onPressed: () async {
                    final val = playerCtrl.text.trim();
                    if (val.isEmpty) return;
                    await setExternalPlayer(val);
                    saved.value = true;
                  },
                ),
                if (saved.value) ...[
                  const SizedBox(height: 12),
                  const _SavedHint('Enregistré'),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── Application ──────────────────────────────────────────
          _SettingsSection(
            icon: Icons.info_outline_rounded,
            title: 'Application',
            subtitle: version != null ? 'JellyClient v$version' : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!Platform.isIOS)
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (Platform.isLinux ||
                          Platform.isWindows ||
                          Platform.isMacOS) {
                        final exe = Platform.resolvedExecutable;
                        await Process.start(exe, [],
                            mode: ProcessStartMode.detached);
                        exit(0);
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Redémarrer JellyClient'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Color(0xFF3A3A3A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Carte de section ───────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF242424)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFFE50914), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 12,
                              height: 1.35)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ─── Petits composants ──────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6),
      );
}

class _SaveButton extends StatelessWidget {
  final String label;
  final Future<void> Function() onPressed;
  const _SaveButton({required this.onPressed, this.label = 'Enregistrer les préférences'});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.save_outlined, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE50914),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _SavedHint extends StatelessWidget {
  final String text;
  const _SavedHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12)),
        ),
      ],
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
              : const Color(0xFF222222),
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? null
              : Border.all(color: const Color(0xFF333333)),
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
