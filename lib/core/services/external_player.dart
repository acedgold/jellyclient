import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/models/jellyfin_models.dart';

const _kPlayerPath    = 'jelly_external_player';
const _kAudioLangPath = 'pref_audio_lang';
const _kSubLangPath   = 'pref_sub_lang';

// ─── Langues disponibles (ISO 639-2) ─────────────────────────────────────────

const kLanguages = [
  ('Français',   'fre'),
  ('English',    'eng'),
  ('Japonais',   'jpn'),
  ('Espagnol',   'spa'),
  ('Allemand',   'ger'),
  ('Italien',    'ita'),
  ('Coréen',     'kor'),
  ('Portugais',  'por'),
  ('Arabe',      'ara'),
  ('Chinois',    'chi'),
];

// Variantes ISO 639-2 T/B — certains serveurs utilisent l'un ou l'autre
const _langSynonyms = <String, List<String>>{
  'fre': ['fra', 'fre', 'fr'],
  'ger': ['deu', 'ger', 'de'],
  'chi': ['zho', 'chi', 'zh'],
};

bool matchesLang(String? streamLang, String prefLang) {
  if (streamLang == null) return false;
  final sl = streamLang.toLowerCase();
  final pl = prefLang.toLowerCase();
  if (sl == pl) return true;
  final syns = _langSynonyms[pl];
  if (syns != null) return syns.contains(sl);
  return sl.startsWith(pl.length >= 2 ? pl.substring(0, 2) : pl);
}

/// Index du meilleur sous-titre dans `subStreams` pour la langue `lang` :
/// on privilégie le sous-titre **complet** (non forcé) ; on ne retient un
/// sous-titre **forcé** que s'il n'existe aucune version complète. -1 si aucun.
int bestSubtitleIndex(List<MediaStream> subStreams, String lang) {
  var idx = subStreams.indexWhere(
      (s) => matchesLang(s.language, lang) && s.isForced != true);
  if (idx < 0) {
    idx = subStreams.indexWhere((s) => matchesLang(s.language, lang));
  }
  return idx;
}

Future<String> getExternalPlayer() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(_kPlayerPath);

  // Si déjà configuré manuellement → utiliser ce chemin
  if (stored != null && stored.isNotEmpty) return stored;

  // Auto-détection Windows
  if (Platform.isWindows) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;

    // 1. VLC portable bundlé à côté de l'exe
    final bundled = '$exeDir\\vlc\\vlc.exe';
    if (File(bundled).existsSync()) return bundled;

    // 2. VLC installé dans Program Files
    for (final path in [
      r'C:\Program Files\VideoLAN\VLC\vlc.exe',
      r'C:\Program Files (x86)\VideoLAN\VLC\vlc.exe',
    ]) {
      if (File(path).existsSync()) return path;
    }
  }

  // Auto-détection macOS
  if (Platform.isMacOS) {
    // VLC installé dans /Applications (le binaire est dans le bundle .app)
    for (final path in [
      '/Applications/VLC.app/Contents/MacOS/VLC',
      '${Platform.environment['HOME'] ?? ''}/Applications/VLC.app/Contents/MacOS/VLC',
    ]) {
      if (File(path).existsSync()) return path;
    }
    // Repli : binaire vlc dans le PATH (Homebrew)
    for (final path in ['/opt/homebrew/bin/vlc', '/usr/local/bin/vlc']) {
      if (File(path).existsSync()) return path;
    }
  }

  // Défaut Linux (et repli macOS) : commande du PATH
  return 'vlc';
}

Future<void> setExternalPlayer(String path) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPlayerPath, path);
}

// ─── Langue audio préférée (par utilisateur) ─────────────────────────────────

Future<String?> getPreferredAudioLang(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('${_kAudioLangPath}_$userId');
}

Future<void> setPreferredAudioLang(String userId, String? lang) async {
  final prefs = await SharedPreferences.getInstance();
  if (lang == null) {
    await prefs.remove('${_kAudioLangPath}_$userId');
  } else {
    await prefs.setString('${_kAudioLangPath}_$userId', lang);
  }
}

// ─── Langue sous-titres préférée (par utilisateur) ───────────────────────────

Future<String?> getPreferredSubLang(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('${_kSubLangPath}_$userId');
}

Future<void> setPreferredSubLang(String userId, String? lang) async {
  final prefs = await SharedPreferences.getInstance();
  if (lang == null) {
    await prefs.remove('${_kSubLangPath}_$userId');
  } else {
    await prefs.setString('${_kSubLangPath}_$userId', lang);
  }
}

