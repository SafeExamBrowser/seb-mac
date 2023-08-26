//
//  SEBConfigFileManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 28.04.13.
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


#import "SEBConfigFileManager.h"
#import "RNDecryptor.h"
#import "RNEncryptor.h"
#import "SEBKeychainManager.h"
#import "SEBCryptor.h"
#import "NSData+NSDataZIPExtension.h"


@implementation SEBConfigFileManager

// Getter methods for write-only properties

- (NSString *)currentConfigPassword {
    [NSException raise:NSInternalInconsistencyException
                format:@"property is write-only"];
    return nil;
}

- (NSData *)currentConfigKeyHash {
    [NSException raise:NSInternalInconsistencyException
                format:@"property is write-only"];
    return nil;
}


#pragma mark Methods for Decrypting, Parsing and Storing SEB Settings to UserDefaults


// Load a SebClientSettings.seb file saved in the preferences directory
// and if it existed and was loaded, use it to re-configure SEB
- (void) reconfigureClientWithSebClientSettings
{
    NSData *sebData = [self.delegate getSEBClientSettings];
    if (sebData) {
        [self storeNewSEBSettings:sebData
                       forEditing:NO
           forceConfiguringClient:YES
                         callback:self
                         selector:@selector(reconfigureClientWithSebClientSettingsCallback)];
    }
}


/// Called after the client was sucesssfully reconfigured with persisted client settings
- (void) reconfigureClientWithSebClientSettingsCallback
{
    [self.delegate reconfigureClientWithSebClientSettingsCallback];
}


// Reconfigure SEB with settings received from an MDM server
-(void) reconfigueClientWithMDMSettingsDict:(NSDictionary *)sebPreferencesDict
                                   callback:(id)callback
                                   selector:(SEL)selector

{
    storeSettingsForEditing = false;
    storeSettingsForceConfiguringClient = true;
    storeSettingsCallback = callback;
    storeSettingsSelector = selector;
    sebFileCredentials = [SEBConfigFileCredentials new];
#ifdef DEBUG
    DDLogDebug(@"%s: Check received MDM settings %@", __FUNCTION__, sebPreferencesDict);
#endif
    [self checkParsedSettingForConfiguringAndStore:sebPreferencesDict];
}

