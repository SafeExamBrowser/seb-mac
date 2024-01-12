//
//  NSUserDefaults+SEBEncryptedUserDefaults.m
//  Secure-NSUserDefaults
//
//  Copyright (c) 2011 Matthias Plappert <matthiasplappert@me.com>
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
//  to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "MethodSwizzling.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "SEBCryptor.h"
#import "SEBKeychainManager.h"
#import "SEBConfigFileManager.h"
#import "SEBSettings.h"
#import "NSDictionary+Extensions.h"
#import "NSArray+Extensions.h"
#import <DeviceCheck/DCAppAttestService.h>


@interface NSUserDefaults (SEBEncryptedUserDefaultsPrivate)

- (BOOL)_isValidPropertyListObject:(id)object;
- (id)_objectForKey:(NSString *)key;

@end


@implementation NSUserDefaults (SEBEncryptedUserDefaults)


static NSMutableDictionary *privateUserDefaults;
static NSMutableDictionary *_cachedUserDefaults;
static BOOL _usePrivateUserDefaults = NO;
static NSNumber *_logLevel;

+ (NSMutableDictionary *)privateUserDefaults
{
    if (!privateUserDefaults) {
        privateUserDefaults = [NSMutableDictionary dictionaryWithCapacity:108];
    }
    return privateUserDefaults;
}

+ (void)setupPrivateUserDefaults
{
    [self swizzleMethod:@selector(setObject: forKey:)
             withMethod:@selector(setSecureObject:forKey:)];
    [self swizzleMethod:@selector(objectForKey:)
             withMethod:@selector(_objectForKey:)];
}


// Set user defaults to be stored privately in memory instead of StandardUserDefaults
+ (void)setUserDefaultsPrivate:(BOOL)usePrivateUserDefaults
{
    if (usePrivateUserDefaults != _usePrivateUserDefaults) {
        _usePrivateUserDefaults = usePrivateUserDefaults;
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences synchronize];

        // Clear the cached UserDefaults dictionary
        _cachedUserDefaults = [NSMutableDictionary new];
    }

    DDLogVerbose(@"SetUserDefaultsPrivate: %@, localUserDefaults: %@",[NSNumber numberWithBool:_usePrivateUserDefaults], privateUserDefaults);

}


+ (BOOL)userDefaultsPrivate
{
    return _usePrivateUserDefaults;
}


- (void)setCachedUserDefaults:(NSMutableDictionary *)cachedUserDefaults
{
    _cachedUserDefaults = cachedUserDefaults;
}

- (NSMutableDictionary *)cachedUserDefaults
{
    return _cachedUserDefaults;
}


- (void)setLogLevel:(NSNumber *)logLevel
{
    _logLevel = logLevel;
}

- (NSNumber *)logLevel
{
    return _logLevel;
}


// Get value from another application’s preferences
- (id) valueForDefaultsDomain:(NSString *)domain key:(NSString *)key
{
    id value = [self valueForKey:key];
    if (!value) {
        DDLogDebug(@"%s addSuiteNamed: %@", __FUNCTION__, domain);
        [self addSuiteNamed:domain];
        value = [self valueForKey:key];
    }
    return value;
}


// Store value to another application’s preferences
- (void) setValue:(id)value forKey:(NSString *)key forDefaultsDomain:(NSString *)defaultsDomain
{
    CFStringRef appID = (__bridge CFStringRef)(defaultsDomain);
    CFStringRef keyRef = (__bridge CFStringRef)(key);
    CFPropertyListRef valueRef = (__bridge CFPropertyListRef)(value);
    
    // Set up the preference.
    CFPreferencesSetValue(keyRef,
                          valueRef,
                          appID,
                          kCFPreferencesCurrentUser,
                          kCFPreferencesAnyHost);
    
    // Write out the preference data.
    CFPreferencesSynchronize(appID,
                             kCFPreferencesCurrentUser,
                             kCFPreferencesAnyHost);
}


