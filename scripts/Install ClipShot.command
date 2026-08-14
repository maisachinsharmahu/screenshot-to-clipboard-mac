#!/bin/bash
# Double-click this after downloading the DMG. It installs ClipShot to
# /Applications and clears the Gatekeeper quarantine flag that Safari/Chrome
# add on download — that flag is what causes the "ClipShot.app is damaged
# and can't be opened" message on an unnotarized app. Removing it is safe:
# it only tells macOS "I've reviewed this myself," which you're doing right
# now by reading this script before running it.
set -e
cd "$(dirname "$0")"

echo "ClipShot Installer"
echo "==================="
echo

if [ ! -d "ClipShot.app" ]; then
  echo "Error: ClipShot.app not found next to this script."
  echo "Make sure you're running this from inside the mounted ClipShot disk image."
  read -n 1 -s -r -p "Press any key to exit..."
  exit 1
fi

echo "Installing to /Applications..."
rm -rf "/Applications/ClipShot.app"
cp -R "ClipShot.app" "/Applications/"

echo "Clearing macOS download quarantine flag..."
xattr -cr "/Applications/ClipShot.app"

echo
echo "Done! Launching ClipShot..."
open "/Applications/ClipShot.app"

sleep 1
echo
echo "ClipShot is installed and running. You can close this window."
read -n 1 -s -r -p "Press any key to close..."
