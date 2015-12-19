//
//  SEBConfigFileManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 28.04.13.
//  Copyright (c) 2010-2015 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2015 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "SEBConfigFileManager.h"
#import "RNDecryptor.h"
#import "RNEncryptor.h"
#import "SEBKeychainManager.h"
#import "SEBCryptor.h"
#import "NSData+NSDataZIPExtension.h"
#import "MyGlobals.h"


@implementation SEBConfigFileManager

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
- (void) reconfigureClientWithSebClientSettings
{
    [self.delegate reconfigureClientWithSebClientSettings];
}


-(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
{
    [self storeNewSEBSettings:sebData
                   forEditing:forEditing
       forceConfiguringClient:NO];
}


// Decrypt new SEB settings
-(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
{
    SEBConfigFileCredentials *sebFileCredentials = [SEBConfigFileCredentials new];

    // In editing mode we can get a saved existing config file password
    // (used when reverting to last saved/openend settings)
    if (forEditing) {
        sebFileCredentials.password = _currentConfigPassword;
        sebFileCredentials.passwordIsHash = _currentConfigPasswordIsHash;
        sebFileCredentials.keyRef = _currentConfigKeyRef;
    }

    [self decryptSEBSettings:sebData
             withCredentials:(SEBConfigFileCredentials *)sebFileCredentials
                  forEditing:forEditing
      forceConfiguringClient:forceConfiguringClient];
}


// Decrypt and deserialize SEB settings
// The decrypting password the user entered and/or
// certificate reference found in the .seb file is returned

-(void) decryptSEBSettings:(NSData *)sebData
           withCredentials:(SEBConfigFileCredentials *)sebFileCredentials
                forEditing:(BOOL)forEditing
    forceConfiguringClient:(BOOL)forceConfiguringClient
{
    // Ungzip the .seb (according to specification >= v14) source data
    NSData *unzippedSebData = [sebData gzipInflate];
    // if unzipped data is not nil, then unzipping worked, we use unzipped data
    // if unzipped data is nil, then the source data may be an uncompressed .seb file, we proceed with it
    if (unzippedSebData) {
        sebData = unzippedSebData;
    }

    NSString *sebFilePassword = sebFileCredentials.password;
    //BOOL passwordIsHash = sebFileCredentials.passwordIsHash;
    SecKeyRef sebFileKeyRef = sebFileCredentials.keyRef;

    NSString *prefixString;
    
    // save the data including the first 4 bytes for the case that it's acutally an unencrypted XML plist
    NSData *sebDataUnencrypted = [sebData copy];

    // Get 4-char prefix
    prefixString = [self getPrefixStringFromData:&sebData];

    DDLogInfo(@"Outer prefix of .seb settings file: %@",prefixString);

    NSError *error = nil;

    //// Check prefix identifying encryption modes

    // Prefix = pkhs ("Public Key Hash") ?
    
    if ([prefixString isEqualToString:@"pkhs"]) {

        // Decrypt with cryptographic identity/private key
        sebData = [self decryptDataWithPublicKeyHashPrefix:sebData forEditing:forEditing sebFileKeyRef:&sebFileKeyRef error:&error];
        if (!sebData || error) {
            return;
        }

        // Get 4-char prefix again
        // and remaining data without prefix, which is either plain or still encoded with password
        prefixString = [self getPrefixStringFromData:&sebData];

        DDLogInfo(@"Inner prefix of .seb settings file: %@", prefixString);

    }
    
    // Prefix = pswd ("Password") ?
    
    if ([prefixString isEqualToString:@"pswd"]) {
        
        // Allow up to 5 attempts for entering decoding password
        attempts = 5;
        encryptedSEBData = sebData;
        NSString *enterPasswordString = NSLocalizedString(@"Enter Password:",nil);
        
        // Ask the user to enter the settings password and proceed to the callback method after this happend
        [self.delegate promptPasswordWithMessageText:enterPasswordString
                                            callback:self
                                            selector:@selector(passwordSettingsStartingExams:)];
        return;
        
    } else {
        
        // Prefix = pwcc ("Password Configuring Client") ?
        
        if ([prefixString isEqualToString:@"pwcc"]) {
            
            // Decrypt with password and configure local client settings

            [self decryptDataWithPasswordForConfiguringClient:sebData
                                                     withCredentials:sebFileCredentials
                                                   forEditing:forEditing
                                       forceConfiguringClient:forceConfiguringClient];
            
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
                    DDLogError(@"%s: No valid prefix and no unencrypted file with valid header", __FUNCTION__);
                    [self.delegate showAlertCorruptedSettings];

                    return;
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
    if (!sebPreferencesDict) {
        return;
    }

    // We need to set the right value for the key sebConfigPurpose to know later where to store the new settings
    [sebPreferencesDict setValue:[NSNumber numberWithInt:sebConfigPurposeStartingExam] forKey:@"sebConfigPurpose"];
    
    // Check if a some value is from a wrong class (another than the value from default settings)
    // and quit reading .seb file if a wrong value was found
    if (![self checkClassOfSettings:sebPreferencesDict]) {
        return;
    }
    // Reading preferences was successful!
    [self storeDecryptedSEBSettings:sebPreferencesDict
                    withCredentials:sebFileCredentials
                         forEditing:forEditing
             forceConfiguringClient:forceConfiguringClient];
}


- (void) passwordSettingsStartingExams:(NSString *)password {
    NSError *error = nil;
    NSData *sebDataDecrypted = [RNDecryptor decryptData:encryptedSEBData withPassword:password error:&error];
    attempts--;

    if (error || !sebDataDecrypted) {
        // wrong password entered, are there still attempts left?
        if (attempts > 0) {
            // Let the user try it again
            NSString *enterPasswordString = NSLocalizedString(@"Wrong Password! Try again to enter the correct password:",nil);
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.delegate promptPasswordWithMessageText:enterPasswordString callback:self selector:@selector(passwordSettingsStartingExams:)];
            return;
            
        } else {
            // Wrong password entered in the last allowed attempts: Stop reading .seb file
            DDLogError(@"%s: Cannot Decrypt Settings: You either entered the wrong password or these settings were saved with an incompatible SEB version.", __FUNCTION__);
            [self.delegate showAlertWrongPassword];
            return;
        }
        
    } else {
        // The .seb data was decrypted successfully
        // Ungzip the .seb (according to specification >= v14) decrypted serialized XML plist data
        sebDataDecrypted = [sebDataDecrypted gzipInflate];
        // If these settings are being decrypted for editing, we return the decryption password
        sebFilePassword = password;
        // Get preferences dictionary from decrypted data
        NSDictionary *sebPreferencesDict = [self getPreferencesDictionaryFromConfigData:sebDataDecrypted forEditing:forEditing];
        // If we didn't get a preferences dict back, we abort reading settings
        if (!sebPreferencesDict) {
            return;
        }
        
        // We need to set the right value for the key sebConfigPurpose to know later where to store the new settings
        [sebPreferencesDict setValue:[NSNumber numberWithInt:sebConfigPurposeStartingExam] forKey:@"sebConfigPurpose"];
        
        // Check if a some value is from a wrong class (another than the value from default settings)
        // and quit reading .seb file if a wrong value was found
        if (![self checkClassOfSettings:sebPreferencesDict]) {
            return;
        }
        // Reading preferences was successful!
        [self storeDecryptedSEBSettings:sebPreferencesDict
                        withCredentials:sebFileCredentials
                             forEditing:forEditing
                 forceConfiguringClient:forceConfiguringClient];

    }
}

// Helper method which decrypts the data using an empty password,
// or the administrator password currently set in SEB
// or asks for the password used for encrypting this SEB file
// for configuring the client

-(void) decryptDataWithPasswordForConfiguringClient:(NSData *)sebData
                                              withCredentials:(SEBConfigFileCredentials *)sebFileCredentials
                                                   forEditing:(BOOL)forEditing
                                       forceConfiguringClient:(BOOL)forceConfiguringClient
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
        if (error || !decryptedSebData) {
            // If decryption with empty and admin password didn't work, ask for the password the .seb file was encrypted with
            // Allow up to 5 attempts for entering decoding password
// ******************************************************************************************************************
            int i = 5;
            password = nil;
            NSString *enterPasswordString = NSLocalizedString(@"Enter password used to encrypt these settings:",nil);
            do {
                i--;
                // Prompt for password
                password = [self.delegate promptPasswordWithMessageText:enterPasswordString];
                if (!password) {
                    return;
                }
                NSString *hashedPassword = [keychainManager generateSHAHashString:password];
                hashedPassword = [hashedPassword uppercaseString];
                error = nil;
                decryptedSebData = [RNDecryptor decryptData:sebData withPassword:hashedPassword error:&error];
                // in case we get an error we allow the user to try it again
                enterPasswordString = NSLocalizedString(@"Wrong Password! Try again to enter the correct password used to encrypt these settings:",nil);
            } while ((!decryptedSebData || error) && i>0);
            if (error || !decryptedSebData) {
                //wrong password entered in 5th try: stop reading .seb file
                DDLogError(@"%s: Cannot Decrypt SEB Settings: You either entered the wrong password or these settings were saved with an incompatible SEB version.", __FUNCTION__);
                [self.delegate showAlertWrongPassword];

                return;
            } else {
                // Decrypting with entered password worked: We save it for returning it later
                *sebFilePasswordPtr = password;
            }
        }
    } else {
        //decrypting with hashedAdminPassword worked: we save it for returning as decryption password
        *sebFilePasswordPtr = hashedAdminPassword;
        // identify this password as hash
        *passwordIsHashPtr = true;
    }

// ******************************************************************************************************************
    
    /// Decryption worked
    
    // Ungzip the .seb (according to specification >= v14) decrypted serialized XML plist data
    decryptedSebData = [decryptedSebData gzipInflate];
    // Check if the openend reconfiguring seb file has the same admin password inside as the current one
    // Get the preferences dictionary
    sebPreferencesDict = [self getPreferencesDictionaryFromConfigData:decryptedSebData error:&error];
    if (error) {
        // Error when deserializing the decrypted configuration data
        [self.delegate presentErrorAlert:error];
        return; //we abort reading the new settings here
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
                // If the user didn't enter the right password we abort
                return;
            }
        } else {
            // The file was actually opened for reconfiguring the SEB client:
            // we have to ask for the current admin password and
            // allow reconfiguring only if the user enters the right one
            // We don't check this for the case the current admin password was used to encrypt the new settings
            // In this case there can be a new admin pw defined in the new settings and users don't need to enter the old one
            if (*passwordIsHashPtr == false && hashedAdminPassword.length > 0) {

// ******************************************************************************************************************
                
                // Allow up to 5 attempts for entering current admin password
                int i = 5;
                NSString *password = nil;
                NSString *hashedPassword;
                NSString *enterPasswordString = NSLocalizedString(@"You can only reconfigure SEB by entering the current SEB administrator password:",nil);
                BOOL passwordsMatch;
                do {
                    i--;
                    // Prompt for password. If cancel was pressed, abort
                    password = [self.delegate promptPasswordWithMessageText:NSLocalizedString(@"Reconfigure SEB Settings", nil)];
                    if (!password) {
                        return nil;
                    }
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
                    DDLogError(@"%s: Cannot Reconfigure SEB Settings: You didn't enter the correct current SEB administrator password.", __FUNCTION__);
                    
                    NSString *title = NSLocalizedString(@"Cannot Reconfigure SEB Settings", nil);
                    NSString *informativeText = NSLocalizedString(@"You didn't enter the correct current SEB administrator password.", nil);
                    [self.delegate showAlertWithTitle:title andText:informativeText];
                    return nil;
                }
            }
        }
    }

