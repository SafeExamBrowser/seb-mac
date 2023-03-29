//
//  Constants.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 29.12.11.
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

@import CocoaLumberjack;
#import "SEBConstants.h"

#ifndef SafeExamBrowser_Constants_h
#define SafeExamBrowser_Constants_h


#define sebConfigFilePrefixLength               4
#define publicKeyHashLenght                     20
#define kMenuBarNotificationCenterIconWidth     46.0


// iOS: these are the various screen placement constants used across most the UIViewControllers

// padding for margins

// for general screen
#define kLeftMargin				20.0
#define kTopMargin				20.0
#define kRightMargin			20.0
#define kTweenMargin			10.0

#define kTextFieldHeight		30.0

// Toolbar height when printing is supported
#define kToolbarHeight 49
#define kNavbarHeight 44
#define kStatusbarHeight 20

#define kCustomButtonHeight     30.0

#define SEBDefaultDockHeight 40.0
#define SEBDefaultDockTimeItemFontSize 14.5
#define SEBDefaultDockTimeItemPreferredWidth 42.0

#define SEBErrorNoValidConfigData 10
#define SEBErrorNoValidPrefixNoValidUnencryptedHeader 11
#define SEBErrorDecryptingSettingsCanceled 101
#define SEBErrorDecryptingNoSettingsPasswordEntered 102
#define SEBErrorDecryptingSettingsAdminPasswordCanceled 105
#define SEBErrorDecryptingNoAdminPasswordEntered 106
#define SEBErrorDecryptingIdentityNotFound 110
#define SEBErrorParsingSettingsFailedValueClassMissmatch 201
#define SEBErrorParsingSettingsSerializingFailed 205
#define SEBErrorOpeningUniversalLinkFailed 300

#define SEBServerDefaultPingInterval 1000
#define SEBServerDefaultFallbackTimeout 30000
#define SEBErrorConnectionSettingsInvalid 400
#define SEBErrorGettingConnectionTokenFailed 401

#define currentStableMajoriOSVersion 16

#define WebViewDefaultTextSize 120.0
#define WebViewDefaultTextZoom 1.0
#define WebViewMinTextZoom 0.9
#define WebViewMaxTextZoom 3.5
#define WebViewDefaultPageZoom 1.0
#define WebViewMinPageZoom 0.25
#define WebViewMaxPageZoom 4.0

enum {
    webViewSelectAutomatic                      = 0,
    webViewSelectForceClassic                   = 1,
    webViewSelectPreferModernInForeignNewTabs   = 2,
    webViewSelectPreferModern                   = 3
};
typedef NSUInteger webViewSelectPolicies;


enum {
    browserUserAgentModeiOSDefault              = 0,
    browserUserAgentModeiOSMacDesktop           = 1,
    browserUserAgentModeiOSCustom               = 2,
    browserUserAgentModeiOSiPad                 = 3
};
typedef NSUInteger browserUserAgentModeiOS;


enum {
    browserUserAgentModeMacDefault              = 0,
    browserUserAgentModeMacCustom               = 1
};
typedef NSUInteger browserUserAgentModeMac;


enum {
    browserUserAgentModeWinDesktopDefault       = 0,
    browserUserAgentModeWinDesktopCustom        = 1
};
typedef NSUInteger browserUserAgentModeWinDesktop;


enum {
    browserUserAgentModeWinTouchDefault         = 0,
    browserUserAgentModeWinTouchIPad            = 1,
    browserUserAgentModeWinTouchCustom          = 2
};
typedef NSUInteger browserUserAgentModeWinTouch;


enum {
    browserViewModeWindow                       = 0,
    browserViewModeFullscreen                   = 1,
    browserViewModeTouch                        = 2
};
typedef NSUInteger browserViewModes;


enum {
    browserWindowPositioningLeft                = 0,
    browserWindowPositioningCenter              = 1,
    browserWindowPositioningRight               = 2
};
typedef NSUInteger browserWindowPositionings;


enum {
    browserWindowShowURLNever                   = 0,
    browserWindowShowURLOnlyLoadError           = 1,
    browserWindowShowURLBeforeTitle             = 2,
    browserWindowShowURLAlways                  = 3
};
typedef NSUInteger browserWindowShowURLPolicies;


enum {
    coveringWindowBackground                    = 0,
    coveringWindowLockdownAlert                 = 1
};
typedef NSUInteger coveringWindowKind;


