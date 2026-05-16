# JellyClient — Adaptations pour le portage Windows

## Fichiers modifiés

### `lib/core/services/platform_utils.dart` (NOUVEAU)
- Fonction `openUrl(String url)` — remplace tous les `xdg-open`
- Gestion automatique selon la plateforme :
  - Linux → `xdg-open`
  - Windows → `cmd /c start "" url`
  - macOS → `open`

### `lib/features/detail/detail_screen.dart`
- IMDb badge : `xdg-open` → `openUrl()` ✅

### `lib/features/series/series_screen.dart`
- IMDb badge : `xdg-open` → `openUrl()` ✅

### `lib/features/settings/settings_screen.dart`
- Chips lecteur : Windows → `vlc.exe` (chemin complet + relatif vlc portable)
- Hint TextField : chemin Windows affiché sur Windows
- Aide bas de page : instructions spécifiques à la plateforme
- Bouton Redémarrer : masqué sur iOS (`!Platform.isIOS`)

### `lib/core/services/external_player.dart`
- Chemins temporaires → `getTemporaryDirectory()` ✅ (déjà portable)
- `DISPLAY` → conditionné `if (!env.containsKey('DISPLAY'))` ✅ (déjà portable)

### `lib/main.dart`
- `getApplicationSupportDirectory()` → portable Windows ✅
- `getTemporaryDirectory()` → portable Windows ✅
- DeviceId UUID → SharedPreferences portable ✅

---

## Ce qui reste identique (aucun changement requis)

| Composant | Raison |
|---|---|
| `flutter_secure_storage` | Windows Credential Manager supporté |
| `SharedPreferences` | Portable Windows |
| `path_provider` | Portable Windows |
| `cached_network_image` | Portable |
| `go_router` | Portable |
| Riverpod / Hooks | Portable |
| `Process.start(player, args)` | Fonctionne sur Windows (VLC/mpv) |
| `ProcessStartMode.detached` | Fonctionne sur Windows |
| Raccourcis clavier | Fonctionnent sur Windows desktop |
| `MouseRegion` (hover) | Fonctionne sur Windows |

---

## Ce qui N'A PAS été adapté (hors scope v1)

| Point | Action requise pour v2 |
|---|---|
| Icône `.ico` | Générer depuis SVG + placer dans `windows/runner/resources/` |
| `flutter_launcher_icons` | Configurer pour Windows |
| Instance unique sur Windows | Tester — devrait fonctionner |
| VLC bundle portable | Documenter dans BUILD.md (manuel) |

---

## Checklist avant de builder sur Windows

- [ ] `flutter doctor` → Windows (desktop) ✅
- [ ] Visual Studio 2022 avec "Desktop development with C++"
- [ ] `flutter pub get` sans erreur
- [ ] `flutter build windows --release` réussit
- [ ] Lancer `.\portage\windows\build_portable.ps1`
- [ ] Tester `jellyclient.exe`
- [ ] Configurer le chemin VLC dans Paramètres
- [ ] Tester lecture d'un film
- [ ] Tester ouverture IMDb (badge dans fiche)
