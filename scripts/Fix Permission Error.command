#!/bin/bash
# If ClipShot won't open ("app is damaged" or "unidentified developer"),
# just double-click this file. That's it — one command, nothing else.
xattr -cr "/Applications/ClipShot.app"
echo
echo "Done. Try opening ClipShot again — it should work now."
read -n 1 -s -r -p "Press any key to close..."