enum {
    certificateTypeSSL                          = 0,
    certificateTypeIdentity                     = 1,
    certificateTypeCA                           = 2,
    certificateTypeSSLDebug                     = 3
};
typedef NSUInteger certificateTypes;


enum {
    configFileShareKeysWithConfig               = 0,
    configFileShareKeysWithoutConfig            = 1
};
typedef NSUInteger configFileShareKeysModes;


enum {
    manuallyWithFileRequester                   = 0,
    attemptUploadSameFileDownloadedBefore       = 1,
    onlyAllowUploadSameFileDownloadedBefore     = 2
};
typedef NSUInteger chooseFileToUploadPolicies;


enum {
    FetchingIdentities                          = 0
};
typedef NSUInteger cryptoIdentities;


enum {
    iOSBetaVersionNone                          = 0,
    iOSBetaVersion16                            = 16
};
typedef NSUInteger iOSBetaVersion;


enum {
    iOSVersion9                                 = 9,
    iOSVersion10                                = 10,
    iOSVersion11                                = 11,
    iOSVersion12                                = 12,
    iOSVersion13                                = 13,
    iOSVersion14                                = 14,
    iOSVersion15                                = 15,
    iOSVersion16                                = 16
};
typedef NSUInteger iOSVersion;


enum {
    remoteProctoringViewShowNever               = 0,
    remoteProctoringViewShowAllowToShow         = 1,
    remoteProctoringViewShowAllowToHide         = 2,
    remoteProctoringViewShowAlways              = 3
};
typedef NSInteger remoteProctoringViewShowPolicies;


enum {
    remoteProctoringButtonStateDefault          = 0,
    remoteProctoringButtonStateNormal           = 1,
    remoteProctoringButtonStateWarning          = 2,
    remoteProctoringButtonStateError            = 3,
    remoteProctoringButtonStateAIInactive       = 4
};
typedef NSInteger remoteProctoringButtonStates;


enum {
    RemoteProctoringEventTypeDefault            = 0,
    RemoteProctoringEventTypeNormal             = 1,
    RemoteProctoringEventTypeWarning            = 2,
    RemoteProctoringEventTypeError              = 3
};
typedef NSInteger RemoteProctoringEventType;


enum {
    mobileStatusBarAppearanceNone               = 0,
    mobileStatusBarAppearanceLight              = 1,
    mobileStatusBarAppearanceDark               = 2
};
typedef NSUInteger mobileStatusBarAppearances;


enum {
    mobileStatusBarAppearanceExtendedInferred   = 0,
    mobileStatusBarAppearanceExtendedLight      = 1,
    mobileStatusBarAppearanceExtendedDark       = 2,
    mobileStatusBarAppearanceExtendedNoneDark   = 3,
    mobileStatusBarAppearanceExtendedNoneLight  = 4
};
typedef NSUInteger mobileStatusBarAppearancesExtended;


enum {
    SEBBackgroundTintStyleNone                  = 0,
    SEBBackgroundTintStyleLight                 = 1,
    SEBBackgroundTintStyleDark                  = 2
};
typedef NSInteger SEBBackgroundTintStyle;


enum {
    getGenerallyBlocked                         = 0,
    openInSameWindow                            = 1,
    openInNewWindow                             = 2
};
typedef NSUInteger newBrowserWindowPolicies;


enum {
    SEBNavigationActionPolicyCancel             = 0,
    SEBNavigationActionPolicyAllow              = 1,
    SEBNavigationActionPolicyDownload           = 2,
    SEBNavigationActionPolicyJSOpen             = 3
};
typedef NSInteger SEBNavigationActionPolicy;


enum {
    SEBNavigationResponsePolicyCancel             = 0,
    SEBNavigationResponsePolicyAllow              = 1,
    SEBNavigationResponsePolicyDownload           = 2
};
typedef NSUInteger SEBNavigationResponsePolicy;


enum {
    operatingSystemMacOS                        = 0,
    operatingSystemWin                          = 1,
};
typedef NSUInteger operatingSystems;


enum {
    oskBehaviorAlwaysShow                       = 0,
    oskBehaviorNeverShow                        = 1,
    oskBehaviorAutoShow                         = 2
};
typedef NSUInteger oskBehaviors;


enum {
    useSystemProxySettings                      = 0,
    useSEBProxySettings                         = 1,
};
typedef NSUInteger proxySettingsPolicies;


enum {
    sebConfigPurposeStartingExam                = 0,
    sebConfigPurposeConfiguringClient           = 1,
    sebConfigPurposeManagedConfiguration        = 2
};
typedef NSUInteger sebConfigPurposes;


