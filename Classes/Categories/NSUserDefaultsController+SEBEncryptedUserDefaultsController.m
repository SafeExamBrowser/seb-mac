//
//  NSUserDefaultsController+SEBEncryptedUserDefaultsController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30.08.12.
//  Copyright (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 2.0 (the "License"); you may not use this file except in
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
//  (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
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
        if (error || decrypted == nil) {
            DDLogError(@"%s: Could not decrypt value for keypath %@, error: %@", __FUNCTION__, keyPath, error);
            return nil;
        }
        // Use a keyed unarchiver configured to return an error instead of raising an
        // NSException (as the deprecated +unarchiveObjectWithData: did) so corrupted
        // stored user data is treated as an invalid value instead of aborting the app.
        // Secure coding is disabled to stay compatible with existing archives and the
        // arbitrary value types stored in the (encrypted) user defaults. The @try/@catch
        // is a final safety net: the failure policy handles all decode failures, but a
        // decoded object's own initWithCoder: could still raise.
        id value = nil;
        @try {
            NSError *unarchiveError = nil;
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:decrypted error:&unarchiveError];
            if (unarchiver == nil) {
                DDLogError(@"%s: Could not create unarchiver for keypath %@, error: %@", __FUNCTION__, keyPath, unarchiveError);
                return nil;
            }
            unarchiver.requiresSecureCoding = NO;
            unarchiver.decodingFailurePolicy = NSDecodingFailurePolicySetErrorAndReturn;
            value = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
            [unarchiver finishDecoding];
        }
        @catch (NSException *exception) {
            DDLogError(@"%s: Unarchiving decrypted value for keypath %@ raised an exception: %@", __FUNCTION__, keyPath, exception);
            return nil;
        }
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
            // Unlike setSecureObject:forKey:, this path doesn't pre-validate that value
            // is a property-list type, so archiving an object that doesn't conform to
            // NSCoding could raise an NSException (not reliably reported via error:).
            // Catch it so an unexpected value type can't abort the app.
            NSError *error = nil;
            NSData *data = nil;
            @try {
                data = [NSKeyedArchiver archivedDataWithRootObject:value requiringSecureCoding:NO error:&error];
            }
            @catch (NSException *exception) {
                DDLogError(@"%s: Archiving value for keypath %@ raised an exception: %@", __FUNCTION__, keyPath, exception);
                return;
            }
            if (error || data == nil) {
                DDLogError(@"%s: Could not archive value for keypath %@, error: %@", __FUNCTION__, keyPath, error);
                return;
            }
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