// Decrypt, parse and store new SEB settings
// Method with selector in the callback object is called after storing settings
// was successful or aborted
-(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
                   callback:(id)callback
                   selector:(SEL)selector
{
    [self storeNewSEBSettings:sebData
                   forEditing:forEditing
       forceConfiguringClient:NO
                     callback:(id)callback
                     selector:(SEL)selector];
}


// Decrypt, parse and store new SEB settings
// When forceConfiguringClient, Exam Settings have the same effect as Client Settings
// Method with selector in the callback object is called after storing settings
// was successful or aborted
-(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
                   callback:(id)callback
                   selector:(SEL)selector
{
    [self storeNewSEBSettings:sebData
                   forEditing:forEditing
       forceConfiguringClient:forceConfiguringClient
         showReconfiguredAlert:YES
                     callback:callback
                     selector:selector];
}


// Decrypt, parse and store new SEB settings
// When forceConfiguringClient, Exam Settings have the same effect as Client Settings
// When showReconfigureAlert=false then don't show the reconfigured notification to the user
// Method with selector in the callback object is called after storing settings
// was successful or aborted
-(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
       showReconfiguredAlert:(BOOL)showReconfiguredAlert
                   callback:(id)callback
                   selector:(SEL)selector
{
    storeSettingsForEditing = forEditing;
    storeSettingsForceConfiguringClient = forceConfiguringClient;
    storeShowReconfiguredAlert = showReconfiguredAlert;
    storeSettingsCallback = callback;
    storeSettingsSelector = selector;
    sebFileCredentials = [SEBConfigFileCredentials new];

    // In editing mode we can get a saved existing config file password
    // (used when reverting to last saved/openend settings)
    if (forEditing) {
        sebFileCredentials.password = _currentConfigPassword;
        sebFileCredentials.passwordIsHash = _currentConfigPasswordIsHash;
        sebFileCredentials.publicKeyHash = _currentConfigKeyHash;
    }

    // Ungzip the .seb (according to specification >= v14) source data
    NSData *unzippedSebData = [sebData gzipInflate];
    // if unzipped data is not nil, then unzipping worked, we use unzipped data
    // if unzipped data is nil, then the source data may be an uncompressed .seb file, we proceed with it
    if (unzippedSebData) {
        sebData = unzippedSebData;
    }

    NSString *prefixString;
    
    // save the data including the first 4 bytes for the case that it's acutally an unencrypted XML plist
    NSData *sebDataUnencrypted = [sebData copy];
#ifdef DEBUG
    NSString *configDataString = [[NSString alloc] initWithData:sebData encoding:NSUTF8StringEncoding];
    DDLogDebug(@"Config data as string: %@", configDataString);
#endif

    // Get 4-char prefix
    prefixString = [self getPrefixStringFromData:&sebData];

    DDLogInfo(@"Outer prefix of .seb settings file: %@", prefixString);

    NSError *error = nil;

    //// Check prefix identifying encryption modes

    // Prefix = pkhs ("Public Key Hash") ?
    
    if ([prefixString isEqualToString:@"pkhs"]) {

        // Decrypt with cryptographic identity/private key
        sebData = [self decryptDataWithPublicKeyHashPrefix:sebData error:&error];
        if (!sebData || error) {
            // Inform callback that storing new settings failed
            [self storeNewSEBSettingsSuccessful:error];
            return;
        }

        // Get 4-char prefix again
        // and remaining data without prefix, which is either plain or still encoded with password
        prefixString = [self getPrefixStringFromData:&sebData];

        DDLogInfo(@"Inner prefix of .seb settings file: %@", prefixString);

    }

    // We cache the encrypted (or maybe already decrypted) settings data
    encryptedSEBData = sebData;
    
    // Prefix = pswd ("Password") ?
    
    if ([prefixString isEqualToString:@"pswd"]) {
        
        // Allow up to 5 attempts for entering decoding password
        attempts = 5;
        NSString *enterPasswordString = NSLocalizedString(@"Enter Exam Password:",nil);
        
        // Prompt for password
        // if we don't have it already
        if (forEditing && sebFileCredentials.password) {
            [self passwordSettingsStartingExam:sebFileCredentials.password];
        } else {
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.delegate promptPasswordWithMessageText:enterPasswordString
                                                   title:[NSString stringWithFormat:@"%@ (%@ %@)", NSLocalizedString(@"Starting Exam",nil), SEBShortAppName, MyGlobals.versionString]
                                                callback:self
                                                selector:@selector(passwordSettingsStartingExam:)];
        }
        return;
        
    } else {
        
        // Prefix = pwcc ("Password Configuring Client") ?
        
        if ([prefixString isEqualToString:@"pwcc"]) {
            
            // Decrypt with password and configure local client settings

            [self decryptDataWithPasswordForConfiguringClient];
            return;
            
        } else {

            // Prefix = plnd ("Plain Data") ?
            
            if (![prefixString isEqualToString:@"plnd"]) {
                // No valid 4-char prefix was found in the .seb file
                // Check if .seb file is unencrypted
                if ([prefixString isEqualToString:@"<?xm"]) {
                    // .seb file seems to be an unencrypted XML plist
                    // get the original data including the first 4 bytes
                    encryptedSEBData = sebDataUnencrypted;
                } else {
                    // No valid prefix and no unencrypted file with valid header
                    // cancel reading .seb file
                    
                    NSString *reason = @"No valid prefix and no unencrypted file with valid header";
                    NSError *error = [self errorCorruptedSettingsForUnderlyingErrorReason:reason];
                    
                    DDLogError(@"%s: %@ (underlying error: %@)", __FUNCTION__, error.userInfo, reason);

                    // Inform callback that storing new settings failed
                    [self storeNewSEBSettingsSuccessful:error];
                    return;
                }
            }
        }
    }
    
    // If we don't deal with an unencrypted seb file
    // ungzip the .seb (according to specification >= v14) decrypted serialized XML plist data
    if (![prefixString isEqualToString:@"<?xm"]) {
        encryptedSEBData = [encryptedSEBData gzipInflate];
    }
    [self parseSettingsStartingExamForEditing:forEditing];
}


- (NSError *) errorCorruptedSettingsForUnderlyingErrorReason:(NSString *)reason
{
    NSMutableDictionary *errorUserInfo = [NSMutableDictionary dictionary];
    errorUserInfo[NSLocalizedDescriptionKey] = NSLocalizedString(@"Parsing Settings Failed", @"");
    errorUserInfo[NSLocalizedFailureReasonErrorKey] = reason;
    NSError *underlyingError = [NSError errorWithDomain:sebErrorDomain
                                                   code:SEBErrorNoValidPrefixNoValidUnencryptedHeader
                                               userInfo:errorUserInfo];
    
    return [self errorCorruptedSettingsForUnderlyingError:underlyingError];
}


- (NSError *) errorCorruptedSettingsForUnderlyingError:(NSError *)error
{
    return [NSError errorWithDomain:sebErrorDomain
                               code:SEBErrorNoValidConfigData
                           userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Opening Settings Failed", @""),
                                      NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Loaded data doesn't contain valid %@ settings.", @""), SEBShortAppName],
                                      NSUnderlyingErrorKey : error}];
}


// Get preferences dictionary from decrypted data and store settings
-(void) parseSettingsStartingExamForEditing:(BOOL)forEditing {
    NSError *error = nil;
    // Get preferences dictionary from decrypted data
    NSDictionary *sebPreferencesDict = [self getPreferencesDictionaryFromConfigData:encryptedSEBData
                                                                         forEditing:forEditing
                                                                              error:&error];
    // If we didn't get a preferences dict back, we abort reading settings
    if (!sebPreferencesDict) {
        // Inform callback that storing new settings failed
        [self storeNewSEBSettingsSuccessful:error];
        return;
    }
    
    // Check if a some value is from a wrong class (another than the value from default settings)
    // and quit reading .seb file if a wrong value was found
    if (![self checkClassOfSettings:sebPreferencesDict error:&error]) {
        // Inform callback that storing new settings failed
        [self storeNewSEBSettingsSuccessful:error];
        return;
    }

    // Reading preferences was successful!
    [self storeDecryptedSEBSettings:sebPreferencesDict];
}


// Inform the callback method if decrypting, parsing and storing new settings was successful or not
- (void) storeNewSEBSettingsSuccessful:(NSError *)error {
    DDLogDebug(@"%s, continue with callback: %@ selector: %@", __FUNCTION__, storeSettingsCallback, NSStringFromSelector(storeSettingsSelector));
    IMP imp = [storeSettingsCallback methodForSelector:storeSettingsSelector];
    void (*func)(id, SEL, NSError*) = (void *)imp;
    func(storeSettingsCallback, storeSettingsSelector, error);
}


- (void) passwordSettingsStartingExam:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
        // Inform callback that storing new settings failed
        [self storeNewSEBSettingsSuccessful:[NSError errorWithDomain:sebErrorDomain
                                                                code:SEBErrorDecryptingSettingsCanceled
                                                            userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Cannot Start Exam", @""),
                                                                       NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"Decrypting exam settings was canceled", @"")}]];
        return;
    }
    
    NSError *error = nil;
    NSData *sebDataDecrypted = [RNDecryptor decryptData:encryptedSEBData withPassword:password error:&error];
    attempts--;

    if (error || !sebDataDecrypted) {
        // wrong password entered, are there still attempts left?
        if (attempts > 0) {
            // Let the user try it again
            NSString *enterPasswordString = NSLocalizedString(@"Wrong password! Try again to enter the correct exam password:",nil);
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.delegate promptPasswordWithMessageText:enterPasswordString
                                                   title:NSLocalizedString(@"Starting Exam",nil)
                                                callback:self
                                                selector:@selector(passwordSettingsStartingExam:)];
            return;
            
        } else {
            // Wrong password entered in the last allowed attempts: Stop reading .seb file
            DDLogError(@"%s: Cannot Decrypt Settings: User either entered the wrong password several times or these settings were saved with an incompatible SEB version.", __FUNCTION__);
            // Inform callback that storing new settings failed
            [self storeNewSEBSettingsSuccessful:[NSError errorWithDomain:sebErrorDomain
                                                                    code:SEBErrorDecryptingNoSettingsPasswordEntered
                                                                userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Cannot Start Exam", @""),
                                                                           NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"You didn't enter the correct exam password.", @"")}]];
            return;
        }
        
    } else {
        // The .seb data was decrypted successfully
        // Ungzip the .seb (according to specification >= v14) decrypted serialized XML plist data
        encryptedSEBData = [sebDataDecrypted gzipInflate];
        // We save the decryption password
        sebFileCredentials.password = password;
        
        // Get preferences dictionary from decrypted data and store settings
        [self parseSettingsStartingExamForEditing:storeSettingsForEditing];
    }
}


