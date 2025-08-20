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
//        let voiceOverActivated = isVoiceOverOn
        let policy = voiceOverPolicySetting
        switch policy {
        case .systemDefault:
            break
        case .enable:
//            if !voiceOverActivated {
                activateVoiceOver()
//            }
            break
        case .disable:
//            if voiceOverActivated {
                deactivateVoiceOver()
//            }
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
    
#else
    
#endif
}
