//
//  PrefsExamViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.11.12.
//  Copyright (c) 2010-2017 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2017 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "PrefsExamViewController.h"
#import "SEBUIUserDefaultsController.h"
#import "SEBEncryptedUserDefaultsController.h"
#import "RNEncryptor.h"
#import "SEBCryptor.h"
#import "SEBKeychainManager.h"

@interface PrefsExamViewController ()

@end

@implementation PrefsExamViewController
@synthesize examKeyTextField;


- (NSString *)title
{
	return NSLocalizedString(@"Exam", @"Title of 'Exam' preference pane");
}


- (NSString *)identifier
{
	return @"ExamPane";
}


- (NSImage *)image
{
	return [NSImage imageNamed:@"ExamIcon"];
}


- (BOOL) usingPrivateDefaults {
    return NSUserDefaults.userDefaultsPrivate;
}


// Delegate called before the Exam settings preferences pane will be displayed
- (void)willBeDisplayed {
    // Check if current settings have unsaved changes
    if (NSUserDefaults.userDefaultsPrivate && [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:!NSUserDefaults.userDefaultsPrivate
                                                        updateSalt:NO]) {
        // There are unsaved changes and private UserDefaults are active
        [self browserExamKeyChanged];
    } else {
        // There are no unsaved changes or local client settings are active
        [self displayBrowserExamKey];
        [self displayConfigKey];
    }
}

- (void)willBeHidden {
//    [examKey setStringValue:@""];
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) useBrowserExamKey:(NSButton *)sender
{
    examKeyTextField.enabled = [sender state];
    configKeyTextField.enabled = [sender state];
    copyBEKToClipboard.enabled = [sender state];
    [self displayMessageOrReGenerateKey];
}


- (IBAction) generateKeys:(id)sender {
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    [self displayBrowserExamKey];
    [self displayConfigKey];
}


- (void)displayKey:(NSData *)keyData keyTextField:(NSTextField *)keyTextField {
    unsigned char hashedChars[32];
    [keyData getBytes:hashedChars length:32];
    
    NSMutableString* hashedString = [[NSMutableString alloc] init];
    for (int i = 0 ; i < 32 ; ++i) {
        [hashedString appendFormat: @"%02x", hashedChars[i]];
    }
    [keyTextField setStringValue:hashedString];
}

- (void)displayBrowserExamKey
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *browserExamKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
    [self displayKey:browserExamKey keyTextField:examKeyTextField];
}

- (void)displayConfigKey
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *configKey = [preferences secureObjectForKey:@"org_safeexambrowser_configKey"];
    [self displayKey:configKey keyTextField:configKeyTextField];
}


- (IBAction)restartExamUseStartURL:(NSButton *)sender {
    restartExamURLTextField.enabled = ![sender state];
    [self displayMessageOrReGenerateKey];
}


- (void)browserExamKeyChanged
{
    // There are unsaved changes: Display message instead of Browser Exam Key
    [examKeyTextField setStringValue:NSLocalizedString(@"Save settings to display its Browser Exam Key", nil)];
    [configKeyTextField setStringValue:NSLocalizedString(@"Save settings to display its Config Key", nil)];
}


- (IBAction) restartExamPasswordProtected:(id)sender {
    [self displayMessageOrReGenerateKey];
}


- (void)displayMessageOrReGenerateKey
{
    if (NSUserDefaults.userDefaultsPrivate) {
        // Private UserDefaults are active: Check if there are unsaved changes
        if ([[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
            // Yes: Display message instead of Browser Exam Key
            [self browserExamKeyChanged];
        } else {
            // No, there are no unsaved changes: Display the key again
            [self displayBrowserExamKey];
            [self displayConfigKey];
        }
    } else {
        // Local client settings are active: Re-generate key
        [self generateKeys:self];
    }
}


@end
