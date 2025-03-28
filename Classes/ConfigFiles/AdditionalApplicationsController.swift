//
//  AdditionalApplicationsController.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 27.03.2025.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
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
