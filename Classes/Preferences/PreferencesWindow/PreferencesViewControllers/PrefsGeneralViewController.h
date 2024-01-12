//
//  PrefsGeneralViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 18.04.11.
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

// Preferences General Pane
// Settings for passwords to enter Preferences and quit SEB
// Buttons to quit and restart SEB, show About panel and help

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"
#import <CommonCrypto/CommonDigest.h>
#import "PreferencesController.h"
#import "SEBKeychainManager.h"

@class PreferencesController;

@interface PrefsGeneralViewController : NSViewController <MBPreferencesModule, NSWindowDelegate> {

    IBOutlet NSTextField *startURL;
    IBOutlet NSTextField *sebServerURL;

	NSMutableString *adminPassword;
	NSMutableString *confirmAdminPassword;
    BOOL adminPasswordIsHash;
    IBOutlet __weak NSSecureTextField *adminPasswordField;
    IBOutlet __weak NSSecureTextField *confirmAdminPasswordField;

    NSMutableString *quitPassword;
    NSMutableString *confirmQuitPassword;
    BOOL quitPasswordIsHash;
    IBOutlet __weak NSSecureTextField *quitPasswordField;
    IBOutlet __weak NSSecureTextField *confirmQuitPasswordField;

	IBOutlet __weak NSButton *prefsQuitSEB;
    IBOutlet __weak NSButton *pasteSavedStringFromPasteboardButton;
    IBOutlet __weak NSButton *pasteSavedStringFromPasteboardToServerURLButton;

	IBOutlet __weak NSObjectController *controller;
	MyGlobals *myGlobals;
    
    @private
    BOOL _wasLoaded;
}

@property (weak, nonatomic) PreferencesController *preferencesController;
@property (strong, nonatomic) SEBKeychainManager *keychainManager;

- (NSString *)identifier;
- (NSImage *)image;

- (void)windowWillClose:(NSNotification *)notification;

- (NSString*) compareAdminPasswords;
- (NSString*) compareQuitPasswords;

- (IBAction) restartSEB:(id)sender;
- (IBAction) quitSEB:(id)sender;
- (IBAction) aboutSEB:(id)sender;
- (IBAction) showHelp:(id)sender;

@end
