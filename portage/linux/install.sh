#!/usr/bin/env bash
#
# Installeur JellyClient pour Linux (bundle Flutter pré-compilé).
# À lancer sur la machine cible : ./install.sh
#
# Pré-requis cible : glibc >= celle de la machine de build (voir BUILD.md),
# GTK3 et un lecteur vidéo externe (VLC recommandé, ou mpv/Celluloid).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="jellyclient"
BUNDLE_SRC="$SCRIPT_DIR/bundle"

INSTALL_DIR="$HOME/.local/share/$APP_NAME"
BIN_LINK_DIR="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"

echo "==> Installation de JellyClient"

# 1. Vérifications
if [[ ! -x "$BUNDLE_SRC/$APP_NAME" ]]; then
  echo "ERREUR : bundle introuvable ($BUNDLE_SRC/$APP_NAME)." >&2
  echo "        Lancez ce script depuis le dossier extrait du paquet." >&2
  exit 1
fi

# Test de compatibilité glibc : si le binaire ne peut pas résoudre ses libs,
# on prévient l'utilisateur au lieu d'un crash silencieux au lancement.
if command -v ldd >/dev/null 2>&1; then
  if ldd "$BUNDLE_SRC/$APP_NAME" 2>&1 | grep -qi "not found"; then
    echo "ATTENTION : des bibliothèques système manquent sur cette machine :" >&2
    ldd "$BUNDLE_SRC/$APP_NAME" 2>&1 | grep -i "not found" >&2
    echo "         (souvent GLIBC trop ancienne, ou GTK3 absent)." >&2
    echo "         GTK3 : sudo apt install libgtk-3-0" >&2
    read -r -p "Continuer quand même l'installation ? [o/N] " ans
    [[ "${ans,,}" == "o" ]] || { echo "Abandon."; exit 1; }
  fi
fi

# 2. Copie du bundle
echo "==> Copie de l'application vers $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "$BUNDLE_SRC/" "$INSTALL_DIR/"
else
  rm -rf "$INSTALL_DIR"/*
  cp -a "$BUNDLE_SRC/." "$INSTALL_DIR/"
fi
chmod +x "$INSTALL_DIR/$APP_NAME"

# 3. Icône
echo "==> Installation de l'icône"
mkdir -p "$ICON_DIR"
if [[ -f "$SCRIPT_DIR/$APP_NAME.svg" ]]; then
  cp "$SCRIPT_DIR/$APP_NAME.svg" "$ICON_DIR/$APP_NAME.svg"
fi

# 4. Raccourci .desktop (chemins générés dynamiquement → portable inter-utilisateurs)
echo "==> Création du raccourci application"
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/$APP_NAME.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=JellyClient
Comment=Client Jellyfin dark cinéma
Exec=$INSTALL_DIR/$APP_NAME
Icon=$APP_NAME
Terminal=false
Categories=AudioVideo;Video;Player;
StartupNotify=true
Keywords=jellyfin;media;film;serie;streaming;
EOF

# 5. Commande terminal optionnelle (~/.local/bin/jellyclient)
mkdir -p "$BIN_LINK_DIR"
ln -sf "$INSTALL_DIR/$APP_NAME" "$BIN_LINK_DIR/$APP_NAME"

# 6. Rafraîchir les caches
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
command -v gtk-update-icon-cache  >/dev/null 2>&1 && gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

echo ""
echo "✓ JellyClient installé."
echo "  • Lancer depuis le menu (chercher « JellyClient »)"
echo "  • Ou en terminal : $APP_NAME  (si ~/.local/bin est dans le PATH)"
echo "  • Ou directement : $INSTALL_DIR/$APP_NAME"
echo ""
echo "  Lecteur externe requis : sudo apt install vlc"
