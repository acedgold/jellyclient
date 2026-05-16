# JellyClient — Contexte projet

Client Jellyfin from scratch en Flutter 3.41.9. Multiplateforme Linux/iOS/Windows.  
Style dark cinéma : fond `#0D0D0D`, accent rouge `#E50914`.

## Chemins critiques

| Quoi | Où |
|---|---|
| Code source (DEV) | `~/development/jellyclient/` |
| Flutter SDK | `~/development/flutter/` (3.41.9 stable) |
| Binary release | `build/linux/x64/release/bundle/jellyclient` |
| Installé (raccourci desktop) | `~/.local/share/jellyclient/` |
| Log VLC | `getTemporaryDirectory()/jellyclient_launch.log` |
| Icône SVG | `~/.local/share/icons/hicolor/scalable/apps/jellyclient.svg` |

## Commandes clés

```bash
export PATH="$PATH:$HOME/development/flutter/bin"
cd ~/development/jellyclient

# Build + installer + lancer (tout en un)
flutter build linux --release && jelly

# Regénérer modèles freezed (après modif jellyfin_models.dart)
dart run build_runner build --delete-conflicting-outputs

# Sync vers un dossier externe (adapter le chemin)
rsync -av --no-links --exclude='.dart_tool' --exclude='build' --exclude='.flutter-plugins*' \
  --exclude='.idea' --exclude='linux/flutter/ephemeral' \
  ~/development/jellyclient/ /chemin/vers/destination/

# Vérifier les args VLC du dernier lancement
cat /tmp/jellyclient_launch.log

# Régénérer les icônes après modif du SVG
for size in 48 128 256; do
  convert -background none ~/.local/share/icons/hicolor/scalable/apps/jellyclient.svg \
    -resize ${size}x${size} ~/.local/share/icons/hicolor/${size}x${size}/apps/jellyclient.png
done
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor/
```

## État actuel (2026-05-15) — Complet

### Optimisations performance (2026-05-15)
- **AppBar alpha** : `double _appBarAlpha + setState` → `ValueNotifier<double> + ListenableBuilder` → plus aucun rebuild de la page pendant le scroll (60fps → 0 rebuild/frame)
- **Flèches sections** : `setState` dans `_onScroll` → `ValueNotifier<bool>` pour `_canLeft/_canRight` ; seul le bouton flèche rebuild via `ValueListenableBuilder`
- **`_HorizontalSection`** : `ListView.separated` → `ListView.builder` avec `itemExtent: 148` (layout précalculé) + `RepaintBoundary` par card
- **`MediaCard`** : `ref.watch(watchlistProvider)` → `ref.watch(watchlistProvider.select(...))` (rebuild uniquement si cet item change) + `RepaintBoundary` autour du hover overlay
- **Widget partagé `_ScrollArrow`** : flèches identiques réutilisées dans Top 10 et toutes les sections

### Rapport progression VLC (2026-05-15)
- `ProcessStartMode.detached` → `ProcessStartMode.normal` → `process.exitCode` disponible
- `launchWithExternalPlayer` : nouveau param `onStopped: void Function(int estimatedTicks)?`
- `unawaited(process.exitCode.then(...))` : monitoring en arrière-plan sans bloquer
- À la fermeture de VLC : `reportPlaybackStop(itemId, estimatedTicks)` + `markPlayed` si > 90%
- Implémenté sur : bouton Lire (detail), quickPlay (card), prochain épisode (série), sheet épisode

### Skip intro (2026-05-15)
- `getIntroTimestamps(episodeId)` dans `JellyfinClient` → endpoint IntroSkipper plugin `/Episode/{id}/IntroTimestamps`
- `_introTimestampsProvider` FutureProvider.family → silencieux si plugin absent
- `_EpisodePlayButtons` widget : bouton "Passer l'intro (→ 1:25)" uniquement si données disponibles
- `ChapterInfo` model ajouté (`startPositionTicks`, `name`) + champ `chapters` dans `JellyItem`
- `Chapters` ajouté aux `Fields` de `getItem`

