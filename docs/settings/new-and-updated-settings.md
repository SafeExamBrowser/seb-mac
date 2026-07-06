# SEB macOS Settings Documentation

Documentation for new and updated SEB macOS settings, including their
NSUserDefaults keys, types, default values, allowed values, and the English UI
strings and tooltips as shown in the preferences window.

## `screenProctoringAACCapturePolicy`

| Field | Value |
|-------|-------|
| **Key** | `org_safeexambrowser_SEB_screenProctoringAACCapturePolicy` |
| **Type** | Integer (enum `ScreenProctoringAACCapturePolicy`) |
| **Default** | `2` (`ScreenProctoringAACCapturePolicyAllWindows`) |
| **Introduced** | New in this version |

### Allowed values

| Value | Constant | Meaning |
|-------|----------|---------|
| `0` | `ScreenProctoringAACCapturePolicyNone` | No view-based capture under AAC. In *Automatic* lockdown mode this also prevents AAC from being selected while screen proctoring is enabled (SEB falls back to Classic kiosk mode, where system screen capture works). If AAC is force-enabled anyway, capture falls back to the active window. |
| `1` | `ScreenProctoringAACCapturePolicyActiveWindow` | Captures only the active browser window (including its window chrome). |
| `2` | `ScreenProctoringAACCapturePolicyAllWindows` | Captures all SEB-owned windows (browser windows, Dock, alerts/dialogs) and composites them onto a full virtual-screen image using their positions and z-order. |

### UI (Security pane → "Lockdown/Kiosk mode" box)

- **Label:** `Screen proctoring capture under AAC:`
- **Popup menu items:**
  - `Don't use AAC (disable Assessment Mode)`
  - `Capture active window only`
  - `Capture all windows (composited)`
- **Tooltip:** `Under AAC (Assessment Mode) the system screen capture returns black, so screen proctoring captures SEB's own windows instead. Choose which windows are captured, or disable using AAC when screen proctoring is enabled.`
- **Enabled only when:** screen proctoring is enabled (`enableScreenProctoring = true`) **and** lockdown mode is not *Enforce classic kiosk mode*.

### Description

Under AAC (Automatic Assessment Configuration) the system screen capture API
(`CGWindowListCreateImage`) returns a black image, so screen proctoring instead
renders SEB's own windows via `NSView` `cacheDisplay`. This policy selects what is
captured. Content not held in a view's backing store (e.g. hardware-decoded or
DRM-protected video) may appear black; SEB-owned windows are composited over a
neutral gray backdrop matching AAC's own background.

## `hideWiFiControls`

| Field | Value |
|-------|-------|
| **Key** | `org_safeexambrowser_SEB_hideWiFiControls` |
| **Type** | Boolean |
| **Default** | `false` |

### UI

Not exposed in the preferences UI — configuration-file / MDM setting only.
(No label or tooltip.)

### Description

Controls whether the Wi-Fi control widget is shown in the SEB Dock. The Wi-Fi
control is normally displayed in the Dock when the menu bar is hidden or when AAC
is active. Setting `hideWiFiControls = true` suppresses it in those cases.

## `lockdownModePolicy`

| Field | Value |
|-------|-------|
| **Key** | `org_safeexambrowser_SEB_lockdownModePolicy` |
| **Type** | Integer (enum `lockdownModePolicy`) |
| **Default** | `0` (`lockdownModePolicyAutomatic`) |

### Allowed values

| Value | Constant | Meaning |
|-------|----------|---------|
| `0` | `lockdownModePolicyAutomatic` | SEB automatically selects the lockdown mode based on the running macOS version and current settings. AAC is used when the macOS version supports it (≥ 10.15.4 except 10.15.5; ≥ 11 / ≥ 12.0 with DNS pre-pinning; ≥ 12.1 unconditionally) **and** none of the following are enabled: screen capture, window capture, screen sharing, browser screen capture, or screen proctoring (unless the screen-proctoring AAC capture policy permits it). Falls back to Classic kiosk mode otherwise. |
| `1` | `lockdownModePolicyEnforceClassic` | Always uses Classic kiosk mode (elevated window levels, no AAC), regardless of macOS version or other settings. Dictionary lookup is only available in this mode. The UI shows `allowSwitchToApplications` instead of `allowOpenAndSavePanel`. |
| `2` | `lockdownModePolicyEnforceAAC` | Always enforces AAC. If the running macOS version does not support AAC, SEB logs an error and AAC is disabled at runtime. The UI shows `allowOpenAndSavePanel` and `allowShareSheet` instead of `allowSwitchToApplications`. |

### UI (Security pane → "Lockdown/Kiosk mode" box)

- **Box title:** `Lockdown/Kiosk mode`
- **Radio buttons:**
  - `Automatic (AAC when no screen/window capture/sharing enabled)`
  - `Enforce classic kiosk mode (allows screen/window capture etc.)`
  - `Enforce AAC Assessment Mode (more secure)`
- **Tooltip:** `Automatic Assessment Configuration (AAC) Assessment Mode is available from macOS Monterey 12.1 (and Catalina 10.15.4 / 10.15.6+), from macOS Big Sur 11 with restrictions. It blocks various macOS features (which cannot be allowed optionally, like screen/window capture/sharing/mirroring, Siri, Dictation, Screen Proctoring)`

### Description

Selects which kiosk/lockdown mechanism SEB uses. *Automatic* picks between AAC
(more secure) and Classic kiosk mode based on macOS version and whether
potentially AAC-incompatible features are enabled. The two *Enforce* options
override that decision.

## `allowAccessibility` (per permitted process)

| Field | Value |
|-------|-------|
| **Key** | `allowAccessibility` (property within each entry of the `permittedProcesses` array) |
| **Type** | Boolean |
| **Default** | `false` |
| **Introduced** | New in this version |

### UI (Applications pane → permitted processes editor)

- **Label:** `Allow Accessibility`
- **Tooltip:** `Allow the permitted process to have Accessibility permissions (see System Settings / Privacy & Security / Accessibility). If 'Detect apps with Accessibility Permissions' in Security Pane is enabled, then processes with Accessibility permissions (not excluded here) will be terminated`

### Description

A per-permitted-process flag that lets a specific permitted application keep its
macOS Accessibility permission. When the "Detect apps with Accessibility
Permissions" security check is enabled, any running app that holds Accessibility
permission and is **not** marked `allowAccessibility = true` is added to the
prohibited-applications list and terminated. Setting this to `true` exempts the
permitted process from that termination, giving exam administrators fine-grained
control over which trusted apps may retain privileged accessibility features.
