#!/bin/bash
#
# Checks an installed copy of Safe Exam Browser on any Mac. Read-only: it changes nothing and starts nothing.
#
#   bash verify-install.sh                                  checks the copy in /Applications or ~/Applications
#   bash verify-install.sh "/path/to/Safe Exam Browser.app"
#
# Run it after install-exam-browser.sh, and once more after an exam to check the log it wrote.

APP="${1:-}"
if [ -z "$APP" ]; then
  for candidate in "/Applications/Safe Exam Browser.app" "$HOME/Applications/Safe Exam Browser.app"; do
    [ -d "$candidate" ] && { APP="$candidate"; break; }
  done
fi
[ -d "$APP" ] || { echo "No Safe Exam Browser.app found. Pass its path as the first argument." >&2; exit 1; }

BAD=0
ok()   { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; BAD=$((BAD + 1)); }
info() { printf '        %s\n' "$1"; }
plist() { /usr/libexec/PlistBuddy -c "Print :$1" "$APP/Contents/Info.plist" 2>/dev/null; }

echo "This Mac: macOS $(sw_vers -productVersion), $(uname -m)"
echo "App:      $APP"
echo

echo "Identity"
BID="$(plist CFBundleIdentifier)"; NAME="$(plist CFBundleDisplayName)"; VERSION="$(plist CFBundleShortVersionString)"
[ "$BID" = "org.safeexambrowser.SafeExamBrowser" ] && ok "bundle ID $BID" || fail "bundle ID is '$BID'"
[ "$NAME" = "Safe Exam Browser" ] && ok "name $NAME" || fail "name is '$NAME'"
info "version $VERSION"
MIN="$(plist LSMinimumSystemVersion)"; [ -n "$MIN" ] && info "needs macOS $MIN or newer"

echo "Signature (ad-hoc: no Apple Developer account is involved)"
if codesign --verify --deep --strict "$APP" 2>/dev/null; then ok "signature intact, nothing in the app was changed after signing"; else fail "signature broken: $(codesign --verify --deep --strict "$APP" 2>&1 | head -1)"; fi
ENT="$(codesign -d --entitlements - "$APP" 2>/dev/null | grep -o 'com.apple.security[a-z.-]*' | tr '\n' ' ')"
case "$ENT" in *device.camera*) ok "camera entitlement present";; *) fail "camera entitlement missing";; esac
case "$ENT" in *device.audio-input*) ok "microphone entitlement present";; *) fail "microphone entitlement missing";; esac

echo "Warning-free start"
QUARANTINED="$(find "$APP" -exec xattr -p com.apple.quarantine {} \; 2>/dev/null | wc -l | tr -d ' ')"
if [ "$QUARANTINED" = "0" ]; then
  ok "no file is marked 'downloaded from the internet', so macOS shows no \"could not verify\" warning"
else
  fail "$QUARANTINED files are still marked as downloaded: run install-exam-browser.sh again (or: find \"$APP\" -exec xattr -d com.apple.quarantine {} \\; 2>/dev/null)"
fi

echo "Log (after an exam has been run)"
LOGDIR="$HOME/Library/Logs/Safe Exam Browser"
LATEST="$(ls -t "$LOGDIR"/"$BID"*.log 2>/dev/null | head -1)"
if [ -z "$LATEST" ]; then
  info "no log yet: start an exam page, quit, then run this again"
else
  info "newest: $(basename "$LATEST") ($(wc -l < "$LATEST" | tr -d ' ') lines)"
  head -3 "$LATEST" | sed 's/^/        | /'
  if ! grep -q 'STARTING UP SEB\|INITIALIZING SEB' "$LATEST" && [ "$(wc -l < "$LATEST" | tr -d ' ')" -lt 30 ]; then
    info "this is a short log from before this app ran an exam (an older SEB leaves such files): run an exam, quit, and run this again"
    LATEST=""
  fi
fi
if [ -n "$LATEST" ]; then
  # A message that spans several lines has the time only on its first line (as in the original), so only lines that start
  # like a log line but are not written in the original layout count
  STARTS="$(grep -cE '^[0-9]{4}/[0-9]{2}/[0-9]{2} ' "$LATEST")"
  BADLAYOUT="$(grep -E '^[0-9]{4}/[0-9]{2}/[0-9]{2} ' "$LATEST" | grep -cvE '^[0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}:[0-9]{3}  ')"
  if [ "$STARTS" -gt 0 ] && [ "$BADLAYOUT" = "0" ]; then ok "every line has the original layout (yyyy/MM/dd HH:mm:ss:SSS  message)"; else fail "$BADLAYOUT of $STARTS lines do not have the original layout"; fi
  grep -q 'INITIALIZING SEB - STARTING SESSION' "$LATEST" && ok "has the start of the session (with its time)" || fail "the start-of-session line is missing"
  grep -q 'EXITING SEB - ENDING SESSION' "$LATEST" && ok "has the end of the session (with its time)" || info "no end-of-session line (the exam may still be running, or SEB was force-quit)"
  grep -q 'Running applications at session start' "$LATEST" && ok "has the list of applications that were running at the start" || fail "the list of running applications is missing"
  LEAKS="$(grep -ciE '://|Title of current Page|clipboard|pasteboard|Started application|Activated app' "$LATEST")"
  [ "$LEAKS" = "0" ] && ok "no page address, page title, clipboard or started application in it" || fail "$LEAKS lines that should never be there"
fi

echo
if [ "$BAD" = "0" ]; then echo "All checks passed."; else echo "$BAD check(s) failed."; fi
echo "Not checkable from a script: the camera/microphone permission prompt (macOS asks once, on the first exam that uses them)."
exit $((BAD > 0))
