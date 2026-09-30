//
//  AccessibilityFeaturesManager.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 18.08.2025.
//  Copyright (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
//  Tobias Halbherr, Kristina Isacson Wildi, Tony Moser,
//  Marco Lehre, Dirk Bauer, Kai Reuter, Karsten Burger,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 2.0 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import Foundation
#if canImport(ApplicationServices)
import ApplicationServices
#endif
import SQLite3
import CocoaLumberjackSwift

@objc public protocol AccessibilityFeaturesProtocol {
//    static var isVoiceOverOn: Bool { get }
}

@objc public class AccessibilityFeaturesManager: NSObject, AccessibilityFeaturesProtocol {
    
    override init() {
        dynamicLogLevel = MyGlobals.ddLogLevel()
    }
    
    class var voiceOverPolicySetting: AccessibilityFeaturePolicy {
        let voiceOverAccessibilityFeaturePolicy = AccessibilityFeaturePolicy(rawValue: UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_accessibilityFeatureVoiceOver")) ?? .systemDefault
        return voiceOverAccessibilityFeaturePolicy
    }

    class var assistiveTouchPolicySetting: AccessibilityFeaturePolicy {
        let assistiveTouchAccessibilityFeaturePolicy = AccessibilityFeaturePolicy(rawValue: UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_accessibilityFeatureAssistiveTouch")) ?? .systemDefault
        return assistiveTouchAccessibilityFeaturePolicy
    }

    class var grayscaleDisplayPolicySetting: AccessibilityFeaturePolicy {
        let grayscaleDisplayAccessibilityFeaturePolicy = AccessibilityFeaturePolicy(rawValue: UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_accessibilityFeatureGrayscaleDisplay")) ?? .systemDefault
        return grayscaleDisplayAccessibilityFeaturePolicy
    }

    class var invertColorsPolicySetting: AccessibilityFeaturePolicy {
        let invertColorsAccessibilityFeaturePolicy = AccessibilityFeaturePolicy(rawValue: UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_accessibilityFeatureInvertColors")) ?? .systemDefault
        return invertColorsAccessibilityFeaturePolicy
    }

    class var zoomPolicySetting: AccessibilityFeaturePolicy {
        let zoomAccessibilityFeaturePolicy = AccessibilityFeaturePolicy(rawValue: UserDefaults.standard.secureInteger(forKey: "org_safeexambrowser_SEB_accessibilityFeatureZoom")) ?? .systemDefault
        return zoomAccessibilityFeaturePolicy
    }

#if os(macOS)
    public class var isVoiceOverOn: Bool {
        return NSWorkspace.shared.isVoiceOverEnabled
    }
    
    @objc public class func controlVoiceOver() {
        let voiceOverActivated = isVoiceOverOn
        UserDefaults.standard.setPersistedSecureBool(voiceOverActivated, forKey: cachedVoiceOverSettingKey)
        conditionallyControlVoiceOver()
    }
    
    class func conditionallyControlVoiceOver() {
        let policy = voiceOverPolicySetting
        switch policy {
        case .systemDefault:
            break
        case .enable:
                activateVoiceOver()
            break
        case .disable:
                deactivateVoiceOver()
            break
        @unknown default:
            break
        }
    }
    
    @objc public class func restoreVoiceOver() {
        let wasVoiceOverEnabledInSystemSettings = UserDefaults.standard.persistedSecureBool(forKey: cachedVoiceOverSettingKey)
        if isVoiceOverOn != wasVoiceOverEnabledInSystemSettings {
            conditionallyActivateVoiceOver(wasVoiceOverEnabledInSystemSettings)
        }
    }
    
    public static var isVoiceOverEnabledInSystemSettings: Bool {
        let voiceOverEnabled = UserDefaults.standard.value(forDefaultsDomain: VoiceOverDefaultsDomain, key: VoiceOverDefaultsKey)
        return voiceOverEnabled as? Bool ?? false
    }

