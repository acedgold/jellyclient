# JellyClient — Windows (portage en cours)

Référence : voir `LINUX.md` pour la liste complète des features à atteindre.  
Parité : voir `FEATURES.md` — toutes les lignes Windows=⬜ sont à implémenter.  
Objectif : parité fonctionnelle totale avec la version Linux.

> Quand tu implémentes une feature → mets ✅ dans la colonne Windows de `FEATURES.md`.

**État global** : codebase prête, target Windows créée, icône faite, scripts de build prêts.  
**Reste** : compiler sur machine Windows (VS2022), tester, corriger les 4 adaptations plateforme.

---

## Prérequis pour builder sur Windows

```powershell
# Installer Flutter SDK (stable 3.41.9+)
# Installer Visual Studio 2022 avec "Desktop development with C++"
# Installer Git + VLC

cd C:\...\JellyClient
flutter pub get
flutter build windows --release

# Ou utiliser le script fourni :
.\portage\windows\build_portable.ps1
```

Fichiers portage déjà prêts :
- `portage/windows/BUILD.md` — guide complet pas à pas
- `portage/windows/build_portable.ps1` — script auto (détecte VLC, crée ZIP portable)
- `windows/runner/resources/app_icon.ico` — icône multi-résolution ✅
- `windows/runner/Runner.rc` — métadonnées (CompanyName=AceDGold) ✅
- `windows/` — target générée via `flutter create --platforms=windows` ✅

---

## Adaptations nécessaires (delta vs Linux)

### 1. Ouvrir une URL dans le navigateur — `platform_utils.dart`

**Linux** : `xdg-open <url>`  
**Windows** : `Process.start('cmd', ['/c', 'start', url])`  
**État** : ⬜ À faire

```dart
// lib/core/services/platform_utils.dart
Future<void> openUrl(String url) async {
  if (Platform.isWindows) {
    await Process.start('cmd', ['/c', 'start', url], mode: ProcessStartMode.detached);
  } else {
    await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
  }
}
```

Fichiers concernés : `detail_screen.dart` et `series_screen.dart` appellent `openUrl()`.

---

### 2. `ProcessStartMode.normal` — survivance VLC à la fermeture de l'app

**Linux** : VLC devient orphelin d'init → continue de jouer si JellyClient est fermé ✅  
**Windows** : à tester — un process `normal` peut recevoir SIGTERM à la fermeture du parent  
**État** : ⬜ À tester

Si VLC se ferme avec l'app sur Windows, deux options :
- Option A : changer en `ProcessStartMode.detached` **uniquement sur Windows** mais perdre le `onStopped`
- Option B : laisser `normal` (acceptable si l'utilisateur ne ferme pas l'app pendant la lecture)

```dart
// external_player.dart — adaptation possible si nécessaire :
mode: Platform.isWindows ? ProcessStartMode.detached : ProcessStartMode.normal,
```

---

### 3. VLC auto-détection — déjà implémentée

**État** : ✅ Déjà fait dans `getExternalPlayer()`

```dart
// Ordre de recherche sur Windows :
// 1. vlc\vlc.exe portable à côté de l'exe
// 2. C:\Program Files\VideoLAN\VLC\vlc.exe
// 3. C:\Program Files (x86)\VideoLAN\VLC\vlc.exe
// 4. Sinon → afficher dialog pour chemin manuel dans Paramètres
```

---

### 4. `flutter_secure_storage` — Windows Credential Manager

**Linux** : libsecret (keychain système) ✅  
**Windows** : Windows Credential Manager (automatique avec le package) ✅ en théorie  
**État** : ⬜ À tester (les tokens doivent persister entre les sessions)

---

### 5. Instance unique — PID lock

**Linux** : `getApplicationSupportDirectory()` → `~/.local/share/dev.acedgold.jellyclient/` ✅  
**Windows** : `getApplicationSupportDirectory()` → `%APPDATA%\acedgold\jellyclient\` (automatique)  
**État** : ⬜ À tester (vérifier que le lock fonctionne et ne bloque pas le redémarrage)

---

### 6. Variable `DISPLAY` — déjà conditionné

**État** : ✅ Déjà fait

```dart
if (!Platform.isWindows && !env.containsKey('DISPLAY')) env['DISPLAY'] = ':0';
```

---

### 7. Split path player (déjà fait)

**État** : ✅ Déjà fait

```dart
// external_player.dart — extrait le nom de l'exe cross-platform :
final name = player.replaceAll('\\', '/').split('/').last.toLowerCase();
```

---

## Checklist de test Windows

Une fois compilé avec VS2022, tester dans cet ordre :

### Auth
- [ ] Ajouter un serveur Jellyfin
- [ ] Se connecter, choisir un profil
- [ ] Fermer et rouvrir l'app → auto-login (token persistant via Credential Manager)
- [ ] Instance unique : lancer 2 fois → 2e se ferme automatiquement

### Home
- [ ] Hero Banner s'affiche (images Jellyfin chargent)
- [ ] Top 10, flèches ← →, scroll horizontal
- [ ] Sections Récents, Genres

### Lecture
- [ ] Cliquer ▶ sur un film → sheet audio/sous-titres → VLC s'ouvre
- [ ] VLC joue le bon fichier avec la bonne piste audio
- [ ] Fermer JellyClient pendant la lecture → VLC continue (ProcessStartMode.normal)
- [ ] Fin de VLC → progression reportée au serveur Jellyfin (vérifier dans l'interface web)

### Liens externes
- [ ] Badge IMDb → ouvre le navigateur Windows
- [ ] (Nécessite adaptation `platform_utils.dart` ci-dessus)

### Paramètres
- [ ] Configurer chemin VLC custom → fonctionne
- [ ] Préférences langue audio/sous-titres → persistent

---

## Features identiques Linux/Windows (aucune adaptation nécessaire)

Ces features fonctionnent identiquement grâce à Flutter cross-platform :

- Toute la navigation (go_router)
- Toutes les requêtes API Jellyfin (dio)
- Toutes les interfaces (Material Design)
- Watchlist locale (SharedPreferences)
- Recherche, genres, watchlist, paramètres langue
- Infinite scroll, tri, filtres
- Playlist M3U (`getTemporaryDirectory()` → `%TEMP%` sur Windows)
- DeviceId UUID
- Skip intro (IntroSkipper)
- Temps restant sur les cards
- Rapport progression (si ProcessStartMode.normal OK)

---

## Features non applicables sur Windows

| Feature Linux | Windows |
|---|---|
| Raccourci `.desktop` | Raccourci Bureau dans `build_portable.ps1` ✅ |
| Icône SVG + `gtk-update-icon-cache` | `.ico` multi-résolution dans `Runner.rc` ✅ |
| `~/bin/jelly` rsync | Workflow VS2022 + `build_portable.ps1` |

---

## Features à ne PAS porter sur iOS (mémo pour éviter confusion)

Ces features sont **Windows/Linux only** — inapplicables sur iOS :
- `Process.start` → lecteur externe VLC (iOS interdit)
- `exit(0)` bouton Redémarrer (App Store interdit)
- Instance unique PID lock (sandboxing iOS gère ça)
- Raccourcis clavier (rare sur iOS sans clavier physique)
