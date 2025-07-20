//
//  AssessmentConfigurationManager.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 31.05.2024.
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
