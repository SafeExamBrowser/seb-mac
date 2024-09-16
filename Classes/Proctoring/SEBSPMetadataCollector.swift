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
    var screenProctoringMetadataBrowser: String?
}

@objc public enum UIEventChange: Int {
    case began
    case modified
    case ended
    case cancelled
}

public class SEBSPMetadataCollector {
    
    private var delegate: ScreenProctoringDelegate?
    private var settings: MetadataSettings
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    
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
            metadata.screenProctoringMetadataBrowser = delegate?.getScreenProctoringMetadataBrowser()
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
        if localEventMonitor == nil || globalEventMonitor == nil {
#if os(macOS)
            let eventHandler = { (event: NSEvent) in
                var eventTypeString = ""
                let location = NSEvent.mouseLocation
                let locationString = " (at \(Int(location.x)), \(Int(location.y)))"
                switch event.type {
                case .leftMouseDown:
                    eventTypeString = "Left mouse pressed"
                case .leftMouseUp:
                    eventTypeString = "Left mouse released"
                case .rightMouseDown:
                    eventTypeString = "Right mouse pressed"
                case .rightMouseUp:
                    eventTypeString = "Right mouse released"
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
                    eventTypeString = "Key pressed \(self.keyEventDesciption(event: event))"
                case .keyUp:
                    eventTypeString = "Key released \(self.keyEventDesciption(event: event))"
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
                    eventTypeString = "Middle mouse pressed"
                case .otherMouseUp:
                    eventTypeString = "Middle mouse released"
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
                DDLogVerbose("Event: \(eventTypeString)")
                self.delegate?.collectedTriggerEvent?(eventData: eventTypeString)
            }
            
            localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.any) { event in
                eventHandler(event)
                return event
            }
            globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.any) { event in
                eventHandler(event)
            }
#endif
        }
    }
    
    public func stopMonitoringEvents() {
#if os(macOS)
        if globalEventMonitor != nil {
            NSEvent.removeMonitor(globalEventMonitor!)
            globalEventMonitor = nil
        }
        if localEventMonitor != nil {
            NSEvent.removeMonitor(localEventMonitor!)
            localEventMonitor = nil
        }
#endif
    }
    
#if os(iOS)
    public func receivedUIEvent(_ event: UIEvent?, view: UIView) {
        var eventTypeString = ""
        
        switch event?.type {
        case .touches:
            eventTypeString = "touch"
        case .motion:
            eventTypeString = "motion"
        case .remoteControl:
            eventTypeString = "remote control"
        case .presses:
            eventTypeString = "press"
        case .scroll:
            eventTypeString = "scroll"
        case .hover:
            eventTypeString = "hover"
        case .transform:
            eventTypeString = "transform"
        case nil:
            eventTypeString = "none"
        case .some(_):
            break
        }
        
        if let uiPressesEvent = event as? UIPressesEvent {
            let presses = uiPressesEvent.allPresses
            var keyEventDescriptions = Array<String>()
            for uiPress in presses {
                keyEventDescriptions.append(keyEventDesciption(uiPress: uiPress))
            }
            eventTypeString = eventTypeString + (keyEventDescriptions.isEmpty ? "" : (eventTypeString.isEmpty ? "" : ": ") + keyEventDescriptions.joined(separator: "/"))
        } else {
            if let touches = event?.allTouches {
                var touchEventDescriptions = Array<String>()
                for touch in touches {
                    let touchEventDescription = touchEventDesciption(touch, view: view)
                    touchEventDescriptions.append("\(touchEventDescription.prefix) \(eventTypeString) \(touchEventDescription.suffix)")
                }
                eventTypeString = touchEventDescriptions.joined(separator: "/")
            } else {
#if DEBUG
                DDLogDebug("SEB Screen Proctoring Metadata Collector: UIEvent without presses or touches.")
#endif
            }
        }
        eventTypeString.firstUppercased
        DDLogVerbose("Event: \(eventTypeString)")
        self.delegate?.collectedTriggerEvent?(eventData: eventTypeString)
    }
    
