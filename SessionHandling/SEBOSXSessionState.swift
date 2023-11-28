//
//  SEBOSXSessionState.swift
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 21.11.23.
//

import Foundation

@objc public class SEBOSXSessionState: NSObject {
    
    @objc var isAACEnabled = false
    @objc var overrideAAC = false
    @objc var wasAACEnabled = false
    @objc var allowSwitchToApplications = false

    @objc var reOpenedExamDetected = false
    @objc var userSwitchDetected = false
    @objc var screenSharingDetected = false
    @objc var screenSharingCheckOverride = false
    @objc var processesDetected = false
    @objc var processCheckSpecificOverride = false
    @objc var processCheckAllOverride = false
    @objc var overriddenProhibitedProcesses: Array<Any>?
    @objc var siriDetected = false
    @objc var siriCheckOverride = false
    @objc var dictationCheckOverride = false
    @objc var dictationDetected = false
    @objc var noRequiredBuiltInScreenAvailable = false
    @objc var builtinDisplayNotAvailableDetected = false
    @objc var builtinDisplayEnforceOverride = false
    @objc var proctoringFailedDetected = false

    @objc var f3Pressed = false
    @objc var alternateKeyPressed = false
    @objc var tabPressedWhileDockIsKeyWindow = false
    @objc var tabPressedWhileWebViewIsFirstResponder = false
    @objc var shiftTabPressedWhileDockIsKeyWindow = false
    @objc var shiftTabPressedWhileWebViewIsFirstResponder = false
    @objc var startingUp = false
    @objc var openedURL = false
    @objc var restarting = false
    @objc var openingSettings = false
    @objc var conditionalInitAfterProcessesChecked = false
    @objc var quittingMyself = false
    @objc var isTerminating = false
    @objc var openingSettingsFileURL: URL?

}
