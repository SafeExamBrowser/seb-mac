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
    func sendScreenShot(data: Data, metaData: String, timeStamp: TimeInterval?, resending: Bool, completion: ((_ success: Bool) -> Void)?)
    func transmitNextScreenShot()
    func startDeferredTransmissionTimer(_ interval: Int)
    func conditionallyCloseSession()
    var currentServerHealth: Int { get }
}

public class ScreenShotCache: FIFOBuffer {
    var delegate: ScreenShotTransmissionDelegate
    private var encryptSecret: String?
    private var cacheDirectoryURL: URL?
    private var transmittingCachedScreenShots = false
    
    init(delegate: ScreenShotTransmissionDelegate, encryptSecret: String?) {
        self.delegate = delegate
        self.encryptSecret = encryptSecret
        dynamicLogLevel = MyGlobals.ddLogLevel()
        cacheDirectoryURL = SEBFileManager.createTemporaryDirectory()
    }
    
    deinit {
        DDLogDebug("SEB Screen Shot Cache: deint called")
    }
    
    struct CachedScreenShot: Equatable, Hashable {
        var metaData: String
        var timestamp: TimeInterval
        var transmissionInterval: Int
        var filename: String?
        
        init(metaData: String, timestamp: TimeInterval, transmissionInterval: Int) {
            self.metaData = metaData
            self.timestamp = timestamp
            self.transmissionInterval = transmissionInterval
        }
        
        static func == (lhs: CachedScreenShot, rhs: CachedScreenShot) -> Bool {
            return lhs.hashValue == rhs.hashValue
//            return lhs.metaData == rhs.metaData &&
//            lhs.timestamp == rhs.timestamp &&
//            lhs.transmissionInterval == rhs.transmissionInterval &&
//            lhs.filename == rhs.filename
        }
    }
    
