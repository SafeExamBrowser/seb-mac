//
//  PrefsSecurityViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 15.02.13.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel, 
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

// Preferences Security Pane

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"

@interface PrefsSecurityViewController : NSViewController <MBPreferencesModule> {

    __weak IBOutlet NSButton *allowScreenCaptureButton;
    __weak IBOutlet NSButton *allowWindowCaptureButton;
    __weak IBOutlet NSButton *blockScreenShotsButton;
    __weak IBOutlet NSButton *allowScreenSharingButton;
    __weak IBOutlet NSButton *screenSharingMacEnforceButton;
    __weak IBOutlet NSButton *enableAppSwitcherButton;
    __weak IBOutlet NSButton *allowSiriButton;
    __weak IBOutlet NSButton *allowDictationButton;
    __weak IBOutlet NSPopUpButton *chooseLogLevelControl;
    __weak IBOutlet NSPopUpButton *chooseLogDirectoryControl;
    __weak IBOutlet NSButton *selectStandardDirectoryButton;
    __weak IBOutlet NSButton *aacDnsPrePinningButton;
    __weak IBOutlet NSButton *allowUserAppFolderInstallButton;
    __weak IBOutlet NSMenuItem *logDirectory;
    __weak IBOutlet NSMatrix *kioskMode;
    __weak IBOutlet NSComboBox *maxNumberDisplays;
    __weak IBOutlet NSButton *allowDisplayMirroringButton;
    __weak IBOutlet NSButton *allowedDisplayBuiltinEnforceButton;
    __weak IBOutlet NSButton *allowedDisplayBuiltinExceptDesktopButton;
    
    __weak IBOutlet NSPopUpButton *minMacOSVersionPopUpButton;
    __weak IBOutlet NSComboBox *minMacOSVersionMajor;
    __weak IBOutlet NSComboBox *minMacOSVersionMinor;
    __weak IBOutlet NSComboBox *minMacOSVersionPatch;

    __weak IBOutlet NSButton *allowiOSScreenCaptureButton;
    __weak IBOutlet NSComboBox *miniOSVersionMajor;
    __weak IBOutlet NSComboBox *miniOSVersionMinor;
    __weak IBOutlet NSComboBox *miniOSVersionPatch;
    __weak IBOutlet NSComboBox *allowediOSBetaVersion;
    
    __weak IBOutlet NSButton *enablePrintScreenButton;
}

- (NSString *)identifier;
- (NSImage *)image;

- (void) setLogDirectory;

- (IBAction) chooseDirectory:(id)sender;
- (IBAction) changedKioskMode:(NSMatrix *)sender;


@end
