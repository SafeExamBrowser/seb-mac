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
//  Copyright (c) 2010-2014 Daniel R. Schneider, ETH Zurich,
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
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2014 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
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
                                 [NSNumber numberWithBool:NO],
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
                                 @"org_safeexambrowser_SEB_allowWLAN",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_blockPopUpWindows",
                                 [NSNumber numberWithLong:120000],
                                 @"org_safeexambrowser_SEB_browserMessagingPingTime",
                                 @"ws:\\localhost:8706",
                                 @"org_safeexambrowser_SEB_browserMessagingSocket",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_browserScreenKeyboard",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_browserURLSalt",
                                 [NSNumber numberWithLong:browserViewModeWindow],
                                 @"org_safeexambrowser_SEB_browserViewMode",
                                 [NSNumber numberWithLong:manuallyWithFileRequester],
                                 @"org_safeexambrowser_SEB_chooseFileToUploadPolicy",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_copyBrowserExamKeyToClipboardWhenQuitting",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_createNewDesktop",
//                                 [NSData data], // public key hash of cryptoIdentity selected/used for encryption 
//                                 @"org_safeexambrowser_SEB_cryptoIdentity",
                                 //@"~/Downloads",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_downloadAndOpenSebConfig",
                                 [NSHomeDirectory() stringByAppendingPathComponent: @"Downloads"],
                                 @"org_safeexambrowser_SEB_downloadDirectoryOSX",
                                 @"Desktop",
                                 @"org_safeexambrowser_SEB_downloadDirectoryWin",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_downloadPDFFiles",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_elevateWindowLevels",
                                 [NSArray array],
                                 @"org_safeexambrowser_SEB_embeddedCertificates",
                                 [NSNumber numberWithBool:NO],
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
                                 @"org_safeexambrowser_enablePreferencesWindow",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_enableSebBrowser",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableURLContentFilter",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableURLFilter",
                                 [NSData data],
                                 @"org_safeexambrowser_SEB_examKeySalt",
                                 [NSNumber numberWithLong:2],
                                 @"org_safeexambrowser_SEB_exitKey1",
                                 [NSNumber numberWithLong:10],
                                 @"org_safeexambrowser_SEB_exitKey2",
                                 [NSNumber numberWithLong:5],
                                 @"org_safeexambrowser_SEB_exitKey3",
                                 @"",
                                 @"org_safeexambrowser_SEB_hashedAdminPassword",
                                 @"",
                                 @"org_safeexambrowser_SEB_hashedQuitPassword",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_hideBrowserWindowToolbar",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_hookKeys",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableEsc",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableCtrlEsc",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_enableAltCtrl",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableAltEsc",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableAltMouseWheel",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_enableAltTab",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableAltF4",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enablePrintScreen",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableRightMouse",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableStartMenu",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableF1",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableF2",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableF3",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableF4",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableF5",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableF6",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableF7",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableF8",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableF9",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableF10",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableF11",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_enableF12",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_ignoreExitKeys",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_ignoreQuitPassword",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_insideSebEnableChangeAPassword",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_insideSebEnableEaseOfAccess",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_insideSebEnableLockThisComputer",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_insideSebEnableLogOff",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_insideSebEnableShutDown",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_insideSebEnableStartTaskManager",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_insideSebEnableSwitchUser",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_insideSebEnableVmWareClientShade",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_killExplorerShell",
                                 NSTemporaryDirectory(),
                                 @"org_safeexambrowser_SEB_logDirectoryOSX",
                                 @"My Documents",
                                 @"org_safeexambrowser_SEB_logDirectoryWin",
                                 @"100%",
                                 @"org_safeexambrowser_SEB_mainBrowserWindowHeight",
                                 [NSNumber numberWithLong:browserWindowPositioningCenter],
                                 @"org_safeexambrowser_SEB_mainBrowserWindowPositioning",
                                 @"100%",
                                 @"org_safeexambrowser_SEB_mainBrowserWindowWidth",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_monitorProcesses",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkBlockForeign",
                                 @"100%",
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkHeight",
                                 [NSNumber numberWithLong:openInNewWindow],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy",
                                 [NSNumber numberWithLong:browserWindowPositioningRight],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkPositioning",
                                 @"1000",
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkWidth",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByScriptBlockForeign",
                                 [NSNumber numberWithLong:openInNewWindow],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_openDownloads",
