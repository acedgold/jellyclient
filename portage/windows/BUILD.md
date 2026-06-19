# JellyClient — Build & distribution Windows (portable, zéro config)

La version Windows **n'est pas une réécriture** : c'est la même base Flutter que
Linux, qui cible déjà Windows. Il n'y a donc rien à « porter » — juste à
**compiler sur une machine Windows** puis à **emballer** le résultat.

Le script [`build_portable.ps1`](build_portable.ps1) fait tout en une commande :
build release → téléchargement et intégration de **VLC portable** → lanceur +
icône + LIRE_MOI → `dist\JellyClient-Windows-portable.zip` prêt à partager.

---

## Prérequis (PC Windows, une seule fois)

1. **Flutter SDK** — https://docs.flutter.dev/get-started/install/windows
   Après install : `flutter doctor` doit montrer **Windows (desktop)** OK.
2. **Visual Studio 2022 Community** avec **uniquement** la charge de travail
   **« Développement Desktop en C++ »**.
   (La charge « UWP » n'est PAS nécessaire.)
3. *(Optionnel)* **7-Zip** — si présent, VLC est extrait depuis le `.7z`
   (plus léger) ; sinon le script bascule automatiquement sur le `.zip`.

Git est optionnel : tu peux copier le dossier du projet via clé USB / réseau.

---

## Build + packaging (1 commande)

```powershell
cd C:\JellyClient          # dossier du projet
.\portage\windows\build_portable.ps1
```

Le script :
- lance `flutter build windows --release` (sauter avec `-SkipBuild`) ;
- télécharge VLC portable (~40 Mo) et l'intègre dans `vlc\` (sauter avec `-SkipVlc`) ;
- produit **`dist\JellyClient-Windows-portable.zip`** (~90 Mo, VLC inclus).

À la fin, la console affiche le chemin du zip et « VLC inclus : OUI ».

---

## Contenu du zip partagé

```
JellyClient-Windows-portable/
  jellyclient.exe              ← exécutable
  jellyclient.ico              ← icône
  flutter_windows.dll, *.dll   ← moteur Flutter + dépendances
  data/                        ← assets Flutter
  vlc/vlc.exe                  ← VLC portable (détecté automatiquement)
  Lancer JellyClient.bat       ← double-clic pour démarrer
  Creer raccourci Bureau.ps1   ← raccourci Bureau optionnel
  LIRE_MOI.txt                 ← instructions destinataire
```

JellyClient cherche VLC dans cet ordre : `vlc\vlc.exe` (bundlé) → Program Files
→ PATH. Le bundle marche donc **sans aucune installation** chez le destinataire.

---

## Partager le zip (release GitHub)

Cohérent avec le paquet Linux. Sur le PC Windows, soit via l'interface web :
**github.com/acedgold/jellyclient → Releases → v1.0.0 → Edit → glisser le zip**,
soit en ligne de commande si `gh` est installé :

```powershell
gh release upload v1.0.0 dist\JellyClient-Windows-portable.zip
```

Lien de téléchargement obtenu :
`https://github.com/acedgold/jellyclient/releases/download/v1.0.0/JellyClient-Windows-portable.zip`

### ⚠️ Avertissement SmartScreen (normal, exe non signé)

Au 1ᵉʳ lancement chez le destinataire, Windows affiche un écran bleu
« Windows a protégé votre PC ». C'est attendu pour un exécutable non signé.
Marche à suivre (à indiquer au destinataire) :
**« Informations complémentaires » → « Exécuter quand même »**.

La signature de code (certificat ~150-300 €/an) n'est pas justifiée pour un
partage entre proches ; on assume cet avertissement.

---

## Données utilisateur

- Préférences : `%LOCALAPPDATA%\dev.acedgold.jellyclient\`
- Tokens Jellyfin : Windows Credential Manager (liés à la session Windows)
- Transfert de profil → se reconnecter sur la nouvelle machine.

## Problèmes connus

| Problème | Solution |
|---|---|
| Téléchargement VLC échoué (réseau) | Relancer, ou installer VLC sur le PC (détection PATH/Program Files) |
| VLC non trouvé chez le destinataire | Renseigner le chemin complet dans Paramètres → Lecteur |
| Fenêtre noire 2-3 s au 1ᵉʳ démarrage | Normal (chargement Flutter au premier run) |
