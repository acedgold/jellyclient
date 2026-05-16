import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/watchlist_storage.dart';
import 'app_providers.dart';

final watchlistStorageProvider = Provider<WatchlistStorage>((ref) {
  throw UnimplementedError('init via ProviderScope overrides');
});

// ─── Watchlist ────────────────────────────────────────────────────────────────

final watchlistProvider = StateProvider<List<WatchlistItem>>((ref) {
  final storage = ref.read(watchlistStorageProvider);
  final server = ref.read(activeServerProvider);
  if (server == null) return [];
  return storage.getWatchlist(server.userId);
});

// ─── Déjà vu ─────────────────────────────────────────────────────────────────

final seenProvider = StateProvider<List<WatchlistItem>>((ref) {
  final storage = ref.read(watchlistStorageProvider);
  final server = ref.read(activeServerProvider);
  if (server == null) return [];
  return storage.getSeen(server.userId);
});

// ─── Actions ──────────────────────────────────────────────────────────────────

Future<void> toggleWatchlist(WidgetRef ref, WatchlistItem item) async {
  final storage = ref.read(watchlistStorageProvider);
  final server = ref.read(activeServerProvider);
  if (server == null) return;
  await storage.toggleWatchlist(server.userId, item);
  ref.read(watchlistProvider.notifier).state =
      storage.getWatchlist(server.userId);
}

Future<void> toggleSeen(WidgetRef ref, WatchlistItem item) async {
  final storage = ref.read(watchlistStorageProvider);
  final server = ref.read(activeServerProvider);
  if (server == null) return;
  await storage.toggleSeen(server.userId, item);
  ref.read(seenProvider.notifier).state = storage.getSeen(server.userId);
}
