//
//  NSUserDefaultsController+SEBEncryptedUserDefaultsController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30.08.12.
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


#import "NSUserDefaultsController+SEBEncryptedUserDefaultsController.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "SEBCryptor.h"

@implementation NSUserDefaultsController (SEBEncryptedUserDefaultsController)


- (id)secureValueForKeyPath:(NSString *)keyPath
{
    NSArray *pathElements = [keyPath componentsSeparatedByString:@"."];
    NSString *key = [pathElements objectAtIndex:[pathElements count]-1];
    if ([NSUserDefaults userDefaultsPrivate]) {
        id value = [[NSUserDefaults privateUserDefaults] valueForKey:key];
        //id value = [self.defaults secureObjectForKey:key];
        DDLogVerbose(@"keypath: %@ [[NSUserDefaults privateUserDefaults] valueForKey:%@]] = %@", keyPath, key, value);
        return value;
    } else {
        NSData *encrypted = [super valueForKeyPath:keyPath];
        
        if (encrypted == nil) {
            // Value = nil -> invalid
            return nil;
        }
        NSError *error;
        NSData *decrypted = [[SEBCryptor sharedSEBCryptor] decryptData:encrypted forKey: key error:&error];
        
        id value = [NSKeyedUnarchiver unarchiveObjectWithData:decrypted];
        DDLogVerbose(@"[super valueForKeyPath:%@] = %@ (decrypted)", keyPath, value);
        return value;
    }
}


- (void)setSecureValue:(id)value forKeyPath:(NSString *)keyPath
{
    NSArray *pathElements = [keyPath componentsSeparatedByString:@"."];
    NSString *key = [pathElements objectAtIndex:[pathElements count]-1];

    // Set value for key (without prefix) in cachedUserDefaults
    // as long as it is a key with an "org_safeexambrowser_SEB_" prefix
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([key hasPrefix:sebUserDefaultsPrefix]) {
        NSMutableDictionary *cachedUserDefaults = [preferences cachedUserDefaults];
        [cachedUserDefaults setValue:value forKey:[key substringFromIndex:SEBUserDefaultsPrefixLength]];
        // Update Exam Settings Key
        [[SEBCryptor sharedSEBCryptor] updateExamSettingsKey:cachedUserDefaults];
    }
    
    if ([NSUserDefaults userDefaultsPrivate]) {
        if (value == nil) value = [NSNull null];
        [[NSUserDefaults privateUserDefaults] setValue:value forKey:key];
        DDLogVerbose(@"keypath: %@ [[NSUserDefaults privateUserDefaults] setValue:%@ forKey:%@]", keyPath, value, key);
    } else {
        if (value == nil || keyPath == nil) {
            // Use non-secure method
            [super setValue:value forKeyPath:keyPath];
            
        } else {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
            NSError *error;
            NSData *encryptedData = [[SEBCryptor sharedSEBCryptor] encryptData:data forKey:key error:&error];
            
            DDLogVerbose(@"[super setValue:(encrypted %@) forKeyPath:%@]", value, keyPath);
            [super setValue:encryptedData forKeyPath:keyPath];
        }
    }
    if ([key isEqualToString:@"org_safeexambrowser_SEB_logLevel"]) {
        preferences.logLevel = value;
        [[MyGlobals sharedMyGlobals] setDDLogLevel:preferences.logLevel.intValue];
    }
    if ([key isEqualToString:@"org_safeexambrowser_SEB_enableLogging"]) {
        if ([value boolValue] == NO) {
            [[MyGlobals sharedMyGlobals] setDDLogLevel:DDLogLevelOff];
        } else {
            [[MyGlobals sharedMyGlobals] setDDLogLevel:preferences.logLevel.intValue];
        }
    }
}


@end
