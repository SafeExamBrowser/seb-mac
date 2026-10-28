#!/bin/bash
#
# Build the college's internal Safe Exam Browser for macOS and package it as a DMG.
#
#   scripts/build-dmg.sh
#
# Output: build/SafeExamBrowser-<version>.dmg
#
# The app is signed ad hoc (no Apple Developer account needed). macOS shows "Apple could not verify ... is free
# of malware" only for files marked "downloaded from the internet" (com.apple.quarantine). Students avoid it by
# installing with scripts/install-exam-browser.sh, which removes that mark, or by getting the app from a USB stick
# or the college's MDM, neither of which adds it.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/build"
SCHEME="Safe Exam Browser"
PRODUCT="Safe Exam Browser"

cd "$ROOT"
rm -rf "$BUILD/Release" "$BUILD/dmg"
mkdir -p "$BUILD"

# libSEBSupport.a is SEB's proprietary module, which is not part of the open source code and
# which the macOS target does not need at link time. An empty stand-in satisfies the project's
# link entry until it is removed from the target.
STUB="$BUILD/stub"
if [ ! -f "$ROOT/Frameworks/libSEBSupport.a" ]; then
  mkdir -p "$STUB"
  printf 'void seb_empty_support_stub(void){}\n' > "$STUB/stub.c"
  clang -c "$STUB/stub.c" -o "$STUB/stub.o"
  rm -f "$STUB/libSEBSupport.a"
  ar rcs "$STUB/libSEBSupport.a" "$STUB/stub.o"
  EXTRA_LIBS="$STUB"
else
  EXTRA_LIBS=""
fi

xcodebuild \
  -workspace SafeExamBrowser.xcworkspace \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$BUILD/DerivedData" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="-" \
  DEVELOPMENT_TEAM="" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  LIBRARY_SEARCH_PATHS="\$(inherited) $EXTRA_LIBS" \
  build

APP="$BUILD/DerivedData/Build/Products/Release/$PRODUCT.app"
[ -d "$APP" ] || { echo "Build did not produce $APP" >&2; exit 1; }

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || echo dev)"
echo "Built $PRODUCT $VERSION"

codesign --verify --deep --strict --verbose=2 "$APP"
echo "Entitlements in the signed app:"
codesign -d --entitlements - "$APP" 2>/dev/null | grep -E 'com\.apple' || true

# DMG with an Applications shortcut
STAGE="$BUILD/dmg"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

# A source tree that was downloaded as a zip carries the "downloaded from the internet" mark on its files, and some
# of those end up inside the app. None must be left in it (xattr has no recursive option on current macOS versions).
find "$STAGE/$PRODUCT.app" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true
codesign --verify --deep --strict "$STAGE/$PRODUCT.app"
DMG="$BUILD/SafeExamBrowser-$VERSION.dmg"
rm -f "$DMG"
hdiutil create -volname "Safe Exam Browser $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
echo "Created $DMG"
