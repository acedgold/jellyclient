# JellyClient — Architecture

## Stack

| Couche | Package | Version |
|---|---|---|
| UI + State | flutter_riverpod + hooks_riverpod | 2.6.1 |
| Hooks | flutter_hooks | 0.21.3 |
| Routing | go_router | 14.8.1 |
| HTTP | dio | 5.9.2 |
| Stockage simple | shared_preferences | 2.5.5 |
| Stockage sécurisé | flutter_secure_storage | 9.2.4 |
| Images | cached_network_image | 3.4.1 |
| Modèles | freezed_annotation + json_annotation | 2.4.4 / 4.9.0 |

**Pas de media_kit** — lecteur externe (VLC/mpv) via `Process.start`.

## Arborescence lib/

```
lib/
├── main.dart                          # Entry point, PID lock, ProviderScope
├── core/
│   ├── api/
│   │   ├── jellyfin_client.dart       # Client HTTP Dio — tous les appels API
│   │   ├── interceptors/
│   │   │   └── auth_interceptor.dart  # Header X-Emby-Authorization
│   │   └── models/
│   │       ├── jellyfin_models.dart   # JellyItem, JellyPerson, ServerProfile...
│   │       ├── jellyfin_models.freezed.dart  # GÉNÉRÉ
│   │       └── jellyfin_models.g.dart        # GÉNÉRÉ
│   ├── providers/
│   │   └── app_providers.dart         # activeServerProvider, jellyfinClientProvider
│   ├── router.dart                    # GoRouter — 8 routes
│   ├── services/
│   │   └── external_player.dart       # Process.start VLC/mpv + calcul indices pistes
│   └── storage/
│       └── server_storage.dart        # CRUD serveurs (SharedPrefs + SecureStorage)
├── features/
│   ├── auth/
│   │   ├── add_server_screen.dart     # Formulaire connexion
│   │   └── servers_screen.dart        # Liste serveurs, switch actif
│   ├── detail/
│   │   └── detail_screen.dart         # Fiche film : backdrop, pistes, casting, providers
│   ├── home/
│   │   └── home_screen.dart           # Bibliothèques (cartes image) + resume + récents
│   ├── library/
│   │   └── library_screen.dart        # Grille + pagination + tri ↑↓ + chips type
│   ├── search/
│   │   └── search_screen.dart         # Recherche debounce 400ms
│   ├── series/
│   │   └── series_screen.dart         # Série : header + casting + onglets saisons + épisodes
│   └── settings/
│       └── settings_screen.dart       # Lecteur externe + bouton redémarrer
└── shared/
    ├── theme/
    │   └── app_theme.dart             # ThemeData dark cinéma + JellyColors
    └── widgets/
        ├── cast_section.dart          # CastSection + ActorRow (partagé film+série)
        └── media_card.dart            # MediaCard + navigateToItem()
```

## API Jellyfin — endpoints utilisés

| Endpoint | Usage |
|---|---|
| `POST /Users/AuthenticateByName` | Login |
| `GET /System/Info` | Ping serveur |
| `GET /Users/{id}/Views` | Médiathèques (id + collectionType) |
| `GET /Users/{id}/Items` | Liste items (parentId, sortBy, limit, startIndex...) |
| `GET /Users/{id}/Items/{itemId}` | Fiche détail (People, ProviderIds, Taglines...) |
| `GET /Users/{id}/Items/Resume` | Continuer à regarder |
| `GET /Users/{id}/Items/Latest` | Ajouts récents par bibliothèque |
| `GET /Shows/{id}/Seasons` | Saisons d'une série |
| `GET /Videos/{id}/stream?Static=true` | Stream direct play |
| `GET /Items/{id}/Images/{type}` | Pochettes, backdrops, photos acteurs |
| `POST /Items/{id}/Refresh` | Rafraîchir métadonnées (FullRefresh) |
| `POST /Users/{id}/FavoriteItems/{id}` | Favoris |
| `POST /Sessions/Playing/Progress` | Heartbeat lecture en cours |
| `POST /Sessions/Playing/Stopped` | Fin de lecture + position |
| `POST /Users/{id}/PlayedItems/{id}` | Marquer comme vu |
| `DELETE /Users/{id}/PlayedItems/{id}` | Marquer comme non vu |
| `GET /Episode/{id}/IntroTimestamps` | Plugin IntroSkipper — début/fin intro (secondes) |
| `GET /Shows/NextUp` | Prochain épisode à voir |

