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

protocol ScreenShotTransmissionDelegate {
    func transmitScreenShot(data: Data, metaData: String, timeStamp: TimeInterval)
    func startDeferredTransmissionTimer(_ interval: Int)
}

public class ScreenShotCache: FIFOBuffer {
    var delegate: ScreenShotTransmissionDelegate

    init(delegate: ScreenShotTransmissionDelegate) {
        self.delegate = delegate
    }
    
    struct CachedScreenShot {
        var metaData: String
        var timestamp: TimeInterval
        var transmissionInverval: Int
        var filename: String?
        var data: Data?
        
        init(metaData: String, timestamp: TimeInterval, transmissionInverval: Int) {
            self.metaData = metaData
            self.timestamp = timestamp
            self.transmissionInverval = transmissionInverval
        }
    }
    
    
    func cacheScreenShotForSending(data: Data, metaData: String, timeStamp: TimeInterval, transmissionInterval: Int) {
        var cachedScreenShotObject = CachedScreenShot(metaData: metaData, timestamp: timeStamp, transmissionInverval: transmissionInterval)
        let filename = "ScreenShot_\(timeStamp)"
        cachedScreenShotObject.filename = filename
        pushObject(cachedScreenShotObject)
        // delegate.startDeferredTransmissionTimer(transmissionIntervall)
    }
    
    func transmitNextCachedScreenShot() {
        guard let screenShot = popObject() as? CachedScreenShot else {
            return
        }
        let filename = screenShot.filename
        // read screen shot from file system
        // {
        //   guard let screenShotData = screenShot.data else {
        //   return
        //
        //    delegate.transmitScreenShot(data: screenShotData, metaData: screenShot.metaData, timeStamp: screenShot.timestamp)
        // }
    }
}
