//
//  SEBOSXConfigFileController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/11/15.
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

#import "SEBOSXConfigFileController.h"

@implementation SEBOSXConfigFileController


-(id) init
{
    self = [super init];
    if (self) {
        self.sebController = (SEBController *)[NSApp delegate];
        
        [super setDelegate:self];
    }
    return self;
}


// Load a SebClientSettings.seb file saved in the preferences directory
// and if it existed and was loaded, use it to re-configure SEB
- (BOOL) reconfigureClientWithSebClientSettings
{
    NSError *error;
    NSURL *preferencesDirectory = [[NSFileManager defaultManager] URLForDirectory:NSLibraryDirectory
                                                                         inDomain:NSUserDomainMask
                                                                appropriateForURL:nil
                                                                           create:NO
                                                                            error:&error];
    if (preferencesDirectory) {
        NSURL *sebClientSettingsFileURL = [preferencesDirectory URLByAppendingPathComponent:@"Preferences/SebClientSettings.seb"];
        NSData *sebData = [NSData dataWithContentsOfURL:sebClientSettingsFileURL];
        if (sebData) {
            DDLogInfo(@"Reconfiguring SEB with SebClientSettings.seb from Preferences directory");
            //            SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
            
            // Decrypt and store the .seb config file
            if ([self storeNewSEBSettings:sebData forEditing:NO forceConfiguringClient:YES]) {
                // if successfull continue with new settings
                DDLogInfo(@"Reconfiguring SEB with SebClientSettings.seb was successful");
                // Delete the SebClientSettings.seb file from the Preferences directory
                error = nil;
                [[NSFileManager defaultManager] removeItemAtURL:sebClientSettingsFileURL error:&error];
                DDLogInfo(@"Attempted to remove SebClientSettings.seb from Preferences directory, result: %@", error.description);
                // Restart SEB with new settings
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"requestRestartNotification" object:self];
                
                return YES;
            }
        }
    }
    return NO;
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
        [prefsController setCurrentConfigKeyRef:sebFileCrentials.keyRef];
    }
    
    [prefsController initPreferencesWindow];
}


- (void) didReconfigurePermanentlyForceConfiguringClient:(BOOL)forceConfiguringClient
                                      sebFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials
                                   showReconfiguredAlert:(BOOL)showReconfiguredAlert {
    if (!forceConfiguringClient && showReconfiguredAlert) {
        if ([[MyGlobals sharedMyGlobals] finishedInitializing]) {
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"SEB Re-Configured", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"New settings have been saved, they will also be used when you start SEB next time again. Do you want to start working with SEB or quit for now?", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
            int answer = [newAlert runModal];
            switch(answer)
            {
                case NSAlertFirstButtonReturn:
                    
                    break; //Continue running SEB
                    
                case NSAlertSecondButtonReturn:
                    
                    self.sebController.quittingMyself = TRUE; //SEB is terminating itself
                    [NSApp terminate: nil]; //quit SEB
            }
        } else {
            // Set the flag to eventually display the dialog later
            [MyGlobals sharedMyGlobals].reconfiguredWhileStarting = YES;
        }
    }

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    PreferencesController *prefsController = self.sebController.preferencesController;

    // If opening the preferences window is allowed
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"]) {
        // we store the .seb file password/hash and/or certificate/identity
        [prefsController setCurrentConfigPassword:sebFileCrentials.password];
        [prefsController setCurrentConfigPasswordIsHash:sebFileCrentials.passwordIsHash];
        [prefsController setCurrentConfigKeyRef:sebFileCrentials.keyRef];
    }
    
    [prefsController initPreferencesWindow];
}


- (void) showAlertWrongPassword {
    NSString *title = NSLocalizedString(@"Cannot Decrypt Settings", nil);
    NSString *informativeText = NSLocalizedString(@"You either entered the wrong password or these settings were saved with an incompatible SEB version.", nil);
    [self showAlertWithTitle:title andText:informativeText];
}

- (void) showAlertCorruptedSettings {
    NSString *title = NSLocalizedString(@"Opening New Settings Failed!", nil);
    NSString *informativeText = NSLocalizedString(@"These settings cannot be used. They may have been created by an incompatible version of SEB or are corrupted.", nil);
    [self showAlertWithTitle:title andText:informativeText];
}

- (void) showAlertWithTitle:(NSString *)title andText:(NSString *)informativeText {
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:title];
    [newAlert setInformativeText:informativeText];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [newAlert setAlertStyle:NSCriticalAlertStyle];
    [newAlert runModal];
}


- (BOOL) saveSettingsUnencrypted {
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"No Encryption Credentials Chosen", nil)];
    [newAlert setInformativeText:NSLocalizedString(@"You should either enter a password or choose a cryptographic identity to encrypt the SEB settings file.\n\nYou can save an unencrypted settings file, but this is not recommended for use in exams.", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Save unencrypted", nil)];
    [newAlert setAlertStyle:NSWarningAlertStyle];
    int answer = [newAlert runModal];
    
    switch(answer)
    {
        case NSAlertFirstButtonReturn:
            // Post a notification to switch to the Config File prefs pane
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"switchToConfigFilePane" object:self];
            // don't save the config data
            return false;
            
        case NSAlertSecondButtonReturn:
            // save .seb config data unencrypted
            return true;
            
        default:
            return false;
    }
}


- (void) presentErrorAlert:(NSError *)error {
    [NSApp presentError:error];
}


@end
