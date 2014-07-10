//
//  PrefsExamViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.11.12.
//  Copyright (c) 2010-2014 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2014 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "PrefsSEBConfigViewController.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "SEBUIUserDefaultsController.h"
#import "SEBEncryptedUserDefaultsController.h"
#import "SEBConfigFileManager.h"
#import "RNEncryptor.h"
#import "SEBCryptor.h"
#import "SEBKeychainManager.h"
#import "MyGlobals.h"
#import "Constants.h"

@interface PrefsSEBConfigViewController ()

@end

@implementation PrefsSEBConfigViewController
@synthesize identitiesNames;
@synthesize identities;


- (NSString *)title
{
	return NSLocalizedString(@"Config File", @"Title of 'SEB Config' preference pane");
}


- (NSString *)identifier
{
	return @"SEBConfigPane";
}


- (NSImage *)image
{
	return [NSImage imageNamed:@"sebConfigIcon"];
}


- (void) setSettingsPassword:(NSString *)password isHash:(BOOL)passwordIsHash
{
    _currentConfigFilePassword = password;
    self.configPasswordIsHash = passwordIsHash;
}


// Select identity for passed identity reference
- (void) selectSettingsIdentity:(SecKeyRef)settingsPrivateKeyRef
{
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];

    [chooseIdentity selectItemAtIndex:0];
    int i, count = [self.identities count];
    for (i=0; i<count; i++) {
        SecIdentityRef identityFromKeychain = (__bridge SecIdentityRef)self.identities[i];
        SecKeyRef privateKeyRef = [keychainManager getPrivateKeyRefFromIdentityRef:identityFromKeychain];
        if (settingsPrivateKeyRef == privateKeyRef) {
            [chooseIdentity selectItemAtIndex:i+1];
            break;
        }
    }
}


// Getter methods for write-only properties

- (NSString *)currentConfigFilePassword {
    [NSException raise:NSInternalInconsistencyException
                format:@"property is write-only"];
    return nil;
}

- (SecKeyRef)currentConfigFileKeyRef {
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
                self.configPasswordIsHash = false;
                [self setValue:nil forKey:@"settingsPassword"];
                [self setValue:nil forKey:@"confirmSettingsPassword"];
                [settingsPasswordField setStringValue:@""];
                [confirmSettingsPasswordField setStringValue:@""];
                return nil;
//                [settingsPassword setString:@""];
//                [confirmSettingsPassword setString:@""];
            }
        }
        
        // Password fields contain actual passwords, not the placeholder for a hash value
       	if (![settingsPassword isEqualToString:confirmSettingsPassword]) {
			//if the two passwords don't match, show it in the label
            return (NSString*)([NSString stringWithString:NSLocalizedString(@"Please confirm password",nil)]);
		} else {
            //[self savePrefs];
        }
    }
    return nil;
}


- (BOOL) usingPrivateDefaults {
    return NSUserDefaults.userDefaultsPrivate;
}


