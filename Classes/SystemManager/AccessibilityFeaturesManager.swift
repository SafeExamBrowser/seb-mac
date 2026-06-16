//
//  AccessibilityFeaturesManager.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 18.08.2025.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
//  Tobias Halbherr, Kristina Isacson Wildi, Tony Moser,
//  Marco Lehre, Dirk Bauer, Kai Reuter, Karsten Burger,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import Foundation
import ApplicationServices
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
    
    @objc public class func getRunningAppsWithAccessibility() {
        DDLogInfo("Scanning for apps with active Accessibility permissions...")

        let tccPaths = [
            //"/Library/Application Support/com.apple.TCC/TCC.db",
            (NSHomeDirectory() as NSString).appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
        ]

        var accessibilityBundleIDs: Set<String> = []

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
                        accessibilityBundleIDs.insert(String(cString: cString))
                    }
                }
                break // Stop after the first query that compiles successfully
            }
        }

        guard !accessibilityBundleIDs.isEmpty else {
            DDLogError("Accessibility check: Could not read TCC database (Full Disk Access may be required)")
            return
        }

        // Cross-reference with running applications
        let runningApps = NSWorkspace.shared.runningApplications
        for bundleID in accessibilityBundleIDs.sorted() {
            let matches = runningApps.filter { $0.bundleIdentifier == bundleID }
            if matches.isEmpty {
                DDLogDebug("Accessibility permission granted (not running): \(bundleID)")
            } else {
                for app in matches {
                    DDLogInfo("Running app with Accessibility permission: \(app.localizedName ?? bundleID) (Bundle: \(bundleID) | PID: \(app.processIdentifier))")
                }
            }
        }
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
