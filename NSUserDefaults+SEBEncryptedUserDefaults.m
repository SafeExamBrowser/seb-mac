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
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "SEBCryptor.h"
#import "SEBKeychainManager.h"
#import "SEBConfigFileManager.h"

@interface NSUserDefaults (SEBEncryptedUserDefaultsPrivate)

- (BOOL)_isValidPropertyListObject:(id)object;
- (id)_objectForKey:(NSString *)key;

@end


@implementation NSUserDefaults (SEBEncryptedUserDefaults)


static NSMutableDictionary *localUserDefaults;
static NSMutableDictionary *_cachedUserDefaults;
static BOOL _usePrivateUserDefaults = NO;
static NSNumber *_logLevel;

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
        [preferences synchronize];

        // Clear the cached UserDefaults dictionary
        _cachedUserDefaults = [NSMutableDictionary new];
    }

    DDLogDebug(@"SetUserDefaultsPrivate: %@, localUserDefaults: %@",[NSNumber numberWithBool:_usePrivateUserDefaults], localUserDefaults);

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


- (NSDictionary *)sebDefaultSettings
{
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 [NSArray array],
//                                 @"org_safeexambrowser_SEB_additionalResources",
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
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_createNewDesktop",
//                                 [NSData data], // public key hash of cryptoIdentity selected/used for encryption 
//                                 @"org_safeexambrowser_SEB_cryptoIdentity",
                                 //@"~/Downloads",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_enableApplicationFolderCheck",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_enableAppSwitcherCheck",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_SEB_downloadAndOpenSebConfig",
                                 [NSHomeDirectory() stringByAppendingPathComponent: @"Downloads"],
                                 @"org_safeexambrowser_SEB_downloadDirectoryOSX",
                                 @"Desktop",
                                 @"org_safeexambrowser_SEB_downloadDirectoryWin",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_SEB_downloadPDFFiles",
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
                                 [NSNumber numberWithBool:YES],
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
                                 @"",
                                 @"org_safeexambrowser_SEB_logDirectoryOSX",
                                 @"",
                                 @"org_safeexambrowser_SEB_logDirectoryWin",
                                 [NSNumber numberWithLong:SEBLogLevelWarning],
                                 @"org_safeexambrowser_SEB_logLevel",
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
                                 @[
                                   @{
                                       @"active" : @YES,
                                       @"allowUserToChooseApp" : @NO,
                                       @"allowedExecutables" : @"",
                                       @"arguments" : @[],
                                       @"autohide" : @NO,
                                       @"autostart" : @YES,
                                       @"description" : @"",
                                       @"executable" : @"xulrunner.exe",
                                       @"identifier" : @"XULRunner",
                                       @"os" : @1,
                                       @"path" : @"../xulrunner/",
                                       @"strongKill" : @YES,
                                       @"title" : @"SEB",
                                       }
                                   ],
                                 @"org_safeexambrowser_SEB_permittedProcesses",
                                 [NSArray array],
                                 @"org_safeexambrowser_SEB_prohibitedProcesses",
                                 @{
                                   @"AutoConfigurationEnabled" : @NO,
                                   @"AutoConfigurationJavaScript" : @"",
                                   @"AutoConfigurationURL" : @"",
                                   @"AutoDiscoveryEnabled" : @NO,
                                   @"ExceptionsList" : @[],
                                   @"ExcludeSimpleHostnames" : @NO,
                                   @"FTPEnable" : @NO,
                                   @"FTPPassive" : @YES,
                                   @"FTPPassword" : @"",
                                   @"FTPPort" : @21,
                                   @"FTPProxy" : @"",
                                   @"FTPRequiresPassword" : @NO,
                                   @"FTPUsername" : @"",
                                   @"HTTPEnable" : @NO,
                                   @"HTTPPassword" : @"",
                                   @"HTTPPort" : @80,
                                   @"HTTPProxy" : @"",
                                   @"HTTPRequiresPassword" : @NO,
                                   @"HTTPSEnable" : @NO,
                                   @"HTTPSPassword" : @"",
                                   @"HTTPSPort" : @443,
                                   @"HTTPSProxy" : @"",
                                   @"HTTPSRequiresPassword" : @NO,
                                   @"HTTPSUsername" : @"",
                                   @"HTTPUsername" : @"",
                                   @"RTSPEnable" : @NO,
                                   @"RTSPPassword" : @"",
                                   @"RTSPPort" : @554,
                                   @"RTSPProxy" : @"",
                                   @"RTSPRequiresPassword" : @NO,
                                   @"RTSPUsername" : @"",
                                   @"SOCKSEnable" : @NO,
                                   @"SOCKSPassword" : @"",
                                   @"SOCKSPort" : @1080,
                                   @"SOCKSProxy" : @"",
                                   @"SOCKSRequiresPassword" : @NO,
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
//                                 [NSNumber numberWithBool:NO],
//                                 @"org_safeexambrowser_SEB_sebServerFallback",
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
//                                 [NSArray array],
//                                 @"org_safeexambrowser_SEB_URLFilterRules",
                                 [NSNumber numberWithBool:NO],
                                 @"org_safeexambrowser_copyBrowserExamKeyToClipboardWhenQuitting",
                                 [NSNumber numberWithBool:YES],
                                 @"org_safeexambrowser_elevateWindowLevels",
                                 @"",
                                 @"org_safeexambrowser_originatorVersion",

                                 nil];
    return appDefaults;
}