// ******************************************************************************************************************
    
    // Check if a some value is from a wrong class (another than the value from default settings)
    // and quit reading .seb file if a wrong value was found
    if (![self checkClassOfSettings:sebPreferencesDict]) {
        return nil;
    }
    
    // We need to set the right value for the key sebConfigPurpose to know later where to store the new settings
    [sebPreferencesDict setValue:[NSNumber numberWithInt:sebConfigPurposeConfiguringClient] forKey:@"sebConfigPurpose"];
    
    // Reading preferences was successful!
    [self storeDecryptedSEBSettings:sebPreferencesDict
                    withCredentials:sebFileCredentials
                         forEditing:forEditing
             forceConfiguringClient:forceConfiguringClient];
}


// Parse and use new SEB settings
-(void) storeDecryptedSEBSettings:(NSDictionary *)sebPreferencesDict
                  withCredentials:(SEBConfigFileCredentials *)sebFileCredentials
                       forEditing:(BOOL)forEditing
           forceConfiguringClient:(BOOL)forceConfiguringClient
{
    if (!sebPreferencesDict) return; //Decryption didn't work, we abort
    
    // Reset SEB, close third party applications
    
    if (!forceConfiguringClient && (forEditing || [[sebPreferencesDict valueForKey:@"sebConfigPurpose"] intValue] == sebConfigPurposeStartingExam)) {
        
        ///
        /// If these SEB settings are ment to start an exam or we're in editing mode
        ///
        
        // Inform delegate that preferences will be reconfigured
        if ([self.delegate respondsToSelector:@selector(willReconfigureTemporary)]) {
            [self.delegate willReconfigureTemporary];
        }
        
        // Switch to private UserDefaults (saved non-persistantly in memory instead in ~/Library/Preferences)
        NSMutableDictionary *privatePreferences = [NSUserDefaults privateUserDefaults]; //this mutable dictionary has to be referenced here, otherwise preferences values will not be saved!
        [NSUserDefaults setUserDefaultsPrivate:YES];
        
        // Write values from .seb config file to the local preferences (shared UserDefaults)
        [self storeIntoUserDefaults:sebPreferencesDict];
        
        DDLogVerbose(@"%s, Temporary preferences set: %@", __FUNCTION__, privatePreferences);
        
        if (forEditing == NO) {
            // if not editing reset credentials
            _currentConfigPassword = nil;
            _currentConfigPasswordIsHash = NO;
            _currentConfigKeyRef = nil;
        }
        
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
        
        // Inform delegate that preferences were reconfigured
        if ([self.delegate respondsToSelector:@selector(didReconfigureTemporaryForEditing:sebFileCredentials:)]) {
            [self.delegate didReconfigureTemporaryForEditing:(BOOL)forEditing
                                          sebFileCredentials:sebFileCredentials];
        }
        
        return; //reading preferences was successful
        
    } else {
        
        ///
        /// If these SEB settings are ment to configure a client
        ///
        
        // Inform delegate that preferences will be reconfigured
        if ([self.delegate respondsToSelector:@selector(willReconfigurePermanently)]) {
            [self.delegate willReconfigurePermanently];
        }
        
        //switch to system's (persisted) UserDefaults
        [NSUserDefaults setUserDefaultsPrivate:NO];
        
        // Check if we have embedded identities and import them into the Windows Certifcate Store
        //NSArray *certificates = [sebPreferencesDict valueForKey:@"embeddedCertificates"];
        NSMutableArray *embeddedCertificates = [sebPreferencesDict valueForKey:@"embeddedCertificates"];
        if (embeddedCertificates) {
            //NSMutableArray *embeddedCertificates = [NSMutableArray arrayWithArray:certificates];
            SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
            for (NSInteger i = embeddedCertificates.count - 1; i >= 0; i--)
            {
                // Get the Embedded Certificate
                NSDictionary *embeddedCertificate = embeddedCertificates[i];
                // Is it an identity?
                if ([[embeddedCertificate objectForKey:@"type"] integerValue] == certificateTypeIdentity)
                {
                    // Store the identity into the Keychain
                    NSData *certificateData = [embeddedCertificate objectForKey:@"certificateData"];
                    if (certificateData) {
                        BOOL success = [keychainManager importIdentityFromData:certificateData];
                        
                        DDLogInfo(@"Importing identity <%@> into Keychain %@", [embeddedCertificate objectForKey:@"name"], success ? @"succedded" : @"failed");
                    }
                }
                // Remove the identity from settings, as it should be only stored in the Certificate Store and not in the locally stored settings file
                [embeddedCertificates removeObjectAtIndex:i];
            }
        }
        
        // Write values from .seb config file to the local preferences (shared UserDefaults)
        [self storeIntoUserDefaults:sebPreferencesDict];
        
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
        // Reset credentials for reverting to these
        _currentConfigPassword = nil;
        _currentConfigPasswordIsHash = NO;
        _currentConfigKeyRef = nil;
        
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
        
        DDLogInfo(@"Should display dialog SEB Re-Configured");
        
        // Inform delegate that preferences were reconfigured
        if ([self.delegate respondsToSelector:@selector(didReconfigurePermanentlyForceConfiguringClient:sebFileCredentials:)]) {
            [self.delegate didReconfigurePermanentlyForceConfiguringClient:forceConfiguringClient
                                                        sebFileCredentials:sebFileCredentials];
        }
        
        return; //reading preferences was successful
    }
}


