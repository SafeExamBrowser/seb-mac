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

#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "NSUserDefaultsController+SEBEncryptedUserDefaultsController.h"
#import "SEBEncryptedUserDefaultsController.h"
#import "MethodSwizzling.h"
//#import "RNCryptor.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "SEBCryptor.h"
#import "MyGlobals.h"
#import "Constants.h"


@interface NSUserDefaults (SEBEncryptedUserDefaultsPrivate)

- (BOOL)_isValidPropertyListObject:(id)object;
- (id)_objectForKey:(NSString *)key;
- (NSString *)_hashObject:(id)object;
- (NSString *)_hashData:(NSData *)data;

@end


@implementation NSUserDefaults (SEBEncryptedUserDefaults)

static NSData *_secretData           = nil;
static NSData *_deviceIdentifierData = nil;

static NSMutableDictionary *localUserDefaults;
static BOOL _usePrivateUserDefaults = NO;


+ (NSMutableDictionary *)privateUserDefaults
{
    if (!localUserDefaults) {
        localUserDefaults = [NSMutableDictionary dictionaryWithCapacity:21];
    }
    return localUserDefaults;
}

+ (void)setupPrivateUserDefaults
{
    [self swizzleMethod:@selector(setObject: forKey:)
             withMethod:@selector(setSecureObject:forKey:)];
    [self swizzleMethod:@selector(objectForKey:)
             withMethod:@selector(_objectForKey:)];
}


// Set user defaults to be stored privately in memory instead of StandardUserDefaults
+ (void)setUserDefaultsPrivate:(BOOL)privateUserDefaults
{
    if (privateUserDefaults != _usePrivateUserDefaults) {
        _usePrivateUserDefaults = privateUserDefaults;
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        BOOL success = [preferences synchronize];
#ifdef DEBUG
        NSLog(@"[preferences synchronize] = %@",[NSNumber numberWithBool:success]);
#endif
    }
#ifdef DEBUG
    NSLog(@"SetUserDefaultsPrivate: %@, localUserDefaults: %@",[NSNumber numberWithBool:_usePrivateUserDefaults], localUserDefaults);
#endif
}


+ (BOOL)userDefaultsPrivate
{
    return _usePrivateUserDefaults;
}


+ (void)setSecret:(NSString *)secret
{
	if (_secretData == nil) {
		_secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
	} else {
		NSAssert(NO, @"The secret has already been set");
	}
}

+ (void)setDeviceIdentifier:(NSString *)deviceIdentifier
{
	if (_deviceIdentifierData == nil) {
		_deviceIdentifierData = [deviceIdentifier dataUsingEncoding:NSUTF8StringEncoding];
	} else {
		NSAssert(NO, @"The device identifier has already been set");
	}
}