//                                 [NSString stringWithFormat:@"SEB_OSX_%@_%@",
//                                  [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"],
//                                  [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"]],
                                 @"",
                                 @"org_safeexambrowser_originatorVersion",
//                                 [NSArray array],
                                 @[
                                   @{
                                       @"active" : @1,
                                       @"allowUserToChooseApp" : @0,
                                       @"allowedExecutables" : @"",
                                       @"arguments" : @[],
                                       @"autohide" : @1,
                                       @"autostart" : @1,
                                       @"description" : @"",
                                       @"executable" : @"xulrunner.exe",
                                       @"identifier" : @"XULRunner",
                                       @"os" : @1,
                                       @"path" : @"../xulrunner/",
                                       @"strongKill" : @1,
                                       @"title" : @"SEB",
                                       }
                                   ],
                                 @"org_safeexambrowser_SEB_permittedProcesses",
                                 [NSArray array],
                                 @"org_safeexambrowser_SEB_prohibitedProcesses",
//                                 [NSDictionary dictionary],
                                 @{
                                   @"AutoConfigurationEnabled" : @0,
                                   @"AutoConfigurationJavaScript" : @"",
                                   @"AutoConfigurationURL" : @"",
                                   @"AutoDiscoveryEnabled" : @0,
                                   @"ExceptionsList" : @[],
                                   @"ExcludeSimpleHostnames" : @0,
                                   @"FTPEnable" : @0,
                                   @"FTPPassive" : @1,
                                   @"FTPPassword" : @"",
                                   @"FTPPort" : @21,
                                   @"FTPProxy" : @"",
                                   @"FTPRequiresPassword" : @0,
                                   @"FTPUsername" : @"",
                                   @"HTTPEnable" : @0,
                                   @"HTTPPassword" : @"",
                                   @"HTTPPort" : @80,
                                   @"HTTPProxy" : @"",
                                   @"HTTPRequiresPassword" : @0,
                                   @"HTTPSEnable" : @0,
                                   @"HTTPSPassword" : @"",
                                   @"HTTPSPort" : @443,
                                   @"HTTPSProxy" : @"",
                                   @"HTTPSRequiresPassword" : @0,
                                   @"HTTPSUsername" : @"",
                                   @"HTTPUsername" : @"",
                                   @"RTSPEnable" : @0,
                                   @"RTSPPassword" : @"",
                                   @"RTSPPort" : @554,
                                   @"RTSPProxy" : @"",
                                   @"RTSPRequiresPassword" : @0,
                                   @"RTSPUsername" : @"",
                                   @"SOCKSEnable" : @0,
                                   @"SOCKSPassword" : @"",
                                   @"SOCKSPort" : @1080,
                                   @"SOCKSProxy" : @"",
                                   @"SOCKSRequiresPassword" : @0,
                                   @"SOCKSUsername" : @""
                                   },
                                 @"org_safeexambrowser_SEB_proxies",
                                 [NSNumber numberWithLong:useSystemProxySettings],
                                 @"org_safeexambrowser_SEB_proxySettingsPolicy",
                                 @"",
                                 @"org_safeexambrowser_SEB_quitURL",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_removeBrowserProfile",
                                 [NSNumber numberWithLong:sebConfigPurposeStartingExam],
                                 @"org_safeexambrowser_SEB_sebConfigPurpose",
                                 [NSNumber numberWithLong:sebModeStartURL],
                                 @"org_safeexambrowser_SEB_sebMode",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_sebServerFallback",
                                 @"",
                                 @"org_safeexambrowser_SEB_sebServerURL",
                                 [NSNumber numberWithLong:forceSebService],
                                 @"org_safeexambrowser_SEB_sebServicePolicy",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_sendBrowserExamKey",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_showMenuBar",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_showTaskBar",
                                 @"http://www.safeexambrowser.org",
                                 @"org_safeexambrowser_SEB_startURL",
                                 [NSNumber numberWithLong:40],
                                 @"org_safeexambrowser_SEB_taskBarHeight",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_touchOptimized",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_URLFilterEnableContentFilter",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_URLFilterRulesAsRegex",
                                 @"",
                                 @"org_safeexambrowser_SEB_URLFilterBlacklist",
                                 @"",
                                 @"org_safeexambrowser_SEB_URLFilterWhitelist",
                                 [NSArray array],
                                 @"org_safeexambrowser_SEB_URLFilterRules",
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
                                   if ([key hasPrefix:@"org_safeexambrowser_SEB_"])
                                       return YES;
                                   
                                   else return NO;
                               }];
    NSMutableDictionary *filteredPrefsDict = [NSMutableDictionary dictionaryWithCapacity:[filteredPrefsSet count]];
    
    // Remove prefix "org_safeexambrowser_SEB_" from keys
    for (NSString *key in filteredPrefsSet) {
//        if ([key isEqualToString:@"org_safeexambrowser_SEB_downloadDirectoryOSX"]) {
//            NSString *downloadPath = [preferences secureStringForKey:key];
//            // generate a path with a tilde (~) substituted for the full path to the current user’s home directory
//            // so that the path is portable to SEB clients with other user's home directories
//            downloadPath = [downloadPath stringByAbbreviatingWithTildeInPath];
//            [filteredPrefsDict setObject:downloadPath forKey:[key substringFromIndex:24]];
//        } else {
            id value = [preferences secureObjectForKey:key];
            if (value) [filteredPrefsDict setObject:value forKey:[key substringFromIndex:24]];
//        }
    }
    return filteredPrefsDict;
}


