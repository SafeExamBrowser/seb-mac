//
//  SEBSPMetaDataCollector.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 27.05.24.
//

import Foundation
import CocoaLumberjackSwift

struct Metadata: Codable {
    var screenProctoringMetadataURL: String?
    var screenProctoringMetadataWindowTitle: String?
    var screenProctoringMetadataActiveApp: String?
    var screenProctoringMetadataUserAction: String?
}

public class SEBSPMetadataCollector {

    private var delegate: ScreenProctoringDelegate?
    private var settings: MetadataSettings

    init(delegate: ScreenProctoringDelegate?, settings: MetadataSettings) {
        self.delegate = delegate
        self.settings = settings
        dynamicLogLevel = MyGlobals.ddLogLevel()
    }
    
    public func collectMetaData() -> String? {
        var metadata = Metadata()

        if settings.activeAppEnabled || settings.activeWindowEnabled {
            if let activeAppWindowMetadata = delegate?.getScreenProctoringMetadataActiveAppWindow() {
                
                if settings.activeAppEnabled {
                    metadata.screenProctoringMetadataActiveApp = activeAppWindowMetadata["activeApp", default: ""]
                }

                if settings.activeWindowEnabled {
                    metadata.screenProctoringMetadataWindowTitle = activeAppWindowMetadata["activeWindow", default: ""]
                }
            }
        }
                
        if settings.urlEnabled {
            metadata.screenProctoringMetadataURL = delegate?.getScreenProctoringMetadataURL()
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
//        if #available(macOS 10.15, *) {
//            encoder.outputFormatting = .withoutEscapingSlashes
//        } else {
//            encoder.outputFormatting = .sortedKeys
//        }

        do {
            let data = try encoder.encode(metadata)
            return String(data: data, encoding: String.Encoding.utf8)
        } catch let error {
            DDLogError("SEB Server API Discovery Resource failed: \(String(describing: error))")
        }
        return nil
    }
}
