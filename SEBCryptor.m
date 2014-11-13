//
//  SEBCryptor.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24.01.13.
//  Copyright (c) 2010-2014 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider,
//  Dirk Bauer, Karsten Burger, Marco Lehre,
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


#import "SEBCryptor.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "SEBEncryptedUserDefaultsController.h"
#import "RNCryptor.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "SEBKeychainManager.h"

@implementation SEBCryptor

//@synthesize HMACKey = _HMACKey;

static SEBCryptor *sharedSEBCryptor = nil;

static const RNCryptorSettings kSEBCryptorAES256Settings = {
    .algorithm = kCCAlgorithmAES128,
    .blockSize = kCCBlockSizeAES128,
    .IVSize = kCCBlockSizeAES128,
    .options = kCCOptionPKCS7Padding,
    .HMACAlgorithm = kCCHmacAlgSHA256,
    .HMACLength = CC_SHA256_DIGEST_LENGTH,
    
    .keySettings = {
        .keySize = kCCKeySizeAES256,
        .saltSize = 8,
        .PBKDFAlgorithm = kCCPBKDF2,
        .PRF = kCCPRFHmacAlgSHA1,
        .rounds = 117
    },
    
    .HMACKeySettings = {
        .keySize = kCCKeySizeAES256,
        .saltSize = 8,
        .PBKDFAlgorithm = kCCPBKDF2,
        .PRF = kCCPRFHmacAlgSHA1,
        .rounds = 113
    }
};


+ (SEBCryptor *)sharedSEBCryptor
{
	@synchronized(self)
	{
		if (sharedSEBCryptor == nil)
		{
			sharedSEBCryptor = [[self alloc] init];
		}
	}
    
	return sharedSEBCryptor;
}


// Returns NO if there were no valid UserDefaults set yet on this system
- (BOOL) hasDefaultsKey
{
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSData *defaultsKey = [keychainManager retrieveKey];
    if (defaultsKey) {
        _currentKey = defaultsKey;
//#ifdef DEBUG
//        NSLog(@"UserDefaults key %@ retrieved.", _currentKey);
//#endif
    } else {
        _currentKey = [RNCryptor randomDataOfLength:kCCKeySizeAES256];
        [keychainManager storeKey:_currentKey];
//#ifdef DEBUG
//        NSLog(@"Generated UserDefaults key %@ as there was none defined yet.", _currentKey);
//#endif
    }
    return (defaultsKey != nil);
}


- (BOOL) updateUDKey
{
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    _currentKey = [RNCryptor randomDataOfLength:kCCKeySizeAES256];
//#ifdef DEBUG
//    NSLog(@"Updated UserDefaults key to %@", _currentKey);
//#endif
    return [keychainManager updateKey:_currentKey];
}


- (NSData *) encryptData:(NSData *)data forKey:(NSString *)key error:(NSError **)error
{
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *HMACData = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, keyData.bytes, keyData.length, _currentKey.bytes, _currentKey.length, HMACData.mutableBytes);

    NSString *password = [HMACData base64Encoding];
//#ifdef DEBUG
//    NSLog(@"Encrypt UD password: %@, error: %@", password, *error);
//#endif
    
    NSData *encryptedData = [RNEncryptor encryptData:data
                                        withSettings:kSEBCryptorAES256Settings
                                            password:password
                                               error:error];
//#ifdef DEBUG
//    NSLog(@"Encrypted UD, error: %@", *error);
//#endif
    return encryptedData;
}


- (NSData *) decryptData:(NSData *)encryptedData forKey:(NSString *)key error:(NSError **)error
{
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *HMACData = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, keyData.bytes, keyData.length, _currentKey.bytes, _currentKey.length, HMACData.mutableBytes);
    
    NSString *password = [HMACData base64Encoding];
//#ifdef DEBUG
//    NSLog(@"Decrypt UD password: %@, error: %@", password, *error);
//#endif
    NSData *decryptedData = [RNDecryptor decryptData:encryptedData withSettings:kSEBCryptorAES256Settings
                                            password:password
                                               error:error];
//#ifdef DEBUG
//    NSLog(@"Decrypted UD, error: %@", *error);
//#endif
    return decryptedData;
}


- (BOOL) checkExamSettings:(NSData *)examSettingsKey
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *currentExamSettingsKey = [preferences secureDataForKey:@"org_safeexambrowser_currentData1"];
    return [examSettingsKey isEqualToData:currentExamSettingsKey];
}


- (void) updateExamSettingsKey:(NSDictionary *)settings
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureObject:[self checksumForLocalPrefDictionary:settings]
                   forKey:@"org_safeexambrowser_currentData1"];
}


