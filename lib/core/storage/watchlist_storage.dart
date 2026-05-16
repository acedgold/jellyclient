import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WatchlistItem {
  final String id;
  final String name;
  final String type; // Movie, Series
  final String? seriesId;
  final DateTime addedAt;

  const WatchlistItem({
    required this.id,
    required this.name,
    required this.type,
    this.seriesId,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        if (seriesId != null) 'seriesId': seriesId,
        'addedAt': addedAt.toIso8601String(),
      };

  factory WatchlistItem.fromJson(Map<String, dynamic> j) => WatchlistItem(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String? ?? 'Movie',
        seriesId: j['seriesId'] as String?,
        addedAt: DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class WatchlistStorage {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Clés par userId ──────────────────────────────────────────────────────

  String _watchlistKey(String userId) => 'jc_watchlist_$userId';
  String _seenKey(String userId) => 'jc_seen_$userId';

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<WatchlistItem> _load(String key) {
    final raw = _prefs.getStringList(key) ?? [];
    return raw.map((s) => WatchlistItem.fromJson(jsonDecode(s))).toList();
  }

  Future<void> _save(String key, List<WatchlistItem> items) async {
    await _prefs.setStringList(
      key,
      items.map((i) => jsonEncode(i.toJson())).toList(),
    );
  }

  // ─── Watchlist ────────────────────────────────────────────────────────────

  List<WatchlistItem> getWatchlist(String userId) =>
      _load(_watchlistKey(userId));

  bool isInWatchlist(String userId, String itemId) =>
      _load(_watchlistKey(userId)).any((i) => i.id == itemId);

  Future<void> toggleWatchlist(String userId, WatchlistItem item) async {
    final list = _load(_watchlistKey(userId));
    final idx = list.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.insert(0, item);
    }
    await _save(_watchlistKey(userId), list);
  }

  // ─── Déjà vu ──────────────────────────────────────────────────────────────

  List<WatchlistItem> getSeen(String userId) =>
      _load(_seenKey(userId));

  bool isSeen(String userId, String itemId) =>
      _load(_seenKey(userId)).any((i) => i.id == itemId);

  Future<void> toggleSeen(String userId, WatchlistItem item) async {
    final list = _load(_seenKey(userId));
    final idx = list.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.insert(0, item);
    }
    await _save(_seenKey(userId), list);
  }

  Future<void> removeFromBoth(String userId, String itemId) async {
    final wl = _load(_watchlistKey(userId))..removeWhere((i) => i.id == itemId);
    final sl = _load(_seenKey(userId))..removeWhere((i) => i.id == itemId);
    await _save(_watchlistKey(userId), wl);
    await _save(_seenKey(userId), sl);
  }
}
