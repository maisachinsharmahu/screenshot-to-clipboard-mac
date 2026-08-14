#!/bin/bash
# Bundled inside the app (Contents/Resources/) and run once, at the end of
# setup, after you choose a screenshots folder. Kept as its own file
# instead of inline code so exactly what it does to your system is
# transparent and auditable, not hidden inside the compiled binary.
#
# What it does:
#   1. Points macOS's own screenshot tool (Cmd+Shift+3/4/5) at your chosen
#      folder, via `defaults write com.apple.screencapture location`.
#   2. Disables the floating screenshot thumbnail preview, via
#      `defaults write com.apple.screencapture show-thumbnail false`.
#      That preview holds your screenshot in a temporary staging location
#      until it's dismissed or times out -- which delays the real file
#      from ever reaching your watched folder. Since this app copies it
#      to your clipboard automatically anyway, you don't need the
#      preview; disabling it means the file is written straight to disk
#      immediately, no delay.
#   3. Restarts SystemUIServer so both settings take effect immediately.
#
# Nothing here touches any file outside the two `defaults` preference
# domains named above. To undo it: see TROUBLESHOOTING.md / README.md's
# Uninstall section.

set -euo pipefail

FOLDER_PATH="$1"

if [ -z "$FOLDER_PATH" ]; then
  echo "Usage: configure-screencapture.sh <folder-path>" >&2
  exit 1
fi

/usr/bin/defaults write com.apple.screencapture location "$FOLDER_PATH"
/usr/bin/defaults write com.apple.screencapture show-thumbnail -bool false
/usr/bin/killall SystemUIServer >/dev/null 2>&1 || true