// Get admin password hash from current settings
static NSString *getHashedAdminPassword(void)
{
    NSString *hashedAdminPassword = [[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
    if (!hashedAdminPassword) {
        // If there was no hashed admin password saved, we set it to an empty string
        // as this is the standard password used to encrypt settings for configuring client
        hashedAdminPassword = @"";
    }
    return hashedAdminPassword;
}


// Get admin password hash from current settings
static NSString *getUppercaseAdminPasswordHash(void)
{
    NSString *hashedAdminPassword = getHashedAdminPassword();
    return [hashedAdminPassword uppercaseString];
}


- (NSString *) getHashedAdminPassword
{
    return getHashedAdminPassword();
}


// Helper method which decrypts the data using an empty password,
// or the administrator password currently set in SEB
// or asks for the password used for encrypting this SEB file
// for configuring the client

- (void) decryptDataWithPasswordForConfiguringClient
{
    // We set the passwordIsHash flag to false here as indicator that another as the current admin password was used
    // to decrypt settings (when the hashed admin password can be used to decryt, then it is set to true below)
    sebFileCredentials.passwordIsHash = false;
    // First try to decrypt with the current admin password
    // get admin password hash
    NSString * hashedAdminPassword = getHashedAdminPassword();
    NSError *error = nil;
    NSData *sebDataDecrypted = [RNDecryptor decryptData:encryptedSEBData withPassword:hashedAdminPassword error:&error];
    if (error || !sebDataDecrypted) {
        // For compatibility with the previous (wrong) implementation, we try it with an uppercase hash
        hashedAdminPassword = [hashedAdminPassword uppercaseString];
        error = nil;
        sebDataDecrypted = [RNDecryptor decryptData:encryptedSEBData withPassword:hashedAdminPassword error:&error];
    }
    if (error || !sebDataDecrypted) {
        // If decryption with admin password didn't work, try it with an empty password
        error = nil;
        sebDataDecrypted = [RNDecryptor decryptData:encryptedSEBData withPassword:@"" error:&error];
        if (error || !sebDataDecrypted) {
            // If decryption with empty and admin password didn't work, ask for the password the .seb file was encrypted with
            // Allow up to 5 attempts for entering decoding password
            attempts = 5;
            NSString *enterPasswordString = NSLocalizedString(@"Enter password used to encrypt these settings:",nil);
            
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.delegate promptPasswordWithMessageText:enterPasswordString
                                                   title:NSLocalizedString(@"Configuring Client",nil)
                                                callback:self
                                                selector:@selector(passwordSettingsConfiguringClient:)];
            return;
        }
    } else {
        //decrypting with hashedAdminPassword worked: we save it for returning as decryption password
        sebFileCredentials.password = hashedAdminPassword;
        // identify this password as hash
        sebFileCredentials.passwordIsHash = true;
    }
    // Decrypting settings for configuring client was successful: continue processing it
    encryptedSEBData = sebDataDecrypted;
    [self decryptForConfiguringClientSuccessful];
}


- (void) passwordSettingsConfiguringClient:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
        // Inform callback that storing new settings failed
        [self storeNewSEBSettingsSuccessful:[NSError errorWithDomain:sebErrorDomain
                                                                code:SEBErrorDecryptingSettingsCanceled
                                                            userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Cannot Configure Client", @""),
                                                                       NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"Decrypting settings was canceled", @"")}]];
        return;
    }
    
    // In settings for configuring client the hashed password is used for encrypting/decrypting
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSString *hashedPassword = [keychainManager generateSHAHashString:password];
    NSError *error = nil;
    NSData *sebDataDecrypted = [RNDecryptor decryptData:encryptedSEBData withPassword:hashedPassword error:&error];
    if (!sebDataDecrypted || error) {
        // For compatibility with the previous (wrong) implementation, we try it with an uppercase hash
        hashedPassword = [hashedPassword uppercaseString];
        error = nil;
        sebDataDecrypted = [RNDecryptor decryptData:encryptedSEBData withPassword:hashedPassword error:&error];
    }
    attempts--;
    
    if (error || !sebDataDecrypted) {
        // wrong password entered, are there still attempts left?
        if (attempts > 0) {
            // Let the user try it again
            NSString *enterPasswordString = NSLocalizedString(@"Wrong password! Try again to enter the correct password used to encrypt these settings:",nil);
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.delegate promptPasswordWithMessageText:enterPasswordString callback:self selector:@selector(passwordSettingsConfiguringClient:)];
            return;
            
        } else {
            // Wrong password entered in the last allowed attempts: Stop reading .seb file
            DDLogError(@"%s: Cannot Decrypt Settings: User either entered the wrong password several times or these settings were saved with an incompatible SEB version.", __FUNCTION__);
            // Inform callback that storing new settings failed
            [self storeNewSEBSettingsSuccessful:[NSError errorWithDomain:sebErrorDomain
                                                                    code:SEBErrorDecryptingNoSettingsPasswordEntered
                                                                userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Cannot Configure Client", @""),
                                                                           NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"You didn't enter the correct settings password.", @"")}]];
            return;
        }
        
    } else {
        // Decrypting settings for configuring client was successful: continue processing it
        encryptedSEBData = sebDataDecrypted;
        [self decryptForConfiguringClientSuccessful];
    }
}


