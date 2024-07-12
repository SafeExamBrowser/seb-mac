//
//  AssessmentConfigurationManager.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 31.05.2024.
//

import Foundation
import AutomaticAssessmentConfiguration

@objc public class AssessmentConfigurationManager: NSObject {
    
    @objc public func autostartApps(permittedApplications: Array<Dictionary<String, Any>>) {
#if os(macOS)
        if #available(macOS 12.0, *) {
            let openConfiguration = NSWorkspace.OpenConfiguration()
            openConfiguration.activates = false
            openConfiguration.addsToRecentItems = false
            openConfiguration.createsNewApplicationInstance = true
            for permittedApplication in permittedApplications {
                if permittedApplication["autostart"] as? Bool == true, let bundleIdentifier = permittedApplication["identifier"] as? String, bundleIdentifier.count > 0 {
                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                        NSWorkspace.shared.openApplication(at: url, configuration: openConfiguration) { app, error in
                            
                        }
                    }
                }
            }
        }
        #endif
    }
}

@available(macOS 10.15.4, iOS 13.4, *)
@objc extension AEAssessmentConfiguration {

    convenience init(permittedApplications: Array<Dictionary<String, Any>>) {
        self.init()
        
        if #available(macOS 12.0, iOS 17.5, *) {
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
