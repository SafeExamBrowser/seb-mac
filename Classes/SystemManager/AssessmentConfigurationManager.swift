//
//  AssessmentConfigurationManager.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 31.05.2024.
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
import AutomaticAssessmentConfiguration
import CocoaLumberjackSwift

@objc public class AssessmentConfigurationManager: NSObject {
    
    override init() {
        dynamicLogLevel = MyGlobals.ddLogLevel()
    }
    
    @objc public func autostartApps(permittedApplications: Array<Dictionary<String, Any>>) {
#if os(macOS)
        if #available(macOS 12.0, *) {
            let openConfiguration = NSWorkspace.OpenConfiguration()
            openConfiguration.activates = false
            openConfiguration.addsToRecentItems = false
            openConfiguration.createsNewApplicationInstance = true
            openConfiguration.arguments = ["-NSQuitAlwaysKeepsWindows", "NO"]
            for permittedApplication in permittedApplications {
                if permittedApplication["autostart"] as? Bool == true, let bundleIdentifier = permittedApplication["identifier"] as? String, bundleIdentifier.count > 0 {
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                        DDLogInfo("Autostarting permitted app with Bundle ID \(bundleIdentifier)")
                        NSWorkspace.shared.openApplication(at: url, configuration: openConfiguration) { app, error in
                            if error != nil {
                                DDLogError("Could not start app at URL \(url) with error \(String(describing: error))")
                            }
                        }
                    }
                }
            }
        }
#endif
    }
    
    @objc public func removeSavedAppWindowState(permittedApplications: Array<Dictionary<String, Any>>) -> Bool {
#if os(macOS)
        for permittedApplication in permittedApplications {
            if let bundleIdentifier = permittedApplication["identifier"] as? String, bundleIdentifier.count > 0 {
                let appSavedStatePath = NSString(string: "~/Library/Saved Application State/\(bundleIdentifier).savedState").expandingTildeInPath
                let appSavedStateURL = URL(fileURLWithPath: appSavedStatePath)
                var resolvedAliasURL: URL
                do {
                    try resolvedAliasURL = URL(resolvingAliasFileAt: appSavedStateURL)
                } catch let error {
                    DDLogDebug("Couldn't follow alias at \(appSavedStateURL) with error: \(error). Try non-Alias URL.")
                    resolvedAliasURL = appSavedStateURL
                }
                let windowsSavedStateURL = resolvedAliasURL.appendingPathComponent("windows.plist")
                do {
                    try FileManager.default.removeItem(at: windowsSavedStateURL)
                    DDLogInfo("Removed saved state of previously opened windows for permitted app at \(windowsSavedStateURL)")
                } catch CocoaError.fileNoSuchFile {
                    DDLogInfo("No windows.plist saved state file at \(windowsSavedStateURL).")
                } catch CocoaError.fileWriteNoPermission {
                    DDLogError("Couldn't remove windows.plist saved state file at \(windowsSavedStateURL) because of not granted permission. Inform user and retry.")
                    return false
                } catch let error {
                    DDLogError("Couldn't remove \(windowsSavedStateURL) with error: \(error)")
                }
            }
        }
#endif
        return true
    }
}

@available(macOS 10.15.4, iOS 13.4, *)
@objc extension AEAssessmentConfiguration {

    convenience init(permittedApplications: Array<Dictionary<String, Any>>) {
        self.init()
        
        if #available(macOS 12.0, iOS 17.7.1, *) {
            for permittedApplication in permittedApplications {
                var application: AEAssessmentApplication
                if let bundleIdentifier = permittedApplication["identifier"] as? String, bundleIdentifier.count > 0 {
#if os(macOS)
                    if let teamIdentifier = permittedApplication["teamIdentifier"] as? String, teamIdentifier.count > 0 {
                        application = AEAssessmentApplication(bundleIdentifier: bundleIdentifier, teamIdentifier: teamIdentifier)
                    } else {
                        application = AEAssessmentApplication(bundleIdentifier: bundleIdentifier)
                    }
#elseif os(iOS)
                    application = AEAssessmentApplication(bundleIdentifier: bundleIdentifier)
#endif
                    let applicationConfig = AEAssessmentParticipantConfiguration()
                    if let allowNetworkAccess = permittedApplication["allowNetworkAccess"] as? Bool {
                        applicationConfig.allowsNetworkAccess = allowNetworkAccess
                    }
                    self.setConfiguration(applicationConfig, for: application)
                }
            }
        }
    }
}
