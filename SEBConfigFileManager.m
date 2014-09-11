//
//  SEBConfigFileManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 28.04.13.
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


#import "SEBConfigFileManager.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "RNDecryptor.h"
#import "RNEncryptor.h"
#import "SEBKeychainManager.h"
#import "SEBCryptor.h"
#import "NSData+NSDataZIPExtension.h"
#import "MyGlobals.h"


@implementation SEBConfigFileManager


-(id) init
{
    self = [super init];
    if (self) {
        self.sebController = [NSApp delegate];
    }
    return self;
}


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


#pragma mark Methods for Decrypting, Parsing and Storing SEB Settings to UserDefaults

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
#ifdef DEBUG
            NSLog(@"Reconfiguring SEB with SebClientSettings.seb from Preferences directory");
#endif
            SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
            
            // Decrypt and store the .seb config file
            if ([configFileManager storeDecryptedSEBSettings:sebData forEditing:NO]) {
                // if successfull continue with new settings
#ifdef DEBUG
                NSLog(@"Reconfiguring SEB with SebClientSettings.seb was successful");
#endif
                // Delete the SebClientSettings.seb file from the Preferences directory
                error = nil;
                [[NSFileManager defaultManager] removeItemAtURL:sebClientSettingsFileURL error:&error];
#ifdef DEBUG
                NSLog(@"Attempted to remove SebClientSettings.seb from Preferences directory, result: %@", error);
#endif
                // Restart SEB with new settings
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"requestRestartNotification" object:self];

                return YES;
            }
        }
    }
    return NO;
}



// Decrypt, parse and use new SEB settings
-(BOOL) storeDecryptedSEBSettings:(NSData *)sebData forEditing:(BOOL)forEditing
{
    NSDictionary *sebPreferencesDict;
    NSString *sebFilePassword = nil;
    BOOL passwordIsHash = false;
    SecKeyRef sebFileKeyRef = nil;

    // In editing mode we can get a saved existing config file password
    // (used when reverting to last saved/openend settings)
    if (forEditing) {
        sebFilePassword = _currentConfigPassword;
        passwordIsHash = _currentConfigPasswordIsHash;
        sebFileKeyRef = _currentConfigKeyRef;
    }
    PreferencesController *prefsController = self.sebController.preferencesController;

    sebPreferencesDict = [self decryptSEBSettings:sebData forEditing:forEditing sebFilePassword:&sebFilePassword passwordIsHashPtr:&passwordIsHash sebFileKeyRef:&sebFileKeyRef];
    if (!sebPreferencesDict) return NO; //Decryption didn't work, we abort
    
    // Reset SEB, close third party applications
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    if (forEditing || [[sebPreferencesDict valueForKey:@"sebConfigPurpose"] intValue] == sebConfigPurposeStartingExam) {

        ///
        /// If these SEB settings are ment to start an exam or we're in editing mode
        ///
        
        // Release preferences window so bindings get synchronized properly with the new loaded values
        [self.sebController.preferencesController releasePreferencesWindow];
        
        // Switch to private UserDefaults (saved non-persistantly in memory instead in ~/Library/Preferences)
        NSMutableDictionary *privatePreferences = [NSUserDefaults privateUserDefaults]; //the mutable dictionary has to be created here, otherwise the preferences values will not be saved!
        [NSUserDefaults setUserDefaultsPrivate:YES];
        
        // Write values from .seb config file to the local preferences (shared UserDefaults)
        [self storeIntoUserDefaults:sebPreferencesDict];
        
#ifdef DEBUG
        NSLog(@"Private preferences set: %@", privatePreferences);
#endif
        if (forEditing == NO) {
            // if not editing reset credentials
            _currentConfigPassword = nil;
            _currentConfigPasswordIsHash = NO;
            _currentConfigKeyRef = nil;
        }

        // If editing mode or opening the preferences window is allowed
        if (forEditing || [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"]) {
            // we store the .seb file password/hash and/or certificate/identity
            [prefsController setCurrentConfigPassword:sebFilePassword];
            [prefsController setCurrentConfigPasswordIsHash:passwordIsHash];
            [prefsController setCurrentConfigKeyRef:sebFileKeyRef];
        }
        
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
        [prefsController initPreferencesWindow];
        
        return YES; //reading preferences was successful

    } else {

        ///
        /// If these SEB settings are ment to configure a client
        ///

        //switch to system's UserDefaults
        [NSUserDefaults setUserDefaultsPrivate:NO];
        
        // Write values from .seb config file to the local preferences (shared UserDefaults)
        [self storeIntoUserDefaults:sebPreferencesDict];
        
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
        // Reset credentials for reverting to these
        _currentConfigPassword = nil;
        _currentConfigPasswordIsHash = NO;
        _currentConfigKeyRef = nil;

#ifdef DEBUG
        NSLog(@"Should display dialog SEB Re-Configured");
#endif
        if ([[MyGlobals sharedMyGlobals] finishedInitializing]) {
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"SEB Re-Configured", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"Local settings of this SEB client have been reconfigured. Do you want to start working with SEB now or quit?", nil)];
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
        }
        
        // If opening the preferences window is allowed
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"]) {
            // we store the .seb file password/hash and/or certificate/identity
            [prefsController setCurrentConfigPassword:sebFilePassword];
            [prefsController setCurrentConfigPasswordIsHash:passwordIsHash];
            [prefsController setCurrentConfigKeyRef:sebFileKeyRef];
        }
        
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
        
        return YES; //reading preferences was successful
    }
}


