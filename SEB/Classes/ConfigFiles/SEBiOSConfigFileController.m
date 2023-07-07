//
//  SEBiOSConfigFileController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15/12/15.
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


#import <Availability.h>

#import "SEBiOSConfigFileController.h"

@implementation SEBiOSConfigFileController
{
    BOOL alertViewHasBeenDismissed;

}

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
    return _sebViewController.startingExamFromSEBServer;
}

// User logged in to LMS, monitoring the client started
- (BOOL) sebServerConnectionEstablished {
    return _sebViewController.sebServerConnectionEstablished;
}


- (void) willReconfigureTemporary {
    // Release preferences window so bindings get synchronized properly with the new loaded values
//    [self.sebController.preferencesController releasePreferencesWindow];
    
}


- (void) didReconfigureTemporaryForEditing:(BOOL)forEditing
                        sebFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials
{
    // Save settings password from the opened config file
    // for possible editing in InAppSettings
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (!sebFileCrentials.password) {
        sebFileCrentials.password = @"";
    }
    [preferences setSecureString:sebFileCrentials.password forKey:@"org_safeexambrowser_settingsPassword"];
    self.sebViewController.configFileKeyHash = sebFileCrentials.publicKeyHash;
}


- (void) didReconfigurePermanentlyForceConfiguringClient:(BOOL)forceConfiguringClient
                                      sebFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials
                                   showReconfiguredAlert:(BOOL)showReconfiguredAlert {
    if (!forceConfiguringClient) {

        if ([[MyGlobals sharedMyGlobals] finishedInitializing] && showReconfiguredAlert) {
            if (_sebViewController.alertController) {
                [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
            }
            _sebViewController.alertController = [UIAlertController  alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ Re-Configured", nil), SEBExtraShortAppName]
                                                                                      message:[NSString stringWithFormat:NSLocalizedString(@"New settings have been saved, they will also be used when you start %@ next time again.", nil), SEBShortAppName]
                                                                               preferredStyle:UIAlertControllerStyleAlert];
            [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", nil)
                                                                                   style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                                       self->_sebViewController.alertController = nil;
                                                                                       
                                                                                       // Inform callback that storing new settings was successful
                                                                                       [super storeNewSEBSettingsSuccessful:nil];
                                                                                   }]];
            
            [_sebViewController.topMostController presentViewController:_sebViewController.alertController animated:NO completion:nil];

        } else {
            
            if (showReconfiguredAlert) {
                // Set the flag to eventually display the dialog later
                [MyGlobals sharedMyGlobals].reconfiguredWhileStarting = YES;
            }
            // Inform callback that storing new settings was successful
            [super storeNewSEBSettingsSuccessful:nil];
        }
    } else {
        // Inform callback that storing new settings was successful
        [super storeNewSEBSettingsSuccessful:nil];
    }
    
    // Save settings password from the opened config file
    // for possible editing in InAppSettings
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (!sebFileCrentials.password) {
        sebFileCrentials.password = @"";
    }
    [preferences setSecureString:sebFileCrentials.password forKey:@"org_safeexambrowser_settingsPassword"];
	    self.sebViewController.configFileKeyHash = sebFileCrentials.publicKeyHash;
}


// Ask the user to enter a password for loading settings using the message text and then call the callback selector with the password as parameter
- (void) promptPasswordWithMessageText:(NSString *)messageText callback:(id)callback selector:(SEL)selector;
{
    [self promptPasswordWithMessageText:messageText title:NSLocalizedString(@"Loading Settings",nil) callback:callback selector:selector];
}


// Ask the user to enter a password using the message text and then call the callback selector with the password as parameter
- (void) promptPasswordWithMessageText:(NSString *)messageText title:(NSString *)titleString callback:(id)callback selector:(SEL)selector;
{
    if (_sebViewController.alertController) {
        [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _sebViewController.alertController = [UIAlertController alertControllerWithTitle:titleString
                                                                message:messageText
                                                         preferredStyle:UIAlertControllerStyleAlert];
    
    [_sebViewController.alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = NSLocalizedString(@"Password", nil);
         textField.secureTextEntry = YES;
     }];
    
    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                 NSString *password = self->_sebViewController.alertController.textFields.firstObject.text;
                                                                 if (!password) {
                                                                     password = @"";
                                                                 }
                                                                 self->_sebViewController.alertController = nil;
                                                                 IMP imp = [callback methodForSelector:selector];
                                                                 void (*func)(id, SEL, NSString*) = (void *)imp;
                                                                 func(callback, selector, password);
                                                             }]];
    
    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                             style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                                 self->_sebViewController.alertController = nil;
                                                                 // Return nil to callback method to indicate that cancel was pressed
                                                                 IMP imp = [callback methodForSelector:selector];
                                                                 void (*func)(id, SEL, NSString*) = (void *)imp;
                                                                 func(callback, selector, nil);
                                                             }]];
    
    [_sebViewController.topMostController presentViewController:_sebViewController.alertController animated:NO completion:nil];
}


