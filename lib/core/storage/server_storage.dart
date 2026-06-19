import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/models/jellyfin_models.dart';

const _kServers = 'jelly_servers';
const _kActiveServerId = 'jelly_active_server';
const _kTokenPrefix = 'jelly_token_';
const _kKnownServers = 'jelly_known_servers';
const _kLastServerId = 'jelly_last_server';
const _kLastLoginPrefix = 'jelly_lastlogin_';

/// Durée pendant laquelle un compte reste connecté sans redemander le mot de
/// passe (fenêtre glissante : réarmée à chaque connexion).
const kSessionWindow = Duration(hours: 24);

/// Normalise une URL de serveur (sans slash final).
String normalizeServerUrl(String url) =>
    url.trim().replaceAll(RegExp(r'/+$'), '');

/// Un serveur connu = URL + nom, indépendant de tout compte/token.
class KnownServer {
  final String id; // = URL normalisée (unique par serveur)
  final String url;
  final String name;

  const KnownServer({required this.id, required this.url, required this.name});

  factory KnownServer.fromUrl(String url, {String? name}) {
    final u = normalizeServerUrl(url);
    return KnownServer(id: u, url: u, name: name ?? u);
  }

  factory KnownServer.fromJson(Map<String, dynamic> j) => KnownServer(
        id: j['id'] as String,
        url: j['url'] as String,
        name: j['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'url': url, 'name': name};
}

class ServerStorage {
  late final SharedPreferences _prefs;
  final _secure = const FlutterSecureStorage();
  String _deviceId = 'jellyclient-unknown';

  // Cache mémoire des tokens (jamais écrits en clair sur disque).
  final Map<String, String> _tokens = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTokens();
    _migrateKnownServersFromProfiles();
  }

  /// Charge les tokens depuis le coffre sécurisé, et MIGRE les anciens tokens
  /// stockés en clair dans les préférences vers le coffre (puis les efface).
  Future<void> _loadTokens() async {
    final raw = _prefs.getStringList(_kServers) ?? [];
    if (raw.isEmpty) return;
    var rewrite = false;
    final cleaned = <String>[];
    for (final s in raw) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      final id = map['id'] as String?;
      if (id == null) {
        cleaned.add(s);
        continue;
      }
      final inJson = (map['accessToken'] as String?) ?? '';
      final secure = await _secure.read(key: '$_kTokenPrefix$id') ?? '';
      final token = secure.isNotEmpty ? secure : inJson;
      if (token.isNotEmpty) {
        _tokens[id] = token;
        if (secure.isEmpty) {
          await _secure.write(key: '$_kTokenPrefix$id', value: token);
        }
      }
      if (inJson.isNotEmpty) {
        map['accessToken'] = ''; // ne jamais conserver le token en clair
        rewrite = true;
      }
      cleaned.add(jsonEncode(map));
    }
    if (rewrite) await _prefs.setStringList(_kServers, cleaned);
  }

  void setDeviceId(String id) => _deviceId = id;
  String get deviceId => _deviceId;

  // ─── Comptes (server + user + token) ────────────────────────────────────

