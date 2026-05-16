# JellyClient — Erreurs et pièges à éviter

Registre des bugs rencontrés. Mis à jour à chaque session.  
**Lire avant de modifier quoi que ce soit.**

---

## 24. Noms de personnes en rouge dans CastSection → illisible

**Symptôme** : Dans la fiche film/série, les noms des réalisateurs/scénaristes/producteurs s'affichent en rouge (#E50914) souligné sur fond noir — difficile à lire, ressemble à un lien web des années 90.  
**Cause** : `color: p.id != null ? const Color(0xFFE50914) : Colors.white` dans `cast_section.dart:72`.  
**Fix** : Changer en `Colors.white` avec `decorationColor: const Color(0xFF555555)` (soulignement discret gris). ✅ Corrigé 2026-05-15.

---

## 25. Chips genre bibliothèque en violet (#7B2FBE) → incohérent avec le thème rouge

**Symptôme** : Dans la bibliothèque, le chip "Tous genres" et les chips genre sélectionnés s'affichent en violet/pourpre au lieu du rouge thème #E50914.  
**Cause** : `selectedColor: const Color(0xFF7B2FBE)` hardcodé dans `library_screen.dart`.  
**Fix** : Remplacer par `Theme.of(context).colorScheme.primary`. ✅ Corrigé 2026-05-15.

---

## 26. Bouton tri ↑/↓ trop proéminent (rouge outline)

**Symptôme** : Le bouton "↑ A→Z" / "↓ Z→A" dans la barre de tri de la bibliothèque utilise la couleur primaire rouge (fond + bordure + texte) — trop dominant visuellement pour un contrôle secondaire.  
**Cause** : `color: colorScheme.primary.withOpacity(0.2)` pour le fond + `border: Border.all(color: colorScheme.primary)`.  
**Fix** : Fond `Color(0xFF2A2A2A)` neutre + texte `Colors.white70`. ✅ Corrigé 2026-05-15.

---

## 21. `setState` dans un listener de scroll → rebuild de toute la page à 60fps

**Symptôme** : L'app rame pendant le scroll, surtout sur la home avec beaucoup de sections.  
**Cause** : `_scrollController.addListener(() { setState(() => _alpha = ...) })` rebuilde le widget parent complet à chaque frame.  
**Fix** : `ValueNotifier<double> _alpha` + `ListenableBuilder` scoped sur le seul widget qui a besoin de se mettre à jour.  
**Règle** : Tout état lié au scroll = `ValueNotifier`. Ne jamais appeler `setState` dans un scroll listener.

---

## 22. `ref.watch(watchlistProvider)` sans `.select()` dans `MediaCard` → rebuild de toutes les cards

**Symptôme** : Ajouter un favori cause un freeze visible (toutes les cards rebuildbent).  
**Cause** : `ref.watch(watchlistProvider)` écoute la liste entière → tout changement rebuilde chaque `MediaCard` visible.  
**Fix** : `ref.watch(watchlistProvider.select((wl) => wl.any((i) => i.id == item.id)))` — seule la card concernée rebuild.  
**Règle** : Dans tout widget de liste, toujours `.select()` pour n'observer que l'état de l'item courant.

---

## 23. `onStopped` callback avec `ref` stale après pop

**Symptôme** : Crash ou état invalide quand VLC se ferme après navigation retour.  
**Cause** : `ref` (WidgetRef) est invalide après que le widget est pop/dispose. Le callback est appelé plus tard (fin de VLC).  
**Fix** : Capturer `client`, `server.userId`, `itemId`, `runTimeTicks` comme variables locales AVANT le launch. Ne jamais utiliser `ref` dans le callback `onStopped`.

---

## 12. `latestProvider` global → sections récents indifférenciées

**Symptôme** : Un seul bloc "Ajoutés récemment" qui mélange toutes les bibliothèques.  
**Cause** : `getLatest` sans `parentId` retourne les derniers items de tout le catalogue.  
**Fix** : Supprimer `latestProvider` global. Créer `_latestByLibraryProvider` (FutureProvider.family<List<JellyItem>, String>) avec `libraryId` comme paramètre. Itérer sur les `libraryViewsProvider` pour afficher une section par bibliothèque.  
**Ne pas refaire** : Ne pas utiliser un provider global pour "récents" — toujours filtrer par `parentId`.

