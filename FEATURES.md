# JellyClient — Parité des features Linux ↔ Windows

**Règle** : toute feature ajoutée à une plateforme doit être ajoutée ici avec ⬜ pour l'autre.  
Un agent qui implémente une feature sur sa plateforme met ✅ dans sa colonne et documente les notes de portage pour l'autre.

Légende : ✅ Fait · ⬜ À faire · N/A Non applicable · 🔄 En cours

> **Windows depuis v1.0.4** : la version Windows est **compilée en cloud** (GitHub
> Actions) et publiée à chaque release. Le code étant le même Flutter, les ⬜
> ci-dessous sont en pratique présents sur Windows dès le build — restent à
> confirmer à l'usage sur W11.

---

## Auth & Serveurs (refonte v1.0.3/1.0.4)

| Feature | Linux | Windows | Notes de portage |
|---|:---:|:---:|---|
| « Ajouter un serveur » = **URL seule** | ✅ | ✅ | Identique Flutter |
| **Page de login dédiée** : avatars utilisateurs publics | ✅ | ✅ | Identique Flutter |
| **Connexion manuelle** (comptes cachés) | ✅ | ✅ | Identique Flutter |
| **Changer de serveur** (pop-up) + responsive | ✅ | ✅ | Identique Flutter |
| Icône « sessions actives » réservée aux administrateurs | ✅ | ✅ | Identique Flutter |
| Multi-serveurs (`KnownServer` + `ServerProfile`) | ✅ | ✅ | Identique Flutter |
| DeviceId UUID unique (`jelly_device_id`) | ✅ | ✅ | Identique Flutter |
| Durcissement sécurité (détails en mémoire privée) | ✅ | ✅ | — |
| ~~Profils « Qui regarde ? » (`profiles_screen`)~~ | ❌ | ❌ | **Supprimé** (obsolète) |

---

## Accueil (Home)

| Feature | Linux | Windows | Notes de portage |
|---|:---:|:---:|---|
| Hero Banner (backdrop, logo, synopsis, genres, play) | ✅ | ⬜ | Identique Flutter |
| AppBar scroll transparent → opaque (ValueNotifier) | ✅ | ⬜ | Identique Flutter |
| Top 10 films (rail, numéros Netflix, hauteur adaptive) | ✅ | ⬜ | Identique Flutter |
| Flèches ← → sur toutes les sections horizontales | ✅ | ⬜ | Identique Flutter |
| Sections Continuer / Récents par lib / 4 Genres | ✅ | ⬜ | Identique Flutter |
| Pull-to-refresh | ✅ | ⬜ | Identique Flutter |

---

## Vignettes (MediaCard)

| Feature | Linux | Windows | Notes de portage |
|---|:---:|:---:|---|
| Hover overlay (▶ ♥ ℹ + synopsis + note) | ✅ | ⬜ | Identique Flutter — `MouseRegion` fonctionne sur W11 |
| Temps restant ("Xmin restant") sur card + overlay | ✅ | ⬜ | Identique Flutter |
| Barre de progression + badges (NOUVEAU, SÉRIE, VU) | ✅ | ⬜ | Identique Flutter |
| Lecture rapide (▶ hover) + rapport progression | ✅ | ⬜ | Identique Flutter |

---

## Bibliothèque

| Feature | Linux | Windows | Notes de portage |
|---|:---:|:---:|---|
| Grille adaptative + infinite scroll | ✅ | ⬜ | Identique Flutter |
| Tri + filtres type/genre + compteur | ✅ | ⬜ | Identique Flutter |

---

## Fiche Film

| Feature | Linux | Windows | Notes de portage |
|---|:---:|:---:|---|
| Backdrop + couleur dynamique (palette_generator) | ✅ | ⬜ | Identique Flutter |
| Métadonnées, genres cliquables, classification | ✅ | ⬜ | Identique Flutter |
| Bouton Lire → sheet audio/sous-titres → VLC | ✅ | ⬜ | VLC auto-détecté dans Program Files |
| Rapport progression (reportPlaybackStop + markPlayed) | ✅ | ⬜ | Tester `ProcessStartMode.normal` sur W11 |
| Favoris ❤ / Watchlist ♥ / Déjà vu ✓ | ✅ | ⬜ | Identique Flutter |
| Badge IMDb → ouvrir navigateur | ✅ | ⬜ | `xdg-open` → `cmd /c start <url>` sur Windows |
| Casting, More Like This, Provider IDs, Refresh | ✅ | ⬜ | Identique Flutter |

---

## Fiche Série

