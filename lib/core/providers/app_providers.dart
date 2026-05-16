import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/jellyfin_client.dart';
import '../api/models/jellyfin_models.dart';
import '../storage/server_storage.dart';

// ─── Storage ──────────────────────────────────────────────────────────────

final serverStorageProvider = Provider<ServerStorage>((ref) {
  throw UnimplementedError('init via ProviderScope overrides');
});

// ─── Active server ────────────────────────────────────────────────────────

final activeServerProvider = StateProvider<ServerProfile?>((ref) {
  final storage = ref.read(serverStorageProvider);
  return storage.getActiveServer();
});

// ─── Jellyfin API client ──────────────────────────────────────────────────

final jellyfinClientProvider = Provider<JellyfinClient>((ref) {
  final server = ref.watch(activeServerProvider);
  final storage = ref.read(serverStorageProvider);
  final client = JellyfinClient(baseUrl: server?.url ?? '');
  if (server != null) {
    client.setToken(server.accessToken);
    client.setDeviceId(storage.deviceId);
  }
  return client;
});

// ─── All servers ──────────────────────────────────────────────────────────

final serversProvider = StateProvider<List<ServerProfile>>((ref) {
  final storage = ref.read(serverStorageProvider);
  return storage.getServers();
});

// ─── Card size (0=petit 1=moyen 2=grand) ──────────────────────────────────

final cardSizeProvider = StateProvider<int>((ref) {
  return ref.read(serverStorageProvider).getCardSize();
});