---

## 13. `ProviderIds` dans `JellyItem` — champ non inclus par défaut

**Symptôme** : `item.providerIds` vide même quand Jellyfin connaît l'IMDb ID.  
**Cause** : L'endpoint `/Users/{id}/Items` et `/Users/{id}/Items/{id}` n'incluent pas `ProviderIds` sauf si demandé explicitement via `?Fields=ProviderIds,...`.  
**Fix** : Ajouter `ProviderIds` dans le paramètre `Fields` de `getItem`. Pour les listes (`getItems`, `getLatest`, etc.), ne pas l'inclure par défaut (trop lourd), uniquement sur la fiche détail.  
**Ne pas refaire** : Ne pas supposer qu'un champ Jellyfin est renvoyé automatiquement — vérifier la doc ou tester avec `?Fields=*`.

---

## 20. Recherche personnes — mauvais endpoint

**Symptôme** : `getItems` avec `IncludeItemTypes=Person` retourne 401 ou 0 résultat.  
**Cause** : Les personnes dans Jellyfin ne passent pas par `/Users/{id}/Items`. L'endpoint correct est `/Persons?searchTerm=...` (sans userId, juste le token dans le header).  
**Fix** : Méthode `searchPersons(query)` dans `JellyfinClient` qui appelle `/Persons`.  
**Ne pas refaire** : Ne jamais utiliser `getItems` avec `IncludeItemTypes=Person` — ça ne fonctionne pas.

---

## 19. Build en chaîne `flutter build && nohup ... &` — binaire non mis à jour

**Symptôme** : Le binaire garde son ancien timestamp après `flutter build linux --release && nohup ./jellyclient &`. La nouvelle version ne tourne pas.  
**Cause** : Quand `flutter build` est lancé depuis Claude Code (via Bash tool), le shell cwd est parfois réinitialisé avant la fin du build, interrompant la chaîne. Le `nohup` lance l'ancien binaire.  
**Fix** : Toujours séparer en deux appels Bash distincts : d'abord `flutter build linux --release`, puis dans un second appel `nohup ... &`.  
**Vérification** : `ls -la ~/development/jellyclient/build/linux/x64/release/bundle/jellyclient` → timestamp doit être récent.

---

## 18. `--no-subs` invalide dans VLC → crash silencieux

**Symptôme** : Clic sur "Lire" → rien ne se passe, VLC démarre (PID assigné) mais quitte immédiatement.  
**Cause** : L'argument `--no-subs` n'existe pas dans VLC. VLC accepte l'URL puis crashe sur l'argument inconnu. mpv lui a `--no-sub` (valide) — d'où la confusion.  
**Fix** : Utiliser `--sub-track=-1` pour désactiver les sous-titres dans VLC.  
**Leçon** : Toujours vérifier `vlc --help` avant d'ajouter des flags. Les flags mpv et VLC ne sont pas interchangeables.

| Lecteur | Désactiver sous-titres | Piste audio N | Piste sous-titre N |
|---|---|---|---|
| VLC | `--sub-track=-1` | `--audio-track=N` | `--sub-track=N` |
| mpv | `--no-sub` | `--aid=N+1` | `--sid=N+1` |

---

## 17. Relancer après modif oublié — `grep ... && flutter build` coupe la chaîne

**Symptôme** : L'app n'est pas relancée après une modification alors qu'on pensait avoir chaîné le build+lancement.  
**Cause** : Utiliser `flutter analyze 2>&1 | grep "^  error" && flutter build ...` — quand grep ne trouve rien (zéro erreur), il retourne exit code 1, ce qui interrompt le `&&` avant le build.  
**Fix** : Ne jamais mettre `grep` dans la chaîne de build. Toujours utiliser `flutter build linux --release && nohup ...` directement.  
**Règle** : Après chaque modification de code JellyClient → toujours builder ET relancer dans la même commande, sans grep intermédiaire.

---

## 14. `flutter analyze && flutter build` chaîné — exit code 1 masqué

**Symptôme** : `flutter analyze 2>&1 | grep error && flutter build` — si analyze retourne 0 erreurs, le grep retourne exit code 1 (aucun match) ce qui court-circuite le `&&` et empêche le build.  
**Fix** : Séparer en deux commandes distinctes. Ne jamais chaîner `grep ... && flutter build`.