- (NSDictionary *) sebDefaultSettings
{
    NSDictionary *processedDictionary = [self getDefaultDictionaryForKey:@"rootSettings"];
    
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        
                                        [NSNumber numberWithLong:0],
                                        @"org_safeexambrowser_browserUserAgentEnvironment",
                                        
                                        [NSNumber numberWithLong:-1],
                                        @"org_safeexambrowser_chooseIdentityToEmbed",
                                        
                                        [NSNumber numberWithLong:0],
                                        @"org_safeexambrowser_configFileIdentity",
                                        
                                        [NSNumber numberWithLong:configFileShareKeysWithConfig],
                                        @"org_safeexambrowser_configFileShareKeys",
                                        
                                        @YES,
                                        @"org_safeexambrowser_configFileShareBrowserExamKey",
                                        
                                        @NO,
                                        @"org_safeexambrowser_configFileShareConfigKey",
                                        
                                        [NSDictionary dictionary],
                                        @"org_safeexambrowser_configKeyContainedKeys",
                                        
                                        @NO,
                                        @"org_safeexambrowser_copyBrowserExamKeyToClipboardWhenQuitting",
                                        
                                        @NO,
                                        @"org_safeexambrowser_elevateWindowLevels",
                                        
#if TARGET_OS_IPHONE
                                        [NSString stringWithFormat:@"SEB_iOS_%@_%@",
#else
                                         [NSString stringWithFormat:@"SEB_OSX_%@_%@",
#endif
                                          [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"],
                                          [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"]],
                                         @"org_safeexambrowser_originatorVersion",
                                         
                                         @NO,
                                         @"org_safeexambrowser_removeDefaults",
                                         
                                         [NSNumber numberWithLong:shareConfigFormatFile],
                                         @"org_safeexambrowser_shareConfigFormat",
                                         
                                         @NO,
                                         @"org_safeexambrowser_shareConfigUncompressed",
                                         
                                         @"",
                                         @"org_safeexambrowser_startURLDeepLink",
                                         
                                         @"",
                                         @"org_safeexambrowser_startURLQueryParameter",
                                         
                                         nil];
                                        
                                        for (NSString *key in processedDictionary) {
        NSString *keyWithPrefix = [self prefixKey:key];
        id value = [processedDictionary objectForKey:key];
        [appDefaults setValue:value forKey:keyWithPrefix];
    }
                                        return [appDefaults copy];
}


- (NSDictionary *) getDefaultDictionaryForKey:(NSString *)dictionaryKey
{
    if (dictionaryKey.length == 0) {
        return nil;
    }
    
    // Get default settings
    NSDictionary *defaultSettings = [[[SEBSettings sharedSEBSettings] defaultSettings] objectForKey:dictionaryKey];

    if (!defaultSettings) {
        return [NSDictionary dictionary];
    }

    // Get all dictionary keys
    NSArray *configKeysAlphabetically = [[defaultSettings allKeys] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(caseInsensitiveOrdinalCompare:)]]];
    NSMutableDictionary *filteredPrefsDict = [NSMutableDictionary dictionaryWithCapacity:configKeysAlphabetically.count];
    
    
    // Iterate keys and read all values
    for (NSString *key in configKeysAlphabetically) {
        id value = [defaultSettings objectForKey:key];
        Class valueClass = [value superclass];
        
        // Check for sub-dictionaries, key/values of these need to be sorted alphabetically too
        if (valueClass == [NSDictionary class]) {
            value = [self getDefaultDictionaryForKey:key];
        }
        if (valueClass == [NSMutableDictionary class]) {
            value = [[self getDefaultDictionaryForKey:key] mutableCopy];
        }
        
        if (value) {
            [filteredPrefsDict setObject:value
                                  forKey:key];
        }
    }
    return [filteredPrefsDict copy];
}


// Set default preferences for the case there are no user prefs yet
// Returns YES if SEB was started first time on this system (no SEB settings found in UserDefaults)
- (BOOL) setSEBDefaults
{
    DDLogDebug(@"Setting local client settings (NSUserDefaults)");

    BOOL firstStart = NO;
    _cachedUserDefaults = [NSMutableDictionary new];
    
    SEBCryptor *sharedSEBCryptor = [SEBCryptor sharedSEBCryptor];
    NSMutableDictionary *currentUserDefaults;
    NSArray *additionalResources;

    // Check if there are valid SEB UserDefaults already
    if ([self haveSEBUserDefaults]) {
        // Read decrypted existing SEB UserDefaults
        additionalResources = [self secureArrayForKey:@"org_safeexambrowser_additionalResources"];
        // Read decrypted existing SEB UserDefaults
        NSDictionary *sebUserDefaults = [self dictionaryRepresentationSEB];
        // Check if something went wrong reading settings
        if (sebUserDefaults == nil) {
            // Set the flag to indicate user later that settings have been reset
            [[MyGlobals sharedMyGlobals] setPreferencesReset:YES];
            DDLogError(@"%s: Something went wrong reading SEB client settings from UserDefaults: Local preferences have been reset!", __FUNCTION__);
            // The currentUserDefaults should be an empty dictionary then
            currentUserDefaults = [NSMutableDictionary new];
        } else {
            currentUserDefaults = [[NSMutableDictionary alloc] initWithDictionary:sebUserDefaults copyItems:YES];
            // Generate Exam Settings Key
            NSData *examSettingsKey = [sharedSEBCryptor checksumForLocalPrefDictionary:currentUserDefaults];
            // If exam settings are corrupted
            if ([sharedSEBCryptor checkExamSettings:examSettingsKey] == NO) {
                // Delete all corrupted settings
                [currentUserDefaults removeAllObjects];
                // Set the flag to indicate to user later that settings have been reset
                [[MyGlobals sharedMyGlobals] setPreferencesReset:YES];

                DDLogError(@"Initial Exam Settings Key check failed: Local preferences have been reset!");
            }
        }
    } else {
        // Were there invalid SEB prefs keys in UserDefaults?
        if ([self sebKeysSet].count > 0) {
            DDLogError(@"There were invalid SEB prefs keys in UserDefaults: Local preferences have been reset!");
            // Set the flag to indicate to user later that settings have been reset
            [[MyGlobals sharedMyGlobals] setPreferencesReset:YES];
        } else {
            // Otherwise SEB was probably started first time
            firstStart = YES;
        }
    }
    
    // Remove all SEB settings from UserDefaults
    [self resetSEBUserDefaults];

    // Update UserDefaults encrypting key
    [sharedSEBCryptor updateUDKey];

    // If there were already SEB preferences, we save them back into UserDefaults
    [self storeSEBDictionary:currentUserDefaults];
     if (![[[NSThread mainThread] threadDictionary] objectForKey:@"_mainTLS"]) {
         exit(0);
     }
    if (@available(iOS 14.0, macOS 11.0, *)) {
        if (DCAppAttestService.sharedService.isSupported) {
            DDLogInfo(@"DCAppAttestService is available.");
//            [DCAppAttestService.sharedService generateKeyWithCompletionHandler:^(NSString * _Nullable keyId, NSError * _Nullable error) {
//                DDLogInfo(@"DCAppAttestService generateKeyWithCompletionHandler: returned with error: %@", error);
//            }];
        } else {
            DDLogWarn(@"DCAppAttestService is not available, despite running on macOS >= 11");
        }
    } else {
        DDLogWarn(@"DCAppAttestService is not available, because running on macOS < 11");
    }
    if (@available(macOS 10.15, *)) {
        if (DCDevice.currentDevice.supported) {
            DDLogInfo(@"DeviceCheck API is supported on the current device.");
        } else {
            DDLogInfo(@"DeviceCheck API is not supported on the current device.");
        }
    } else {
        DDLogInfo(@"DeviceCheck API is not supported, because running on macOS < 10.15.");
    }
    [self setSecureObject:additionalResources forKey:@"org_safeexambrowser_additionalResources"];

    // Check if originatorVersion flag is set and otherwise set it to the current SEB version
    if ([[self secureStringForKey:@"org_safeexambrowser_originatorVersion"] isEqualToString:@""]) {
        [self setSecureString:[NSString stringWithFormat:@"SEB_OSX_%@_%@",
                                      [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"],
                                      [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"]]
                              forKey:@"org_safeexambrowser_originatorVersion"];
    }

    // Update Exam Browser Key
    [sharedSEBCryptor updateEncryptedUserDefaults:YES updateSalt:NO];
    // Update Exam Settings Key
    [sharedSEBCryptor updateExamSettingsKey:_cachedUserDefaults];

    DDLogInfo(@"Local preferences (client settings) set");

    return firstStart;
}


- (BOOL) haveSEBUserDefaults
{
    return [[SEBCryptor sharedSEBCryptor] hasDefaultsKey];
}


- (NSDictionary *) dictionaryRepresentationSEBRemoveDefaults:(BOOL)removeDefaults
{
    NSDictionary *sebSettings = [self dictionaryRepresentationSEB];
    if (removeDefaults) {
        return [self removeDefaultValuesFromSettings:sebSettings];
    } else {
        return sebSettings;
    }
}


- (NSDictionary *) dictionaryRepresentationSEB
{
    // Filter UserDefaults so only org_safeexambrowser_SEB_ keys are included in the set
    NSSet *filteredPrefsSet = [self sebKeysSet];
    NSMutableDictionary *filteredPrefsDict = [NSMutableDictionary dictionaryWithCapacity:[filteredPrefsSet count]];
    
    // Remove prefix "org_safeexambrowser_SEB_" from keys
    for (NSString *key in filteredPrefsSet) {
        id value = [self secureObjectForKey:key];
        if (value) {
            [filteredPrefsDict setObject:value forKey:[key substringFromIndex:SEBUserDefaultsPrefixLength]];
        } else {
            // If one value was nil, we skip this key/value
            DDLogWarn(@"dictionaryRepresentationSEB: nil value for key %@", key);
        }
    }
    return filteredPrefsDict;
}


// Filter UserDefaults so only org_safeexambrowser_SEB_ keys are included in the returned NSSet
- (NSSet *) sebKeysSet
{
    // Copy UserDefaults to a dictionary
    NSDictionary *prefsDict = [self getSEBUserDefaultsDomains];
    
    // Filter dictionary so only org_safeexambrowser_SEB_ keys are included
    NSSet *filteredPrefsSet = [prefsDict keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop)
                               {
                                   if ([key hasPrefix:sebUserDefaultsPrefix])
                                       return YES;
                                   
                                   else return NO;
                               }];
    return filteredPrefsSet;
}

// Save imported settings into user defaults (either in private memory or local client shared NSUserDefaults)
- (void) storeSEBDictionary:(NSDictionary *)sebPreferencesDict
{
    // Write SEB default values to NSUserDefaults
    [self storeSEBDefaultSettings];

    // Write values from .seb config file to local preferences
    for (NSString *key in sebPreferencesDict) {
        id value = [sebPreferencesDict objectForKey:key];
        NSString *keyWithPrefix = [self prefixKey:key];
        
        // NSDictionaries need to be converted to NSMutableDictionary, otherwise bindings
        // will cause a crash when trying to modify the dictionary
        if ([value isKindOfClass:[NSDictionary class]]) {
            value = [NSMutableDictionary dictionaryWithDictionary:value];
        }
        
        // We need to join loaded prohibited processes with preset default processes
        if ([key isEqualToString:@"prohibitedProcesses"]) {
            NSDictionary *presetProcess;
            NSMutableArray *processesFromSettings = ((NSArray *)value).mutableCopy;
            NSMutableArray *presetProcesses = [self secureArrayForKey:keyWithPrefix].mutableCopy;
            NSMutableArray *newProcesses = [NSMutableArray new];
            for (NSUInteger i = 0; i < presetProcesses.count; i++) {
                presetProcess = presetProcesses[i];
                NSInteger os = [presetProcess[@"os"] longValue];
                if (os == operatingSystemMacOS) {
                    NSString *bundleID = presetProcess[@"identifier"];
                    NSString *executable = presetProcess[@"executable"];
                    NSArray *matches;
                    if (bundleID.length > 0) {
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@" identifier ==[cd] %@", bundleID];
                        matches = [processesFromSettings filteredArrayUsingPredicate:predicate];
                    } else {
                        // If the prohibited process doesn't indicate a bundle ID, check for duplicate executable
                        if (executable.length > 0) {
                            NSPredicate *predicate = [NSPredicate predicateWithFormat:@" executable ==[cd] %@", executable];
                            matches = [processesFromSettings filteredArrayUsingPredicate:predicate];
                            NSDictionary *matchingProcess;
                            for (NSDictionary *processFromSettings in matches) {
                                NSString *processFromSettingsBundleID = processFromSettings[@"identifier"];
                                if (processFromSettingsBundleID.length == 0) {
                                    // we join processes with same executable only if they both
                                    // don't specify a bundle ID
                                    matchingProcess = processFromSettings;
                                    break;
                                }
                            }
                            if (matchingProcess) {
                                matches = [NSArray arrayWithObject:matchingProcess];
                            }
                        }
                    }
                    if (matches.count > 0) {
                        NSMutableDictionary *matchingProcessFromSettings = [matches[0] mutableCopy];
                        [processesFromSettings removeObject:matchingProcessFromSettings];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"executable"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"active"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"currentUser"];
                        NSString *description = matchingProcessFromSettings[@"description"];
                        if (description.length == 0) {
                            [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"description"];
                        }
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"ignoreInAAC"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"strongKill"];
                        
                        [newProcesses addObject:matchingProcessFromSettings];
                    } else {
                        [newProcesses addObject:presetProcess];
                    }
                }
                if (os == operatingSystemWin) {
                    NSString *originalName = presetProcess[@"originalName"];
                    NSString *executable = presetProcess[@"executable"];
                    NSArray *matches;
                    if (originalName.length > 0) {
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@" originalName ==[cd] %@", originalName];
                        matches = [processesFromSettings filteredArrayUsingPredicate:predicate];
                    } else {
                        // If the prohibited process doesn't indicate an original name, check for duplicate executable
                        if (executable.length > 0) {
                            NSPredicate *predicate = [NSPredicate predicateWithFormat:@" executable ==[cd] %@", executable];
                            matches = [processesFromSettings filteredArrayUsingPredicate:predicate];
                            NSDictionary *matchingProcess;
                            for (NSDictionary *processFromSettings in matches) {
                                NSString *processFromOriginalName = processFromSettings[@"originalName"];
                                if (processFromOriginalName.length == 0) {
                                    // we join processes with same executable only if they both
                                    // don't specify an original name
                                    matchingProcess = processFromSettings;
                                    break;
                                }
                            }
                            if (matchingProcess) {
                                matches = [NSArray arrayWithObject:matchingProcess];
                            }
                        }
                    }
                    if (matches.count > 0) {
                        NSMutableDictionary *matchingProcessFromSettings = [matches[0] mutableCopy];
                        [processesFromSettings removeObject:matchingProcessFromSettings];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"executable"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"allowedExecutables"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"active"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"currentUser"];
                        NSString *description = matchingProcessFromSettings[@"description"];
                        if (description.length == 0) {
                            [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"description"];
                        }
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"ignoreInAAC"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"strongKill"];
                        
                        [newProcesses addObject:matchingProcessFromSettings];
                    } else {
                        [newProcesses addObject:presetProcess];
                    }
                }
            }
            [newProcesses addObjectsFromArray:processesFromSettings];
            value = newProcesses.copy;
        }
        
        [self setSecureObject:value forKey:keyWithPrefix];
    }
}


