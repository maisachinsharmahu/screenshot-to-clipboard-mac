#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="ClipShot"
DIST_DIR="dist"
STAGING="dist/dmg_staging"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"

if [ ! -d "$DIST_DIR/$APP_NAME.app" ]; then
  echo "Build the app first: ./scripts/build_app.sh"
  exit 1
fi

rm -rf "$STAGING" "$DMG_PATH"
mkdir -p "$STAGING"
cp -R "$DIST_DIR/$APP_NAME.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG_PATH"
rm -rf "$STAGING"

echo "==> Done: $DMG_PATH"
