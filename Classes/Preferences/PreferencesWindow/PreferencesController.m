//
//  PreferencesController.m
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

#import "PreferencesController.h"
#import "MBPreferencesController.h"
#import "SEBCryptor.h"
#import "SEBURLFilter.h"
#import "NSURL+SEBURL.h"
#import "PreferencesViewController.h"
#import <CoreImage/CoreImage.h>


@implementation NSViewController (SEBNSViewController)

- (NSScrollView *) scrollView
{
    NSArray *subviews = self.view.subviews;
    for (NSView *subview in subviews) {
        if ([subview isKindOfClass:[NSScrollView class]]) {
            return (NSScrollView *)subview;
        }
    }
    return nil;
}

@end


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
    return [self.preferencesWindow isVisible];
}


- (NSWindow *)preferencesWindow
{
    return [MBPreferencesController sharedController].window;
}


- (BOOL) usingPrivateDefaults {
    return NSUserDefaults.userDefaultsPrivate;
}


- (SEBOSXConfigFileController *) configFileController
{
    if (!_configFileController) {
        _configFileController = [[SEBOSXConfigFileController alloc] init];
        _configFileController.sebController = self.sebController;
    }
    return _configFileController;
}


- (SEBBrowserController *)browserController {
    if (!_browserController) {
        _browserController = _sebController.browserController;
    }
    return _browserController;
}


#pragma mark -
#pragma mark Methods for initializing, opening, closing, releasing and re-opening preferences window

- (void)awakeFromNib
{
    restartSEB = NO;
    
    // Add an observer for the notification to display the preferences window again
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showPreferencesWindow:)
                                                 name:@"showPreferencesWindow" object:nil];
    
    // Add an observer for the notification to switch to the Config File prefs pane
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(switchToConfigFilePane:)
                                                 name:@"switchToConfigFilePane" object:nil];
    
}

- (void)initPreferencesWindow
{
    // Check if running on macOS 10.7/10.8
    if (floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_9) {
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
    
	PrefsAppearanceViewController *appearance = [[PrefsAppearanceViewController alloc]
                                                 initWithNibName:@"PreferencesAppearance" bundle:nil];
	PrefsBrowserViewController *browser = [[PrefsBrowserViewController alloc]
                                           initWithNibName:@"PreferencesBrowser" bundle:nil];
	PrefsDownUploadsViewController *downuploads = [[PrefsDownUploadsViewController alloc]
                                                   initWithNibName:@"PreferencesDownUploads" bundle:nil];
    self.browserController.browserExamKey = nil;
    self.browserController.browserExamKeySalt = [[NSUserDefaults standardUserDefaults] secureObjectForKey:@"org_safeexambrowser_SEB_examKeySalt"];
    self.browserController.configKey = nil;
    self.examVC = [[PrefsExamViewController alloc] initWithNibName:@"PreferencesExam" bundle:nil];
    self.examVC.preferencesController = self;
	PrefsApplicationsViewController *applications = [[PrefsApplicationsViewController alloc]
                                                     initWithNibName:@"PreferencesApplications" bundle:nil];
    applications.preferencesController = self;
//	PrefsResourcesViewController *resources = [[PrefsResourcesViewController alloc] initWithNibName:@"PreferencesResources" bundle:nil];
	self.networkVC = [[PrefsNetworkViewController alloc] initWithNibName:@"PreferencesNetwork" bundle:nil];
    self.networkVC.preferencesController = self;
	PrefsSecurityViewController *security = [[PrefsSecurityViewController alloc]
                                             initWithNibName:@"PreferencesSecurity" bundle:nil];
    [[MBPreferencesController sharedController] setModules:[NSArray arrayWithObjects:
                                                            self.generalVC,
                                                            self.configFileVC,
                                                            appearance,
                                                            browser,
                                                            downuploads,
                                                            self.examVC,
                                                            applications,
                                                            self.networkVC,
                                                            security,
                                                            nil]];
    // Set self as the window delegate to be able to post a notification when preferences window is closing
    // will be overridden when the general pane is displayed (loaded from nib)
    if (![self.preferencesWindow delegate]) {
        // Set delegate only if it's not yet set!
        [self.preferencesWindow setDelegate:self];
    }
}


// Public method called to open the preferences window
- (void)openPreferencesWindow
{
    if (![[MBPreferencesController sharedController] modules]) {
        [self initPreferencesWindow];
    }

    // Store current settings (before they probably get edited)
    [self storeCurrentSettings];
    urlFilterLearningModeInitialState = self.networkVC.URLFilterLearningMode;
    
    [[MBPreferencesController sharedController] setSettingsFileURL:[[MyGlobals sharedMyGlobals] currentConfigURL]];
	[[MBPreferencesController sharedController] showWindow:self];
}


// Method called to programmatically close the preferences window
- (void) closePreferencesWindow
{
    DDLogInfo(@"%s", __FUNCTION__);

    self.generalVC = nil;
    self.configFileVC = nil;
    self.examVC = nil;
    [self.networkVC removeObservers];
    self.networkVC = nil;
    [[MBPreferencesController sharedController] unloadNibs];
}


// Releases preferences window so after reopening bindings get synchronized properly with new loaded values
- (void)releasePreferencesWindow
{
    DDLogDebug(@"%s", __FUNCTION__);
    self.refreshingPreferences = YES;
    [self closePreferencesWindow];
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

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [self.configFileVC hideQRConfig];
}

- (void)windowDidResignKey:(NSNotification *)notification
{
    [self.configFileVC hideQRConfig];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
    [self.configFileVC hideQRConfig];
}

// Executed to decide if window should close
- (BOOL)windowShouldClose:(id)sender
{
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];

    BOOL shouldClose = true;
    // If Preferences are being closed and we're not just refreshing the preferences window
    if (!self.refreshingPreferences) {
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        [self.sebController.browserController.mainBrowserWindow makeKeyAndOrderFront:self];
        shouldClose = [self conditionallyClosePreferencesWindowAskToApply:YES];
    }
    if (shouldClose) {
        [self closePreferencesWindow];
    }
    return shouldClose;
}


