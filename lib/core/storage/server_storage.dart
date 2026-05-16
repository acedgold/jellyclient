import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/models/jellyfin_models.dart';

const _kServers = 'jelly_servers';
const _kActiveServerId = 'jelly_active_server';
const _kTokenPrefix = 'jelly_token_';

class ServerStorage {
  late final SharedPreferences _prefs;
  final _secure = const FlutterSecureStorage();
  String _deviceId = 'jellyclient-unknown';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void setDeviceId(String id) => _deviceId = id;
  String get deviceId => _deviceId;

  // ─── Servers ──────────────────────────────────────────────────────────

  List<ServerProfile> getServers() {
    final raw = _prefs.getStringList(_kServers) ?? [];
    return raw
        .map((s) => ServerProfile.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveServer(ServerProfile server) async {
    final servers = getServers();
    final idx = servers.indexWhere((s) => s.id == server.id);
    if (idx >= 0) {
      servers[idx] = server;
    } else {
      servers.add(server);
    }
    await _prefs.setStringList(
      _kServers,
      servers.map((s) => jsonEncode(s.toJson())).toList(),
    );
    await _secure.write(key: '$_kTokenPrefix${server.id}', value: server.accessToken);
  }

  Future<void> deleteServer(String serverId) async {
    final servers = getServers()..removeWhere((s) => s.id == serverId);
    await _prefs.setStringList(
      _kServers,
      servers.map((s) => jsonEncode(s.toJson())).toList(),
    );
    await _secure.delete(key: '$_kTokenPrefix$serverId');
    if (getActiveServerId() == serverId && servers.isNotEmpty) {
      await setActiveServer(servers.first.id);
    }
  }

  // ─── Active server ────────────────────────────────────────────────────

  String? getActiveServerId() => _prefs.getString(_kActiveServerId);

  Future<void> setActiveServer(String serverId) async {
    await _prefs.setString(_kActiveServerId, serverId);
  }

  ServerProfile? getActiveServer() {
    final id = getActiveServerId();
    if (id == null) return null;
    final servers = getServers();
    try {
      return servers.firstWhere((s) => s.id == id);
    } catch (_) {
      return servers.isEmpty ? null : servers.first;
    }
  }

  Future<String?> getToken(String serverId) async {
    return _secure.read(key: '$_kTokenPrefix$serverId');
  }

  // ─── UI Preferences ───────────────────────────────────────────────────

  int getCardSize() => _prefs.getInt('jelly_card_size') ?? 1;

  Future<void> setCardSize(int size) =>
      _prefs.setInt('jelly_card_size', size);
}
