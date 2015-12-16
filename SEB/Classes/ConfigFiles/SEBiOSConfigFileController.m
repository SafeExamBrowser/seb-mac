//
//  SEBiOSConfigFileController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15/12/15.
//
//

#import "SEBiOSConfigFileController.h"

@implementation SEBiOSConfigFileController

-(id) init
{
    self = [super init];
    if (self) {
        
        [super setDelegate:self];

        self.sebViewController = (SEBViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
}
    return self;
}


- (void) willReconfigureTemporary {
    // Release preferences window so bindings get synchronized properly with the new loaded values
//    [self.sebController.preferencesController releasePreferencesWindow];
    
}


- (void) didReconfigureTemporaryForEditing:(BOOL)forEditing sebFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials {
    // Reset SEB, close third party applications
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    PreferencesController *prefsController = self.sebController.preferencesController;
    
    // If editing mode or opening the preferences window is allowed
    if (forEditing || [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"]) {
        // we store the .seb file password/hash and/or certificate/identity
//        [prefsController setCurrentConfigPassword:sebFileCrentials.password];
//        [prefsController setCurrentConfigPasswordIsHash:sebFileCrentials.passwordIsHash];
//        [prefsController setCurrentConfigKeyRef:sebFileCrentials.keyRef];
    }
    
//    [prefsController initPreferencesWindow];
}


- (void) didReconfigurePermanentlyForceConfiguringClient:(BOOL)forceConfiguringClient sebFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials {
    if (!forceConfiguringClient) {

        if ([[MyGlobals sharedMyGlobals] finishedInitializing]) {
            
            self.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"SEB Re-Configured", nil)
                                                                        message:NSLocalizedString(@"Local settings of this SEB client have been reconfigured.", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
            [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", nil)
                                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                               [self.alertController dismissViewControllerAnimated:YES completion:nil];
                                                                               
//                                                                               [self startExam];
                                                                           }]];
            
            [self.sebViewController presentViewController:self.alertController animated:YES completion:nil];

        } else {
            // Set the flag to eventually display the dialog later
            [MyGlobals sharedMyGlobals].reconfiguredWhileStarting = YES;
        }
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        NSDate *date;
        while ([self.alertController isBeingPresented]) {
            date = [[NSDate alloc] init];
            [runLoop runUntilDate:date];
        }
    }
    
//    PreferencesController *prefsController = self.sebController.preferencesController;
//    
//    // If opening the preferences window is allowed
//    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"]) {
//        // we store the .seb file password/hash and/or certificate/identity
//        [prefsController setCurrentConfigPassword:sebFileCrentials.password];
//        [prefsController setCurrentConfigPasswordIsHash:sebFileCrentials.passwordIsHash];
//        [prefsController setCurrentConfigKeyRef:sebFileCrentials.keyRef];
//    }
    
//    [prefsController initPreferencesWindow];
}


- (NSString *) promptPasswordWithMessageText:(NSString *)messageText
{
//    alertButtonIndex = -1;
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Loading Settings",nil)
//                                                        message:messageText
//                                                       delegate:self
//                                              cancelButtonTitle:@"Cancel"
//                                              otherButtonTitles:@"Ok", nil];
//    alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
//    UITextField *passwordTextField = [alertView textFieldAtIndex:0];
//    [alertView show];
//    
//    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
//    NSDate *date;
//    while (alertButtonIndex < 0) {
//        date = [[NSDate alloc] init];
//        [runLoop runUntilDate:date];
//    }
//
//    if (alertButtonIndex == 0) {
//        return nil;
//    }
//
//    NSString *password = passwordTextField.text;
//    
//    if (!password) {
//        password = @"";
//    }
//    return password;
    return @"seb";
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    alertButtonIndex = buttonIndex;
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
    self.alertController = [UIAlertController  alertControllerWithTitle:title
                                                                message:informativeText
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                 [self.alertController dismissViewControllerAnimated:YES completion:nil];
                                                             }]];
    
    [self.sebViewController presentViewController:self.alertController animated:YES completion:nil];
}


- (BOOL) saveSettingsUnencrypted {
    __block BOOL saveSettingsUnencrypted;
    
    self.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"No Encryption Credentials Chosen", nil)
                                                                message:NSLocalizedString(@"You should either enter a password or choose a cryptographic identity to encrypt the SEB settings file.\n\nYou can save an unencrypted settings file, but this is not recommended for use in exams.", nil)
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                 [self.alertController dismissViewControllerAnimated:YES completion:nil];
                                                                 // Post a notification to switch to the Config File prefs pane
                                                                 [[NSNotificationCenter defaultCenter]
                                                                  postNotificationName:@"switchToConfigFilePane" object:self];
                                                                 // don't save the config data
                                                                 saveSettingsUnencrypted = false;
                                                             }]];
    
    [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Save unencrypted", nil)
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                 [self.alertController dismissViewControllerAnimated:YES completion:nil];
                                                                 // save .seb config data unencrypted
                                                                 saveSettingsUnencrypted = true;
                                                             }]];
    
    [self.sebViewController presentViewController:self.alertController animated:YES completion:nil];

    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    NSDate *date;
    while ([self.alertController isBeingPresented]) {
        date = [[NSDate alloc] init];
        [runLoop runUntilDate:date];
    }
    return saveSettingsUnencrypted;
}


- (void) presentErrorAlert:(NSError *)error {
//    [NSApp presentError:error];
}


@end
