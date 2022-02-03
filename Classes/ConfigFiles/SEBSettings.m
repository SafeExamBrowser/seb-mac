//
//  SEBSettings.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 21.08.17.
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


#import "SEBSettings.h"

@implementation SEBSettings


static SEBSettings *sharedSEBSettings = nil;


+ (SEBSettings *)sharedSEBSettings
{
    @synchronized(self)
    {
        if (sharedSEBSettings == nil)
        {
            sharedSEBSettings = [[self alloc] init];
        }
    }
    
    return sharedSEBSettings;
}


- (NSDictionary *)defaultSettings
{
    if ([NSUserDefaults userDefaultsPrivate]) {
        return [self defaultExamSettings];

    } else {
        return [self defaultClientSettings];
    }
}


- (NSDictionary *)defaultClientSettings
{
    if (!_defaultSettings) {
        _defaultSettings = [self extendDefaultSettings:[self defaultSEBSettings] withSettingsIdentifier:@"defaultSettings"];
        }
    return _defaultSettings;
}


- (NSDictionary *)defaultExamSettings
{
    if (!_defaultExamSettings) {
        _defaultExamSettings = [self extendDefaultSettings:[self defaultClientSettings] withSettingsIdentifier:@"defaultExamSettings"];
        }
    return _defaultExamSettings;
}


- (NSDictionary *)extendDefaultSettings:(NSDictionary *)defaultSettings withSettingsIdentifier:(NSString *)settingsIdentifier
{
    NSMutableDictionary *completeDefaultSettings = [NSMutableDictionary dictionaryWithDictionary:defaultSettings];
        
    NSArray *sebExtensions = [MyGlobals SEBExtensions];
    for (NSString *sebExtensionString in sebExtensions) {
        Class SEBExtensionClass = NSClassFromString(sebExtensionString);
        
        if ([SEBExtensionClass respondsToSelector: NSSelectorFromString(settingsIdentifier)]) {
            SEL selector = NSSelectorFromString(settingsIdentifier);
            IMP imp = [SEBExtensionClass methodForSelector:selector];
            NSDictionary *(*func)(id, SEL) = (void *)imp;
            NSDictionary *extensionSettings = func(SEBExtensionClass, selector);
            
            NSMutableDictionary *defaultExtensionSettings = [NSMutableDictionary dictionaryWithDictionary:extensionSettings];
            
            NSArray *extensionDictionaryKeys = [defaultExtensionSettings allKeys];
            for (NSString *extensionDictKey in extensionDictionaryKeys) {
                // First check if extension settings dictionary contains arrays of subdictionaries with missing default keys
                NSMutableDictionary *extensionSubDict = [[defaultExtensionSettings objectForKey:extensionDictKey] mutableCopy];
                NSArray *extensionSubDictionaryKeys = [extensionSubDict allKeys];
                for (NSString *extensionSubDictKey in extensionSubDictionaryKeys) {
                    id extensionSubElement = [extensionSubDict objectForKey:extensionSubDictKey];
                    if ([extensionSubElement isKindOfClass:[NSArray class]]) {
                        NSMutableArray *extensionSubArray = NSMutableArray.new;
                        for (NSDictionary* extensionSubDict in extensionSubElement) {
                            NSMutableDictionary *completedExtensionSubDict = [[completeDefaultSettings objectForKey:extensionSubDictKey] mutableCopy];
                            [completedExtensionSubDict addEntriesFromDictionary:extensionSubDict];
                            [extensionSubArray addObject:completedExtensionSubDict];
                        }
                        if (extensionSubArray) {
                            [extensionSubDict setObject:extensionSubArray.copy forKey:extensionSubDictKey];
                        }
                    }
                }
                [defaultExtensionSettings setObject:extensionSubDict.copy forKey:extensionDictKey];
            }
            
            NSArray *subDictionaries = [completeDefaultSettings allKeys];
            for (NSString *subDictKey in subDictionaries) {
                NSDictionary *subExtensionDict = [defaultExtensionSettings objectForKey:subDictKey];
                if (subExtensionDict.count > 0) {
                    NSMutableDictionary *subDict = [[completeDefaultSettings objectForKey:subDictKey] mutableCopy];
                    if (subDict) {
                        [subDict addEntriesFromDictionary:subExtensionDict];
                        [completeDefaultSettings setObject:subDict forKey:subDictKey];
                        [defaultExtensionSettings removeObjectForKey:subDictKey];
                    } else {
                        [completeDefaultSettings setObject:subExtensionDict forKey:subDictKey];
                    }
                }
            }
            [completeDefaultSettings addEntriesFromDictionary:defaultExtensionSettings];
        }
    }
    return completeDefaultSettings.copy;
}
    

