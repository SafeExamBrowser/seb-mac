//
//  PreferencesController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 18.04.11.
//  Copyright (c) 2010-2014 Daniel R. Schneider, ETH Zurich, 
//  Educational Development and Technology (LET), 
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
//  (c) 2010-2014 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Controller for the preferences window, populates it with panes

#import "PreferencesController.h"
#import "MBPreferencesController.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "SEBConfigFileManager.h"
#import "SEBCryptor.h"


@implementation PreferencesController


// Getter methods for write-only properties

//- (NSString *)currentConfigPassword {
//    [NSException raise:NSInternalInconsistencyException
//                format:@"property is write-only"];
//    return nil;
//}

- (SecKeyRef)currentConfigKeyRef {
    [NSException raise:NSInternalInconsistencyException
                format:@"property is write-only"];
    return nil;
}


- (void)awakeFromNib
{
    [self initPreferencesWindow];
}


- (void)showPreferences:(id)sender
{
    [[MBPreferencesController sharedController] setSettingsTitle:[[MyGlobals sharedMyGlobals] currentConfigPath]];
	[[MBPreferencesController sharedController] showWindow:sender];
}


- (BOOL)preferencesAreOpen {
    return [[MBPreferencesController sharedController].window isVisible];
}


- (void)windowWillClose:(NSNotification *)notification
{
    [[NSApplication sharedApplication] stopModal];
    // Post a notification that preferences were closed
    if (self.preferencesAreOpen) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"preferencesClosed" object:self];
    }
}


- (void)initPreferencesWindow
{
    // Save current settings
    // Get key/values from private UserDefaults
//    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    NSDictionary *privatePreferences = [preferences dictionaryRepresentationSEB];
    
    [[MBPreferencesController sharedController] setSettingsTitle:[[MyGlobals sharedMyGlobals] currentConfigPath]];
    [[MBPreferencesController sharedController] openWindow];
    // Set the modules for preferences panes
	PrefsGeneralViewController *general = [[PrefsGeneralViewController alloc] initWithNibName:@"PreferencesGeneral" bundle:nil];
	self.SEBConfigVC = [[PrefsSEBConfigViewController alloc] initWithNibName:@"PreferencesSEBConfig" bundle:nil];
    self.SEBConfigVC.preferencesController = self;
    
    // Set settings credentials in the SEB config prefs pane
    [self setConfigFileCredentials];
    
	PrefsAppearanceViewController *appearance = [[PrefsAppearanceViewController alloc] initWithNibName:@"PreferencesAppearance" bundle:nil];
	PrefsBrowserViewController *browser = [[PrefsBrowserViewController alloc] initWithNibName:@"PreferencesBrowser" bundle:nil];
	PrefsDownUploadsViewController *downuploads = [[PrefsDownUploadsViewController alloc] initWithNibName:@"PreferencesDownUploads" bundle:nil];
	PrefsExamViewController *exam = [[PrefsExamViewController alloc] initWithNibName:@"PreferencesExam" bundle:nil];
	PrefsApplicationsViewController *applications = [[PrefsApplicationsViewController alloc] initWithNibName:@"PreferencesApplications" bundle:nil];
	PrefsResourcesViewController *resources = [[PrefsResourcesViewController alloc] initWithNibName:@"PreferencesResources" bundle:nil];
	PrefsNetworkViewController *network = [[PrefsNetworkViewController alloc] initWithNibName:@"PreferencesNetwork" bundle:nil];
	PrefsSecurityViewController *security = [[PrefsSecurityViewController alloc] initWithNibName:@"PreferencesSecurity" bundle:nil];
	[[MBPreferencesController sharedController] setModules:[NSArray arrayWithObjects:general, self.SEBConfigVC, appearance, browser, downuploads, exam, applications, resources, network, security, nil]];
//	[[MBPreferencesController sharedController] setModules:[NSArray arrayWithObjects:general, config, appearance, browser, downuploads, exam, applications, network, security, nil]];
    // Set self as the window delegate to be able to post a notification when preferences window is closing
    // will be overridden when the general pane is displayed (loaded from nib)
    if (![[MBPreferencesController sharedController].window delegate]) {
        // Set delegate only if it's not yet set!
        [[MBPreferencesController sharedController].window setDelegate:self];
#ifdef DEBUG
        NSLog(@"Set PreferencesController as delegate for preferences window");
#endif
    }
}


- (void)releasePreferencesWindow
{
//    self.SEBConfigVC.preferencesController = nil;
//    self.SEBConfigVC = nil;
    [[MBPreferencesController sharedController] unloadNibs];
}


