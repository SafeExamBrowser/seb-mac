//
//  SEBViewController.h
//
//  Created by Daniel R. Schneider on 10/09/15.
//  Copyright (c) 2010-2020 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2020 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


/**
 * @protocol    SEBConfigURLManagerDelegate
 *
 * @brief       All SEB config URL managers must conform to
 *              the SEBConfigURLDelegate protocol.
 */
@protocol SEBConfigURLManagerDelegate <NSObject>
/**
 * @name		Item Attributes
 */
@required

/**
 * @brief       Evaluate an entered string, derive a SEB config URL and act on result.
 * @details
 */
- (void)evaluateEnteredURLString:(NSString *)inputURLString;

@end


#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#import "RNCryptor.h"
#import "SEBCryptor.h"

#import "SEBRootViewController.h"
#import "LGSideMenuController.h"

#import "IASKAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "SEBIASKSecureSettingsStore.h"
#import "SEBInAppSettingsViewController.h"

#import "SEBUIController.h"
#import "SEBSliderItem.h"
#import "SEBNavigationController.h"

#import "SEBInitAssistantViewController.h"
#import "SEBiOSInitAssistantViewController.h"

#import "SEBiOSLockedViewController.h"
#import "SEBiOSConfigFileController.h"
#import "QRCodeReaderViewController.h"
#import "AboutSEBiOSViewController.h"

#import "SEBBrowserController.h"
#import "SEBBrowserTabViewController.h"
#import "SEBSearchBarViewController.h"

#import "ServerController.h"
#import "SEBServerViewController.h"
#import "ServerLogger.h"

#import "RTCVideoTrack.h"
#import "RTCVideoFrame.h"
#import "RTCCVPixelBuffer.h"

@class AppDelegate;
@class SEBUIController;
@class SEBBrowserController;
@class SEBBrowserTabViewController;
@class SEBSearchBarViewController;
@class SEBiOSConfigFileController;
@class SEBInAppSettingsViewController;
@class SEBInitAssistantViewController;
@class SEBiOSInitAssistantViewController;
@class SEBiOSLockedViewController;
@class QRCodeReaderViewController;
@class AboutSEBiOSViewController;
@class ServerController;
@class SEBServerViewController;
@class RTCVideoTrack;
@class RTCVideoFrame;

@interface SEBViewController : UIViewController <IASKSettingsDelegate, SEBLockedViewControllerDelegate, QRCodeReaderDelegate, LGSideMenuDelegate, SEBBrowserControllerDelegate, NSURLSessionDelegate, ProctoringImageAnayzerDelegate>
{
    UIBarButtonItem *leftButton;
    UIBarButtonItem *settingsShareButton;
    UIBarButtonItem *settingsActionButton;

@private
    NSInteger attempts;
    BOOL adminPasswordPlaceholder;
    BOOL quitPasswordPlaceholder;
    BOOL ASAMActiveChecked;
    BOOL sebUIInitialized;
    DDFileLogger *_myLogger;

    NSURL *currentConfigPath;
    NSURL *directlyDownloadedURL;
    
    NSDictionary *receivedServerConfig;

    NSString *currentStartURL;
    NSString *startURLQueryParameter;

    NSUInteger statusBarAppearance;
    UIBarButtonItem *toolbarBackButton;
    UIBarButtonItem *toolbarForwardButton;
    UIBarButtonItem *toolbarReloadButton;
    CGFloat navigationBarItemsOffset;
    
}

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (weak) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerTopContraint;
@property (copy) NSURLRequest *request;

@property (strong, nonatomic) UIViewController *topMostController;
@property (strong, nonatomic) SEBBrowserController *browserController;
@property (strong, nonatomic) SEBBrowserTabViewController *browserTabViewController;
@property (strong, nonatomic) SEBUIController *sebUIController;
//@property (nonatomic, strong) SEBiOSDockController *dockController;
@property (strong, nonatomic) SEBSearchBarViewController *searchBarViewController;

@property (strong, nonatomic) SEBiOSInitAssistantViewController *assistantViewController;

@property (strong, nonatomic) AboutSEBiOSViewController *aboutSEBViewController;
@property (strong, nonatomic) MFMailComposeViewController *mailViewController;
@property (strong, nonatomic) UIViewController *rootViewController;
@property (strong, nonatomic) SEBiOSConfigFileController *configFileController;

/// Locking down SEB
@property (strong, nonatomic) SEBiOSLockedViewController *sebLockedViewController;
@property (readwrite) BOOL sebLocked;
@property (readwrite) BOOL unlockPasswordEntered;
@property (readwrite, strong) NSDate *didLockSEBTime;
@property (readwrite, strong) NSDate *didResignActiveTime;
@property (readwrite, strong) NSDate *didBecomeActiveTime;
@property (readwrite, strong) NSDate *didResumeExamTime;
@property (readwrite, strong) NSDate *appDidEnterBackgroundTime;
@property (readwrite, strong) NSDate *appDidBecomeActiveTime;

