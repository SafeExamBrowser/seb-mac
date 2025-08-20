//
//  FileManager.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 19.08.2024.
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

@objc class SEBFileManager: NSObject {
 
    var downUploadTempURL: URL?

    override init() {
        dynamicLogLevel = MyGlobals.ddLogLevel()
    }
 
    @objc static func createTemporaryDirectory() -> URL {
        
        let fileManager = FileManager.default
        var tempDirectory: URL
        do {
            tempDirectory = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: fileManager.temporaryDirectory, create: true)
        } catch let error {
            DDLogError("Creating temporary directory failed with error: \(error)")
            // As a fallback just use the default temporary directory
            tempDirectory = fileManager.temporaryDirectory
        }
        var tempDirectoryURL = tempDirectory.appendingPathComponent(UUID().uuidString)
        
        if !fileManager.fileExists(atPath: tempDirectoryURL.path) {
            do {
                try fileManager.createDirectory(atPath: tempDirectoryURL.path, withIntermediateDirectories: true)
            } catch let error {
                DDLogError("Creating temporary subfolder failed with error: \(error)")
                // As a fallback just use the default temporary directory
                tempDirectoryURL = fileManager.temporaryDirectory
            }
        } else {
            DDLogDebug("Temporary directory already existed at \(tempDirectoryURL)");
            return createTemporaryDirectory()
        }
        return tempDirectoryURL
    }
    
    @objc static func removeTemporaryDirectory(url: URL) -> Bool {
        let fileManager = FileManager.default
        do {
            let filesInTemporaryDirectory = try fileManager.contentsOfDirectory(atPath: url.path)
            DDLogInfo("Contents of the temporary directory: \(filesInTemporaryDirectory)")
        } catch let error {
            DDLogError("Reading contents of temporary directory failed with error: \(error)")
        }
        do {
            try fileManager.removeItem(atPath: url.path)
        } catch let error {
            DDLogError("Could not remove temporary directory with error: \(error)")
        }
        let parentDirectory = url.deletingLastPathComponent()
#if os(macOS)
        let directoryPrefix = "NSIRD_\(SEBFullAppName)"
#elseif os(iOS)
        let directoryPrefix = "NSIRD_\(SEBShortAppName)"
#endif
        if parentDirectory.lastPathComponent.hasPrefix(directoryPrefix) {
            do {
                try fileManager.removeItem(atPath: parentDirectory.path)
            } catch let error {
                DDLogError("Could not remove temporary app directory with error: \(error)")
                return false
            }
        }
        return true
    }
    
    @objc func getTempDownUploadDirectory(configKey: Data) -> URL {
        if downUploadTempURL == nil {
            // Check if there is a temporary down/upload directory location persistently stored
            // What only happends when it couldn't be reset last time SEB has run
            let storedDirectoryURLConfigKey = getStoredDirectoryURL(key: TempDownUploadLocation, currentConfigKey: configKey)
            if storedDirectoryURLConfigKey != nil {
                // There is a redirected location saved
                let storedDownUploadDirectoryURL = storedDirectoryURLConfigKey?.url //sebSystemManager.getStoredDirectoryURL(withKey: TempDownUploadLocation)
                let storedDownUploadDirectoryConfigKey = storedDirectoryURLConfigKey?.configKey
                DDLogDebug("There was a persistently saved temporary down/upload directory location\(storedDownUploadDirectoryURL!.path) with ConfigKey \(storedDownUploadDirectoryConfigKey as Any). Looks like SEB didn't quit properly when running last time.")
                // Check if this directory actually exists
                if !FileManager.default.fileExists(atPath: storedDownUploadDirectoryURL!.path) {
                    DDLogDebug("The persistently saved temporary down/upload directory doesn't actually exist anymore. Create new one.")
                } else {
                    downUploadTempURL = storedDownUploadDirectoryURL
                    return downUploadTempURL!
                }
            }
            // No temporary down/upload directory location was persistently saved or it doesn't actually exist
            downUploadTempURL = SEBFileManager.createTemporaryDirectory()
            storeDirectoryURL(downUploadTempURL!, key: TempDownUploadLocation, configKey: configKey)
        } else {
            DDLogDebug("Temporary down/upload directory location was already set: \(downUploadTempURL!.path)");
        }
        return downUploadTempURL!
    }
    
    @objc func removeTempDownUploadDirectory() -> Bool {
        if downUploadTempURL != nil {
            if SEBFileManager.removeTemporaryDirectory(url: downUploadTempURL!) {
                UserDefaults.standard.setPersistedSecureObject(Data(), forKey: TempDownUploadLocation)
#if DEBUG
                DDLogDebug("Removed temp downUpload location \(downUploadTempURL!.path) successfully.")
#else
                DDLogDebug("Removed temp downUpload location successfully.")
#endif
            } else {
#if DEBUG
                DDLogError("Failed removing temp downUpload location \(downUploadTempURL!.path)")
#else
                DDLogDebug("Failed removing temp downUpload location")
#endif
                downUploadTempURL = nil
                return false
            }
            downUploadTempURL = nil
        }
        return true
    }

    private func storeDirectoryURL(_ url: URL, key: String, configKey: Data) {
        let storedDirectoryURLDictionary = ["url" : url, "configKey" : configKey] as [String : Any]
        var data = Data()
        do {
            data = try NSKeyedArchiver.archivedData(withRootObject: storedDirectoryURLDictionary, requiringSecureCoding: true)
        } catch let error {
            DDLogError("Could not encode stored URL dictionary with error \(error)")
        }
        UserDefaults.standard.setPersistedSecureObject(data, forKey: key)
    }

    private func getStoredDirectoryURL(key: String, currentConfigKey: Data) -> (url: URL, configKey: Data)? {
        guard let storedDirectoryData = UserDefaults.standard.persistedSecureObject(forKey: key) as? Data else {
            return nil
        }
        if !storedDirectoryData.isEmpty {
            do {
                guard let storedDirectoryURLDictionary = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, NSString.self, NSURL.self, NSData.self], from: storedDirectoryData) as? [String : Any] else {
                    return nil
                }
                guard let directoryURL = storedDirectoryURLDictionary["url"] as? URL else {
                    return nil
                }
                // We perform this check for security reasons...
                if directoryURL.path.hasPrefix("../") {
                    return nil
                }
                guard let directoryURLConfigKey = storedDirectoryURLDictionary["configKey"] as? Data else {
                    return nil
                }
                if currentConfigKey != directoryURLConfigKey {
                    return nil
                }
                return (directoryURL, directoryURLConfigKey)
            } catch let error {
                DDLogError("Could not decode stored URL dictionary with error \(error)")
            }
        }
        return nil
    }
}
    
