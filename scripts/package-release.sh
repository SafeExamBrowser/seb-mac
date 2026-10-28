#!/bin/bash
#
# Gathers what an administrator hands out into build/release/: the DMG, the installer, the checker, the guide,
# and SHA256SUMS. Run it after scripts/build-dmg.sh; it builds nothing and changes nothing outside build/release/.
#
#   scripts/package-release.sh
#   cd build/release && shasum -a 256 -c SHA256SUMS      (anyone can check their copy this way)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DMG="$(ls "$ROOT"/build/SafeExamBrowser-*.dmg 2>/dev/null | sort | tail -1 || true)"
[ -f "$DMG" ] || { echo "No build/SafeExamBrowser-*.dmg found. Run scripts/build-dmg.sh first." >&2; exit 1; }

hdiutil verify -quiet "$DMG" || { echo "The DMG fails its own checksum: $DMG" >&2; exit 1; }

OUT="$ROOT/build/release"
rm -rf "$OUT"
mkdir -p "$OUT"
cp "$DMG" "$OUT/"
cp "$ROOT/scripts/install-exam-browser.sh" "$ROOT/scripts/verify-install.sh" "$ROOT/docs/EXAM-BROWSER.md" "$OUT/"

# The sums are written under another name first so that the file never lists itself
(cd "$OUT" && shasum -a 256 -- * > .sums && mv .sums SHA256SUMS)

echo "Release folder: $OUT"
(cd "$OUT" && ls -l | sed 's/^/  /' && echo && cat SHA256SUMS | sed 's/^/  /')
