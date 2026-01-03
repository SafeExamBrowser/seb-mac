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


#import "PrefsConfigFileViewController.h"
#import "SEBUIUserDefaultsController.h"
#import "SEBEncryptedUserDefaultsController.h"
#import "SEBOSXConfigFileController.h"
#import "RNEncryptor.h"
#import "SEBCryptor.h"

@interface PrefsConfigFileViewController ()

@end

@implementation PrefsConfigFileViewController
@synthesize identitiesNames;
@synthesize identities;

@synthesize keychainManager;


- (NSString *)title
{
	return NSLocalizedString(@"Configuration", @"Title of 'Configuration' preference pane");
}


- (NSString *)identifier
{
	return @"ConfigFilePane";
}


- (NSImage *)image
{
	return [NSImage imageNamed:@"sebConfigIcon"];
}


- (void) awakeFromNib
{
    
}


- (SEBKeychainManager *) keychainManager
{
    if (!keychainManager) {
        keychainManager = [[SEBKeychainManager alloc] init];
    }
    return keychainManager;
}


- (void) setSettingsPassword:(NSString *)password isHash:(BOOL)passwordIsHash
{
    _currentConfigFilePassword = password;
    self.configPasswordIsHash = passwordIsHash;
    // This initializes password text fields and the identity menu according to those passed values
//    [self willBeDisplayed];
}


// Getter methods for write-only properties

- (NSString *)currentConfigFilePassword {
    [NSException raise:NSInternalInconsistencyException
                format:@"property is write-only"];
    return nil;
}

- (NSData *)currentConfigFileKeyHash {
    [NSException raise:NSInternalInconsistencyException
                format:@"property is write-only"];
    return nil;
}


// Definitition of the dependent keys for comparing settings passwords
+ (NSSet *)keyPathsForValuesAffectingCompareSettingsPasswords {
    return [NSSet setWithObjects:@"settingsPassword", @"confirmSettingsPassword", nil];
}


// Method called by the bindings object controller for comparing the settings passwords
- (NSString*) compareSettingsPasswords {
	if ((settingsPassword != nil) | (confirmSettingsPassword != nil)) {
        
        // If the flag is set for password fields contain a placeholder
        // instead of the hash loaded from settings (no cleartext password)
        if (self.configPasswordIsHash)
        {
            if (![settingsPassword isEqualToString:confirmSettingsPassword])
            {
                // and when the password texts aren't the same anymore, this means the user tries to edit the password
                // (which is only the placeholder right now), we have to clear the placeholder from the textFields
                [self resetSettingsPasswordFields];
                return nil;
            }
        } else {
            // Password fields contain actual passwords, not the placeholder for a hash value
            if (![settingsPassword isEqualToString:confirmSettingsPassword]) {
                //if the two passwords don't match, show it in the label
                return (NSString*)([NSString stringWithString:NSLocalizedString(@"Please enter correct confirm password", @"")]);
            }
        }
    }
    return nil;
}


// Reset the settings password and confirm password fields and the identity popup menu
- (void) resetSettingsPasswordFields
{
    _currentConfigFilePassword = nil;
    self.configPasswordIsHash = false;
    [self setValue:nil forKey:@"settingsPassword"];
    [self setValue:nil forKey:@"confirmSettingsPassword"];
    [settingsPasswordField setStringValue:@""];
    [confirmSettingsPasswordField setStringValue:@""];
}


// Reset the settings password and confirm password fields and the identity popup menu
- (void) resetSettingsIdentity
{
    _currentConfigFileKeyHash = nil;
    [chooseIdentity selectItemAtIndex:0];
}


- (BOOL) usingPrivateDefaults {
    return NSUserDefaults.userDefaultsPrivate;
}


// Return YES if currently opened settings are loaded from a file
- (BOOL) editingSettingsFile {
    return [self.preferencesController editingSettingsFile];
}


