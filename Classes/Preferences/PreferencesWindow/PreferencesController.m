//
//  PreferencesController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 18.04.11.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Controller for the preferences window, populates it with panes

#import "PreferencesController.h"
#import "MBPreferencesController.h"
#import "SEBCryptor.h"


@implementation PreferencesController


#pragma mark -
#pragma mark Property methods, partially used for bindings

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


- (BOOL)preferencesAreOpen {
    return [[MBPreferencesController sharedController].window isVisible];
}


- (BOOL) usingPrivateDefaults {
    return NSUserDefaults.userDefaultsPrivate;
}


#pragma mark -
#pragma mark Methods for initializing, opening, closing, releasing and re-opening preferences window

- (void)awakeFromNib
{
    restartSEB = NO;
    
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
    // Check if running on OS X 10.7
    if (floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_7) {
        // Don't init
        return;
    }
    
    // Save current settings
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
	self.examVC = [[PrefsExamViewController alloc] initWithNibName:@"PreferencesExam" bundle:nil];
	PrefsApplicationsViewController *applications = [[PrefsApplicationsViewController alloc] initWithNibName:@"PreferencesApplications" bundle:nil];
//	PrefsResourcesViewController *resources = [[PrefsResourcesViewController alloc] initWithNibName:@"PreferencesResources" bundle:nil];
	PrefsNetworkViewController *network = [[PrefsNetworkViewController alloc] initWithNibName:@"PreferencesNetwork" bundle:nil];
	PrefsSecurityViewController *security = [[PrefsSecurityViewController alloc] initWithNibName:@"PreferencesSecurity" bundle:nil];
//    [[MBPreferencesController sharedController] setModules:[NSArray arrayWithObjects:self.generalVC, self.configFileVC, appearance, browser, downuploads, self.examVC, applications, resources, network, security, nil]];
    [[MBPreferencesController sharedController] setModules:[NSArray arrayWithObjects:self.generalVC, self.configFileVC, appearance, browser, downuploads, self.examVC, applications, network, security, nil]];
    // Set self as the window delegate to be able to post a notification when preferences window is closing
    // will be overridden when the general pane is displayed (loaded from nib)
    if (![[MBPreferencesController sharedController].window delegate]) {
        // Set delegate only if it's not yet set!
        [[MBPreferencesController sharedController].window setDelegate:self];
    }
}


// Public method called to open the preferences Window
- (void)openPreferencesWindow
{
    // Store current settings (before the probably get edited)
    [self storeCurrentSettings];
    
    [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
	[[MBPreferencesController sharedController] showWindow:self];
}


// Method called to programmatically close the preferences window
- (void) closePreferencesWindow
{
    [[MBPreferencesController sharedController].window orderOut:self];
}


// Releases preferences window so after reopening bindings get synchronized properly with new loaded values
- (void)releasePreferencesWindow
{
    self.refreshingPreferences = YES;
    [[MBPreferencesController sharedController] unloadNibs];
}


// Method called to reopen the closed preferences window programmatically
- (void)reopenPreferencesWindow
{
    // Post a notification that it was requested to re-open the preferences window
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"showPreferencesWindow" object:self];
}


// Reopen the closed preferences window after the according notification
- (void)showPreferencesWindow:(NSNotification *)notification
{
    [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
    [[MBPreferencesController sharedController] setPreferencesWindowTitle];
	[[MBPreferencesController sharedController] showWindow:self];
}


// Switch to the Config File prefs pane after the according notification
- (void)switchToConfigFilePane:(NSNotification *)notification
{
	[[MBPreferencesController sharedController] changeToModuleWithIdentifier:self.configFileVC.identifier];
}


#pragma mark -
#pragma mark NSWindowDelegate methods and helper method for closing preferences window

// Executed to decide if window should close
- (BOOL)windowShouldClose:(id)sender
{
    // If Preferences are being closed and we're not just refreshing the preferences window
    if (!self.refreshingPreferences) {
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        [self.sebController.browserController.mainBrowserWindow makeKeyAndOrderFront:self];
        return [self conditionallyClosePreferencesWindowAskToApply:YES];
    } else {
        return YES;
    }
}


// Executed when preferences window is about to be closed
- (void)windowWillClose:(NSNotification *)notification
{
    if (self.preferencesAreOpen && !self.refreshingPreferences) {
//        self.sebController.browserController.reinforceKioskModeRequested = YES;
        // Post a notification that the preferences window closes
        if (restartSEB) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"preferencesClosedRestartSEB" object:self];
        } else {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"preferencesClosed" object:self];
        }
    }
    self.refreshingPreferences = NO;
}