// Decrypt and deserialize SEB settings
// The decrypting password the user entered and/or
// certificate reference found in the .seb file is returned

-(NSDictionary *) decryptSEBSettings:(NSData *)sebData forEditing:(BOOL)forEditing sebFilePassword:(NSString **)sebFilePasswordPtr passwordIsHashPtr:(BOOL*)passwordIsHashPtr sebFileKeyRef:(SecKeyRef *)sebFileKeyRefPtr
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // Ungzip the .seb (according to specification >= v14) source data
    NSData *unzippedSebData = [sebData gzipInflate];
    // if unzipped data is not nil, then unzipping worked, we use unzipped data
    // if unzipped data is nil, then the source data may be an uncompressed .seb file, we proceed with it
    if (unzippedSebData) sebData = unzippedSebData;

    NSString *prefixString;
    
    // save the data including the first 4 bytes for the case that it's acutally an unencrypted XML plist
    NSData *sebDataUnencrypted = [sebData copy];

    // Get 4-char prefix
    prefixString = [self getPrefixStringFromData:&sebData];
#ifdef DEBUG
    NSLog(@"Outer prefix of .seb settings file: %@",prefixString);
#endif
    NSError *error = nil;

    //// Check prefix identifying encryption modes

    // Prefix = pkhs ("Public Key Hash") ?
    
    if ([prefixString isEqualToString:@"pkhs"]) {

        // Decrypt with cryptographic identity/private key
        sebData = [self decryptDataWithPublicKeyHashPrefix:sebData forEditing:forEditing sebFileKeyRef:sebFileKeyRefPtr error:&error];
        if (!sebData || error) {
            return nil;
        }

        // Get 4-char prefix again
        // and remaining data without prefix, which is either plain or still encoded with password
        prefixString = [self getPrefixStringFromData:&sebData];
#ifdef DEBUG
        NSLog(@"Inner prefix of .seb settings file: %@", prefixString);
#endif
    }
    
    // Prefix = pswd ("Password") ?
    
    if ([prefixString isEqualToString:@"pswd"]) {
        
        // Decrypt with password
        // if user enters the right one

        NSData *sebDataDecrypted = nil;
        NSString *password;
        // Allow up to 5 attempts for entering decoding password
        NSString *enterPasswordString = NSLocalizedString(@"Enter Password:",nil);
        int i = 5;
        do {
            i--;
            // Prompt for password
            // if we don't have it already
            if (forEditing && *sebFilePasswordPtr) {
                password = *sebFilePasswordPtr;
            } else {
                if ([self.sebController showEnterPasswordDialog:enterPasswordString modalForWindow:nil windowTitle:NSLocalizedString(@"Loading Settings",nil)] == SEBEnterPasswordCancel) return nil;
                password = [self.sebController.enterPassword stringValue];
            }
            if (!password) return nil;
            error = nil;
            sebDataDecrypted = [RNDecryptor decryptData:sebData withPassword:password error:&error];
            enterPasswordString = NSLocalizedString(@"Wrong Password! Try again to enter the correct password:",nil);
            // in case we get an error we allow the user to try it again
        } while (error && i>0);
        if (error || !sebDataDecrypted) {
            //wrong password entered in 5th try: stop reading .seb file
            NSRunAlertPanel(NSLocalizedString(@"Cannot decrypt settings", nil),
                            NSLocalizedString(@"You either entered the wrong password or these settings were saved with an incompatible SEB version.", nil),
                            NSLocalizedString(@"OK", nil), nil, nil);
            return nil;
        } else {
            sebData = sebDataDecrypted;
            // If these settings are being decrypted for editing, we return the decryption password
            *sebFilePasswordPtr = password;
        }
    } else {
        
        // Prefix = pwcc ("Password Configuring Client") ?
        
        if ([prefixString isEqualToString:@"pwcc"]) {
            
            // Decrypt with password and configure local client settings
            // and quit afterwards, returning if reading the .seb file was successfull

            return [self decryptDataWithPasswordForConfiguringClient:sebData forEditing:forEditing sebFilePassword:sebFilePasswordPtr passwordIsHashPtr:passwordIsHashPtr];
            
        } else {

            // Prefix = plnd ("Plain Data") ?
            
            if (![prefixString isEqualToString:@"plnd"]) {
                // No valid 4-char prefix was found in the .seb file
                // Check if .seb file is unencrypted
                if ([prefixString isEqualToString:@"<?xm"]) {
                    // .seb file seems to be an unencrypted XML plist
                    // get the original data including the first 4 bytes
                    sebData = sebDataUnencrypted;
                } else {
                    // No valid prefix and no unencrypted file with valid header
                    // cancel reading .seb file
                    NSRunAlertPanel(NSLocalizedString(@"Opening new settings failed!", nil),
                                    NSLocalizedString(@"These settings cannot be used. They may have been created by an newer, incompatible version of SEB or are corrupted.", nil),
                                    NSLocalizedString(@"OK", nil), nil, nil);
                    return nil;
                }
            }
        }
    }
    
    // If we deal with an unencrypted seb file
    if ([prefixString isEqualToString:@"<?xm"]) {
        // We reset the "for editing" flag, because it doesn't make sense having to enter an admin pw if the file is unencrypted
        forEditing = false;
    } else {
        // The file was encrypted:
        // Ungzip the .seb (according to specification >= v14) decrypted serialized XML plist data
        sebData = [sebData gzipInflate];
    }

    // Get preferences dictionary from decrypted data
    NSDictionary *sebPreferencesDict = [self getPreferencesDictionaryFromConfigData:sebData forEditing:forEditing];
    // If we didn't get a preferences dict back, we abort reading settings
    if (!sebPreferencesDict) return nil;

    // We need to set the right value for the key sebConfigPurpose to know later where to store the new settings
    [sebPreferencesDict setValue:[NSNumber numberWithInt:sebConfigPurposeStartingExam] forKey:@"sebConfigPurpose"];
    
    // Check if a some value is from a wrong class (another than the value from default settings)
    // and quit reading .seb file if a wrong value was found
    if (![preferences checkClassOfSettings:sebPreferencesDict]) {
        return nil;
    }
    // Reading preferences was successful!
    return sebPreferencesDict;
}


