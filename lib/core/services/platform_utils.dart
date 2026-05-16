import 'dart:io';

/// Ouvre une URL dans le navigateur par défaut du système.
/// Compatible Linux (xdg-open), Windows (start), macOS (open).
Future<void> openUrl(String url) async {
  try {
    if (Platform.isLinux) {
      await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
    } else if (Platform.isWindows) {
      // Sur Windows, 'start' est une commande interne cmd
      // Le "" vide est le titre de la fenêtre (obligatoire quand l'URL contient &)
      await Process.start(
        'cmd',
        ['/c', 'start', '', url],
        mode: ProcessStartMode.detached,
      );
    } else if (Platform.isMacOS) {
      await Process.start('open', [url], mode: ProcessStartMode.detached);
    }
  } catch (_) {
    // Fallback silencieux — l'URL peut être copiée manuellement
  }
}