enum {
    SEBClientConfigURLSchemeNone                = 0,
    SEBClientConfigURLSchemeSubdomainShort      = 1,
    SEBClientConfigURLSchemeSubdomainLong       = 2,
    SEBClientConfigURLSchemeDomain              = 3,
    SEBClientConfigURLSchemeWellKnown           = 4
};
typedef NSUInteger SEBClientConfigURLSchemes;


enum {
    SEBEnterPasswordCancel                      = 0,
    SEBEnterPasswordOK                          = 1,
    SEBEnterPasswordAborted                     = 2
};
typedef NSUInteger SEBEnterPasswordResponse;


enum {
    SEBURLFilterAlertPatternDomain               = 0,
    SEBURLFilterAlertPatternHost                 = 1,
    SEBURLFilterAlertPatternHostPath             = 2,
    SEBURLFilterAlertPatternDirectory            = 3,
    SEBURLFilterAlertPatternCustom               = 4
};
typedef NSUInteger SEBURLFilterAlertPattern;


enum {
    SEBURLFilterAlertDismiss                     = 0,
    SEBURLFilterAlertAllow                       = 1,
    SEBURLFilterAlertIgnore                      = 2,
    SEBURLFilterAlertBlock                       = 3,
    SEBURLFilterAlertDismissAll                  = 4
};
typedef NSUInteger SEBURLFilterAlertResponse;


enum {
    sebModeStartURL                             = 0,
    sebModeSebServer                            = 1
};
typedef NSUInteger sebModes;


enum {
    ignoreService                               = 0,
    indicateMissingService                      = 1,
    forceSebService                             = 2
};
typedef NSUInteger sebServicePolicies;


enum {
    SEBKioskModeNone                            = 0,
    SEBKioskModeCreateNewDesktop                = 1,
    SEBKioskModeKillExplorerShell               = 2
};
typedef NSUInteger SEBKioskMode;


enum {
    StoreDecryptedSEBSettingsResultSuccess      = 0,
    StoreDecryptedSEBSettingsResultCanceled     = 1,
    StoreDecryptedSEBSettingsResultWrongFormat  = 2
};
typedef NSUInteger StoreDecryptedSEBSettingsResult;


enum {
    URLFilterMessageText                        = 0,
    URLFilterMessageX                           = 1
};
typedef NSUInteger URLFilterMessages;


enum {
    URLFilterActionBlock                        = 0,
    URLFilterActionAllow                        = 1,
    URLFilterActionIgnore                       = 2,
    URLFilterActionUnknown                      = 3
};
typedef NSUInteger URLFilterRuleActions;


enum {
    SEBLogLevelError                            = 0,
    SEBLogLevelWarning                          = 1,
    SEBLogLevelInfo                             = 2,
    SEBLogLevelDebug                            = 3,
    SEBLogLevelVerbose                          = 4
};
typedef NSUInteger SEBLogLevel;


enum {
/*! @constant   SEBLowBatteryWarningNone
 *
 *  @abstract   The system is not in a low battery situation, or is on drawing from an external power source.
 *
 *  @discussion The system displays no low power warnings; neither should application clients of this
 *              API.
 */
    SEBLowBatteryWarningNone  = 1,

/*! @constant   SEBLowBatteryWarningEarly
 *
 *  @abstract   The battery can provide no more than 20 minutes of runtime.
 *
 *  @discussion macOS makes no guarantees that the system shall remain in Early Warning for 20 minutes.
 *              Batteries are frequently calibrated differently and may provide runtime
 *              for more, or less, than the estimated 20 minutes.
 *              macOS alerts the user by changing the color of BatteryMonitor to red.
 *              Warning the user is optional for full screen apps.
 */
    SEBLowBatteryWarningEarly = 2,

/*! @constant   SEBLowBatteryWarningFinal
 *
 *  @abstract   The battery can provide no more than 10 minutes of runtime.
 *
 *  @discussion macOS makes no guarantees that the system shall remain in Final Warning for 10 minutes.
 *              Batteries are frequently calibrated differently and may provide runtime
 *              for more, or less, than the estimated 10 minutes.
 */
    SEBLowBatteryWarningFinal = 3
};
typedef NSInteger SEBLowBatteryWarningLevel;


