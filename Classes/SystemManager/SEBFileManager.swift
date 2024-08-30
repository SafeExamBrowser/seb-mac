//
//  FileManager.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 19.08.2024.
//

import Foundation
import CocoaLumberjackSwift

@objc class SEBFileManager: NSObject {
    
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
        if parentDirectory.lastPathComponent.hasPrefix("NSIRD_\(SEBFullAppName)") {
            do {
                try fileManager.removeItem(atPath: parentDirectory.path)
            } catch let error {
                DDLogError("Could not remove temporary app directory with error: \(error)")
                return false
            }
        }
        return true
    }
}
    