// Check if a some value is from a wrong class (another than the value from default settings)
- (BOOL)checkClassOfSettings:(NSDictionary *)sebPreferencesDict
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // get default settings
    NSDictionary *defaultSettings = [preferences sebDefaultSettings];
    
    // Check if a some value is from a wrong class other than the value from default settings)
    for (NSString *key in sebPreferencesDict) {
        NSString *keyWithPrefix = [preferences prefixKey:key];
        id value = [sebPreferencesDict objectForKey:key];
#ifdef DEBUG
        NSLog(@"%s Value for key %@ is %@", __FUNCTION__, key, value);
#else
        DDLogVerbose(@"%s Value for key %@ is %@", __FUNCTION__, key, value);
#endif
        id defaultValue = [defaultSettings objectForKey:keyWithPrefix];
        Class valueClass = [value superclass];
        Class defaultValueClass = [defaultValue superclass];
        if (!value || (valueClass && defaultValueClass && !([defaultValue isKindOfClass:valueClass] || [value isKindOfClass:defaultValueClass]))) {
            // Class of newly loaded value is different than the one from the default value
            // If yes, then cancel reading .seb file
            DDLogError(@"%s Value for key %@ is NULL or doesn't have the correct class!", __FUNCTION__, key);

            [self.delegate showAlertWithTitle:NSLocalizedString(@"Reading New Settings Failed!",nil)
                                      andText:NSLocalizedString(@"These settings cannot be used. They may have been created by an incompatible version of SEB or are corrupted.", nil)];
            
            return NO; //we abort reading the new settings here
        }
    }
    return YES;
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
        DDLogError(@"%s: Serialization of the XML plist went wrong! Error: %@", __FUNCTION__, error.description);
        [self.delegate presentErrorAlert:error];

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
            // Get the current hashed admin password
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
        DDLogError(@"%s: Serialization of the XML plist went wrong! Error: %@", __FUNCTION__, plistError.description);
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


