#!/usr/bin/env bash
#
# Construit le paquet de distribution Linux de JellyClient.
# À lancer sur la MACHINE DE DÉVELOPPEMENT (celle qui a Flutter).
#
# Produit : portage/linux/dist/jellyclient-linux-x64.tar.gz
# contenant le bundle compilé + install.sh + uninstall.sh + icône.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUNDLE="$PROJECT_ROOT/build/linux/x64/release/bundle"
DIST="$SCRIPT_DIR/dist"
STAGE="$DIST/jellyclient-linux-x64"

export PATH="$HOME/development/flutter/bin:$PATH"

# 1. (Re)build release si demandé : ./package.sh --build
if [[ "${1:-}" == "--build" ]]; then
  echo "==> flutter build linux --release"
  ( cd "$PROJECT_ROOT" \
    && flutter pub get \
    && dart run build_runner build --delete-conflicting-outputs \
    && flutter build linux --release )
fi

if [[ ! -x "$BUNDLE/jellyclient" ]]; then
  echo "ERREUR : bundle introuvable. Lancez : ./package.sh --build" >&2
  exit 1
fi

# 2. Mise en scène
echo "==> Assemblage du paquet"
rm -rf "$STAGE"
mkdir -p "$STAGE/bundle"
cp -a "$BUNDLE/." "$STAGE/bundle/"
cp "$SCRIPT_DIR/install.sh"   "$STAGE/install.sh"
cp "$SCRIPT_DIR/uninstall.sh" "$STAGE/uninstall.sh"
cp "$SCRIPT_DIR/jellyclient.svg" "$STAGE/jellyclient.svg"
chmod +x "$STAGE/install.sh" "$STAGE/uninstall.sh"

# Note de compatibilité glibc dans le paquet
GLIBC="$(ldd --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo '?')"
cat > "$STAGE/LISEZ-MOI.txt" <<EOF
JellyClient — paquet Linux x86_64 (bundle Flutter pré-compilé)

Installation :
  tar xzf jellyclient-linux-x64.tar.gz
  cd jellyclient-linux-x64
  ./install.sh

Désinstallation :
  ./uninstall.sh   (dans le même dossier)

Pré-requis cible :
  - glibc >= $GLIBC  (ce paquet a été compilé sur une machine glibc $GLIBC ;
    une machine cible plus ANCIENNE refusera de lancer le binaire)
  - GTK3 :  sudo apt install libgtk-3-0
  - Lecteur vidéo externe :  sudo apt install vlc   (ou mpv / celluloid)
EOF

# 3. Archive
echo "==> Compression"
tar -C "$DIST" -czf "$DIST/jellyclient-linux-x64.tar.gz" "jellyclient-linux-x64"
rm -rf "$STAGE"

echo ""
echo "✓ Paquet prêt :"
ls -lh "$DIST/jellyclient-linux-x64.tar.gz"
echo ""
echo "  Transférez-le sur la machine cible, puis :"
echo "    tar xzf jellyclient-linux-x64.tar.gz && cd jellyclient-linux-x64 && ./install.sh"