    @objc public class func restoreVoiceOver(newStatus: Bool) {
        conditionallyControlVoiceOver()
    }

    class func conditionallyActivateVoiceOver(_ activate: Bool) {
        if activate {
            activateVoiceOver()
        } else {
            deactivateVoiceOver()
        }
    }
    
    @objc public class func activateVoiceOver() {
        if #available(macOS 10.15, *) {
            let openConfiguration = NSWorkspace.OpenConfiguration()
            openConfiguration.activates = false
            openConfiguration.addsToRecentItems = false
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: VoiceOverBundleID) {
                DDLogInfo("Starting VoiceOver")
                NSWorkspace.shared.openApplication(at: url, configuration: openConfiguration) { app, error in
                    if error != nil {
                        DDLogError("Could not start VoiceOver with error \(String(describing: error))")
                    }
                }
            }
        } else {
            DDLogError("Cannot activate VoiceOver on macOS 10.14 or earlier")
        }
    }
    
    @objc public class func deactivateVoiceOver() {
        let runningVoiceOverAppInstances = NSRunningApplication.runningApplications(withBundleIdentifier: VoiceOverBundleID)
        for app in runningVoiceOverAppInstances {
            app.terminate()
        }
        UserDefaults.standard.setValue(false as NSNumber, forKey: VoiceOverDefaultsKey, forDefaultsDomain: VoiceOverDefaultsDomain)
    }
    
    /// Classification of a Full Disk Access probe. Deliberately distinguishes a plain access
    /// denial from an unexpected failure, so callers can report the actual problem instead of
    /// unconditionally telling the user "Full Disk Access is not granted" (which is misleading
    /// when the grant is present but not being applied to this copy of SEB).
    @objc public enum FullDiskAccessStatus: Int {
        case granted        // The system TCC database is readable — Full Disk Access is effective.
        case denied         // open()/read() was denied (EACCES/EPERM). Either FDA was never granted,
                            // or the grant is not being applied to this copy of SEB (e.g. a
                            // code-signature/identity mismatch or app translocation).
        case unavailable    // An unexpected error (not a plain access denial) prevented the check.
    }

    /// Structured result of probing for Full Disk Access. Preserves the failing operation and
    /// errno so callers can surface the real error rather than a bare "not granted".
    @objc public class FullDiskAccessProbeResult: NSObject {
        @objc public let status: FullDiskAccessStatus
        @objc public let errnoCode: Int32          // 0 when granted
        @objc public let failedOperation: String   // "" when granted, otherwise "open" or "read"
        @objc public let fileExists: Bool          // stat() result — NOT reliable before macOS 13

        init(status: FullDiskAccessStatus, errnoCode: Int32, failedOperation: String, fileExists: Bool) {
            self.status = status
            self.errnoCode = errnoCode
            self.failedOperation = failedOperation
            self.fileExists = fileExists
        }

        /// Localized errno description, e.g. "Permission denied". Empty when granted.
        @objc public var errnoDescription: String {
            errnoCode == 0 ? "" : String(cString: strerror(errnoCode))
        }
    }

