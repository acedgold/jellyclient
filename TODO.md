# JellyClient — TODO

> Détails par plateforme : **`LINUX.md`** et **`WINDOWS.md`**.

## Fait (v1.0.1 → v1.0.4)
- [x] Build & distribution Windows en cloud (GitHub Actions) + zip portable VLC
- [x] Distribution Linux (`portage/linux/package.sh`) + release GitHub par version
- [x] Liens « latest » permanents + branding page de connexion (streaming)
- [x] Version dans la barre de titre + icône de fenêtre Linux
- [x] Fix bibliothèque vide au retour + suppression filtres type
- [x] Page de login dédiée (avatars publics + manuel + changer de serveur, responsive)
- [x] Icône sessions actives réservée aux administrateurs
- [x] Durcissement sécurité (détails en mémoire privée)

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