// Method called when the endcrypted UserDefaults possibly changed
// Re-Calculates a checksum hash which is used as Browser Exam Key
// If the passed parameter generateNewSalt is YES,
// and the checksum changed (means some setting changed), then
// the exam key salt random value is re-generated
// Returns true if the checksum actually changed
- (BOOL)updateEncryptedUserDefaults:(BOOL)updateUserDefaults updateSalt:(BOOL)generateNewSalt
{
    NSData *newChecksum;
    return [self updateEncryptedUserDefaults:updateUserDefaults updateSalt:generateNewSalt newChecksum:&newChecksum];
}

- (BOOL)updateEncryptedUserDefaults:(BOOL)updateUserDefaults updateSalt:(BOOL)generateNewSalt newChecksum:(NSData **)newChecksumPtr
{
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // Get current salt for exam key
    NSData *HMACKey = [preferences secureDataForKey:@"org_safeexambrowser_SEB_examKeySalt"];
    // If there was no salt yet, then we generate it in any case
    if ([HMACKey isEqualToData:[NSData data]]) {
        [self generateExamKeySalt];

        DDLogInfo(@"Generated Browser Exam Key salt as there was none defined yet.");
    }
        
    // Filter dictionary so only org_safeexambrowser_SEB_ keys are included
    NSSet *filteredPrefsSet = [preferences sebKeysSet];
    NSMutableDictionary *filteredPrefsDict = [NSMutableDictionary dictionaryWithCapacity:[filteredPrefsSet count]];

    // get default settings
    NSDictionary *defaultSettings = [preferences sebDefaultSettings];
    
    // iterate keys and read all values
    for (NSString *key in filteredPrefsSet) {
        id value = [preferences secureObjectForKey:key];
        id defaultValue = [defaultSettings objectForKey:key];
        Class valueClass = [value superclass];
        Class defaultValueClass = [defaultValue superclass];
        if (valueClass && defaultValueClass && !([defaultValue isKindOfClass:valueClass] || [value isKindOfClass:defaultValueClass])) {
            // Class of local preferences value is different than the one from the default value
            // If yes, then cancel reading .seb file and create error object
            [self presentPreferencesCorruptedError];
            // Return value: Checksum changed
            return YES;
        }
        if (value) {
            [filteredPrefsDict setObject:value forKey:key];
        }
//        // If the value is a int wrapped into a NSNumber, then we need to convert that into a long
//        // because UI bindings to selected index (checkbox, popup menu) produce long values
//        if (valueClass == [NSNumber class] && (strcmp ([value objCType], @encode(int)) == 0)) {
//            [filteredPrefsDict setObject:[NSNumber numberWithLong:[value longValue]] forKey:key];
//        } else {
//            if (value) [filteredPrefsDict setObject:value forKey:key];
//        }
    }

    // Convert preferences dictionary to XML property list
    NSData *HMACData = [self checksumForPrefDictionary:filteredPrefsDict];
    *newChecksumPtr = HMACData;
    
    // Get current Browser Exam Key
    NSData *currentBrowserExamKey = [preferences secureDataForKey:@"org_safeexambrowser_currentData"];

    // If both Keys are not the same, then settings changed
    if (![currentBrowserExamKey isEqualToData:HMACData]) {
        // If we're supposed to, generate a new exam key salt
        if (generateNewSalt) {
            HMACKey = [self generateExamKeySalt];
            // Update salt in the filtered prefs directory
            [filteredPrefsDict setObject:HMACKey forKey:@"org_safeexambrowser_SEB_examKeySalt"];
            // Generate new Browser Exam Key using new salt
            HMACData = [self checksumForPrefDictionary:filteredPrefsDict];
        }
        // If we're supposed to, generate new Browser Exam Key and store it in settings
        if (updateUserDefaults) {
            // Store new exam key in UserDefaults
            [preferences setSecureObject:HMACData forKey:@"org_safeexambrowser_currentData"];
        }
        // Return value: Checksum changed
        return YES;
    }
    
    // Return value: Checksum not changed
    return NO;
}


- (NSData *)checksumForPrefDictionary:(NSDictionary *)prefsDict
{
    NSError *error = nil;
    
    NSData *archivedPrefs = [NSPropertyListSerialization dataWithPropertyList:prefsDict
                                                                       format:NSPropertyListXMLFormat_v1_0
                                                                      options:0
                                                                        error:&error];
    NSData *HMACData;
    if (error || !archivedPrefs) {
        // Serialization of the XML plist went wrong
        // Pref key is empty
        HMACData = [NSData data];
    } else {
        // Generate new pref key
        HMACData = [self generateChecksumForCurrentData:archivedPrefs];
    }
    return HMACData;
}