- (void) setConfigFileCredentials
{
    [self.SEBConfigVC setSettingsPassword:_currentConfigPassword isHash:_currentConfigPasswordIsHash];
    [self.SEBConfigVC setCurrentConfigFileKeyRef:_currentConfigKeyRef];
}


- (IBAction) openSEBPrefs:(id)sender {
    // Set the default name for the file and show the panel.
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    //[panel setNameFieldStringValue:newName];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"seb"]];
    [panel beginSheetModalForWindow:[MBPreferencesController sharedController].window
                  completionHandler:^(NSInteger result){
                      if (result == NSFileHandlingPanelOKButton)
                      {
                          NSURL *sebFileURL = [panel URL];
                          
                          // Check if private UserDefauls are switched on already
                          if (NSUserDefaults.userDefaultsPrivate) {
                          }
                          
#ifdef DEBUG
                          NSLog(@"Loading .seb settings file with file URL %@", sebFileURL);
#endif
                          NSError *error = nil;
                          NSData *sebData = [NSData dataWithContentsOfURL:sebFileURL options:nil error:&error];
                          
                          if (error) {
                              // Error when reading configuration data
                              [NSApp presentError:error];
                          } else {
                              SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
                              
                              // Decrypt and store the .seb config file
                              if ([configFileManager storeDecryptedSEBSettings:sebData forEditing:YES]) {
                                  // if successfull save the path to the file for possible editing in the preferences window
                                  [[MyGlobals sharedMyGlobals] setCurrentConfigPath:sebFileURL.absoluteString];
                                  
                                  [[MBPreferencesController sharedController] setSettingsTitle:[[MyGlobals sharedMyGlobals] currentConfigPath]];
                                  [[MBPreferencesController sharedController] showWindow:sender];
                                  
                                  //[self requestedRestart:nil];
                              }
                          }
                      }
                  }];
    
}


// Action saving current preferences to a .seb file choosing the filename
- (IBAction) saveSEBPrefs:(id)sender
{
    [self savePrefsAs:NO];
}


// Action saving current preferences to a .seb file choosing the filename
- (IBAction) saveSEBPrefsAs:(id)sender
{
    [self savePrefsAs:YES];
}


// Method which encrypts and saves current preferences to an encrypted .seb file
- (void) savePrefsAs:(BOOL)saveAs
{
    // Get selected config purpose
    sebConfigPurposes configPurpose = [self.SEBConfigVC getSelectedConfigPurpose];
    
    // Read SEB settings from UserDefaults and encrypt them using the provided security credentials
    NSData *encryptedSebData = [self.SEBConfigVC encryptSEBSettingsWithSelectedCredentials];
    
    // If SEB settings were actually read and encrypted we save them
    if (encryptedSebData) {
        NSURL *currentConfigFileURL;
        // Check if local client settings (UserDefauls) are active
        if (!NSUserDefaults.userDefaultsPrivate) {
            // Preset "SebClientSettings.seb" as default file name
            currentConfigFileURL = [NSURL URLWithString:@"SebClientSettings.seb"];
        } else {
            // Get the current filename
            //            filename = [[MyGlobals sharedMyGlobals] currentConfigPath].lastPathComponent;
            currentConfigFileURL = [NSURL URLWithString:[[MyGlobals sharedMyGlobals] currentConfigPath]];
            //            if ([[MyGlobals sharedMyGlobals] currentConfigPath]) {
            //            }
        }
        if (!saveAs && [currentConfigFileURL isFileURL]) {
            // "Save": Rewrite the file openend before
            if (![encryptedSebData writeToURL:currentConfigFileURL atomically:YES]) {
                // If the prefs file couldn't be written to app bundle
                NSRunAlertPanel(NSLocalizedString(@"Writing Settings Failed", nil),
                                NSLocalizedString(@"Make sure you have write permissions in the chosen directory", nil),
                                NSLocalizedString(@"OK", nil), nil, nil);
            }
            
        } else {
            // "Save As": Set the default name and if there is an existing path for the file and show the panel.
            NSSavePanel *panel = [NSSavePanel savePanel];
            [panel setDirectoryURL:currentConfigFileURL];
            [panel setNameFieldStringValue:currentConfigFileURL.lastPathComponent];
            [panel setAllowedFileTypes:[NSArray arrayWithObject:@"seb"]];
            [panel beginSheetModalForWindow:[MBPreferencesController sharedController].window
                          completionHandler:^(NSInteger result){
                              if (result == NSFileHandlingPanelOKButton)
                              {
                                  NSURL*  prefsFileURL = [panel URL];
                                  // Write the contents in the new format.
                                  if (![encryptedSebData writeToURL:prefsFileURL atomically:YES]) {
                                      //if (![filteredPrefsDict writeToURL:prefsFileURL atomically:YES]) {
                                      // If the prefs file couldn't be written to app bundle
                                      NSRunAlertPanel(NSLocalizedString(@"Writing Settings Failed", nil),
                                                      NSLocalizedString(@"Make sure you have write permissions in the chosen directory", nil),
                                                      NSLocalizedString(@"OK", nil), nil, nil);
                                  } else {
                                      // Prefs got successfully written to file
                                      // If "Save As" or the last file didn't had a full path (wasn't stored on drive):
                                      // Store the new path as the current config file path
                                      if (saveAs || ![currentConfigFileURL isFileURL]) {
                                          [[MyGlobals sharedMyGlobals] setCurrentConfigPath:panel.URL.absoluteString];
                                          [[MBPreferencesController sharedController] setSettingsTitle:[[MyGlobals sharedMyGlobals] currentConfigPath]];
                                          [[MBPreferencesController sharedController] setPreferencesWindowTitle];
                                      }
                                      NSString *settingsSavedMessage = configPurpose ? NSLocalizedString(@"Settings have been saved, use this file to reconfigure local settings of a SEB client.", nil) : NSLocalizedString(@"Settings have been saved, use this file to start the exam with SEB.", nil);
                                      NSRunAlertPanel(NSLocalizedString(@"Writing Settings Succeeded", nil), @"%@", NSLocalizedString(@"OK", nil), nil, nil,settingsSavedMessage);
                                  }
                              }
                          }];
        }
    }
}


