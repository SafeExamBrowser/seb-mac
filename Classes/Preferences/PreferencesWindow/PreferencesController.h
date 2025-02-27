//
//  PreferencesController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 18.04.11.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, 
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

// Controller for the preferences window, populates it with panes

#import <Cocoa/Cocoa.h>
#import "SEBOSXConfigFileController.h"

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
#import "SEBEncapsulatedSettings.h"
#import "SEBBrowserController.h"

@class SEBController;
@class SEBOSXConfigFileController;
@class PrefsGeneralViewController;
@class PrefsConfigFileViewController;
@class PrefsAppearanceViewController;
@class PrefsBrowserViewController;
@class PrefsExamViewController;
@class PrefsNetworkViewController;
@class SEBBrowserController;


@interface NSViewController (SEBNSViewController)

- (NSScrollView *) scrollView;

@end


@interface PreferencesController : NSObject <NSWindowDelegate, NSOpenSavePanelDelegate> {

    IBOutlet NSMenu *settingsMenu;
    
@private
    SEBEncapsulatedSettings *settingsBeforeEditing;
    BOOL restartSEB;
    NSURL *currentSEBFileURL;
    BOOL urlFilterLearningModeInitialState;
}

@property BOOL currentConfigPasswordIsHash;
@property BOOL refreshingPreferences;
@property BOOL certOSWarningDisplayed;
@property (readonly) BOOL canSavePlainText;
@property (weak, nonatomic) IBOutlet SEBController *sebController;
@property (weak, nonatomic) NSWindow *preferencesWindow;
@property (strong, nonatomic) SEBOSXConfigFileController *configFileController;
@property (weak, nonatomic) SEBBrowserController *browserController;
@property (strong, nonatomic) PrefsGeneralViewController *generalVC;
@property (strong, nonatomic) PrefsConfigFileViewController *configFileVC;
@property (strong, nonatomic) PrefsExamViewController *examVC;
@property (strong, nonatomic) PrefsNetworkViewController *networkVC;

// Write-only properties
@property (nonatomic) NSString *currentConfigPassword;
@property (nonatomic) NSData *currentConfigFileKeyHash;
// To make the getter unavailable
- (NSString *)currentConfigPassword UNAVAILABLE_ATTRIBUTE;
- (NSData *)currentConfigFileKeyHash UNAVAILABLE_ATTRIBUTE;

- (void) openSEBPrefsAtURL:(NSURL *)sebFileURL;

- (void) openPreferencesWindow;
- (void) showPreferencesWindow:(NSNotification *)notification;
- (BOOL) preferencesAreOpen;
- (BOOL) usingPrivateDefaults;
- (BOOL) editingSettingsFile;
- (void) initPreferencesWindow;
- (void) releasePreferencesWindow;
- (void) reopenPreferencesWindow;

- (void) storeCurrentSettings;
- (void) restoreStoredSettings;
- (BOOL) settingsChanged;

- (NSData *)encodeConfigData:(NSData *)encryptedConfigData
               forPurpose:(sebConfigPurposes)configPurpose
                   format:(ShareConfigFormat)shareConfigFormat
             uncompressed:(BOOL)uncompressed
           removeDefaults:(BOOL)removeDefaults;

- (IBAction) restartSEB:(id)sender;
- (IBAction) quitSEB:(id)sender;

- (IBAction) openSEBPrefs:(id)sender;
- (IBAction) saveSEBPrefs:(id)sender;
- (IBAction) saveSEBPrefsAs:(id)sender;

- (IBAction) revertToLastSaved:(id)sender;
- (IBAction) revertToLocalClientSettings:(id)sender;
- (IBAction) revertToDefaultSettings:(id)sender;

- (IBAction) applyAndRestartSEB:(id)sender;
- (IBAction) createExamSettings:(id)sender;
- (IBAction) configureClient:(id)sender;

//- (int) unsavedSettingsAlertWithText:(NSString *)informativeText;

//- (void) setCurrentConfigPassword:(NSString *)currentConfigPassword;
//- (void) setCurrentConfigPasswordIsHash:(BOOL)currentConfigPasswordIsHash;
//- (void) setCurrentConfigKeyRef:(SecKeyRef)currentConfigKeyRef;

@end
