//
//  PreferencesController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 18.04.11.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich, 
//  Educational Development and Technology (LET), 
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Controller for the preferences window, populates it with panes

#import <Cocoa/Cocoa.h>
#import "SEBOSXConfigFileController.h"
#import "SEBController.h"
#import "PrefsGeneralViewController.h"
#import "PrefsConfigFileViewController.h"
#import "PrefsAppearanceViewController.h"
#import "PrefsBrowserViewController.h"
#import "PrefsDownUploadsViewController.h"
#import "PrefsExamViewController.h"
#import "PrefsApplicationsViewController.h"
#import "PrefsResourcesViewController.h"
#import "PrefsNetworkViewController.h"
#import "PrefsSecurityViewController.h"

@class SEBController;
@class SEBOSXConfigFileController;
@class PrefsGeneralViewController;
@class PrefsConfigFileViewController;
@class PrefsExamViewController;


@interface PreferencesController : NSObject <NSWindowDelegate> {

    IBOutlet NSMenu *settingsMenu;
    
@private
    NSDictionary *_settingsBeforeEditing;
    NSURL *_configURLBeforeEditing;
    BOOL _userDefaultsPrivateBeforeEditing;
    NSData *_browserExamKeyBeforeEditing;
    BOOL restartSEB;
}

@property BOOL currentConfigPasswordIsHash;
@property BOOL refreshingPreferences;
@property (strong, nonatomic) IBOutlet SEBController *sebController;
@property (strong, nonatomic) SEBOSXConfigFileController *configFileManager;
@property (strong, nonatomic) PrefsGeneralViewController *generalVC;
@property (strong, nonatomic) PrefsConfigFileViewController *configFileVC;
@property (strong, nonatomic) PrefsExamViewController *examVC;

// Write-only properties
@property (nonatomic) NSString *currentConfigPassword;
@property (nonatomic) NSData *currentConfigKeyHash;
// To make the getter unavailable
- (NSString *)currentConfigPassword UNAVAILABLE_ATTRIBUTE;
- (NSData *)currentConfigKeyHash UNAVAILABLE_ATTRIBUTE;

- (void) openSEBPrefsAtURL:(NSURL *)sebFileURL;

- (void) openPreferencesWindow;
- (void) showPreferencesWindow:(NSNotification *)notification;
- (BOOL) preferencesAreOpen;
- (BOOL) usingPrivateDefaults;
- (BOOL) editingSettingsFile;
- (void) initPreferencesWindow;
- (void) releasePreferencesWindow;

- (void) storeCurrentSettings;
- (void) restoreStoredSettings;
- (BOOL) settingsChanged;

- (IBAction) restartSEB:(id)sender;
- (IBAction) quitSEB:(id)sender;

- (IBAction) openSEBPrefs:(id)sender;
- (IBAction) saveSEBPrefs:(id)sender;
- (IBAction) saveSEBPrefsAs:(id)sender;

- (IBAction) revertToLastSaved:(id)sender;
- (IBAction) revertToLocalClientSettings:(id)sender;
- (IBAction) revertToDefaultSettings:(id)sender;

- (IBAction) applyAndRestartSEB:(id)sender;
- (IBAction) editDuplicate:(id)sender;
- (IBAction) configureClient:(id)sender;

//- (int) unsavedSettingsAlertWithText:(NSString *)informativeText;

//- (void) setCurrentConfigPassword:(NSString *)currentConfigPassword;
//- (void) setCurrentConfigPasswordIsHash:(BOOL)currentConfigPasswordIsHash;
//- (void) setCurrentConfigKeyRef:(NSData *)currentConfigKeyHash;

@end
