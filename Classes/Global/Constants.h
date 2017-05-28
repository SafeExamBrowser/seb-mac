//
//  Constants.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 29.12.11.
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
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright 
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import "DDLog.h"

#ifndef SafeExamBrowser_Constants_h
#define SafeExamBrowser_Constants_h


#define sebConfigFilePrefixLength               4
#define publicKeyHashLenght                     20


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

#define SEBErrorNoValidConfigData 10
#define SEBErrorNoValidPrefixNoValidUnencryptedHeader 11
#define SEBErrorDecryptingSettingsCanceled 101
#define SEBErrorDecryptingNoSettingsPasswordEntered 102
#define SEBErrorDecryptingSettingsAdminPasswordCanceled 105
#define SEBErrorDecryptingNoAdminPasswordEntered 106
#define SEBErrorDecryptingIdentityNotFound 110
#define SEBErrorParsingSettingsFailedValueClassMissmatch 201
#define SEBErrorParsingSettingsSerializingFailed 205


enum {
    browserUserAgentModeiOSDefault              = 0,
    browserUserAgentModeiOSMacDesktop           = 1,
    browserUserAgentModeiOSCustom               = 2
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
    browserUserAgentModeWinTouchiPad            = 1,
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
    certificateTypeSSLClientCertificate         = 0,
    certificateTypeIdentity                     = 1,
};
typedef NSUInteger certificateTypes;


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
    mobileStatusBarAppearanceNone               = 0,
    mobileStatusBarAppearanceLight              = 1,
    mobileStatusBarAppearanceDark               = 2
};
typedef NSUInteger mobileStatusBarAppearances;


enum {
    getGenerallyBlocked                         = 0,
    openInSameWindow                            = 1,
    openInNewWindow                             = 2
};
typedef NSUInteger newBrowserWindowPolicies;


enum {
    operatingSystemOSX                          = 0,
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
    SEBClientConfigURLSchemeDomain              = 3
};
typedef NSUInteger SEBClientConfigURLSchemes;


enum {
    SEBEnterPasswordCancel                      = 0,
    SEBEnterPasswordOK                          = 1
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
    SEBURLFilterAlertDismiss                      = 0,
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


static NSString __unused *userDefaultsMasala = @"Di𝈭l𝈖Ch𝈒ah𝉇t𝈁a𝉈Hai1972";

// Error numbers for SEB error domains
static NSString __unused *sebErrorDomain = @"org.safeexambrowser.SEB";

static NSString __unused *SEBUserAgentDefaultSuffix = @"SEB";
static NSString __unused *SEBUserAgentDefaultBrowserSuffix = @"Safari";
static NSString __unused *SEBUserAgentDefaultSafariVersion = @"602.4.6";
static NSString __unused *SEBiOSUserAgentDesktopMac = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/602.4.8 (KHTML, like Gecko) Version/10.0.3 Safari/602.4.8";
static NSString __unused *SEBWinUserAgentDesktopDefault = @"Mozilla/5.0 (Windows NT 6.3; rv:41.0) Gecko/20100101 Firefox/41";
static NSString __unused *SEBWinUserAgentTouchDefault = @"Mozilla/5.0 (Windows NT 6.3; rv:41.0; Touch) Gecko/20100101 Firefox/41";
static NSString __unused *SEBWinUserAgentTouchiPad = @"Mozilla/5.0 (iPad; CPU OS 9_0_2 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13A452 Safari/601.1";

static unsigned char __unused keyUsageServerAuthentication[8] = {0x2b, 0x06, 0x01, 0x05, 0x05, 0x07, 0x03, 0x01};

// The Managed app configuration dictionary pushed down from an MDM server are stored in this key.
static NSString * const kConfigurationKey = @"com.apple.configuration.managed";

// The dictionary that is sent back to the MDM server as feedback must be stored in this key.
static NSString * const kFeedbackKey = @"com.apple.feedback.managed";

#endif