- (NSData *)checksumForLocalPrefDictionary:(NSDictionary *)prefsDict
{
    NSMutableDictionary *cleanedPrefs = [NSMutableDictionary dictionaryWithDictionary:prefsDict];
    [cleanedPrefs removeObjectForKey:@"examKeySalt"];
    [cleanedPrefs removeObjectForKey:@"logDirectoryOSX"];
    
    NSError *error = nil;
    NSData *archivedPrefs = [NSPropertyListSerialization dataWithPropertyList:prefsDict
                                                                       format:NSPropertyListXMLFormat_v1_0
                                                                      options:0
                                                                        error:&error];
//    NSData *archivedPrefs = [NSJSONSerialization dataWithJSONObject:prefsDict options:0 error:&error];
#ifdef DEBUG
//    NSLog(@"LocalPrefDictionary: %@", [[NSString alloc] initWithData:archivedPrefs encoding:NSUTF8StringEncoding]);
#endif
    
    NSData *HMACData;
    if (error || !archivedPrefs) {
        // Serialization of the XML plist went wrong
        // Pref key is empty
        HMACData = [NSData data];
    } else {
        // Generate new pref key
        HMACData = [self generateSHAHashForData:archivedPrefs];
    }
    return HMACData;
}


- (NSData *)generateChecksumForCurrentData:(NSData *)currentData
{
    // Get current salt for exam key
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *HMACKey = [preferences secureDataForKey:@"org_safeexambrowser_SEB_examKeySalt"];

    NSMutableData *HMACData = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, HMACKey.bytes, HMACKey.length, currentData.bytes, currentData.length, HMACData.mutableBytes);
    return HMACData;
}


// Calculate a random salt value for the Browser Exam Key and save it to UserDefaults
- (NSData *)generateExamKeySalt
{
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *HMACKey = [RNCryptor randomDataOfLength:kCCKeySizeAES256];
    [preferences setSecureObject:HMACKey forKey:@"org_safeexambrowser_SEB_examKeySalt"];
    return HMACKey;
}


- (NSData*) generateSHAHash:(NSString*)inputString {
    unsigned char hashedChars[32];
    CC_SHA256([inputString UTF8String],
              [inputString lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
              hashedChars);
    NSData *hashedData = [NSData dataWithBytes:hashedChars length:32];
    return hashedData;
}


- (NSData*) generateSHAHashForData:(NSData *)inputData {
    unsigned char hashedChars[32];
    CC_SHA256(inputData.bytes,
              inputData.length,
              hashedChars);
    NSData *hashedData = [NSData dataWithBytes:hashedChars length:32];
    return hashedData;
}


- (void)presentPreferencesCorruptedError
{
//    NSDictionary *newDict = @{ NSLocalizedDescriptionKey :
//                                   NSLocalizedString(@"Local SEB settings are corrupted!", nil),
//                               /*NSLocalizedFailureReasonErrorKey :
//                                NSLocalizedString(@"Either an incompatible version of SEB has been used on this computer or the preferences file has been manipulated. In the first case you can quit SEB now and use the previous version to export settings as a .seb config file for reconfiguring the new version. Otherwise local settings need to be reset to the default values in order for SEB to continue running.", nil),*/
//                               //NSURLErrorKey : furl,
//                               NSRecoveryAttempterErrorKey : self,
//                               NSLocalizedRecoverySuggestionErrorKey :
//                                   NSLocalizedString(@"Local preferences have either been manipulated or created by an incompatible SEB version. You can reset settings now or quit and try to use your previous SEB version to review or export settings as a .seb file for configuring the new version.\n\nReset local settings and continue?", @""),
//                               NSLocalizedRecoveryOptionsErrorKey :
//                                   @[NSLocalizedString(@"Continue", @""), NSLocalizedString(@"Quit", @"")] };
//    
//    NSError *newError = [[NSError alloc] initWithDomain:sebErrorDomain
//                                                   code:1 userInfo:newDict];


    // Set the flag to indicate to user later that settings have been reset
    [[MyGlobals sharedMyGlobals] setPreferencesReset:YES];
    // Reset settings to the default values
//	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    [preferences resetSEBUserDefaults];
//    [preferences storeSEBDefaultSettings];
//    // Update Exam Browser Key
//    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
//#ifdef DEBUG
//    NSLog(@"Local preferences have been reset!");
//#endif
    return;
}


// Error recovery attempter when local preferences need to be reset
- (BOOL)attemptRecoveryFromError:(NSError *)error
                     optionIndex:(NSUInteger)recoveryOptionIndex
{
    BOOL success = NO;
    
    if (recoveryOptionIndex == 0) { // Recovery requested.
        [[NSUserDefaults standardUserDefaults] resetSEBUserDefaults];
        [self updateEncryptedUserDefaults:YES updateSalt:YES];
        success = YES;
    }
    if (recoveryOptionIndex == 1) { // Quit requested.
        // Terminate SEB without any further user confirmation required
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestQuitNotification" object:self];
        success = NO;
    }
    return success;
}


@end