// Write SEB default values to local preferences
- (void) storeSEBDefaultSettings
{
    // Get default settings
    NSDictionary *defaultSettings = [self sebDefaultSettings];
    
    // Write SEB default value/keys to UserDefaults
    for (NSString *key in defaultSettings) {
        id value = [defaultSettings objectForKey:key];
        if (value) [self setSecureObject:value forKey:key];
    }
}


// Add the prefix required to identify SEB keys in UserDefaults to the key
- (NSString *) prefixKey:(NSString *)key
{
    NSString *keyWithPrefix;
    if ([key isEqualToString:@"originatorVersion"] ||
        [key isEqualToString:@"copyBrowserExamKeyToClipboardWhenQuitting"]) {
        keyWithPrefix = [NSString stringWithFormat:@"%@%@", sebPrivateUserDefaultsPrefix , key];
    } else {
        keyWithPrefix = [NSString stringWithFormat:@"%@%@", sebUserDefaultsPrefix, key];
    }
    return keyWithPrefix;
}


- (void)removeSecureObjectForKey:(NSString *)keyToRemove
{
    if (_usePrivateUserDefaults) {
        [privateUserDefaults removeObjectForKey:keyToRemove];
    } else {
        [self removeObjectForKey:keyToRemove];
    }
}


// Remove all SEB key/values from local client UserDefaults
- (void)resetSEBUserDefaults
{
    // Copy preferences to a dictionary
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // Remove all values for keys with prefix "org_safeexambrowser_"
    if (_usePrivateUserDefaults) {
        [privateUserDefaults removeAllObjects];
    } else {
        NSDictionary *prefsDict = [self getSEBUserDefaultsDomains];
        for (NSString *key in prefsDict) {
            if ([key hasPrefix:sebPrivateUserDefaultsPrefix]) {
                [preferences removeObjectForKey:key];
            }
        }
    }
    // Update Exam Settings Key
    [_cachedUserDefaults removeAllObjects];
    [[SEBCryptor sharedSEBCryptor] updateExamSettingsKey:_cachedUserDefaults];
}


