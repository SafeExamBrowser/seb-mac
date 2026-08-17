//
//  SEBAllowedSEBVersionsTestSupport.swift
//  SafeExamBrowser
//
//  Test-only bridge that exposes the Objective-C SEBAllowedSEBVersions class to
//  the Swift unit test target. The test target links the app module but cannot see
//  Objective-C classes directly, so this small @objc public wrapper (part of the
//  app's Swift module) provides access.
//  Compiled only in DEBUG builds — nothing ships in release.
//

#if DEBUG
import Foundation

@objc public final class SEBAllowedSEBVersionsTestSupport: NSObject {

    /// Wraps -[SEBAllowedSEBVersions allowedSEBVersion:buildNumber:platform:allianceEdition:fromVersionStrings:].
    /// `platform` uses the SEBAllowedVersionPlatform raw values (Mac = 0, Win = 1, iOS = 2).
    @objc public static func allowed(version: String,
                                     buildNumber: String?,
                                     platform: Int,
                                     allianceEdition: Bool,
                                     restrictions: [String]?) -> Bool {
        let checker = SEBAllowedSEBVersions()
        return checker.allowedSEBVersion(version,
                                         buildNumber: buildNumber,
                                         platform: SEBAllowedVersionPlatform(rawValue: platform)!,
                                         allianceEdition: allianceEdition,
                                         fromVersionStrings: restrictions)
    }

    /// Wraps -[SEBAllowedSEBVersions requirementDescriptionForPlatform:fromVersionStrings:].
    @objc public static func requirementDescription(platform: Int,
                                                     restrictions: [String]?) -> String? {
        let checker = SEBAllowedSEBVersions()
        return checker.requirementDescription(for: SEBAllowedVersionPlatform(rawValue: platform)!,
                                              fromVersionStrings: restrictions)
    }
}
#endif
