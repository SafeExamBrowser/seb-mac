//
//  SEBCryptor.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24.01.13.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "SEBCryptor.h"
#import "RNCryptor.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "SEBKeychainManager.h"
#import "SEBSettings.h"


@implementation NSString (SEBCryptor)

- (NSComparisonResult)caseInsensitiveOrdinalCompare:(NSString *)string {
    return [self compare:string options:NSCaseInsensitiveSearch | NSForcedOrderingSearch];
}

@end


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
#ifdef DEBUG
        DDLogDebug(@"UserDefaults key %@ retrieved.", _currentKey);
#else
        DDLogDebug(@"UserDefaults key retrieved.");
#endif
    } else {
        DDLogDebug(@"UserDefaults key not found, probably it wasn't yet existing, creating a new one.");
        _currentKey = [RNCryptor randomDataOfLength:kCCKeySizeAES256];
        if ([keychainManager storeKey:_currentKey]) {
#ifdef DEBUG
            DDLogDebug(@"Generated UserDefaults key %@ as there was none defined yet.", _currentKey);
#else
            DDLogDebug(@"Generated UserDefaults key as there was none defined yet.");
#endif
        } else {
            DDLogError(@"Could not save new UserDefaults key to keychain. Local settings will be reset to default values when starting SEB next time.");
        }
    }
    return (defaultsKey != nil);
}


- (BOOL) updateUDKey
{
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    _currentKey = [RNCryptor randomDataOfLength:kCCKeySizeAES256];
#ifdef DEBUG
    DDLogVerbose(@"Updating UserDefaults key to %@", _currentKey);
#else
    DDLogDebug(@"Updating UserDefaults key");
#endif
    return [keychainManager updateKey:_currentKey];
}


- (NSData *) encryptData:(NSData *)data forKey:(NSString *)key error:(NSError **)error
{
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *HMACData = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, keyData.bytes, keyData.length, _currentKey.bytes, _currentKey.length, HMACData.mutableBytes);

    NSString *password = [HMACData base64EncodedStringWithOptions:0];
    
    NSData *encryptedData = [RNEncryptor encryptData:data
                                        withSettings:kSEBCryptorAES256Settings
                                            password:password
                                               error:error];
    if (*error) {
#ifdef DEBUG
        DDLogVerbose(@"Encrypt UserDefaults with key %@, error: %@", password, [*error description]);
#else
        DDLogError(@"Encrypt UserDefaults with key, error: %@", [*error description]);
#endif
    }
    return encryptedData;
}


- (NSData *) decryptData:(NSData *)encryptedData forKey:(NSString *)key error:(NSError **)error
{
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *HMACData = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, keyData.bytes, keyData.length, _currentKey.bytes, _currentKey.length, HMACData.mutableBytes);
    
    NSString *password = [HMACData base64EncodedStringWithOptions:0];
    NSData *decryptedData = [RNDecryptor decryptData:encryptedData withSettings:kSEBCryptorAES256Settings
                                            password:password
                                               error:error];
    if (*error) {
#ifdef DEBUG
        DDLogVerbose(@"Decrypt UserDefaults with key %@, error: %@", password, [*error description]);
#else
        DDLogError(@"Encrypt UserDefaults with key, error: %@", [*error description]);
#endif
    }
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
- (BOOL)updateEncryptedUserDefaults:(BOOL)updateUserDefaults
                         updateSalt:(BOOL)generateNewSalt
{
    if (!lockQueue) {
        lockQueue = dispatch_queue_create("org.safeexambrowser.cryptorqueue", NULL);
    }
    __block BOOL encryptedUserDefaultsChanged;
    
    dispatch_sync(lockQueue, ^{
        NSData *newChecksum;
        encryptedUserDefaultsChanged = [self updateEncryptedUserDefaults:updateUserDefaults
                                                              updateSalt:generateNewSalt
                                                             newChecksum:&newChecksum];
    });
    
    return encryptedUserDefaultsChanged;
}


