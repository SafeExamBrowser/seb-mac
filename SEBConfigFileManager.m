//
//  SEBConfigFileManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 28.04.13.
//
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


#pragma mark Methods for Decrypting, Parsing and Storing SEB Settings to UserDefaults

// Decrypt, parse and store SEB settings to UserDefaults
-(BOOL) storeDecryptedSEBSettings:(NSData *)sebData
{
    NSDictionary *sebPreferencesDict;
    NSString *sebFilePassword = nil;
    SecKeyRef sebFileKeyRef = nil;
    
    sebPreferencesDict = [self decryptSEBSettings:sebData forEditing:NO sebFilePassword:&sebFilePassword sebFileKeyRef:&sebFileKeyRef];
    if (!sebPreferencesDict) return NO; //Decryption didn't work, we abort
    
    if ([[sebPreferencesDict valueForKey:@"sebConfigPurpose"] intValue] == sebConfigPurposeStartingExam) {

        /// If these SEB settings are ment to start an exam

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
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults];
        [self.sebController.preferencesController initPreferencesWindow];
        
        return YES; //reading preferences was successful

    } else {

        /// If these SEB settings are ment to configure a client

        //switch to system's UserDefaults
        [NSUserDefaults setUserDefaultsPrivate:NO];
        
        // Write values from .seb config file to the local preferences (shared UserDefaults)
        [self storeIntoUserDefaults:sebPreferencesDict];
        
        int answer = NSRunAlertPanel(NSLocalizedString(@"SEB Re-Configured",nil), NSLocalizedString(@"Local settings of this SEB client have been reconfigured. Do you want to start working with SEB now or quit?",nil),
                                     NSLocalizedString(@"Continue",nil), NSLocalizedString(@"Quit",nil), nil);
        switch(answer)
        {
            case NSAlertDefaultReturn:
                break; //Cancel: don't quit
            default:
                self.sebController.quittingMyself = TRUE; //SEB is terminating itself
                [NSApp terminate: nil]; //quit SEB
        }
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults];
        
        return YES; //reading preferences was successful
    }
}