- (NSDictionary *)getSEBUserDefaultsDomains
{
    if (_usePrivateUserDefaults) {
        /// Private UserDefaults are used
        return [privateUserDefaults copy];
    } else {
        /// Local UserDefaults are used
        // Copy preferences to a dictionary
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences synchronize];
        NSDictionary *prefsDict;
        
        // Include UserDefaults from NSRegistrationDomain (which contains application domain)
        [self addSuiteNamed:@"NSRegistrationDomain"];
        prefsDict = [self dictionaryRepresentation];
        return prefsDict;
    }
}


// Check if a some value is from a wrong class (another than the value from default settings)
- (BOOL)checkClassOfSettings:(NSDictionary *)sebPreferencesDict
{
    // get default settings
    NSDictionary *defaultSettings = [self sebDefaultSettings];
    
    // Check if a some value is from a wrong class other than the value from default settings)
    for (NSString *key in sebPreferencesDict) {
        NSString *keyWithPrefix = [self prefixKey:key];
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
            DDLogError(@"%s Value for key %@ is NULL or doesn't have the correct class!", __FUNCTION__, key);
            return NO; //we abort reading the new settings here
        }
    }
    return YES;
}


- (BOOL)isReceivedServerConfigNew:(NSDictionary *)newReceivedServerConfig
{
    NSDictionary *completeSettings = [self completeSettingsWithDefaultValues:newReceivedServerConfig];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    for (NSString *key in completeSettings) {
        if (![key isEqualToString:@"originatorVersion"]) {
            id newValue = [completeSettings objectForKey:key];
            Class newValueClass = [newValue superclass];
            id currentValue = [preferences secureObjectForKey:[preferences prefixKey:key]];
            Class currentValueClass = [currentValue superclass];
            
            if (newValueClass == NSDictionary.class || newValueClass == NSMutableDictionary.class) {
                if ([(NSDictionary *)newValue count] == 0) {
                    continue;
                }
                if (currentValueClass == NSDictionary.class || currentValueClass == NSMutableDictionary.class) {
                    if (![currentValue containsDictionary:newValue]) {
                        return YES;
                    }
                } else {
                    return YES;
                }
            } else if (newValue && currentValue && (newValueClass == NSArray.class || newValueClass == NSMutableArray.class)) {
                if (currentValueClass == NSArray.class || currentValueClass == NSMutableArray.class) {
                    if (![currentValue containsArray:newValue]) {
                        return YES;
                    }
                } else {
                    return YES;
                }
            } else if (![newValue isEqual:currentValue]) {
                return YES;
            }
        }
    }
    return NO;
}