// Delegate called before the Exam settings preferences pane will be displayed
- (void)willBeDisplayed {
    //Load settings password from user defaults
    //[self loadPrefs];
    //[chooseIdentity synchronizeTitleAndSelectedItem];
    if (!self.identitiesNames) { //no identities available yet, get them from keychain
        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
        NSArray *names;
        NSArray *identitiesInKeychain = [keychainManager getIdentitiesAndNames:&names];
        self.identities = identitiesInKeychain;
        self.identitiesNames = [names copy];
        [chooseIdentity removeAllItems];
        //first put "None" item in popupbutton list
        [chooseIdentity addItemWithTitle:NSLocalizedString(@"None", nil)];
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
    else
    {
        [self setValue:_currentConfigFilePassword forKey:@"settingsPassword"];
        [self setValue:_currentConfigFilePassword forKey:@"confirmSettingsPassword"];
    }
    
    
    [self selectSettingsIdentity:_currentConfigFileKeyRef];
}


//- (void) loadPrefs {
//	// Loads preferences from the system's user defaults database
//	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    NSString *settingsPwd = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_settingsPassword"];
//    if ([settingsPwd isEqualToString:@""]) {
//        //empty passwords need to be set to NIL because of the text fields' bindings
//        [self setValue:nil forKey:@"settingsPassword"];
//        [self setValue:nil forKey:@"confirmSettingsPassword"];
//    } else {
//        //if there actually was a hashed password set, use a placeholder string
//        [self setValue:settingsPwd forKey:@"settingsPassword"];
//        [self setValue:settingsPwd forKey:@"confirmSettingsPassword"];
//    }
//}
//
//
//- (void) savePrefs {
//	// Saves preferences to the system's user defaults database
//	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    
//    if (settingsPassword == nil) {
//        //if no settings pw was entered, save a empty NSData object in preferences
//        [preferences setSecureObject:@"" forKey:@"org_safeexambrowser_SEB_settingsPassword"];
//    } else
//        //if password was changed, save the new password in preferences
//        [preferences setSecureObject:settingsPassword forKey:@"org_safeexambrowser_SEB_settingsPassword"];
//}


- (IBAction) openSEBPrefs:(id)sender {
    // Set the default name for the file and show the panel.
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    //[panel setNameFieldStringValue:newName];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"seb"]];
    [panel beginSheetModalForWindow:[MBPreferencesController sharedController].window
                  completionHandler:^(NSInteger result){
                      if (result == NSFileHandlingPanelOKButton)
                      {
                          NSURL *sebFileURL = [panel URL];
                          
                          // Check if private UserDefauls are switched on already
                          if (NSUserDefaults.userDefaultsPrivate) {
                          }
                          
#ifdef DEBUG
                          NSLog(@"Loading .seb settings file with file URL %@", sebFileURL);
#endif
                          NSError *error = nil;
                          NSData *sebData = [NSData dataWithContentsOfURL:sebFileURL options:nil error:&error];
                          
                          if (error) {
                              // Error when reading configuration data
                              [NSApp presentError:error];
                          } else {
                              SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
                              
                              // Decrypt and store the .seb config file
                              if ([configFileManager storeDecryptedSEBSettings:sebData forEditing:YES]) {
                                  // if successfull save the path to the file for possible editing in the preferences window
                                  [[MyGlobals sharedMyGlobals] setCurrentConfigPath:sebFileURL.absoluteString];
                                  
                                  [[MBPreferencesController sharedController] setSettingsTitle:[[MyGlobals sharedMyGlobals] currentConfigPath]];
                                  [[MBPreferencesController sharedController] showWindow:sender];
                                  
                                  //[self requestedRestart:nil];
                              }
                          }
                      }
                  }];
    
}


// Action saving current preferences to a .seb file choosing the filename
- (IBAction) saveSEBPrefs:(id)sender
{
    [self savePrefsAs:NO];
}


// Action saving current preferences to a .seb file choosing the filename
- (IBAction) saveSEBPrefsAs:(id)sender
{
    [self savePrefsAs:YES];
}


// Method which encrypts and saves current preferences to an encrypted .seb file
- (void) savePrefsAs:(BOOL)saveAs
{
    SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
    
    // Get SecIdentityRef for selected identity
    SecIdentityRef identityRef = nil;
    if ([chooseIdentity indexOfSelectedItem]) {
        // If an identity is selected, then we get the according SecIdentityRef
        NSInteger selectedIdentity = [chooseIdentity indexOfSelectedItem]-1;
        identityRef = (__bridge SecIdentityRef)([self.identities objectAtIndex:selectedIdentity]);
    }

    // Get selected config purpose
    sebConfigPurposes configPurpose = [sebPurpose selectedRow];
    
    // Read SEB settings from UserDefaults and encrypt them using the provided security credentials
    NSString *encryptingPassword;
    if (self.configPasswordIsHash) {
        encryptingPassword = _currentConfigFilePassword;
    } else {
        encryptingPassword = settingsPassword;
    }
    NSData *encryptedSebData = [configFileManager encryptSEBSettingsWithPassword:encryptingPassword passwordIsHash:self.configPasswordIsHash withIdentity:identityRef forPurpose:configPurpose];
    
    // If SEB settings were actually read and encrypted we save them
    if (encryptedSebData) {
        NSURL *currentConfigFileURL;
        // Check if local client settings (UserDefauls) are active
        if (!NSUserDefaults.userDefaultsPrivate) {
            // Preset "SebClientSettings.seb" as default file name
            currentConfigFileURL = [NSURL URLWithString:@"SebClientSettings.seb"];
        } else {
            // Get the current filename
//            filename = [[MyGlobals sharedMyGlobals] currentConfigPath].lastPathComponent;
            currentConfigFileURL = [NSURL URLWithString:[[MyGlobals sharedMyGlobals] currentConfigPath]];
//            if ([[MyGlobals sharedMyGlobals] currentConfigPath]) {
//            }
        }
        if (!saveAs && [currentConfigFileURL isFileURL]) {
            // "Save": Rewrite the file openend before
            if (![encryptedSebData writeToURL:currentConfigFileURL atomically:YES]) {
                // If the prefs file couldn't be written to app bundle
                NSRunAlertPanel(NSLocalizedString(@"Writing Settings Failed", nil),
                                NSLocalizedString(@"Make sure you have write permissions in the chosen directory", nil),
                                NSLocalizedString(@"OK", nil), nil, nil);
            }
            
        } else {
            // "Save As": Set the default name and if there is an existing path for the file and show the panel.
            NSSavePanel *panel = [NSSavePanel savePanel];
            [panel setDirectoryURL:currentConfigFileURL];
            [panel setNameFieldStringValue:currentConfigFileURL.lastPathComponent];
            [panel setAllowedFileTypes:[NSArray arrayWithObject:@"seb"]];
            [panel beginSheetModalForWindow:[MBPreferencesController sharedController].window
                          completionHandler:^(NSInteger result){
                              if (result == NSFileHandlingPanelOKButton)
                              {
                                  NSURL*  prefsFileURL = [panel URL];
                                  // Write the contents in the new format.
                                  if (![encryptedSebData writeToURL:prefsFileURL atomically:YES]) {
                                      //if (![filteredPrefsDict writeToURL:prefsFileURL atomically:YES]) {
                                      // If the prefs file couldn't be written to app bundle
                                      NSRunAlertPanel(NSLocalizedString(@"Writing Settings Failed", nil),
                                                      NSLocalizedString(@"Make sure you have write permissions in the chosen directory", nil),
                                                      NSLocalizedString(@"OK", nil), nil, nil);
                                  } else {
                                      // Prefs got successfully written to file
                                      // If "Save As" or the last file didn't had a full path (wasn't stored on drive):
                                      // Store the new path as the current config file path
                                      if (saveAs || ![currentConfigFileURL isFileURL]) {
                                          [[MyGlobals sharedMyGlobals] setCurrentConfigPath:panel.URL.absoluteString];
                                          [[MBPreferencesController sharedController] setSettingsTitle:[[MyGlobals sharedMyGlobals] currentConfigPath]];
                                          [[MBPreferencesController sharedController] setPreferencesWindowTitle];
                                      }
                                      NSString *settingsSavedMessage = configPurpose ? NSLocalizedString(@"Settings have been saved, use this file to reconfigure local settings of a SEB client.", nil) : NSLocalizedString(@"Settings have been saved, use this file to start the exam with SEB.", nil);
                                      NSRunAlertPanel(NSLocalizedString(@"Writing Settings Succeeded", nil), @"%@", NSLocalizedString(@"OK", nil), nil, nil,settingsSavedMessage);
                                  }
                              }
                          }];
        }
    }
}


// Action reverting preferences to the last saved or opend file
- (IBAction) revertToLastSaved:(id)sender
{
#ifdef DEBUG
    NSLog(@"Reverting settings to last saved or opened .seb file");
#endif
    NSError *error = nil;
    NSData *sebData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[MyGlobals sharedMyGlobals] currentConfigPath]] options:nil error:&error];
    
    if (error) {
        // Error when reading configuration data
        [NSApp presentError:error];
    } else {
        SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
        
        // Decrypt and store the .seb config file
        if ([configFileManager storeDecryptedSEBSettings:sebData forEditing:YES]) {
            
            [[MBPreferencesController sharedController] setSettingsTitle:[[MyGlobals sharedMyGlobals] currentConfigPath]];
            [[MBPreferencesController sharedController] showWindow:sender];
            
            //[self requestedRestart:nil];
        }
    }
}


// Action reverting preferences to local client settings
- (IBAction) revertToLocalClientSettings:(id)sender
{

}


// Action reverting preferences to default settings
- (IBAction) revertToDefaultSettings:(id)sender
{
    
}


// Action duplicating current preferences for editing
- (IBAction) applyAndTest:(id)sender
{
    
}


// Action duplicating current preferences for editing
- (IBAction) editDuplicate:(id)sender
{
    
}


// Action duplicating current preferences for editing
- (IBAction) configureClient:(id)sender
{
    // Get key/values from private UserDefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *privatePreferences = [preferences dictionaryRepresentationSEB];
    
    //switch to system's UserDefaults
    [NSUserDefaults setUserDefaultsPrivate:NO];
    
    // Write values from .seb config file to the local preferences (shared UserDefaults)
    SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
    [configFileManager storeIntoUserDefaults:privatePreferences];

    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults];
    
    [[MyGlobals sharedMyGlobals] setCurrentConfigPath:NSLocalizedString(@"Local Client Settings", nil)];

    [[MBPreferencesController sharedController] setSettingsTitle:[[MyGlobals sharedMyGlobals] currentConfigPath]];
    [[MBPreferencesController sharedController] setPreferencesWindowTitle];
}


@end