## Points d'attention critiques

- **CIFS** : jamais `flutter pub get`/`build` dans VibeCoding — symlinks impossibles
- **JSON PascalCase** : `@JsonKey(name:'Id')` sur chaque champ Jellyfin. Pas de `build.yaml field_rename:pascal`
- **GoRouter redirect** : utiliser la variable capturée par `ref.watch`, jamais `ref.read` dans le callback
- **context.pop()** : toujours `context.canPop() ? context.pop() : context.go('/home')`
- **Build + lancer** : `flutter build && nohup ...` sans grep intermédiaire (exit code 1 coupe la chaîne)
- **Indices pistes VLC** : Jellyfin = index absolu, VLC = 0-based par type, mpv = 1-based
- **Episodes orphelins** : dans une vue Library avec `recursive=false`, Episode = fichier mal indexé → masqué
- **SortBy=Random** : utilisé pour l'image aléatoire des cartes bibliothèque
- **collectionType null** : Jellyfin ne retourne pas toujours collectionType → filtre par chips manuel

## Routing — logique de navigation

`navigateToItem(context, item)` dans `media_card.dart` :
- `type == 'Series'` → `/series/:id`
- `type == 'Episode'` → `/series/:seriesId`
- tout le reste → `/detail/:id`

## Lecteur externe

```
launchWithExternalPlayer(url, title, startTicks, audioTrackPos, subtitleTrackPos,
                         audioLang?, subLang?, onStopped?)
  → getExternalPlayer() → SharedPreferences → 'vlc' (défaut Linux) / auto-détection Windows
  → _buildArgs() → args spécifiques VLC ou mpv
  → Process.start(player, args, mode: ProcessStartMode.normal)  ← PAS detached
  → si onStopped != null : unawaited(process.exitCode.then(...))
       estimatedTicks = startTicks + elapsed.inMilliseconds * 10000
       → onStopped(estimatedTicks)
```

**Rapport progression** : les call sites capturent `client`, `userId`, `itemId`, `runTimeTicks` avant le launch (ref peut être invalide après pop). Dans `onStopped` :  
- `client.reportPlaybackStop(itemId, estimatedTicks)`  
- si `estimatedTicks >= runTimeTicks * 0.9` → `client.markPlayed(userId, itemId)`

VLC : `--audio-track=N` (0-based), `--sub-track=N`, `--sub-track=-1` (désactiver)  
mpv : `--aid=N+1` (1-based), `--sid=N+1`, `--no-sub`

## Skip intro

```
getIntroTimestamps(episodeId) → (double start, double end)?
  → GET /Episode/{id}/IntroTimestamps  (plugin IntroSkipper)
  → retourne null si plugin absent (404) — silencieux
```

`_introTimestampsProvider` (FutureProvider.family) dans `series_screen.dart`.  
`_EpisodePlayButtons` widget : bouton "Passer l'intro (→ M:SS)" si `introEnd != null`.  
Lance VLC avec `startTicks = (introEnd * 10000000).toInt()`.

## Modèles ajoutés

`ChapterInfo` (`startPositionTicks`, `name`) + champ `chapters: List<ChapterInfo>` dans `JellyItem`.  
`Chapters` inclus dans `Fields` de `getItem`.

## Performance — règles à ne pas casser

| Pattern | À faire | À NE PAS faire |
|---|---|---|
| État lié au scroll | `ValueNotifier` + `ValueListenableBuilder` | `setState` dans un listener de scroll |
| Watchlist dans MediaCard | `watchlistProvider.select((wl) => wl.any((i) => i.id == item.id))` | `ref.watch(watchlistProvider)` sans select |
| Hover overlay | Entourer `AnimatedOpacity` d'un `RepaintBoundary` | Laisser l'animation propager les repaints |
| Listes horizontales fixes | `ListView.builder` + `itemExtent: cardW + gap` | `ListView.separated` (mesure chaque item) |
| AppBar alpha | `ValueNotifier` + `ListenableBuilder` scoped | `setState` dans `_HomeScreenState._onScroll` |
