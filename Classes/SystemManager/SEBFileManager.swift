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
}
    