| Feature | Linux | Windows | Notes de portage |
|---|:---:|:---:|---|
| Header + onglets saisons + épisodes | ✅ | ⬜ | Identique Flutter |
| Prochain épisode + rapport progression | ✅ | ⬜ | Tester `ProcessStartMode.normal` sur W11 |
| Playlist M3U saison + sélection épisodes | ✅ | ⬜ | `getTemporaryDirectory()` → `%TEMP%` W11 ✅ |
| Skip intro (plugin IntroSkipper) | ✅ | ⬜ | Identique Flutter — endpoint plugin |
| Marquage vu/non vu par épisode | ✅ | ⬜ | Identique Flutter |

---

## Lecteur externe

| Feature | Linux | Windows | Notes de portage |
|---|:---:|:---:|---|
| Auto-détection VLC (PATH / Program Files) | ✅ | ✅ | Déjà codé dans `getExternalPlayer()` |
| Chemin VLC configurable (Paramètres) | ✅ | ⬜ | Identique Flutter |
| Direct play + reprise | ✅ | ⬜ | Identique Flutter |
| Sélection audio/sous-titres (index + langue) | ✅ | ⬜ | Identique Flutter |
| Playlist M3U (saison) | ✅ | ⬜ | Identique Flutter |
| `ProcessStartMode.normal` + rapport progression | ✅ | ⬜ | **Tester si VLC survit à la fermeture de l'app W11** |
| Variable `DISPLAY` conditionné `!isWindows` | ✅ | ✅ | Déjà fait |
| Split path `replaceAll('\\','/')` pour exe Windows | ✅ | ✅ | Déjà fait |

---

## Préférences de lecture

| Feature | Linux | Windows | Notes de portage |
|---|:---:|:---:|---|
| Langue audio/sous-titres par userId | ✅ | ⬜ | Identique Flutter (`SharedPreferences`) |
| Bouton Enregistrer + confirmation | ✅ | ⬜ | Identique Flutter |
| Auto-sélection dans toutes les sheets | ✅ | ⬜ | Identique Flutter |

---

## Recherche & Navigation

| Feature | Linux | Windows | Notes de portage |
|---|:---:|:---:|---|
| Recherche films + séries + acteurs | ✅ | ⬜ | Identique Flutter |
| Fiche acteur + filmographie | ✅ | ⬜ | Identique Flutter |
| Raccourcis clavier (Echap, Ctrl+F, Ctrl+H) | ✅ | ⬜ | Identique Flutter — clavier W11 OK |
| Navigation retour (`canPop` guard) | ✅ | ⬜ | Identique Flutter |

---

## Mes listes (Watchlist)

| Feature | Linux | Windows | Notes de portage |
|---|:---:|:---:|---|
| À regarder + Déjà vu + swipe-to-dismiss | ✅ | ⬜ | Identique Flutter |
| Favoris Jellyfin synchronisés | ✅ | ⬜ | Identique Flutter |

---

## Système & Icône

| Feature | Linux | Windows | Notes de portage |
|---|:---:|:---:|---|
| Instance unique (PID lock) | ✅ | ⬜ | `getApplicationSupportDirectory()` → `%APPDATA%` W11 (à tester) |
| Icône personnalisée | ✅ | ✅ | Linux : SVG+PNG · Windows : `.ico` multi-res |
| Raccourci bureau/menu | ✅ | ✅ | Linux : `.desktop` · Windows : `build_portable.ps1` |
| Redémarrer l'app | ✅ | ⬜ | Identique Flutter (`exit(0)`) |

---

## Features spécifiques à une plateforme

Ces features n'ont pas à être portées sur l'autre plateforme.

| Feature | Linux | Windows | Raison |
|---|:---:|:---:|---|
| `gtk-update-icon-cache` | ✅ | N/A | Spécifique Linux/GTK |
| `~/bin/jelly` rsync build→install | ✅ | N/A | Workflow Linux |
| `build_portable.ps1` (ZIP portable + VLC) | N/A | ✅ | Spécifique Windows |
| `Runner.rc` (métadonnées exe) | N/A | ✅ | Spécifique Windows |

---

## Comment utiliser ce fichier

**Quand tu ajoutes une feature sur Linux :**
1. Ajoute une ligne dans la bonne section avec Linux=✅, Windows=⬜
2. Note dans la colonne "Notes de portage" ce qui change sur Windows (ou "Identique Flutter")
3. L'agent Windows verra le ⬜ et saura quoi faire

**Quand tu ajoutes une feature sur Windows :**
1. Ajoute une ligne avec Windows=✅, Linux=⬜
2. Note ce qui change sur Linux
3. L'agent Linux verra le ⬜ et saura quoi faire

**Quand tu portes une feature :**
1. Change ⬜ → ✅ dans ta colonne
2. Met à jour `LINUX.md` ou `WINDOWS.md` selon la plateforme
