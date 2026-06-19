import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/api/jellyfin_client.dart';
import '../../core/api/models/jellyfin_models.dart';
import '../../core/providers/app_providers.dart';

class ServersScreen extends ConsumerWidget {
  const ServersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(serversProvider);
    final activeId = ref.watch(activeServerProvider)?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Bouton retour discret ────────────────────────────────
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: Color(0xFF666666)),
                onPressed: () => context.go('/home'),
              ),
            ),

            // ─── Header centré ────────────────────────────────────────
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFE50914),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'J',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'JellyClient',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ref.watch(appVersionProvider).maybeWhen(
                    data: (v) => 'Version $v',
                    orElse: () => '',
                  ),
              style: const TextStyle(
                color: Color(0xFFE50914),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sélectionner un serveur Jellyfin',
              style: TextStyle(color: Color(0xFF888888), fontSize: 14),
            ),
            const SizedBox(height: 32),

            // ─── Liste des serveurs ───────────────────────────────────
            Expanded(
              child: servers.isEmpty
                  ? _EmptyState(onAdd: () => context.go('/add-server'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: servers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final s = servers[i];
                        return _ServerCard(
                          server: s,
                          isActive: s.id == activeId,
                        );
                      },
                    ),
            ),

            // ─── Bouton Ajouter ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_box_outlined, size: 18),
                  label: const Text('Ajouter un serveur'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0xFF333333)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => context.go('/add-server'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Carte serveur ────────────────────────────────────────────────────────────

class _ServerCard extends ConsumerStatefulWidget {
  final ServerProfile server;
  final bool isActive;

  const _ServerCard({required this.server, required this.isActive});

  @override
  ConsumerState<_ServerCard> createState() => _ServerCardState();
}

class _ServerCardState extends ConsumerState<_ServerCard> {
  bool _testing = false;
  bool? _pingOk;
  double? _speedMBps;

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _pingOk = null;
      _speedMBps = null;
    });
    final result = await JellyfinClient.testServer(
        widget.server.url, widget.server.accessToken);
    if (mounted) {
      setState(() {
        _testing = false;
        _pingOk = result.ok;
        _speedMBps = result.speedMBps;
      });
    }
  }

  Color get _dotColor {
    if (_pingOk == true) return const Color(0xFF4CAF50);
    if (_pingOk == false) return const Color(0xFFE53935);
    return const Color(0xFF555555);
  }

  String get _statusLabel {
    if (widget.isActive) return 'Actif';
    if (_pingOk == true) return 'Accessible';
    if (_pingOk == false) return 'Erreur';
    return 'Inconnu';
  }

  Color get _statusColor {
    if (widget.isActive) return const Color(0xFFE50914);
    if (_pingOk == true) return const Color(0xFF4CAF50);
    if (_pingOk == false) return const Color(0xFFE53935);
    return const Color(0xFF666666);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isActive
            ? const Color(0xFF1C1010)
            : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: widget.isActive
            ? Border.all(color: const Color(0xFF3A1010), width: 1)
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Ligne 1 : pastille + URL + badge statut ──────────────
          Row(
            children: [
              // Pastille état (avec spinner si test en cours)
              _testing
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF888888)),
                    )
                  : Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.server.url,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Badge statut
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _statusColor.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          // Nom d'utilisateur (discret)
          if (widget.server.username.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Text(
                widget.server.username,
                style: const TextStyle(
                    color: Color(0xFF666666), fontSize: 12),
              ),
            ),
          ],

          // Débit affiché après test réussi
          if (_pingOk == true && _speedMBps != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Row(
                children: [
                  const Icon(Icons.download_rounded,
                      size: 12, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 4),
                  Text(
                    '${_speedMBps!.toStringAsFixed(1)} MB/s',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_pingOk == true && _speedMBps == null && !_testing) ...[
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.only(left: 24),
              child: Text(
                'Débit non mesurable (catalogue vide ?)',
                style:
                    TextStyle(color: Color(0xFF666666), fontSize: 11),
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          const SizedBox(height: 12),

          // ─── Ligne 2 : actions ────────────────────────────────────
          Row(
            children: [
              // Se connecter
              _PillButton(
                label: 'Se connecter',
                primary: true,
                onPressed: () async {
                  final storage = ref.read(serverStorageProvider);
                  await storage.setActiveServer(widget.server.id);
                  ref.read(activeServerProvider.notifier).state =
                      widget.server;
                  if (context.mounted) context.go('/home');
                },
              ),
              const SizedBox(width: 8),
              // Tester
              _PillButton(
                label: 'Tester',
                primary: false,
                onPressed: _testing ? null : _testConnection,
              ),
              const Spacer(),
              // Retirer
              GestureDetector(
                onTap: () async {
                  final storage = ref.read(serverStorageProvider);
                  await storage.deleteServer(widget.server.id);
                  ref.read(serversProvider.notifier).state =
                      storage.getServers();
                  final newActive = storage.getActiveServer();
                  ref.read(activeServerProvider.notifier).state = newActive;
                  if (context.mounted && newActive == null) {
                    context.go('/add-server');
                  }
                },
                child: const Text(
                  'Retirer',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bouton pill ──────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback? onPressed;

  const _PillButton({
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: primary ? Colors.white : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: primary ? Colors.black : const Color(0xFFAAAAAA),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── État vide ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dns_outlined,
              size: 56, color: Color(0xFF333333)),
          const SizedBox(height: 16),
          const Text(
            'Aucun serveur configuré',
            style: TextStyle(color: Color(0xFF666666), fontSize: 15),
          ),
          const SizedBox(height: 20),
          _PillButton(
              label: 'Ajouter un serveur',
              primary: true,
              onPressed: onAdd),
        ],
      ),
    );
  }
}