- (NSDictionary *)sebDefaultSettings
{
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_allowBrowsingBackForward",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_allowDownUploads",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_allowFlashFullscreen",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_allowPreferencesWindow",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_allowQuit",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_allowSwitchToApplications",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_allowUserSwitching",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_allowVirtualMachine",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_blockPopUpWindows",
                                 [NSNumber numberWithInt:browserViewModeWindow],
                                 @"org_safeexambrowser_SEB_browserViewMode",
                                 [NSNumber numberWithInt:manuallyWithFileRequester],
                                 @"org_safeexambrowser_SEB_chooseFileToUploadPolicy",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_copyBrowserExamKeyToClipboardWhenQuitting",
                                 [NSNumber numberWithInt:0],
                                 @"org_safeexambrowser_SEB_cryptoIdentity",
                                 //@"~/Downloads",
                                 [NSHomeDirectory() stringByAppendingPathComponent: @"Downloads"],
                                 @"org_safeexambrowser_SEB_downloadDirectoryOSX",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_downloadPDFFiles",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_elevateWindowLevels",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_enableBrowserWindowToolbar",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableJava",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_enableJavaScript",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableLogging",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_enablePlugIns",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_enablePreferencesWindow",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_enableSebBrowser",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableUrlContentFilter",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableUrlFilter",
                                 [NSData data],
                                 @"org_safeexambrowser_SEB_examKeySalt",
                                 @"",
                                 @"org_safeexambrowser_SEB_hashedAdminPassword",
                                 @"",
                                 @"org_safeexambrowser_SEB_hashedQuitPassword",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_hideBrowserWindowToolbar",
                                 NSTemporaryDirectory(),
                                 @"org_safeexambrowser_SEB_logDirectoryOSX",
                                 @"100%",
                                 @"org_safeexambrowser_SEB_mainBrowserWindowHeight",
                                 [NSNumber numberWithInt:1],
                                 @"org_safeexambrowser_SEB_mainBrowserWindowPositioning",
                                 @"100%",
                                 @"org_safeexambrowser_SEB_mainBrowserWindowWidth",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_monitorProcesses",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkBlockForeign",
                                 @"100%",
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkHeight",
                                 [NSNumber numberWithInt:openInNewWindow],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy",
                                 [NSNumber numberWithInt:2],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkPositioning",
                                 @"800",
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkWidth",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByScriptBlockForeign",
                                 [NSNumber numberWithInt:openInNewWindow],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_openDownloads",
                                 [NSString stringWithFormat:@"SEB_OSX_%@_%@",
                                  [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"],
                                  [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"]],
                                 @"org_safeexambrowser_SEB_originatorVersion",
                                 [NSArray array],
                                 @"org_safeexambrowser_SEB_permittedProcesses",
                                 [NSArray array],
                                 @"org_safeexambrowser_SEB_prohibitedProcesses",
                                 @"",
                                 @"org_safeexambrowser_SEB_quitURL",
                                 [NSNumber numberWithInt:sebConfigPurposeStartingExam],
                                 @"org_safeexambrowser_SEB_sebConfigPurpose",
                                 [NSNumber numberWithInt:sebModeStartURL],
                                 @"org_safeexambrowser_SEB_sebMode",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_sebServerFallback",
                                 @"",
                                 @"org_safeexambrowser_SEB_sebServerURL",
                                 [NSNumber numberWithInt:forceSebService],
                                 @"org_safeexambrowser_SEB_sebServicePolicy",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_sendBrowserExamKey",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_showMenuBar",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_showTaskBar",
                                 @"",
                                 @"org_safeexambrowser_SEB_settingsPassword",
                                 @"http://www.safeexambrowser.org/macosx",
                                 @"org_safeexambrowser_SEB_startURL",
                                 [NSArray array],
                                 @"org_safeexambrowser_SEB_urlFilterRules",
                                 nil];
    return appDefaults;
}


- (NSDictionary *)dictionaryRepresentationSEB
{
    // Copy preferences to a dictionary
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *prefsDict = [self getSEBUserDefaultsDomains];
    
    // Filter dictionary so only org_safeexambrowser_SEB_ keys are included
    NSSet *filteredPrefsSet = [prefsDict keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop)
                               {
                                   if ([key hasPrefix:@"org_safeexambrowser_SEB_"] &&
                                       ![key isEqualToString:@"org_safeexambrowser_SEB_enablePreferencesWindow"] &&
                                       ![key isEqualToString:@"org_safeexambrowser_SEB_elevateWindowLevels"])
                                       return YES;
                                   
                                   else return NO;
                               }];
    NSMutableDictionary *filteredPrefsDict = [NSMutableDictionary dictionaryWithCapacity:[filteredPrefsSet count]];
    
    // Remove prefix "org_safeexambrowser_SEB_" from keys
    for (NSString *key in filteredPrefsSet) {
        if ([key isEqualToString:@"org_safeexambrowser_SEB_downloadDirectoryOSX"]) {
            NSString *downloadPath = [preferences secureStringForKey:key];
            // generate a path with a tilde (~) substituted for the full path to the current user’s home directory
            // so that the path is portable to SEB clients with other user's home directories
            downloadPath = [downloadPath stringByAbbreviatingWithTildeInPath];
            [filteredPrefsDict setObject:downloadPath forKey:[key substringFromIndex:24]];
        } else {
            id value = [preferences secureObjectForKey:key];
            if (value) [filteredPrefsDict setObject:value forKey:[key substringFromIndex:24]];
        }
    }
    return filteredPrefsDict;
}


- (void)resetSEBUserDefaults
{
    // Copy preferences to a dictionary
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *prefsDict = [self getSEBUserDefaultsDomains];

    // Remove all values for keys with prefix "org_safeexambrowser_SEB_"
    for (NSString *key in prefsDict) {
        if ([key hasPrefix:@"org_safeexambrowser_SEB_"]) {
            [preferences removeObjectForKey:key];
        }
    }
}


- (NSDictionary *)getSEBUserDefaultsDomains
{
    // Copy preferences to a dictionary
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences synchronize];
    NSDictionary *prefsDict;
    
    // Get CFBundleIdentifier of the application
    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleId = [bundleInfo objectForKey: @"CFBundleIdentifier"];
    
    // Include UserDefaults from NSRegistrationDomain and application domain
    NSUserDefaults *appUserDefaults = [[NSUserDefaults alloc] init];
    [appUserDefaults addSuiteNamed:@"NSRegistrationDomain"];
    [appUserDefaults addSuiteNamed: bundleId];
    prefsDict = [appUserDefaults dictionaryRepresentation];
    return prefsDict;
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
	[self setSecureObject:[NSNumber numberWithInt:value] forKey:key];
}


