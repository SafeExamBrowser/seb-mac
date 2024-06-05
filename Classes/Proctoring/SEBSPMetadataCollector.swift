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
    
    public func collectMetaData(triggerMetadata: String) -> String? {
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
        
        metadata.screenProctoringMetadataUserAction = triggerMetadata
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        do {
            let data = try encoder.encode(metadata)
            return String(data: data, encoding: String.Encoding.utf8)
        } catch let error {
            DDLogError("SEB Server API Discovery Resource failed: \(String(describing: error))")
        }
        return nil
    }
    
    public func monitorEvents() {
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.any) { event in
            var eventTypeString = ""
            switch event.type {
            case .leftMouseDown:
                eventTypeString = "Left mouse down"
            case .leftMouseUp:
                eventTypeString = "Left mouse up"
            case .rightMouseDown:
                eventTypeString = "Right mouse down"
            case .rightMouseUp:
                eventTypeString = "Right mouse up"
            case .mouseMoved:
                eventTypeString = "Mouse moved"
            case .leftMouseDragged:
                eventTypeString = "Left mouse dragged"
            case .rightMouseDragged:
                eventTypeString = "Right mouse dragged"
            case .mouseEntered:
                eventTypeString = "Mouse entered area"
            case .mouseExited:
                eventTypeString = "Mouse exited area"
            case .keyDown:
                eventTypeString = "Key down"
            case .keyUp:
                eventTypeString = "Key up"
            case .flagsChanged:
                eventTypeString = "Modifier key pressed"
            case .appKitDefined:
                eventTypeString = "AppKit-related event"
            case .systemDefined:
                eventTypeString = "System-related event"
            case .applicationDefined:
                eventTypeString = "App-defined event"
            case .periodic:
                eventTypeString = "Event that provides execution time to periodic tasks"
            case .cursorUpdate:
                eventTypeString = "Cursor was updated"
            case .scrollWheel:
                eventTypeString = "Scroll wheel position changed"
            case .tabletPoint:
                eventTypeString = "Point on a tablet touched"
            case .tabletProximity:
                eventTypeString = "Pencil hovering over a tablet"
            case .otherMouseDown:
                eventTypeString = "Middle mouse down"
            case .otherMouseUp:
                eventTypeString = "Middle mouse up"
            case .otherMouseDragged:
                eventTypeString = "Middle mouse dragged"
            case .gesture:
                eventTypeString = "Some gesture performed"
            case .magnify:
                eventTypeString = "Magnifying gesture performed"
            case .swipe:
                eventTypeString = "Swipe gesture performed"
            case .rotate:
                eventTypeString = "Rotate gesture performed"
            case .beginGesture:
                eventTypeString = "Gesture starting"
            case .endGesture:
                eventTypeString = "Gesture ending"
            case .smartMagnify:
                eventTypeString = "Smart zoom gesture (two-finger double tap) performed"
            case .quickLook:
                eventTypeString = "Quick Look request initiated"
            case .pressure:
                eventTypeString = "Pressure changed"
            case .directTouch:
                eventTypeString = "Touch bar touched"
            case .changeMode:
                eventTypeString = "Mode of a pencil on an iPad connected as screen changed"
            @unknown default:
                eventTypeString = "Unknown event type (\(event.type))"
            }
            DDLogDebug("Event: \(eventTypeString)")
            self.delegate?.collectedTriggerEvent(eventData: eventTypeString)
        }
    }
}
