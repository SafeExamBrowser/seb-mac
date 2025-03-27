//
//  AdditionalApplicationsController.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 27.03.2025.
//

import Foundation

@objc public class AdditionalApplicationsController: NSObject {
    
    @objc static var runningOnOS: SEBSupportedOS {
        get {
#if os(iOS)
            let runningOnOS = SEBSupportedOSiPadOS
#elseif os(macOS)
            let runningOnOS = SEBSupportedOSmacOS
#endif
            return SEBSupportedOS(runningOnOS)
        }
    }
    
    @objc class func downloadFileTypesExtensions() -> Set<String> {
        var downloadFileExtensions: Set<String> = []
        if let downloadFileTypes = UserDefaults.standard.secureArray(forKey: "org_safeexambrowser_SEB_downloadFileTypes") {
            let filterFileTypesOS = NSPredicate(format: "os == %d", runningOnOS)
            let osFilteredFileTypes = (downloadFileTypes as NSArray).filtered(using: filterFileTypesOS) as? [[String: Any]] ?? []
            downloadFileExtensions = Set(osFilteredFileTypes.map { $0["extension"] } as! [String])
        }
        return downloadFileExtensions
    }
    
    @objc class func appBundleIdentifier(fileExtension: String) -> String? {
        var appBundleIdentifier: String?
        if let downloadFileTypes = UserDefaults.standard.secureArray(forKey: "org_safeexambrowser_SEB_downloadFileTypes") as? [[String: Any]] {
            let filterFileExtension = NSPredicate(format: "os == %d AND extension == %@", runningOnOS, fileExtension)
            if let osFilteredFileTypes = (downloadFileTypes as NSArray).filtered(using: filterFileExtension) as? [[String: Any]] {
                appBundleIdentifier = osFilteredFileTypes.first?["associatedAppId"] as? String
            }
        }
        return appBundleIdentifier
    }
    
    @objc class func appScheme(bundleIdentifier: String) -> String? {
        var appScheme: String?
        if let additionalApplications = UserDefaults.standard.secureArray(forKey: "org_safeexambrowser_SEB_permittedProcesses") {
            let filterAppBundleId = NSPredicate(format: "os == %d AND identifier == %@", runningOnOS, bundleIdentifier)
            if let bundleIdOSFilteredApps = (additionalApplications as NSArray).filtered(using: filterAppBundleId) as? [[String: Any]] {
                appScheme = bundleIdOSFilteredApps.first?["path"] as? String
            }
        }
        return appScheme
    }
}