/// Settings
@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;
@property (nonatomic, retain) SEBInAppSettingsViewController *sebInAppSettingsViewController;
@property (strong, nonatomic) NSData *configFileKeyHash;

@property (strong, nonatomic) QRCodeReaderViewController *codeReaderViewController;
@property (strong, nonatomic) QRCodeReaderViewController *visibleCodeReaderViewController;

@property (nonatomic, strong) id <SEBConfigURLManagerDelegate> configURLManagerDelegate;

/// SEB Server
@property (strong, nonatomic) ServerController *serverController;
@property (strong, nonatomic) SEBServerViewController *sebServerViewController;

/// Remote Proctoring
@property (strong, nonatomic) JitsiViewController *jitsiViewController;
@property (strong, nonatomic) ProctoringImageAnalyzer *proctoringImageAnalyzer API_AVAILABLE(ios(11));
@property (readwrite) UIInterfaceOrientation userInterfaceOrientation;
@property (strong, atomic) NSMutableArray<RTCVideoTrack *> *allRTCTracks;
@property (strong, atomic) NSMutableArray<RTCVideoTrack *> *localRTCTracks;
@property (strong, nonatomic) CIContext *ciContext;
@property (strong, nonatomic) CIImage *proctoringStateIcon;

@property(readwrite) BOOL previousSessionJitsiMeetEnabled;

@property(readwrite) BOOL jitsiMeetReceiveAudio;
@property(readwrite) BOOL jitsiMeetReceiveVideo;
@property(readwrite) BOOL jitsiMeetSendAudio;
@property(readwrite) BOOL jitsiMeetSendVideo;

- (void) startProctoringWithAttributes:(NSDictionary *)attributes;
- (void) toggleProctoringViewVisibility;
- (BOOL) rtcAudioInputEnabled;
- (BOOL) rtcAudioReceivingEnabled;
- (BOOL) rtcVideoSendingEnabled;
- (BOOL) rtcVideoReceivingEnabled;
- (BOOL) rtcVideoTrackIsLocal:(RTCVideoTrack *)videoTrack;

- (void) detectFace:(CMSampleBufferRef)sampleBuffer;
- (RTCVideoFrame *) overlayFrame:(RTCVideoFrame *)frame;

/// Views and bars
@property (strong, nonatomic) UIAlertController *alertController;
@property (strong, nonatomic) UIAlertController *inactiveAlertController;
@property (strong, nonatomic) UIAlertController *allowediOSAlertController;

@property (strong, nonatomic) UIView *coveringView;
@property (strong, nonatomic) UIView *statusBarView;
@property (strong, nonatomic) UIView *navigationBarView;
@property (strong, nonatomic) UIView *toolBarView;
@property (strong, nonatomic) UIView *bottomBackgroundView;
@property (strong, nonatomic) NSArray *dockItems;

@property (strong, nonatomic) NSLayoutConstraint *statusBarBottomConstraint;
@property (strong, nonatomic) NSLayoutConstraint *toolBarHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *navigationBarHeightConstraint;
@property (strong, nonatomic) NSLayoutConstraint *navigationBarBottomConstraint;
@property (strong, nonatomic) NSLayoutConstraint *navigationBarLeftConstraintToSafeArea;
@property (strong, nonatomic) NSLayoutConstraint *navigationBarLeftConstraintToSuperView;

@property(readwrite) BOOL secureMode;
@property(readwrite) BOOL enableASAM;
@property(readwrite) BOOL allowSAM;

// Flags for managing states for kiosk modes
@property(readwrite) BOOL ASAMActive;
@property(readwrite) BOOL SAMActive;
@property(readwrite) BOOL singleAppModeActivated;
@property(readwrite) BOOL noSAMAlertDisplayed;
@property(readwrite) BOOL startSAMWAlertDisplayed;
@property(readwrite) BOOL pausedSAMAlertDisplayed;
@property(readwrite) BOOL endSAMWAlertDisplayed;
@property(readwrite) BOOL clientConfigSecureModePaused;

@property(readwrite) BOOL examSessionClearCookiesOnEnd;

@property(readwrite) BOOL finishedStartingUp;
@property(readwrite) BOOL didReceiveMDMConfig;
@property(readwrite) BOOL isReconfiguringToMDMConfig;
@property(readwrite) BOOL openCloseSlider;
@property(readwrite) BOOL viewDidLayoutSubviewsAlreadyCalled;
@property(readwrite) BOOL restartSessionAlertDisplayed;
@property(readwrite) BOOL aboutSEBViewDisplayed;
@property(readwrite) BOOL examRunning;
@property(readwrite) BOOL initAssistantOpen;
@property(readwrite) BOOL settingsOpen;
@property(readwrite) BOOL settingsDidClose;
@property(readwrite) BOOL scannedQRCode;