// Decrypting the settings for configuring client was successful:
// We have to find out if we're allowed to use it
- (void) decryptForConfiguringClientSuccessful
{
    // Ungzip the .seb (according to specification >= v14) decrypted serialized XML plist data
    encryptedSEBData = [encryptedSEBData gzipInflate];
    // Check if the openend reconfiguring seb file has the same admin password inside as the current one
    // Get the preferences dictionary
    NSError *error = nil;
    parsedSEBPreferencesDict = [self getPreferencesDictionaryFromConfigData:encryptedSEBData error:&error];
    if (error) {
        // Error when deserializing the decrypted configuration data
        // Inform callback that storing new settings failed
        [self storeNewSEBSettingsSuccessful:error];
        return; //we abort reading the new settings here
    }
    // Get the admin password set in these settings
    NSString *sebFileHashedAdminPassword = [parsedSEBPreferencesDict objectForKey:@"hashedAdminPassword"];
    if (!sebFileHashedAdminPassword) {
        sebFileHashedAdminPassword = @"";
    }
    NSString * hashedAdminPassword = getUppercaseAdminPasswordHash();
    
    // Has the SEB config file the same admin password inside as the current one?
    // If yes, then we can directly use those setting to configure the client
    if ([hashedAdminPassword caseInsensitiveCompare:sebFileHashedAdminPassword] != NSOrderedSame) {
        //No: The admin password inside the .seb file wasn't the same as the current one
        if (storeSettingsForEditing) {
            // If the file is openend for editing (and not to reconfigure SEB)
            // we have to ask the user for the admin password inside the file
            if (![self askForPasswordAndCompareToHashedPassword:sebFileHashedAdminPassword error:&error]) {
                // If the user didn't enter the right password we abort
                // Inform callback that storing new settings failed
                [self storeNewSEBSettingsSuccessful:error];
                return;
            }
        } else {
            // The file was actually opened for reconfiguring the SEB client:
            // we have to ask for the current admin password and
            // allow reconfiguring only if the user enters the right one
            // We don't check this only for the case the current admin password was used to encrypt/decrypt those settings
            // In this case there can be a new admin pw defined in the new settings and users don't need to enter the old one
            if (sebFileCredentials.passwordIsHash == false && hashedAdminPassword.length > 0) {
                
                // Allow up to 5 attempts for entering decoding password
                attempts = 5;
                NSString *enterPasswordString = [NSString stringWithFormat:NSLocalizedString(@"You can only reconfigure by entering the current %@ administrator password:", @""), SEBShortAppName];
                
                // Ask the user to enter the settings password and proceed to the callback method after this happend
                [self.delegate promptPasswordWithMessageText:enterPasswordString
                                                       title:NSLocalizedString(@"Configuring Client",nil)
                                                    callback:self
                                                    selector:@selector(adminPasswordSettingsConfiguringClient:)];
                return;
            }
        }
    }
    
    [self checkParsedSettingForConfiguringAndStore:parsedSEBPreferencesDict];
}