    /// Probes whether SEB can read the system TCC database (required for Full Disk Access), and
    /// returns a structured result preserving the failing operation and errno.
    ///
    /// We must NOT use `FileManager.isReadableFile(atPath:)` here: it is backed by
    /// `access(2)`, which only checks POSIX permissions and is not intercepted by TCC
    /// on macOS 11 and 12 (Apple only made the `access`/`stat` family TCC-aware in
    /// macOS 13). On those versions it reports the raw POSIX readability of the TCC
    /// database regardless of the Full Disk Access grant — returning false on macOS 12
    /// even after FDA is granted (so Retry/relaunch never detect it) and true on
    /// macOS 11 even without FDA (so the dialog never appears).
    ///
    /// Instead we actually open the TCC database and read a byte. `open(2)` is gated
    /// by TCC on every macOS version that supports Full Disk Access, so it only
    /// succeeds when FDA has actually been granted.
    ///
    /// NOTE: `fileExists` is reported for diagnostics ONLY. The parent directory is not
    /// searchable by non-root users and `stat()` is not TCC-aware before macOS 13, so this
    /// is false on macOS 12 even when FDA is granted — it must never be used to decide access.
    @objc public static var fullDiskAccessProbe: FullDiskAccessProbeResult {
        let path = "/Library/Application Support/com.apple.TCC/TCC.db"
        let exists = FileManager.default.fileExists(atPath: path)
        let fd = open(path, O_RDONLY)
        guard fd >= 0 else {
            let err = errno
            DDLogInfo("hasFullDiskAccess: open(\(path)) failed - errno \(err) (\(String(cString: strerror(err)))), fileExists=\(exists)")
            let status: FullDiskAccessStatus = (err == EACCES || err == EPERM) ? .denied : .unavailable
            return FullDiskAccessProbeResult(status: status, errnoCode: err, failedOperation: "open", fileExists: exists)
        }
        defer { close(fd) }
        var byte: UInt8 = 0
        // read() returns -1 (with errno EPERM) if the read is denied by TCC, 0 at EOF,
        // or the number of bytes read otherwise. Any non-negative result means access.
        let bytesRead = read(fd, &byte, 1)
        if bytesRead < 0 {
            let err = errno
            DDLogInfo("hasFullDiskAccess: read(\(path)) failed - errno \(err) (\(String(cString: strerror(err)))), fileExists=\(exists)")
            let status: FullDiskAccessStatus = (err == EACCES || err == EPERM) ? .denied : .unavailable
            return FullDiskAccessProbeResult(status: status, errnoCode: err, failedOperation: "read", fileExists: exists)
        }
        DDLogInfo("hasFullDiskAccess: TCC database readable - Full Disk Access granted.")
        return FullDiskAccessProbeResult(status: .granted, errnoCode: 0, failedOperation: "", fileExists: exists)
    }

    /// Convenience: true only when Full Disk Access is effective (the system TCC database is readable).
    @objc public static var hasFullDiskAccess: Bool {
        return fullDiskAccessProbe.status == .granted
    }

    /// Opens System Settings to the Full Disk Access pane.
    @objc public class func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Result of querying the TCC databases for apps with Accessibility permission.
    ///
    /// `systemDatabaseAvailable` is critical for security: the `kTCCServiceAccessibility` service
    /// lives ONLY in the system TCC database, so if that database could not be read the returned
    /// `bundleIDs` set is INCOMPLETE and must NOT be treated as "no apps have the permission".
    @objc public class AccessibilityPermissionQueryResult: NSObject {
        @objc public let bundleIDs: NSSet
        @objc public let systemDatabaseAvailable: Bool

        init(bundleIDs: NSSet, systemDatabaseAvailable: Bool) {
            self.bundleIDs = bundleIDs
            self.systemDatabaseAvailable = systemDatabaseAvailable
        }
    }

    /// Queries both TCC databases for the bundle IDs granted Accessibility permission, and reports
    /// whether the (authoritative) system database was actually readable. Requires Full Disk Access;
    /// with FDA unavailable the system database can't be read and the result is flagged incomplete.
    @objc public class func accessibilityPermissionQuery() -> AccessibilityPermissionQueryResult {
        let tccPaths = [
            "/Library/Application Support/com.apple.TCC/TCC.db",
            (NSHomeDirectory() as NSString).appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
        ]

        // Reading the system TCC database IS the Full Disk Access probe, so reuse the vetted
        // open()+read() check as the authoritative signal for whether it is available. sqlite3's
        // own open result is unreliable here (lazy open; access semantics differ across versions).
        let systemDatabaseAvailable = (fullDiskAccessProbe.status == .granted)