//    public func touchesChange(_ change:UIEventChange, touches: Set<UITouch>, with event: UIEvent?) {
//    }
//
//    public func pressesChange(_ change:UIEventChange, presses: Set<UIPress>, with event: UIPressesEvent?) {
//        let key = event.key
//    }

    func touchEventDesciption(_ touch: UITouch, view: UIView) -> (prefix: String, suffix: String) {
        var touchEventPrefix = ""
        var touchEventSufix = ""

        let location = touch.location(in: view)
        let touchLocationString = " (at \(Int(location.x)), \(Int(location.y)))"

        switch touch.type {
        case .direct:
            touchEventPrefix = "direct"
        case .indirect:
            touchEventPrefix = "indirect"
        case .pencil:
            touchEventPrefix = "pencil"
        case .indirectPointer:
            touchEventPrefix = "indirect pointer"
        @unknown default:
            touchEventPrefix = "unknown"
        }

        switch touch.phase {
        case .began:
            touchEventSufix = "began"
        case .moved:
            touchEventSufix = "moved"
        case .stationary:
            touchEventSufix = "stationary"
        case .ended:
            touchEventSufix = "ended"
        case .cancelled:
            touchEventSufix = "cancelled"
        case .regionEntered:
            touchEventSufix = "region entered"
        case .regionMoved:
            touchEventSufix = "region moved"
        case .regionExited:
            touchEventSufix = "region exited"
        @unknown default:
            break
        }
        
        touchEventSufix += touchLocationString

        return (prefix: touchEventPrefix, suffix: touchEventSufix)
    }
    
    func keyEventDesciption(uiPress: UIPress) -> String {
        var keyEventDescription = ""
        if let key = uiPress.key  {
            if #available(iOS 13.4, *) {
                let characters = key.charactersIgnoringModifiers.replaceSpecialCharactersWithKeyName()
                let modifiers = keyModifiers(key: key)
                let resultingCharacters = key.characters.replaceSpecialCharactersWithKeyName()
                if characters != nil || resultingCharacters != nil || !modifiers.isEmpty {
                    if characters != nil && !modifiers.isEmpty {
                        keyEventDescription = "\(modifiers)-\(characters!)"
                    } else if !modifiers.isEmpty {
                        keyEventDescription = modifiers
                    }
                    if characters != nil && keyEventDescription.isEmpty {
                        keyEventDescription = "Alphanumeric key"
                    } else {
                        if resultingCharacters != nil {
            //                keyEventDescription = "'\(resultingCharacters!)' (\(keyEventDescription))"
                            keyEventDescription = "'Alphanumeric key' (\(keyEventDescription))"
                        }
                    }
                }
            } else {
                keyEventDescription = "Alphanumeric key"
            }
        } else {
            var nonKeyboardKey = ""
            switch uiPress.type {
            case .upArrow:
                nonKeyboardKey = "Up Arrow"
            case .downArrow:
                nonKeyboardKey = "Down Arrow"
            case .leftArrow:
                nonKeyboardKey = "Left Arrow"
            case .rightArrow:
                nonKeyboardKeys = "Right Arrow"
            case .select:
                nonKeyboardKeys = "Select"
            case .menu:
                nonKeyboardKeys = "Menu"
            case .playPause:
                nonKeyboardKeys = "Play/Pause"
            case .pageUp:
                nonKeyboardKey = "Page Up"
            case .pageDown:
                nonKeyboardKey = "Page Down"
            @unknown default:
                nonKeyboardKey = "Unknown"
            }
            keyEventDescription = "\(nonKeyboardKey) button"
        }
        switch uiPress.phase {
        case .began:
            keyEventDescription += " pressed"
        case .changed:
            keyEventDescription += " changed"
            break
        case .stationary:
            break
        case .ended:
            keyEventDescription += " released"
        case .cancelled:
            keyEventDescription += " cancelled"
        @unknown default:
            break
        }
        return keyEventDescription
    }

    @available(iOS 13.4, *)
    func keyModifiers(key: UIKey) -> String {
        let modifierMask = key.modifierFlags
        var modifiers = Array<String>()
        if modifierMask.contains(.alphaShift) {
            modifiers.append("Caps Lock")
        }
        if modifierMask.contains(.shift) {
            modifiers.append("Shift")
        }
        if modifierMask.contains(.control) {
            modifiers.append("Control")
        }
        if modifierMask.contains(.alternate) {
            modifiers.append("Option/Alt")
        }
        if modifierMask.contains(.command) {
            modifiers.append("Command")
        }
        if modifierMask.contains(.numericPad) {
            modifiers.append("numeric keypad/arrow key")
        }
        return modifiers.joined(separator: "-")
    }
#endif
    
    
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
            } 
            if characters != nil && keyEventDescription.isEmpty {
                keyEventDescription = "alphanumeric key"
            } else {
                if resultingCharacters != nil {
    //                keyEventDescription = "'\(resultingCharacters!)' (\(keyEventDescription))"
                    keyEventDescription = "'alphanumeric key' (\(keyEventDescription))"
                }
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
        var newString = self.replacingOccurrences(of: "\t", with: "Tab")
        newString = newString.replacingOccurrences(of: "\r", with: "Return")
        newString = newString.replacingOccurrences(of: "\u{08}", with: "Backspace")
        return newString
    }
}

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { prefix(1).capitalized + dropFirst() }
}