// Ask user to enter password and compare it to the passed (hashed) password string
- (BOOL) askForPasswordAndCompareToHashedPassword:(NSString *)sebFileHashedAdminPassword
{
    // Check if there wasn't a hashed password (= empty password)
    if (sebFileHashedAdminPassword.length == 0) return true;
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
        password = [self.delegate promptPasswordWithMessageText:NSLocalizedString(@"Loading settings",nil)];
        if (!password) {
            // If cancel was pressed, abort
            return false;
        }
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
        NSString *title = NSLocalizedString(@"Loading Settings", nil);
        NSString *informativeText = NSLocalizedString(@"If you don't enter the right administrator password from these settings you cannot open them.", nil);
        [self.delegate showAlertWithTitle:title andText:informativeText];

        DDLogError(@"%s: Loading Settings: If you don't enter the right administrator password from these settings you cannot open them.", __FUNCTION__);
        
        return NO;
    }
    // Right password entered
    return YES;
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

        DDLogError(@"%s: Error Decrypting Settings: The identity needed to decrypt settings has not been found in the keychain!", __FUNCTION__);
        
        NSString *title = NSLocalizedString(@"Error Decrypting Settings", nil);
        NSString *informativeText = NSLocalizedString(@"The identity needed to decrypt settings has not been found in the keychain!", nil);
        [self.delegate showAlertWithTitle:title andText:informativeText];

        return nil;
    }

    DDLogInfo(@"Private key retrieved with hash: %@", privateKeyRef);

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
    // Check if data has at least the lenght of the prefix
    if (prefixLength > [*data length]) {
        DDLogError(@"%s: Data is shorter than prefix!", __FUNCTION__);
        return nil;
    }
    
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
        DDLogError(@"%s: Serialization of the XML plist went wrong! Error: %@", __FUNCTION__, error.description);
        
        [self.delegate showAlertCorruptedSettings];

        return nil;
    }
    
    NSMutableString *sebXML = [[NSMutableString alloc] initWithData:dataRep encoding:NSUTF8StringEncoding];
    DDLogVerbose(@".seb XML plist: %@", sebXML);
    
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
            if ([self.delegate saveSettingsUnencrypted]) {
                // save .seb config data unencrypted
                return encryptedSebData;
            } else {
                // don't save the config data
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
    SecCertificateRef certificateRef = [keychainManager copyCertificateFromIdentity:identityRef];
    
    //get public key hash from selected identity's certificate
    NSData* publicKeyHash = [keychainManager getPublicKeyHashFromCertificate:certificateRef];
    
    //encrypt data using public key
    NSData *encryptedData = [keychainManager encryptData:data withPublicKeyFromCertificate:certificateRef];
    CFRelease(certificateRef);
    
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
                                               error:&error];
    [encryptedSebData appendData:encryptedData];
    
    return encryptedSebData;
}


@end
