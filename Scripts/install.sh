#!/bin/bash
set -euo pipefail

APP_NAME="ScreenAnchor"
APP_BUNDLE="${APP_NAME}.app"
INSTALL_DIR="$HOME/Applications"

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "Error: ${APP_BUNDLE} not found. Run 'make bundle' first."
    exit 1
fi

echo "==> Installing to ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}"

# Stop running instance if any
pkill -x "${APP_NAME}" 2>/dev/null || true
sleep 0.5

# Copy to Applications
rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
cp -R "${APP_BUNDLE}" "${INSTALL_DIR}/${APP_BUNDLE}"

echo "==> Installed to ${INSTALL_DIR}/${APP_BUNDLE}"
echo "    Launch: open ${INSTALL_DIR}/${APP_BUNDLE}"
