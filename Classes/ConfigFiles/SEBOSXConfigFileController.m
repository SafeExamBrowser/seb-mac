//
//  SEBOSXConfigFileController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/11/15.
//
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
            if ([self storeDecryptedSEBSettings:sebData forEditing:NO forceConfiguringClient:YES]) {
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


- (void) didReconfigurePermanentlyForceConfiguringClient:(BOOL)forceConfiguringClient sebFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials {
    if (!forceConfiguringClient) {
        if ([[MyGlobals sharedMyGlobals] finishedInitializing]) {
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"SEB Re-Configured", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"Local settings of this SEB client have been reconfigured. Do you want to continue working with SEB now or quit?", nil)];
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


- (NSString *) promptPasswordWithMessageText:(NSString *)messageText {
    if ([self.sebController showEnterPasswordDialog:messageText modalForWindow:nil windowTitle:NSLocalizedString(@"Loading Settings",nil)] == SEBEnterPasswordCancel) {
        return nil;
    }
    NSString *password = [self.sebController.enterPassword stringValue];
    
    if (!password) {
        password = @"";
    }
    return password;
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