// Action reverting preferences to the last saved or opend file
- (IBAction) revertToLastSaved:(id)sender
{
#ifdef DEBUG
    NSLog(@"Reverting settings to last saved or opened .seb file");
#endif
    NSError *error = nil;
    NSData *sebData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[MyGlobals sharedMyGlobals] currentConfigPath]] options:nil error:&error];
    
    if (error) {
        // Error when reading configuration data
        [NSApp presentError:error];
    } else {
        SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
        
        // Decrypt and store the .seb config file
        if ([configFileManager storeDecryptedSEBSettings:sebData forEditing:YES]) {
            
            [[MBPreferencesController sharedController] setSettingsTitle:[[MyGlobals sharedMyGlobals] currentConfigPath]];
            [[MBPreferencesController sharedController] showWindow:sender];
            
            //[self requestedRestart:nil];
        }
    }
}


// Action reverting preferences to local client settings
- (IBAction) revertToLocalClientSettings:(id)sender
{
    
}


// Action reverting preferences to default settings
- (IBAction) revertToDefaultSettings:(id)sender
{
    // Reset the config file password
    _currentConfigPassword = nil;
    _currentConfigPasswordIsHash = NO;
    _currentConfigKeyRef = nil;


    // If using private defaults
    if (NSUserDefaults.userDefaultsPrivate) {
        // Release preferences window so bindings get synchronized properly with the new loaded values
        [self releasePreferencesWindow];
    }
    
    // Get default SEB settings
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaultSettings = [preferences sebDefaultSettings];
    
    // Write values from .seb config file to the local preferences (shared UserDefaults)
    SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
    [configFileManager storeIntoUserDefaults:defaultSettings];
    
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults];
    
    // If using private defaults
    if (NSUserDefaults.userDefaultsPrivate) {
        // Re-initialize and open preferences window
        [self initPreferencesWindow];
        [[MBPreferencesController sharedController] showWindow:sender];
    }
}


// Action duplicating current preferences for editing
- (IBAction) applyAndTest:(id)sender
{
    
}


// Action duplicating current preferences for editing
- (IBAction) editDuplicate:(id)sender
{
    
}


// Action duplicating current preferences for editing
- (IBAction) configureClient:(id)sender
{
    // Get key/values from private UserDefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *privatePreferences = [preferences dictionaryRepresentationSEB];
    
    //switch to system's UserDefaults
    [NSUserDefaults setUserDefaultsPrivate:NO];
    
    // Write values from .seb config file to the local preferences (shared UserDefaults)
    SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
    [configFileManager storeIntoUserDefaults:privatePreferences];
    
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults];
    
    [[MyGlobals sharedMyGlobals] setCurrentConfigPath:NSLocalizedString(@"Local Client Settings", nil)];
    
    [[MBPreferencesController sharedController] setSettingsTitle:[[MyGlobals sharedMyGlobals] currentConfigPath]];
    [[MBPreferencesController sharedController] setPreferencesWindowTitle];
}


@end