// Set default preferences for the case there are no user prefs yet
// Returns YES if SEB was started first time on this system (no SEB settings found in UserDefaults)
- (BOOL)setSEBDefaults
{
    DDLogInfo(@"Setting local client settings (NSUserDefaults)");

    BOOL firstStart = NO;
    _cachedUserDefaults = [NSMutableDictionary new];
    
    SEBCryptor *sharedSEBCryptor = [SEBCryptor sharedSEBCryptor];
    NSMutableDictionary *currentUserDefaults;

    // Check if there are valid SEB UserDefaults already
    if ([self haveSEBUserDefaults]) {
        // Read decrypted existing SEB UserDefaults
        NSDictionary *sebUserDefaults = [self dictionaryRepresentationSEB];
        // Check if something went wrong reading settings
        if (sebUserDefaults == nil) {
            // Set the flag to indicate user later that settings have been reset
            [[MyGlobals sharedMyGlobals] setPreferencesReset:YES];
            // The currentUserDefaults should be an empty dictionary then
            currentUserDefaults = [NSMutableDictionary new];
        } else {
            currentUserDefaults = [[NSMutableDictionary alloc] initWithDictionary:sebUserDefaults copyItems:YES];
            // Generate Exam Settings Key
            NSData *examSettingsKey = [sharedSEBCryptor checksumForLocalPrefDictionary:currentUserDefaults];
            // If exam settings are corrupted
            if ([sharedSEBCryptor checkExamSettings:examSettingsKey] == false) {
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


- (BOOL)haveSEBUserDefaults
{
    return [[SEBCryptor sharedSEBCryptor] hasDefaultsKey];
}


- (NSDictionary *)dictionaryRepresentationSEB
{
    // Filter UserDefaults so only org_safeexambrowser_SEB_ keys are included in the set
    NSSet *filteredPrefsSet = [self sebKeysSet];
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
            id value = [self secureObjectForKey:key];
        if (value) {
            [filteredPrefsDict setObject:value forKey:[key substringFromIndex:24]];
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
                                   if ([key hasPrefix:@"org_safeexambrowser_SEB_"])
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
        
        // If imported settings are being saved into local client NSUserDefaults
        // import embedded certificates (and identities) into the keychain
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

                            DDLogInfo(@"Importing SSL certificate <%@> into Keychain %@", [certificate objectForKey:@"name"], success ? @"succedded" : @"failed");
                        }
                        break;
                        
                    case certificateTypeIdentity:
                        if (certificateData) {
                            BOOL success = [keychainManager importIdentityFromData:certificateData];

                            DDLogInfo(@"Importing identity <%@> into Keychain %@", [certificate objectForKey:@"name"], success ? @"succedded" : @"failed");
                        }
                        break;
                }
            }
            
        } else {
            // other values can be saved into shared NSUserDefaults
            [self setSecureObject:value forKey:keyWithPrefix];
        }
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
        keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_%@", key];
    } else {
        keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_SEB_%@", key];
    }
    return keyWithPrefix;
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
//    prefsDict = [self getSEBUserDefaultsDomains];
//    DDLogDebug(@"SEB UserDefaults domains after resetSEBUserDefaults: %@", prefsDict);
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


// Check if a some value is from a wrong class (another than the value from default settings)
- (BOOL)checkClassOfSettings:(NSDictionary *)sebPreferencesDict
{
    // get default settings
    NSDictionary *defaultSettings = [self sebDefaultSettings];
    
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
    // Set value for key (without prefix) in cachedUserDefaults
    // as long as it is a key with an "org_safeexambrowser_SEB_" prefix
    if ([key hasPrefix:@"org_safeexambrowser_SEB_"]) {
        [_cachedUserDefaults setValue:value forKey:[key substringFromIndex:24]];
        // Update Exam Settings Key
        [[SEBCryptor sharedSEBCryptor] updateExamSettingsKey:_cachedUserDefaults];
    }

    if (_usePrivateUserDefaults) {
        if (value == nil) value = [NSNull null];
        [localUserDefaults setValue:value forKey:key];
        //NSString *keypath = [NSString stringWithFormat:@"values.%@", key];
        //[[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController] setValue:value forKeyPath:keypath];

        DDLogDebug(@"[localUserDefaults setObject:%@ forKey:%@]", [localUserDefaults valueForKey:key], key);

    } else {
        if (value == nil || key == nil) {
            // Use non-secure method
            [self setObject:value forKey:key];
            
        } else if ([self _isValidPropertyListObject:value]) {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
            NSError *error;
            NSData *encryptedData;
            
            // Treat keys without SEB prefix separately
            if (![key hasPrefix:@"org_safeexambrowser_"]) {
                encryptedData = [RNEncryptor encryptData:data
                                                    withSettings:kRNCryptorAES256Settings
                                                        password:userDefaultsMasala
                                                           error:&error];
                [self setObject:encryptedData forKey:key];
            } else {
                encryptedData = [[SEBCryptor sharedSEBCryptor] encryptData:data forKey:key error:&error];
                if (error) {

                    DDLogError(@"PREFERENCES CORRUPTED ERROR at [self setObject:(encrypted %@) forKey:%@]", value, key);

                    [[SEBCryptor sharedSEBCryptor] presentPreferencesCorruptedError];
                    return;
                } else {
                    [self setObject:encryptedData forKey:key];

                    DDLogDebug(@"[self setObject:(encrypted %@) forKey:%@]", value, key);
                }
            }
            
        }
        //[[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults];
    }
    if ([key isEqualToString:@"org_safeexambrowser_SEB_logLevel"]) {
        _logLevel = value;
        [[MyGlobals sharedMyGlobals] setDDLogLevel:_logLevel.intValue];
    }
    if ([key isEqualToString:@"org_safeexambrowser_SEB_enableLogging"]) {
        if ((BOOL)value == NO) {
            [[MyGlobals sharedMyGlobals] setDDLogLevel:nil];
        } else {
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
        if (error) {

            DDLogError(@"PREFERENCES CORRUPTED ERROR at [self secureDataForObject:%@ andKey:%@]", value, key);

            [[SEBCryptor sharedSEBCryptor] presentPreferencesCorruptedError];
            return nil;
        }
        if ([key isEqualToString:@"org_safeexambrowser_SEB_logLevel"]) {
            _logLevel = value;
            [[MyGlobals sharedMyGlobals] setDDLogLevel:_logLevel.intValue];
        }
        if ([key isEqualToString:@"org_safeexambrowser_SEB_enableLogging"]) {
            if ((BOOL)value == NO) {
                [[MyGlobals sharedMyGlobals] setDDLogLevel:nil];
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
		NSLog(format, object, [object class]);
		return NO;
	}
}


- (id)_objectForKey:(NSString *)key
{
    if (_usePrivateUserDefaults) {

        DDLogDebug(@"[localUserDefaults objectForKey:%@] = %@", key, [localUserDefaults valueForKey:key]);

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
        NSData *decrypted;
        
        // Treat keys without SEB prefix separately
        if (![key hasPrefix:@"org_safeexambrowser_"]) {
            decrypted = [RNDecryptor decryptData:encrypted
                                            withPassword:userDefaultsMasala
                                                   error:&error];
            if (error) {
                return nil;
            }
        } else {
            decrypted = [[SEBCryptor sharedSEBCryptor] decryptData:encrypted forKey:key error:&error];
            if (error) {

                DDLogError(@"PREFERENCES CORRUPTED ERROR at [self _objectForKey:%@], error: %@", key, error);

                [[SEBCryptor sharedSEBCryptor] presentPreferencesCorruptedError];
                return nil;
            }
        }

        id value = [NSKeyedUnarchiver unarchiveObjectWithData:decrypted];

        DDLogDebug(@"[self objectForKey:%@] = %@ (decrypted)", key, value);

        return value;
    }
}


@end