// Helper method which decrypts the data using an empty password,
// or the administrator password currently set in SEB
// or asks for the password used for encrypting this SEB file
// for configuring the client

-(NSDictionary *) decryptDataWithPasswordForConfiguringClient:(NSData *)sebData forEditing:(BOOL)forEditing sebFilePassword:(NSString **)sebFilePasswordPtr passwordIsHashPtr:(BOOL*)passwordIsHashPtr
{
    *passwordIsHashPtr = false;
    NSString *password;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    // First try to decrypt with the current admin password
    // get admin password hash
    NSString *hashedAdminPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
    if (!hashedAdminPassword) {
        hashedAdminPassword = @"";
    }
    hashedAdminPassword = [hashedAdminPassword uppercaseString];
    NSDictionary *sebPreferencesDict = nil;
    NSError *error = nil;
    NSData *decryptedSebData = [RNDecryptor decryptData:sebData withPassword:hashedAdminPassword error:&error];
    if (error || !decryptedSebData) {
        // If decryption with admin password didn't work, try it with an empty password
        error = nil;
        decryptedSebData = [RNDecryptor decryptData:sebData withPassword:@"" error:&error];
        if (!error) {
            // Decrypting with empty password worked
            // Ungzip the .seb (according to specification >= v14) decrypted serialized XML plist data
            decryptedSebData = [decryptedSebData gzipInflate];
            // Check if the openend reconfiguring seb file has the same admin password inside as the current one
            // Get the preferences dictionary
            sebPreferencesDict = [self getPreferencesDictionaryFromConfigData:decryptedSebData error:&error];
            if (error) {
                // Error when deserializing the decrypted configuration data
                [NSApp presentError:error];
                return nil; //we abort reading the new settings here
            }
            // Get the admin password set in these settings
            NSString *sebFileHashedAdminPassword = [sebPreferencesDict objectForKey:@"hashedAdminPassword"];
            if (!sebFileHashedAdminPassword) {
                sebFileHashedAdminPassword = @"";
            }
            // Has the SEB config file the same admin password inside as the current one?
            if ([hashedAdminPassword caseInsensitiveCompare:sebFileHashedAdminPassword] != NSOrderedSame) {
                //No: The admin password inside the .seb file wasn't the same as the current one
                if (forEditing) {
                    // If the file is openend for editing (and not to reconfigure SEB)
                    // we have to ask the user for the admin password inside the file
                    if (![self askForPasswordAndCompareToHashedPassword:sebFileHashedAdminPassword]) {
                        // If the user didn't entered the right password we abort
                        return nil;
                    }
                } else {
                    // The file was actually opened for reconfiguring the SEB client:
                    // we have to ask for the current admin password and
                    // allow reconfiguring only if the user enters the right one
                    // Allow up to 5 attempts for entering current admin password
                    int i = 5;
                    NSString *password = nil;
                    NSString *hashedPassword;
                    NSString *enterPasswordString = NSLocalizedString(@"You can only reconfigure SEB by entering the current SEB administrator password:",nil);
                    BOOL passwordsMatch;
                    do {
                        i--;
                        // Prompt for password. If cancel was pressed, abort
                        if ([self.sebController showEnterPasswordDialog:enterPasswordString modalForWindow:nil windowTitle:NSLocalizedString(@"Reconfigure SEB Settings",nil)] == SEBEnterPasswordCancel) {
                            // If cancel was pressed, abort
                            return nil;
                        }
                        password = [self.sebController.enterPassword stringValue];
                        if (password.length == 0) {
                            hashedPassword = @"";
                        } else {
                            hashedPassword = [keychainManager generateSHAHashString:password];
                        }
                        passwordsMatch = [hashedPassword caseInsensitiveCompare:hashedAdminPassword] == NSOrderedSame;
                        // in case we get an error we allow the user to try it again
                        enterPasswordString = NSLocalizedString(@"Wrong Password! Try again to enter the correct current SEB administrator password:",nil);
                    } while ((!password || !passwordsMatch) && i > 0);
                    
                    if (!passwordsMatch) {
                        //wrong password entered in 5th try: stop reading .seb file
                        NSRunAlertPanel(NSLocalizedString(@"Cannot Reconfigure SEB Settings", nil),
                                        NSLocalizedString(@"You either entered the wrong password or these settings were saved with an incompatible SEB version.", nil),
                                        NSLocalizedString(@"OK", nil), nil, nil);
                        return nil;
                    }
                }
            }
        } else {
            // If decryption with empty and admin password didn't work, ask for the password the .seb file was encrypted with
            // Allow up to 5 attempts for entering decoding password
            int i = 5;
            password = nil;
            NSString *enterPasswordString = NSLocalizedString(@"Enter password used to encrypt these settings:",nil);
            do {
                i--;
                // Prompt for password
                if ([self.sebController showEnterPasswordDialog:enterPasswordString modalForWindow:nil windowTitle:NSLocalizedString(@"Loading Settings",nil)] == SEBEnterPasswordCancel) return nil;
                password = [self.sebController.enterPassword stringValue];
                if (!password) {
                    password = @"";
                }
                NSString *hashedPassword = [keychainManager generateSHAHashString:password];
                hashedPassword = [hashedPassword uppercaseString];
                error = nil;
                decryptedSebData = [RNDecryptor decryptData:sebData withPassword:hashedPassword error:&error];
                // in case we get an error we allow the user to try it again
                enterPasswordString = NSLocalizedString(@"Wrong Password! Try again to enter the correct password used to encrypt these settings:",nil);
            } while (error && i>0);
            if (error || !decryptedSebData) {
                //wrong password entered in 5th try: stop reading .seb file
                NSRunAlertPanel(NSLocalizedString(@"Cannot Decrypt SEB Settings", nil),
                                NSLocalizedString(@"You either entered the wrong password or these settings were saved with an incompatible SEB version.", nil),
                                NSLocalizedString(@"OK", nil), nil, nil);
                return nil;
            } else {
                // Decrypting with entered password worked: We save it for returning it later
                *sebFilePasswordPtr = password;
            }
        }
    } else {
        //decrypting with hashedAdminPassword worked: we save it for returning as decryption password if settings are meant for editing
        *sebFilePasswordPtr = hashedAdminPassword;
        // identify this password as hash
        *passwordIsHashPtr = true;
        
    }
    // Decryption worked
    if (!sebPreferencesDict) {
        // If we don't have the dictionary yet from above
        sebData = decryptedSebData;
        
        // Ungzip the .seb (according to specification >= v14) decrypted serialized XML plist data
        sebData = [sebData gzipInflate];
        
        // Get preferences dictionary from decrypted data
        sebPreferencesDict = [self getPreferencesDictionaryFromConfigData:sebData forEditing:forEditing];
        // If we didn't get a preferences dict back, we abort reading settings
        if (!sebPreferencesDict) return nil;
    }

    // Check if a some value is from a wrong class (another than the value from default settings)
    // and quit reading .seb file if a wrong value was found
    if (![preferences checkClassOfSettings:sebPreferencesDict]) return nil;
    
    // We need to set the right value for the key sebConfigPurpose to know later where to store the new settings
    [sebPreferencesDict setValue:[NSNumber numberWithInt:sebConfigPurposeConfiguringClient] forKey:@"sebConfigPurpose"];
    
    return sebPreferencesDict;
}