---

## 15. `pkill -f jellyclient && nohup jellyclient &` — exit code 144 (signal TERM sur le shell)

**Symptôme** : Exit code 144 quand on chaîne `pkill` et `nohup` dans la même commande bash.  
**Cause** : `pkill -f jellyclient` peut matcher le processus bash courant si "jellyclient" apparaît dans ses arguments. Le shell reçoit SIGTERM (144 = 128 + 16).  
**Fix** : Toujours séparer en deux commandes : d'abord `pkill`, puis dans un appel bash séparé `nohup ... &`. Ou utiliser `pkill -f "bundle/jellyclient"` (pattern plus précis).

---

## 16. Saisons Jellyfin — endpoint `/Shows/{id}/Seasons` et non `/Users/{id}/Items`

**Symptôme** : `getSeasons` avec `ParentId={seriesId}&IncludeItemTypes=Season` retourne 0 résultats.  
**Cause** : Jellyfin expose les saisons via l'endpoint dédié `/Shows/{seriesId}/Seasons?UserId={userId}` et non via l'endpoint générique `/Users/{id}/Items`.  
**Fix** : Utiliser `GET /Shows/{seriesId}/Seasons?UserId={userId}&Fields=...` pour les saisons. L'endpoint générique fonctionne pour les épisodes (`ParentId={seasonId}&IncludeItemTypes=Episode`).

---

---

## 1. CIFS — symlinks impossibles → `flutter pub get` crash

**Symptôme** : `FileSystemException: Cannot create link ... (OS Error: Operation not supported, errno = 95)`  
**Cause** : Le projet était dans `un partage réseau/` sur un partage CIFS/SMB. Flutter crée des symlinks dans `windows/flutter/ephemeral/.plugin_symlinks/` et `linux/flutter/ephemeral/`. CIFS rejette `symlink()`.  
**Fix** : Développer dans `~/development/jellyclient/` (filesystem local). Synchroniser vers un répertoire réseau avec `rsync --exclude=build --exclude=.dart_tool`.  
**Ne pas refaire** : Ne jamais faire `flutter pub get` ou `flutter build` depuis un chemin CIFS.

---

## 2. JSON PascalCase — `null is not a subtype of String`

**Symptôme** : Crash au chargement des items Jellyfin. `_JellyItemFromJson` retourne null pour tous les champs.  
**Cause** : L'API Jellyfin retourne `{"Id": "...", "Name": "..."}` (PascalCase). `json_serializable` par défaut mappe les champs Dart camelCase (`id`, `name`) vers les clés JSON camelCase (`id`, `name`). Résultat : tous les champs sont null.  
**Fix** : Ajouter `@JsonKey(name: 'Id')`, `@JsonKey(name: 'Name')` etc. sur **chaque champ** de `JellyItem`, `UserData`, `MediaStream`, etc.  
**À ne pas faire** : Ajouter un `build.yaml` avec `field_rename: pascal` — ça casse la sérialisation de `ServerProfile` (modèle interne stocké en camelCase dans SharedPreferences).

---

## 3. `build.yaml` field_rename:pascal — casse ServerProfile

**Symptôme** : Crash au démarrage — `ServerProfile.fromJson` ne trouve pas les champs.  
**Cause** : `field_rename: pascal` s'applique à **tous** les modèles, y compris `ServerProfile` qui est un modèle interne sauvegardé en camelCase dans SharedPreferences.  
**Fix** : Supprimer `build.yaml`. Utiliser `@JsonKey` explicite uniquement sur les modèles API Jellyfin.  
**Nettoyage associé** : Effacer `~/.local/share/dev.acedgold.jellyclient/shared_preferences.json` après ce changement (données corrompues).

---

## 4. GoRouter redirect — `ref.read` interdit dans le callback

**Symptôme** : `Cannot use ref functions after the dependency of a provider changed but before the provider rebuilt`  
**Cause** : Dans `routerProvider`, `ref.watch(activeServerProvider)` capture la valeur. Mais dans le callback `redirect:`, un deuxième `ref.read(activeServerProvider)` était appelé pendant que Riverpod était en train de rebâtir.  
**Fix** : Utiliser la variable `activeServer` capturée par `ref.watch` directement dans le closure `redirect:`. Ne jamais appeler `ref.read` ou `ref.watch` à l'intérieur d'un callback go_router.