// Get dictionary of all SEB settings (also local UI client settings)
- (NSDictionary *)dictionarySEBUserDefaults
{
    // Copy all UserDefaults in SEB's domain to a dictionary
    NSDictionary *prefsDict = [self getSEBUserDefaultsDomains];
    
    // Filter dictionary so only org_safeexambrowser_SEB_ keys are included
    NSSet *filteredPrefsSet = [prefsDict keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop)
                               {
                                   if ([key hasPrefix:@"org_safeexambrowser_"])
                                       return YES;
                                   
                                   else return NO;
                               }];
    NSMutableDictionary *filteredPrefsDict = [NSMutableDictionary dictionaryWithCapacity:[filteredPrefsSet count]];
    return filteredPrefsDict;
}


- (void)resetSEBUserDefaults
{
    // Copy preferences to a dictionary
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *prefsDict = [self getSEBUserDefaultsDomains];

    // Remove all values for keys with prefix "org_safeexambrowser_"
    for (NSString *key in prefsDict) {
        if ([key hasPrefix:@"org_safeexambrowser_"]) {
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
    
//    // Get CFBundleIdentifier of the application
//    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
//    NSString *bundleId = [bundleInfo objectForKey: @"CFBundleIdentifier"];
    
    // Include UserDefaults from NSRegistrationDomain and application domain
    NSUserDefaults *appUserDefaults = [[NSUserDefaults alloc] init];
    [appUserDefaults addSuiteNamed:@"NSRegistrationDomain"];
//    [appUserDefaults addSuiteNamed: bundleId];
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
        NSLog(@"[localUserDefaults objectForKey:%@] = %@", key, [localUserDefaults valueForKey:key]);
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
        NSLog(@"[self objectForKey:%@] = %@ (decrypted)", key, value);
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
