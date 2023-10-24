//
//  SEBOSXConfigFileController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/11/15.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBOSXConfigFileController.h"
#import "MBPreferencesController.h"

@implementation SEBOSXConfigFileController


-(id) init
{
    self = [super init];
    if (self) {
        
        [super setDelegate:self];
}
    return self;
}


// Exam URL is opened in a webview (tab), waiting for user to log in
- (BOOL) startingExamFromSEBServer {
    return _sebController.startingExamFromSEBServer;
}

// User logged in to LMS, monitoring the client started
- (BOOL) sebServerConnectionEstablished {
    return _sebController.sebServerConnectionEstablished;
}


/// Load a SebClientSettings.seb file saved in the preferences directory
- (NSData *) getSEBClientSettings
{
    NSData *sebData;
    
    // Try to read SEB client settings from /Library/Preferences/ directory,
    // valid for all users on a Mac
    sebData = [self getSEBClientSettingsFromDomain:NSLocalDomainMask];
    
    if (!sebData) {
        // Try to read SEB client settings from ~Library/Preferences/ directory,
        // valid for the current user
        sebData = [self getSEBClientSettingsFromDomain:NSUserDomainMask];
    }
    
    return sebData;
}


- (NSData *) getSEBClientSettingsFromDomain:(NSSearchPathDomainMask)domain
{
    NSError *error;
    NSData *sebData;
    NSURL *libraryDirectory = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory
                                                                          inDomain:domain
                                                                 appropriateForURL:nil
                                                                            create:NO
                                                                             error:&error];
    if (libraryDirectory) {
        NSURL *sebClientSettingsFileURL = [[libraryDirectory URLByAppendingPathComponent:SEBClientSettingsDirectory] URLByAppendingPathComponent:SEBClientSettingsFilename];
        sebData = [NSData dataWithContentsOfURL:sebClientSettingsFileURL];
        if (sebData && domain == NSUserDomainMask) {
            // Delete the SEBClientSettings.seb file from the user's Preferences directory
            error = nil;
            [[NSFileManager defaultManager] removeItemAtURL:sebClientSettingsFileURL error:&error];
            DDLogInfo(@"Attempted to remove file %@, result: %@", sebClientSettingsFileURL, error.description);
        }
    }
    return sebData;
}


/// Called after the client was sucesssfully reconfigured with persisted client settings
- (void) reconfigureClientWithSebClientSettingsCallback
{
    DDLogInfo(@"Reconfiguring with client settings was successful");
    // Restart SEB with new settings
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestRestartNotification" object:self];
}


- (void) willReconfigureTemporary {
    // Release preferences window so bindings get synchronized properly with the new loaded values
    [self.sebController.preferencesController releasePreferencesWindow];
    
}


- (void) didReconfigureTemporaryForEditing:(BOOL)forEditing sebFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials {
    // Reset SEB, close third party applications
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    PreferencesController *prefsController = self.sebController.preferencesController;

    // If editing mode or opening the preferences window is allowed
    if (forEditing || [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"]) {
        // we store the .seb file password/hash and/or certificate/identity
        [prefsController setCurrentConfigPassword:sebFileCrentials.password];
        [prefsController setCurrentConfigPasswordIsHash:sebFileCrentials.passwordIsHash];
        [prefsController setCurrentConfigFileKeyHash:sebFileCrentials.publicKeyHash];
    }
    // Update Browser Exam Key
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    if (!([prefsController preferencesAreOpen] || self.sebController.alternateKeyPressed)) {
        [prefsController initPreferencesWindow];
    }
}


- (void) didReconfigurePermanentlyForceConfiguringClient:(BOOL)forceConfiguringClient
                                      sebFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials
                                   showReconfiguredAlert:(BOOL)showReconfiguredAlert {
    if (!forceConfiguringClient && showReconfiguredAlert) {
        if ([[MyGlobals sharedMyGlobals] finishedInitializing]) {
            NSAlert *newAlert = [self.sebController newAlert];
            [newAlert setMessageText:NSLocalizedString(@"SEB Re-Configured", @"")];
            [newAlert setInformativeText:NSLocalizedString(@"New settings have been saved, they will also be used when you start SEB next time again. Do you want to start working with SEB or quit for now?", @"")];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Continue", @"")];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Quit", @"")];
            void (^alertOKHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                [self.sebController removeAlertWindow:newAlert.window];
                switch(answer)
                {
                    case NSAlertFirstButtonReturn:
                        
                        //Continue running SEB
                        [self didReconfigurePermanentlyWithSEBFileCredentials:sebFileCrentials];
                        return;
                        
                    case NSAlertSecondButtonReturn:
                        
                        [self.sebController requestedExit:nil]; // Quit SEB
                        return;
                }
            };
            [self.sebController runModalAlert:newAlert conditionallyForWindow:self.sebController.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))alertOKHandler];
            return;

        } else {
            // Set the flag to eventually display the dialog later
            [MyGlobals sharedMyGlobals].reconfiguredWhileStarting = YES;
        }
    }
    [self didReconfigurePermanentlyWithSEBFileCredentials:sebFileCrentials];
}

- (void) didReconfigurePermanentlyWithSEBFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    PreferencesController *prefsController = self.sebController.preferencesController;

    // If opening the preferences window is allowed
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"]) {
        // we store the .seb file password/hash and/or certificate/identity
        [prefsController setCurrentConfigPassword:sebFileCrentials.password];
        [prefsController setCurrentConfigPasswordIsHash:sebFileCrentials.passwordIsHash];
        [prefsController setCurrentConfigFileKeyHash:sebFileCrentials.publicKeyHash];
    }
    // Update Browser Exam Key
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    [prefsController initPreferencesWindow];

    // Inform callback that storing new settings was successful
    [self storeNewSEBSettingsSuccessful:nil];
}


