# Safe Exam Browser for open-book exams (Mac)

An internal build of Safe Exam Browser 3.7.1.1 for exams where students may use any software (ChatGPT, Claude, Google, notes). It looks and behaves like the original Safe Exam Browser, with the changes listed below. It keeps the original name and bundle ID, `org.safeexambrowser.SafeExamBrowser`.

**Nothing leaves the student's Mac and nothing is visible to the examiner.** There is no screen capture, no SEB Server, no proctoring code (they are not compiled into the app), and the log stays on the student's disk.

## Contents of a release

`build/SafeExamBrowser-3.7.1.1.dmg`, universal (Apple silicon and Intel), about 12 MB. Build it with `bash scripts/build-dmg.sh` (needs Xcode; the first build downloads the Swift packages). Check a copy with `shasum -a 256`; the file built on 2026-10-28 has the SHA-256 `126e117b4666808245e5557affd572bd8794c0493225cfd218c6d99aef3203d1`.

`bash scripts/package-release.sh` then gathers what to hand out into `build/release/`: the DMG, `install-exam-browser.sh`, `verify-install.sh`, this guide, and `SHA256SUMS` (check with `shasum -a 256 -c SHA256SUMS` inside that folder).

The app is signed ad hoc (no Apple Developer account) and is not notarized. That is why the install step below matters.

## Installing on a student's Mac

Browsers mark downloads as "downloaded from the internet", and macOS then shows *"Apple could not verify … is free of malware"* for an app that isn't notarized. The installer script removes that mark. Give students these lines:

```
curl -fLO https://your.server/install-exam-browser.sh
bash install-exam-browser.sh https://your.server/SafeExamBrowser.dmg
bash install-exam-browser.sh ~/Downloads/SafeExamBrowser-3.7.1.1.dmg      (a DMG already on the Mac, or from a USB stick)
```

Download the script with `curl` as shown (it adds no mark) and run it with `bash`; double-clicking a script that a browser downloaded triggers the same warning for the script itself.

It installs to `/Applications` (or `~/Applications` if that isn't writable; no admin rights needed) and replaces an official SEB in the same folder. It checks the app's signature before replacing anything, so a damaged download stops with a message and leaves the installed app as it was. `INSTALL_DIR=<folder>` and `NO_OPEN=1` are supported.

To check an installed copy, run `bash scripts/verify-install.sh`. It is read-only and prints what is wrong: identity, signature, camera entitlement, leftover marks, and, after an exam, whether the log follows the rules below.

## Starting an exam

The app opens a start page with one field. Students can give it:

- a web address (`https://…`, or just `exams.example.edu/quiz`, or a single-word intranet name)
- a `seb://` or `sebs://` link
- the address of a `.seb` file

Double-clicking a `.seb` file, or opening a `seb://` link, starts the exam directly. Nothing is fixed in the app: any address or configuration works.

## What the student sees and can do

- One full-screen window, no title bar, not movable, with SEB's taskbar at the bottom. Links open in the same window.
- **Cmd+Shift+L locks and unlocks.** A small lock icon flashes at the top-left for about one second (closed = locked, open = unlocked) and disappears. No text stays on screen.
  - Locked: a black backdrop covers every screen; Cmd+Tab, Mission Control, Spaces, Show Desktop, and the keys that move between tabs and windows (Ctrl+Tab, Cmd+1…9, Cmd+Shift+[ ], Cmd+`, Cmd+H, Cmd+M, Cmd+Option+←/→) do nothing.
  - Unlocked: gestures, Mission Control and app switching are the normal macOS ones, with no overlap.
- **Copy and paste always work**, between the exam and any other app, even on pages that try to forbid it. Selecting text works too.
- **Pages cannot tell** that the student switched windows, tabs or apps (no blur, focus or visibility events; `document.hidden` is always false), and cannot stop copy and paste, and cannot stop the student from quitting with Cmd+Q.
- **Quit** with Cmd+Q and confirm. After the confirmation the app terminates within five seconds even if the web view is slow to answer.
- **Camera and microphone**, for exams that need them: SEB shows its own "Permissions Required" message, then macOS asks once. The app never records or uploads anything.

## The log

Location: `~/Library/Logs/Safe Exam Browser/`. File name: `org.safeexambrowser.SafeExamBrowser <UTC date and time>.log`. It is the original SEB log: same logger, same line layout (`yyyy/MM/dd HH:mm:ss:SSS  message`), same wording, up to 20 files kept. **SEB adds no lines of its own.**

- The start of the exam is the original `---------- INITIALIZING SEB - STARTING SESSION ----------` line, and the end is `---------- EXITING SEB - ENDING SESSION ----------`, each with its time. The applications that were running in the background at the start are listed, as in the original.
- While the exam runs, **nothing** is written.
- Lines that would show what the student did are never written, at any time: page addresses and titles, copy and paste, downloads, applications started or switched to, window and focus switching. Locking or unlocking (Cmd+Shift+L) leaves no trace either.
- If the app is killed (force quit, power loss) there is no end line, as in the original.

## What differs from the official Safe Exam Browser

Defaults are relaxed for open-book use: switching to other applications is allowed, no process or virtual-machine, screen-sharing, display or accessibility checks, no Location Services or Full Disk Access requests, no changes to the student's system settings, the system clipboard is shared with other apps, and the app need not live in `/Applications`. SEB Server, screen proctoring and remote proctoring do not exist in this build.

Two bugs of the original are fixed: a held Command key at launch no longer produces a blocking alert when quitting (when the setting that forbids it is off), and the process watchers no longer use a fifth of a CPU core at idle (about 2% now).

## Removing it

Delete the app, then `~/Library/Application Support/org.safeexambrowser.SafeExamBrowser` (holds one key file), `~/Library/Logs/Safe Exam Browser` if the logs are no longer wanted, and run `defaults delete org.safeexambrowser.SafeExamBrowser`. An official SEB on the same Mac shares that preference domain, so do the last step only if it is not needed.

## Tested, and not tested

Tested on macOS 26.2 (Apple silicon), from the built DMG, with real key presses: launching from a `.seb` file (the address parser was tested separately on 29 inputs, including `seb://`, `sebs://`, bare host names and rejected schemes); copy and paste (normal and hostile pages); lock and unlock, blocked keys, Mission Control; the quit dialog; the camera exam end to end; the log against the complete original log; a network check (the app's own process connects to nothing but this Mac; no code that contacts a fixed remote host is compiled in); installing from a DMG marked as downloaded; first launch on a Mac that has the official SEB's preferences; dozens of launches and quits in a row without a crash or hang.

Not tested: a second Mac (use `verify-install.sh` on it), other macOS versions, Intel Macs, real trackpad gestures (the equivalent keyboard shortcuts were used), more than one display, and sleep or wake during an exam.