- (void) adminPasswordSettingsConfiguringClient:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
        // Inform callback that storing new settings failed
        [self storeNewSEBSettingsSuccessful:[NSError errorWithDomain:sebErrorDomain
                                                                code:SEBErrorDecryptingSettingsAdminPasswordCanceled
                                                            userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Cannot Reconfigure Client", @""),
                                                                       NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Entering the current %@ administrator password was canceled", @""), SEBShortAppName]}]];
        return;
    }

    // Get admin password hash from current client settings
    NSString *hashedAdminPassword = getUppercaseAdminPasswordHash();

    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSString *hashedPassword;
    if (password.length == 0) {
        // An empty password has to be an empty hashed password string
        hashedPassword = @"";
    } else {
        hashedPassword = [keychainManager generateSHAHashString:password];
        hashedPassword = [hashedPassword uppercaseString];
    }
    
    attempts--;
    
    if ([hashedPassword caseInsensitiveCompare:hashedAdminPassword] != NSOrderedSame) {
        // wrong password entered, are there still attempts left?
        if (attempts > 0) {
            // Let the user try it again
            NSString *enterPasswordString = [NSString stringWithFormat:NSLocalizedString(@"Wrong password! Try again to enter the current %@ administrator password:",nil), SEBShortAppName];
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.delegate promptPasswordWithMessageText:enterPasswordString
                                                   title:NSLocalizedString(@"Configuring Client",nil)
                                                callback:self
                                                selector:@selector(adminPasswordSettingsConfiguringClient:)];
            return;
            
        } else {
            // Wrong password entered in the last allowed attempts: Stop reading .seb file
            NSError *error = [NSError errorWithDomain:sebErrorDomain
                                                 code:SEBErrorDecryptingNoAdminPasswordEntered
                                             userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Cannot Reconfigure Client", @""),
                                                        NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"You didn't enter the correct current %@ administrator password.", @""), SEBShortAppName]}];
            DDLogError(@"%s: %@ ", __FUNCTION__, error.userInfo);

            // Inform callback that storing new settings failed
            [self storeNewSEBSettingsSuccessful:error];
            return;
        }
        
    } else {
        // The correct admin password was entered: continue processing the parsed SEB settings it
        [self checkParsedSettingForConfiguringAndStore:parsedSEBPreferencesDict];
    }
}


- (void) promptPasswordForHashedPassword:(NSString *)passwordHash
                             messageText:(NSString *)messageText
                                   title:(NSString *)title
                       completionHandler:(void (^)(BOOL correctPasswordEntered))enteredPasswordHandler
{
    // Allow up to 5 attempts for entering the password
    NSInteger attempts = 5;
    [self.delegate promptPasswordForHashedPassword:passwordHash messageText:messageText title:title attempts:attempts callback:self selector:@selector(checkEnteredPassword:hashedPassword:messageText:title:attempts:completionHandler:) completionHandler:enteredPasswordHandler];
}


- (void) checkEnteredPassword:(NSString *)password
               hashedPassword:(NSString *)passwordHash
                  messageText:(NSString *)messageText
                        title:(NSString *)title
                     attempts:(NSInteger)attempts
            completionHandler:(void (^)(BOOL correctPasswordEntered))enteredPasswordHandler
{
    if (password == nil) {
        if (enteredPasswordHandler) {
            enteredPasswordHandler(NO);
        }
        return;
    }
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSString *hashedPassword;
    if (password.length == 0) {
        // An empty password has to be an empty hashed password string
        hashedPassword = @"";
    } else {
        hashedPassword = [keychainManager generateSHAHashString:password];
        hashedPassword = [hashedPassword uppercaseString];
    }
    
    attempts--;
    
    if ([hashedPassword caseInsensitiveCompare:passwordHash] != NSOrderedSame) {
        // wrong password entered, are there still attempts left?
        if (attempts > 0) {
            // Let the user try it again
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.delegate promptPasswordForHashedPassword:passwordHash messageText:messageText title:title attempts:attempts callback:self selector:@selector(checkEnteredPassword:hashedPassword:messageText:title:attempts:completionHandler:) completionHandler:enteredPasswordHandler];
            return;
            
        } else {
            // Wrong password entered in the last allowed attempts
            // Inform completion handler that entering the correct password failed
            if (enteredPasswordHandler) {
                enteredPasswordHandler(NO);
            }
            return;
        }
        
    } else {
        // Inform completion handler that entering the correct password correct admin password succeeded
        if (enteredPasswordHandler) {
            enteredPasswordHandler(YES);
        }
    }
}