---

## 5. `context.pop()` — crash "There is nothing to pop"

**Symptôme** : `GoError: There is nothing to pop` quand l'utilisateur clique le bouton retour.  
**Cause** : Certains écrans sont la route racine du stack (navigués avec `context.go()`). `context.pop()` échoue si le stack est vide.  
**Fix** : Toujours utiliser `context.canPop() ? context.pop() : context.go('/home')` pour les boutons retour.  
**Fichiers concernés** : `detail_screen.dart`, `library_screen.dart`, `servers_screen.dart`, `settings_screen.dart`, `search_screen.dart`.

---

## 6. media_kit — écran bleu (rendu H/W AMD X11)

**Symptôme** : Le son fonctionne, l'image reste bleue. `Using H/W rendering` dans les logs.  
**Cause** : media_kit tente un rendu OpenGL sur GPU AMD (radeonsi/renoir) via X11. Le chemin texture GPU → Flutter texture ne fonctionne pas dans cette config.  
**Fix tenté** : `enableHardwareAcceleration: false` sur `VideoController` + `gpu-context=x11` + `hwdec=no` via `NativePlayer.setProperty`.  
**Résultat** : Image OK mais contrôles (`MaterialVideoControls`) disparus car le mode software change le pipeline de rendu.  
**Fix final** : **Abandon de media_kit**, passage au lecteur externe (VLC/mpv via `Process.start`).  
**Leçon** : Ne pas réintégrer media_kit sans avoir vérifié le rendu GPU sur cette machine d'abord.

---

## 7. media_kit — contrôles invisibles avec `VideoControllerConfiguration(enableHardwareAcceleration: false)`

**Symptôme** : Image visible mais play/pause/barre de progression disparaissent.  
**Cause** : `enableHardwareAcceleration: false` change le backend de rendu. Le widget `MaterialVideoControls` utilise la même surface que la vidéo. En mode software, l'overlay des contrôles n'est plus rendu.  
**Fix** : Ne pas utiliser ce flag. Voir erreur #6 — solution = lecteur externe.

---

## 8. Indices pistes VLC — confusion Jellyfin absolu vs VLC relatif

**Symptôme** : VLC ouvre le bon film mais joue la mauvaise piste audio / pas de sous-titres.  
**Cause** : L'API Jellyfin retourne `MediaStream.index` = index absolu parmi **tous** les streams (vidéo, audio, sous-titre confondus). VLC `--audio-track=N` = index 0-based parmi les pistes **audio uniquement**.  
**Fix** : `_relativePos()` dans `_PlayButton` — filtre les streams par type, puis trouve la position 0-based du stream sélectionné.  
**Différence VLC vs mpv** : VLC = 0-based, mpv = 1-based (`--aid=N+1`, `--sid=N+1`).

---

## 9. `Process.start` avec `pkill jellyclient` — exit code 144

**Symptôme** : Commande bash `pkill -f jellyclient && nohup ./jellyclient &` retourne exit code 144 (= 128+16, signal TERM).  
**Cause** : `pkill` tue aussi la session bash courante si le pattern match le processus parent.  
**Fix** : Séparer en deux commandes distinctes — d'abord `pkill`, puis dans une nouvelle commande `nohup ./jellyclient &`.

---

## 10. `isar_generator` — non disponible sur pub.dev pour Flutter 3.41

**Symptôme** : `Because jellyclient depends on isar_generator ^3.1.8 which doesn't match any versions`  
**Cause** : isar_generator v3 n'est plus publié pour Dart 3.11.x.  
**Fix** : Remplacer Isar par `shared_preferences` (settings) + `flutter_secure_storage` (tokens). Pas de BD locale pour le cache — Riverpod gère le cache en mémoire.

---

## 11. `flutter run` non-interactif — "Lost connection to device"

**Symptôme** : L'app se lance, fonctionne quelques secondes, puis "Lost connection to device".  
**Cause** : `flutter run` en mode non-interactif (bash sans stdin) se déconnecte quand il détecte que stdin est fermé.  
**Fix** : Utiliser `flutter build linux --release` + lancer le binaire directement avec `nohup ... &`.  
**Note** : Pour le hot-reload pendant le dev, ouvrir un vrai terminal et lancer `flutter run -d linux` manuellement.
