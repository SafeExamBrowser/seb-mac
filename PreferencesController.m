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
#import "SEBCryptor.h"


@implementation PreferencesController


// Getter methods for write-only properties

- (NSString *)currentConfigPassword {
    [NSException raise:NSInternalInconsistencyException
                format:@"property is write-only"];
    return nil;
}

- (SecKeyRef)currentConfigKeyRef {
    [NSException raise:NSInternalInconsistencyException
                format:@"property is write-only"];
    return nil;
}


- (void)awakeFromNib
{
    self.configFileManager = [[SEBConfigFileManager alloc] init];

    // Add an observer for the notification to display the preferences window again
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showPreferencesWindow:)
                                                 name:@"showPreferencesWindow" object:nil];
    
    // Add an observer for the notification to switch to the Config File prefs pane
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(switchToConfigFilePane:)
                                                 name:@"switchToConfigFilePane" object:nil];
    
    [self initPreferencesWindow];
}


- (void)initPreferencesWindow
{
    // Save current settings
    // Get key/values from private UserDefaults
    //    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    //    NSDictionary *privatePreferences = [preferences dictionaryRepresentationSEB];
    self.refreshingPreferences = NO;
    [[MBPreferencesController sharedController] setSettingsMenu:settingsMenu];
    [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
    [[MBPreferencesController sharedController] openWindow];
    
    // Set the modules for preferences panes
	self.generalVC = [[PrefsGeneralViewController alloc] initWithNibName:@"PreferencesGeneral" bundle:nil];
    self.generalVC.preferencesController = self;
    
	self.configFileVC = [[PrefsConfigFileViewController alloc] initWithNibName:@"PreferencesConfigFile" bundle:nil];
    self.configFileVC.preferencesController = self;
    
    // Set settings credentials in the Config File prefs pane
    [self setConfigFileCredentials];
    
	PrefsAppearanceViewController *appearance = [[PrefsAppearanceViewController alloc] initWithNibName:@"PreferencesAppearance" bundle:nil];
	PrefsBrowserViewController *browser = [[PrefsBrowserViewController alloc] initWithNibName:@"PreferencesBrowser" bundle:nil];
	PrefsDownUploadsViewController *downuploads = [[PrefsDownUploadsViewController alloc] initWithNibName:@"PreferencesDownUploads" bundle:nil];
	PrefsExamViewController *exam = [[PrefsExamViewController alloc] initWithNibName:@"PreferencesExam" bundle:nil];
	PrefsApplicationsViewController *applications = [[PrefsApplicationsViewController alloc] initWithNibName:@"PreferencesApplications" bundle:nil];
	PrefsResourcesViewController *resources = [[PrefsResourcesViewController alloc] initWithNibName:@"PreferencesResources" bundle:nil];
	PrefsNetworkViewController *network = [[PrefsNetworkViewController alloc] initWithNibName:@"PreferencesNetwork" bundle:nil];
	PrefsSecurityViewController *security = [[PrefsSecurityViewController alloc] initWithNibName:@"PreferencesSecurity" bundle:nil];
	[[MBPreferencesController sharedController] setModules:[NSArray arrayWithObjects:self.generalVC, self.configFileVC, appearance, browser, downuploads, exam, applications, resources, network, security, nil]];
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


- (void)showPreferences:(id)sender
{
    // Store current settings (before the probably get edited)
    [self storeCurrentSettings];
    
    [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
	[[MBPreferencesController sharedController] showWindow:self];
}


- (void)reopenPreferencesWindow
{
    // Post a notification that it was requested to re-open the preferences window
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"showPreferencesWindow" object:self];
}


- (void)showPreferencesWindow:(NSNotification *)notification
{
	[[MBPreferencesController sharedController] showWindow:self];
}


- (void)switchToConfigFilePane:(NSNotification *)notification
{
	[[MBPreferencesController sharedController] changeToModuleWithIdentifier:self.configFileVC.identifier];
}


- (void) closePreferencesWindow:(id)sender {
//    // Save passwords in General pane
//	[self.generalVC windowWillClose:nil];
    
    [[MBPreferencesController sharedController].window orderOut:self];
}


- (BOOL)preferencesAreOpen {
    return [[MBPreferencesController sharedController].window isVisible];
}


// Executed when preferences window is about to be closed
- (void)windowWillClose:(NSNotification *)notification
{
    if (!self.refreshingPreferences) {
//        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        // Post a notification that the preferences window closes
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"preferencesClosed" object:self];
    }
    self.refreshingPreferences = NO;
}


// Executed to decide if window should close
- (BOOL)windowShouldClose:(id)sender
{
    // If Preferences are being closed and we're not just refreshing the preferences window
    if (!self.refreshingPreferences) {
//        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        return [self conditionallyClosePreferencesWindowAskToApply:YES];
    } else {
        return YES;
    }
}


// Executed when preferences window should be closed, checking first for unsaved settings,
// if edited settings should be applied – only if passed flag is YES
// with restarting SEB or not – this question only appears if flag is YES (otherwise restart anyways)
// and if "Allow to open preferences window on client" is disabled
// Returns NO if user cancels closing the preferences window
- (BOOL)conditionallyClosePreferencesWindowAskToApply:(BOOL)askToApplySettings
{
    // Save settings in the General pane
    [self.generalVC windowWillClose:nil];
    
    // If private settings are active, check if those current settings have unsaved changes
    if (NSUserDefaults.userDefaultsPrivate && [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
        // There are unsaved changes
        int answer = [self usavedSettingsAlertWithText:
                      NSLocalizedString(@"Edited settings have unsaved changes.", nil)];
        ;
        switch(answer)
        {
            case NSAlertAlternateReturn:
                // Cancel: Don't close preferences
                return NO;
                
            case NSAlertDefaultReturn:
                // Save the current settings data first (also updates the Browser Exam Key)
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    return NO;
                }
                break;
                
            case NSAlertOtherReturn:
                // don't save the config data, just re-generate Browser Exam Key
                [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
                break;
        }
    } else {
        // If local settings active: Just re-generate Browser Exam Key
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    }
    
    // If settings changed:
    if ([self settingsChanged]) {
        BOOL restartSEB = YES;
        if (askToApplySettings) {
            // Ask if edited settings should be applied or previously active settings restored
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Apply Settings?", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"You edited settings. Do you want to apply them (with or without restarting SEB) or continue using previous settings?", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Don't Apply", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Apply & Restart", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Apply", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            int answer = [newAlert runModal];
            switch(answer)
            {
                case NSAlertFirstButtonReturn:
                    // Don't apply edited settings: Restore previous settings
                    // Release preferences window so bindings get synchronized properly with the new loaded values
                    [self releasePreferencesWindow];
                    [self restoreStoredSettings];
                    [self initPreferencesWindow];
                    // Post a notification that the preferences window closes
                    // (as windowWillClose will not be executed anymore because we closed it manually)
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"preferencesClosed" object:self];

                    return YES;
                    
                case NSAlertSecondButtonReturn:
                    // Apply edited settings and restart SEB
                    break;
                    
                case NSAlertThirdButtonReturn:
                    // Apply edited settings without restarting SEB
                    restartSEB = NO;
                    break;
                    
                case NSAlertThirdButtonReturn+1:
                    // Cancel: Don't close preferences
                    return NO;
            }
        }
        
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        // If opening the preferences window isn't allowed in these settings,
        // which is dangerous when being applied, we confirm the user knows what he's doing
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"] == NO) {
            NSAlert *newAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Opening Preferences Disabled", nil)
                                                defaultButton:NSLocalizedString(@"Override", nil)
                                              alternateButton:NSLocalizedString(@"Cancel", nil)
                                                  otherButton:NSLocalizedString(@"Apply Anyways", nil)
                                    informativeTextWithFormat:NSLocalizedString(@"These new settings have the option \"Allow to open preferences window on client\" disabled. If you apply them, you won't be able to open preferences anymore. Are you sure you want this? Otherwise you can override the option for this session.", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            int answer = [newAlert runModal];
            switch(answer)
            {
                case NSAlertAlternateReturn:
                    // Cancel: Don't apply new settings
                    return NO;
                    
                case NSAlertDefaultReturn:
                    // Apply edited allow prefs setting while overriding disabling the preferences window for this session
                    // Internal key already is YES (as we are inside the preferences window...)
                    [preferences setSecureBool:NO forKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"];
                    
                case NSAlertOtherReturn:
                    // Apply edited allow prefs settings without overriding:
                    // we need to set the .seb key and the internal key forbidding opening preferences
                    [preferences setSecureBool:NO forKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"];
                    [preferences setSecureBool:NO forKey:@"org_safeexambrowser_enablePreferencesWindow"];
                    break;
            }
        }
        if (restartSEB) {
            // Post a notification that it was requested to restart SEB with changed settings
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"requestRestartNotification" object:self];
        }
    }
    return YES;
}


//- (BOOL)windowShouldClose:(id)sender
//{
//    return YES;
//}

- (void)releasePreferencesWindow
{
//    self.SEBConfigVC.preferencesController = nil;
//    self.SEBConfigVC = nil;
    self.refreshingPreferences = YES;
    [[MBPreferencesController sharedController] unloadNibs];
}


- (void) setConfigFileCredentials
{
    [self.configFileVC setSettingsPassword:_currentConfigPassword isHash:_currentConfigPasswordIsHash];
    [self.configFileVC setCurrentConfigFileKeyRef:_currentConfigKeyRef];
}


// Stores current settings in memory (before editing them)
- (void) storeCurrentSettings
{
    // Store key/values from local or private UserDefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    _settingsBeforeEditing = [preferences dictionaryRepresentationSEB];
    // Store current flag for private/local client settings
    _userDefaultsPrivateBeforeEditing = NSUserDefaults.userDefaultsPrivate;
    // Store current config URL
    _configURLBeforeEditing = [[MyGlobals sharedMyGlobals] currentConfigURL];
    // Store current Browser Exam Key
    _browserExamKeyBeforeEditing = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
}


// Restores settings which were stored in memory before editing
- (void) restoreStoredSettings
{
    // If config mode changed (private/local client settings), then switch to the mode active before
    if (_userDefaultsPrivateBeforeEditing != NSUserDefaults.userDefaultsPrivate) {
        [NSUserDefaults setUserDefaultsPrivate:_userDefaultsPrivateBeforeEditing];
    }
    // Store all .seb (only the ones with prefix "org_safeexambrowser_SEB_"!) settings from before editing back into UserDefaults
    [self.configFileManager storeIntoUserDefaults:_settingsBeforeEditing];
    // Store exam key before editing into UserDefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureObject:_browserExamKeyBeforeEditing forKey:@"org_safeexambrowser_currentData"];

    // Set the original settings title in the preferences window
    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:_configURLBeforeEditing];
}


// Check if settings have changed
- (BOOL) settingsChanged
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    return ![_browserExamKeyBeforeEditing isEqualToData:[preferences secureObjectForKey:@"org_safeexambrowser_currentData"]];
}