// Check if a some value is from a wrong class (another than the value from default settings)
// and quit reading .seb file if a wrong value was found
- (void) checkParsedSettingForConfiguringAndStore:(NSDictionary *)sebPreferencesDict {
    NSError *error = nil;
    if (![self checkClassOfSettings:sebPreferencesDict error:&error]) {
        DDLogError(@"%s: Checking settings failed!", __FUNCTION__);
        // Inform callback that storing new settings failed
        [self storeNewSEBSettingsSuccessful:error];
        return;
    }
    
    // Reading preferences was successful!
    DDLogInfo(@"%s: Checking received settings was successful", __FUNCTION__);
    [self storeDecryptedSEBSettings:sebPreferencesDict];
}


// Store and use new SEB settings
- (void) storeDecryptedSEBSettings:(NSDictionary *)sebPreferencesDict
{
    if (!sebPreferencesDict) {
        return; //Decryption didn't work, we abort
    }
    
    id sebConfigPurposeValue = [sebPreferencesDict valueForKey:@"sebConfigPurpose"];
    NSUInteger sebConfigPurpose = sebConfigPurposeDefault;
    if (sebConfigPurposeValue) {
        sebConfigPurpose = [sebConfigPurposeValue intValue];
    }
    
    if (!storeSettingsForceConfiguringClient && (storeSettingsForEditing || sebConfigPurpose == sebConfigPurposeStartingExam)) {
        
        ///
        /// If these SEB settings are ment to start an exam or we're in editing mode
        ///
        
        if (!storeSettingsForEditing && sebConfigPurpose == sebConfigPurposeStartingExam) {
            if ((_delegate.startingExamFromSEBServer || _delegate.sebServerConnectionEstablished) && [[sebPreferencesDict valueForKey:@"sebMode"] intValue] == sebModeSebServer) {
                
                DDLogError(@"%s: There is already a SEB Server session running. It is not allowed to reconfigure for another SEB Server session.", __FUNCTION__);

                NSString *title = NSLocalizedString(@"Cannot Start Another SEB Server Session", @"");
                NSString *informativeText = NSLocalizedString(@"There is already a SEB Server session running. It is not allowed to reconfigure for another SEB Server session. Quit the SEB Server session first.", @"");
                [self.delegate showAlertWithTitle:title andText:informativeText];

                return;
            }
        }
        // Inform delegate that preferences will be reconfigured
        if ([self.delegate respondsToSelector:@selector(willReconfigureTemporary)]) {
            [self.delegate willReconfigureTemporary];
        }
        
        // Switch to private UserDefaults (saved non-persistently in memory instead in ~/Library/Preferences)
        NSMutableDictionary *privatePreferences = [NSUserDefaults privateUserDefaults]; //this mutable dictionary has to be referenced here, otherwise preferences values will not be saved!
        [NSUserDefaults setUserDefaultsPrivate:YES];
        
        // Write values from .seb config file to the local preferences (shared UserDefaults)
        [self storeIntoUserDefaults:sebPreferencesDict];
        
        DDLogVerbose(@"%s, Temporary preferences set: %@", __FUNCTION__, privatePreferences);
        
        if (storeSettingsForEditing == NO) {
            // if not editing reset credentials
            _currentConfigPassword = nil;
            _currentConfigPasswordIsHash = NO;
            _currentConfigKeyHash = nil;
        }
        
        // Inform delegate that preferences were reconfigured
        if ([self.delegate respondsToSelector:@selector(didReconfigureTemporaryForEditing:sebFileCredentials:)]) {
            [self.delegate didReconfigureTemporaryForEditing:storeSettingsForEditing
                                          sebFileCredentials:sebFileCredentials];
        }
        
        // Inform callback that storing new settings was successful
        [self storeNewSEBSettingsSuccessful:nil];
        return;
        
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
                DDLogVerbose(@"%s: Removing embedded certficate at index %ld", __FUNCTION__, (long)i);
                [embeddedCertificates removeObjectAtIndex:i];
            }
        }
        
        // Write values from .seb config file to the local preferences (shared UserDefaults)
        [self storeIntoUserDefaults:sebPreferencesDict];
        
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
        // Reset credentials for reverting to these
        _currentConfigPassword = nil;
        _currentConfigPasswordIsHash = NO;
        _currentConfigKeyHash = nil;
        
        DDLogInfo(@"Should display dialog SEB Re-Configured");
        
        // Inform delegate that preferences were reconfigured
        if ([self.delegate respondsToSelector:@selector(didReconfigurePermanentlyForceConfiguringClient:sebFileCredentials:showReconfiguredAlert:)]) {
            [self.delegate didReconfigurePermanentlyForceConfiguringClient:storeSettingsForceConfiguringClient
                                                        sebFileCredentials:sebFileCredentials showReconfiguredAlert:storeShowReconfiguredAlert];
            return;
            
        } else {
            // Inform callback that storing new settings was successful
            [self storeNewSEBSettingsSuccessful:nil];
        }
    }
}


