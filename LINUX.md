# JellyClient — Linux (version de référence)

État : **Production. Toutes les features sont complètes.**  
Flutter 3.41.9 — build : `~/development/flutter/bin/flutter build linux --release`

> **Parité Linux ↔ Windows** : voir `FEATURES.md` pour le tableau de parité complet.  
> Quand tu ajoutes une feature ici → mets à jour `FEATURES.md` avec Windows=⬜ et les notes de portage.

---

## Auth & Serveurs

| Feature | État | Fichier clé |
|---|---|---|
| Ajout serveur (URL + login/mot de passe) | ✅ | `auth/add_server_screen.dart` |
| Auto-login au démarrage (token SecureStorage) | ✅ | `core/storage/server_storage.dart` |
| Multi-serveurs + switch actif | ✅ | `auth/servers_screen.dart` |
| Profils utilisateurs (GET /Users Jellyfin) | ✅ | `auth/profiles_screen.dart` |
| `setActiveServer()` après chaque switch → userId stable | ✅ | `core/providers/app_providers.dart` |
| DeviceId UUID unique par installation (`jelly_device_id`) | ✅ | `main.dart` |

---

## Accueil (Home)

| Feature | État | Détail |
|---|---|---|
| Hero Banner (backdrop, logo PNG/texte, synopsis, genres, bouton Lire) | ✅ | `_HeroBannerContent` — hauteur `screenH × 0.50` |
| AppBar scroll-aware transparent → opaque | ✅ | `ValueNotifier<double>` + `ListenableBuilder` — 0 rebuild de la page |
| Top 10 — Derniers films (rail, numéros stylisés Netflix) | ✅ | Hauteur adaptive `(screenW × 0.38 - 42) × 1.5` |
| Flèches ← → sur Top 10 et toutes les sections | ✅ | `_ScrollArrow` (ValueNotifier, 0 setState) |
| Sections horizontales : Continuer / Récents / Genres | ✅ | `_HorizontalSection` StatefulWidget + `itemExtent` |
| Pull-to-refresh | ✅ | Invalide 6 providers |
| 4 sections genre max (évite surcharge réseau) | ✅ | `list.take(4)` |

---

## Vignettes (MediaCard)

| Feature | État | Détail |
|---|---|---|
| Hover overlay (▶ ♥ ℹ + synopsis + note) | ✅ | `MouseRegion` + `AnimatedOpacity` |
| **Temps restant** ("Xmin restant" rouge) | ✅ | `_formatRemaining()` — sur card + overlay hover |
| Barre de progression (`playedPercentage`) | ✅ | `LinearProgressIndicator` en bas |
| Badges NOUVEAU (bleu ≤7j), SÉRIE, VU (✓) | ✅ | |
| Lecture rapide (▶ hover) avec préférences langue | ✅ | `_quickPlay()` + `onStopped` |
| Ajout/retrait watchlist depuis hover | ✅ | |
| `watchlistProvider.select()` — rebuild minimal | ✅ | Pas de rebuild global sur changement favori |
| `RepaintBoundary` autour du hover overlay | ✅ | Isole les repaints d'animation |

---

## Bibliothèque

| Feature | État | Détail |
|---|---|---|
| Grille adaptative | ✅ | `SliverGridDelegate` |
| Infinite scroll (chargement à 85%) | ✅ | |
| Tri A–Z / Date / Note / Année + ordre ↑↓ | ✅ | |
| Filtre par type (Film/Série) + genre | ✅ | chips |
| Compteur `X / N médias` en temps réel | ✅ | |

---

## Fiche Film

| Feature | État | Détail |
|---|---|---|
| Backdrop 220px + couleur dynamique (`palette_generator`) | ✅ | |
| Titre, année, durée, note, genres cliquables, classification | ✅ | |
| Bouton Lire → sheet audio/sous-titres → VLC | ✅ | `_FilmPlaySheet` |
| Reprise (`Reprendre` si progress > 0) | ✅ | |
| **Rapport progression** : `reportPlaybackStop` + `markPlayed` (>90%) | ✅ | `onStopped` callback |
| Favoris Jellyfin ❤ / Watchlist ♥ / Déjà vu ✓ | ✅ | |
| IMDb badge → `xdg-open` | ✅ | `platform_utils.dart` |
| Casting & Équipe (photos 88px, noms 12px) | ✅ | `CastSection` |
| More Like This (rail "Dans le même genre") | ✅ | `_MoreLikeThis` |
| Provider IDs (TMDb, TVDb) | ✅ | |
| Rafraîchir métadonnées (FullRefresh) | ✅ | |