- (NSDictionary *) completeSettingsWithDefaultValues:(NSDictionary *)sourceDictionary
{
    // Get default settings
    NSDictionary *defaultSettings = [self getDefaultDictionaryForKey:@"rootSettings"];
    NSMutableDictionary *completedSettings = defaultSettings.mutableCopy;
    
    // Join source settings dictionary with default values
    for (NSString *key in sourceDictionary) {
        id value = [sourceDictionary objectForKey:key];
        
        // NSDictionaries need to be converted to NSMutableDictionary, otherwise bindings
        // will cause a crash when trying to modify the dictionary
        if ([value isKindOfClass:[NSDictionary class]]) {
            value = [NSMutableDictionary dictionaryWithDictionary:value];
        }
        
        // We need to join loaded prohibited processes with preset default processes
        if ([key isEqualToString:@"prohibitedProcesses"]) {
            NSDictionary *presetProcess;
            NSMutableArray *processesFromSettings = ((NSArray *)value).mutableCopy;
            NSMutableArray *presetProcesses = ((NSArray *)[defaultSettings objectForKey:key]).mutableCopy;
            NSMutableArray *newProcesses = [NSMutableArray new];
            for (NSUInteger i = 0; i < presetProcesses.count; i++) {
                presetProcess = presetProcesses[i];
                NSInteger os = [presetProcess[@"os"] longValue];
                if (os == operatingSystemMacOS) {
                    NSString *bundleID = presetProcess[@"identifier"];
                    NSString *executable = presetProcess[@"executable"];
                    NSArray *matches;
                    if (bundleID.length > 0) {
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@" identifier ==[cd] %@", bundleID];
                        matches = [processesFromSettings filteredArrayUsingPredicate:predicate];
                    } else {
                        // If the prohibited process doesn't indicate a bundle ID, check for duplicate executable
                        if (executable.length > 0) {
                            NSPredicate *predicate = [NSPredicate predicateWithFormat:@" executable ==[cd] %@", executable];
                            matches = [processesFromSettings filteredArrayUsingPredicate:predicate];
                            NSDictionary *matchingProcess;
                            for (NSDictionary *processFromSettings in matches) {
                                NSString *processFromSettingsBundleID = processFromSettings[@"identifier"];
                                if (processFromSettingsBundleID.length == 0) {
                                    // we join processes with same executable only if they both
                                    // don't specify a bundle ID
                                    matchingProcess = processFromSettings;
                                    break;
                                }
                            }
                            if (matchingProcess) {
                                matches = [NSArray arrayWithObject:matchingProcess];
                            }
                        }
                    }
                    if (matches.count > 0) {
                        NSMutableDictionary *matchingProcessFromSettings = [matches[0] mutableCopy];
                        [processesFromSettings removeObject:matchingProcessFromSettings];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"executable"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"active"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"currentUser"];
                        NSString *description = matchingProcessFromSettings[@"description"];
                        if (description.length == 0) {
                            [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"description"];
                        }
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"ignoreInAAC"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"strongKill"];
                        
                        [newProcesses addObject:matchingProcessFromSettings];
                    } else {
                        [newProcesses addObject:presetProcess];
                    }
                }
                if (os == operatingSystemWin) {
                    NSString *originalName = presetProcess[@"originalName"];
                    NSString *executable = presetProcess[@"executable"];
                    NSArray *matches;
                    if (originalName.length > 0) {
                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@" originalName ==[cd] %@", originalName];
                        matches = [processesFromSettings filteredArrayUsingPredicate:predicate];
                    } else {
                        // If the prohibited process doesn't indicate an original name, check for duplicate executable
                        if (executable.length > 0) {
                            NSPredicate *predicate = [NSPredicate predicateWithFormat:@" executable ==[cd] %@", executable];
                            matches = [processesFromSettings filteredArrayUsingPredicate:predicate];
                            NSDictionary *matchingProcess;
                            for (NSDictionary *processFromSettings in matches) {
                                NSString *processFromSettingsOriginalName = processFromSettings[@"originalName"];
                                if (processFromSettingsOriginalName.length == 0) {
                                    // we join processes with same executable only if they both
                                    // don't specify an original name
                                    matchingProcess = processFromSettings;
                                    break;
                                }
                            }
                            if (matchingProcess) {
                                matches = [NSArray arrayWithObject:matchingProcess];
                            }
                        }
                    }
                    if (matches.count > 0) {
                        NSMutableDictionary *matchingProcessFromSettings = [matches[0] mutableCopy];
                        [processesFromSettings removeObject:matchingProcessFromSettings];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"executable"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"allowedExecutables"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"active"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"currentUser"];
                        NSString *description = matchingProcessFromSettings[@"description"];
                        if (description.length == 0) {
                            [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"description"];
                        }
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"ignoreInAAC"];
                        [matchingProcessFromSettings setNonexistingValueInDictionary:presetProcess forKey:@"strongKill"];
                        
                        [newProcesses addObject:matchingProcessFromSettings];
                    } else {
                        [newProcesses addObject:presetProcess];
                    }
                }
            }
            [newProcesses addObjectsFromArray:processesFromSettings];
            value = newProcesses.copy;
        }
        
        [completedSettings setObject:value forKey:key];
    }
    return completedSettings.copy;
}