// Check if a some value is from a wrong class (another than the value from default settings)
- (BOOL)checkClassOfSettings:(NSDictionary *)sebPreferencesDict error:(NSError **)error
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

            *error = [NSError errorWithDomain:sebErrorDomain
                                         code:SEBErrorParsingSettingsFailedValueClassMissmatch
                                     userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Reading Settings Failed", @""),
                                                NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"These settings are corrupted and cannot be used (failing key: %@).", @""), key]}];
            
            return NO; //we abort reading the new settings here
        }
    }
    return YES;
}


// Get preferences dictionary from decrypted data.
// In editing mode, users have to enter the right SEB administrator password
// before they can access the settings contents
// and returns the decrypted bytes
-(NSDictionary *) getPreferencesDictionaryFromConfigData:(NSData *)sebData forEditing:(BOOL)forEditing error:(NSError **)error
{
    // Get preferences dictionary from decrypted data
    NSDictionary *sebPreferencesDict = [self getPreferencesDictionaryFromConfigData:sebData error:error];
    if (*error) {
        DDLogError(@"%s: Failed serializing XML plist! Error: %@", __FUNCTION__, *error);

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
            NSString *hashedAdminPassword = getHashedAdminPassword();
            // If the current hashed admin password is same as the hashed admin password from the settings file
            // then the user is allowed to access the settings
            if ([hashedAdminPassword caseInsensitiveCompare:sebFileHashedAdminPassword] != NSOrderedSame) {
                // otherwise we have to ask for the SEB administrator password used in those settings and
                // allow opening settings only if the user enters the right one
                
                if (![self askForPasswordAndCompareToHashedPassword:sebFileHashedAdminPassword error:error]) {
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
        DDLogError(@"%s: Failed serializing of the XML plist ! Error: %@", __FUNCTION__, plistError.description);
        NSString *failureReason = [plistError localizedFailureReason];
        if (!failureReason) {
            failureReason = @"";
        }
        *error = [[NSError alloc] initWithDomain:sebErrorDomain
                                            code:SEBErrorParsingSettingsSerializingFailed
                                        userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Reading Settings Failed", @""),
                                                    NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"These settings are corrupted and cannot be used.", @""),
                                                    NSLocalizedFailureReasonErrorKey : failureReason,
                                                    NSUnderlyingErrorKey : plistError
                                                    }];
        sebPreferencesDict = nil; //we don't have any settings to return
    }
    return sebPreferencesDict;
}


// Ask user to enter password and compare it to the passed (hashed) password string
- (BOOL) askForPasswordAndCompareToHashedPassword:(NSString *)sebFileHashedAdminPassword error:(NSError **)error
{
    // Check if there wasn't a hashed password (= empty password)
    if (sebFileHashedAdminPassword.length == 0) return true;
    
    // We can only ask for the admin password if the SEBConfigUIDelegate implements a modal
    // password dialog. This isn't the case on iOS, but there this method never should be called
    // because opening SEB settings for editing isn't supported in SEB for iOS
    if (![self.delegate respondsToSelector:@selector(promptPasswordWithMessageTextModal:title:)]) {
        return false;
    }
    // Ask for a SEB administrator password and
    // allow opening settings only if the user enters the right one
    // Allow up to 5 attempts for entering admin password
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    int i = 5;
    NSString *password = nil;
    NSString *hashedPassword;
    bool passwordsMatch;
    do {
        i--;
        // Prompt for password
        password = [self.delegate promptPasswordWithMessageTextModal:[NSString stringWithFormat:NSLocalizedString(@"Enter the %@ administrator password used in these settings:",nil), SEBShortAppName]
                                                               title:NSLocalizedString(@"Loading settings",nil)];
        if (!password) {
            // If cancel was pressed, abort
            return false;
        }
        if (password.length == 0) {
            hashedPassword = @"";
        } else {
            hashedPassword = [keychainManager generateSHAHashString:password];
        }
        passwordsMatch = (hashedPassword && [hashedPassword caseInsensitiveCompare:sebFileHashedAdminPassword] == NSOrderedSame);
        // in case we get an error we allow the user to try it again
    } while ((password == nil || !passwordsMatch) && i > 0);
    
    if (!passwordsMatch) {
        //wrong password entered in 5th try: stop reading .seb file
        NSString *title = NSLocalizedString(@"Loading Settings", @"");
        NSString *informativeText = NSLocalizedString(@"If you don't enter the right administrator password used in these settings you cannot open them.", @"");
        [self.delegate showAlertWithTitle:title andText:informativeText];

        DDLogError(@"%s: Loading Settings: If you don't enter the right administrator password used in these settings you cannot open them.", __FUNCTION__);
        
        return NO;
    }
    // Right password entered
    return YES;
}


