# CrashLogs

Drop exported crash reports here for analysis.

## How to export from the Xcode Organizer

1. **Window ▸ Organizer**, select the **Crashes** tab.
2. Pick the build in the left sidebar and the crash point you want.
3. Right-click the crash log in the detail pane → **Export…** (or **Open in Finder**).
4. Save the resulting `.ips` / `.crash` file into this folder.

Alternatively, copy the backtrace text from the Organizer detail pane and paste it
directly into chat.

## Notes

- `.ips` / `.crash` files are plain JSON/text and can be read and analyzed directly.
- For addresses to resolve to real function names, the crash must be **symbolicated**.
  The Organizer symbolicates automatically when the matching **dSYM** is present.
  If you see raw hex addresses, locate the dSYM via
  Organizer → right-click archive → *Show in Finder* → `*.xcarchive/dSYMs/`.
- Crash reports can contain user/device identifiers and paths, so the actual log
  files are **git-ignored** (see `.gitignore`). Only this README is tracked.