- (void) showAlertWrongPassword {
    NSString *title = NSLocalizedString(@"Cannot Decrypt Settings", @"");
    NSString *informativeText = NSLocalizedString(@"You either entered the wrong password or these settings were saved with an incompatible SEB version.", @"");
    [self showAlertWithTitle:title andText:informativeText];
}

- (void) showAlertCorruptedSettings {
    NSString *title = NSLocalizedString(@"Opening New Settings Failed!", @"");
    NSString *informativeText = NSLocalizedString(@"These settings cannot be used. They may have been created by an incompatible version of SEB or are corrupted.", @"");
    [self showAlertWithTitle:title andText:informativeText];
}

- (void) showAlertWithTitle:(NSString *)title andText:(NSString *)informativeText {
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:title];
    [newAlert setInformativeText:informativeText];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
    [newAlert setAlertStyle:NSAlertStyleCritical];
    [self.sebController runModalAlert:newAlert conditionallyForWindow:self.sebController.browserController.mainBrowserWindow completionHandler:nil];
}


- (BOOL) saveSettingsUnencryptedUncompressed:(BOOL)uncompressed;
 {
    NSAlert *newAlert = [self.sebController newAlert];
    [newAlert setMessageText:NSLocalizedString(@"No Encryption Credentials Chosen", @"")];
     
     [newAlert setInformativeText:[NSString stringWithFormat:@"%@%@\n\n%@", NSLocalizedString(@"The configuration will be saved unencrypted", @""), uncompressed ? @"." : NSLocalizedString(@", but compressed using gzip.", @""), NSLocalizedString(@"Recommended for higher security: Assessment systems using the Config Key or Browser Exam Key to verify the configuration.", @"")]];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
    [newAlert setAlertStyle:NSAlertStyleWarning];
    BOOL (^unencryptedSaveAlertAnswerHandler)(NSModalResponse) = ^BOOL (NSModalResponse answer) {
        [self.sebController removeAlertWindow:newAlert.window];
        switch(answer)
        {
            case NSAlertFirstButtonReturn:
                // Post a notification to switch to the Config File prefs pane
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"switchToConfigFilePane" object:self];
                // don't save the config data
                return NO;
                
            case NSAlertSecondButtonReturn:
                // save .seb config data unencrypted
                return YES;
                
            default:
                return NO;
        }
    };
    if (@available(macOS 12.0, *)) {
    } else {
        if (@available(macOS 11.0, *)) {
            if (self.sebController.isAACEnabled || self.sebController.wasAACEnabled) {
                [newAlert beginSheetModalForWindow:MBPreferencesController.sharedController.window completionHandler:(void (^)(NSModalResponse answer))unencryptedSaveAlertAnswerHandler];
                return YES;
            }
        }
    }
    [newAlert addButtonWithTitle:NSLocalizedString(@"Save Unencrypted", @"")];
    NSModalResponse answer = [newAlert runModal];
    return unencryptedSaveAlertAnswerHandler(answer);
}


// Ask the user to enter a password for loading settings using the message text and then call the callback selector with the password as parameter
- (void) promptPasswordWithMessageText:(NSString *)messageText callback:(id)callback selector:(SEL)selector;
{
    [self promptPasswordWithMessageText:messageText
                                  title:NSLocalizedString(@"Loading Settings",nil)
                               callback:callback
                               selector:selector];
}


- (void)promptPasswordWithMessageText:(NSString *)messageText
                                title:(NSString *)title
                             callback:(id)callback
                             selector:(SEL)selector
{
    NSString *password = nil;
    if ([self.sebController showEnterPasswordDialog:messageText modalForWindow:nil windowTitle:title] == SEBEnterPasswordOK) {
        password = [self.sebController.enterPassword stringValue];
    }
    IMP imp = [callback methodForSelector:selector];
    void (*func)(id, SEL, NSString*) = (void *)imp;
    func(callback, selector, password);
}


- (void) promptPasswordForHashedPassword:(NSString *)passwordHash
                             messageText:(NSString *)messageText
                                   title:(NSString *)title
                                attempts:(NSInteger)attempts
                                callback:(id)callback
                                selector:(SEL)selector
                       completionHandler:(void (^)(BOOL correctPasswordEntered))enteredPasswordHandler
{
    NSString *password = nil;
    if ([self.sebController showEnterPasswordDialog:messageText modalForWindow:nil windowTitle:title] == SEBEnterPasswordOK) {
        password = [self.sebController.enterPassword stringValue];
    }
    IMP imp = [callback methodForSelector:selector];
    void (*func)(id, SEL, NSString*, NSString*, NSString*, NSString*, NSInteger, void (^)(BOOL)) = (void *)imp;
    func(callback, selector, password, passwordHash, messageText, title, attempts, enteredPasswordHandler);
}


- (NSString *) promptPasswordWithMessageTextModal:(NSString *)messageText
                                            title:(NSString *)title
{
    NSString *password = nil;
    if ([self.sebController showEnterPasswordDialog:messageText modalForWindow:nil windowTitle:title] == SEBEnterPasswordOK) {
        password = [self.sebController.enterPassword stringValue];
    }
    return password;
}


- (void)showAlertWithError:(NSError *)error {
    [self presentErrorAlert:error];
}

- (void)presentErrorAlert:(NSError *)error {
    [self.sebController.browserController.mainBrowserWindow presentError:error modalForWindow:self.sebController.browserController.mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
}


@end