// Save imported settings into user defaults (either in private memory or local shared UserDefaults)
-(void) storeIntoUserDefaults:(NSDictionary *)sebPreferencesDict
{
    NSDictionary *configKeyContainedKeys = [NSDictionary dictionary];
    NSData *configKey = [NSData data];
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    // We reset the Config Key in current user defaults, to make sure it is freshly calculated for loaded settings
    [preferences setSecureObject:nil forKey:@"org_safeexambrowser_configKey"];
    sebPreferencesDict = [[SEBCryptor sharedSEBCryptor] updateConfigKeyInSettings:sebPreferencesDict
                                                        configKeyContainedKeysRef:&configKeyContainedKeys
                                                                     configKeyRef:&configKey
                                                          initializeContainedKeys:YES];
    
    [preferences storeSEBDictionary:sebPreferencesDict];

    [preferences setSecureObject:configKeyContainedKeys forKey:@"org_safeexambrowser_configKeyContainedKeys"];
    // Store new Config Key in UserDefaults
    [preferences setSecureObject:configKey forKey:@"org_safeexambrowser_configKey"];
    
}


// Helper method which fetches the public key hash from a seb data object,
// retrieves the according cryptographic identity from the keychain
// and returns the decrypted data
-(NSData *) decryptDataWithPublicKeyHashPrefix:(NSData *)sebData error:(NSError **)error
{
    // Get 20 bytes public key hash prefix
    // and remaining data with the prefix stripped
    NSData *publicKeyHash = [self getPrefixDataFromData:&sebData withLength:publicKeyHashLenght];
    
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    SecKeyRef privateKeyRef = [keychainManager getPrivateKeyFromPublicKeyHash:publicKeyHash];
    if (!privateKeyRef) {

        *error = [NSError errorWithDomain:sebErrorDomain
                                     code:SEBErrorDecryptingIdentityNotFound
                                 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Error Decrypting Settings", @""),
                                            NSLocalizedRecoverySuggestionErrorKey : [NSString stringWithFormat:NSLocalizedString(@"The identity certificate needed to decrypt these settings isn't installed on this device. %@ might not have been configured correctly for your institution.", @""), SEBShortAppName]}];
        DDLogError(@"%s: %@", __FUNCTION__, [*error userInfo]);
        sebFileCredentials.publicKeyHash = nil;
        return nil;
    }

    DDLogInfo(@"Private key retrieved with hash: %@", publicKeyHash);

    // If these settings are being decrypted for editing, we will return the decryption certificate reference
    // in the variable which was passed as reference when calling this method
    sebFileCredentials.publicKeyHash = publicKeyHash;
    
    sebData = [keychainManager decryptData:sebData withPrivateKey:privateKeyRef];
    
    if (!sebData) {

        *error = [NSError errorWithDomain:sebErrorDomain
                                     code:SEBErrorDecryptingIdentityNotFound
                                 userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Error Decrypting Settings", @""),
                                            NSLocalizedRecoverySuggestionErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Couldn't access the identity certificate needed to decrypt these settings. %@ might not have been configured correctly for your institution.", @""), SEBShortAppName]}];
        DDLogError(@"%s: %@", __FUNCTION__, [*error userInfo]);
        sebFileCredentials.publicKeyHash = nil;
        return nil;
    }
    
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
                                 forPurpose:(sebConfigPurposes)configPurpose
                             removeDefaults:(BOOL)removeDefaults
{

    // Copy preferences to a dictionary
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *filteredPrefsDict;
    filteredPrefsDict = [NSMutableDictionary dictionaryWithDictionary:[preferences dictionaryRepresentationSEBRemoveDefaults:removeDefaults]];
    
    if (!removeDefaults) {
        // Write SEB_OS_version_build version information to .seb settings
        NSString *originatorVersion = [NSString stringWithFormat:@"SEB_iOS_%@_%@",
                                       [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"],
                                       [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"]];
        [filteredPrefsDict setObject:originatorVersion forKey:@"originatorVersion"];
    } else {
        [filteredPrefsDict removeObjectForKey:@"sebConfigPurpose"];
    }
    
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
        
//        [self.delegate showAlertCorruptedSettings];

        return nil;
    }
    
    NSMutableString *sebXML = [[NSMutableString alloc] initWithData:dataRep encoding:NSUTF8StringEncoding];
    DDLogVerbose(@".seb XML plist: %@", sebXML);
    
    NSData *encryptedSebData = [sebXML dataUsingEncoding:NSUTF8StringEncoding];
    //NSData *encryptedSebData = [NSKeyedArchiver archivedDataWithRootObject:filteredPrefsDict];
    
    NSString *encryptingPassword = nil;
    
    // Check for special case: SEB settings for Managed Configuration
    if (configPurpose == sebConfigPurposeManagedConfiguration) {
        // Return SEB config data unencrypted and not gzip compressed
        return encryptedSebData;
    }
    
    // gzip the serialized XML data
    encryptedSebData = [encryptedSebData gzipDeflate];
    
    // Check for special case: SEB settings for configuring client, empty password
    if (settingsPassword.length == 0 && configPurpose == sebConfigPurposeConfiguringClient) {
        encryptingPassword = @"";
    } else {
        // in all other cases:
        // Check if no password entered and no identity selected
        if (settingsPassword.length == 0 && !identityRef && configPurpose != sebConfigPurposeManagedConfiguration) {
            if ([self.delegate saveSettingsUnencrypted]) {
                // save .seb config data unencrypted
                return encryptedSebData;
            } else {
                // don't save the config data
                return nil;
            }
        }
    }
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
