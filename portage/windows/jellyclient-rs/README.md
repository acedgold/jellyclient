# JellyClient — Version Rust native

Client Jellyfin en Rust natif avec egui. Produit un **seul fichier .exe** autonome sur Windows.

## Avantages vs Flutter

| | Flutter | Rust/egui |
|---|---|---|
| Taille exe | ~50 MB (dossier) | **~8 MB** (1 fichier) |
| Dépendances | DLLs Flutter + data/ | **aucune** |
| Démarrage | ~2-3s | **<0.5s** |
| RAM | ~200 MB | **~30 MB** |
| Portable | Dossier entier | **1 fichier .exe** |

## Build (sur Windows)

```powershell
cd portage\windows\jellyclient-rs
cargo build --release
# Résultat : target\release\jellyclient.exe (~8 MB, standalone)
```

## Structure

```
src/
  main.rs       ← App egui + UI (login, home, library, detail)
  api/
    mod.rs      ← Client HTTP Jellyfin (reqwest blocking)
    models.rs   ← Types de données (serde)
  player.rs     ← Lancement VLC + détection automatique
assets/
  icon.png      ← Icône 256×256
```

## Fonctionnalités Phase 1

- ✅ Login (URL + username + password)
- ✅ Auto-détection VLC (portable bundlé > Program Files > PATH)
- ✅ Accueil : Bibliothèques + Continuer à regarder + Derniers ajouts
- ✅ Grille bibliothèque avec pagination
- ✅ Fiche détail (backdrop + poster + synopsis + bouton Lire)
- ✅ Lancement VLC avec reprise de position
- ✅ Thème dark cinéma (#0D0D0D + rouge #E50914)
- ✅ Images Jellyfin chargées automatiquement
- ✅ Tokens sauvegardés (Windows Credential Manager)

## Phase 2 (à venir)

- [ ] Vue Séries → Saisons → Épisodes
- [ ] Sélection audio/sous-titres avant lecture
- [ ] Recherche
- [ ] Progression rapportée à Jellyfin
- [ ] Hover avec actions rapides
