import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'core/providers/app_providers.dart';
import 'core/providers/watchlist_providers.dart';
import 'core/router.dart';
import 'core/storage/server_storage.dart';
import 'core/storage/watchlist_storage.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _ensureSingleInstance();

  final deviceId = await _getOrCreateDeviceId();
  await _cleanLegacyPrefs();

  final storage = ServerStorage();
  await storage.init();
  storage.setDeviceId(deviceId);

  final watchlistStorage = WatchlistStorage();
  await watchlistStorage.init();

  runApp(
    ProviderScope(
      overrides: [
        serverStorageProvider.overrideWithValue(storage),
        watchlistStorageProvider.overrideWithValue(watchlistStorage),
      ],
      child: const JellyClientApp(),
    ),
  );
}

Future<void> _cleanLegacyPrefs() async {
  // Supprimer les anciennes clés sans userId (pref_audio_lang, pref_sub_lang)
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('pref_audio_lang');
  await prefs.remove('pref_sub_lang');
}

Future<String> _getOrCreateDeviceId() async {
  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString('jelly_device_id');
  if (id == null) {
    id = 'jellyclient-${const Uuid().v4()}';
    await prefs.setString('jelly_device_id', id);
  }
  return id;
}

Future<void> _ensureSingleInstance() async {
  try {
    final dir = await getApplicationSupportDirectory();
    final lockFile = File('${dir.path}/jellyclient.pid');
    if (lockFile.existsSync()) {
      final oldPid = int.tryParse(lockFile.readAsStringSync().trim());
      if (oldPid != null) {
        Process.killPid(oldPid, ProcessSignal.sigterm);
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
    lockFile.writeAsStringSync('$pid');
  } catch (_) {}
}

// ─── Intents pour raccourcis clavier ─────────────────────────────────────────

class _BackIntent extends Intent {
  const _BackIntent();
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}

class _HomeIntent extends Intent {
  const _HomeIntent();
}

// ─── App ──────────────────────────────────────────────────────────────────────

class JellyClientApp extends ConsumerWidget {
  const JellyClientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'JellyClient',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.escape): const _BackIntent(),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            const _SearchIntent(),
        const SingleActivator(LogicalKeyboardKey.keyH, control: true):
            const _HomeIntent(),
      },
      actions: {
        ...WidgetsApp.defaultActions,
        _BackIntent: CallbackAction<_BackIntent>(
          onInvoke: (_) {
            if (router.canPop()) router.pop();
            return null;
          },
        ),
        _SearchIntent: CallbackAction<_SearchIntent>(
          onInvoke: (_) {
            router.go('/search');
            return null;
          },
        ),
        _HomeIntent: CallbackAction<_HomeIntent>(
          onInvoke: (_) {
            router.go('/home');
            return null;
          },
        ),
      },
    );
  }
}
