#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

BINARY_NAME="ScreenshotToClipboard"   # Swift product name (Contents/MacOS/<this>)
APP_NAME="ClipShot"                   # .app bundle display name in Finder
BUILD_DIR=".build/release"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

echo "==> Building release binary"
swift build -c release

echo "==> Assembling .app bundle"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$BINARY_NAME" "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"
cp Resources/Info.plist "$APP_BUNDLE/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
cp Resources/configure-screencapture.sh "$APP_BUNDLE/Contents/Resources/configure-screencapture.sh"
chmod +x "$APP_BUNDLE/Contents/Resources/configure-screencapture.sh"

echo "==> Ad-hoc code signing"
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> Verifying"
codesign --verify --verbose "$APP_BUNDLE"
spctl --assess --type execute "$APP_BUNDLE" 2>&1 || echo "(expected: not notarized — see README for first-launch instructions)"

echo "==> Done: $APP_BUNDLE"