- (BOOL)updateEncryptedUserDefaults:(BOOL)updateUserDefaults
                         updateSalt:(BOOL)generateNewSalt
                        newChecksum:(NSData **)newChecksumPtr
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Only calculate Config Key when UserDefaults should actually be updated
    // Otherwise this method is only used to check if settings changed,
    // then we can save time as the Config Key isn't relevant in this case
    if (updateUserDefaults) {
        if (generateNewSalt) {
            // Force generating a new Config Key Salt
            [preferences setSecureObject:[NSData data] forKey:@"org_safeexambrowser_SEB_configKeySalt"];
        }
        [self updateConfigKey];
    }
    
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

    // Get default settings
    NSDictionary *defaultSettings = [preferences sebDefaultSettings];
    
    // Iterate keys and read all values
    for (NSString *key in filteredPrefsSet) {
        id value = [preferences secureObjectForKey:key];
        id defaultValue = [defaultSettings objectForKey:key];
        Class valueClass = [value superclass];
        Class defaultValueClass = [defaultValue superclass];
        if (!value || (valueClass && defaultValueClass &&
                       !([defaultValue isKindOfClass:valueClass] ||
                         [value isKindOfClass:defaultValueClass]))) {
            // Class of local preferences value is different than the one from the default value
            // If yes, then cancel reading .seb file and create error object
            DDLogError(@"%s Value for key %@ is not having the correct class!", __FUNCTION__, key);
            DDLogError(@"Triggering present alert for 'Local SEB settings have been reset'");
            [self presentPreferencesCorruptedError];
            [self resetSEBUserDefaults];
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
        DDLogError(@"%s: Serialization of the XML plist went wrong! Error: %@", __FUNCTION__, error.description);
        // Pref key is empty
        HMACData = [NSData data];
    } else {
        // Generate new pref key
        HMACData = [self generateChecksumForBEK:archivedPrefs];
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
    NSData *HMACData;
    if (error || !archivedPrefs) {
        // Serialization of the XML plist went wrong
        DDLogError(@"%s: Serialization of the XML plist went wrong! Error: %@", __FUNCTION__, error.description);
#ifdef DEBUG
        DDLogVerbose(@"LocalPrefDictionary XML plist: %@", [[NSString alloc] initWithData:archivedPrefs encoding:NSUTF8StringEncoding]);
#endif
        
        // Pref key is empty
        HMACData = [NSData data];
    } else {
        // Generate new pref key
        HMACData = [self generateSHAHashForData:archivedPrefs];
    }
    return HMACData;
}


- (NSData *)checksumForJSONString:(NSString *)jsonString
{
    DDLogVerbose(@"JSON for Config Key: %@", jsonString);
    
    unsigned char hashedChars[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256([jsonString UTF8String],
              (uint)[jsonString lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
              hashedChars);
    NSData *hashData = [NSData dataWithBytes:(const void *)hashedChars length:CC_SHA256_DIGEST_LENGTH];
    DDLogVerbose(@"Config Key: %@", hashData);

    return hashData;
}


- (NSString *)jsonStringForObject:(id)object
{
    Class objectClass = [object superclass];
    NSString *jsonString;

    if (objectClass == [NSData class] || objectClass == [NSMutableData class]) {
        if ([object isEqualToData:[NSData data]]) {
            jsonString = @"\"\"";
        } else {
            jsonString = [NSString stringWithFormat:@"\"%@\"", [object base64EncodedStringWithOptions:0]];
        }
    } else if (objectClass == [NSString class] || [objectClass isSubclassOfClass:[NSString class]]) {
        jsonString = [NSString stringWithFormat:@"\"%@\"", object];
    } else if ((strcmp([object objCType], "c") == 0)) {
        jsonString = [NSString stringWithFormat:@"%@", ([object boolValue] == 0 ? @"false" : @"true")];
    } else {
        jsonString = [NSString stringWithFormat:@"%@", object];
    }
    
    return jsonString;
}


- (NSData *)generateChecksumForBEK:(NSData *)currentData
{
    // Get current salt for exam key
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *HMACKey = [preferences secureDataForKey:@"org_safeexambrowser_SEB_examKeySalt"];

    return [self generateChecksumForData:currentData withSalt:HMACKey];
}

- (NSData *)generateChecksumForData:(NSData *)currentData withSalt:(NSData *)HMACKey {
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


// Calculate a random salt value for the Browser Exam Key and save it to UserDefaults
- (NSData *)generateConfigKeySalt
{
    NSData *HMACKey = [RNCryptor randomDataOfLength:kCCKeySizeAES256];
    return HMACKey;
}


/// Config Key

// Update Config Key, which is a hash over all config keys
// in a JSON object. As this key needs to be platform independent,
// following rules must be followed strictly when creating the key:
// - Convert binary data to base64 strings
// - Exception: additionalResources
// - Sort keys alphabetically, also in sub-dictionaries
// - UTF-8 character encoding
// - Strip all whitespace from the beginning and end of strings
//
- (void) updateConfigKey
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    NSData *configKey = [preferences secureDataForKey:@"org_safeexambrowser_configKey"];
    if (!configKey) {
        // Filter dictionary so only org_safeexambrowser_SEB_ keys are included
        NSDictionary *filteredPrefsDict = [preferences dictionaryRepresentationSEB];
        
        BOOL initializeContainedKeys = NO;
        // Get dictionary with keys covered by the Config Key in the settings to process
        NSDictionary *configKeyContainedKeys = [preferences secureDictionaryForKey:@"org_safeexambrowser_configKeyContainedKeys"];
        if (configKeyContainedKeys.count == 0) {
            configKeyContainedKeys = [NSDictionary dictionary];
            initializeContainedKeys = YES;
        }
        if (configKeyContainedKeys && [configKeyContainedKeys superclass] != [NSDictionary class] &&
            [configKeyContainedKeys superclass] != [NSMutableDictionary class]) {
            // Class of local preferences value is different than the one from the default value
            // If yes, then cancel reading .seb file and create error object
            DDLogError(@"%s Value for key configKeyContainedKeys is not having the correct NSDictionary class!", __FUNCTION__);
            DDLogError(@"Triggering present alert for 'Local SEB settings have been reset'");
            // Reset Config Key
            [preferences setSecureObject:[NSData data] forKey:@"org_safeexambrowser_configKey"];
            [self presentPreferencesCorruptedError];
            [self resetSEBUserDefaults];
            return;
        }
        
        configKey = [NSData data];
        [self updateConfigKeyInSettings:filteredPrefsDict
              configKeyContainedKeysRef:&configKeyContainedKeys
                           configKeyRef:&configKey
                initializeContainedKeys:initializeContainedKeys];
        
        [preferences setSecureObject:configKeyContainedKeys forKey:@"org_safeexambrowser_configKeyContainedKeys"];
        
        // Store new Config Key in UserDefaults
        [preferences setSecureObject:configKey forKey:@"org_safeexambrowser_configKey"];
    }
}


- (NSDictionary *) updateConfigKeyInSettings:(NSDictionary *) sourceDictionary
                   configKeyContainedKeysRef:(NSDictionary **) configKeyContainedKeys
                                configKeyRef:(NSData **)configKeyRef
                     initializeContainedKeys:(BOOL)initializeContainedKeys
{
    NSMutableDictionary *containedKeysMutable = [*configKeyContainedKeys mutableCopy];
    NSMutableString *jsonString = [NSMutableString new];
    NSDictionary *processedDictionary = [self getConfigKeyDictionaryForKey:@"rootSettings"
                                                                dictionary:sourceDictionary
                                                          containedKeysPtr:&containedKeysMutable
                                                                   jsonPtr:&jsonString
                                                   initializeContainedKeys:initializeContainedKeys];

    *configKeyContainedKeys = [containedKeysMutable copy];
    
    // Convert preferences dictionary to JSON and generate the Config Key hash
    *configKeyRef = [self checksumForJSONString:[jsonString copy]];
    
    return processedDictionary;
}


- (NSDictionary *) getConfigKeyDictionaryForKey:(NSString *)dictionaryKey
                                     dictionary:(NSDictionary *)sourceDictionary
                               containedKeysPtr:(NSMutableDictionary **)containedKeysPtr
                                        jsonPtr:(NSMutableString **)jsonStringPtr
                        initializeContainedKeys:(BOOL)initializeContainedKeys
{
    if (dictionaryKey.length == 0) {
        return nil;
    }
    
    // Get all dictionary keys alphabetically sorted
    NSMutableArray *configKeysAlphabetically = [[sourceDictionary allKeys] sortedArrayUsingDescriptors:@[[NSSortDescriptor
                                                                                                   sortDescriptorWithKey:@"description"
                                                                                                   ascending:YES
                                                                                                   selector:@selector(caseInsensitiveOrdinalCompare:)]]].mutableCopy;
    // Remove the special key "originatorVersion" which doesn't have any functionality,
    // it's just meta data indicating which SEB version saved the config file
    [configKeysAlphabetically removeObject:@"originatorVersion"];
    NSMutableDictionary *filteredPrefsDict = [NSMutableDictionary dictionaryWithCapacity:configKeysAlphabetically.count];
    
    // Get default settings including sub-dictionaries and sub-arrays
    NSDictionary *defaultSettings = [[NSUserDefaults standardUserDefaults] getDefaultDictionaryForKey:dictionaryKey];

    NSArray *containedKeys = [*containedKeysPtr objectForKey:dictionaryKey];
    if (!containedKeys || (containedKeys.count == 0 &&
        configKeysAlphabetically.count != 0 &&
        initializeContainedKeys)) {
        // In case this key was empty, we use all current keys
        containedKeys = configKeysAlphabetically.copy;
        [*containedKeysPtr setObject:containedKeys forKey:dictionaryKey];
    } else if (![configKeysAlphabetically isEqualToArray:containedKeys]) {
        NSArray *newArray = [configKeysAlphabetically arrayByAddingObjectsFromArray:containedKeys];
        containedKeys = (NSArray *)[[NSSet setWithArray:newArray] allObjects];
        containedKeys = [containedKeys sortedArrayUsingDescriptors:@[[NSSortDescriptor
                                                                                                       sortDescriptorWithKey:@"description"
                                                                                                       ascending:YES
                                                                                                       selector:@selector(caseInsensitiveCompare:)]]].mutableCopy;
        [*containedKeysPtr setObject:containedKeys forKey:dictionaryKey];
    }
    
    [*jsonStringPtr appendString:@"{"];
    NSMutableString *dictionaryJSON = [NSMutableString new];
    NSString *key;
    NSUInteger counter = 0;
    
    // Iterate keys and read all values
    while (counter < configKeysAlphabetically.count) {
        key = configKeysAlphabetically[counter];
        id value = [sourceDictionary objectForKey:key];
        id defaultValue = [defaultSettings objectForKey:key];
        Class valueClass = [value superclass];
        Class defaultValueClass = [defaultValue superclass];
        if (!value || (valueClass && defaultValueClass && !([defaultValue isKindOfClass:valueClass] || [value isKindOfClass:defaultValueClass]))) {
            // Class of local preferences value is different than the one from the default value
            // If yes, then cancel reading .seb file and create error object
            DDLogError(@"%s Value for key %@ is not having the correct class!", __FUNCTION__, key);
            DDLogError(@"Triggering present alert for 'Local SEB settings have been reset'");
            // Reset Config Key
            [filteredPrefsDict setObject:[NSData data] forKey:@"configKey"];
            [self presentPreferencesCorruptedError];
            [self resetSEBUserDefaults];
            // Return value: No settings
            return @{};
        }
        
        // Check for sub-dictionaries, key/values of these need to be sorted alphabetically too
        if (valueClass == [NSDictionary class]) {
            value = [self getConfigKeyDictionaryForKey:key
                                            dictionary:value
                                      containedKeysPtr:containedKeysPtr
                                               jsonPtr:&dictionaryJSON
                               initializeContainedKeys:initializeContainedKeys];
            if (!value || [(NSDictionary *)value count] == 0) {
                [configKeysAlphabetically removeObjectAtIndex:counter];
                dictionaryJSON.string = @"";
                continue;
            }
        }
        if (valueClass == [NSMutableDictionary class]) {
            value = [[self getConfigKeyDictionaryForKey:key
                                             dictionary:value
                                       containedKeysPtr:containedKeysPtr
                                                jsonPtr:&dictionaryJSON
                                initializeContainedKeys:initializeContainedKeys] mutableCopy];
            if (!value || [(NSMutableDictionary *)value count] == 0) {
                [configKeysAlphabetically removeObjectAtIndex:counter];
                dictionaryJSON.string = @"";
                continue;
            }
        }
        
        // Sub-dictionaries are usually contained in arrays, so we have to treat this case separately
        if (valueClass == [NSArray class]) {
            value = [self getConfigKeyArrayForKey:key
                                            array:value
                                 containedKeysPtr:containedKeysPtr
                                          jsonPtr:&dictionaryJSON
                          initializeContainedKeys:initializeContainedKeys];
        }
        if (valueClass == [NSMutableArray class]) {
            value = [[self getConfigKeyArrayForKey:key
                                             array:value
                                  containedKeysPtr:containedKeysPtr
                                           jsonPtr:&dictionaryJSON
                           initializeContainedKeys:initializeContainedKeys] mutableCopy];
        }
        // If the key isn't contained in the array of keys in current settings
        // probably because those settings were saved in an older or other
        // platform version of SEB
        // then the value has to be equal to the default value of this key
        // but only when there is a default value for that key
        // this is important also for values, where a default value doesn't make sense
        // like for example "originatorVersion"
        if (![containedKeys containsObject:key]) {
            if (defaultValue && ![value isEqual:defaultValue]) {
                // if this isn't the case, we have to reset the Config Key and abort
                [filteredPrefsDict setObject:[NSData data] forKey:@"configKey"];
                return @{};
            }
        } else if (value) {
            // If the key is contained in the array of keys in current settings,
            // we use it for calculating the Config Key
            [filteredPrefsDict setObject:value forKey:key];
            // Update JSON string
                [*jsonStringPtr appendFormat:@"\"%@\":", key];
            if (dictionaryJSON.length > 0) {
                [*jsonStringPtr appendFormat:@"%@,", dictionaryJSON];
            } else {
                [*jsonStringPtr appendFormat:@"%@,", [self jsonStringForObject:value]];
            }
        }
        dictionaryJSON.string = @"";
        
        counter++;
    }
    
    if ([*jsonStringPtr length] > 2) {
        [*jsonStringPtr deleteCharactersInRange:NSMakeRange([*jsonStringPtr length] - 1, 1)];
    }
    [*jsonStringPtr appendString:@"}"];

    return [filteredPrefsDict copy];
}


- (NSArray *) getConfigKeyArrayForKey:(NSString *)dictionaryKey
                                array:(NSArray *)sourceArray
                     containedKeysPtr:(NSMutableDictionary **)containedKeysPtr
                              jsonPtr:(NSMutableString **)jsonStringPtr
              initializeContainedKeys:(BOOL)initializeContainedKeys
{
    [*jsonStringPtr appendString:@"["];

    NSMutableArray *processedArray = [NSMutableArray new];
    for (id object in sourceArray) {
        if (object) {
            Class objectClass = [object superclass];
            if (objectClass == [NSDictionary class]) {
                [processedArray addObject:(NSDictionary *)[self getConfigKeyDictionaryForKey:dictionaryKey
                                                                                  dictionary:object
                                                                            containedKeysPtr:containedKeysPtr
                                                                                     jsonPtr:jsonStringPtr
                                                                     initializeContainedKeys:initializeContainedKeys]];
            } else if (objectClass == [NSMutableDictionary class]) {
                [processedArray addObject:(NSMutableDictionary *)[[self getConfigKeyDictionaryForKey:dictionaryKey
                                                                                          dictionary:object
                                                                                    containedKeysPtr:containedKeysPtr
                                                                                             jsonPtr:jsonStringPtr
                                                                             initializeContainedKeys:initializeContainedKeys] mutableCopy]];
            } else {
                [processedArray addObject:object];
                [*jsonStringPtr appendFormat:@"%@", [self jsonStringForObject:object]];
            }
            [*jsonStringPtr appendString:@","];
        }
    }
    if ([*jsonStringPtr length] > 2) {
        [*jsonStringPtr deleteCharactersInRange:NSMakeRange([*jsonStringPtr length] - 1, 1)];
    }
    [*jsonStringPtr appendString:@"]"];

    return [processedArray copy];
}


- (NSData*) generateSHAHash:(NSString*)inputString {
    unsigned char hashedChars[32];
    CC_SHA256([inputString UTF8String],
              (uint)[inputString lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
              hashedChars);
    NSData *hashedData = [NSData dataWithBytes:hashedChars length:32];
    return hashedData;
}


- (NSData*) generateSHAHashForData:(NSData *)inputData {
    unsigned char hashedChars[32];
    CC_SHA256(inputData.bytes,
              (uint)inputData.length,
              hashedChars);
    NSData *hashedData = [NSData dataWithBytes:hashedChars length:32];
    return hashedData;
}


- (void) presentPreferencesCorruptedError
{
    // Set the flag to indicate to user later that settings have been reset
    [[MyGlobals sharedMyGlobals] setPreferencesReset:YES];
    DDLogError(@"%s: \[\[MyGlobals sharedMyGlobals] setPreferencesReset:YES]", __FUNCTION__);
    return;
}


- (void) resetSEBUserDefaults
{
    // Remove SEB settings key/values from User Defaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences resetSEBUserDefaults];
    // Update Config and Browser Exam Keys
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    DDLogError(@"Client settings have been reset!");
}


// Error recovery attempter when local preferences need to be reset
- (BOOL) attemptRecoveryFromError:(NSError *)error
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
         postNotificationName:@"requestQuit" object:self];
        success = NO;
    }
    return success;
}


@end