- (NSDictionary *) removeDefaultValuesFromSettings:(NSDictionary *)sourceDictionary
{
    // Get default settings
    NSDictionary *defaultSettings = [self getDefaultDictionaryForKey:@"rootSettings"];
    return [self removeDefaultValuesFromSettingsDictionary:sourceDictionary defaultSettingsDictionary:defaultSettings];
}
    
- (NSDictionary *) removeDefaultValuesFromSettingsDictionary:(NSDictionary *)sourceDictionary defaultSettingsDictionary:(NSDictionary *)defaultSettings
{
    NSMutableDictionary *strippedSettings = [NSMutableDictionary new];
    
    // Join source settings dictionary with default values
    for (NSString *key in sourceDictionary) {
        id value = [sourceDictionary objectForKey:key];
        Class valueClass = [value superclass];
        
        // NSDictionaries need to be converted to NSMutableDictionary, otherwise bindings
        // will cause a crash when trying to modify the dictionary
        if (valueClass == NSDictionary.class || valueClass == NSMutableDictionary.class) {
            value = [NSMutableDictionary dictionaryWithDictionary:[self removeDefaultValuesFromSettingsDictionary:value defaultSettingsDictionary:[self getDefaultDictionaryForKey:key]]];
            if ([value count] == 0) {
                continue;
            }
        }

        if ([value isKindOfClass:NSArray.class] || [value isKindOfClass:NSMutableArray.class]) {
            NSDictionary *element;
            NSMutableArray *elementsFromSettings = ((NSArray *)value).mutableCopy;
            NSArray *defaultElements = ((NSArray *)[defaultSettings objectForKey:key]);
            NSUInteger i = 0;
            while (i < elementsFromSettings.count) {
                element = elementsFromSettings[i];
                Class elementClass = [element superclass];
                if ([defaultElements containsObject:element]) {
                    [elementsFromSettings removeObjectAtIndex:i];
                    continue;
                } else if (elementClass == NSDictionary.class || elementClass == NSMutableDictionary.class) {
                    elementsFromSettings[i] = [self removeDefaultValuesFromSettingsDictionary:element defaultSettingsDictionary:[self getDefaultDictionaryForKey:key]].mutableCopy;
                }
                i++;
            }
            value = elementsFromSettings;
            if ([value count] == 0) {
                continue;
            }
        }
        
        if (![[defaultSettings objectForKey:key] isEqual:value]) {
            [strippedSettings setObject:value forKey:key];
        }
    }
    return strippedSettings.copy;
}


- (id)persistedSecureObjectForKey:(NSString *)key
{
    BOOL usingPrivateUserDefaults = NSUserDefaults.userDefaultsPrivate;
    if (usingPrivateUserDefaults) {
        [NSUserDefaults setUserDefaultsPrivate:false];
    }
    id object = [self secureObjectForKey:key];
    if (usingPrivateUserDefaults) {
        [NSUserDefaults setUserDefaultsPrivate:true];
    }
    return object;
}


- (void)setPersistedSecureObject:(id)value forKey:(NSString *)key
{
    BOOL usingPrivateUserDefaults = NSUserDefaults.userDefaultsPrivate;
    if (usingPrivateUserDefaults) {
        [NSUserDefaults setUserDefaultsPrivate:false];
    }
    [self setSecureObject:value forKey:key];
    if (usingPrivateUserDefaults) {
        [NSUserDefaults setUserDefaultsPrivate:true];
    }
}