// Check if passwords are confirmed
- (BOOL) arePasswordsUnconfirmed
{
    BOOL passwordIsUnconfirmed = NO;
    
    NSString *unconfirmedPassword;
    if (self.generalVC.compareAdminPasswords) {
        unconfirmedPassword = NSLocalizedString(@"administrator", nil);
        [self alertForUnconfirmedPassword:unconfirmedPassword];
        passwordIsUnconfirmed = YES;
    }
    
    if (self.generalVC.compareQuitPasswords) {
        unconfirmedPassword = NSLocalizedString(@"quit", nil);
        [self alertForUnconfirmedPassword:unconfirmedPassword];
        passwordIsUnconfirmed = YES;
    }
    
    if (self.configFileVC.compareSettingsPasswords) {
        unconfirmedPassword = NSLocalizedString(@"settings", nil);
        [self alertForUnconfirmedPassword:unconfirmedPassword];
        passwordIsUnconfirmed = YES;
    }
    
    return passwordIsUnconfirmed;
}

// Show alert that the password with passed name string isn't confirmed
- (void) alertForUnconfirmedPassword:(NSString *)passwordName
{
    NSRunAlertPanel(NSLocalizedString(@"Unconfirmed Password", nil),
                    @"%@",
                    NSLocalizedString(@"OK", nil), nil, nil,
                    [NSString stringWithFormat:NSLocalizedString(@"Please confirm the %@ password first.", nil), passwordName]);
}