// Decrypt SEB settings according to a dictionary with the settings' key/values
-(NSDictionary *) decryptSEBSettings:(NSData *)sebData forEditing:(BOOL)forEditing sebFilePassword:(NSString **)sebFilePasswordPtr sebFileKeyRef:(SecKeyRef *)sebFileKeyRefPtr
{
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
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
        // Allow up to 5 attempts for entering decoding password
        NSString *enterPasswordString = NSLocalizedString(@"Enter Password:",nil);
        int i = 5;
        do {
            i--;
            // Prompt for password
            if ([self.sebController showEnterPasswordDialog:enterPasswordString modalForWindow:nil windowTitle:NSLocalizedString(@"Loading new settings",nil)] == SEBEnterPasswordCancel) return nil;
            NSString *password = [self.sebController.enterPassword stringValue];
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
        }
        sebData = sebDataDecrypted;
    } else {
        
        // Prefix = pwcc ("Password Configuring Client") ?
        
        if ([prefixString isEqualToString:@"pwcc"]) {
            
            // Decrypt with password and configure local client settings
            // and quit afterwards, returning if reading the .seb file was successfull

            return [self decryptDataWithPasswordForConfiguringClient:sebData forEditing:forEditing sebFilePassword:sebFilePasswordPtr];
            
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
    
    // Decryption worked
    // If we don't deal with an unencrypted seb file
    // ungzip the .seb (according to specification >= v14) decrypted serialized XML plist data
    if (![prefixString isEqualToString:@"<?xm"]) sebData = [sebData gzipInflate];

    // Get preferences dictionary from decrypted data
    error = nil;
    //NSDictionary *sebPreferencesDict = [NSKeyedUnarchiver unarchiveObjectWithData:sebData];
    NSDictionary *sebPreferencesDict = [self getPreferencesDictionaryFromConfigData:sebData error:&error];
    if (error) {
        [NSApp presentError:error];
        return nil; //we abort reading the new settings here
    }

    /// In editing mode, if the current administrator password isn't the same as in the new settings,
    /// the user has to enter the right SEB administrator password before he can access the settings contents
    if (forEditing)
    {
        NSString *sebFileHashedAdminPassword = [sebPreferencesDict objectForKey:@"hashedAdminPassword"];
        // If there is an admin password saved in the settings
        if (sebFileHashedAdminPassword) {
            // Get the current admin password
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            NSString *hashedAdminPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
            if (!hashedAdminPassword) hashedAdminPassword = @"";
            // If the current hashed admin password is same like the hashed admin password from the settings file
            // then the user is allowed to access the settings
            if ([hashedAdminPassword caseInsensitiveCompare:sebFileHashedAdminPassword] != NSOrderedSame) {
                // otherwise we have to ask for the current SEB administrator password and
                // allow opening settings only if the user enters the right one
                // Allow up to 5 attempts for entering  admin password
                int i = 5;
                NSString *password = nil;
                NSString *hashedPassword;
                NSString *enterPasswordString = NSLocalizedString(@"Enter the SEB administrator password used in these settings:",nil);
                bool passwordsMatch;
                do
                {
                    i--;
                    // Prompt for password
                    if ([self.sebController showEnterPasswordDialog:enterPasswordString modalForWindow:nil windowTitle:NSLocalizedString(@"Loading settings",nil)] == SEBEnterPasswordCancel) return nil;
                    NSString *password = [self.sebController.enterPassword stringValue];
                    hashedPassword = [keychainManager generateSHAHashString:password];
                    if ([hashedPassword caseInsensitiveCompare:sebFileHashedAdminPassword] == NSOrderedSame)
                    {
                        passwordsMatch = true;
                    }
                    else
                    {
                        passwordsMatch = false;
                    }
                    // in case we get an error we allow the user to try it again
                    enterPasswordString = NSLocalizedString(@"Wrong password! Try again to enter the correct SEB administrator password from these settings:", nil);
                } while ((password == nil || !passwordsMatch) && i > 0);
                if (!passwordsMatch)
                {
                    //wrong password entered in 5th try: stop reading .seb file
                    NSRunAlertPanel(NSLocalizedString(@"Loading Settings", nil),
                                    NSLocalizedString(@"If you don't enter the right administrator password from these settings you cannot open them.", nil),
                                    NSLocalizedString(@"OK", nil), nil, nil);
                    return nil;
                }
            }
        }
    }
    
    // Check if a some value is from a wrong class (another than the value from default settings)
    // and quit reading .seb file if a wrong value was found
    if (![self checkClassOfSettings:sebPreferencesDict]) return nil;
    
    // We need to set the right value for the key sebConfigPurpose to know later where to store the new settings
    [sebPreferencesDict setValue:[NSNumber numberWithInt:sebConfigPurposeStartingExam] forKey:@"sebConfigPurpose"];
    
    return sebPreferencesDict;
}


-(NSDictionary *) decryptDataWithPasswordForConfiguringClient:(NSData *)sebData forEditing:(BOOL)forEditing sebFilePassword:(NSString **)sebFilePasswordPtr
{
    // Configure local client settings
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    // First try to decrypt with the current admin password
    // get admin password hash
    NSString *hashedAdminPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
    if (!hashedAdminPassword) hashedAdminPassword = @"";
    NSDictionary *sebPreferencesDict = nil;
    NSError *error = nil;
    NSData *decryptedSebData = [RNDecryptor decryptData:sebData withPassword:hashedAdminPassword error:&error];
    if (error || !decryptedSebData) {
        // If decryption with admin password didn't work, try it with an empty password
        error = nil;
        decryptedSebData = [RNDecryptor decryptData:sebData withPassword:@"" error:&error];
        if (!error) {
            //Decrypting with empty password worked
            // Ungzip the .seb (according to specification >= v14) decrypted serialized XML plist data
            decryptedSebData = [decryptedSebData gzipInflate];
            //Check if the openend reconfiguring seb file has the same admin password inside like the current one
            sebPreferencesDict = [self getPreferencesDictionaryFromConfigData:decryptedSebData error:&error];
            if (error) {
                [NSApp presentError:error];
                return nil; //we abort reading the new settings here
            }
            NSString *sebFileHashedAdminPassword = [sebPreferencesDict objectForKey:@"hashedAdminPassword"];
            // If there is an admin password saved in the settings
            if (hashedAdminPassword) {
                if ([hashedAdminPassword caseInsensitiveCompare:sebFileHashedAdminPassword] != NSOrderedSame) {
                    //No: The admin password inside the .seb file wasn't the same like the current one
                    //now we have to ask for the current admin password and
                    //allow reconfiguring only if the user enters the right one
                    // Allow up to 5 attempts for entering current admin password
                    int i = 5;
                    NSString *password = nil;
                    NSString *hashedPassword;
                    NSString *enterPasswordString = NSLocalizedString(@"You can only reconfigure SEB by entering the current SEB administrator password (because it was changed since installing SEB):",nil);
                    BOOL passwordsMatch;
                    do {
                        i--;
                        // Prompt for password. If cancel was pressed, abort
                        if ([self.sebController showEnterPasswordDialog:enterPasswordString modalForWindow:nil windowTitle:NSLocalizedString(@"Reconfiguring Local SEB Settings",nil)] == SEBEnterPasswordCancel) return NO;
                        password = [self.sebController.enterPassword stringValue];
                        hashedPassword = [keychainManager generateSHAHashString:password];
                        passwordsMatch = [hashedAdminPassword caseInsensitiveCompare:hashedPassword] == NSOrderedSame;
                        // in case we get an error we allow the user to try it again
                        enterPasswordString = NSLocalizedString(@"Wrong Password! Try again to enter the correct current SEB administrator password:",nil);
                    } while ((!password || !passwordsMatch) && i>0);
                    if (!passwordsMatch) {
                        //wrong password entered in 5th try: stop reading .seb file
                        NSRunAlertPanel(NSLocalizedString(@"Cannot Decrypt SEB Settings", nil),
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
            NSString *enterPasswordString = NSLocalizedString(@"Enter password used to encrypt .seb file:",nil);
            do {
                i--;
                // Prompt for password
                if ([self.sebController showEnterPasswordDialog:enterPasswordString modalForWindow:nil windowTitle:NSLocalizedString(@"Reconfiguring Local SEB Settings",nil)] == SEBEnterPasswordCancel) return NO;
                NSString *password = [self.sebController.enterPassword stringValue];
                if (!password) return NO;
                error = nil;
                decryptedSebData = [RNDecryptor decryptData:sebData withPassword:password error:&error];
                // in case we get an error we allow the user to try it again
                enterPasswordString = NSLocalizedString(@"Wrong Password! Try again to enter the correct password used to encrypt .seb file:",nil);
            } while (error && i>0);
            if (error || !decryptedSebData) {
                //wrong password entered in 5th try: stop reading .seb file
                NSRunAlertPanel(NSLocalizedString(@"Cannot Decrypt SEB Settings", nil),
                                NSLocalizedString(@"You either entered the wrong password or these settings were saved with an incompatible SEB version.", nil),
                                NSLocalizedString(@"OK", nil), nil, nil);
                return nil;
            }
        }
    }
    // Decryption worked
    if (!sebPreferencesDict) {
        // If we don't have the dictionary yet from above
        sebData = decryptedSebData;
        
        // Ungzip the .seb (according to specification >= v14) decrypted serialized XML plist data
        sebData = [sebData gzipInflate];
        
        // Get preferences dictionary from decrypted data
        error = nil;
        sebPreferencesDict = [self getPreferencesDictionaryFromConfigData:sebData error:&error];
        if (error) {
            [NSApp presentError:error];
            return nil; //we abort reading the new settings here
        }
    }
    
    /// In editing mode, if the current administrator password isn't the same as in the new settings,
    /// the user has to enter the right SEB administrator password before he can access the settings contents
    if (forEditing)
    {
        NSString *sebFileHashedAdminPassword = [sebPreferencesDict objectForKey:@"hashedAdminPassword"];
        // If there is an admin password saved in the settings
        if (sebFileHashedAdminPassword) {
            // Get the current admin password
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            NSString *hashedAdminPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
            if (!hashedAdminPassword) hashedAdminPassword = @"";
            // If the current hashed admin password is same like the hashed admin password from the settings file
            // then the user is allowed to access the settings
            if ([hashedAdminPassword caseInsensitiveCompare:sebFileHashedAdminPassword] != NSOrderedSame) {
                // otherwise we have to ask for the current SEB administrator password and
                // allow opening settings only if the user enters the right one
                // Allow up to 5 attempts for entering  admin password
                int i = 5;
                NSString *password = nil;
                NSString *hashedPassword;
                NSString *enterPasswordString = NSLocalizedString(@"Enter the SEB administrator password used in these settings:",nil);
                bool passwordsMatch;
                do
                {
                    i--;
                    // Prompt for password
                    if ([self.sebController showEnterPasswordDialog:enterPasswordString modalForWindow:nil windowTitle:NSLocalizedString(@"Loading settings",nil)] == SEBEnterPasswordCancel) return nil;
                    NSString *password = [self.sebController.enterPassword stringValue];
                    hashedPassword = [keychainManager generateSHAHashString:password];
                    if ([hashedPassword caseInsensitiveCompare:sebFileHashedAdminPassword] == NSOrderedSame)
                    {
                        passwordsMatch = true;
                    }
                    else
                    {
                        passwordsMatch = false;
                    }
                    // in case we get an error we allow the user to try it again
                    enterPasswordString = NSLocalizedString(@"Wrong password! Try again to enter the correct SEB administrator password from these settings:", nil);
                } while ((password == nil || !passwordsMatch) && i > 0);
                if (!passwordsMatch)
                {
                    //wrong password entered in 5th try: stop reading .seb file
                    NSRunAlertPanel(NSLocalizedString(@"Loading Settings", nil),
                                    NSLocalizedString(@"If you don't enter the right administrator password from these settings you cannot open them.", nil),
                                    NSLocalizedString(@"OK", nil), nil, nil);
                    return nil;
                }
            }
        }
    }
    
    // Check if a some value is from a wrong class (another than the value from default settings)
    // and quit reading .seb file if a wrong value was found
    if (![self checkClassOfSettings:sebPreferencesDict]) return nil;
    
    // We need to set the right value for the key sebConfigPurpose to know later where to store the new settings
    [sebPreferencesDict setValue:[NSNumber numberWithInt:sebConfigPurposeConfiguringClient] forKey:@"sebConfigPurpose"];
    
    return sebPreferencesDict;
}


// Check if a some value is from a wrong class (another than the value from default settings)
-(BOOL)checkClassOfSettings:(NSDictionary *)sebPreferencesDict
{
    // get default settings
    NSDictionary *defaultSettings = [[NSUserDefaults standardUserDefaults] sebDefaultSettings];
    
    // Check if a some value is from a wrong class other than the value from default settings)
    for (NSString *key in sebPreferencesDict) {
        NSString *keyWithPrefix = [self prefixKey:key];
        id value = [sebPreferencesDict objectForKey:key];
        id defaultValue = [defaultSettings objectForKey:keyWithPrefix];
        Class valueClass = [value superclass];
        Class defaultValueClass = [defaultValue superclass];
        if (valueClass && defaultValueClass && !([defaultValue isKindOfClass:valueClass] || [value isKindOfClass:defaultValueClass])) {
            //if (valueClass && defaultValueClass && valueClass != defaultValueClass) {
            //if (!(object_getClass([value class]) == object_getClass([defaultValue class]))) {
            //if (defaultValue && !([value class] == [defaultValue class])) {
            // Class of newly loaded value is different than the one from the default value
            // If yes, then cancel reading .seb file
            NSRunAlertPanel(NSLocalizedString(@"Loading new SEB settings failed!", nil),
                            NSLocalizedString(@"This settings file cannot be used. It may have been created by an older, incompatible version of SEB or it is corrupted.", nil),
                            NSLocalizedString(@"OK", nil), nil, nil);
            return NO; //we abort reading the new settings here
        }
    }
    return YES;
}


// Save imported settings into private user defaults (either in memory or local shared UserDefaults)
-(void) storeIntoUserDefaults:(NSDictionary *)sebPreferencesDict
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    // get default settings
    NSDictionary *defaultSettings = [preferences sebDefaultSettings];

    // Write SEB default values to the local preferences
    for (NSString *key in defaultSettings) {
        id value = [defaultSettings objectForKey:key];
        if (value) [preferences setSecureObject:value forKey:key];
    }
    
    // Write values from .seb config file to the local preferences
    for (NSString *key in sebPreferencesDict) {
        id value = [sebPreferencesDict objectForKey:key];
        if ([key isEqualToString:@"allowPreferencesWindow"]) {
            [preferences setSecureObject:
             [[sebPreferencesDict objectForKey:key] copy]
                                  forKey:@"org_safeexambrowser_enablePreferencesWindow"];
        }
        NSString *keyWithPrefix = [self prefixKey:key];
        
        // If imported settings are being saved into shared UserDefaults
        // Import embedded certificates (and identities) into the keychain
        // but don't save into local preferences
        if (!NSUserDefaults.userDefaultsPrivate && [key isEqualToString:@"embeddedCertificates"]) {
            SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
            for (NSDictionary *certificate in value) {
                int certificateType = [[certificate objectForKey:@"type"] integerValue];
                NSData *certificateData = [certificate objectForKey:@"certificateData"];
                switch (certificateType) {
                    case certificateTypeSSLClientCertificate:
                        if (certificateData) {
                            BOOL success = [keychainManager importCertificateFromData:certificateData];
#ifdef DEBUG
                            NSLog(@"Importing SSL certificate <%@> into Keychain %@", [certificate objectForKey:@"name"], success ? @"succedded" : @"failed");
#endif
                        }
                        break;
                        
                    case certificateTypeIdentity:
                        if (certificateData) {
                            BOOL success = [keychainManager importIdentityFromData:certificateData];
#ifdef DEBUG
                            NSLog(@"Importing identity <%@> into Keychain %@", [certificate objectForKey:@"name"], success ? @"succedded" : @"failed");
#endif
                        }
                        break;
                }
            }
            
        } else {
            // other values can be saved into local preferences
            [preferences setSecureObject:value forKey:keyWithPrefix];
        }
    }
}


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
    
    sebData = [keychainManager decryptData:sebData withPrivateKey:privateKeyRef];
    
    return sebData;
}


-(NSString *) getPrefixStringFromData:(NSData **)data
{
    NSData *prefixData = [self getPrefixDataFromData:data withLength:sebConfigFilePrefixLength];
    return [[NSString alloc] initWithData:prefixData encoding:NSUTF8StringEncoding];
}


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


// Get preferences dictionary from decrypted data
-(NSDictionary *) getPreferencesDictionaryFromConfigData:(NSData *)sebData error:(NSError **)error
{
    NSError *plistError = nil;
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


// Add the prefix required to identify SEB keys in UserDefaults to the key 
- (NSString *) prefixKey:(NSString *)key
{
    NSString *keyWithPrefix;
    if ([key isEqualToString:@"originatorVersion"] ||
        [key isEqualToString:@"copyBrowserExamKeyToClipboardWhenQuitting"]) {
        keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_%@", key];
    } else {
        keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_SEB_%@", key];
    }
    return keyWithPrefix;
}


#pragma mark Generate Encrypted .seb Settings Data

// Read SEB settings from UserDefaults and encrypt them using provided security credentials
- (NSData *) encryptSEBSettingsWithPassword:(NSString *)settingsPassword
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
        
    }
    
    NSMutableString *sebXML = [[NSMutableString alloc] initWithData:dataRep encoding:NSUTF8StringEncoding];
#ifdef DEBUG
    NSLog(@".seb XML plist: %@", sebXML);
#endif
    
    NSData *encryptedSebData = [sebXML dataUsingEncoding:NSUTF8StringEncoding];
    //NSData *encryptedSebData = [NSKeyedArchiver archivedDataWithRootObject:filteredPrefsDict];
    
    NSString *encryptingPassword = nil;
    
    // Check for special case: .seb configures client, empty password
    if (!settingsPassword && configPurpose == sebConfigPurposeConfiguringClient) {
        encryptingPassword = @"";
    } else {
        // in all other cases:
        // Check if no password entered and no identity selected
        if (!settingsPassword && !identityRef) {
            int answer = NSRunAlertPanel(NSLocalizedString(@"No encryption credentials chosen",nil), NSLocalizedString(@"You should either enter a password or choose a cryptographic identity to encrypt the SEB settings file.\n\nYou can save an unencrypted SEB file, but this is not recommended for use in exams.",nil),
                                         NSLocalizedString(@"OK",nil), NSLocalizedString(@"Save unencrypted",nil), nil);
            switch(answer)
            {
                case NSAlertDefaultReturn:
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
    if (settingsPassword) {
        encryptingPassword = settingsPassword;
    }
    // So if password is empty (special case) or provided
    if (encryptingPassword) {
        // encrypt with password
        encryptedSebData = [self encryptData:encryptedSebData usingPassword:encryptingPassword forPurpose:configPurpose];
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
- (NSData*) encryptData:(NSData*)data usingPassword:password forPurpose:(sebConfigPurposes)configPurpose {
    const char *utfString;
    // Check if .seb file should start exam or configure client
    if (configPurpose == sebConfigPurposeStartingExam) {
        // prefix string for starting exam: normal password will be prompted
        utfString = [@"pswd" UTF8String];
    } else {
        // prefix string for configuring client: configuring password will either be hashed admin pw on client
        // or if no admin pw on client set: empty pw //(((or prompt pw before configuring)))
        utfString = [@"pwcc" UTF8String];
        if (![password isEqualToString:@""]) {
            //empty password means no admin pw on clients and should not be hashed
            SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
            password = [keychainManager generateSHAHashString:password];
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