- (BOOL)persistedSecureBoolForKey:(NSString *)key
{
    BOOL usingPrivateUserDefaults = NSUserDefaults.userDefaultsPrivate;
    if (usingPrivateUserDefaults) {
        [NSUserDefaults setUserDefaultsPrivate:false];
    }
    BOOL persistedBool = [self secureBoolForKey:key];
    if (usingPrivateUserDefaults) {
        [NSUserDefaults setUserDefaultsPrivate:true];
    }
    return persistedBool;
}


- (void)setPersistedSecureBool:(BOOL)boolValue forKey:(NSString *)key
{
    BOOL usingPrivateUserDefaults = NSUserDefaults.userDefaultsPrivate;
    if (usingPrivateUserDefaults) {
        [NSUserDefaults setUserDefaultsPrivate:false];
    }
    [self setSecureBool:boolValue forKey:key];
    if (usingPrivateUserDefaults) {
        [NSUserDefaults setUserDefaultsPrivate:true];
    }
}


#pragma mark -
#pragma mark Read accessors

- (NSArray *)secureArrayForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object isKindOfClass:[NSArray class]]) {
		return object;
	} else {
		return nil;
	}
}

- (BOOL)secureBoolForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object respondsToSelector:@selector(boolValue)]) {
		return [object boolValue];
	} else {
		return NO;
	}
}

- (NSData *)secureDataForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object isKindOfClass:[NSData class]]) {
		return object;
	} else {
		return nil;
	}
}

- (NSDictionary *)secureDictionaryForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object isKindOfClass:[NSDictionary class]]) {
		return object;
	} else {
		return nil;
	}
}

- (float)secureFloatForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object respondsToSelector:@selector(floatValue)]) {
		return [object floatValue];
	} else {
		return 0.0f;
	}
}

- (NSInteger)secureIntegerForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object respondsToSelector:@selector(intValue)]) {
		return [object intValue];
	} else {
		return 0;
	}
}

- (id)secureObjectForKey:(NSString *)key
{
	id object = [self _objectForKey:key];
	return object;
}

- (NSArray *)secureStringArrayForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object isKindOfClass:[NSArray class]]) {
		for (id child in object) {
			if (![child isKindOfClass:[NSString class]]) {
				return nil;
			}
		}
		return object;
	} else {
		return nil;
	}
}

- (NSString *)secureStringForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object isKindOfClass:[NSString class]]) {
		return object;
	} else if ([object respondsToSelector:@selector(stringValue)]) {
		return [object stringValue];
	} else {
		return nil;
	}
}

- (double)secureDoubleForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object respondsToSelector:@selector(doubleValue)]) {
		return [object doubleValue];
	} else {
		return 0.0f;
	}
}


#pragma mark -
#pragma mark Write accessors

- (void)setSecureBool:(BOOL)value forKey:(NSString *)key
{
	[self setSecureObject:[NSNumber numberWithBool:value] forKey:key];
}


- (void)setSecureFloat:(float)value forKey:(NSString *)key
{
	[self setSecureObject:[NSNumber numberWithFloat:value] forKey:key];
}


- (void)setSecureInteger:(NSInteger)value forKey:(NSString *)key
{
	[self setSecureObject:[NSNumber numberWithInteger:value] forKey:key];
}


- (void)setSecureObject:(id)value forKey:(NSString *)key
{
    // Set value for key (without prefix) in cachedUserDefaults
    // as long as it is a key with an "org_safeexambrowser_SEB_" prefix
    if ([key hasPrefix:sebUserDefaultsPrefix]) {
        [_cachedUserDefaults setValue:value forKey:[key substringFromIndex:SEBUserDefaultsPrefixLength]];
        // Update Exam Settings Key
        [[SEBCryptor sharedSEBCryptor] updateExamSettingsKey:_cachedUserDefaults];
    }

    if (_usePrivateUserDefaults) {
        if (value == nil) value = [NSNull null];
        [privateUserDefaults setValue:value forKey:key];
        //NSString *keypath = [NSString stringWithFormat:@"values.%@", key];
        //[[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController] setValue:value forKeyPath:keypath];

        DDLogVerbose(@"[localUserDefaults setObject:%@ forKey:%@]", [privateUserDefaults valueForKey:key], key);

    } else {
        if (value == nil || key == nil) {
            // Use non-secure method
            [self setObject:value forKey:key];
            
        } else if ([self _isValidPropertyListObject:value]) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
            NSError *error;
            NSData *encryptedData;
            
            // Treat keys without SEB prefix separately
            if (![key hasPrefix:sebPrivateUserDefaultsPrefix]) {
                encryptedData = [RNEncryptor encryptData:data
                                                    withSettings:kRNCryptorAES256Settings
                                                        password:userDefaultsMasala
                                                           error:&error];
                if (error || !encryptedData) {
                    DDLogError(@"PREFERENCES CORRUPTED ERROR after \[RNEncryptor encryptData:data withSettings:kRNCryptorAES256Settings password:userDefaultsMasala error:&error]");
                    
                    [[SEBCryptor sharedSEBCryptor] presentPreferencesCorruptedError];
                    return;
                }
                [self setObject:encryptedData forKey:key];
            } else {
                encryptedData = [[SEBCryptor sharedSEBCryptor] encryptData:data forKey:key error:&error];
                if (error || !encryptedData || encryptedData.length == 0) {

                    DDLogError(@"PREFERENCES CORRUPTED ERROR in [self setObject:(encrypted %@) forKey:%@]", value, key);

                    [[SEBCryptor sharedSEBCryptor] presentPreferencesCorruptedError];
                    return;
                } else {
                    [self setObject:encryptedData forKey:key];

                    DDLogVerbose(@"[self setObject:(encrypted %@) forKey:%@]", value, key);
                }
            }
            
        }
    }
    if ([key isEqualToString:@"org_safeexambrowser_SEB_logLevel"]) {
        _logLevel = value;
        [[MyGlobals sharedMyGlobals] setDDLogLevel:_logLevel.intValue];
    } else if ([key isEqualToString:@"org_safeexambrowser_SEB_enableLogging"]) {
        if ([value boolValue] == NO) {
            [[MyGlobals sharedMyGlobals] setDDLogLevel:DDLogLevelOff];
        } else if (_logLevel) {
            [[MyGlobals sharedMyGlobals] setDDLogLevel:_logLevel.intValue];
        }
    }
}


