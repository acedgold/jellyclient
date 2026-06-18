#!/usr/bin/env bash
#
# Désinstalle JellyClient (installé via install.sh).
#
set -euo pipefail

APP_NAME="jellyclient"
INSTALL_DIR="$HOME/.local/share/$APP_NAME"
DESKTOP_FILE="$HOME/.local/share/applications/$APP_NAME.desktop"
ICON_FILE="$HOME/.local/share/icons/hicolor/scalable/apps/$APP_NAME.svg"
BIN_LINK="$HOME/.local/bin/$APP_NAME"

echo "==> Désinstallation de JellyClient"
rm -rf "$INSTALL_DIR"
rm -f "$DESKTOP_FILE" "$ICON_FILE" "$BIN_LINK"

command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$(dirname "$DESKTOP_FILE")" 2>/dev/null || true

echo "✓ JellyClient désinstallé."
echo "  (Les serveurs/préférences enregistrés ne sont pas supprimés ici.)"