- (void)setSecureObject:(id)value forKey:(NSString *)key
{
    if (_usePrivateUserDefaults) {
        if (value == nil) value = [NSNull null];
        [localUserDefaults setValue:value forKey:key];
        //NSString *keypath = [NSString stringWithFormat:@"values.%@", key];
        //[[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController] setValue:value forKeyPath:keypath];
#ifdef DEBUG
        NSLog(@"[localUserDefaults setObject:%@ forKey:%@]", [localUserDefaults valueForKey:key], key);
#endif
    } else {
        if (value == nil || key == nil) {
            // Use non-secure method
            [self setObject:value forKey:key];
            
        } else if ([self _isValidPropertyListObject:value]) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
            NSError *error;
            NSData *encryptedData = [RNEncryptor encryptData:data
                                                withSettings:kRNCryptorAES256Settings
                                                    password:userDefaultsMasala
                                                       error:&error];
            if (error) {
                [[SEBCryptor sharedSEBCryptor] presentPreferencesCorruptedError];
                return;
            }
            
            [self setObject:encryptedData forKey:key];
#ifdef DEBUG
            NSLog(@"[self setObject:(encrypted %@) forKey:%@]", value, key);
#endif
        }
        //[[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults];
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
- (NSData *)secureDataForObject:(id)value
{
	if ([self _isValidPropertyListObject:value]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
        NSError *error;
        NSData *encryptedData = [RNEncryptor encryptData:data
                                            withSettings:kRNCryptorAES256Settings
                                                password:userDefaultsMasala
                                                   error:&error];
        if (error) {
            [[SEBCryptor sharedSEBCryptor] presentPreferencesCorruptedError];
            return nil;
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
		NSLog(format, object, [object class]);
		return NO;
	}
}


- (id)_objectForKey:(NSString *)key
{
    if (_usePrivateUserDefaults) {
#ifdef DEBUG
        NSLog(@"%@ = [localUserDefaults objectForKey:%@]", [localUserDefaults valueForKey:key], key);
#endif
        return [localUserDefaults valueForKey:key];
        //NSString *keypath = [NSString stringWithFormat:@"values.%@", key];
        //return [[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController] valueForKeyPath:keypath];
    } else {
        NSData *encrypted = [self objectForKey:key];
		
        if (encrypted == nil) {
            // Value = nil -> invalid
            return nil;
        }
        NSError *error;
        NSData *decrypted = [RNDecryptor decryptData:encrypted
                                            withPassword:userDefaultsMasala
                                               error:&error];
        if (error) {
            [[SEBCryptor sharedSEBCryptor] presentPreferencesCorruptedError];
            return nil;
        }
        id value = [NSKeyedUnarchiver unarchiveObjectWithData:decrypted];
#ifdef DEBUG
        NSLog(@"%@ (decrypted) = [self objectForKey:%@]", value, key);
#endif
        return value;
    }
}


- (NSString *)_hashObject:(id)object
{
	if (_secretData == nil) {
		// Use if statement in case asserts are disabled
		NSAssert(NO, @"Provide a secret before using any secure writing or reading methods!");
		return nil;
	}
    
    // Copy object to make sure it is immutable (thanks Stephen)
    object = [object copy];
	
	// Archive & hash
	NSMutableData *archivedData = [[NSKeyedArchiver archivedDataWithRootObject:object] mutableCopy];
	[archivedData appendData:_secretData];
	if (_deviceIdentifierData != nil) {
		[archivedData appendData:_deviceIdentifierData];
	}
	NSString *hash = [self _hashData:archivedData];
	
	return hash;
}


- (NSString *)_hashData:(NSData *)data
{
	const char *cStr = [data bytes];
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5(cStr, [data length], digest);
	
	static NSString *format = @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x";
	NSString *hash = [NSString stringWithFormat:format, digest[0], digest[1], 
														digest[2], digest[3],
														digest[4], digest[5],
														digest[6], digest[7],
														digest[8], digest[9],
														digest[10], digest[11],
														digest[12], digest[13],
														digest[14], digest[15]];
	return hash;
}

@end