enum {
    SEBMinOSX10_7                               = 0,
    SEBMinOSX10_8                               = 1,
    SEBMinOSX10_9                               = 2,
    SEBMinOSX10_10                              = 3,
    SEBMinOSX10_11                              = 4,
    SEBMinMacOS10_12                            = 5,
    SEBMinMacOS10_13                            = 6,
    SEBMinMacOS10_14                            = 7,
    SEBMinMacOS10_15                            = 8,
    SEBMinMacOS11                               = 9,
    SEBMinMacOS12                               = 10,
    SEBMinMacOS13                               = 11
};
typedef NSUInteger SEBMinMacOSVersion;


enum {
    SEBDockItemPositionLeftPinned               = 0,
    SEBDockItemPositionCenter                   = 1,
    SEBDockItemPositionRightPinned              = 2
};
typedef NSUInteger SEBDockItemPosition;


enum {
    SEBUnsavedSettingsAnswerSave                = 0,
    SEBUnsavedSettingsAnswerDontSave            = 1,
    SEBUnsavedSettingsAnswerCancel              = 2
};
typedef NSUInteger SEBUnsavedSettingsAnswer;


enum {
    SEBApplySettingsAnswerDontApply             = 0,
    SEBApplySettingsAnswerApply                 = 1,
    SEBApplySettingsAnswerCancel                = 2
};
typedef NSUInteger SEBApplySettingsAnswers;


enum {
    SEBDisabledPreferencesAnswerOverride        = 0,
    SEBDisabledPreferencesAnswerApply           = 1,
    SEBDisabledPreferencesAnswerCancel          = 2
};
typedef NSUInteger SEBDisabledPreferencesAnswer;


enum {
    SEBZoomModePage                             = 0,
    SEBZoomModeText                             = 1
};
typedef NSUInteger SEBZoomModes;


static NSString __unused *screenSharingAgent = @"ScreensharingAgent";
static NSString __unused *screenSharingAgentBundleID = @"com.apple.screensharing.agent";
static NSString __unused *screenCaptureAgent = @"screencapture";
static NSString __unused *AppleVNCAgent = @"AppleVNCServer";
static NSString __unused *AppleVNCAgentBundleID = @"com.apple.AppleVNCServer";
static NSString __unused *ARDAgent = @"ARDAgent";
static NSString __unused *ARDAgentBundleID = @"com.apple.RemoteDesktopAgent";
static NSString __unused *fontRegistryUIAgent = @"FontRegistryUIAgent";
static NSString __unused *fontRegistryUIAgentBundleID = @"com.apple.FontRegistryUIAgent";
static NSString __unused *lookupQuicklookHelper = @"QuickLookUIHelper";
static NSString __unused *lookupQuicklookHelperBundleID = @"com.apple.quicklook.ui.helper";
static NSString __unused *lookupViewService = @"LookupViewService";
static NSString __unused *lookupViewServiceBundleID = @"com.apple.LookupViewService";
static NSString __unused *XcodeBundleID = @"com.apple.dt.Xcode";
static NSString __unused *SiriService = @"SiriNCService";
static NSString __unused *SiriDefaultsDomain = @"com.apple.assistant.support";
static NSString __unused *SiriDefaultsKey = @"Assistant Enabled";
static NSString __unused *cachedSiriSettingKey = @"cachedSiriSettingKey";
static NSString __unused *TouchBarAgent = @"com.apple.controlstrip";
static NSString __unused *TouchBarDefaultsDomain = @"com.apple.touchbar.agent";
static NSString __unused *TouchBarGlobalDefaultsKey = @"PresentationModeGlobal";
static NSString __unused *TouchBarGlobalDefaultsValue = @"fullControlStrip";
static NSString __unused *TouchBarFnDictionaryDefaultsKey = @"PresentationModeFnModes";
static NSString __unused *TouchBarFnDefaultsKey = @"fullControlStrip";
static NSString __unused *TouchBarFnDefaultsValue = @"functionKeys";
static NSString __unused *BTouchBarAgent = @"BetterTouchTool";
static NSString __unused *BTouchBarRestartAgent = @"BTTRelaunch";
static NSString __unused *WebKitNetworkingProcessBundleID = @"com.apple.WebKit.Networking";
static NSString __unused *UniversalControlBundleID = @"com.apple.universalcontrol";
static NSString __unused *cachedTouchBarGlobalSettingsKey = @"cachedTouchBarGlobalSettingsKey";
static NSString __unused *cachedTouchBarFnDictionarySettingsKey = @"cachedTouchBarFnDictionarySettingsKey";
static NSString __unused *systemPreferencesBundleID = @"com.apple.systempreferences";
static NSString __unused *pathToKeyboardPreferences = @"/System/Library/PreferencePanes/Keyboard.prefPane";
static NSString __unused *pathToSecurityPrivacyPreferences = @"x-apple.systempreferences:com.apple.preference.security?Privacy";
static NSString __unused *DictationProcess = @"DictationIM";
static NSString __unused *DictationDefaultsDomain = @"com.apple.speech.recognition.AppleSpeechRecognition.prefs";
static NSString __unused *DictationDefaultsKey = @"DictationIMMasterDictationEnabled";
static NSString __unused *AppleDictationDefaultsDomain = @"com.apple.HIToolbox";
static NSString __unused *AppleDictationDefaultsKey = @"AppleDictationAutoEnable";
static NSString __unused *cachedDictationSettingKey = @"cachedDictationSettingKey";
static NSString __unused *cachedRemoteDictationSettingKey = @"cachedRemoteDictationSettingKey";
static NSString __unused *RemoteDictationDefaultsDomain = @"com.apple.assistant.support";
static NSString __unused *RemoteDictationDefaultsKey = @"Dictation Enabled";
static NSString __unused *fontDownloadAttemptedKey = @"fontDownloadAttempted";
static NSString __unused *fontDownloadAttemptedOnPageTitleKey = @"fontDownloadAttemptedOnPageTitle";
static NSString __unused *fontDownloadAttemptedOnPageURLOrPlaceholderKey = @"fontDownloadAttemptedOnPageURLOrPlaceholder";

