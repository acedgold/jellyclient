# JellyClient — TODO

> Détails par plateforme : **`LINUX.md`** et **`WINDOWS.md`**.

## Fait (v1.0.1 → v1.0.6)
- [x] Build & distribution Windows en cloud (GitHub Actions) + zip portable VLC
- [x] Distribution Linux (`portage/linux/package.sh`) + release GitHub par version
- [x] Liens « latest » permanents + branding page de connexion (streaming)
- [x] Version dans la barre de titre + icône de fenêtre Linux
- [x] Fix bibliothèque vide au retour + suppression filtres type
- [x] Page de login dédiée (avatars publics + manuel + changer de serveur, responsive)
- [x] Icône sessions actives réservée aux administrateurs
- [x] Durcissement sécurité (détails en mémoire privée)
- [x] v1.0.5 vignettes biblio alignées accueil · v1.0.6 hero fiche + badges
- [x] Cible macOS (lecteur VLC, entitlements)

## Fait (v1.0.8)
- [x] Accueil : vignettes +10 %, polices (nom/synopsis/note) et titres de section agrandis
- [x] Vignettes séries : badge nombre d'épisodes non vus (haut-droit), langue à gauche
- [x] Vignettes films : badge durée (haut-gauche)
- [x] Refonte esthétique des écrans Paramètres et Mes listes (cartes, en-têtes)

## Fait (v1.0.7)
- [x] Lecture : sélection audio/sous-titres par **index** (VLC ignore
      `--audio-language` sur flux réseau) + sous-titres **non forcés** préférés
- [x] Note des épisodes affichée (★) dans la liste des saisons
- [x] Fenêtre de connexion redessinée (carte, avatar, champs, bascule mot de passe)
- [x] Barre du haut réorganisée en 3 zones (navigation / tailles vignettes / compte)
- [x] Images acteurs agrandies (+32 %)
- [x] Durcissement sécurité et fiabilité de la connexion
- [x] 0 warning analyzer (config `invalid_annotation_target` + code mort retiré)
- Décision : **pas** de feature « VO audio » (aucune donnée fiable de langue
      originale côté Jellyfin → abandonnée, préférences laissées telles quelles)

## À faire

### Multi-plateforme
- [ ] Confirmer à l'usage sur Windows W11 : lecture VLC (survie du process), instance
      unique, persistance de session, ouverture URL IMDb
- [ ] Branding du 2ᵉ serveur Jellyfin (en attente d'accès)

### Linux
- [ ] Card hover élargie (scale + popup débordant, style Netflix desktop)
- [ ] Remplacer `palette_generator` (discontinued)

### iOS
- [ ] Build iOS (lecteur interne, `url_launcher`, pas d'`exit()`)

### Maintenance versionnage
- [ ] À chaque release : bumper la version dans la barre de titre (2 fichiers natifs)