        var result: Set<String> = []

        for path in tccPaths {
            var db: OpaquePointer?
            guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK,
                  let db else {
                DDLogDebug("Could not open TCC database at \(path)")
                continue
            }
            defer { sqlite3_close(db) }

            // Try macOS 12+ schema (auth_value = 2); fall back to older schema (allowed = 1).
            // sqlite3_prepare_v2 returns an error if the referenced column doesn't exist,
            // so whichever query compiles successfully is the right one for this OS version.
            let queries = [
                "SELECT client FROM access WHERE service = 'kTCCServiceAccessibility' AND client_type = 0 AND auth_value = 2",
                "SELECT client FROM access WHERE service = 'kTCCServiceAccessibility' AND client_type = 0 AND allowed = 1"
            ]
            for query in queries {
                var stmt: OpaquePointer?
                guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK, let stmt else {
                    sqlite3_finalize(stmt)
                    continue
                }
                defer { sqlite3_finalize(stmt) }
                while sqlite3_step(stmt) == SQLITE_ROW {
                    if let cString = sqlite3_column_text(stmt, 0) {
                        result.insert(String(cString: cString))
                    }
                }
                break // Stop after the first query that compiles successfully
            }
        }

        // Exclude SEB itself — it legitimately holds Accessibility permission
        // and must never appear in its own prohibited list.
        result.remove(Bundle.main.bundleIdentifier ?? "")

        return AccessibilityPermissionQueryResult(bundleIDs: result as NSSet,
                                                  systemDatabaseAvailable: systemDatabaseAvailable)
    }


#else
    
    @available(iOS 12.2, *)
    typealias AccessibilityFeaturePolicySettings = (name: String, identifier: UIGuidedAccessAccessibilityFeature, policy: AccessibilityFeaturePolicy)

    @available(iOS 12.2, *)
    class var accessibilityFeaturesPolicySettings: [AccessibilityFeaturePolicySettings] {
        return [("AssistiveTouch", .assistiveTouch, assistiveTouchPolicySetting),
                ("Grayscale Display", .grayscaleDisplay, grayscaleDisplayPolicySetting),
                ("Smart Invert",.invertColors, invertColorsPolicySetting),
                ("VoiceOver", .voiceOver, voiceOverPolicySetting),
                ("Zoom", .zoom, zoomPolicySetting)]
    }
    
    
    @available(iOS 12.2, *)
    @objc public class func configureAccessibilityFeatures(completionHandler: @escaping () -> Void) {
        let accessibilityFeaturesPolicies = accessibilityFeaturesPolicySettings
        configureAccessibilityFeature(featuresPolicySettings: accessibilityFeaturesPolicies, completionHandler: completionHandler)
    }
    
    @available(iOS 12.2, *)
    class func configureAccessibilityFeature(featuresPolicySettings: [AccessibilityFeaturePolicySettings], completionHandler: @escaping () -> Void) {
        if let featurePolicySetting = featuresPolicySettings.last {
            let policy = featurePolicySetting.policy
            if policy != .systemDefault {
                UIAccessibility.configureForGuidedAccess(features: featurePolicySetting.identifier, enabled: policy == .enable) { success, error in
                    if !success || error != nil {
                        DDLogError("Accessibility Features Manager: Could not disable \(featurePolicySetting.name) with error \(error.debugDescription)!")
                        DDLogInfo("Accessibility Features Manager: Quitting session")
                        NotificationCenter.default.post(name: NSNotification.Name("requestQuit"), object: self)
                        return
                    } else {
                        DDLogInfo("Accessibility Features Manager: \(featurePolicySetting.name) \(policy == .enable ? "enabled" : "disabled").")
                    }
                }
            }
            configureAccessibilityFeature(featuresPolicySettings: featuresPolicySettings.dropLast(), completionHandler: completionHandler)

        } else {
            completionHandler()
        }
    }

#endif
}