// Get preferences dictionary from decrypted data.
// In editing mode, users have to enter the right SEB administrator password
// before they can access the settings contents
// and returns the decrypted bytes
-(NSDictionary *) getPreferencesDictionaryFromConfigData:(NSData *)sebData forEditing:(BOOL)forEditing
{
    // Get preferences dictionary from decrypted data
    NSError *error = nil;
    NSDictionary *sebPreferencesDict = [self getPreferencesDictionaryFromConfigData:sebData error:&error];
    if (error) {
        [NSApp presentError:error];
        return nil; //we abort reading the new settings here
    }
    /// In editing mode, if the current administrator password isn't the same as in the new settings,
    /// the user has to enter the right SEB administrator password before he can access the settings contents
    if (forEditing)
    {
        // Get the admin password set in these settings
        NSString *sebFileHashedAdminPassword = [sebPreferencesDict objectForKey:@"hashedAdminPassword"];
        // If there was no or an empty admin password set in these settings, the user can access them anyways
        if (sebFileHashedAdminPassword.length > 0) {
            // Get the current admin password
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            NSString *hashedAdminPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
            if (!hashedAdminPassword) {
                hashedAdminPassword = @"";
            }
            // If the current hashed admin password is same as the hashed admin password from the settings file
            // then the user is allowed to access the settings
            if ([hashedAdminPassword caseInsensitiveCompare:sebFileHashedAdminPassword] != NSOrderedSame) {
                // otherwise we have to ask for the SEB administrator password used in those settings and
                // allow opening settings only if the user enters the right one
                
                if (![self askForPasswordAndCompareToHashedPassword:sebFileHashedAdminPassword]) {
                    return nil;
                }
            }
        }
    }
    // Reading preferences was successful!
    return sebPreferencesDict;
}


