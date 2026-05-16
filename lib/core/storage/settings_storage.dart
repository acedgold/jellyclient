import 'package:shared_preferences/shared_preferences.dart';

const _kExternalPlayer = 'jelly_external_player';

class SettingsStorage {
  late final SharedPreferences _prefs;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  String getExternalPlayer() => _prefs.getString(_kExternalPlayer) ?? 'vlc';

  Future<void> setExternalPlayer(String path) =>
      _prefs.setString(_kExternalPlayer, path);
}
