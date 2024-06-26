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
            DDLogError("SEB Screen Proctoring Metadata Collector: Creating json from metadata failed: \(String(describing: error))")
        }
        return nil
    }
    
    public func monitorEvents() {

#if os(macOS)
        let eventHandler = { (event: NSEvent) in
            var eventTypeString = ""
            let location = NSEvent.mouseLocation
            let locationString = " (at \(Int(location.x)), \(Int(location.y)))"
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
                eventTypeString = "Key down \(self.keyEventDesciption(event: event))"
            case .keyUp:
                eventTypeString = "Key up \(self.keyEventDesciption(event: event))"
            case .flagsChanged:
                eventTypeString = "Modifier key pressed \(self.keyEventModifiers(event: event))"
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
            eventTypeString += locationString
            DDLogDebug("Event: \(eventTypeString)")
            self.delegate?.collectedTriggerEvent(eventData: eventTypeString)
        }
        
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.any) { event in
            eventHandler(event)
            return event
        }
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.any) { event in
            eventHandler(event)
        }
        #endif
    }
    
#if os(macOS)

    func keyEventDesciption(event: NSEvent) -> String {
        let characters = event.charactersIgnoringModifiers?.replaceSpecialCharactersWithKeyName()
        let modifiers = keyEventModifiers(event: event)
        let resultingCharacters = event.characters?.replaceSpecialCharactersWithKeyName()
        var keyEventDescription = ""
        if characters != nil || resultingCharacters != nil || !modifiers.isEmpty {
            
            if characters != nil && !modifiers.isEmpty {
                keyEventDescription = "\(modifiers)-\(characters!)"
            } else if !modifiers.isEmpty {
                keyEventDescription = modifiers
            } else if characters != nil {
                keyEventDescription = characters!
            }

            if resultingCharacters != nil {
                keyEventDescription = "'\(resultingCharacters!)' (\(keyEventDescription))"
            }
            keyEventDescription = ": \(keyEventDescription)"
        }
        return keyEventDescription
    }
    
    func keyEventModifiers(event: NSEvent) -> String {
        let modifierMask = event.modifierFlags
        var modifiers = Array<String>()
        if modifierMask.contains(.capsLock) {
            modifiers.append("Caps Lock")
        }
        if modifierMask.contains(.shift) {
            modifiers.append("Shift")
        }
        if modifierMask.contains(.control) {
            modifiers.append("Control")
        }
        if modifierMask.contains(.option) {
            modifiers.append("Option/Alt")
        }
        if modifierMask.contains(.command) {
            modifiers.append("Command")
        }
        if modifierMask.contains(.numericPad) {
            modifiers.append("numeric keypad/arrow key")
        }
        if modifierMask.contains(.help) {
            modifiers.append("Help")
        }
        if modifierMask.contains(.function) {
            modifiers.append("function")
        }
        return modifiers.joined(separator: "-")
    }
#endif
}

extension String {
    public func replaceSpecialCharactersWithKeyName() -> String? {
        self.replacingOccurrences(of: "\t", with: "Tab")
    }
}