// Ask user to enter password and compare it to the passed (hashed) password string
- (BOOL) askForPasswordAndCompareToHashedPassword:(NSString *)sebFileHashedAdminPassword
{
    // Ask for a SEB administrator password and
    // allow opening settings only if the user enters the right one
    // Allow up to 5 attempts for entering admin password
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    int i = 5;
    NSString *password = nil;
    NSString *hashedPassword;
    NSString *enterPasswordString = NSLocalizedString(@"Enter the SEB administrator password used in these settings:",nil);
    bool passwordsMatch;
    do {
        i--;
        // Prompt for password
        if ([self.sebController showEnterPasswordDialog:enterPasswordString modalForWindow:nil windowTitle:NSLocalizedString(@"Loading settings",nil)] == SEBEnterPasswordCancel) {
            // If cancel was pressed, abort
            return nil;
        }
        password = [self.sebController.enterPassword stringValue];
        if (password.length == 0) {
            hashedPassword = @"";
        } else {
            hashedPassword = [keychainManager generateSHAHashString:password];
        }
        passwordsMatch = ([hashedPassword caseInsensitiveCompare:sebFileHashedAdminPassword] == NSOrderedSame);
        // in case we get an error we allow the user to try it again
        enterPasswordString = NSLocalizedString(@"Wrong password! Try again to enter the correct SEB administrator password from these settings:", nil);
    } while ((password == nil || !passwordsMatch) && i > 0);
    
    if (!passwordsMatch) {
        //wrong password entered in 5th try: stop reading .seb file
        NSRunAlertPanel(NSLocalizedString(@"Loading Settings", nil),
                        NSLocalizedString(@"If you don't enter the right administrator password from these settings you cannot open them.", nil),
                        NSLocalizedString(@"OK", nil), nil, nil);
        return NO;
    }
    // Right password entered
    return YES;
}