Future<void> launchWithExternalPlayer({
  required String url,
  String? title,
  int startTicks = 0,
  int? audioTrackPos,
  int? subtitleTrackPos,
  String? audioLang,    // code ISO 639-2 pour la lecture rapide (ex: 'fre')
  String? subLang,      // code ISO 639-2 pour les sous-titres (null = aucun)
  List<MediaStream>? mediaStreams, // pistes du média → résolution langue → index
  void Function(int estimatedTicks)? onStopped,
}) async {
  final player = await getExternalPlayer();
  final startSecs = startTicks ~/ 10000000;

  // VLC/mpv ignorent souvent --audio-language/--sub-language sur un flux réseau.
  // Si on a les pistes, on résout la langue préférée en INDEX (fiable) et on
  // passe --audio-track / --sub-track. Les index sont 0-based PAR TYPE.
  if (mediaStreams != null && mediaStreams.isNotEmpty) {
    final audioStreams =
        mediaStreams.where((s) => s.type == 'Audio').toList();
    final subStreams =
        mediaStreams.where((s) => s.type == 'Subtitle').toList();
    if (audioTrackPos == null && audioLang != null) {
      final idx =
          audioStreams.indexWhere((s) => matchesLang(s.language, audioLang));
      if (idx >= 0) audioTrackPos = idx; // sinon : piste audio par défaut
    }
    // Ne décider des sous-titres que si on a réellement les pistes (sinon on
    // laisse le fallback --sub-language plutôt que de forcer "aucun").
    if (subtitleTrackPos == null && subLang != null && subStreams.isNotEmpty) {
      final idx = bestSubtitleIndex(subStreams, subLang); // complet > forcé
      subtitleTrackPos = idx >= 0 ? idx : -1; // pas de correspondance → off
    }
  }

  final args = _buildArgs(
    player: player,
    url: url,
    title: title,
    startSecs: startSecs,
    audioTrackPos: audioTrackPos,
    subtitleTrackPos: subtitleTrackPos,
    audioLang: audioLang,
    subLang: subLang,
  );

  // Log debug
  try {
    final tmp = await getTemporaryDirectory();
    File('${tmp.path}/jellyclient_launch.log').writeAsStringSync(
      'player=$player\n'
      'args=${args.join(' ')}\n'
      'audioTrackPos=$audioTrackPos subtitleTrackPos=$subtitleTrackPos\n'
      'audioLang=$audioLang subLang=$subLang\n'
      'DISPLAY=${Platform.environment['DISPLAY']}\n',
    );
  } catch (_) {}

  // Lancement direct sans shell intermédiaire
  final env = Map<String, String>.from(Platform.environment);
  if (!Platform.isWindows && !env.containsKey('DISPLAY')) env['DISPLAY'] = ':0';

  final launchTime = DateTime.now();
  final process = await Process.start(
    player,
    args,
    environment: env,
    mode: ProcessStartMode.normal,
    includeParentEnvironment: true,
  );

  if (onStopped != null) {
    final capturedStart = startTicks;
    unawaited(process.exitCode.then((_) {
      final elapsed = DateTime.now().difference(launchTime);
      final estimatedTicks = capturedStart + elapsed.inMilliseconds * 10000;
      onStopped(estimatedTicks);
    }));
  }
}

List<String> _buildArgs({
  required String player,
  required String url,
  String? title,
  int startSecs = 0,
  int? audioTrackPos,
  int? subtitleTrackPos,
  String? audioLang,
  String? subLang,
}) {
  final name = player.replaceAll('\\', '/').split('/').last.toLowerCase();

  if (name.contains('vlc')) {
    return [
      url,
      if (startSecs > 0) '--start-time=$startSecs',
      '--fullscreen',
      // Audio : index explicite (sheets) ou langue (lecture rapide)
      if (audioTrackPos != null)
        '--audio-track=$audioTrackPos'
      else if (audioLang != null)
        '--audio-language=$audioLang',
      // Sous-titres : index explicite, langue, ou désactivé
      if (subtitleTrackPos != null && subtitleTrackPos >= 0)
        '--sub-track=$subtitleTrackPos'
      else if (subtitleTrackPos == null && subLang != null)
        '--sub-language=$subLang'
      else
        '--sub-track=-1',
    ];
  }

  if (name.contains('mpv')) {
    return [
      url,
      if (title != null) '--title=$title',
      if (startSecs > 0) '--start=$startSecs',
      '--fs',
      '--hwdec=no',
      if (audioTrackPos != null)
        '--aid=${audioTrackPos + 1}'
      else if (audioLang != null)
        '--alang=$audioLang',
      if (subtitleTrackPos != null && subtitleTrackPos >= 0)
        '--sid=${subtitleTrackPos + 1}'
      else if (subtitleTrackPos == null && subLang != null)
        '--slang=$subLang'
      else
        '--no-sub',
    ];
  }

  return [url];
}