// Executed when preferences window is about to be closed
- (void)windowWillClose:(NSNotification *)notification
{
    [self.configFileVC hideQRConfig];
    if (self.preferencesAreOpen && !self.refreshingPreferences) {
//        self.sebController.browserController.reinforceKioskModeRequested = YES;
        // Post a notification that the preferences window closes
        if (restartSEB) {
            restartSEB = NO;
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"preferencesClosedRestartSEB" object:self];
        } else {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"preferencesClosed" object:self];
        }
    }
    self.refreshingPreferences = NO;
}


- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    NSSize newFrameSize;
    NSSize windowSize = sender.frame.size;

    NSViewController *viewController = (NSViewController *)[MBPreferencesController sharedController].currentModule;
    
    NSSize newWindowSize = [MBPreferencesController sharedController].newWindowSize;
    NSScrollView *scrollView = [viewController scrollView];
    if (scrollView) {
        NSSize contentViewSize = scrollView.contentView.bounds.size;
        NSSize fullContentSize = [scrollView documentView].fittingSize;
        CGFloat windowBorderWidth = windowSize.width - fullContentSize.width;
        CGFloat windowBorderHeight = windowSize.height - contentViewSize.height;

        newFrameSize = NSMakeSize(fullContentSize.width + windowBorderWidth, (frameSize.height < fullContentSize.height + windowBorderHeight ? frameSize.height : fullContentSize.height + windowBorderHeight));
#ifdef DEBUG
        DDLogVerbose(@"New frame size for Preferences window containing a scroll view: %f, %f", newFrameSize.width, newFrameSize.height);
#endif
    } else {
        newFrameSize = newWindowSize;
    }
    return newFrameSize;
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
    [self.networkVC windowWillClose:[NSNotification notificationWithName:NSWindowWillCloseNotification object:nil]];

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    SEBEncapsulatedSettings *oldSettings = [[SEBEncapsulatedSettings alloc] initWithCurrentSettings];

    // If private settings are active, check if those current settings have unsaved changes
    if (NSUserDefaults.userDefaultsPrivate && [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO]) {
        // There are unsaved changes
        SEBUnsavedSettingsAnswer answer = [self unsavedSettingsAlertWithText:
                      NSLocalizedString(@"Edited settings have unsaved changes.", @"")];
        switch(answer)
        {
            case SEBUnsavedSettingsAnswerSave:
            {
                // Save the current settings data first (this also updates the Browser Exam Key)
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    // Saving failed: Abort closing the prefs window, restore possibly changed setting keys
                    [oldSettings restoreSettings];
                    return NO;
                }
                break;
            }
                
            case SEBUnsavedSettingsAnswerCancel:
            {
                // Cancel: Don't close preferences, restore old Browser Exam Key
                // Saving failed: Abort closing the prefs window, restore possibly changed setting keys
                [oldSettings restoreSettings];
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
                    // Cancel: Abort closing the prefs window, restore possibly changed setting keys
                    [oldSettings restoreSettings];
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
                    // Cancel: Abort closing the prefs window, restore possibly changed setting keys
                    [oldSettings restoreSettings];
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
    [self.configFileVC setCurrentConfigFileKeyHash:_currentConfigFileKeyHash];
    [self.configFileVC setSettingsPassword:_currentConfigPassword isHash:_currentConfigPasswordIsHash];
}


// Stores current settings in memory (before editing them)
- (void) storeCurrentSettings
{
    settingsBeforeEditing = [[SEBEncapsulatedSettings alloc] initWithCurrentSettings];
}


// Restores settings which were stored in memory before editing
- (void) restoreStoredSettings
{
    [settingsBeforeEditing restoreSettings];
}


// Check if settings have changed
- (BOOL) settingsChanged
{
    if (self.networkVC.URLFilterLearningMode != urlFilterLearningModeInitialState) {
        return YES;
    }
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    return settingsBeforeEditing != nil && ![settingsBeforeEditing.browserExamKey isEqualToData:[preferences secureObjectForKey:@"org_safeexambrowser_currentData"]];
}


- (void) openSEBPrefsAtURL:(NSURL *)sebFileURL
{
    NSError *error = nil;
    NSData *sebData = [NSData dataWithContentsOfURL:sebFileURL options:NSDataReadingUncached error:&error];
    
    if (error || !sebData) {
        // Error when reading configuration data
        [MBPreferencesController.sharedController.window presentError:error modalForWindow:MBPreferencesController.sharedController.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
        DDLogError(@"%s: Reading a settings file with path %@ didn't work, error: %@", __FUNCTION__, sebFileURL.absoluteString, error.description);

    } else {
        if (sebData.length == 0) {
            DDLogError(@"%s: Loaded settings file with path %@ was empty!", __FUNCTION__, sebFileURL.absoluteString);

            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Opening Settings Failed", @"")];
            [newAlert setInformativeText:NSLocalizedString(@"Loaded settings are empty and cannot be used.", @"")];
            [newAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
            [newAlert setAlertStyle:NSAlertStyleCritical];
            // beginSheetModalForWindow: completionHandler: is available from macOS 10.9,
            // which also is the minimum macOS version the Preferences window is available from
            [newAlert beginSheetModalForWindow:MBPreferencesController.sharedController.window completionHandler:nil];
            return;
        }
        // Release preferences window so bindings get synchronized properly with the new loaded values
        [self releasePreferencesWindow];

        // Decrypt and store the .seb config file
        currentSEBFileURL = sebFileURL;
        [self.configFileController storeNewSEBSettings:sebData
                                         forEditing:YES
                                           callback:self
                                              selector:@selector(openingSEBPrefsSucessfull:)];
    }
}


- (void) openingSEBPrefsSucessfull:(NSError *)error
{
    if (error) {
        // Error when reading configuration data
        [MBPreferencesController.sharedController.window presentError:error modalForWindow:MBPreferencesController.sharedController.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
    } else {
        // if successfull save the path to the file for possible editing in the preferences window
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:currentSEBFileURL];
        
        [[MBPreferencesController sharedController] setSettingsFileURL:currentSEBFileURL];
    }
    // Re-initialize and open preferences window
    [self initPreferencesWindow];
    [self reopenPreferencesWindow];
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
        unconfirmedPassword = NSLocalizedString(@"administrator", @"");
        [self alertForUnconfirmedPassword:unconfirmedPassword];
        passwordIsUnconfirmed = YES;
    }
    
    if (self.generalVC.compareQuitPasswords) {
        unconfirmedPassword = NSLocalizedString(@"quit", @"");
        [self alertForUnconfirmedPassword:unconfirmedPassword];
        passwordIsUnconfirmed = YES;
    }
    
    if (self.configFileVC.compareSettingsPasswords) {
        unconfirmedPassword = NSLocalizedString(@"settings", @"");
        [self alertForUnconfirmedPassword:unconfirmedPassword];
        passwordIsUnconfirmed = YES;
    }
    
    return passwordIsUnconfirmed;
}


- (BOOL) canSavePlainText
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    ShareConfigFormat shareConfigFormat = [preferences secureIntegerForKey:@"org_safeexambrowser_shareConfigFormat"];
    BOOL configPurposeStartingExam = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebConfigPurpose"] == sebConfigPurposeStartingExam;
    return shareConfigFormat == shareConfigFormatFile &&
    configPurposeStartingExam &&
    !self.configFileVC.isEncrypted;
}


// Show alert that the password with passed name string isn't confirmed
- (void) alertForUnconfirmedPassword:(NSString *)passwordName
{
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Unconfirmed Password", @"")];
    [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Please confirm the %@ password first.", @""), passwordName]];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
    [newAlert setAlertStyle:NSAlertStyleInformational];
    // beginSheetModalForWindow: completionHandler: is available from macOS 10.9,
    // which also is the minimum macOS version the Preferences window is available from
    [newAlert beginSheetModalForWindow:MBPreferencesController.sharedController.window completionHandler:nil];
}


- (SEBDisabledPreferencesAnswer) alertForDisabledPreferences
{
    if (@available(macOS 12.0, *)) {
    } else {
        if (@available(macOS 11.0, *)) {
            if (self.sebController.isAACEnabled || self.sebController.wasAACEnabled) {
                return SEBDisabledPreferencesAnswerApply;
            }
        }
    }
    NSString *informativeText = NSUserDefaults.userDefaultsPrivate
    ? NSLocalizedString(@"These settings have the option 'Allow to open preferences window on client' disabled. Are you sure you want to apply this? Otherwise you can override this option for the current session.", @"")
    : [NSString stringWithFormat:NSLocalizedString(@"Local client settings have the option 'Allow to open preferences window on client' disabled, which will prevent opening the preferences window even when you restart %@. Are you sure you want to apply this? Otherwise you can reset this option.", @""), SEBShortAppName];
    
    NSString *defaultButtonText = NSUserDefaults.userDefaultsPrivate
    ? NSLocalizedString(@"Override", @"")
    : NSLocalizedString(@"Reset", @"");
    
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Opening Preferences Disabled", @"")];
    [newAlert setInformativeText:informativeText];
    [newAlert addButtonWithTitle:defaultButtonText];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Apply Anyways", @"")];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    [newAlert setAlertStyle:NSAlertStyleCritical];
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
            NSLocalizedString(@"Current settings have unsaved changes. If you don't save those first, you will loose them.", @"")];
}

- (SEBUnsavedSettingsAnswer) unsavedSettingsAlertWithText:(NSString *)informativeText
{
    if (@available(macOS 12.0, *)) {
    } else {
        if (@available(macOS 11.0, *)) {
            if (self.sebController.isAACEnabled || self.sebController.wasAACEnabled) {
                return SEBUnsavedSettingsAnswerDontSave;
            }
        }
    }
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Unsaved Changes", @"")];
    [newAlert setInformativeText:informativeText];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Save Changes", @"")];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Don't Save", @"")];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    [newAlert setAlertStyle:NSAlertStyleWarning];
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
    if (@available(macOS 12.0, *)) {
    } else {
        if (@available(macOS 11.0, *)) {
            if (self.sebController.isAACEnabled || self.sebController.wasAACEnabled) {
                return SEBApplySettingsAnswerApply;
            }
        }
    }
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Apply Edited Settings?", @"")];
    if (NSUserDefaults.userDefaultsPrivate) {
        [newAlert setInformativeText:NSLocalizedString(@"You edited settings. Do you want to apply them or continue using previous settings?", @"")];
    } else {
        [newAlert setInformativeText:NSLocalizedString(@"You edited settings. Do you want to apply them or continue using previous settings (current settings will be discarded)?", @"")];
    }
    [newAlert addButtonWithTitle:NSLocalizedString(@"Don't Apply", @"")];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Apply", @"")];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    NSInteger answer = [newAlert runModal];
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
- (IBAction) restartSEB:(id)sender 
{
    if (!self.preferencesAreOpen) {
        return;
    }
    
    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return;
    }

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    SEBEncapsulatedSettings *oldSettings = [[SEBEncapsulatedSettings alloc] initWithCurrentSettings];

    BOOL browserExamKeyChanged = [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    
    // If private settings are active, check if those current settings have unsaved changes
    if (NSUserDefaults.userDefaultsPrivate && browserExamKeyChanged) {
        // There are unsaved changes
        SEBUnsavedSettingsAnswer answer = [self unsavedSettingsAlertWithText:
                      NSLocalizedString(@"Edited settings have unsaved changes.", @"")];
        switch(answer)
        {
            case SEBUnsavedSettingsAnswerSave:
            {
                // Save the current settings data first (this also updates the Browser Exam Key)
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    // Saving failed: Saving failed: Abort closing the prefs window, restore possibly changed setting keys
                    [oldSettings restoreSettings];

                    return;
                }
                break;
            }
                
            case SEBUnsavedSettingsAnswerCancel:
            {
                // Cancel: Don't restart, restore possibly changed setting keys
                [oldSettings restoreSettings];

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
                // Cancel: Don't restart, restore possibly changed setting keys
                [oldSettings restoreSettings];

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
                // Cancel: Don't apply new settings, don't restart, restore possibly changed setting keys
                [oldSettings restoreSettings];

                return;
            }
        }
    }
    
    //Close prefs window
    restartSEB = YES;
    [self closePreferencesWindow];
}