  List<ServerProfile> getServers() {
    final raw = _prefs.getStringList(_kServers) ?? [];
    return raw.map((s) {
      final p = ServerProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);
      // Le token vient du cache (coffre sécurisé), jamais des préférences.
      return p.copyWith(accessToken: _tokens[p.id] ?? '');
    }).toList();
  }

  // Sérialise SANS le token (jamais écrit en clair dans les préférences).
  String _encodeWithoutToken(ServerProfile s) =>
      jsonEncode(s.copyWith(accessToken: '').toJson());

  Future<void> saveServer(ServerProfile server) async {
    _tokens[server.id] = server.accessToken;
    await _secure.write(key: '$_kTokenPrefix${server.id}', value: server.accessToken);
    final servers = getServers();
    final idx = servers.indexWhere((s) => s.id == server.id);
    if (idx >= 0) {
      servers[idx] = server;
    } else {
      servers.add(server);
    }
    await _prefs.setStringList(
      _kServers,
      servers.map(_encodeWithoutToken).toList(),
    );
    // S'assurer que le serveur est aussi enregistré comme serveur connu.
    await saveKnownServer(KnownServer.fromUrl(server.url, name: server.name));
  }

  Future<void> deleteServer(String serverId) async {
    _tokens.remove(serverId);
    final servers = getServers()..removeWhere((s) => s.id == serverId);
    await _prefs.setStringList(
      _kServers,
      servers.map(_encodeWithoutToken).toList(),
    );
    await _secure.delete(key: '$_kTokenPrefix$serverId');
    await _prefs.remove('$_kLastLoginPrefix$serverId');
    if (getActiveServerId() == serverId && servers.isNotEmpty) {
      await setActiveServer(servers.first.id);
    }
  }

  /// Comptes enregistrés pour un serveur (par URL).
  List<ServerProfile> getProfilesForServer(String serverUrl) {
    final u = normalizeServerUrl(serverUrl);
    return getServers().where((p) => normalizeServerUrl(p.url) == u).toList();
  }

  // ─── Serveurs connus (URL + nom, sans compte) ───────────────────────────

  List<KnownServer> getKnownServers() {
    final raw = _prefs.getStringList(_kKnownServers) ?? [];
    return raw
        .map((s) => KnownServer.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveKnownServer(KnownServer server) async {
    final list = getKnownServers();
    final idx = list.indexWhere((s) => s.id == server.id);
    if (idx >= 0) {
      list[idx] = server;
    } else {
      list.add(server);
    }
    await _prefs.setStringList(
      _kKnownServers,
      list.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  Future<void> deleteKnownServer(String id) async {
    final list = getKnownServers()..removeWhere((s) => s.id == id);
    await _prefs.setStringList(
      _kKnownServers,
      list.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }

  /// Backfill : dérive les serveurs connus depuis les comptes déjà enregistrés.
  void _migrateKnownServersFromProfiles() {
    final known = getKnownServers();
    final knownIds = known.map((k) => k.id).toSet();
    final toAdd = <KnownServer>[];
    for (final p in getServers()) {
      final id = normalizeServerUrl(p.url);
      if (!knownIds.contains(id)) {
        knownIds.add(id);
        toAdd.add(KnownServer.fromUrl(p.url, name: p.name));
      }
    }
    if (toAdd.isNotEmpty) {
      final all = [...known, ...toAdd];
      _prefs.setStringList(
        _kKnownServers,
        all.map((s) => jsonEncode(s.toJson())).toList(),
      );
    }
  }

  // ─── Dernier serveur utilisé (défaut de la page de login) ───────────────

  String? getLastServerId() => _prefs.getString(_kLastServerId);
  Future<void> setLastServerId(String id) =>
      _prefs.setString(_kLastServerId, id);

  KnownServer? getLastOrFirstKnownServer() {
    final list = getKnownServers();
    if (list.isEmpty) return null;
    final lastId = getLastServerId();
    if (lastId != null) {
      for (final s in list) {
        if (s.id == lastId) return s;
      }
    }
    return list.first;
  }

  // ─── Fenêtre de session 24 h (par compte) ───────────────────────────────

  DateTime? getLastLoginAt(String profileId) {
    final raw = _prefs.getString('$_kLastLoginPrefix$profileId');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> markLogin(String profileId) =>
      _prefs.setString('$_kLastLoginPrefix$profileId',
          DateTime.now().toIso8601String());

  Future<void> clearLogin(String profileId) =>
      _prefs.remove('$_kLastLoginPrefix$profileId');

  /// Vrai si le compte a une session valide (< 24 h) → connexion 1 clic.
  bool hasValidSession(String profileId) {
    final last = getLastLoginAt(profileId);
    if (last == null) return false;
    return DateTime.now().difference(last) < kSessionWindow;
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
    return _tokens[serverId] ?? await _secure.read(key: '$_kTokenPrefix$serverId');
  }

  // ─── UI Preferences ───────────────────────────────────────────────────

  int getCardSize() => _prefs.getInt('jelly_card_size') ?? 1;

  Future<void> setCardSize(int size) =>
      _prefs.setInt('jelly_card_size', size);
}