// Executed when preferences window should be closed, checking first for unsaved settings,
// if edited settings should be applied – only if passed flag is YES
// with restarting SEB or not – this question only appears if flag is YES (otherwise restart anyways)
// and if "Allow to open preferences window on client" is disabled
// Returns NO if user cancels closing the preferences window
- (BOOL)conditionallyClosePreferencesWindowAskToApply:(BOOL)askToApplySettings
{
    restartSEB = NO;
    
    // Save settings in the General pane
    [self.generalVC windowWillClose:[NSNotification notificationWithName:NSWindowWillCloseNotification object:nil]];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *oldBrowserExamKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];

    // If private settings are active, check if those current settings have unsaved changes
    if (NSUserDefaults.userDefaultsPrivate && [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO]) {
        // There are unsaved changes
        SEBUnsavedSettingsAnswer answer = [self unsavedSettingsAlertWithText:
                      NSLocalizedString(@"Edited settings have unsaved changes.", nil)];
        switch(answer)
        {
            case SEBUnsavedSettingsAnswerSave:
            {
                // Save the current settings data first (this also updates the Browser Exam Key)
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    // Saving failed: Abort closing the prefs window, restore old Browser Exam Key
                    [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                    return NO;
                }
                break;
            }
                
            case SEBUnsavedSettingsAnswerCancel:
            {
                // Cancel: Don't close preferences, restore old Browser Exam Key
                [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                return NO;
            }
        }

    } else if (!NSUserDefaults.userDefaultsPrivate) {
        
        // If local settings active: Just re-generate Browser Exam Key
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    }
    
    // If settings changed:
    if ([self settingsChanged]) {
        if (askToApplySettings) {
            // Ask if edited settings should be applied or previously active settings restored
            SEBApplySettingsAnswers answer = [self askToApplySettingsAlert];
            switch(answer)
            {
                case SEBApplySettingsAnswerDontApply:
                {
                    // Post a notification that the preferences window closes
                    // (as windowWillClose will not be executed anymore because we closed it manually)
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"preferencesClosed" object:self];
                    
                    return YES;
                }
                    
                case SEBApplySettingsAnswerCancel:
                {
                    // Cancel: Don't close preferences, restore old Browser Exam Key
                    [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                    return NO;
                }
            }
        }
        
        // If opening the preferences window isn't allowed in these settings,
        // which is dangerous when being applied, we confirm the user knows what he's doing
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"] == NO) {
            SEBDisabledPreferencesAnswer answer = [self alertForDisabledPreferences];
            switch(answer)
            {
                case SEBDisabledPreferencesAnswerOverride:
                {
                    // Apply edited allow prefs setting while overriding disabling the preferences window for this session/resetting it
                    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"];
                    if (NSUserDefaults.userDefaultsPrivate) {
                        // Release preferences window so bindings get synchronized properly with the new loaded values
                        [self releasePreferencesWindow];
                        // Reopen preferences window
                        [self initPreferencesWindow];
                    }
                    // Re-generate Browser Exam Key only when using
                    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
                    
                    break;
                }
                    
                case SEBDisabledPreferencesAnswerCancel:
                {
                    // Cancel: Don't apply new settings, don't close prefs, restore old Browser Exam Key
                    [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                    return NO;
                }
            }
        }
        // We request to restart SEB (in windowWillClose) with changed settings
        restartSEB = YES;
    }
    return YES;
}


#pragma mark -
#pragma mark Helper methods

