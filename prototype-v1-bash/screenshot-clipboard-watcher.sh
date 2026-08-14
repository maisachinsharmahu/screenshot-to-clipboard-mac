#!/bin/bash
# Persistent watcher: sits in a tight sleep loop and auto-copies any newly
# created screenshot/screen-recording to the clipboard, so you never have to
# grab the floating thumbnail before it vanishes.
#
# Detection loop never blocks: each copy runs in the background, guarded so
# that only the truly-latest screenshot ever wins the clipboard, even if an
# older copy is still mid-flight when a newer screenshot arrives.
#
# ARCHIVED — superseded by the native Swift app in Sources/ScreenshotToClipboard/.

RAW_LOCATION=$(defaults read com.apple.screencapture location 2>/dev/null)
if [ -n "$RAW_LOCATION" ]; then
  SCREENSHOT_DIR="${RAW_LOCATION/#\~/$HOME}"
else
  SCREENSHOT_DIR="$HOME/Desktop"
fi

[ -d "$SCREENSHOT_DIR" ] || exit 1

TARGET_MARKER="$HOME/.screenshot_watcher_target"
JXA_HELPER="$HOME/bin/copy-to-clipboard.js"

find_newest() {
  find "$SCREENSHOT_DIR" -maxdepth 1 -type f \
    \( -iname "Screenshot*.png" -o -iname "Screenshot*.jpg" -o -iname "Screenshot*.jpeg" \
       -o -iname "Screenshot*.heic" -o -iname "Screenshot*.tiff" \
       -o -iname "Screen Recording*.mov" \) \
    -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -n 1
}

copy_to_clipboard_async() {
  local FILE="$1"
  (
    local EXT_LOWER
    EXT_LOWER=$(echo "${FILE##*.}" | tr '[:upper:]' '[:lower:]')

    if [ "$EXT_LOWER" = "mov" ]; then
      # Wait for the recording to finish being written (size stabilizes)
      local PREV_SIZE=-1
      local CUR_SIZE
      CUR_SIZE=$(stat -f%z "$FILE" 2>/dev/null)
      local TRIES=0
      while [ "$PREV_SIZE" != "$CUR_SIZE" ] && [ "$TRIES" -lt 600 ]; do
        PREV_SIZE=$CUR_SIZE
        sleep 1
        CUR_SIZE=$(stat -f%z "$FILE" 2>/dev/null)
        [ -z "$CUR_SIZE" ] && exit 0
        TRIES=$((TRIES + 1))
      done
      osascript -l JavaScript "$JXA_HELPER" "$FILE" file "$TARGET_MARKER" >/dev/null 2>&1
    else
      osascript -l JavaScript "$JXA_HELPER" "$FILE" image "$TARGET_MARKER" >/dev/null 2>&1
    fi
  ) &
}

# Seed with whatever's already newest so we don't copy old history on start
LAST_SEEN=$(find_newest)
printf '%s' "$LAST_SEEN" > "$TARGET_MARKER"

while true; do
  CURRENT=$(find_newest)
  if [ -n "$CURRENT" ] && [ "$CURRENT" != "$LAST_SEEN" ]; then
    LAST_SEEN="$CURRENT"
    printf '%s' "$CURRENT" > "$TARGET_MARKER"
    copy_to_clipboard_async "$CURRENT"
  fi
  sleep 0.4
done