// Get preferences dictionary from decrypted data
-(NSDictionary *) getPreferencesDictionaryFromConfigData:(NSData *)sebData error:(NSError **)error
{
    NSError *plistError = nil;
    //NSString *sebPreferencesXML = [[NSString alloc] initWithData:sebData encoding:NSUTF8StringEncoding];
    NSDictionary *sebPreferencesDict = [NSPropertyListSerialization propertyListWithData:sebData
                                                                                 options:0
                                                                                  format:NULL
                                                                                   error:&plistError];
    if (plistError) {
        // If it exists, then add the localized error reason from serializing the plist to the error object
        NSString *failureReason = [plistError localizedFailureReason];
        if (!failureReason) failureReason = @"";
        NSMutableDictionary *newErrorDict =
        [NSMutableDictionary dictionaryWithDictionary:@{ NSLocalizedDescriptionKey :
                                                             NSLocalizedString(@"Loading new settings failed!", nil),
                                                         NSLocalizedRecoverySuggestionErrorKey :
                                                             [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"These settings are corrupted and cannot be used.", nil), failureReason]
                                                         }];
        
        NSError *newError = [[NSError alloc] initWithDomain:sebErrorDomain
                                                       code:1 userInfo:newErrorDict];
        *error = newError;
        sebPreferencesDict = nil; //we don't have any settings to return
    }
    return sebPreferencesDict;
}


// Save imported settings into user defaults (either in private memory or local shared UserDefaults)
-(void) storeIntoUserDefaults:(NSDictionary *)sebPreferencesDict
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences storeSEBDictionary:sebPreferencesDict];
}


// Helper method which fetches the public key hash from a seb data object,
// retrieves the according cryptographic identity from the keychain
// and returns the decrypted data
-(NSData *) decryptDataWithPublicKeyHashPrefix:(NSData *)sebData forEditing:(BOOL)forEditing sebFileKeyRef:(SecKeyRef *)privateKeyRefPtr error:(NSError **)error
{
    // Get 20 bytes public key hash prefix
    // and remaining data with the prefix stripped
    NSData *publicKeyHash = [self getPrefixDataFromData:&sebData withLength:publicKeyHashLenght];
    
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    SecKeyRef privateKeyRef = [keychainManager getPrivateKeyFromPublicKeyHash:publicKeyHash];
    if (!privateKeyRef) {
        NSRunAlertPanel(NSLocalizedString(@"Error Decrypting Settings", nil),
                        NSLocalizedString(@"The identity needed to decrypt settings has not been found in the keychain!", nil),
                        NSLocalizedString(@"OK", nil), nil, nil);
        return nil;
    }
#ifdef DEBUG
    NSLog(@"Private key retrieved with hash: %@", privateKeyRef);
#endif
    // If these settings are being decrypted for editing, we will return the decryption certificate reference
    // in the variable which was passed as reference when calling this method
    *privateKeyRefPtr = privateKeyRef;
    
    sebData = [keychainManager decryptData:sebData withPrivateKey:privateKeyRef];
    
    return sebData;
}