// Delegate called before the Exam settings preferences pane will be displayed
- (void)willBeDisplayed {
    if (!self.identitiesNames) { //no identities available yet, get them from keychain
        NSArray *names;
        NSArray *identitiesInKeychain = [self.keychainManager getIdentitiesAndNames:&names];
        self.identities = identitiesInKeychain;
        self.identitiesNames = [names copy];
        [chooseIdentity removeAllItems];
        //first put "None" item in popupbutton list
        [chooseIdentity addItemWithTitle:NSLocalizedString(@"None", @"")];
        [chooseIdentity addItemsWithTitles: self.identitiesNames];
    }
    
    // Set the settings password correctly
    // If the settings password from the currently open config file contains a hash (and it isn't empty)
    if (self.configPasswordIsHash && _currentConfigFilePassword.length > 0)
    {
        // CAUTION: We need to reset this flag BEFORE changing the textBox text value,
        // because otherwise the compare passwords method will delete the first textBox again.
        self.configPasswordIsHash = false;
        [self setValue:@"0000000000000000" forKey:@"settingsPassword"];
        self.configPasswordIsHash = true;
        [self setValue:@"0000000000000000" forKey:@"confirmSettingsPassword"];
    }
    // Otherwise if there is a settings password from the currently open config file
    else if (_currentConfigFilePassword)
    {
        [self setValue:_currentConfigFilePassword forKey:@"settingsPassword"];
        [self setValue:_currentConfigFilePassword forKey:@"confirmSettingsPassword"];
        // Reset the password string from the currently open config file
        _currentConfigFilePassword = nil;
    }
    
    // If there is a identity reference from the currently open config file
    if (_currentConfigFileKeyHash) {
        [self selectSettingsIdentity:_currentConfigFileKeyHash];
        _currentConfigFileKeyHash = nil;
    }
}


// Method invoked when switching from this one to another tab
- (void)willBeHidden
{
    // If settings password is confirmed
    if (![self compareSettingsPasswords]) {
        _currentConfigFilePassword = settingsPassword;
        _currentConfigFileKeyHash = [self.keychainManager getPublicKeyHashFromIdentity:[self getSelectedIdentity]];;
    } else {
        // if it's not confirmed properly, then clear the settings password textFields
        [self resetSettingsPasswordFields];
    }
}


- (void) revertLastSavedButtonSetEnabled:(id)sender
{
    revertLastFileButton.enabled = [self editingSettingsFile];
}

// Get selected config purpose
- (sebConfigPurposes) getSelectedConfigPurpose
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    sebConfigPurposes configPurpose = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebConfigPurpose"];
    return configPurpose;
}


// Select identity for passed identity reference
- (void) selectSettingsIdentity:(NSData *)settingsPublicKeyHash
{
    [chooseIdentity selectItemAtIndex:0];
    
    if (settingsPublicKeyHash) {
        NSUInteger i, count = [self.identities count];
        for (i=0; i<count; i++) {
            SecIdentityRef identityFromKeychain = (__bridge SecIdentityRef)self.identities[i];
            NSData *publicKeyHash = [self.keychainManager getPublicKeyHashFromIdentity:identityFromKeychain];
            if ([settingsPublicKeyHash isEqualToData:publicKeyHash]) {
                [chooseIdentity selectItemAtIndex:i+1];
                break;
            }
        }
    }
}


// Get SecIdentityRef for selected identity
- (SecIdentityRef) getSelectedIdentity
{
    SecIdentityRef identityRef = nil;
    if ([chooseIdentity indexOfSelectedItem]) {
        // If an identity is selected, then we get the according SecIdentityRef
        NSInteger selectedIdentity = [chooseIdentity indexOfSelectedItem]-1;
        identityRef = (__bridge SecIdentityRef)([self.identities objectAtIndex:selectedIdentity]);
    }
    return identityRef;
}


- (BOOL) isEncrypted
{
    return [chooseIdentity indexOfSelectedItem] || settingsPassword.length > 0;
}


// Read SEB settings from UserDefaults and encrypt them using the provided security credentials
- (NSData *) encryptSEBSettingsWithSelectedCredentialsConfigFormat:(ShareConfigFormat)shareConfigFormat
                                                  allowUnencrypted:(BOOL)allowUnencrypted
                                                      uncompressed:(BOOL)uncompressed
                                                    removeDefaults:(BOOL)removeDefaults
{
    // Get selected config purpose
    sebConfigPurposes configPurpose = [self getSelectedConfigPurpose];

    // Get SecIdentityRef for selected identity
    SecIdentityRef identityRef;
    // Is there one saved from the currently open config file?
    // ToDo: This is broken, needs refactoring
    if (_currentConfigFileKeyHash) {
        identityRef = [self.keychainManager getIdentityRefFromPublicKeyHash:_currentConfigFileKeyHash];
    } else {
        identityRef = [self getSelectedIdentity];
    }
    
    // Get password
    NSString *encryptingPassword;
    // Is there one saved from the currently open config file?
    if (_currentConfigFilePassword) {
        encryptingPassword = _currentConfigFilePassword;
    } else {
        encryptingPassword = settingsPassword;
    }
    
    // Encrypt current settings with current credentials
    NSData *encryptedSebData = [self.preferencesController.configFileController
                                encryptSEBSettingsWithPassword:encryptingPassword
                                passwordIsHash:self.configPasswordIsHash
                                withIdentity:identityRef
                                forPurpose:configPurpose
                                allowUnencrypted:allowUnencrypted
                                uncompressed:uncompressed
                                removeDefaults:removeDefaults || shareConfigFormat == shareConfigFormatLink || shareConfigFormat == shareConfigFormatQRCode];
    return encryptedSebData;
}


