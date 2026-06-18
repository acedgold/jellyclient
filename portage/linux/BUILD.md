# Distribution Linux de JellyClient (bundle pré-compilé)

Permet d'installer JellyClient sur une autre machine Linux **sans y installer
Flutter** : on compile une fois sur la machine de dev, puis on transfère un
paquet auto-installable.

## 1. Construire le paquet (machine de dev)

```bash
cd portage/linux
./package.sh --build      # build release + assemblage
# ou, si le bundle est déjà compilé :
./package.sh
```

Résultat : `portage/linux/dist/jellyclient-linux-x64.tar.gz`.

## 2. Installer (machine cible)

```bash
tar xzf jellyclient-linux-x64.tar.gz
cd jellyclient-linux-x64
./install.sh
```

L'app apparaît dans le menu (« JellyClient »), avec une commande terminale
`jellyclient` et l'icône. Désinstallation : `./uninstall.sh` depuis le même
dossier.

## ⚠️ Compatibilité glibc — le point critique

Le bundle Flutter embarque le moteur Flutter mais **PAS la glibc** : il se lie
dynamiquement à celle de la machine cible. Règle :

> La machine cible doit avoir une glibc **≥ celle de la machine de build**.

| Machine de build         | glibc | Cibles compatibles                          |
|--------------------------|-------|---------------------------------------------|
| Linux Mint 22.x / Ubuntu 24.04 | 2.39  | Ubuntu 24.04+, **Zorin OS 18**, Mint 22.x   |
| Ubuntu 22.04             | 2.35  | Ubuntu 22.04+, Zorin OS 17/18, Mint 21.x    |
| Ubuntu 20.04             | 2.31  | quasi toutes les distros récentes           |

Symptôme d'incompatibilité : `version 'GLIBC_2.xx' not found` au lancement.
Pour viser des distros anciennes, **compiler sur une base plus ancienne**
(VM/conteneur Ubuntu 20.04 ou 22.04). L'installeur détecte le souci via `ldd`
et prévient avant de lancer.

## Pré-requis runtime sur la cible

- `libgtk-3-0` : `sudo apt install libgtk-3-0` (présent par défaut sur Zorin/Mint/Ubuntu desktop)
- Lecteur vidéo externe : `sudo apt install vlc` (ou mpv / celluloid)