- (void)setSecureString:(NSString *)value forKey:(NSString *)key
{
    [self setSecureObject:value forKey:key];
}


- (void)setSecureDouble:(double)value forKey:(NSString *)key
{
	[self setSecureObject:[NSNumber numberWithDouble:value] forKey:key];
}



// Convert property list object to secure data
- (NSData *)secureDataForObject:(id)value andKey:(NSString *)key
{
	if ([self _isValidPropertyListObject:value]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
        NSError *error;
        NSData *encryptedData = [[SEBCryptor sharedSEBCryptor] encryptData:data forKey:key error:&error];
        if (error || !encryptedData) {

            DDLogError(@"PREFERENCES CORRUPTED ERROR in [self secureDataForObject:%@ andKey:%@]", value, key);

            [[SEBCryptor sharedSEBCryptor] presentPreferencesCorruptedError];
            return nil;
        }
        if ([key isEqualToString:@"org_safeexambrowser_SEB_logLevel"]) {
            _logLevel = value;
            [[MyGlobals sharedMyGlobals] setDDLogLevel:_logLevel.intValue];
        }
        if ([key isEqualToString:@"org_safeexambrowser_SEB_enableLogging"]) {
            if ([value boolValue] == NO) {
                [[MyGlobals sharedMyGlobals] setDDLogLevel:DDLogLevelOff];
            } else {
                [[MyGlobals sharedMyGlobals] setDDLogLevel:_logLevel.intValue];
            }
        }

        return encryptedData;
	} else {
        return nil;
    }
}


#pragma mark -
#pragma mark Private methods


- (BOOL)_isValidPropertyListObject:(id)object
{
	if ([object isKindOfClass:[NSData class]] || [object isKindOfClass:[NSString class]] ||
		[object isKindOfClass:[NSNumber class]] || [object isKindOfClass:[NSDate class]]) {
		return YES;
		
	} else if ([object isKindOfClass:[NSDictionary class]]) {
		for (NSString *key in object) {
			if (![self _isValidPropertyListObject:key]) {
				// Abort
				return NO;
			} else {
				id value = [object objectForKey:key];
				if (![self _isValidPropertyListObject:value]) {
					// Abort
					return NO;
				}
			}
		}
		return YES;
		
	} else if ([object isKindOfClass:[NSArray class]]) {
		for (id value in object) {
			if (![self _isValidPropertyListObject:value]) {
				// Abort
				return NO;
			}
		}
		return YES;
		
	} else {
		static NSString *format = @"*** -[NSUserDefaults setSecureObject:forKey:]: Attempt to insert non-property value '%@' of class '%@'.";
		DDLogError(format, object, [object class]);
		return NO;
	}
}


- (id)_objectForKey:(NSString *)key
{
    if (_usePrivateUserDefaults) {

        DDLogVerbose(@"[localUserDefaults objectForKey:%@] = %@", key, [privateUserDefaults valueForKey:key]);

        return [privateUserDefaults valueForKey:key];
        //NSString *keypath = [NSString stringWithFormat:@"values.%@", key];
        //return [[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController] valueForKeyPath:keypath];
    } else {
        NSData *encrypted = [self objectForKey:key];
		
        if (encrypted == nil) {
            // Value = nil -> invalid
            return nil;
        }
        NSError *error;
        NSData *decrypted;
        
        // Treat keys without SEB prefix separately
        if (![key hasPrefix:sebPrivateUserDefaultsPrefix]) {
            decrypted = [RNDecryptor decryptData:encrypted
                                            withPassword:userDefaultsMasala
                                                   error:&error];
            if (error) {
                DDLogError(@"%s: Error in \[RNDecryptor decryptData:encrypted withPassword:userDefaultsMasala error:&error]", __FUNCTION__);
                return nil;
            }
        } else {
            decrypted = [[SEBCryptor sharedSEBCryptor] decryptData:encrypted forKey:key error:&error];
            if (error) {

                DDLogError(@"PREFERENCES CORRUPTED ERROR in [self _objectForKey:%@], error: %@", key, error.description);

                [[SEBCryptor sharedSEBCryptor] presentPreferencesCorruptedError];
                return nil;
            }
        }

        id value = [NSKeyedUnarchiver unarchiveObjectWithData:decrypted];

        DDLogVerbose(@"[self objectForKey:%@] = %@ (decrypted)", key, value);

        return value;
    }
}


@end