- (void) initializeLogger;
- (void) sendLogEventWithLogLevel:(NSUInteger)logLevel
                        timestamp: (NSString *)timestamp
                     numericValue:(double)numericValue
                          message:(NSString *)message;

- (BOOL) allowediOSVersion;
- (void) newWebViewTabDidMoveToParentViewController;

- (BOOL) handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem;

- (void) showConfigURLWarning:(NSError *)error;
- (void) scanQRCode;

#pragma mark - Init, reconfigure and reset SEB
- (void) conditionallyShowSettingsModal;
- (void) conditionallyResetSettings;
- (void) settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender;

- (void) showReconfiguringAlertWithError:(NSError *)error;

- (void) showStartSingleAppMode;

#pragma mark - Start and quit exam session
- (void) startExam;
- (void) quitExamConditionally;
- (void) sessionQuitRestart:(BOOL)restart;
- (void) quitExamWithCallback:(id)callback selector:(SEL)selector;

#pragma mark - Connecting to SEB Server
@property(readwrite) BOOL establishingSEBServerConnection;
@property(readwrite) BOOL startingExamFromSEBServer;
@property(readwrite) BOOL sebServerConnectionEstablished;
@property(readwrite) BOOL sebServerViewDisplayed;
- (void) didSelectExamWithExamId:(NSString *)examId url:(NSString *)url;
- (void) closeServerView:(id)sender;
- (void) loginToExam:(NSString *)url;
- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies;
- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url;
- (void) didEstablishSEBServerConnection;

#pragma mark - Kiosk mode
- (void) stopAutonomousSingleAppMode;

#pragma mark - Lockdown windows
- (void) conditionallyOpenStartExamLockdownWindows;
- (BOOL) conditionallyOpenSleepModeLockdownWindows;
- (void) openLockdownWindows;

- (void) closeSettingsBeforeOpeningSEBConfig:(id)sebConfig
                                    callback:(id)callback
                                    selector:(SEL)selector;
- (void) conditionallyDownloadAndOpenSEBConfigFromURL:(NSURL *)url;
- (void) conditionallyOpenSEBConfigFromData:(NSData *)sebConfigData;
- (void) conditionallyOpenSEBConfigFromUniversalLink:(NSURL *)universalURL;
- (void) conditionallyOpenSEBConfigFromMDMServer:(NSDictionary *)serverConfig;
- (void) resetReceivedServerConfig;

- (void) storeSEBSettingsDownloadedDirectlySuccessful:(NSError *)error;
- (void) storeNewSEBSettings:(NSData *)sebData;
- (void) storeNewSEBSettingsSuccessful:(NSError *)error;

- (void) showToolbarNavigation:(BOOL)show;
- (void) setToolbarTitle:(NSString *)title;

#pragma mark - SEB Dock and left slider button handler
- (void) leftDrawerButtonPress:(id)sender;
- (void) leftDrawerKeyShortcutPress:(id)sender;
- (void) showAboutSEB;
- (IBAction) toggleScrollLock;
- (void) updateScrollLockButtonStates;
@property (readonly) BOOL isScrollLockActive;
- (IBAction) backToStart;
- (IBAction) goBack;
- (IBAction) goForward;
- (IBAction) reload;

- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward;
- (void) activateReloadButtonsExamTab:(BOOL)examTab;
- (void) activateReloadButtons:(BOOL)reloadEnabled;

- (void) alertWithTitle:(NSString *)title
                message:(NSString *)message
           action1Title:(NSString *)action1Title
         action1Handler:(void (^)(void))action1Handler
           action2Title:(NSString *)action2Title
         action2Handler:(void (^)(void))action2Handler;

- (void) alertWithTitle:(NSString *)title
                message:(NSString *)message
         preferredStyle:(UIAlertControllerStyle)controllerStyle
           action1Title:(NSString *)action1Title
           action1Style:(UIAlertActionStyle)action1Style
         action1Handler:(void (^)(void))action1Handler
           action2Title:(NSString *)action2Title
           action2Style:(UIAlertActionStyle)action2Style
         action2Handler:(void (^)(void))action2Handler;

// Delegate method to display an enter password dialog with the
// passed message text asynchronously, calling the callback
// method with the entered password when one was entered
- (void) showEnterUsernamePasswordDialog:(NSString *)text
                                   title:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector;
// Delegate method to hide the previously displayed enter password dialog
- (void) hideEnterUsernamePasswordDialog;
- (UIViewController *) topMostController;

@end