static NSString __unused *userDefaultsMasala = @"Di𝈭l𝈖Ch𝈒ah𝉇t𝈁a𝉈Hai1972";

// Error numbers for SEB error domains
enum {
    SEBErrorASCCNoConfigFound                   = 1000,
    SEBErrorASCCNoWiFi                          = 1001,
    SEBErrorASCCNoHostnameFound                 = 1002,
    SEBErrorASCCCanceled                        = 1003
};
typedef NSUInteger SEBErrorDomainErrors;

static NSString __unused *SEBUserAgentDefaultBrowserSuffix = @"Version/14.0.3 Safari";
static NSString __unused *SEBUserAgentDefaultSafariVersion = @"605.1.15";
static NSString __unused *SEBiOSUserAgentDesktopMac = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0.3 Safari/605.1.15";
static NSString __unused *SEBiOSUserAgentiPadDefault = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Safari/605.1.15";
static NSString __unused *SEBWinUserAgentDesktopDefault = @"Mozilla/5.0 (Windows NT 10.0; WOW64; rv:52.0) Gecko/20100101 Firefox/52.0";
static NSString __unused *SEBWinUserAgentTouchDefault = @"Mozilla/5.0 (Windows NT 10.0; WOW64; rv:52.0; Touch) Gecko/20100101 Firefox/52.0";
static NSString __unused *SEBWinUserAgentTouchiPad = @"Mozilla/5.0 (iPad; CPU OS 12_4_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.1.2 Mobile/15E148 Safari/604.1";
static NSString __unused *SEBBrowserExamKeyHeaderKey = @"X-SafeExamBrowser-RequestHash";
static NSString __unused *SEBConfigKeyHeaderKey = @"X-SafeExamBrowser-ConfigKeyHash";
static NSString __unused *runningOSmacOS = @"macOS";
static NSString __unused *runningOSiOS = @"iOS";
static NSString __unused *runningOSiPadOS = @"iPadOS";

static NSString __unused *filenameExtensionPDF = @"pdf";
static NSString __unused *mimeTypePDF = @"application/pdf";

static NSString __unused *SEBKeyShortcutSideMenu = @"m";
static NSString __unused *SEBKeyShortcutReload = @"r";
static NSString __unused *SEBKeyShortcutFind = @"f";
static NSString __unused *SEBKeyShortcutQuit = @"q";

static unsigned char __unused keyUsageServerAuthentication[8] = {0x2b, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x01};

// The Managed app configuration dictionary pushed down from an MDM server are stored in this key.
static NSString * const kConfigurationKey = @"com.apple.configuration.managed";

// The dictionary that is sent back to the MDM server as feedback must be stored in this key.
static NSString * const kFeedbackKey = @"com.apple.feedback.managed";

static NSInteger SEBMinMacOSVersionSupported = SEBMinOSX10_11;
static NSInteger SEBMinMacOSVersionSupportedMajor = 10;
static NSInteger SEBMinMacOSVersionSupportedMinor = 11;
static NSInteger SEBMinMacOSVersionSupportedPatch = 0;

#endif