- (void) showAlertWrongPassword {
    NSString *title = NSLocalizedString(@"Cannot Decrypt Settings", nil);
    NSString *informativeText = [NSString stringWithFormat:NSLocalizedString(@"You either entered the wrong password or these settings were saved with an incompatible %@ version.", nil), SEBShortAppName];
    [self showAlertWithTitle:title andText:informativeText];
}

- (void) showAlertCorruptedSettings {
    NSString *title = NSLocalizedString(@"Opening New Settings Failed!", nil);
    NSString *informativeText = [NSString stringWithFormat:NSLocalizedString(@"These settings cannot be used. They may have been created by an incompatible version of %@ or are corrupted.", nil), SEBShortAppName];
    [self showAlertWithTitle:title andText:informativeText];
}


- (void) showAlertWithError:(NSError *)error
{
    [_sebViewController showAlertWithError:error];
}


- (void) showAlertWithTitle:(NSString *)title
                    andText:(NSString *)informativeText
{
    [_sebViewController showAlertWithTitle:title andText:informativeText];
}


- (NSInteger) showAlertWithTitle:(NSString *)title text:(NSString *)informativeText cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_AVAILABLE(10_6, 4_0)
{
//    __block NSInteger pressedButtonIndex;
//    __block dispatch_semaphore_t generateNotificationsSemaphore;
//        UIAlertViewBlock *alertViewBlock = [[UIAlertViewBlock alloc] initWithTitle:title message:informativeText block:^(NSInteger buttonIndex)
//                               {
//                                   pressedButtonIndex = buttonIndex;
//                                   if (buttonIndex == alertViewBlock.cancelButtonIndex) {
//                                       NSLog(@"Cancel pressed");
//                                   }
//                                   else {
//                                       NSLog(@"Button with index %ld pressed", (long)buttonIndex);
//                                   }
//                                   
//                                   dispatch_semaphore_signal(generateNotificationsSemaphore);
//                               }
//                                                    cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles, nil];
//        
//        [alertViewBlock show];
//        
//    
//    return pressedButtonIndex;
    
    return 0;
    
//    self.alertController = [UIAlertController  alertControllerWithTitle:title
//                                                                message:informativeText
//                                                         preferredStyle:UIAlertControllerStyleAlert];
//    [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
//                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//                                                                 [self.alertController dismissViewControllerAnimated:NO completion:nil];
//                                                             }]];
//    
//    [self.sebViewController presentViewController:self.alertController animated:NO completion:nil];
}


- (BOOL) saveSettingsUnencrypted {
//    __block BOOL saveSettingsUnencrypted = true;
//    
//    if (_sebViewController.alertController) {
//        [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
//    }
//    _sebViewController.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"No Encryption Credentials Chosen", nil)
//                                                                message:[NSString stringWithFormat:@"%@\n\n%@", NSLocalizedString(@"The configuration file will be saved unencrypted, but compressed using gzip. To save a plain text config file in the Plist or .seb format, use the option MDM Managed Configuration.                      },", nil), NSLocalizedString(@"Recommended for higher security: Assessment systems using the Config Key or Browser Exam Key to verify the configuration.", nil)]
//                                                         preferredStyle:UIAlertControllerStyleAlert];
//    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
//                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//                                                                 [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
//
//                                                                 // Post a notification to switch to the Config File prefs pane
//                                                                 [[NSNotificationCenter defaultCenter]
//                                                                  postNotificationName:@"switchToConfigFilePane" object:self];
//                                                                 // don't save the config data
//                                                                 saveSettingsUnencrypted = false;
//                                                             }]];
//    
//    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Save unencrypted", nil)
//                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//                                                                 [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
//
//                                                                 // save .seb config data unencrypted
//                                                                 saveSettingsUnencrypted = true;
//                                                             }]];
//    
//    [_sebViewController presentViewController:_sebViewController.alertController animated:NO completion:nil];

    return true;
}


- (void) presentErrorAlert:(NSError *)error {
    [self showAlertWithError:error];
}

- (void)promptPasswordForHashedPassword:(NSString *)passwordHash messageText:(NSString *)messageText title:(NSString *)title attempts:(NSInteger)attempts callback:(id)callback selector:(SEL)aSelector completionHandler:(void (^)(BOOL))enteredPasswordHandler {

//    
}



@end