- (NSDictionary *)defaultSEBSettings
{
    return  @{@"rootSettings" :
                  [NSDictionary dictionaryWithObjectsAndKeys:
                   
                   [NSArray array],
                   @"additionalResources",
                   
                   @NO,
                   @"allowBrowsingBackForward",
                   
                   @NO,
                   @"allowDeveloperConsole",
                   
                   @NO,
                   @"allowDictation",

                   @NO,
                   @"allowDictionaryLookup",
                   
                   @NO,
                   @"allowDisplayMirroring",
                   
                   @YES,
                   @"allowedDisplayBuiltin",
                   
                   @YES,
                   @"allowedDisplayBuiltinEnforce",
                   
                   @YES,
                   @"allowedDisplayBuiltinExceptDesktop",

                   [NSNumber numberWithLong:1],
                   @"allowedDisplaysMaxNumber",
                   
                   @NO,
                   @"allowDownUploads",
                   
                   @NO,
                   @"allowFlashFullscreen",
                   
                   [NSNumber numberWithLong:iOSBetaVersionNone],
                   @"allowiOSBetaVersionNumber",
                   
                   [NSNumber numberWithLong:iOSVersion9],
                   @"allowiOSVersionNumberMajor",
                   
                   @3,
                   @"allowiOSVersionNumberMinor",
                   
                   @5,
                   @"allowiOSVersionNumberPatch",
                   
                   @NO,
                   @"allowMacOSVersionNumberCheckFull",
                   
                   [NSNumber numberWithLong:SEBMinMacOSVersionSupportedMajor],
                   @"allowMacOSVersionNumberMajor",
                   
                   [NSNumber numberWithLong:SEBMinMacOSVersionSupportedMinor],
                   @"allowMacOSVersionNumberMinor",
                   
                   [NSNumber numberWithLong:SEBMinMacOSVersionSupportedPatch],
                   @"allowMacOSVersionNumberPatch",
                   
                   @NO,
                   @"allowPDFPlugIn",
                   
                   @YES,
                   @"allowPreferencesWindow",
                   
                   @YES,
                   @"allowQuit",
                   
                   @NO,
                   @"allowScreenCapture",
                   
                   @NO,
                   @"allowScreenSharing",
                   
                   @NO,
                   @"allowSiri",
                   
                   @NO,
                   @"allowSpellCheck",
                   
                   @NO,
                   @"allowSwitchToApplications",
                   
                   @NO,
                   @"allowUserAppFolderInstall",
                   
                   @YES,
                   @"allowUserSwitching",
                   
                   @NO,
                   @"allowVideoCapture",
                   
                   @NO,
                   @"allowVirtualMachine",
                   
                   @NO,
                   @"allowWindowCapture",
                   
                   @NO,
                   @"allowWlan",
                   
                   @YES,
                   @"autoQuitApplications",
                   
                   @NO,
                   @"blockPopUpWindows",
                   
                   @NO,
                   @"blockScreenShotsLegacy",
                   
                   @YES,
                   @"browserMediaAutoplay",
                   
                   @YES,
                   @"browserMediaAutoplayAudio",
                   
                   @YES,
                   @"browserMediaAutoplayVideo",
                   
                   [NSNumber numberWithLong:120000],
                   @"browserMessagingPingTime",
                   
                   @"ws:\\localhost:8706",
                   @"browserMessagingSocket",
                   
                   @NO,
                   @"browserScreenKeyboard",
                   
                   @YES,
                   @"browserURLSalt",
                   
                   @"",
                   @"browserUserAgent",
                   
                   [NSNumber numberWithLong:browserUserAgentModeiOSDefault],
                   @"browserUserAgentiOS",
                   
                   @"",
                   @"browserUserAgentiOSCustom",
                   
                   [NSNumber numberWithLong:browserUserAgentModeMacDefault],
                   @"browserUserAgentMac",
                   
                   @"",
                   @"browserUserAgentMacCustom",
                   
                   [NSNumber numberWithLong:browserUserAgentModeWinDesktopDefault],
                   @"browserUserAgentWinDesktopMode",
                   
                   @"",
                   @"browserUserAgentWinDesktopModeCustom",
                   
                   [NSNumber numberWithLong:browserUserAgentModeWinTouchDefault],
                   @"browserUserAgentWinTouchMode",
                   
                   @"",
                   @"browserUserAgentWinTouchModeCustom",
                   
                   SEBWinUserAgentTouchiPad,
                   @"browserUserAgentWinTouchModeIPad",
                   
                   [NSNumber numberWithLong:browserViewModeWindow],
                   @"browserViewMode",
                   
                   @YES,
                   @"browserWindowAllowReload",
                   
                   [NSNumber numberWithLong:browserWindowShowURLNever],
                   @"browserWindowShowURL",
                   
                   [NSNumber numberWithLong:webViewSelectPreferModernInForeignNewTabs],
                   @"browserWindowWebView",
                   
                   [NSNumber numberWithLong:manuallyWithFileRequester],
                   @"chooseFileToUploadPolicy",
                   
                   [NSData data],
                   @"configKeySalt",
                   
                   @NO,
                   @"configFileCreateIdentity",
                   
                   @NO,
                   @"configFileEncryptUsingIdentity",
                   
                   @YES,
                   @"createNewDesktop",
                   
                   [NSNumber numberWithDouble:WebViewDefaultPageZoom],
                   @"defaultPageZoomLevel",
                   
                   [NSNumber numberWithDouble:WebViewDefaultPageZoom],
                   @"defaultTextZoomLevel",
                   
                   @YES,
                   @"detectStoppedProcess",
                   
                   @YES,
                   @"downloadAndOpenSebConfig",
                   
                   [NSHomeDirectory() stringByAppendingPathComponent: @"Downloads"],
                   @"downloadDirectoryOSX",
                   
                   @"Downloads",
                   @"downloadDirectoryWin",
                   
                   @NO,
                   @"downloadPDFFiles",
                   
                   [NSArray array],
                   @"embeddedCertificates",
                   
                   @YES,
                   @"enableAppSwitcherCheck",
                   
                   @NO,
                   @"enableBrowserWindowToolbar",
                   
                   @NO,
                   @"enableChromeNotifications",
                   
                   @NO,
                   @"enableDrawingEditor",
                   
                   @NO,
                   @"enableJava",
                   
                   @YES,
                   @"enableJavaScript",
                   
                   @YES,
                   @"enableLogging",
                   
                   @NO,
                   @"enableMacOSAAC",
                   
                   @YES,
                   @"enablePlugIns",
                   
                   @YES,
                   @"enablePrivateClipboard",
                   
                   @YES,
                   @"enablePrivateClipboardMacEnforce",
                                  
                   @YES,
                   @"enableScrollLock",

                   @YES,
                   @"enableSebBrowser",
                   
                   @NO,
                   @"enableTouchExit",
                   
                   @NO,
                   @"enableWindowsUpdate",
                   
                   @YES,
                   @"enableEsc",

                   @NO,
                   @"enableCtrlEsc",
                   
                   @NO,
                   @"enableAltEsc",
                   
                   @NO,
                   @"enableAltMouseWheel",
                   
                   @YES,
                   @"enableAltTab",
                   
                   @NO,
                   @"enableAltF4",
                   
                   @NO,
                   @"enablePrintScreen",
                   
                   @YES,
                   @"enableRightMouse",
                   
                   @NO,
                   @"enableRightMouseMac",
                   
                   @NO,
                   @"enableStartMenu",
                   
                   @YES,
                   @"enableF1",
                   
                   @YES,
                   @"enableF2",
                   
                   @YES,
                   @"enableF3",
                   
                   @YES,
                   @"enableF4",
                   
                   @YES,
                   @"enableF5",
                   
                   @YES,
                   @"enableF6",
                   
                   @YES,
                   @"enableF7",
                   
                   @YES,
                   @"enableF8",
                   
                   @YES,
                   @"enableF9",
                   
                   @YES,
                   @"enableF10",
                   
                   @YES,
                   @"enableF11",
                   
                   @YES,
                   @"enableF12",
                   
                   @YES,
                   @"enableZoomPage",
                   
                   @YES,
                   @"enableZoomText",
                   
                   [NSData data],
                   @"examKeySalt",
                   
                   @YES,
                   @"examSessionClearCookiesOnEnd",
                   
                   @YES,
                   @"examSessionClearCookiesOnStart",
                   
                   @NO,
                   @"examSessionReconfigureAllow",
                   
                   @"",
                   @"examSessionReconfigureConfigURL",
                   
                   [NSNumber numberWithLong:2],
                   @"exitKey1",
                   
                   [NSNumber numberWithLong:10],
                   @"exitKey2",
                   
                   [NSNumber numberWithLong:5],
                   @"exitKey3",
                   
                   @"",
                   @"hashedAdminPassword",
                   
                   @"",
                   @"hashedQuitPassword",
                   
                   @NO,
                   @"hideBrowserWindowToolbar",
                   
                   @YES,
                   @"hookKeys",
                   
                   @YES,
                   @"forceAppFolderInstall",
                   
                   @YES,
                   @"ignoreExitKeys",
                   
                   @NO,
                   @"ignoreQuitPassword",
                   
                   @NO,
                   @"insideSebEnableChangeAPassword",
                   
                   @NO,
                   @"insideSebEnableEaseOfAccess",
                   
                   @NO,
                   @"insideSebEnableLockThisComputer",
                   
                   @NO,
                   @"insideSebEnableLogOff",
                   
                   @NO,
                   @"insideSebEnableNetworkConnectionSelector",
                   
                   @NO,
                   @"insideSebEnableShutDown",
                   
                   @NO,
                   @"insideSebEnableStartTaskManager",
                   
                   @NO,
                   @"insideSebEnableSwitchUser",
                   
                   @NO,
                   @"insideSebEnableVmWareClientShade",
                   
                   @NO,
                   @"jitsiMeetAudioMuted",
                   
                   @NO,
                   @"jitsiMeetAudioOnly",
                   
                   @NO,
                   @"jitsiMeetEnable",
                   
                   @NO,
                   @"jitsiMeetFeatureFlagChat",
                   
                   @NO,
                   @"jitsiMeetFeatureFlagCloseCaptions",
                   
                   @NO,
                   @"jitsiMeetFeatureFlagDisplayMeetingName",
                   
                   @NO,
                   @"jitsiMeetFeatureFlagRaiseHand",
                   
                   @NO,
                   @"jitsiMeetFeatureFlagRecording",
                   
                   @NO,
                   @"jitsiMeetFeatureFlagTileView",
                   
                   @NO,
                   @"jitsiMeetReceiveAudio",
                   
                   @NO,
                   @"jitsiMeetReceiveVideo",
                   
                   @"",
                   @"jitsiMeetRoom",
                   
                   @YES,
                   @"jitsiMeetSendAudio",
                   
                   @YES,
                   @"jitsiMeetSendVideo",
                   
                   @"",
                   @"jitsiMeetServerURL",
                   
                   @"",
                   @"jitsiMeetSubject",
                   
                   @"",
                   @"jitsiMeetToken",
                   
                   @"",
                   @"jitsiMeetUserInfoAvatarURL",
                   
                   @"",
                   @"jitsiMeetUserInfoDisplayName",
                   
                   @"",
                   @"jitsiMeetUserInfoEMail",
                   
                   @NO,
                   @"jitsiMeetVideoMuted",
                   
                   @NO,
                   @"killExplorerShell",
                   
                   @"",
                   @"logDirectoryOSX",
                   
                   @"",
                   @"logDirectoryWin",
                   
                   [NSNumber numberWithLong:SEBLogLevelDebug],
                   @"logLevel",
                   
                   @NO,
                   @"logSendingRequiresAdminPassword",
                   
                   @"100%",
                   @"mainBrowserWindowHeight",
                   
                   [NSNumber numberWithLong:browserWindowPositioningCenter],
                   @"mainBrowserWindowPositioning",
                   
                   @"100%",
                   @"mainBrowserWindowWidth",
                   
                   [NSNumber numberWithLong:SEBMinOSX10_11],
                   @"minMacOSVersion",
                   
                   @0,
                   @"minMacOSVersionNumberMinor",
                   
                   @YES,
                   @"mobileAllowInlineMediaPlayback",
                   
                   @NO,
                   @"mobileAllowPictureInPictureMediaPlayback",

                   @NO,
                   @"mobileAllowQRCodeConfig",
                   
                   @NO,
                   @"mobileAllowSingleAppMode",
                                      
                   @NO,
                   @"mobileCompactAllowInlineMediaPlayback",
                   
                   @NO,
                   @"mobileEnableGuidedAccessLinkTransform",
                   
                   @YES,
                   @"mobileEnableASAM",
                   
                   @YES,
                   @"mobileSleepModeLockScreen",
                   
                   @NO,
                   @"mobileShowSettings",
                   
                   [NSNumber numberWithLong:mobileStatusBarAppearanceLight],
                   @"mobileStatusBarAppearance",
                   
                   [NSNumber numberWithLong:mobileStatusBarAppearanceExtendedLight],
                   @"mobileStatusBarAppearanceExtended",
                   
                   @YES,
                   @"mobileSupportedFormFactorsCompact",
                   
                   @YES,
                   @"mobileSupportedFormFactorsNonTelephonyCompact",
                   
                   @YES,
                   @"mobileSupportedFormFactorsRegular",
                   
                   @YES,
                   @"mobileSupportedScreenOrientationsCompactPortrait",
                   
                   @NO,
                   @"mobileSupportedScreenOrientationsCompactPortraitUpsideDown",
                   
                   @YES,
                   @"mobileSupportedScreenOrientationsCompactLandscapeLeft",
                   
                   @YES,
                   @"mobileSupportedScreenOrientationsCompactLandscapeRight",
                   
                   @YES,
                   @"mobileSupportedScreenOrientationsRegularPortrait",
                   
                   @YES,
                   @"mobileSupportedScreenOrientationsRegularPortraitUpsideDown",
                   
                   @YES,
                   @"mobileSupportedScreenOrientationsRegularLandscapeLeft",
                   
                   @YES,
                   @"mobileSupportedScreenOrientationsRegularLandscapeRight",
                   
                   @YES,
                   @"mobilePreventAutoLock",
                   
                   @YES,
                   @"monitorProcesses",
                   
                   @YES,
                   @"newBrowserWindowAllowReload",
                   
                   @NO,
                   @"newBrowserWindowByLinkBlockForeign",
                   
                   @"100%",
                   @"newBrowserWindowByLinkHeight",
                   
                   [NSNumber numberWithLong:openInNewWindow],
                   @"newBrowserWindowByLinkPolicy",
                   
                   [NSNumber numberWithLong:browserWindowPositioningRight],
                   @"newBrowserWindowByLinkPositioning",
                   
                   @"1000",
                   @"newBrowserWindowByLinkWidth",
                   
                   @NO,
                   @"newBrowserWindowByScriptBlockForeign",
                   
                   [NSNumber numberWithLong:openInNewWindow],
                   @"newBrowserWindowByScriptPolicy",
                   
                   @YES,
                   @"newBrowserWindowNavigation",
                   
                   @NO,
                   @"newBrowserWindowShowReloadWarning",
                   
                   [NSNumber numberWithLong:browserWindowShowURLBeforeTitle],
                   @"newBrowserWindowShowURL",
                   
                   @NO,
                   @"openDownloads",
                   
                   [NSNumber numberWithLong:oskBehaviorAutoShow],
                   @"oskBehavior",
                   
                   [NSArray array],
                   @"permittedProcesses",
                   
                   @NO,
                   @"pinEmbeddedCertificates",
                   
                   @NO,
                   @"proctoringAIEnable",
                   
                   @YES,
                   @"proctoringDetectFaceAngleDisplay",
                   
                   @YES,
                   @"proctoringDetectFaceCount",
                   
                   @YES,
                   @"proctoringDetectFaceCountDisplay",
                   
                   @YES,
                   @"proctoringDetectFacePitch",
                   
                   @YES,
                   @"proctoringDetectFaceYaw",
                   
                   @YES,
                   @"proctoringDetectTalking",
                   
                   @YES,
                   @"proctoringDetectTalkingDisplay",
                   
                   [NSArray array],
                   @"prohibitedProcesses",
                   
                   [NSMutableDictionary new],
                   @"proxies",
                   
                   [NSNumber numberWithLong:useSystemProxySettings],
                   @"proxySettingsPolicy",
                   
                   @"",
                   @"quitURL",
                   
                   @YES,
                   @"quitURLConfirm",
                   
                   @NO,
                   @"quitURLRestart",
                   
                   @YES,
                   @"raiseHandButtonShow",
                   
                   @NO,
                   @"raiseHandButtonAlwaysPromptMessage",
                   
                   [NSNumber numberWithLong:remoteProctoringViewShowNever],
                   @"remoteProctoringViewShow",

                   @NO,
                   @"removeBrowserProfile",
                   
                   @NO,
                   @"removeLocalStorage",
                   
                   @YES,
                   @"restartExamPasswordProtected",
                   
                   @"",
                   @"restartExamText",
                   
                   @"",
                   @"restartExamURL",
                   
                   @NO,
                   @"restartExamUseStartURL",
                   
                   @NO,
                   @"screenSharingMacEnforceBlocked",
                   
                   [NSNumber numberWithLong:sebConfigPurposeConfiguringClient],
                   @"sebConfigPurpose",
                   
                   [NSNumber numberWithLong:sebModeStartURL],
                   @"sebMode",
                   
                   [NSMutableDictionary new],
                   @"sebServerConfiguration",
                   
                   @NO,
                   @"sebServerFallback",
                   
                   @"",
                   @"sebServerURL",
                   
                   @YES,
                   @"sebServiceIgnore",
                   
                   [NSNumber numberWithLong:forceSebService],
                   @"sebServicePolicy",
                   
                   @NO,
                   @"sendBrowserExamKey",
                   
                   @NO,
                   @"setVmwareConfiguration",
                   
                   @YES,
                   @"showBackToStartButton",
                   
                   @NO,
                   @"showInputLanguage",
                   
                   @YES,
                   @"showMenuBar",
                   
                   @NO,
                   @"showNavigationButtons",
                   
                   @YES,
                   @"showProctoringViewButton",
                   
                   @YES,
                   @"showQuitButton",
                   
                   @YES,
                   @"showReloadButton",
                                      
                   @NO,
                   @"showReloadWarning",
                   
                   @NO,
                   @"showScanQRCodeButton",
                   
                   @YES,
                   @"showScrollLockButton",
                   
                   @YES,
                   @"showTaskBar",
                   
                   @YES,
                   @"showTime",
                   
                   SEBStartPage,
                   @"startURL",
                   
                   @NO,
                   @"startURLAllowDeepLink",
                   
                   @NO,
                   @"startURLAppendQueryParameter",
                   
                   [NSNumber numberWithLong:SEBDefaultDockHeight],
                   @"taskBarHeight",
                   
                   @NO,
                   @"terminateProcesses",
                   
                   @NO,
                   @"touchOptimized",
                   
                   @NO,
                   @"URLFilterEnable",
                   
                   @NO,
                   @"URLFilterEnableContentFilter",
                   
                   [NSArray array],
                   @"URLFilterIgnoreList",
                   
                   [NSNumber numberWithLong:URLFilterMessageText],
                   @"URLFilterMessage",
                   
                   @NO,
                   @"urlFilterRegex",
                   
                   @NO,
                   @"urlFilterTrustedContent",
                   
                   @"",
                   @"blacklistURLFilter",
                   
                   @"",
                   @"whitelistURLFilter",
                   
                   [NSArray array],
                   @"URLFilterRules",
                   
                   [NSNumber numberWithLong:SEBZoomModePage],
                   @"zoomMode",
                   
                   @"",
                   @"zoomAPIKey",
                   
                   @NO,
                   @"zoomAudioMuted",
                   
                   @NO,
                   @"zoomEnable",
                   
                   @NO,
                   @"zoomFeatureFlagChat",
                   
                   @NO,
                   @"zoomFeatureFlagCloseCaptions",
                   
                   @NO,
                   @"zoomFeatureFlagRaiseHand",
                   
                   @NO,
                   @"zoomFeatureFlagTileView",
                   
                   @"",
                   @"zoomMeetingKey",
                   
                   @NO,
                   @"zoomReceiveAudio",
                   
                   @NO,
                   @"zoomReceiveVideo",
                   
                   @"",
                   @"zoomRoom",
                   
                   @"",
                   @"zoomSDKToken",
                   
                   @YES,
                   @"zoomSendAudio",
                   
                   @YES,
                   @"zoomSendVideo",
                   
                   @"",
                   @"zoomServerURL",
                   
                   @"",
                   @"zoomSubject",
                   
                   @"",
                   @"zoomToken",
                   
                   @"",
                   @"zoomUserInfoDisplayName",
                   
                   @"",
                   @"zoomUserName",
                   
                   @NO,
                   @"zoomVideoMuted",
                   
                   nil],
              
              @"additionalResources" : @{
                      @"active" : @YES,
                      @"additionalResources" : @[],
                      @"autoOpen" : @NO,
                      @"identifier" : @"",
                      @"title" : @"",
                      @"URL" : @"",
                      @"URLFilterRules" :  @[],
                      @"resourceData" : @"",
                      @"resourceIcons" : @[],
                      },
              
              @"permittedProcesses" : @{
                      @"active" : @YES,
                      @"allowUserToChooseApp" : @NO,
                      @"allowedExecutables" : @"",
                      @"arguments" : @[],
                      @"autostart" : @NO,
                      @"description" : @"",
                      @"executable" : @"",
                      @"iconInTaskbar" : @YES,
                      @"identifier" : @"",
                      @"originalName" : @"",
                      @"os" : @0,
                      @"path" : @"",
                      @"runInBackground" : @NO,
                      @"strongKill" : @NO,
                      @"title" : @"",
                      @"windowHandlingProcess" : @""
                      },
              
              @"prohibitedProcesses" : @{
                      @"active" : @YES,
                      @"allowedExecutables" : @"",
                      @"currentUser" : @NO,
                      @"description" : @"",
                      @"executable" : @"",
                      @"identifier" : @"",
                      @"ignoreInAAC" : @YES,
                      @"originalName" : @"",
                      @"os" : @0,
                      @"strongKill" : @NO,
                      @"user" : @""
                      },
              
              @"URLFilterRules" : @{
                      @"action" : [NSNumber numberWithLong:URLFilterActionAllow],
                      @"active" : @YES,
                      @"expression" : @"",
                      @"regex" : @NO
                      },
              
              @"embeddedCertificates" : @{
                      @"certificateData" : [NSData data],
                      @"certificateDataBase64" : @"",
                      @"name" : @"",
                      @"type" : [NSNumber numberWithLong:certificateTypeSSL],
                      },
              
              @"proxies" : @{
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
              
              @"sebServerConfiguration" : @{
                      @"institution" : @"",
                      @"clientName" : @"",
                      @"clientSecret" : @"",
                      @"apiDiscovery" : @"",
                      @"pingInterval" : @1000
                      }
              
              };
}


@end
