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

## État (mis à jour 2026-06-19)

| Point | État |
|---|---|
| Icône `.ico` | ✅ `windows/runner/resources/app_icon.ico` + `portage/windows/assets/jellyclient.ico` (copiée dans le bundle) |
| VLC portable bundlé | ✅ téléchargé et intégré automatiquement par `build_portable.ps1` |
| Packaging zip portable | ✅ `build_portable.ps1` → `dist\JellyClient-Windows-portable.zip` |
| Piste Rust (`jellyclient-rs`) | ❌ **abandonnée et supprimée** (réécriture from-scratch trop complexe — la base Flutter conserve déjà toutes les fonctions) |

> Le « portage » Windows se résume désormais à : **builder sur un PC Windows**
> via `build_portable.ps1` (voir [BUILD.md](BUILD.md)). Aucune réécriture.

---

## Checklist avant de builder sur Windows

- [ ] `flutter doctor` → Windows (desktop) ✅
- [ ] Visual Studio 2022 avec "Développement Desktop en C++" (charge UWP inutile)
- [ ] `.\portage\windows\build_portable.ps1` (build + VLC + zip en 1 commande)
- [ ] Tester le zip : dézipper → `Lancer JellyClient.bat`
- [ ] Tester lecture d'un film (VLC bundlé) + ouverture IMDb (badge fiche)
- [ ] Uploader le zip sur la release GitHub v1.0.0
