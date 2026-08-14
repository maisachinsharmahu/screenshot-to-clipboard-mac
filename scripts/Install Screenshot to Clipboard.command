#!/bin/bash
# Double-click this after downloading the DMG. It installs Screenshot to
# Clipboard to /Applications and clears the Gatekeeper quarantine flag that
# Safari/Chrome add on download — that flag is what causes the "app is
# damaged and can't be opened" message on an unnotarized app. Removing it is
# safe: it only tells macOS "I've reviewed this myself," which you're doing
# right now by reading this script before running it.
set -e
cd "$(dirname "$0")"

APP_NAME="Screenshot to Clipboard"

echo "$APP_NAME Installer"
echo "==================="
echo

if [ ! -d "$APP_NAME.app" ]; then
  echo "Error: $APP_NAME.app not found next to this script."
  echo "Make sure you're running this from inside the mounted disk image."
  read -n 1 -s -r -p "Press any key to exit..."
  exit 1
fi

echo "Installing to /Applications..."
rm -rf "/Applications/$APP_NAME.app"
cp -R "$APP_NAME.app" "/Applications/"

echo "Clearing macOS download quarantine flag..."
xattr -cr "/Applications/$APP_NAME.app"

echo
echo "Done! Launching $APP_NAME..."
open "/Applications/$APP_NAME.app"

sleep 1
echo
echo "$APP_NAME is installed and running. You can close this window."
read -n 1 -s -r -p "Press any key to close..."
