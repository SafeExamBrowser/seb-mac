//
//  SEBSPMetaDataCollector.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 27.05.24.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import Foundation
import CocoaLumberjackSwift

@objc public protocol SEBSPMetadataCollectorDelegate: AnyObject {
    func receivedUIEvent(_ event: UIEvent?)
}

struct Metadata: Codable {
    var screenProctoringMetadataURL: String?
    var screenProctoringMetadataWindowTitle: String?
    var screenProctoringMetadataApplication: String?
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
    private var maxJSONLength = 4000

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
                    metadata.screenProctoringMetadataApplication = activeAppWindowMetadata["activeApp", default: ""]
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
            let metadataJsonString = String(data: data, encoding: String.Encoding.utf8)
#if DEBUG
            DDLogDebug("Metadata Collector: Coalesced metadata JSON: \(metadataJsonString as Any)")
#endif
            DDLogDebug("SEB Screen Proctoring Metadata Collector: Metadata length: \(metadataJsonString?.count as Any)")
            if (metadataJsonString?.count ?? 00) > maxJSONLength {
                DDLogError("SEB Screen Proctoring Metadata Collector: JSON exceeded maximum length of \(maxJSONLength) chars and was not sent: \(String(describing: metadataJsonString))")
                return ""
            }
            return metadataJsonString
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
                    eventTypeString = "Key pressed: \(self.keyEventDesciption(event: event))"
                case .keyUp:
                    eventTypeString = "Key released: \(self.keyEventDesciption(event: event))"
                case .flagsChanged:
                    let modifier = self.keyEventModifiers(event: event)
                    eventTypeString = "Modifier key pressed\(modifier.count > 0 ? ": \(modifier)" : ""))"
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
        var eventNotTouchBegan = false
        
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
                eventNotTouchBegan = true
            }
            eventTypeString = eventTypeString + (keyEventDescriptions.isEmpty ? "" : (eventTypeString.isEmpty ? "" : ": ") + keyEventDescriptions.joined(separator: "/"))
        } else {
            if let touches = event?.allTouches {
                var touchEventDescriptions = Array<String>()
                for touch in touches {
                    if touch.phase != .began {
                        eventNotTouchBegan = true
                    }
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
        eventTypeString = eventTypeString.firstUppercased
        DDLogVerbose("Event: \(eventTypeString)")
        if eventNotTouchBegan {
            self.delegate?.collectedTriggerEvent?(eventData: eventTypeString)
        } else {
            DDLogVerbose("Event was touch began, not triggering screen shot.")
        }
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
                var characters = key.charactersIgnoringModifiers
                if characters.replacedSpecialCharactersWithKeyName() {
                    keyEventDescription = characters
                }
                let modifiers = keyModifiers(key: key)
                var resultingCharacters = key.characters
                if resultingCharacters.replacedSpecialCharactersWithKeyName() && keyEventDescription.isEmpty {
                    keyEventDescription = resultingCharacters
                }
                if !characters.isEmpty || !resultingCharacters.isEmpty || !modifiers.isEmpty {
                    if !modifiers.isEmpty && !characters.isEmpty && !(modifiers == "Shift" || modifiers == "Option/Alt") {
                            keyEventDescription = "\(modifiers)-\(characters)"
                        self.delegate?.collectedKeyboardShortcutEvent?(keyEventDescription)
                    }
                    if (!characters.isEmpty || !resultingCharacters.isEmpty) && keyEventDescription.isEmpty {
                        keyEventDescription = keysSPS.alphanumericKeyString.firstUppercased
                        self.delegate?.collectedAlphanumericKeyEvent?()
                    } else if !modifiers.isEmpty && keyEventDescription.isEmpty {
                        keyEventDescription = modifiers
                    }
                }
            } else if keyEventDescription.isEmpty {
                keyEventDescription = keysSPS.alphanumericKeyString.firstUppercased
                self.delegate?.collectedAlphanumericKeyEvent?()
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
                nonKeyboardKey = "Right Arrow"
            case .select:
                nonKeyboardKey = "Select"
            case .menu:
                nonKeyboardKey = "Menu"
            case .playPause:
                nonKeyboardKey = "Play/Pause"
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
            modifiers.append("Numeric keypad/arrow key")
        }
        return modifiers.joined(separator: "-")
    }
#endif
    
    
#if os(macOS)
    
    func keyEventDesciption(event: NSEvent) -> String {
        var keyEventDescription = ""
        var characters = event.charactersIgnoringModifiers ?? ""
        if characters.replacedSpecialCharactersWithKeyName() {
            keyEventDescription = characters
        }
        let modifiers = keyEventModifiers(event: event)
        var resultingCharacters = event.characters ?? ""
        if resultingCharacters.replacedSpecialCharactersWithKeyName() && keyEventDescription.isEmpty {
            keyEventDescription = resultingCharacters
        }
        if !characters.isEmpty || !resultingCharacters.isEmpty || !modifiers.isEmpty {
            if !modifiers.isEmpty && !characters.isEmpty && !(modifiers == "Shift" || modifiers == "Option/Alt") {
                keyEventDescription = "\(modifiers)-\(characters)"
                self.delegate?.collectedKeyboardShortcutEvent?(keyEventDescription)
            }
            if (!characters.isEmpty || !resultingCharacters.isEmpty) && keyEventDescription.isEmpty {
                keyEventDescription = keysSPS.alphanumericKeyString.firstUppercased
                self.delegate?.collectedAlphanumericKeyEvent?()
            } else if !modifiers.isEmpty && keyEventDescription.isEmpty {
                keyEventDescription = modifiers
            }
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
        if modifierMask.contains(.deviceIndependentFlagsMask) {
            modifiers.append("device-independent modifier")
        }
        return modifiers.joined(separator: "-")
    }
#endif
}

extension String {
    public func replaceSpecialCharactersWithKeyName() -> String {
        var newString = self.replacingOccurrences(of: "\t", with: "Tab")
        newString = newString.replacingOccurrences(of: "\r", with: "Return")
        newString = newString.replacingOccurrences(of: "\u{03}", with: "Enter")
        newString = newString.replacingOccurrences(of: "\u{08}", with: "Backspace")
        newString = newString.replacingOccurrences(of: "\u{0a}", with: "Newline")
        newString = newString.replacingOccurrences(of: "\u{0c}", with: "Form Feed")
        newString = newString.replacingOccurrences(of: "\u{0d}", with: "Carriage Return")
        newString = newString.replacingOccurrences(of: "\u{19}", with: "Back Tab")
        newString = newString.replacingOccurrences(of: "\u{7f}", with: "Delete")
        newString = newString.replacingOccurrences(of: "\u{2028}", with: "Line Separator")
        newString = newString.replacingOccurrences(of: "\u{2029}", with: "Paragraph Separator")
        newString = newString.replacingOccurrences(of: "\u{2191}", with: "Cursor Up")
        newString = newString.replacingOccurrences(of: "\u{2193}", with: "Cursor Down")
        newString = newString.replacingOccurrences(of: "\u{2190}", with: "Cursor Left")
        newString = newString.replacingOccurrences(of: "\u{2192}", with: "Cursor Right")
#if os(iOS)
        newString = newString.replacingOccurrences(of: UIKeyCommand.inputEscape, with: "Escape")
        newString = newString.replacingOccurrences(of: UIKeyCommand.inputUpArrow, with: "Cursor Up")
        newString = newString.replacingOccurrences(of: UIKeyCommand.inputDownArrow, with: "Cursor Down")
        newString = newString.replacingOccurrences(of: UIKeyCommand.inputLeftArrow, with: "Cursor Left")
        newString = newString.replacingOccurrences(of: UIKeyCommand.inputRightArrow, with: "Cursor Right")
        newString = newString.replacingOccurrences(of: UIKeyCommand.inputPageUp, with: "Page Up")
        newString = newString.replacingOccurrences(of: UIKeyCommand.inputPageDown, with: "Page Down")
        if #available(iOS 13.4, *) {
            newString = newString.replacingOccurrences(of: UIKeyCommand.inputHome, with: "Home")
            newString = newString.replacingOccurrences(of: UIKeyCommand.inputEnd, with: "End")
            newString = newString.replacingOccurrences(of: UIKeyCommand.f1, with: "F1")
            newString = newString.replacingOccurrences(of: UIKeyCommand.f2, with: "F2")
            newString = newString.replacingOccurrences(of: UIKeyCommand.f3, with: "F3")
            newString = newString.replacingOccurrences(of: UIKeyCommand.f4, with: "F4")
            newString = newString.replacingOccurrences(of: UIKeyCommand.f5, with: "F5")
            newString = newString.replacingOccurrences(of: UIKeyCommand.f6, with: "F6")
            newString = newString.replacingOccurrences(of: UIKeyCommand.f7, with: "F7")
            newString = newString.replacingOccurrences(of: UIKeyCommand.f8, with: "F8")
            newString = newString.replacingOccurrences(of: UIKeyCommand.f9, with: "F9")
            newString = newString.replacingOccurrences(of: UIKeyCommand.f10, with: "F10")
            newString = newString.replacingOccurrences(of: UIKeyCommand.f11, with: "F11")
            newString = newString.replacingOccurrences(of: UIKeyCommand.f12, with: "F12")
        }
        if #available(iOS 15.0, *) {
            newString = newString.replacingOccurrences(of: UIKeyCommand.inputDelete, with: "Page Down")
        }
#endif
        return newString
    }
    
    mutating func replacedSpecialCharactersWithKeyName() -> Bool {
        let oldString = self
        self = self.replaceSpecialCharactersWithKeyName()
        return oldString != self
    }
}

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { prefix(1).capitalized + dropFirst() }
}
