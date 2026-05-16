# JellyClient — Build Windows 11 (version portable)

## Prérequis (sur le PC Windows)

1. **Flutter SDK** — https://docs.flutter.dev/get-started/install/windows
   ```powershell
   # Vérifier l'installation
   flutter doctor
   ```
   Vérifier que `Windows (desktop)` est coché.

2. **Visual Studio 2022** avec les workloads :
   - "Desktop development with C++"
   - "Universal Windows Platform development"

3. **Git** pour cloner le projet si besoin.

---

## Étapes de build

### 1. Récupérer le code source

Cloner le dépôt ou copier le dossier `JellyClient/` sur le PC Windows :
```powershell
git clone https://github.com/<votre-utilisateur>/jellyclient.git C:\JellyClient
```

### 2. Installer les dépendances

```powershell
cd C:\JellyClient
flutter pub get
```

### 3. Builder la version release

```powershell
flutter build windows --release
```

Le résultat sera dans :
```
build\windows\x64\runner\Release\
```

### 4. Packager en version portable

Lancer le script PowerShell inclus :
```powershell
.\portage\windows\build_portable.ps1
```

Ce script crée `dist\JellyClient-Windows-portable.zip`.

---

## Contenu du bundle portable

```
JellyClient-Windows-portable/
  jellyclient.exe          ← exécutable principal
  jellyclient.ico          ← icône
  flutter_windows.dll      ← moteur Flutter
  *.dll                    ← dépendances
  data/                    ← assets Flutter
  README_WINDOWS.txt       ← instructions utilisateur
  vlc/                     ← (optionnel) VLC portable
```

### VLC Portable (recommandé)

Télécharger VLC portable depuis https://www.videolan.org/vlc/download-windows.html  
Extraire dans `JellyClient-Windows-portable\vlc\`  
Puis dans JellyClient Paramètres → Lecteur : `vlc\vlc.exe`

---

## Données utilisateur (non portables entre machines)

Les préférences sont stockées dans :
```
%LOCALAPPDATA%\dev.acedgold.jellyclient\
```

Les tokens Jellyfin sont dans le Windows Credential Manager (liés à la session Windows).  
Pour transférer un profil → re-se connecter sur la nouvelle machine.

---

## Problèmes connus Windows

| Problème | Solution |
|---|---|
| VLC non trouvé | Configurer le chemin complet dans Paramètres |
| Fenêtre noire au démarrage | Attendre 2-3s (chargement Flutter first run) |
| Erreur `flutter_secure_storage` | Vérifier que Windows Credential Manager est actif |

---

## Commande build complète (copier-coller)

```powershell
cd C:\JellyClient
flutter pub get
flutter build windows --release
.\portage\windows\build_portable.ps1
```
