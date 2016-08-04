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
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


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


- (NSDictionary *)sebDefaultSettings
{
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 [NSArray array],
//                                 @"org_safeexambrowser_SEB_additionalResources",
                                 @NO,
                                 @"org_safeexambrowser_SEB_allowBrowsingBackForward",
                                 @NO,
                                 @"org_safeexambrowser_SEB_allowDictionaryLookup",
                                 @NO,
                                 @"org_safeexambrowser_SEB_allowDownUploads",
                                 @NO,
                                 @"org_safeexambrowser_SEB_allowFlashFullscreen",
                                 @NO,
                                 @"org_safeexambrowser_SEB_allowPDFPlugIn",
                                 @YES,
                                 @"org_safeexambrowser_SEB_allowPreferencesWindow",
                                 @YES,
                                 @"org_safeexambrowser_SEB_allowQuit",
                                 @NO,
                                 @"org_safeexambrowser_SEB_allowSpellCheck",
                                 @NO,
                                 @"org_safeexambrowser_SEB_allowSwitchToApplications",
                                 @YES,
                                 @"org_safeexambrowser_SEB_allowUserSwitching",
                                 @NO,
                                 @"org_safeexambrowser_SEB_allowVirtualMachine",
                                 @NO,
                                 @"org_safeexambrowser_SEB_allowWLAN",
                                 @NO,
                                 @"org_safeexambrowser_SEB_blockPopUpWindows",
                                 [NSNumber numberWithLong:120000],
                                 @"org_safeexambrowser_SEB_browserMessagingPingTime",
                                 @"ws:\\localhost:8706",
                                 @"org_safeexambrowser_SEB_browserMessagingSocket",
                                 @NO,
                                 @"org_safeexambrowser_SEB_browserScreenKeyboard",
                                 @YES,
                                 @"org_safeexambrowser_SEB_browserURLSalt",
                                 [NSNumber numberWithLong:browserUserAgentModeMacDefault],
                                 @"org_safeexambrowser_SEB_browserUserAgentMac",
                                 @"",
                                 @"org_safeexambrowser_SEB_browserUserAgentMacCustom",
                                 [NSNumber numberWithLong:browserUserAgentModeWinDesktopDefault],
                                 @"org_safeexambrowser_SEB_browserUserAgentWinDesktopMode",
                                 @"",
                                 @"org_safeexambrowser_SEB_browserUserAgentWinDesktopModeCustom",
                                 [NSNumber numberWithLong:browserUserAgentModeWinTouchDefault],
                                 @"org_safeexambrowser_SEB_browserUserAgentWinTouchMode",
                                 @"",
                                 @"org_safeexambrowser_SEB_browserUserAgentWinTouchModeCustom",
                                 [NSNumber numberWithLong:browserViewModeWindow],
                                 @"org_safeexambrowser_SEB_browserViewMode",
                                 [NSNumber numberWithLong:manuallyWithFileRequester],
                                 @"org_safeexambrowser_SEB_chooseFileToUploadPolicy",
                                 @YES,
                                 @"org_safeexambrowser_SEB_createNewDesktop",
//                                 [NSData data], // public key hash of cryptoIdentity selected/used for encryption 
//                                 @"org_safeexambrowser_SEB_cryptoIdentity",
                                 //@"~/Downloads",
                                 @YES,
                                 @"org_safeexambrowser_SEB_downloadAndOpenSebConfig",
                                 [NSHomeDirectory() stringByAppendingPathComponent: @"Downloads"],
                                 @"org_safeexambrowser_SEB_downloadDirectoryOSX",
                                 @"Desktop",
                                 @"org_safeexambrowser_SEB_downloadDirectoryWin",
                                 @NO,
                                 @"org_safeexambrowser_SEB_downloadPDFFiles",
                                 [NSArray array],
                                 @"org_safeexambrowser_SEB_embeddedCertificates",
                                 @YES,
                                 @"org_safeexambrowser_SEB_enableAppSwitcherCheck",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableBrowserWindowToolbar",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableJava",
                                 @YES,
                                 @"org_safeexambrowser_SEB_enableJavaScript",
                                 @YES,
                                 @"org_safeexambrowser_SEB_enableLogging",
                                 @YES,
                                 @"org_safeexambrowser_SEB_enablePlugIns",
                                 @YES,
                                 @"org_safeexambrowser_SEB_enableSebBrowser",
                                 @false,
                                 @"org_safeexambrowser_SEB_enableTouchExit",
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
                                 @NO,
                                 @"org_safeexambrowser_SEB_hideBrowserWindowToolbar",
                                 @YES,
                                 @"org_safeexambrowser_SEB_hookKeys",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableEsc",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableCtrlEsc",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableAltEsc",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableAltMouseWheel",
                                 @YES,
                                 @"org_safeexambrowser_SEB_enableAltTab",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableAltF4",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enablePrintScreen",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableRightMouse",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableStartMenu",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableF1",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableF2",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableF3",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableF4",
                                 @YES,
                                 @"org_safeexambrowser_SEB_enableF5",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableF6",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableF7",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableF8",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableF9",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableF10",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableF11",
                                 @NO,
                                 @"org_safeexambrowser_SEB_enableF12",
                                 @YES,
                                 @"org_safeexambrowser_SEB_enableZoomPage",
                                 @YES,
                                 @"org_safeexambrowser_SEB_enableZoomText",
                                 @YES,
                                 @"org_safeexambrowser_SEB_forceAppFolderInstall",
                                 @YES,
                                 @"org_safeexambrowser_SEB_ignoreExitKeys",
                                 @NO,
                                 @"org_safeexambrowser_SEB_ignoreQuitPassword",
                                 @NO,
                                 @"org_safeexambrowser_SEB_insideSebEnableChangeAPassword",
                                 @NO,
                                 @"org_safeexambrowser_SEB_insideSebEnableEaseOfAccess",
                                 @NO,
                                 @"org_safeexambrowser_SEB_insideSebEnableLockThisComputer",
                                 @NO,
                                 @"org_safeexambrowser_SEB_insideSebEnableLogOff",
                                 @NO,
                                 @"org_safeexambrowser_SEB_insideSebEnableShutDown",
                                 @NO,
                                 @"org_safeexambrowser_SEB_insideSebEnableStartTaskManager",
                                 @NO,
                                 @"org_safeexambrowser_SEB_insideSebEnableSwitchUser",
                                 @NO,
                                 @"org_safeexambrowser_SEB_insideSebEnableVmWareClientShade",
                                 @NO,
                                 @"org_safeexambrowser_SEB_killExplorerShell",
                                 @"",
                                 @"org_safeexambrowser_SEB_logDirectoryOSX",
                                 @"",
                                 @"org_safeexambrowser_SEB_logDirectoryWin",
                                 [NSNumber numberWithLong:SEBLogLevelDebug],
                                 @"org_safeexambrowser_SEB_logLevel",
                                 @"100%",
                                 @"org_safeexambrowser_SEB_mainBrowserWindowHeight",
                                 [NSNumber numberWithLong:browserWindowPositioningCenter],
                                 @"org_safeexambrowser_SEB_mainBrowserWindowPositioning",
                                 @"100%",
                                 @"org_safeexambrowser_SEB_mainBrowserWindowWidth",
                                 @YES,
                                 @"org_safeexambrowser_SEB_monitorProcesses",
                                 @NO,
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkBlockForeign",
                                 @"100%",
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkHeight",
                                 [NSNumber numberWithLong:openInNewWindow],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy",
                                 [NSNumber numberWithLong:browserWindowPositioningRight],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkPositioning",
                                 @"1000",
                                 @"org_safeexambrowser_SEB_newBrowserWindowByLinkWidth",
                                 @NO,
                                 @"org_safeexambrowser_SEB_newBrowserWindowByScriptBlockForeign",
                                 [NSNumber numberWithLong:openInNewWindow],
                                 @"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy",
                                 @NO,
                                 @"org_safeexambrowser_SEB_openDownloads",
                                 [NSNumber numberWithLong:oskBehaviorAutoShow],
                                 @"org_safeexambrowser_SEB_oskBehavior",
                                 @[
                                   @{
                                       @"active" : @YES,
                                       @"allowUserToChooseApp" : @NO,
                                       @"allowedExecutables" : @"",
                                       @"arguments" : @[],
                                       @"autostart" : @YES,
                                       @"description" : @"",
                                       @"executable" : @"xulrunner.exe",
                                       @"iconInTaskbar" : @YES,
                                       @"identifier" : @"XULRunner",
                                       @"os" : @1,
                                       @"path" : @"../xulrunner/",
                                       @"runInBackground" : @NO,
                                       @"strongKill" : @YES,
                                       @"title" : @"SEB",
                                       @"windowHandlingProcess" : @""
                                       }
                                   ],
                                 @"org_safeexambrowser_SEB_permittedProcesses",
                                 @NO,
                                 @"org_safeexambrowser_SEB_pinEmbeddedCertificates",
                                 [NSArray array],
                                 @"org_safeexambrowser_SEB_prohibitedProcesses",
                                 [NSMutableDictionary dictionaryWithDictionary:@{
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
                                   }],
                                 @"org_safeexambrowser_SEB_proxies",
                                 [NSNumber numberWithLong:useSystemProxySettings],
                                 @"org_safeexambrowser_SEB_proxySettingsPolicy",
                                 @"",
                                 @"org_safeexambrowser_SEB_quitURL",
                                 @YES,
                                 @"org_safeexambrowser_SEB_removeBrowserProfile",
                                 @YES,
                                 @"org_safeexambrowser_SEB_removeLocalStorage",
                                 @YES,
                                 @"org_safeexambrowser_SEB_restartExamPasswordProtected",
                                 @"",
                                 @"org_safeexambrowser_SEB_restartExamText",
                                 @"",
                                 @"org_safeexambrowser_SEB_restartExamURL",
                                 @NO,
                                 @"org_safeexambrowser_SEB_restartExamUseStartURL",
                                 [NSNumber numberWithLong:sebConfigPurposeConfiguringClient],
                                 @"org_safeexambrowser_SEB_sebConfigPurpose",
                                 [NSNumber numberWithLong:sebModeStartURL],
                                 @"org_safeexambrowser_SEB_sebMode",
                                 @NO,
                                 @"org_safeexambrowser_SEB_sebServerFallback",
                                 @"",
                                 @"org_safeexambrowser_SEB_sebServerURL",
                                 [NSNumber numberWithLong:forceSebService],
                                 @"org_safeexambrowser_SEB_sebServicePolicy",
                                 @NO,
                                 @"org_safeexambrowser_SEB_sendBrowserExamKey",
                                 @NO,
                                 @"org_safeexambrowser_SEB_showInputLanguage",
                                 @YES,
                                 @"org_safeexambrowser_SEB_showMenuBar",
                                 @YES,
                                 @"org_safeexambrowser_SEB_showReloadButton",
                                 @NO,
                                 @"org_safeexambrowser_SEB_showReloadWarning",
                                 @YES,
                                 @"org_safeexambrowser_SEB_showTaskBar",
                                 @YES,
                                 @"org_safeexambrowser_SEB_showTime",
                                 @"http://www.safeexambrowser.org/start",
                                 @"org_safeexambrowser_SEB_startURL",
                                 [NSNumber numberWithLong:40],
                                 @"org_safeexambrowser_SEB_taskBarHeight",
                                 @NO,
                                 @"org_safeexambrowser_SEB_touchOptimized",
                                 @NO,
                                 @"org_safeexambrowser_SEB_URLFilterEnable",
                                 @NO,
                                 @"org_safeexambrowser_SEB_URLFilterEnableContentFilter",
                                 [NSArray array],
                                 @"org_safeexambrowser_SEB_URLFilterIgnoreList",
                                 [NSNumber numberWithLong:URLFilterMessageText],
                                 @"org_safeexambrowser_SEB_URLFilterMessage",
                                 @NO,
                                 @"org_safeexambrowser_SEB_urlFilterRegex",
                                 @NO,
                                 @"org_safeexambrowser_SEB_urlFilterTrustedContent",
                                 @"",
                                 @"org_safeexambrowser_SEB_blacklistURLFilter",
                                 @"",
                                 @"org_safeexambrowser_SEB_whitelistURLFilter",
                                 [NSArray array],
                                 @"org_safeexambrowser_SEB_URLFilterRules",
                                 [NSNumber numberWithLong:SEBZoomModePage],
                                 @"org_safeexambrowser_SEB_zoomMode",
                                 [NSNumber numberWithLong:0],
                                 @"org_safeexambrowser_browserUserAgentEnvironment",
                                 @NO,
                                 @"org_safeexambrowser_copyBrowserExamKeyToClipboardWhenQuitting",
                                 @YES,
                                 @"org_safeexambrowser_elevateWindowLevels",
                                 [NSString stringWithFormat:@"SEB_OSX_%@_%@",
                                  [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"],
                                  [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"]],
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
        
        // NSDictionaries need to be converted to NSMutableDictionary, otherwise bindings
        // will cause a crash when trying to modify the dictionary
        if ([value isKindOfClass:[NSDictionary class]]) {
            value = [NSMutableDictionary dictionaryWithDictionary:value];
        }
        NSString *keyWithPrefix = [self prefixKey:key];
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
        keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_%@", key];
    } else {
        keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_SEB_%@", key];
    }
    return keyWithPrefix;
}


// Remove all SEB key/values from local client UserDefaults
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
    // Update Exam Settings Key
    [_cachedUserDefaults removeAllObjects];
    [[SEBCryptor sharedSEBCryptor] updateExamSettingsKey:_cachedUserDefaults];

//    prefsDict = [self getSEBUserDefaultsDomains];
//    DDLogVerbose(@"SEB UserDefaults domains after resetSEBUserDefaults: %@", prefsDict);
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
            //if (valueClass && defaultValueClass && valueClass != defaultValueClass) {
            //if (!(object_getClass([value class]) == object_getClass([defaultValue class]))) {
            //if (defaultValue && !([value class] == [defaultValue class])) {
            // Class of newly loaded value is different than the one from the default value
            // If yes, then cancel reading .seb file
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Reading New Settings Failed!",nil)];
            [newAlert setInformativeText:NSLocalizedString(@"These settings cannot be used. They may have been created by an incompatible version of SEB or are corrupted.", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            [newAlert runModal];

            DDLogError(@"%s Value for key %@ is NULL or doesn't have the correct class!", __FUNCTION__, key);
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
            if (![key hasPrefix:@"org_safeexambrowser_"]) {
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
                if (error || !encryptedData) {

                    DDLogError(@"PREFERENCES CORRUPTED ERROR in [self setObject:(encrypted %@) forKey:%@]", value, key);

                    [[SEBCryptor sharedSEBCryptor] presentPreferencesCorruptedError];
                    return;
                } else {
                    [self setObject:encryptedData forKey:key];

                    DDLogVerbose(@"[self setObject:(encrypted %@) forKey:%@]", value, key);
                }
            }
            
        }
        //[[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults];
    }
    if ([key isEqualToString:@"org_safeexambrowser_SEB_logLevel"]) {
        _logLevel = value;
        [[MyGlobals sharedMyGlobals] setDDLogLevel:_logLevel.intValue];
    } else if ([key isEqualToString:@"org_safeexambrowser_SEB_enableLogging"]) {
        if ([value boolValue] == NO) {
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
        if (![key hasPrefix:@"org_safeexambrowser_"]) {
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
