//
//  AssessmentConfigurationManager.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 31.05.2024.
//

import Foundation
import AutomaticAssessmentConfiguration

@available(macOS 10.15.4, *)
@objc extension AEAssessmentConfiguration {

    convenience init(permittedApplications: Array<Dictionary<String, Any>>) {
        self.init()

        if #available(macOS 12.0, *) {
            for permittedApplication in permittedApplications {
                var application: AEAssessmentApplication
                if let bundleIdentifier = permittedApplication["identifier"] as? String, bundleIdentifier.count > 0 {
                    if let teamIdentifier = permittedApplication["teamIdentifier"] as? String, teamIdentifier.count > 0 {
                        application = AEAssessmentApplication(bundleIdentifier: bundleIdentifier, teamIdentifier: teamIdentifier)
                    } else {
                        application = AEAssessmentApplication(bundleIdentifier: bundleIdentifier)
                    }
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