    private func screenShotFilename(timeStamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timeStamp)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss_SSS"
        let filename = "ScreenShot_\(dateFormatter.string(from: date)).png"
        return filename
    }
    
    func cacheScreenShotForSending(data: Data, metaData: String, timeStamp: TimeInterval, transmissionInterval: Int) {
        var cachedScreenShotObject = CachedScreenShot(metaData: metaData, timestamp: timeStamp, transmissionInterval: transmissionInterval)
        let filename = screenShotFilename(timeStamp: timeStamp)
        cachedScreenShotObject.filename = filename
        var fileURL: URL
        if #available(macOS 13.0, iOS 16.0, *) {
            fileURL = cacheDirectoryURL!.appending(path: filename)
        } else {
            fileURL = cacheDirectoryURL!.appendingPathComponent(filename)
        }
        do {
            var cacheData = data
            if #available(macOS 10.15.0, iOS 13.0, *) {
                if let keyString = self.encryptSecret {
                    if let symmetricKey = SEBGCMCryptor.symmetricKey(string: keyString) {
                        do {
                            let encryptedData = try SEBGCMCryptor.encryptData(data: data, key: symmetricKey)
                                cacheData = encryptedData
                        } catch let error {
                            DDLogError("Encrypting screen shot failed with error: \(error)")
                        }
                    }
                }
            }
            try cacheData.write(to: fileURL, options: [.atomic])
            DDLogInfo("Screen Shot Cache: Screen shot \(filename) saved.")
        } catch let error {
            DDLogError("Writing screen shot at \(fileURL) failed with error: \(error)")
            return
        }
        pushObject(cachedScreenShotObject)
    }
    
    fileprivate func removeFromQueue(_ screenShot: CachedScreenShot) {
        let removeSuccess = self.removeObject(screenShot)
        if removeSuccess {
            DDLogInfo("Removing screen shot from queue was successful")
        } else {
            DDLogError("Removing screen shot from queue failed, as it was empty")
        }
    }
    
    func transmitNextCachedScreenShot(interval: Int?) {
        guard let screenShot = copyObject() as? CachedScreenShot else {
            DDLogError("Screen Shot Cache: Couldn't pop screen shot from cache for transmission.")
            self.delegate.transmitNextScreenShot()
            return
        }
        guard let filename = screenShot.filename else {
            DDLogError("Screen Shot Cache: Screen shot from cache for transmission didn't had a filename set.")
            self.delegate.transmitNextScreenShot()
            return
        }
        var fileURL: URL
        if #available(macOS 13.0, iOS 16.0, *) {
            fileURL = cacheDirectoryURL!.appending(path: filename)
        } else {
            fileURL = cacheDirectoryURL!.appendingPathComponent(filename)
        }
        
        let startTimerForNextCachedScreenShot = {
            // Copy next cached screen shot (don't remove it from queue)
            guard let screenShot = self.copyObject() as? CachedScreenShot else {
                DDLogError("Screen Shot Cache: Couldn't copy screen shot from cache for deferred transmission.")
                self.delegate.transmitNextScreenShot()
                return
            }
            var transmissionInterval = screenShot.transmissionInterval
            if transmissionInterval == 0 {
                transmissionInterval = 1
            }
            var timerInterval: Int
            if interval != nil {
                timerInterval = interval!
            } else {
                timerInterval = (self.delegate.currentServerHealth + 2) * transmissionInterval
            }
            let filename = self.screenShotFilename(timeStamp: screenShot.timestamp)
            DDLogInfo("Screen Shot Cache: Started timer with interval \(timerInterval) for transmission of screen shot \(filename).")
            // Start timer to transmit the cached screen shot: Use the saved interval between this and the previous screen shot
            // and the current SPS server health + 1 (to prioritize sending cached screen shots lower than current (live) screen shots.
            self.delegate.startDeferredTransmissionTimer(timerInterval)
        }
        
        do {
            var screenShotData = try Data(contentsOf: fileURL)
            if #available(macOS 10.15.0, iOS 13.0, *) {
                if let keyString = self.encryptSecret {
                    if let symmetricKey = SEBGCMCryptor.symmetricKey(string: keyString) {
                        do {
                            let decryptedData = try SEBGCMCryptor.decryptData(ciphertext: screenShotData, key: symmetricKey)
                                screenShotData = decryptedData
                        } catch let error {
                            DDLogError("Decrypting screen shot failed with error: \(error)")
                        }
                    }
                }
            }
            delegate.sendScreenShot(data: screenShotData, metaData: screenShot.metaData, timeStamp: screenShot.timestamp, resending: true, completion: {success in
                if success {
                    var fileURL: URL
                    if #available(macOS 13.0, iOS 16.0, *) {
                        fileURL = self.cacheDirectoryURL!.appending(path: filename)
                    } else {
                        fileURL = self.cacheDirectoryURL!.appendingPathComponent(filename)
                    }
                    DDLogInfo("Screen Shot Cache: Screen shot \(filename) successfully transmitted to SPS, remove from cache.")
                    do {
                        try FileManager.default.removeItem(at: fileURL)
                        DDLogInfo("Screen Shot Cache: Screen shot \(filename) successfully removed from cache.")
                    } catch let error {
                        DDLogError("Screen Shot Cache: Couldn't remove screen shot at \(fileURL) with error: \(error). Removing it from queue anyways.")
                    }
                    self.removeFromQueue(screenShot)
                } else {
                    DDLogWarn("Screen Shot Cache: Cached screen shot \(filename) could not be transmitted. Don't remove it from the cache, attempt sending it later.")
                }
                startTimerForNextCachedScreenShot()
            })
        } catch let error {
            DDLogError("Screen Shot Cache: Reading screen shot at \(fileURL) failed with error: \(error)")

            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain && nsError.code == 260 {
                DDLogError("Screen Shot Cache: Cached screen shot didn't exist anymore, removing it from queue.")
                self.removeFromQueue(screenShot)
            }
            startTimerForNextCachedScreenShot()
        }
    }
    
    func conditionallyRemoveCacheDirectory() {
        guard let temporaryDirectoryURL = cacheDirectoryURL else {
            DDLogInfo("Screen Shot Cache: No temporary cache directory.")
            return
        }
        let success = SEBFileManager.removeTemporaryDirectory(url: temporaryDirectoryURL)
        DDLogInfo("Screen Shot Cache: Temporary directory \(success ? "" : "not ")removed.")
    }
}