- (void) setConfigFileCredentials
{
    [self.configFileVC setCurrentConfigFileKeyRef:_currentConfigKeyRef];
    [self.configFileVC setSettingsPassword:_currentConfigPassword isHash:_currentConfigPasswordIsHash];
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


- (void) openSEBPrefsAtURL:(NSURL *)sebFileURL
{
    NSError *error = nil;
    NSData *sebData = [NSData dataWithContentsOfURL:sebFileURL options:nil error:&error];
    
    if (error || !sebData) {
        // Error when reading configuration data
        [NSApp presentError:error];
        DDLogError(@"%s: Reading a settings file with path %@ didn't work, error: %@", __FUNCTION__, sebFileURL.absoluteString, error.description);

    } else {
        if (sebData.length == 0) {
            DDLogError(@"%s: Loaded settings file with path %@ was empty!", __FUNCTION__, sebFileURL.absoluteString);

            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Opening Settings Failed", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"Loaded settings are empty and cannot be used.", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            [newAlert runModal];
            return;
        }
        // Decrypt and store the .seb config file
        if ([self.configFileManager storeDecryptedSEBSettings:sebData forEditing:YES] == storeDecryptedSEBSettingsResultSuccess) {
            // if successfull save the path to the file for possible editing in the preferences window
            [[MyGlobals sharedMyGlobals] setCurrentConfigURL:sebFileURL];
            
            [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
            [self reopenPreferencesWindow];
        }
    }
}


// Return YES if currently opened settings are loaded from a file
- (BOOL) editingSettingsFile
{
    return [[[MyGlobals sharedMyGlobals] currentConfigURL] isFileURL];
}


// Check if passwords are confirmed and save changed passwords in the General pane
- (BOOL) passwordsConfirmedAndSaved
{
    // Check if passwords are confirmed and save them if yes
    if ([self arePasswordsUnconfirmed]) {
        return NO;
    }
    
    // Save settings in the General pane
    [self.generalVC windowWillClose:[NSNotification notificationWithName:NSWindowWillCloseNotification object:nil]];
 
    return YES;
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
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Unconfirmed Password", nil)];
    [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Please confirm the %@ password first.", nil), passwordName]];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [newAlert setAlertStyle:NSInformationalAlertStyle];
    [newAlert runModal];
}


- (SEBDisabledPreferencesAnswer) alertForDisabledPreferences
{
    NSString *informativeText = NSUserDefaults.userDefaultsPrivate
    ? NSLocalizedString(@"These settings have the option 'Allow to open preferences window on client' disabled. Are you sure you want to apply this? Otherwise you can override this option for the current session.", nil)
    : NSLocalizedString(@"Local client settings have the option 'Allow to open preferences window on client' disabled, which will prevent opening the preferences window even when you restart SEB. Are you sure you want to apply this? Otherwise you can reset this option.", nil);
    
    NSString *defaultButtonText = NSUserDefaults.userDefaultsPrivate
    ? NSLocalizedString(@"Override", nil)
    : NSLocalizedString(@"Reset", nil);
    
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Opening Preferences Disabled", nil)];
    [newAlert setInformativeText:informativeText];
    [newAlert addButtonWithTitle:defaultButtonText];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Apply Anyways", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [newAlert setAlertStyle:NSCriticalAlertStyle];
    switch([newAlert runModal])
    {
        case NSAlertFirstButtonReturn:
            return SEBDisabledPreferencesAnswerOverride;
            
        case NSAlertSecondButtonReturn:
            return SEBDisabledPreferencesAnswerApply;
    }
    return SEBDisabledPreferencesAnswerCancel;
}


- (SEBUnsavedSettingsAnswer) unsavedSettingsAlert
{
    return [self unsavedSettingsAlertWithText:
            NSLocalizedString(@"Current settings have unsaved changes. If you don't save those first, you will loose them.", nil)];
}

- (SEBUnsavedSettingsAnswer) unsavedSettingsAlertWithText:(NSString *)informativeText
{
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Unsaved Changes", nil)];
    [newAlert setInformativeText:informativeText];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Save Changes", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Don't Save", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [newAlert setAlertStyle:NSWarningAlertStyle];
    switch([newAlert runModal])
    {
        case NSAlertFirstButtonReturn:
            return SEBUnsavedSettingsAnswerSave;
            
        case NSAlertSecondButtonReturn:
            return SEBUnsavedSettingsAnswerDontSave;
    }
    return SEBUnsavedSettingsAnswerCancel;
}


// Ask if edited settings should be applied or previously active settings restored
- (SEBApplySettingsAnswers) askToApplySettingsAlert
{
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Apply Edited Settings?", nil)];
    if (NSUserDefaults.userDefaultsPrivate) {
        [newAlert setInformativeText:NSLocalizedString(@"You edited settings. Do you want to apply them or continue using previous settings?", nil)];
    } else {
        [newAlert setInformativeText:NSLocalizedString(@"You edited settings. Do you want to apply them or continue using previous settings (current settings will be discarded)?", nil)];
    }
    [newAlert addButtonWithTitle:NSLocalizedString(@"Don't Apply", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Apply", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    int answer = [newAlert runModal];
    switch(answer)
    {
        case NSAlertFirstButtonReturn:
        {
            // Don't apply edited settings: Restore previous settings
            // Release preferences window so bindings get synchronized properly with the new loaded values
            [self releasePreferencesWindow];
            [self restoreStoredSettings];
            [self initPreferencesWindow];
        }
    }
    switch(answer)
    {
        case NSAlertFirstButtonReturn:
            return SEBApplySettingsAnswerDontApply;
            
        case NSAlertSecondButtonReturn:
            return SEBApplySettingsAnswerApply;
    }
    return SEBApplySettingsAnswerCancel;
}


#pragma mark -
#pragma mark IBActions: Methods for quitting, restarting SEB,
#pragma mark opening, saving, reverting and using edited settings

// Save preferences and restart SEB with the new settings
- (IBAction) restartSEB:(id)sender {

    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return;
    }

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *oldBrowserExamKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
    
    BOOL browserExamKeyChanged = [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    
    // If private settings are active, check if those current settings have unsaved changes
    if (NSUserDefaults.userDefaultsPrivate && browserExamKeyChanged) {
        // There are unsaved changes
        SEBUnsavedSettingsAnswer answer = [self unsavedSettingsAlertWithText:
                      NSLocalizedString(@"Edited settings have unsaved changes.", nil)];
        switch(answer)
        {
            case SEBUnsavedSettingsAnswerSave:
            {
                // Save the current settings data first (this also updates the Browser Exam Key)
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    // Saving failed: Abort restarting, restore old Browser Exam Key
                    [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                    return;
                }
                break;
            }
                
            case SEBUnsavedSettingsAnswerCancel:
            {
                // Cancel: Don't restart, restore old Browser Exam Key
                [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                return;
            }
        }
    }

    // If settings changed since before opening preferences:
    if ([self settingsChanged]) {
        // Ask if edited settings should be applied or previously active settings restored
        SEBApplySettingsAnswers answer = [self askToApplySettingsAlert];
        switch(answer)
        {
            case SEBApplySettingsAnswerDontApply:
            {
                // Don't apply edited settings and restart SEB
                break;
            }
                
            case SEBApplySettingsAnswerCancel:
            {
                // Cancel: Don't restart, restore old Browser Exam Key
                [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                return;
            }
        }
    }
    
    // If opening the preferences window isn't allowed in these settings,
    // which is dangerous when being applied, we confirm the user knows what he's doing
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"] == NO) {
        SEBDisabledPreferencesAnswer answer = [self alertForDisabledPreferences];
        switch(answer)
        {
            case SEBDisabledPreferencesAnswerOverride:
            {
                // Apply edited allow prefs setting while overriding disabling the preferences window for this session/resetting it
                [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"];
                if (NSUserDefaults.userDefaultsPrivate) {
                    // Release preferences window so bindings get synchronized properly with the new loaded values
                    [self releasePreferencesWindow];
                    // Reopen preferences window
                    [self initPreferencesWindow];
                }
                // Re-generate Browser Exam Key
                [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
                break;
            }
                
            case SEBDisabledPreferencesAnswerCancel:
            {
                // Cancel: Don't apply new settings, don't restart, restore old Browser Exam Key
                [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                return;
            }
        }
    }
    
    //Close prefs window with "order out", which doesn't trigger windowWillClose
    [self closePreferencesWindow];
    
    // Post a notification that the preferences window was closed and SEB should be restarted
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"preferencesClosedRestartSEB" object:self];
}


// Save preferences and quit SEB
- (IBAction) quitSEB:(id)sender {

    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return;
    }
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *oldBrowserExamKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
    
    BOOL browserExamKeyChanged = [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    
    /// If private settings are active, check if those current settings have unsaved changes

    if (NSUserDefaults.userDefaultsPrivate && browserExamKeyChanged) {
        // There are unsaved changes
        SEBUnsavedSettingsAnswer answer = [self unsavedSettingsAlert];
        switch(answer)
        {
            case SEBUnsavedSettingsAnswerSave:
            {
                // Save the current settings data first (this also updates the Browser Exam Key if saving is successful)
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    // Saving failed: Abort quitting, restore old Browser Exam Key
                    [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                    return;
                }
                break;
            }
                
            case SEBUnsavedSettingsAnswerCancel:
            {
                // Cancel: Don't quit, restore old Browser Exam Key
                [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                return;
            }
        }

    } else if (!NSUserDefaults.userDefaultsPrivate) {
        
        /// Local client settings are active
        
        // If settings changed:
        if ([self settingsChanged]) {
            // Ask if edited settings should be applied or previously active settings restored
            SEBApplySettingsAnswers answer = [self askToApplySettingsAlert];
            switch(answer)
            {
                case SEBApplySettingsAnswerCancel:
                {
                    // Cancel: Don't quit
                    return;
                }
            }
        }
        
        // If opening the preferences window isn't allowed in these settings,
        // which is dangerous when being applied, we confirm the user knows what he's doing
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"] == NO) {
            SEBDisabledPreferencesAnswer answer = [self alertForDisabledPreferences];
            switch(answer)
            {
                case SEBDisabledPreferencesAnswerOverride:
                {
                    // Apply edited allow prefs setting while overriding disabling the preferences window for this session/resetting it
                    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"];
                    break;
                }
                    
                case SEBDisabledPreferencesAnswerCancel:
                {
                    // Cancel: Don't apply new settings, don't quit
                    return;
                }
            }
        }
    }
    [self closePreferencesWindow];

	[[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestQuitNotification" object:self];
}


- (IBAction) openSEBPrefs:(id)sender
{
    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return;
    }
    
    // If private settings are active, check if those current settings have unsaved changes
    if (NSUserDefaults.userDefaultsPrivate && [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
        // There are unsaved changes
        SEBUnsavedSettingsAnswer answer = [self unsavedSettingsAlert];
        switch(answer)
        {
            case SEBUnsavedSettingsAnswerSave:
            {
                // Save the current settings data first
                // this also updates the Browser Exam Key, we save it in case we need to cancel
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    // Saving failed: Abort opening prefs
                    return;
                }
                break;
            }
                
            case SEBUnsavedSettingsAnswerCancel:
            {
                // Cancel: Don't open settings
                return;
            }
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
                          DDLogInfo(@"Loading .seb settings file with file URL %@", sebFileURL);
                          [self openSEBPrefsAtURL:sebFileURL];

                      }
                  }];
}


// Action saving current preferences to a .seb file choosing the filename
- (IBAction) saveSEBPrefs:(id)sender
{
    [self savePrefsAs:NO fileURLUpdate:YES];
}


// Action saving current preferences to a .seb file choosing the filename
- (IBAction) saveSEBPrefsAs:(id)sender
{
    [self savePrefsAs:YES fileURLUpdate:YES];
}


// Method which saves current preferences to a .seb file
// with parameter indicating if the saved settings file URL should be updated
- (BOOL) savePrefsAs:(BOOL)saveAs fileURLUpdate:(BOOL)fileURLUpdate
{
    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return NO;
    }
   
    // Get selected config purpose
    sebConfigPurposes configPurpose = [self.configFileVC getSelectedConfigPurpose];
    NSURL *currentConfigFileURL;
    
    // Save current Browser Exam Key and its salt for the case saving fails
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *oldBrowserExamKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
    NSData *oldBrowserExamKeySalt = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_examKeySalt"];
    
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
        NSURL *prefsFileURL;
        if (!saveAs && [currentConfigFileURL isFileURL]) {
            // "Save": Rewrite the file openend before
            NSError *error;
            if (![encryptedSebData writeToURL:currentConfigFileURL options:NSDataWritingAtomic error:&error]) {
                // If the prefs file couldn't be saved
                NSAlert *newAlert = [[NSAlert alloc] init];
                [newAlert setMessageText:NSLocalizedString(@"Saving Settings Failed", nil)];
                [newAlert setInformativeText:[error localizedDescription]];
                [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [newAlert setAlertStyle:NSCriticalAlertStyle];
                [newAlert runModal];

                [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                [preferences setSecureObject:oldBrowserExamKeySalt forKey:@"org_safeexambrowser_SEB_examKeySalt"];
                return NO;
            } else {
                if (fileURLUpdate) {
                    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:currentConfigFileURL];
                    [self.configFileVC revertLastSavedButtonSetEnabled:self];
                    [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
                    [[MBPreferencesController sharedController] setPreferencesWindowTitle];
                }
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
            int result = [panel runModal];
            if (result == NSFileHandlingPanelOKButton) {
                prefsFileURL = [panel URL];
                NSError *error;
                // Write the contents in the new format.
                if (![encryptedSebData writeToURL:prefsFileURL options:NSDataWritingAtomic error:&error]) {
                    //if (![filteredPrefsDict writeToURL:prefsFileURL atomically:YES]) {
                    // If the prefs file couldn't be written
                    NSAlert *newAlert = [[NSAlert alloc] init];
                    [newAlert setMessageText:NSLocalizedString(@"Saving Settings Failed", nil)];
                    [newAlert setInformativeText:[error localizedDescription]];
                    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                    [newAlert setAlertStyle:NSCriticalAlertStyle];
                    [newAlert runModal];

                    [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                    [preferences setSecureObject:oldBrowserExamKeySalt forKey:@"org_safeexambrowser_SEB_examKeySalt"];
                    
                } else {
                    // Prefs got successfully written to file
                    // If "Save As" or the last file didn't had a full path (wasn't stored on drive):
                    // Store the new path as the current config file path
                    if (NSUserDefaults.userDefaultsPrivate && fileURLUpdate && (saveAs || ![currentConfigFileURL isFileURL])) {
                        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:prefsFileURL];
                        [self.configFileVC revertLastSavedButtonSetEnabled:self];
                        [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
                    }
                    if (NSUserDefaults.userDefaultsPrivate && fileURLUpdate) {
                        [[MBPreferencesController sharedController] setPreferencesWindowTitle];
                    }
                    if (fileURLUpdate) {
                        NSString *settingsSavedTitle = configPurpose ? NSLocalizedString(@"Settings for Configuring Client", nil) : NSLocalizedString(@"Settings for Starting Exam", nil);
                        NSString *settingsSavedMessage = configPurpose ? NSLocalizedString(@"Settings have been saved, use this file to configure local settings of a SEB client.", nil) : NSLocalizedString(@"Settings have been saved, use this file to start an exam with SEB.", nil);
                        NSAlert *settingsSavedAlert = [[NSAlert alloc] init];
                        [settingsSavedAlert setMessageText:settingsSavedTitle];
                        [settingsSavedAlert setInformativeText:settingsSavedMessage];
                        [settingsSavedAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                        [settingsSavedAlert runModal];
                    }
                }
            } else {
                // Saving settings was canceled
                [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
                [preferences setSecureObject:oldBrowserExamKeySalt forKey:@"org_safeexambrowser_SEB_examKeySalt"];
                return NO;
            }
        }
        [self.examVC displayBrowserExamKey];

        // When Save As with local user defaults we ask if the saved file should be edited further
        if (saveAs && !NSUserDefaults.userDefaultsPrivate) {
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Edit Saved Settings?", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"Do you want to continue editing the saved settings file?", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Edit File", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            int answer = [newAlert runModal];
            switch(answer)
            {
                case NSAlertFirstButtonReturn:
                {
                    // Release preferences window so bindings get synchronized properly with the new loaded values
                    [self releasePreferencesWindow];
                    
                    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:prefsFileURL];
                    [self.configFileVC revertLastSavedButtonSetEnabled:self];

                    // Get key/values from local shared client UserDefaults
                    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
                    NSDictionary *localClientPreferences = [preferences dictionaryRepresentationSEB];
                    
                    // Switch to private UserDefaults (saved non-persistantly in memory instead in ~/Library/Preferences)
                    NSMutableDictionary *privatePreferences = [NSUserDefaults privateUserDefaults]; //the mutable dictionary has to be created here, otherwise the preferences values will not be saved!
                    [NSUserDefaults setUserDefaultsPrivate:YES];
                    
                    [self.configFileManager storeIntoUserDefaults:localClientPreferences];
                    DDLogVerbose(@"Private preferences set: %@", privatePreferences);
                    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:YES];

                    // Re-initialize and open preferences window
                    [self initPreferencesWindow];
                    [self reopenPreferencesWindow];
                    
                    return YES;
                }
                    
                case NSAlertSecondButtonReturn:
                {
                    // Keep working with local client settings
                    break;
                }
            }
        }
        return YES;
    }
    // This is only executed when there would be an error encrypting the SEB settings
    [preferences setSecureObject:oldBrowserExamKey forKey:@"org_safeexambrowser_currentData"];
    [preferences setSecureObject:oldBrowserExamKeySalt forKey:@"org_safeexambrowser_SEB_examKeySalt"];
    return NO;
}


// Action reverting preferences to default settings
- (IBAction) revertToDefaultSettings:(id)sender
{
    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return;
    }
    
    // Check if current settings have unsaved changes
    if ([[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
        // There are unsaved changes
        SEBUnsavedSettingsAnswer answer = [self unsavedSettingsAlert];
        switch(answer)
        {
            case SEBUnsavedSettingsAnswerSave:
            {
                // Save the current settings data first
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    // Saving failed: Abort restarting
                    return;
                }
                // If local client settings are active
                if (!NSUserDefaults.userDefaultsPrivate) {
                    // Reset the last saved file name
                    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
                }
                break;
            }
                
            case SEBUnsavedSettingsAnswerCancel:
            {
                // Cancel: Don't revert to default settings
                return;
            }
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

    // Reset UserDefaults (remove all SEB key/values)
//    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    NSDictionary *prefsDict = [preferences getSEBUserDefaultsDomains];
//    
//    // Remove all values for keys with prefix "org_safeexambrowser_" besides the exam settings key
//    for (NSString *key in prefsDict) {
//        if ([key hasPrefix:@"org_safeexambrowser_"] && ![key isEqualToString:@"org_safeexambrowser_currentData1"]) {
//            [preferences removeObjectForKey:key];
//        }
//    }
    
    // Write just default SEB settings to UserDefaults
    NSDictionary *emptySettings = [NSDictionary dictionary];
    [self.configFileManager storeIntoUserDefaults:emptySettings];
    
    // If using private defaults
    if (NSUserDefaults.userDefaultsPrivate) {
        // If reverting other than local client settings to default, use "starting exam" as config purpose
        [[NSUserDefaults standardUserDefaults] setSecureInteger:[NSNumber numberWithInt:sebConfigPurposeStartingExam] forKey:@"org_safeexambrowser_SEB_sebConfigPurpose"];
    }
    
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
    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return;
    }
    
    // Check if current settings have unsaved changes
    if ([[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
        // There are unsaved changes
        SEBUnsavedSettingsAnswer answer = [self unsavedSettingsAlert];
        switch(answer)
        {
            case SEBUnsavedSettingsAnswerSave:
            {
                // Save the current settings data first (this also updates the Browser Exam Key)
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    // Saving failed: Abort reverting to local client settings
                    return;
                }
                break;
            }
                
            case SEBUnsavedSettingsAnswerCancel:
            {
                // Cancel: Don't revert to local client settings
                return;
            }
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
    
    // Re-initialize and open preferences window
    [self initPreferencesWindow];
	[self reopenPreferencesWindow];
}


// Action reverting preferences to the last saved or opened file
- (IBAction) revertToLastSaved:(id)sender
{
    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return;
    }
    
    // Check if current settings have unsaved changes
    if ([[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
        // There are unsaved changes
        SEBUnsavedSettingsAnswer answer = [self unsavedSettingsAlert];
        switch(answer)
        {
            case SEBUnsavedSettingsAnswerSave:
            {
                // Save the current settings data first (this also updates the Browser Exam Key)
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    // Saving failed: Abort reverting
                    return;
                }
                // If local client settings are active
                if (!NSUserDefaults.userDefaultsPrivate) {
                    // Reset the last saved file name
                    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
                }
                break;
            }
                
            case SEBUnsavedSettingsAnswerCancel:
            {
                // Cancel: Don't revert to last saved/opened file
                return;
            }
        }
    }
    
    // If using private user defaults
    if (NSUserDefaults.userDefaultsPrivate) {
        DDLogInfo(@"Reverting private settings to last saved or opened .seb file");
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
            if ([self.configFileManager storeDecryptedSEBSettings:sebData forEditing:YES] == storeDecryptedSEBSettingsResultSuccess) {
                
                [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
                [self reopenPreferencesWindow];
            }
        }
    } else {
        // If using local client settings
        DDLogInfo(@"Reverting local client settings to settings before editing");
        [self.configFileManager storeIntoUserDefaults:_settingsBeforeEditing];
    }
}


// Action duplicating current preferences for editing
- (IBAction) editDuplicate:(id)sender
{
    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return;
    }
    
   /// Using local or private defaults?
    if (NSUserDefaults.userDefaultsPrivate) {
        
        /// If using private defaults
        
        // Check if current settings have unsaved changes
        if ([[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
            // There are unsaved changes
            SEBUnsavedSettingsAnswer answer = [self unsavedSettingsAlert];
            switch(answer)
            {
                case SEBUnsavedSettingsAnswerSave:
                {
                    // Save the current settings data first (this also updates the Browser Exam Key)
                    if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                        // Saving failed: Abort duplicating
                        return;
                    }
                    break;
                }
                    
                case SEBUnsavedSettingsAnswerCancel:
                {
                    // Cancel: Don't create a duplicate
                    return;
                }
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
        
        DDLogVerbose(@"Private preferences set: %@", privatePreferences);
    }
    
    // Re-initialize and open preferences window
    [self initPreferencesWindow];
	[self reopenPreferencesWindow];
}


// Action configuring client with currently edited preferences
- (IBAction) configureClient:(id)sender
{
    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return;
    }
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // If opening the preferences window isn't allowed in these settings,
    // which is dangerous when being applied, we confirm the user knows what he's doing
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"] == NO) {
        //switch to system's UserDefaults
        [NSUserDefaults setUserDefaultsPrivate:NO];
        SEBDisabledPreferencesAnswer answer = [self alertForDisabledPreferences];
        //switch to private UserDefaults
        [NSUserDefaults setUserDefaultsPrivate:YES];
        switch(answer)
        {
            case SEBDisabledPreferencesAnswerOverride:
            {
                // Apply edited allow prefs setting while overriding disabling the preferences window for this session/resetting it
                [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"];

                break;
            }
                
            case SEBDisabledPreferencesAnswerCancel:
            {
                // Cancel: Don't configure client
                return;
            }
        }
    }

    // Get key/values from private UserDefaults
    NSDictionary *privatePreferences = [preferences dictionaryRepresentationSEB];
    
    // Release preferences window so buttons get enabled properly for the local client settings mode
    [self releasePreferencesWindow];
    
    //switch to system's UserDefaults
    [NSUserDefaults setUserDefaultsPrivate:NO];
    
    // Write values from .seb config file to the local preferences (shared UserDefaults)
    [self.configFileManager storeIntoUserDefaults:privatePreferences];
    
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    
    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
    
    // Re-initialize and open preferences window
    [self initPreferencesWindow];
	[self reopenPreferencesWindow];
}


// Action applying currently edited preferences, closing preferences window and restarting SEB
- (IBAction) applyAndRestartSEB:(id)sender
{
    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return;
    }
    
    // Close preferences window (if user doesn't cancel it) but without asking to apply settings
    // this also triggers a SEB restart
    if ([self conditionallyClosePreferencesWindowAskToApply:NO]) {
        // Close preferences window manually (as windowShouldClose: won't be called)
        [self closePreferencesWindow];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"preferencesClosedRestartSEB" object:self];
    }
}


@end