#pragma mark -
#pragma mark IBActions

- (IBAction)showQRConfig:(id)sender {
    qrCodeOverlayController = [[QRCodeOverlayController alloc] initWithDelegate:self];

    // Get selected config purpose
    sebConfigPurposes configPurpose = [self.preferencesController.configFileVC getSelectedConfigPurpose];
    if (configPurpose != sebConfigPurposeStartingExam && configPurpose != sebConfigPurposeConfiguringClient) {
        configPurpose = sebConfigPurposeStartingExam;
    }
    // Read SEB settings from UserDefaults and encrypt them using the provided security credentials
    NSData *encryptedSEBData = [self encryptSEBSettingsWithSelectedCredentialsConfigFormat:shareConfigFormatQRCode
                                                                                       allowUnencrypted:YES
                                                                                           uncompressed:NO
                                                                                         removeDefaults:YES];
    if (encryptedSEBData) {
        NSData *qrCodePNGImageData = [self.preferencesController encodeConfigData:encryptedSEBData forPurpose:configPurpose format:shareConfigFormatQRCode uncompressed:NO removeDefaults:YES];
        if (![qrCodeOverlayController showQRCodeWithPngData:qrCodePNGImageData isVQRCode:NO]) {
            DDLogError(@"%s: Couldn't generate image for QR code", __FUNCTION__);
        }
    } else {
        DDLogError(@"%s: Failed to generate config data", __FUNCTION__);
    }
}


- (void)openLockModalWindows {
    [self.preferencesController.sebController openLockModalWindows];
}

- (void)closeLockModalWindows {
    [self.preferencesController.sebController closeLockModalWindows];
}


- (void) windowWillClose:(NSNotification *)notification
{
    [self hideQRConfig];
}


// Action if config file purpose is changed to "starting exam"
- (IBAction) changeConfigFilePurpose:(id)sender {
    // If purpose "starting exam" gets selected and there was a settings password containing a hash
    // we need to reset this password, as a hash as a password is only possible for
    // config files configuring an exam.
    if (self.configPasswordIsHash == YES) {
        [self resetSettingsPasswordFields];
    }
}


- (IBAction) openSEBPrefs:(id)sender {
    [self.preferencesController openSEBPrefs:sender];
}


// Action saving current preferences to a .seb file choosing the filename
- (IBAction) saveSEBPrefs:(id)sender
{
    [self.preferencesController saveSEBPrefs:sender];
}


// Action saving current preferences to a .seb file choosing the filename
- (IBAction) saveSEBPrefsAs:(id)sender
{
    [self.preferencesController saveSEBPrefsAs:sender];
}


// Action reverting preferences to the last saved or opend file
- (IBAction) revertToLastSaved:(id)sender
{
    [self.preferencesController revertToLastSaved:sender];
}


// Action reverting preferences to local client settings
- (IBAction) revertToLocalClientSettings:(id)sender
{
    [self.preferencesController revertToLocalClientSettings:sender];
}


// Action reverting preferences to default settings
- (IBAction) revertToDefaultSettings:(id)sender
{
    [self.preferencesController revertToDefaultSettings:sender];
}


// Action applying currently edited preferences, closing preferences window and restarting SEB
- (IBAction) applyAndRestartSEB:(id)sender
{
    [self.preferencesController applyAndRestartSEB:sender];
}


// Action duplicating current preferences for editing
- (IBAction) createExamSettings:(id)sender
{
    [self.preferencesController createExamSettings:sender];
}


// Action configuring client with currently edited preferences
- (IBAction) configureClient:(id)sender
{
    [self.preferencesController configureClient:sender];
}


@end