// Save preferences and quit SEB
- (IBAction) quitSEB:(id)sender
{
    if (!self.preferencesAreOpen) {
        return;
    }
    
    DDLogInfo(@"%s Quitting SEB while Preferences window is open", __FUNCTION__);
    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return;
    }
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    SEBEncapsulatedSettings *oldSettings = [[SEBEncapsulatedSettings alloc] initWithCurrentSettings];

    BOOL browserExamKeyChanged = [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    
    /// If private settings are active, check if those current settings have unsaved changes

    if (NSUserDefaults.userDefaultsPrivate && browserExamKeyChanged) {
        DDLogInfo(@"Private user defaults (exam settings) active: There are unsaved changes");
        SEBUnsavedSettingsAnswer answer = [self unsavedSettingsAlert];
        switch(answer)
        {
            case SEBUnsavedSettingsAnswerSave:
            {
                // Save the current settings data first (this also updates the Browser Exam Key if saving is successful)
                if (![self savePrefsAs:NO fileURLUpdate:NO]) {
                    // Saving failed: Abort quitting, restore possibly changed setting keys
                    [oldSettings restoreSettings];

                    return;
                }
                break;
            }
                
            case SEBUnsavedSettingsAnswerCancel:
            {
                // Cancel: Don't quit, restore possibly changed setting keys
                [oldSettings restoreSettings];

                return;
            }
        }

    } else if (!NSUserDefaults.userDefaultsPrivate) {
        
        /// Local client settings are active
        DDLogInfo(@"Client settings are active");
        // If settings changed:
        if ([self settingsChanged]) {
            DDLogInfo(@"Client settings have been changed, ask if they should be applied.");
            // Ask if edited settings should be applied or previously active settings restored
            SEBApplySettingsAnswers answer = [self askToApplySettingsAlert];
            switch(answer)
            {
                case SEBApplySettingsAnswerCancel:
                {
                    // Cancel: Don't quit
                    DDLogInfo(@"User selected to cancel applying changed client settings, also abort quitting SEB.");
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
    _sebController.quittingMyself = YES;
    [self closePreferencesWindow];

	[[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestExitNotification" object:self];
}


- (IBAction) openSEBPrefs:(id)sender
{
    if (!self.preferencesAreOpen) {
        return;
    }
    
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
    [panel setAllowedFileTypes:[NSArray arrayWithObject:SEBFileExtension]];
    // beginSheetModalForWindow: completionHandler: is available from macOS 10.9,
    // which also is the minimum macOS version the Preferences window is available from
    [panel beginSheetModalForWindow:self.preferencesWindow
                  completionHandler:^(NSInteger result){
                      if (result == NSModalResponseOK)
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
    if (!self.preferencesAreOpen) {
        return NO;
    }
    
    // Check if passwords are confirmed and save them if yes
    if (![self passwordsConfirmedAndSaved]) {
        // If they were not confirmed, return
        return NO;
    }
   
    // Get selected config purpose
    sebConfigPurposes configPurpose = [self.configFileVC getSelectedConfigPurpose];
    NSURL *currentConfigFileURL;
    
    // Save current settings including Browser Exam and Config Key and their salt values for the case saving fails
    SEBEncapsulatedSettings *oldSettings = [[SEBEncapsulatedSettings alloc] initWithCurrentSettings];
    // When saving settings, keys will change
    self.browserController.browserExamKey = nil;
    self.browserController.configKey = nil;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    // Force recalculating Config Key
//    [preferences setSecureObject:[NSData data] forKey:@"org_safeexambrowser_configKey"];

    if ([preferences secureObjectForKey:@"org_safeexambrowser_SEB_allowWLAN"]) {
        // Remove this outdated key (current version: allowWlan) as it messes up ConfigKey calculation
        [preferences removeSecureObjectForKey:@"org_safeexambrowser_SEB_allowWLAN"];
        // Force recalculating the ConfigKeyContainedKeys dictionary
        [preferences setSecureObject:[NSDictionary dictionary] forKey:@"org_safeexambrowser_configKeyContainedKeys"];
    }
    
    /// Check if local client or private settings (UserDefauls) are active
    ///
    if (!NSUserDefaults.userDefaultsPrivate) {
        
        /// Local Client settings are active
        
        // Update filter rules, as those might change the settings checksum
        [[SEBURLFilter sharedSEBURLFilter] updateFilterRulesSebRules:YES withStartURL:_sebController.startURL];

        // Update the Browser Exam Key without re-generating its salt
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
        
        // Preset "SebClientSettings.seb" as default file name
        currentConfigFileURL = [NSURL fileURLWithPathString:SEBClientSettingsFilename];
        
    } else {
        
        /// Private settings are active
        
        // Update filter rules, as those might change the settings checksum
        [[SEBURLFilter sharedSEBURLFilter] updateFilterRulesSebRules:YES withStartURL:_sebController.startURL];

        // Update the Browser Exam Key with a new salt if Save As
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:saveAs];
        
        // Get the current filename
        currentConfigFileURL = [[MyGlobals sharedMyGlobals] currentConfigURL];
    }
    self.browserController.browserExamKeySalt = [[NSUserDefaults standardUserDefaults] secureObjectForKey:@"org_safeexambrowser_SEB_examKeySalt"];

    NSURL *prefsFileURL = currentConfigFileURL;
    if (configPurpose == sebConfigPurposeManagedConfiguration) {
        prefsFileURL = [prefsFileURL.URLByDeletingPathExtension URLByAppendingPathExtension:PlistFileExtension];
    }

    if (saveAs || ![currentConfigFileURL isFileURL]) {
        
        // "Save As": Set the default name and if there is an existing path for the file and show the panel.
        NSSavePanel *panel = [NSSavePanel savePanel];
        panel.accessoryView = configPurpose == sebConfigPurposeManagedConfiguration ? nil : _sebController.savePanelAccessoryView;
        panel.delegate = self;
        
        BOOL sharePlainTextConfig = [preferences secureBoolForKey:@"org_safeexambrowser_shareConfigUncompressed"] || MyGlobals.sharedMyGlobals.currentConfigUncompressed;
        _sebController.shareConfigUncompressedButton.state = sharePlainTextConfig;
        NSURL *directory = currentConfigFileURL.URLByDeletingLastPathComponent;
        NSString *directoryString = directory.relativePath;
        if ([directoryString isEqualToString:@"."]) {
            NSFileManager *fileManager = [NSFileManager new];
            directory = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0];
        }
        [panel setDirectoryURL:directory];
        if (configPurpose == sebConfigPurposeManagedConfiguration) {
            [panel setNameFieldStringValue:currentConfigFileURL.lastPathComponent];
        } else {
            [panel setNameFieldStringValue:[currentConfigFileURL.lastPathComponent stringByDeletingPathExtension]];
        }

        NSMutableArray *allowedFileTypes = [NSMutableArray arrayWithObjects:SEBFileExtension, PlistFileExtension, nil];
        if (configPurpose != sebConfigPurposeManagedConfiguration) {
            [allowedFileTypes addObjectsFromArray:[NSArray arrayWithObjects:@"txt", @"png", nil]];
        }
        _sebController.shareConfigUncompressedButton.hidden = !self.canSavePlainText;
        [panel setAllowedFileTypes:allowedFileTypes.copy];
        NSInteger result = [panel runModal];
        if (result == NSModalResponseOK) {
            prefsFileURL = [panel URL];
        } else {
            // Saving settings was canceled
            [oldSettings restoreSettings];
            return NO;
        }
    }
    
    // Read SEB settings from UserDefaults and encrypt them using the provided security credentials
    ShareConfigFormat shareConfigFormat = [preferences secureIntegerForKey:@"org_safeexambrowser_shareConfigFormat"];
    [_sebController.shareConfigFormatPopUpButton selectItemAtIndex:shareConfigFormat];
    BOOL sharePlainTextConfig = _sebController.shareConfigUncompressedButton.state;
    MyGlobals.sharedMyGlobals.currentConfigUncompressed = sharePlainTextConfig;
    [preferences setSecureBool:sharePlainTextConfig forKey:@"org_safeexambrowser_shareConfigUncompressed"];
    BOOL uncompressed = self.canSavePlainText && sharePlainTextConfig;
    BOOL removeDefaults = [preferences secureBoolForKey:@"org_safeexambrowser_removeDefaults"];

    // Read SEB settings from UserDefaults and encrypt them using the provided security credentials
    NSData *encryptedConfigData = [self.configFileVC encryptSEBSettingsWithSelectedCredentialsConfigFormat:shareConfigFormat
                                                                                       allowUnencrypted:NO
                                                                                           uncompressed:uncompressed
                                                                                         removeDefaults:removeDefaults];
    if (encryptedConfigData) {

        NSData *encryptedSEBData = [self encodeConfigData:encryptedConfigData forPurpose:configPurpose format:shareConfigFormat uncompressed:uncompressed removeDefaults:removeDefaults];

        if (shareConfigFormat == shareConfigFormatQRCode && encryptedSEBData == nil) {
            shareConfigFormat = shareConfigFormatFile;
            encryptedSEBData = encryptedConfigData;
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Config Too Large for QR Code", @"")];
            [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"This configuration doesn't fit into a QR code, maybe it was created with an older %@ version/on another platform or contains large data like many prohibited processes, embedded certificates or many URL filter rules. You could try to re-create it manually from scratch using default settings and changing only necessary settings.", @""), SEBShortAppName]];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Share as Configuration", @"")];
            [newAlert setAlertStyle:NSAlertStyleCritical];
            switch([newAlert runModal])
            {
                case NSAlertFirstButtonReturn:
                    // Saving settings was canceled
                    [oldSettings restoreSettings];
                    return NO;
                    
                case NSAlertSecondButtonReturn:
                    break;
            }
        }
        
        if (configPurpose != sebConfigPurposeManagedConfiguration) {
            NSString *fileExtension = [[MyGlobals sharedMyGlobals] fileExtensionForConfigFormat:shareConfigFormat];
            if ([fileExtension caseInsensitiveCompare:prefsFileURL.pathExtension] != NSOrderedSame) {
                fileURLUpdate = YES;
            }
            prefsFileURL = [prefsFileURL.URLByDeletingPathExtension URLByAppendingPathExtension:fileExtension];
        }

        NSError *error;
        // Write the contents in the new format.
        if (![encryptedSEBData writeToURL:prefsFileURL options:NSDataWritingAtomic error:&error]) {
            //if (![filteredPrefsDict writeToURL:prefsFileURL atomically:YES]) {
            // If the prefs file couldn't be written
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Saving Settings Failed", @"")];
            [newAlert setInformativeText:[error localizedDescription]];
            [newAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
            [newAlert setAlertStyle:NSAlertStyleCritical];
            [self.sebController runModalAlert:newAlert conditionallyForWindow:MBPreferencesController.sharedController.window completionHandler:nil];

            [oldSettings restoreSettings];
            return NO;
            
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
                [[MyGlobals sharedMyGlobals] setCurrentConfigURL:prefsFileURL];
                [[MBPreferencesController sharedController] setSettingsFileURL:prefsFileURL];
                [[MBPreferencesController sharedController] setPreferencesWindowTitle];
            }
            if (fileURLUpdate && saveAs && configPurpose != sebConfigPurposeManagedConfiguration) {
                NSString *settingsSavedTitle = configPurpose ? NSLocalizedString(@"Settings for Configuring Client", @"") : NSLocalizedString(@"Settings for Starting Exam", @"");
                NSString *settingsSavedMessage = configPurpose ?
                [NSString stringWithFormat:NSLocalizedString(@"Settings have been saved, use this file to configure a %@ client permanently.", @""), SEBShortAppName] :
                [NSString stringWithFormat:NSLocalizedString(@"Settings have been saved, use this file to start an exam with %@.", @""), SEBShortAppName];
                NSAlert *settingsSavedAlert = [[NSAlert alloc] init];
                [settingsSavedAlert setMessageText:settingsSavedTitle];
                [settingsSavedAlert setInformativeText:settingsSavedMessage];
                [settingsSavedAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
                [self.sebController runModalAlert:settingsSavedAlert conditionallyForWindow:MBPreferencesController.sharedController.window completionHandler:nil];
            }
        }
        
        [self.examVC displayUpdatedKeys];

        // When Save As with local user defaults we ask if the saved file should be edited further
        if (saveAs && !NSUserDefaults.userDefaultsPrivate) {
            if (@available(macOS 12.0, *)) {
            } else {
                if (@available(macOS 11.0, *)) {
                    if (self.sebController.isAACEnabled || self.sebController.wasAACEnabled) {
                        return YES;
                    }
                }
            }

            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Edit Saved Settings?", @"")];
            [newAlert setInformativeText:NSLocalizedString(@"Do you want to continue editing the saved settings file?", @"")];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Edit File", @"")];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
            NSInteger answer = [newAlert runModal];
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
                    
                    [self.configFileController storeIntoUserDefaults:localClientPreferences];
                    [preferences setSecureInteger:shareConfigFormat forKey:@"org_safeexambrowser_shareConfigFormat"];
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

    } else {
        // This is only executed when there would be an error encrypting the SEB settings
        [oldSettings restoreSettings];
        return NO;
    }

    return YES;
}


- (NSData *)encodeConfigData:(NSData *)encryptedSEBData
                        forPurpose:(sebConfigPurposes)configPurpose
                            format:(ShareConfigFormat)shareConfigFormat
                      uncompressed:(BOOL)uncompressed
                    removeDefaults:(BOOL)removeDefaults
{
    if (encryptedSEBData) {
        
        if (configPurpose != sebConfigPurposeManagedConfiguration && (shareConfigFormat == shareConfigFormatLink || shareConfigFormat == shareConfigFormatQRCode)) {
            NSString *configInDataURL = [NSString stringWithFormat:@"%@://%@;base64,%@", SEBSSecureProtocolScheme, SEBConfigMIMEType, [encryptedSEBData base64EncodedStringWithOptions:(0)]];
            if (shareConfigFormat == shareConfigFormatQRCode) {
                CIImage *ciImage = [QRCodeGenerator generateQRCodeFrom:configInDataURL];
                if (ciImage) {
                    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
                    encryptedSEBData = [[CIContext contextWithOptions:nil] PNGRepresentationOfImage:ciImage format:kCIFormatBGRA8 colorSpace:colorSpace options:NSDictionary.new];
                } else {
                    DDLogInfo(@"Config too large for QR code.");
                    return nil;
                }
                
            } else {
                encryptedSEBData = [configInDataURL dataUsingEncoding:NSUTF8StringEncoding];
            }
        }
    }
    return encryptedSEBData;
}


- (NSString *)panel:(id)sender
userEnteredFilename:(NSString *)filename
          confirmed:(BOOL)okFlag
{
    sebConfigPurposes configPurpose = [self.configFileVC getSelectedConfigPurpose];
    if (configPurpose != sebConfigPurposeManagedConfiguration) {
        ShareConfigFormat shareConfigFormat = [[NSUserDefaults standardUserDefaults] secureIntegerForKey:@"org_safeexambrowser_shareConfigFormat"];
        NSString *fileExtension = [[MyGlobals sharedMyGlobals] fileExtensionForConfigFormat:shareConfigFormat];
        filename = [filename.stringByDeletingPathExtension stringByAppendingPathExtension:fileExtension];
    } else if (!(filename.pathExtension && [filename.pathExtension caseInsensitiveCompare:SEBFileExtension] == NSOrderedSame)) {
        filename = [filename.stringByDeletingPathExtension stringByAppendingPathExtension:PlistFileExtension];
    }
    return filename;
}


// Action reverting preferences to default settings
- (IBAction) revertToDefaultSettings:(id)sender
{
    if (!self.preferencesAreOpen) {
        return;
    }
    
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
    _currentConfigFileKeyHash = nil;
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
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (NSUserDefaults.userDefaultsPrivate) {
        [preferences resetSEBUserDefaults];
    } else {
        NSDictionary *prefsDict = [preferences getSEBUserDefaultsDomains];
        // Remove all values for keys with prefix "org_safeexambrowser_" besides the exam settings key
        for (NSString *key in prefsDict) {
            if ([key hasPrefix:@"org_safeexambrowser_"] && ![key isEqualToString:@"org_safeexambrowser_currentData1"]) {
                [preferences removeObjectForKey:key];
            }
        }
    }
    
    // Write just default SEB settings to UserDefaults
    NSDictionary *emptySettings = [NSDictionary dictionary];
    [self.configFileController storeIntoUserDefaults:emptySettings];
    
    // If using private defaults
    if (NSUserDefaults.userDefaultsPrivate) {
        // If reverting other than local client settings to default, use "starting exam" as config purpose
        [[NSUserDefaults standardUserDefaults] setSecureInteger:sebConfigPurposeStartingExam forKey:@"org_safeexambrowser_SEB_sebConfigPurpose"];
    }
    
    [self resetBEKCK];
    
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
    if (!self.preferencesAreOpen) {
        return;
    }
    
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

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    void (^revertToClientSettings)(BOOL) = ^void (BOOL correctPasswordEntered) {
        if (correctPasswordEntered) {
            // Release preferences window so buttons get enabled properly for the local client settings mode
            [self releasePreferencesWindow];

            // Get key/values from local shared client UserDefaults
            NSDictionary *localClientPreferences = [preferences dictionaryRepresentationSEB];
            
            // Reset the config file password
            self.currentConfigPassword = nil;
            self.currentConfigPasswordIsHash = NO;
            // Reset the config file encrypting identity (key) reference
            self.currentConfigFileKeyHash = nil;
            
            [self resetBEKCK];

            // Update local preferences and recalculate Config Key (also its contained keys)
            [self.configFileController storeIntoUserDefaults:localClientPreferences];
            
            [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];

            // Re-initialize and open preferences window
            [self initPreferencesWindow];
            [self reopenPreferencesWindow];

        } else {
            [NSUserDefaults setUserDefaultsPrivate:YES];
        }
    };

    NSString *privateDefaultsHashedAdminPassword = [self.configFileController getHashedAdminPassword];

    // Switch to system's UserDefaults
    [NSUserDefaults setUserDefaultsPrivate:NO];
    NSString *hashedAdminPassword = [self.configFileController getHashedAdminPassword];
    // Check if the admin password from the current private defaults is the same as the one in client setting
    if (hashedAdminPassword.length > 0 && ([privateDefaultsHashedAdminPassword caseInsensitiveCompare:hashedAdminPassword] != NSOrderedSame)) {
        // If admin passwords differ, ask the user to enter the admin pw from client settings
        [self.configFileController promptPasswordForHashedPassword:hashedAdminPassword messageText:[NSString stringWithFormat:NSLocalizedString(@"Enter the %@ administrator password used in client settings:",nil), SEBShortAppName] title:NSLocalizedString(@"Revert to Client Settings",nil) completionHandler:revertToClientSettings];
    } else {
        revertToClientSettings(YES);
    }
}


// Action reverting preferences to the last saved or opened file
- (IBAction) revertToLastSaved:(id)sender
{
    if (!self.preferencesAreOpen) {
        return;
    }
    
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
        currentSEBFileURL = [[MyGlobals sharedMyGlobals] currentConfigURL];
        NSData *sebData = [NSData dataWithContentsOfURL:currentSEBFileURL
                                                options:NSDataReadingUncached
                                                  error:&error];
        if (error) {
            // Error when reading configuration data
            [MBPreferencesController.sharedController.window presentError:error modalForWindow:MBPreferencesController.sharedController.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
        } else {
            // Release preferences window so buttons get enabled properly for the local client settings mode
            [self releasePreferencesWindow];

            // Pass saved credentials from the last loaded file to the Config File Manager
            self.configFileController.currentConfigPassword = _currentConfigPassword;
            self.configFileController.currentConfigPasswordIsHash = _currentConfigPasswordIsHash;
            self.configFileController.currentConfigKeyHash = _currentConfigFileKeyHash;
            
            // Decrypt and store the .seb config file
            [self.configFileController storeNewSEBSettings:sebData
                                                forEditing:YES
                                                  callback:self
                                                  selector:@selector(openingSEBPrefsSucessfull:)];
        }
    } else {
        // If using local client settings
        // Release preferences window so buttons get enabled properly for the local client settings mode
        [self releasePreferencesWindow];
        DDLogInfo(@"Reverting local client settings to settings before editing");
        [settingsBeforeEditing restoreSettings];
        
        // Re-initialize and open preferences window
        [self initPreferencesWindow];
        [self reopenPreferencesWindow];
    }
}


// Action using current preferences to create (new) exam settings
- (IBAction) createExamSettings:(id)sender
{
    if (!self.preferencesAreOpen) {
        return;
    }
    
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
        NSString *filename = currentConfigFilePath.lastPathComponent;
        filename = [[MyGlobals sharedMyGlobals] createUniqueFilename:filename intendedExtension:SEBFileExtension];
        NSString *extension = filename.pathExtension;
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:[[[currentConfigFilePath URLByDeletingLastPathComponent] URLByAppendingPathComponent:filename] URLByAppendingPathExtension:extension]];
    } else {
        
        /// If using local defaults
        
        // Release preferences window so bindings get synchronized properly with the new loaded values
        [self releasePreferencesWindow];
        
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:[NSURL fileURLWithPathString:SEBExamSettingsFilename]];
        
        // Get key/values from local shared client UserDefaults
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSDictionary *localClientPreferences = [preferences dictionaryRepresentationSEB];
        
        // Switch to private UserDefaults (saved non-persistantly in memory instead in ~/Library/Preferences)
        NSMutableDictionary *privatePreferences = [NSUserDefaults privateUserDefaults]; //the mutable dictionary has to be created here, otherwise the preferences values will not be saved!
        [NSUserDefaults setUserDefaultsPrivate:YES];
        
        [self.configFileController storeIntoUserDefaults:localClientPreferences];
        
        // Switch config purpose to "starting exam"
        [preferences setSecureInteger:sebConfigPurposeStartingExam forKey:@"org_safeexambrowser_SEB_sebConfigPurpose"];        
        DDLogVerbose(@"Private preferences set: %@", privatePreferences);
        
        [self resetBEKCK];
    }
    
    // Re-initialize and open preferences window
    [self initPreferencesWindow];
	[self reopenPreferencesWindow];
}


- (void) resetBEKCK
{
    [self.browserController resetBEKCK];
}


// Action configuring client with currently edited preferences
- (IBAction) configureClient:(id)sender
{
    if (!self.preferencesAreOpen) {
        return;
    }
    
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
    
    void (^configureClient)(BOOL) = ^void (BOOL correctPasswordEntered) {
        if (correctPasswordEntered) {
            // Get key/values from private UserDefaults
            NSDictionary *privatePreferences = [preferences dictionaryRepresentationSEB];
            
            // Release preferences window so buttons get enabled properly for the local client settings mode
            [self releasePreferencesWindow];
            
            // Switch to system's UserDefaults
            [NSUserDefaults setUserDefaultsPrivate:NO];

            // Write values from .seb config file to the local preferences (shared UserDefaults)
            [self.configFileController storeIntoUserDefaults:privatePreferences];
            
            [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
            
            [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
            
            // Re-initialize and open preferences window
            [self initPreferencesWindow];
            [self reopenPreferencesWindow];

        } else {
            [NSUserDefaults setUserDefaultsPrivate:YES];
        }
    };

    NSString *privateDefaultsHashedAdminPassword = [self.configFileController getHashedAdminPassword];

    // Switch to system's UserDefaults
    [NSUserDefaults setUserDefaultsPrivate:NO];
    NSString *hashedAdminPassword = [self.configFileController getHashedAdminPassword];
    //switch to private UserDefaults
    [NSUserDefaults setUserDefaultsPrivate:YES];
    // Check if the admin password from the current private defaults is the same as the one in client setting
    if ([privateDefaultsHashedAdminPassword caseInsensitiveCompare:hashedAdminPassword] != NSOrderedSame) {
        // If admin passwords differ, ask the user to enter the admin pw from client settings
        [self.configFileController promptPasswordForHashedPassword:hashedAdminPassword messageText:[NSString stringWithFormat:NSLocalizedString(@"Enter the %@ administrator password used in client settings:",nil), SEBShortAppName] title:NSLocalizedString(@"Configure Client",nil) completionHandler:configureClient];
    } else {
        configureClient(YES);
    }
}


// Action applying currently edited preferences, closing preferences window and restarting SEB
- (IBAction) applyAndRestartSEB:(id)sender
{
    if (!self.preferencesAreOpen) {
        return;
    }
    
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
    }
}


@end
