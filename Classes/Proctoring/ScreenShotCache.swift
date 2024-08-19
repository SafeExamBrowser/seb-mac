//
//  ScreenShotCache.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 18.08.2024.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import Foundation
import CocoaLumberjackSwift

protocol ScreenShotTransmissionDelegate {
    func transmitScreenShot(data: Data, metaData: String, timeStamp: TimeInterval)
    func startDeferredTransmissionTimer(_ interval: Int)
}

public class ScreenShotCache: FIFOBuffer {
    var delegate: ScreenShotTransmissionDelegate
    private var cacheDirectoryURL: URL?

    init(delegate: ScreenShotTransmissionDelegate) {
        self.delegate = delegate
        dynamicLogLevel = MyGlobals.ddLogLevel()
        cacheDirectoryURL = SEBFileManager.createTemporaryDirectory()
    }
    
    struct CachedScreenShot {
        var metaData: String
        var timestamp: TimeInterval
        var transmissionInverval: Int
        var filename: String?
        
        init(metaData: String, timestamp: TimeInterval, transmissionInverval: Int) {
            self.metaData = metaData
            self.timestamp = timestamp
            self.transmissionInverval = transmissionInverval
        }
    }
    
    
    func cacheScreenShotForSending(data: Data, metaData: String, timeStamp: TimeInterval, transmissionInterval: Int) {
        var cachedScreenShotObject = CachedScreenShot(metaData: metaData, timestamp: timeStamp, transmissionInverval: transmissionInterval)
        let filename = "ScreenShot_\(timeStamp).png"
        cachedScreenShotObject.filename = filename
        var fileURL: URL
        if #available(macOS 13.0, iOS 16.0, *) {
            fileURL = cacheDirectoryURL!.appending(path: filename)
        } else {
            fileURL = cacheDirectoryURL!.appendingPathComponent(filename)
        }
        do {
            try data.write(to: fileURL, options: [.atomic])
        } catch let error {
            DDLogError("Writing screen shot at \(fileURL) failed with error: \(error)")
            return
        }
        pushObject(cachedScreenShotObject)
    }
    
    func transmitNextCachedScreenShot() {
        guard let screenShot = popObject() as? CachedScreenShot else {
            return
        }
        guard let filename = screenShot.filename else {
            return
        }
        var fileURL: URL
        if #available(macOS 13.0, iOS 16.0, *) {
            fileURL = cacheDirectoryURL!.appending(path: filename)
        } else {
            fileURL = cacheDirectoryURL!.appendingPathComponent(filename)
        }
        do {
            let screenShotData = try Data(contentsOf: fileURL)
            delegate.transmitScreenShot(data: screenShotData, metaData: screenShot.metaData, timeStamp: screenShot.timestamp)
        } catch let error {
            DDLogError("Reading screen shot at \(fileURL) failed with error: \(error)")
            return
        }
    }
}