### Temps restant sur les cards (2026-05-15)
- `_formatRemaining()` dans `_MediaCardState` : `(runTimeTicks - playbackPositionTicks) / 600000000` → "Xmin" ou "Xh Ymin"
- Affiché sur la card directement (blanc, au-dessus barre de progression, droite)
- Affiché dans le hover overlay (rouge "#E50914 restant", dans la ligne rating/année)

### Top 10 + Sections (2026-05-15)
- Top 10 : hauteur adaptive `(screenW × 0.38 - 42) × 1.5`, flèches ← →, police numéros proportionnelle
- `_HorizontalSection` : StatefulWidget avec flèches ← → sur toutes les sections (Continuer, Récents, Genres)

### Icône personnalisée
- SVG : "J" rouge (#E50914) sur fond noir arrondi, crochet + point blanc
- PNG générés : 48×48, 128×128, 256×256
- `.desktop` mis à jour : `Icon=jellyclient`
- `~/bin/jelly` : rsync build→install avant lancement → raccourci toujours à jour

### Préférences de langue (par utilisateur)
- Clés : `pref_audio_lang_<userId>`, `pref_sub_lang_<userId>`
- Paramètres → chips + bouton **Enregistrer** (obligatoire) + confirmation
- Auto-sélection dans `_FilmPlaySheet`, `_SeasonTrackSheet`, `_EpisodePlaySheet`
- Lecture rapide : `--audio-language` + `--sub-language` passés à VLC/mpv
- `_cleanLegacyPrefs()` au démarrage → supprime anciennes clés sans userId
- `setActiveServer()` après chaque switch → userId stable au redémarrage

### Features Netflix complètes
- Hero Banner / AppBar scroll / Top 10 / Sections genre
- Quick actions hover (▶ ♥ ℹ + synopsis + note)
- Fiche film/série redesign : play blanc → sheet audio/sous-titres → VLC
- Profils utilisateurs (GET /Users serveur)
- Infinite scroll bibliothèque
- More Like This / Favoris Jellyfin / Badges NOUVEAU

### Portabilité (audit Opus ✅)
- DeviceId UUID unique (`jelly_device_id`)
- `getTemporaryDirectory()` pour log + playlist M3U
- Aucun URL/ID/credential hardcodé

## Pièges critiques

1. **CIFS** : jamais flutter pub get/build dans VibeCoding
2. **JSON PascalCase** : `@JsonKey(name:'Id')` — ne pas utiliser `field_rename:pascal`
3. **build_runner** obligatoire après modif `jellyfin_models.dart`
4. **Indices VLC** : 0-based par type ; mpv : 1-based par type
5. **VLC `--no-subs` INVALIDE** → `--sub-track=-1`
6. **DeviceId** : UUID au 1er lancement, clé `jelly_device_id`
7. **Préférences langue** : clé `pref_audio_lang_<userId>` (userId = Jellyfin UUID)
8. **Bouton Enregistrer obligatoire** : chips ne sauvegardent pas automatiquement
9. **`setActiveServer()`** : appeler après chaque switch profil
10. **`~/bin/jelly`** : rsync build→install → raccourci desktop toujours synchronisé
11. **media_kit** : écran bleu AMD X11 — abandon définitif
12. **palette_generator** : discontinued mais fonctionnel — à remplacer à terme
13. **`ProcessStartMode.normal`** (pas detached) : VLC devient orphelin d'init si JellyClient est fermé → OK Linux ; à tester Windows
14. **`onStopped` callback** : capturer `client`, `userId`, `itemId`, `runTimeTicks` AVANT le launch — `ref` invalide après pop du widget
15. **`getIntroTimestamps`** retourne `null` silencieusement si plugin IntroSkipper absent — pas de gestion d'erreur côté UI
16. **`setState` dans `_onScroll`** : NE PAS remettre — utiliser `ValueNotifier` pour tout état lié au scroll
17. **`watchlistProvider.select()`** obligatoire dans `MediaCard` — sans `.select()` toutes les cards rebuildbent à chaque changement de favori

## Serveur Jellyfin de référence

Configurer vos serveurs depuis l'interface (page "Serveurs" → "Ajouter un serveur").
Exemples : `https://jellyfin.example.com` · `https://streaming.example.com`
