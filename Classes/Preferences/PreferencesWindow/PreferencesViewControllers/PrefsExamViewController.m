//
//  PrefsExamViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.11.12.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
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


- (void)awakeFromNib {
    [self scrollToTop:_scrollView];
}


// Delegate called before the Exam settings preferences pane will be displayed
- (void)willBeDisplayed {
    [self displayMessageOrReGenerateKey];
}

- (void)willBeHidden {
//    [examKey setStringValue:@""];
}


- (SEBBrowserController *)browserController {
    if (!_browserController) {
        _browserController = _preferencesController.browserController;
    }
    return _browserController;
}


#pragma mark -
#pragma mark Action methods to recalculate and display new keys/message for key changed when
#pragma mark one of the settings in the Exam Pane is changed and private user defaults are active

// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction)useBrowserExamKey:(NSButton *)sender
{
    examKeyTextField.enabled = [sender state];
    configKeyTextField.enabled = [sender state];
    copyBEKToClipboard.enabled = [sender state];
    [self displayMessageOrReGenerateKey];
}


- (IBAction)generateKeys:(id)sender {
    [self displayMessageOrReGenerateKey];
}


- (IBAction)restartExamUseStartURL:(NSButton *)sender {
    restartExamURLTextField.enabled = ![sender state];
    [self displayMessageOrReGenerateKey];
}


#pragma mark -
#pragma mark Methods to recalculate and display new keys/message for key changed


- (void) displayUpdatedKeys
{
    [self displayMessageOrReGenerateKey];
}


- (void)displayMessageOrReGenerateKey
{
    BOOL settingsChanged = [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO];
    DDLogDebug(@"%s settings changed: %hhd", __FUNCTION__, settingsChanged);
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (NSUserDefaults.userDefaultsPrivate) {
        // Private UserDefaults are active: Check if there are unsaved changes
        if (settingsChanged) {
            self.browserController.browserExamKey = nil;
            self.browserController.configKey = nil;
            // Force recalculating Config Key
            [preferences setSecureObject:[NSData data] forKey:@"org_safeexambrowser_configKey"];
            [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
            // Yes: Display message instead of Browser Exam Key
            [self displayMessageKeyChanged];
        } else {
            // No, there are no unsaved changes: Display current keys
            [self displayBrowserExamKey];
            [self displayConfigKey];
        }
    } else {
        // Local client settings are active: If settings changed, re-generate keys
        if (settingsChanged) {
            // Also reset (it will be re-generated) the dictionary containing all keys which
            // were used to calculate the Config Key. When a config is changed, all keys of
            // the current SEB version should be used to re-calculate the Config Key
            [preferences setSecureObject:[NSDictionary dictionary]
                                  forKey:@"org_safeexambrowser_configKeyContainedKeys"];
            self.browserController.browserExamKey = nil;
            self.browserController.configKey = nil;
            // Force recalculating Config Key
            [preferences setSecureObject:[NSData data] forKey:@"org_safeexambrowser_configKey"];
            [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
        }
        // Display updated or current keys
        [self displayBrowserExamKey];
        [self displayConfigKey];
    }
}


- (void)displayBrowserExamKey
{
    NSData *browserExamKey = self.browserController.browserExamKey;
    [self displayKeyHash:browserExamKey keyTextField:examKeyTextField];
}


- (void)displayConfigKey
{
    NSData *configKey = self.browserController.configKey;
    [self displayKeyHash:configKey keyTextField:configKeyTextField];
}


- (void)displayKeyHash:(NSData *)keyData keyTextField:(NSTextField *)keyTextField {
    unsigned char hashedChars[32];
    [keyData getBytes:hashedChars length:32];
    
    NSMutableString* hashedString = [[NSMutableString alloc] init];
    for (int i = 0 ; i < 32 ; ++i) {
        [hashedString appendFormat: @"%02x", hashedChars[i]];
    }
    [keyTextField setStringValue:hashedString];
}


- (void)displayMessageKeyChanged
{
    // There are unsaved changes in private user defaults: Display message instead of Keys
    [examKeyTextField setStringValue:NSLocalizedString(@"Save settings to display its Browser Exam Key", @"")];
    [configKeyTextField setStringValue:NSLocalizedString(@"Save settings to display its Config Key", @"")];
}


@end