---

## Fiche Série

| Feature | État | Détail |
|---|---|---|
| Backdrop 220px + badges (saisons, non vus) | ✅ | |
| Prochain épisode (▶ SxxExx — Titre, bouton large) | ✅ | `_NextEpisodeButtonLarge` + `onStopped` |
| Casting | ✅ | |
| Onglets saisons | ✅ | `TabBar` + `_EpisodeList` |
| Lire toute la saison → playlist M3U | ✅ | `_PlaySeasonButton` |
| Choisir épisodes → sheet cochages → playlist M3U | ✅ | `_EpisodeSelectionSheet` |
| Sheet épisode : audio + sous-titres + Lire/Reprendre | ✅ | `_EpisodePlaySheet` + `_EpisodePlayButtons` |
| **Skip intro** (plugin IntroSkipper) | ✅ | Bouton "Passer l'intro (→ X:XX)" si plugin actif |
| **Rapport progression** par épisode | ✅ | `onStopped` dans `_EpisodePlayButtons` |
| Marquage vu/non vu par épisode | ✅ | |

---

## Lecteur externe (VLC / mpv)

| Feature | État | Détail |
|---|---|---|
| VLC détecté par défaut (`vlc` dans PATH) | ✅ | `getExternalPlayer()` |
| Chemin configurable (Paramètres) | ✅ | |
| Direct play (stream URL Static=true + api_key + DeviceId) | ✅ | |
| Reprise (`--start-time` VLC / `--start` mpv) | ✅ | |
| Sélection audio par index (0-based VLC, 1-based mpv) | ✅ | |
| Sélection sous-titres par index | ✅ | `--sub-track=-1` pour désactiver sur VLC |
| Sélection audio/sous-titres par langue ISO 639-2 | ✅ | |
| Playlist M3U (saison) via `getTemporaryDirectory()` | ✅ | |
| `ProcessStartMode.normal` + monitoring via `process.exitCode` | ✅ | VLC survit à la fermeture de JellyClient |
| Rapport progression à la fermeture | ✅ | `onStopped(estimatedTicks)` |
| Log debug `/tmp/jellyclient_launch.log` | ✅ | |

---

## Préférences de lecture

| Feature | État | Détail |
|---|---|---|
| Langue audio préférée (par userId) | ✅ | Clé `pref_audio_lang_<userId>` |
| Langue sous-titres préférée (null = désactivé) | ✅ | Clé `pref_sub_lang_<userId>` |
| Bouton Enregistrer + confirmation | ✅ | Obligatoire — les chips ne sauvegardent pas auto |
| Auto-sélection dans toutes les sheets de lecture | ✅ | |
| `matchesLang()` : synonymes ISO 639-2 (fre/fra/fr, deu/ger...) | ✅ | |

---

## Recherche & Navigation

| Feature | État | Détail |
|---|---|---|
| Recherche films + séries + acteurs (debounce 400ms) | ✅ | |
| Fiche acteur + filmographie | ✅ | `person_screen.dart` |
| Vue genre (grille) | ✅ | `genre_screen.dart` |
| Raccourcis clavier Echap / Ctrl+F / Ctrl+H | ✅ | |
| Navigation retour robuste (`canPop` guard) | ✅ | |

---

## Mes listes (Watchlist)

| Feature | État | Détail |
|---|---|---|
| Onglets À regarder + Déjà vu + compteurs | ✅ | |
| Grille/liste + tri + swipe-to-dismiss | ✅ | |
| Favoris Jellyfin ❤ synchronisés | ✅ | |

---

## Système

| Feature | État | Détail |
|---|---|---|
| Instance unique (PID lock, `getApplicationSupportDirectory()`) | ✅ | |
| Icône personnalisée (SVG "J" rouge, PNG 48/128/256, .desktop) | ✅ | `~/.local/share/icons/hicolor/` |
| Raccourci desktop (`~/bin/jelly` rsync build→install) | ✅ | |
| Redémarrer l'app (`Platform.resolvedExecutable + exit(0)`) | ✅ | |

---

## Ce qui reste à faire (Linux)

| # | Feature | Priorité |
|---|---|---|
| 1 | **Card hover élargie** : scale + popup débordant (style Netflix desktop) | Moyenne |
| 2 | Remplacer `palette_generator` (discontinued) | Faible |