#pragma mark -
#pragma mark IBActions: Methods for quitting, restarting SEB,
#pragma mark opening, saving, reverting and using edited settings

// Save preferences and restart SEB with the new settings
- (IBAction) restartSEB:(id)sender {

    self.refreshingPreferences = YES;  //prevents that new page is reloaded before restarting
    // Save passwords in General pane
	[self.generalVC windowWillClose:nil];

    // If private settings are active, check if those current settings have unsaved changes
    if (NSUserDefaults.userDefaultsPrivate && [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
        // There are unsaved changes
        int answer = [self usavedSettingsAlert];
        switch(answer)
        {
            case NSAlertAlternateReturn:
                // Cancel: Don't restart
                return;
                
            case NSAlertDefaultReturn:
                // Save the current settings data first
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    return;
                }
                break;
                
            case NSAlertOtherReturn:
                // don't save the config data
                break;
        }
    }

    // If settings changed:
    if ([self settingsChanged]) {
        // Ask if edited settings should be applied or previously active settings restored
        NSAlert *newAlert = [[NSAlert alloc] init];
        [newAlert setMessageText:NSLocalizedString(@"Apply Edited Settings?", nil)];
        [newAlert setInformativeText:NSLocalizedString(@"You edited settings. Do you want to apply them or continue using previous settings?", nil)];
        [newAlert addButtonWithTitle:NSLocalizedString(@"Don't Apply", nil)];
        [newAlert addButtonWithTitle:NSLocalizedString(@"Apply", nil)];
        [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        int answer = [newAlert runModal];
        switch(answer)
        {
            case NSAlertFirstButtonReturn:
                // Don't apply edited settings: Restore previous settings
                // Release preferences window so bindings get synchronized properly with the new loaded values
                [self releasePreferencesWindow];
                [self restoreStoredSettings];
                [self initPreferencesWindow];
                // Apply restored settings and restart SEB
                break;
                
            case NSAlertSecondButtonReturn:
                // Apply edited settings and restart SEB
                break;
                
            case NSAlertThirdButtonReturn:
                // Cancel: Don't close preferences
                return;
        }
        
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        // If opening the preferences window isn't allowed in these settings,
        // which is dangerous when being applied, we confirm the user knows what he's doing
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"] == NO) {
            NSAlert *newAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Opening Preferences Disabled", nil)
                                                defaultButton:NSLocalizedString(@"Override", nil)
                                              alternateButton:NSLocalizedString(@"Cancel", nil)
                                                  otherButton:NSLocalizedString(@"Apply Anyways", nil)
                                    informativeTextWithFormat:NSLocalizedString(@"These new settings have the option \"Allow to open preferences window on client\" disabled. If you apply them, you won't be able to open preferences anymore. Are you sure you want this? Otherwise you can override the option.", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            int answer = [newAlert runModal];
            switch(answer)
            {
                case NSAlertAlternateReturn:
                    // Cancel: Don't apply new settings
                    return;
                    
                case NSAlertDefaultReturn:
                    // Apply edited settings while overriding disabling the preferences window
                    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"];
                    
                case NSAlertOtherReturn:
                    // Apply edited settings without overriding
                    break;
            }
        }
    }
    [self closePreferencesWindow:sender];
    // Post a notification that the preferences window closes
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"preferencesClosed" object:self];

    // Post a notification that it was requested to restart SEB with changed settings
	[[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestRestartNotification" object:self];
    
}


// Save preferences and quit SEB
- (IBAction) quitSEB:(id)sender {

    self.refreshingPreferences = YES;  //prevents that new page is reloaded before quitting
    // Save passwords in General pane
	[self.generalVC windowWillClose:nil];

    // If private settings are active, check if those current settings have unsaved changes
    if (NSUserDefaults.userDefaultsPrivate && [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
        // There are unsaved changes
        int answer = [self usavedSettingsAlert];
        switch(answer)
        {
            case NSAlertAlternateReturn:
                // Cancel: Don't quit
                return;
                
            case NSAlertDefaultReturn:
                // Save the current settings data first
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    return;
                }
                break;
                
            case NSAlertOtherReturn:
                // don't save the config data
                break;
        }
    } else {
        
        // Local client settings are active
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        // If opening the preferences window isn't allowed in these settings,
        // which is dangerous when being applied, we confirm the user knows what he's doing
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"] == NO) {
            NSAlert *newAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Opening Preferences Disabled", nil)
                                                defaultButton:NSLocalizedString(@"Override", nil)
                                              alternateButton:NSLocalizedString(@"Cancel", nil)
                                                  otherButton:NSLocalizedString(@"Apply Anyways", nil)
                                    informativeTextWithFormat:NSLocalizedString(@"Local client settings have the option \"Allow to open preferences window on client\" disabled. If you apply them, you won't be able to open preferences anymore when you start SEB next time. Are you sure you want this? Otherwise you can override this option.", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            int answer = [newAlert runModal];
            switch(answer)
            {
                case NSAlertAlternateReturn:
                    // Cancel: Don't apply new settings
                    return;
                    
                case NSAlertDefaultReturn:
                    // Apply edited settings while overriding disabling the preferences window
                    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"];
                    
                case NSAlertOtherReturn:
                    // Apply edited settings without overriding
                    break;
            }
        }
    }
    [self closePreferencesWindow:sender];

	[[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestQuitNotification" object:self];
}


- (IBAction) openSEBPrefs:(id)sender {
    // If private settings are active, check if those current settings have unsaved changes
    if (NSUserDefaults.userDefaultsPrivate && [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
        // There are unsaved changes
        int answer = [self usavedSettingsAlert];
        switch(answer)
        {
            case NSAlertAlternateReturn:
                // Cancel: Don't open new settings
                return;
                
            case NSAlertDefaultReturn:
                // Save the current settings data first
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    return;
                }
                break;
                
            case NSAlertOtherReturn:
                // don't save the config data
                break;
        }
    }
    
    // Set the default name for the file and show the panel.
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    //[panel setNameFieldStringValue:newName];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"seb"]];
    [panel beginSheetModalForWindow:[MBPreferencesController sharedController].window
                  completionHandler:^(NSInteger result){
                      if (result == NSFileHandlingPanelOKButton)
                      {
                          NSURL *sebFileURL = [panel URL];
#ifdef DEBUG
                          NSLog(@"Loading .seb settings file with file URL %@", sebFileURL);
#endif
                          NSError *error = nil;
                          NSData *sebData = [NSData dataWithContentsOfURL:sebFileURL options:nil error:&error];
                          
                          if (error) {
                              // Error when reading configuration data
                              [NSApp presentError:error];
                          } else {
                              // Decrypt and store the .seb config file
                              if ([self.configFileManager storeDecryptedSEBSettings:sebData forEditing:YES]) {
                                  // if successfull save the path to the file for possible editing in the preferences window
                                  [[MyGlobals sharedMyGlobals] setCurrentConfigURL:sebFileURL];
                                  
                                  [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
                                  [self reopenPreferencesWindow];
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
    [self savePrefsAs:saveAs fileURLUpdate:YES];
}


// Method which encrypts and saves current preferences to an encrypted .seb file
// with parameter indicating if the saved settings file URL should be updated
- (BOOL) savePrefsAs:(BOOL)saveAs fileURLUpdate:(BOOL)fileURLUpdate
{
    // Check if passwords are confirmed
    if ([self arePasswordsUnconfirmed]) {
        return NO;
    }
   
    // Get selected config purpose
    sebConfigPurposes configPurpose = [self.configFileVC getSelectedConfigPurpose];
    NSURL *currentConfigFileURL;
    
    /// Check if local client or private settings (UserDefauls) are active
    ///
    if (!NSUserDefaults.userDefaultsPrivate) {
        
        /// Local Client settings are active
        
        // Update the Browser Exam Key without re-generating its salt
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
        
        // Preset "SebClientSettings.seb" as default file name
        currentConfigFileURL = [NSURL URLWithString:@"SebClientSettings.seb"];
    } else {
        
        /// Private settings are active
        
        // Update the Browser Exam Key with a new salt
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:YES];
        
        // Get the current filename
        currentConfigFileURL = [[MyGlobals sharedMyGlobals] currentConfigURL];
    }
    // Read SEB settings from UserDefaults and encrypt them using the provided security credentials
    NSData *encryptedSebData = [self.configFileVC encryptSEBSettingsWithSelectedCredentials];
    
    // If SEB settings were actually read and encrypted we save them
    if (encryptedSebData) {
        if (!saveAs && [currentConfigFileURL isFileURL]) {
            // "Save": Rewrite the file openend before
            NSError *error;
            if (![encryptedSebData writeToURL:currentConfigFileURL options:NSDataWritingAtomic error:&error]) {
                // If the prefs file couldn't be written to app bundle
                NSRunAlertPanel(NSLocalizedString(@"Writing Settings Failed", nil),
                                NSLocalizedString(@"Make sure you have write permissions in the chosen directory", nil),
                                NSLocalizedString(@"OK", nil), nil, nil);
            } else if (fileURLUpdate) {
                [[MyGlobals sharedMyGlobals] setCurrentConfigURL:currentConfigFileURL];
                [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
                [[MBPreferencesController sharedController] setPreferencesWindowTitle];
            }
            
        } else {
            // "Save As": Set the default name and if there is an existing path for the file and show the panel.
            NSSavePanel *panel = [NSSavePanel savePanel];
            NSURL *directory = currentConfigFileURL.URLByDeletingLastPathComponent;
            NSString *directoryString = directory.relativePath;
            if ([directoryString isEqualToString:@"."]) {
                NSFileManager *fileManager = [NSFileManager new];
                directory = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
            }
            [panel setDirectoryURL:directory];
            [panel setNameFieldStringValue:currentConfigFileURL.lastPathComponent];
            [panel setAllowedFileTypes:[NSArray arrayWithObject:@"seb"]];
            [panel beginSheetModalForWindow:[MBPreferencesController sharedController].window
                          completionHandler:^(NSInteger result){
                              if (result == NSFileHandlingPanelOKButton)
                              {
                                  NSURL *prefsFileURL = [panel URL];
                                  NSError *error;
                                  // Write the contents in the new format.
                                  if (![encryptedSebData writeToURL:prefsFileURL options:NSDataWritingAtomic error:&error]) {
                                      //if (![filteredPrefsDict writeToURL:prefsFileURL atomically:YES]) {
                                      // If the prefs file couldn't be written to app bundle
                                      NSRunAlertPanel(NSLocalizedString(@"Writing Settings Failed", nil),
                                                      NSLocalizedString(@"Make sure you have write permissions in the chosen directory", nil),
                                                      NSLocalizedString(@"OK", nil), nil, nil);
                                  } else {
                                      // Prefs got successfully written to file
                                      // If "Save As" or the last file didn't had a full path (wasn't stored on drive):
                                      // Store the new path as the current config file path
                                      if (fileURLUpdate && (saveAs || ![currentConfigFileURL isFileURL])) {
                                          [[MyGlobals sharedMyGlobals] setCurrentConfigURL:panel.URL];
                                          [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
                                      }
                                      if (fileURLUpdate) {
                                          [[MBPreferencesController sharedController] setPreferencesWindowTitle];
                                          NSString *settingsSavedMessage = configPurpose ? NSLocalizedString(@"Settings have been saved, use this file to reconfigure local settings of a SEB client.", nil) : NSLocalizedString(@"Settings have been saved, use this file to start the exam with SEB.", nil);
                                          NSRunAlertPanel(NSLocalizedString(@"Writing Settings Succeeded", nil), @"%@", NSLocalizedString(@"OK", nil), nil, nil,settingsSavedMessage);
                                      }
                                  }
                              }
                          }];
        }
    }
    return YES;
}


// Action reverting preferences to default settings
- (IBAction) revertToDefaultSettings:(id)sender
{
    // Check if current settings have unsaved changes
    if ([[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
        // There are unsaved changes
        int answer = [self usavedSettingsAlert];
        switch(answer)
        {
            case NSAlertAlternateReturn:
                // Cancel: Don't revert to default settings
                return;
                
            case NSAlertDefaultReturn:
                // Save the current settings data first
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    return;
                }
                // If local client settings are active
                if (!NSUserDefaults.userDefaultsPrivate) {
                    // Reset the last saved file name
                    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
                    [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
                    [[MBPreferencesController sharedController] setPreferencesWindowTitle];
                }
                break;
                
            case NSAlertOtherReturn:
                // don't save the config data
                break;
        }
    }
    
    // Reset the config file password
    _currentConfigPassword = nil;
    _currentConfigPasswordIsHash = NO;
    // Reset the config file encrypting identity (key) reference
    _currentConfigKeyRef = nil;
    // Reset the settings password and confirm password fields and the identity popup menu
    [self.configFileVC resetSettingsPasswordFields];
    // Reset the settings identity popup menu
    [self.configFileVC resetSettingsIdentity];
    
    // If using private defaults
    if (NSUserDefaults.userDefaultsPrivate) {
        // Release preferences window so bindings get synchronized properly with the new loaded values
        [self releasePreferencesWindow];
    }
    
    // Get default SEB settings
//    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    NSDictionary *defaultSettings = [preferences sebDefaultSettings];
    NSDictionary *emptySettings = [NSDictionary dictionary];
    
    // Write values from .seb config file to the local preferences (shared UserDefaults)
    [self.configFileManager storeIntoUserDefaults:emptySettings];
    
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:YES];
    
    // If using private defaults
    if (NSUserDefaults.userDefaultsPrivate) {
        // Re-initialize and open preferences window
        [self initPreferencesWindow];
        [self reopenPreferencesWindow];
    }
}


// Action reverting preferences to local client settings
- (IBAction) revertToLocalClientSettings:(id)sender
{
    // Check if current settings have unsaved changes
    if ([[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
        // There are unsaved changes
        int answer = [self usavedSettingsAlert];
        switch(answer)
        {
            case NSAlertAlternateReturn:
                // Cancel: Don't revert to local client settings
                return;
                
            case NSAlertDefaultReturn:
                // Save the current settings data first
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    return;
                }
                break;
                
            case NSAlertOtherReturn:
                // don't save the config data
                break;
        }
    }

    // Release preferences window so buttons get enabled properly for the local client settings mode
    [self releasePreferencesWindow];
    
    //switch to system's UserDefaults
    [NSUserDefaults setUserDefaultsPrivate:NO];
    
    // Get key/values from local shared client UserDefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *localClientPreferences = [preferences dictionaryRepresentationSEB];
    
    // Reset the config file password
    _currentConfigPassword = nil;
    _currentConfigPasswordIsHash = NO;
    // Reset the config file encrypting identity (key) reference
    _currentConfigKeyRef = nil;
    
    // Write values from local to private preferences
    [self.configFileManager storeIntoUserDefaults:localClientPreferences];
    
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    
    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
    
    [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
    [[MBPreferencesController sharedController] setPreferencesWindowTitle];
    
    // Re-initialize and open preferences window
    [self initPreferencesWindow];
	[self reopenPreferencesWindow];
}


// Action reverting preferences to the last saved or opend file
- (IBAction) revertToLastSaved:(id)sender
{
    // Check if current settings have unsaved changes
    if ([[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
        // There are unsaved changes
        int answer = [self usavedSettingsAlert];
        switch(answer)
        {
            case NSAlertAlternateReturn:
                // Cancel: Don't create a duplicate
                return;
                
            case NSAlertDefaultReturn:
                // Save the current settings data first
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    return;
                }
                // If local client settings are active
                if (!NSUserDefaults.userDefaultsPrivate) {
                    // Reset the last saved file name
                    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
                    [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
                    [[MBPreferencesController sharedController] setPreferencesWindowTitle];
                }
                break;
                
            case NSAlertOtherReturn:
                // don't save the config data
                break;
        }
    }
    
    // If using private user defaults
    if (NSUserDefaults.userDefaultsPrivate) {
#ifdef DEBUG
        NSLog(@"Reverting private settings to last saved or opened .seb file");
#endif
        NSError *error = nil;
        NSData *sebData = [NSData dataWithContentsOfURL:[[MyGlobals sharedMyGlobals] currentConfigURL] options:nil error:&error];
        
        if (error) {
            // Error when reading configuration data
            [NSApp presentError:error];
        } else {
            // Pass saved credentials from the last loaded file to the Config File Manager
            self.configFileManager.currentConfigPassword = _currentConfigPassword;
            self.configFileManager.currentConfigPasswordIsHash = _currentConfigPasswordIsHash;
            self.configFileManager.currentConfigKeyRef = _currentConfigKeyRef;
            
            // Decrypt and store the .seb config file
            if ([self.configFileManager storeDecryptedSEBSettings:sebData forEditing:YES]) {
                
                [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
                [self reopenPreferencesWindow];
                
                //[self requestedRestart:nil];
            }
        }
    } else {
        // If using local client settings
#ifdef DEBUG
        NSLog(@"Reverting local client settings to settings before editing");
#endif
        [self.configFileManager storeIntoUserDefaults:_settingsBeforeEditing];
    }
}


// Action duplicating current preferences for editing
- (IBAction) editDuplicate:(id)sender
{
   /// Using local or private defaults?
    if (NSUserDefaults.userDefaultsPrivate) {
        
        /// If using private defaults
        
        // Check if current settings have unsaved changes
        if ([[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
            // There are unsaved changes
            int answer = [self usavedSettingsAlert];
            switch(answer)
            {
                case NSAlertAlternateReturn:
                    // Cancel: Don't create a duplicate
                    return;
                    
                case NSAlertDefaultReturn:
                    // Save the current settings data first
                    if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                        return;
                    }
                    break;
                    
                case NSAlertOtherReturn:
                    // don't save the config data
                    break;
            }
        }
        
        // Release preferences window so bindings get synchronized properly with the new loaded values
        [self releasePreferencesWindow];
        
        // Add string " copy" (or " n+1" if the filename already ends with " copy" or " copy n")
        // to the config name filename
        // Get the current config file full path
        NSURL *currentConfigFilePath = [[MyGlobals sharedMyGlobals] currentConfigURL];
        // Get the filename without extension
        NSString *filename = currentConfigFilePath.lastPathComponent.stringByDeletingPathExtension;
        // Get the extension (should be .seb)
        NSString *extension = currentConfigFilePath.pathExtension;
        if (filename.length == 0) {
            filename = NSLocalizedString(@"untitled", @"untitled filename");
            extension = @".seb";
        } else {
            NSRange copyStringRange = [filename rangeOfString:NSLocalizedString(@" copy", @"word indicating the duplicate of a file, same as in Finder ' copy'") options:NSBackwardsSearch];
            if (copyStringRange.location == NSNotFound) {
                filename = [filename stringByAppendingString:NSLocalizedString(@" copy", nil)];
            } else {
                NSString *copyNumberString = [filename substringFromIndex:copyStringRange.location+copyStringRange.length];
                if (copyNumberString.length == 0) {
                    filename = [filename stringByAppendingString:NSLocalizedString(@" 1", nil)];
                } else {
                    NSInteger copyNumber = [[copyNumberString substringFromIndex:1] integerValue];
                    if (copyNumber == 0) {
                        filename = [filename stringByAppendingString:NSLocalizedString(@" copy", nil)];
                    } else {
                        filename = [[filename substringToIndex:copyStringRange.location+copyStringRange.length+1] stringByAppendingString:[NSString stringWithFormat:@"%ld", copyNumber+1]];
                    }
                }
            }
        }
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:[[[currentConfigFilePath URLByDeletingLastPathComponent] URLByAppendingPathComponent:filename] URLByAppendingPathExtension:extension]];
    } else {
        
        /// If using local defaults
        
        // Release preferences window so bindings get synchronized properly with the new loaded values
        [self releasePreferencesWindow];
        
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:[NSURL URLWithString:@"SebClientSettings.seb"]];
        
        // Get key/values from local shared client UserDefaults
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSDictionary *localClientPreferences = [preferences dictionaryRepresentationSEB];
        
        // Switch to private UserDefaults (saved non-persistantly in memory instead in ~/Library/Preferences)
        NSMutableDictionary *privatePreferences = [NSUserDefaults privateUserDefaults]; //the mutable dictionary has to be created here, otherwise the preferences values will not be saved!
        [NSUserDefaults setUserDefaultsPrivate:YES];
        
        [self.configFileManager storeIntoUserDefaults:localClientPreferences];
        
#ifdef DEBUG
        NSLog(@"Private preferences set: %@", privatePreferences);
#endif
        
    }
    
    // Set the new settings title in the preferences window
    [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
    [[MBPreferencesController sharedController] setPreferencesWindowTitle];

    // Re-initialize and open preferences window
    [self initPreferencesWindow];
	[self reopenPreferencesWindow];
}


// Action configuring client with currently edited preferences
- (IBAction) configureClient:(id)sender
{
    // Get key/values from private UserDefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *privatePreferences = [preferences dictionaryRepresentationSEB];
    
    // Release preferences window so buttons get enabled properly for the local client settings mode
    [self releasePreferencesWindow];
    
    //switch to system's UserDefaults
    [NSUserDefaults setUserDefaultsPrivate:NO];
    
    // Write values from .seb config file to the local preferences (shared UserDefaults)
    [self.configFileManager storeIntoUserDefaults:privatePreferences];
    
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    
    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
    
    [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
    [[MBPreferencesController sharedController] setPreferencesWindowTitle];

    // Re-initialize and open preferences window
    [self initPreferencesWindow];
	[self reopenPreferencesWindow];
}


// Action applying currently edited preferences, closing preferences window and restarting SEB
- (IBAction) applyAndRestartSEB:(id)sender
{
    // Close preferences window (if user doesn't cancel it) but without asking to apply settings
    if ([self conditionallyClosePreferencesWindowAskToApply:NO]) {
        [[MBPreferencesController sharedController].window orderOut:self];
        // Post a notification that it was requested to restart SEB with changed settings
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestRestartNotification" object:self];
    }
}


- (int) usavedSettingsAlert
{
    return [self usavedSettingsAlertWithText:
            NSLocalizedString(@"Current settings have unsaved changes. If you don't save those first, you will loose them.", nil)];
}

- (int) usavedSettingsAlertWithText:(NSString *)informativeText
{
    NSAlert *newAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Unsaved Changes", nil)
                                        defaultButton:NSLocalizedString(@"Save Changes", nil)
                                      alternateButton:NSLocalizedString(@"Cancel", nil)
                                          otherButton:NSLocalizedString(@"Don't Save", nil)
                            informativeTextWithFormat:@"%@", informativeText];
    [newAlert setAlertStyle:NSWarningAlertStyle];
    return [newAlert runModal];
}

@end
