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
#import "SEBKeychainManager.h"
#import "SEBCryptor.h"
#import "MyGlobals.h"
#import "Constants.h"

@implementation SEBConfigFileManager


-(id) init
{
    self = [super init];
    if (self) {
        self.sebController = [NSApp delegate];
    }
    return self;
}


-(BOOL) readSEBConfig:(NSData *)sebData
{
    // Getting 4-char prefix
    const char *utfString = [@"    " UTF8String];
    [sebData getBytes:(void *)utfString length:4];
    
    // Get data without the prefix
    NSRange range = {4, [sebData length]-4};
    sebData = [sebData subdataWithRange:range];
#ifdef DEBUG
    NSLog(@"Outer prefix of .seb settings file: %s",utfString);
    //NSLog(@"Prefix of .seb settings file: %@",[NSString stringWithUTF8String:utfString]);
#endif
    
    //
    // Decrypt with cryptographic identity/private key
    //
    if ([[NSString stringWithUTF8String:utfString] isEqualToString:@"pkhs"]) {
        // Get 20 bytes public key hash
        NSRange hashRange = {0, 20};
        NSData *publicKeyHash = [sebData subdataWithRange:hashRange];
        
        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
        SecKeyRef privateKeyRef = [keychainManager getPrivateKeyFromPublicKeyHash:publicKeyHash];
        if (!privateKeyRef) {
            NSRunAlertPanel(NSLocalizedString(@"Error Decrypting Settings", nil),
                            NSLocalizedString(@"The identity needed to decrypt settings has not been found in the keychain!", nil),
                            NSLocalizedString(@"OK", nil), nil, nil);
            return NO;
        }
#ifdef DEBUG
        NSLog(@"Private key retrieved with hash: %@", privateKeyRef);
#endif
        NSRange dataRange = {20, [sebData length]-20};
        sebData = [sebData subdataWithRange:dataRange];
        
        sebData = [keychainManager decryptData:sebData withPrivateKey:privateKeyRef];
        
        // Getting 4-char prefix again
        [sebData getBytes:(void *)utfString length:4];
#ifdef DEBUG
        NSLog(@"Inner prefix of .seb settings file: %s",utfString);
        //NSLog(@"Prefix of .seb settings file: %@",[NSString stringWithUTF8String:utfString]);
#endif
        // Get remaining data without prefix, which is either plain or still encoded with password
        NSRange range = {4, [sebData length]-4};
        sebData = [sebData subdataWithRange:range];
    }
    
    //
    // Decrypt with password
    //
    NSError *error;
    
    if ([[NSString stringWithUTF8String:utfString] isEqualToString:@"pswd"]) {
#ifdef DEBUG
        //NSLog(@"Dump of encypted .seb settings (without prefix): %@",encryptedSebData);
#endif
        NSData *sebDataDecrypted = nil;
        // Allow up to 5 attempts for entering decoding password
        int i = 5;
        do {
            i--;
            // Prompt for password
            if ([self.sebController showEnterPasswordDialog:NSLocalizedString(@"Enter Password:",nil) modalForWindow:nil windowTitle:NSLocalizedString(@"Loading New SEB Settings",nil)] == SEBEnterPasswordCancel) return NO;
            NSString *password = [self.sebController.enterPassword stringValue];
            if (!password) return NO;
            error = nil;
            sebDataDecrypted = [RNDecryptor decryptData:sebData withPassword:password error:&error];
            // in case we get an error we allow the user to try it again
        } while (error && i>0);
        if (error) {
            //wrong password entered in 5th try: stop reading .seb file
            return NO;
        }
        sebData = sebDataDecrypted;
    } else {
        
        //
        // Configure local client settings
        //
        if ([[NSString stringWithUTF8String:utfString] isEqualToString:@"pwcc"]) {
            //get admin password hash
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            NSString *hashedAdminPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
            //if (!hashedAdminPassword) {
            //   hashedAdminPassword = @"";
            //}
            NSDictionary *sebPreferencesDict = nil;
            error = nil;
            NSData *decryptedSebData = [RNDecryptor decryptData:sebData withPassword:hashedAdminPassword error:&error];
            if (error) {
                //if decryption with admin password didn't work, try it with an empty password
                error = nil;
                decryptedSebData = [RNDecryptor decryptData:sebData withPassword:@"" error:&error];
                if (!error) {
                    //Decrypting with empty password worked:
                    //Check if the openend reconfiguring seb file has the same admin password inside like the current one
                    sebPreferencesDict = [NSPropertyListSerialization propertyListWithData:decryptedSebData
                                                                                   options:0
                                                                                    format:NULL
                                                                                     error:&error];
                    if (error) {
                        NSRunAlertPanel(NSLocalizedString(@"Loading new SEB settings failed!", nil),
                                        NSLocalizedString(@"This settings file is corrupted and cannot be used.", nil),
                                        NSLocalizedString(@"OK", nil), nil, nil);
                        return NO; //we abort reading the new settings here
                    }
                    NSString *sebFileHashedAdminPassword = [sebPreferencesDict objectForKey:@"hashedAdminPassword"];
                    if (![hashedAdminPassword isEqualToString:sebFileHashedAdminPassword]) {
                        //No: The admin password inside the .seb file wasn't the same like the current one
                        //now we have to ask for the current admin password and
                        //allow reconfiguring only if the user enters the right one
                        // Allow up to 5 attempts for entering current admin password
                        int i = 5;
                        NSString *password = nil;
                        NSString *hashedPassword;
                        BOOL passwordsMatch;
                        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
                        do {
                            i--;
                            // Prompt for password
                            if ([self.sebController showEnterPasswordDialog:NSLocalizedString(@"You can only reconfigure SEB by entering the current SEB administrator password (because it was changed since installing SEB):",nil) modalForWindow:nil windowTitle:NSLocalizedString(@"Reconfiguring Local SEB Settings",nil)] == SEBEnterPasswordCancel) return NO;
                            password = [self.sebController.enterPassword stringValue];
                            hashedPassword = [keychainManager generateSHAHashString:password];
                            passwordsMatch = [hashedAdminPassword isEqualToString:hashedPassword];
                            // in case we get an error we allow the user to try it again
                        } while ((!password || !passwordsMatch) && i>0);
                        if (!passwordsMatch) {
                            //wrong password entered in 5th try: stop reading .seb file
                            return NO;
                        }
                    }
                    
                } else {
                    //if decryption with admin password didn't work, ask for the password the .seb file was encrypted with
                    //empty password means no admin pw on clients and should not be hashed
                    //NSData *sebDataDecrypted = nil;
                    // Allow up to 3 attempts for entering decoding password
                    int i = 3;
                    do {
                        i--;
                        // Prompt for password
                        if ([self.sebController showEnterPasswordDialog:NSLocalizedString(@"Enter password used to encrypt .seb file:",nil) modalForWindow:nil windowTitle:NSLocalizedString(@"Reconfiguring Local SEB Settings",nil)] == SEBEnterPasswordCancel) return NO;
                        NSString *password = [self.sebController.enterPassword stringValue];
                        if (!password) return NO;
                        error = nil;
                        decryptedSebData = [RNDecryptor decryptData:sebData withPassword:password error:&error];
                        // in case we get an error we allow the user to try it again
                    } while (error && i>0);
                    if (error) {
                        //wrong password entered in 5th try: stop reading .seb file
                        return NO;
                    }
                }
            }
            
            sebData = decryptedSebData;
            if (!error) {
                //
                // Decryption worked
                //
                // Get preferences dictionary from decrypted data
                NSError *error;
                // If we don't have the dictionary yet from above
                if (!sebPreferencesDict) sebPreferencesDict = [NSPropertyListSerialization propertyListWithData:sebData
                                                                                                        options:0
                                                                                                         format:NULL
                                                                                                          error:&error];
                if (error) {
                    NSRunAlertPanel(NSLocalizedString(@"Loading new SEB settings failed!", nil),
                                    NSLocalizedString(@"This settings file is corrupted and cannot be used.", nil),
                                    NSLocalizedString(@"OK", nil), nil, nil);
                    return NO; //we abort reading the new settings here
                }
                // get default settings
                NSDictionary *defaultSettings = [preferences sebDefaultSettings];
                
                // Check if a some value is from a wrong class (another than the value from default settings)
                for (NSString *key in sebPreferencesDict) {
                    NSString *keyWithPrefix;
                    if ([key isEqualToString:@"originatorVersion"] ||
                        [key isEqualToString:@"copyBrowserExamKeyToClipboardWhenQuitting"]) {
                        keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_%@", key];
                    } else {
                        keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_SEB_%@", key];
                    }
                    id value = [sebPreferencesDict objectForKey:key];
                    id defaultValue = [defaultSettings objectForKey:keyWithPrefix];
                    Class valueClass = [value superclass];
                    Class defaultValueClass = [defaultValue superclass];
                    if (valueClass && defaultValueClass && !([defaultValue isKindOfClass:valueClass] || [value isKindOfClass:defaultValueClass])) {
                        // Class of newly loaded value is different than the one from the default value
                        // If yes, then cancel reading .seb file
                        NSRunAlertPanel(NSLocalizedString(@"Loading new SEB settings failed!", nil),
                                        NSLocalizedString(@"This settings file cannot be used. It may have been created by an older, incompatible version of SEB or it is corrupted.", nil),
                                        NSLocalizedString(@"OK", nil), nil, nil);
                        return NO; //we abort reading the new settings here
                    }
                }
                
                //switch to system's UserDefaults
                [NSUserDefaults setUserDefaultsPrivate:NO];
                
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
                    NSString *keyWithPrefix;
                    if ([key isEqualToString:@"originatorVersion"] ||
                        [key isEqualToString:@"copyBrowserExamKeyToClipboardWhenQuitting"]) {
                        keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_%@", key];
                    } else {
                        keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_SEB_%@", key];
                    }
                    if ([key isEqualToString:@"embeddedCertificates"]) {
                        // Embedded certificates (and identities) we import to the keychain
                        // but don't save into local preferences
                        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
                        //NSArray *embeddedCertificates = value;
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
                        [preferences setSecureObject:value forKey:keyWithPrefix];
                    }
                }
                int answer = NSRunAlertPanel(NSLocalizedString(@"SEB Re-Configured",nil), NSLocalizedString(@"The local settings of SEB have been reconfigured. Do you want to start working with SEB now or quit?",nil),
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
            }
            return YES; //reading preferences was successful
            
        } else {
            //
            // No valid 4-char prefix was found in the .seb file
            //
            if (![[NSString stringWithUTF8String:utfString] isEqualToString:@"plnd"]) {
                // prefix is not the one for plain data: cancel reading .seb file
                NSRunAlertPanel(NSLocalizedString(@"Loading new SEB settings failed!", nil),
                                NSLocalizedString(@"This settings file cannot be used. It may have been created by an newer, incompatible version of SEB or it is corrupted.", nil),
                                NSLocalizedString(@"OK", nil), nil, nil);
                return NO;
            }
        }
    }
    
    //if decrypting wasn't successfull then stop here
    if (!sebData) return NO;
    
    // Get preferences dictionary from decrypted data
    //NSDictionary *sebPreferencesDict = [NSKeyedUnarchiver unarchiveObjectWithData:sebData];
    NSDictionary *sebPreferencesDict = [NSPropertyListSerialization propertyListWithData:sebData
                                                                                 options:0
                                                                                  format:NULL
                                                                                   error:&error];
    if (error) {
        NSRunAlertPanel(NSLocalizedString(@"Loading new SEB settings failed!", nil),
                        NSLocalizedString(@"This settings file is corrupted and cannot be used.", nil),
                        NSLocalizedString(@"OK", nil), nil, nil);
        return NO; //we abort reading the new settings here
    }
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // get default settings
    NSDictionary *defaultSettings = [preferences sebDefaultSettings];
    
    // Check if a some value is from a wrong class (another than the value from default settings)
    for (NSString *key in sebPreferencesDict) {
        NSString *keyWithPrefix;
        if ([key isEqualToString:@"originatorVersion"] ||
            [key isEqualToString:@"copyBrowserExamKeyToClipboardWhenQuitting"]) {
            keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_%@", key];
        } else {
            keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_SEB_%@", key];
        }
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
    
    // Release preferences window so bindings get synchronized properly with the new loaded values
    [self.sebController.preferencesController releasePreferencesWindow];
    
    // Switch to private UserDefaults (saved non-persistantly in memory instead in ~/Library/Preferences)
    NSMutableDictionary *privatePreferences = [NSUserDefaults privateUserDefaults];
    [NSUserDefaults setUserDefaultsPrivate:YES];
    
    // Write SEB default values to the private preferences
    for (NSString *key in defaultSettings) {
        id value = [defaultSettings objectForKey:key];
        if (value) [preferences setSecureObject:value forKey:key];
    }
    // Write values from .seb config file to the private preferences
    for (NSString *key in sebPreferencesDict) {
        NSString *keyWithPrefix;
        if ([key isEqualToString:@"originatorVersion"] ||
            [key isEqualToString:@"copyBrowserExamKeyToClipboardWhenQuitting"]) {
            keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_%@", key];
        } else {
            keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_SEB_%@", key];
        }
        id value = [sebPreferencesDict objectForKey:key];
        if ([key isEqualToString:@"allowPreferencesWindow"]) {
            [preferences setSecureObject:
             [[sebPreferencesDict objectForKey:key] copy]
                                  forKey:@"org_safeexambrowser_enablePreferencesWindow"];
        }
        if (value) [preferences setSecureObject:value forKey:keyWithPrefix];
        //NSString *keypath = [NSString stringWithFormat:@"values.%@", keyWithPrefix];
        //if (value) [[[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController] values] setValue:value forKeyPath:keyWithPrefix];
        //if (value) [[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController] setValue:value forKeyPath:keypath];
    }
#ifdef DEBUG
    NSLog(@"Private preferences set: %@", privatePreferences);
#endif
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults];
    [self.sebController.preferencesController initPreferencesWindow];
    
    return YES; //reading preferences was successful
}

@end