// Helper method for returning a prefix string (of sebConfigFilePrefixLength, currently 4 chars)
// from a data byte array which is returned without the stripped prefix
-(NSString *) getPrefixStringFromData:(NSData **)data
{
    NSData *prefixData = [self getPrefixDataFromData:data withLength:sebConfigFilePrefixLength];
    return [[NSString alloc] initWithData:prefixData encoding:NSUTF8StringEncoding];
}


// Helper method for stripping (and returning) a prefix byte array of prefixLength
// from a data byte array which is returned without the stripped prefix
-(NSData *) getPrefixDataFromData:(NSData **)data withLength:(NSUInteger)prefixLength
{
    // Get prefix with indicated length
    NSRange prefixRange = {0, prefixLength};
    NSData *prefixData = [*data subdataWithRange:prefixRange];
    
    // Get data without the stripped prefix
    NSRange range = {prefixLength, [*data length]-prefixLength};
    *data = [*data subdataWithRange:range];
    
    return prefixData;
}


#pragma mark Generate Encrypted .seb Settings Data

// Read SEB settings from UserDefaults and encrypt them using provided security credentials
- (NSData *) encryptSEBSettingsWithPassword:(NSString *)settingsPassword
                             passwordIsHash:(BOOL) passwordIsHash
                               withIdentity:(SecIdentityRef) identityRef
                                 forPurpose:(sebConfigPurposes)configPurpose {

    // Copy preferences to a dictionary
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *filteredPrefsDict;
    filteredPrefsDict = [NSMutableDictionary dictionaryWithDictionary:[preferences dictionaryRepresentationSEB]];
    
    // Write SEB_OS_version_build version information to .seb settings
    NSString *originatorVersion = [NSString stringWithFormat:@"SEB_OSX_%@_%@",
                                   [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"],
                                   [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"]];
    [filteredPrefsDict setObject:originatorVersion forKey:@"originatorVersion"];
    
    // Remove copy Browser Exam Key to clipboard when quitting flag when saving for starting exams
    if (configPurpose == sebConfigPurposeStartingExam) {
        [filteredPrefsDict removeObjectForKey:@"copyBrowserExamKeyToClipboardWhenQuitting"];
    }
    
    // Convert preferences dictionary to XML property list
    NSError *error = nil;
    NSData *dataRep = [NSPropertyListSerialization dataWithPropertyList:filteredPrefsDict
                                                                 format:NSPropertyListXMLFormat_v1_0
                                                                options:0
                                                                  error:&error];
    if (error || !dataRep) {
        // Serialization of the XML plist went wrong
        // Looks like there is a key with a NULL value
        // TO DO: Error handling for this unlikely case
#ifdef DEBUG
        NSLog(@"Serialization of the XML plist went wrong! Error: %@", error);
#endif
    }
    
    NSMutableString *sebXML = [[NSMutableString alloc] initWithData:dataRep encoding:NSUTF8StringEncoding];
#ifdef DEBUG
    NSLog(@".seb XML plist: %@", sebXML);
#endif
    
    NSData *encryptedSebData = [sebXML dataUsingEncoding:NSUTF8StringEncoding];
    //NSData *encryptedSebData = [NSKeyedArchiver archivedDataWithRootObject:filteredPrefsDict];
    
    NSString *encryptingPassword = nil;
    
    // Check for special case: .seb configures client, empty password
    if (settingsPassword.length == 0 && configPurpose == sebConfigPurposeConfiguringClient) {
        encryptingPassword = @"";
    } else {
        // in all other cases:
        // Check if no password entered and no identity selected
        if (settingsPassword.length == 0 && !identityRef) {
            int answer = NSRunAlertPanel(NSLocalizedString(@"No encryption credentials chosen",nil), NSLocalizedString(@"You should either enter a password or choose a cryptographic identity to encrypt the SEB settings file.\n\nYou can save an unencrypted settings file, but this is not recommended for use in exams.",nil),
                                         NSLocalizedString(@"OK",nil), NSLocalizedString(@"Save unencrypted",nil), nil);
            switch(answer)
            {
                case NSAlertDefaultReturn:
                    // Post a notification to switch to the Config File prefs pane
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"switchToConfigFilePane" object:self];
                    // don't save the config data
                    return nil;
                    
                case NSAlertAlternateReturn:
                    // save .seb config data unencrypted
                    return encryptedSebData;
                    
                default:
                    return nil;
            }
        }
    }
    // gzip the serialized XML data
    encryptedSebData = [encryptedSebData gzipDeflate];
    
    // Check if password for encryption is provided and use it then
    if (settingsPassword.length > 0) {
        encryptingPassword = settingsPassword;
    }
    // So if password is provided or an empty string (special case)
    if (encryptingPassword) {
        // encrypt with password
        encryptedSebData = [self encryptData:encryptedSebData usingPassword:encryptingPassword passwordIsHash:passwordIsHash forPurpose:configPurpose];
    } else {
        // if no encryption with password: add a spare 4-char prefix identifying plain data
        NSString *prefixString = @"plnd";
        NSMutableData *encryptedData = [NSMutableData dataWithData:[prefixString dataUsingEncoding:NSUTF8StringEncoding]];
        //append plain data
        [encryptedData appendData:encryptedSebData];
        encryptedSebData = [NSData dataWithData:encryptedData];
    }
    // Check if cryptographic identity for encryption is selected
    if (identityRef) {
        // Encrypt preferences using a cryptographic identity
        encryptedSebData = [self encryptData:encryptedSebData usingIdentity:identityRef];
    }
    
    // gzip the encrypted data
    encryptedSebData = [encryptedSebData gzipDeflate];
    
    return encryptedSebData;
}


// Encrypt preferences using a certificate
-(NSData *) encryptData:(NSData *) data usingIdentity:(SecIdentityRef) identityRef
{
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    
    //get certificate from selected identity
    SecCertificateRef certificateRef = [keychainManager getCertificateFromIdentity:identityRef];
    
    //get public key hash from selected identity's certificate
    NSData* publicKeyHash = [keychainManager getPublicKeyHashFromCertificate:certificateRef];
    
    //encrypt data using public key
    NSData *encryptedData = [keychainManager encryptData:data withPublicKeyFromCertificate:certificateRef];
    
    //Prefix indicating data has been encrypted with a public key identified by hash
    NSString *prefixString = @"pkhs";
    NSMutableData *encryptedSebData = [NSMutableData dataWithData:[prefixString dataUsingEncoding:NSUTF8StringEncoding]];
    //append public key hash
    [encryptedSebData appendData:publicKeyHash];
    //append encrypted data
    [encryptedSebData appendData:encryptedData];
    
    return encryptedSebData;
}


// Encrypt preferences using a password
- (NSData*) encryptData:(NSData*)data usingPassword:(NSString *)password passwordIsHash:(BOOL)passwordIsHash forPurpose:(sebConfigPurposes)configPurpose {
    const char *utfString;
    // Check if .seb file should start exam or configure client
    if (configPurpose == sebConfigPurposeStartingExam) {
        // prefix string for starting exam: normal password will be prompted
        utfString = [@"pswd" UTF8String];
    } else {
        // prefix string for configuring client: configuring password will either be hashed admin pw on client
        // or if no admin pw on client set: empty pw
        utfString = [@"pwcc" UTF8String];
        //empty password means no admin pw on clients and should not be hashed
        //or we got already a hashed admin pw as settings pw, then we don't hash again
        if (password.length > 0 && !passwordIsHash) {
            // if not empty password and password is not yet hash: hash the pw
            SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
            password = [keychainManager generateSHAHashString:password];
            password = [password uppercaseString];
        }
    }
    NSMutableData *encryptedSebData = [NSMutableData dataWithBytes:utfString length:4];
    NSError *error;
    NSData *encryptedData = [RNEncryptor encryptData:data
                                        withSettings:kRNCryptorAES256Settings
                                            password:password
                                               error:&error];;
    [encryptedSebData appendData:encryptedData];
    
    return encryptedSebData;
}


@end
