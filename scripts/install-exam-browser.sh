#!/bin/bash
#
# Installs Safe Exam Browser from the DMG, without the macOS "Apple could not verify ... is free of malware" warning.
#
#   bash install-exam-browser.sh https://exams.example.edu/SafeExamBrowser.dmg     download and install
#   bash install-exam-browser.sh ~/Downloads/SafeExamBrowser-3.7.1.1.dmg           install a DMG already on the Mac
#
# macOS shows that warning only for files marked "downloaded from the internet" (com.apple.quarantine), which
# browsers and AirDrop add. curl does not add it, and this script removes it from a copy of the app. Run it
# with `bash <file>`; double-clicking a downloaded script triggers the same warning for the script itself.
#
# Installs to /Applications, or to ~/Applications when /Applications is not writable (no admin rights needed).
# INSTALL_DIR=<folder> overrides the folder, NO_OPEN=1 skips starting the app.
#
# This app has the same name and bundle ID as the official Safe Exam Browser: installing it replaces an official
# copy in the same folder.

set -euo pipefail

SRC="${1:-}"
if [ -z "$SRC" ]; then
  echo "Usage: bash $0 <https-url-or-path-of-SafeExamBrowser.dmg>" >&2
  exit 1
fi

APP_NAME="Safe Exam Browser.app"
DEST="${INSTALL_DIR:-/Applications}"
if [ ! -w "$DEST" ]; then
  DEST="$HOME/Applications"
  mkdir -p "$DEST"
fi

WORK="$(mktemp -d)"
MNT="$WORK/mnt"
STAGED="$DEST/.$APP_NAME.installing"
cleanup() {
  hdiutil detach "$MNT" -quiet 2>/dev/null || true
  rm -rf "$WORK" "$STAGED"
}
trap cleanup EXIT

case "$SRC" in
  https://*)
    DMG="$WORK/SafeExamBrowser.dmg"
    echo "Downloading..."
    curl -fL --progress-bar "$SRC" -o "$DMG"
    ;;
  *)
    DMG="$SRC"
    [ -f "$DMG" ] || { echo "No such file: $DMG" >&2; exit 1; }
    ;;
esac

mkdir -p "$MNT"
hdiutil attach "$DMG" -nobrowse -readonly -mountpoint "$MNT" -quiet
[ -d "$MNT/$APP_NAME" ] || { echo "$APP_NAME is not in this disk image." >&2; exit 1; }

# Copy next to the destination first, so a failed copy or a damaged download never leaves the Mac without an app
rm -rf "${STAGED:?}"
ditto "$MNT/$APP_NAME" "$STAGED"

# Remove the "downloaded from the internet" mark from the app and everything in it
# (xattr has no recursive option on current macOS versions, so go file by file)
find "$STAGED" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true

if ! codesign --verify --deep --strict "$STAGED" 2>/dev/null; then
  echo "The app in this disk image is damaged (its signature does not match). Nothing was changed; download it again." >&2
  exit 1
fi

# Quit a running copy so the files can be replaced, then swap the verified copy in
pkill -f "$APP_NAME/Contents/MacOS" 2>/dev/null || true
rm -rf "${DEST:?}/${APP_NAME:?}"
mv "$STAGED" "$DEST/$APP_NAME"

echo "Installed: $DEST/$APP_NAME"
if [ -z "${NO_OPEN:-}" ]; then
  open "$DEST/$APP_NAME"
fi
