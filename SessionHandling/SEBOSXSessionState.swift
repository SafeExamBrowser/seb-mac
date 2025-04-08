//
//  SEBOSXSessionState.swift
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 21.11.23.
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

@objc public class SEBSessionState: NSObject {
    
    @objc public var sebServerExamStartURL: URL?
    
    @objc lazy public var startURL: URL? = {
        var currentStartURL: URL?
        if sebServerExamStartURL != nil {
            currentStartURL = sebServerExamStartURL
        } else {
            currentStartURL = URL(string: UserDefaults.standard.secureString(forKey: "org_safeexambrowser_SEB_startURL"))
            if currentStartURL == nil {
                currentStartURL = URL(string: SEBStartPage)
            }
        }
        return currentStartURL
    }()
}

@objc public class SEBOSXSessionState: SEBSessionState {
    
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
