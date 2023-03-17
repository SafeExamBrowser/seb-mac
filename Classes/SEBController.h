//
//  SEBController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.04.10.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

// Main Safe Exam Browser controller class

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <AVFoundation/AVFoundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "PreferencesController.h"
#import "SEBOSXConfigFileController.h"

#import "CapView.h"
#import "CapWindow.h"
#import "CapWindowController.h"
#import "SEBLockedViewController.h"
#import "SEBOSXLockedViewController.h"

#import "AboutWindow.h"
#import "AboutWindowController.h"
#import "SEBOSXBrowserController.h"

#import "SEBBrowserWindow.h"
#import "SEBWebView.h"

#import "SEBDockController.h"
#import "SEBDockItem.h"
#import "SEBDockItemTime.h"
#import "SEBDockItemBattery.h"
#import "SEBBatteryController.h"

#import "SEBEncryptedUserDefaultsController.h"
#import "SEBSystemManager.h"
#import "ProcessListViewController.h"
#import "AssessmentModeManager.h"
#import "HUDController.h"

#import "CocoaLumberjack.h"

#import "ServerController.h"
#import "SEBServerOSXViewController.h"
#import "ServerLogger.h"

#import "SEBZoomController.h"

@class PreferencesController;
@class SEBOSXConfigFileController;
@class SEBSystemManager;
@class ProcessListViewController;
@class SEBDockController;
@class SEBOSXBrowserController;
@class SEBOSXLockedViewController;
@class HUDController;
@class ServerController;
@class SEBServerOSXViewController;
@class SEBBatteryController;
@class SEBZoomController;


@interface SEBController : NSObject <NSApplicationDelegate, SEBLockedViewControllerDelegate, ProcessListViewControllerDelegate, AssessmentModeDelegate, ServerControllerDelegate, ServerLoggerDelegate, SEBDockItemButtonDelegate>
{
    NSArray *runningAppsWhileTerminating;
    NSMutableArray *visibleApps;
    BOOL f3Pressed;
    BOOL firstStart;
    BOOL quittingMyself;
    NSAlert *_modalAlert;
    IBOutlet NSWindow *cmdKeyAlertWindow;
    IBOutlet NSMenuItem *configMenu;
    IBOutlet NSMenu *settingsMenu;
    IBOutlet NSView *passwordView;
    IBOutlet NSPanel *informationHUD;
    IBOutlet NSTextField *informationHUDLabel;
    __weak IBOutlet NSView *inactiveScreenCoverLabel;
    IBOutlet NSWindow *enterPasswordDialogWindow;
    IBOutlet NSTextField *enterPasswordDialog;
    
    IBOutlet NSWindow *enterUsernamePasswordDialogWindow;
    IBOutlet NSTextField *enterUsernamePasswordText;
    __weak IBOutlet NSTextField *usernameTextField;
    __weak IBOutlet NSSecureTextField *passwordSecureTextField;
    id senderModalDelegate;
    SEL senderDidEndSelector;
    
    IBOutlet SEBDockItemTime *sebDockItemTime;
    IBOutlet SEBDockItemBattery *sebDockItemBattery;

	IOPMAssertionID assertionID1;
	IOPMAssertionID assertionID2;
    
    NSRunningApplication *sebInstance;
    NSRunningApplication *launchedApplication;
    
    @private
    BOOL _cmdKeyDown;
    DDFileLogger *_myLogger;
    BOOL _forceAppFolder;
    BOOL enforceMinMacOSVersion;
    pid_t sebPID;
    BOOL allowScreenCapture;
    BOOL allowScreenSharing;
    BOOL allowSiri;
    BOOL allowDictation;
    BOOL allowDictionaryLookup;
    BOOL detectSIGSTOP;
    BOOL screenCapturePermissionsRequested;
    BOOL systemPreferencesOpenedForScreenRecordingPermissions;
    NSString *currentExamStartURL;
    BOOL fontRegistryUIAgentRunning;
    BOOL fontRegistryUIAgentDialogClosed;
    NSUInteger fontRegistryUIAgentSkipDownloadCounter;
    #define logReportCounter 11
    NSUInteger screenSharingLogCounter;
    NSUInteger siriLogCounter;
    NSUInteger dictationLogCounter;
    NSInteger prohibitedProcessesLogCounter;
    NSModalSession lockdownModalSession;
    NSUInteger lastNumberRunningBSDProcesses;
    BOOL checkingRunningProcesses;
    BOOL checkingForWindows;
    NSDate *lastTimeProcessCheck;
    NSDate *timeProcessCheckBeforeSIGSTOP;
    
    CGEventRef keyboardEventReturnKey;
    
    NSImage *ProctoringIconDefaultState;
    NSImage *ProctoringIconAIInactiveState;
    NSImage *ProctoringIconNormalState;
    NSImage *ProctoringIconWarningState;
    NSImage *ProctoringIconErrorState;
    NSColor *ProctoringIconColorNormalState;
    NSColor *ProctoringIconColorWarningState;
    NSColor *ProctoringIconColorErrorState;
    
    CIImage *ProctoringBadgeNormalState;
    CIImage *ProctoringBadgeWarningState;
    CIImage *ProctoringBadgeErrorState;
    
    NSImage *RaisedHandIconDefaultState;
    NSColor *RaisedHandIconColorDefaultState;
    NSImage *RaisedHandIconRaisedState;
    NSColor *RaisedHandIconColorRaisedState;
    
    NSInteger raiseHandUID;
    NSString *raiseHandNotification;
}

- (void) firstDOMElementDeselected;
- (void) lastDOMElementDeselected;

@property(strong, nonatomic) AssessmentModeManager *assessmentModeManager API_AVAILABLE(macos(10.15.4));
@property(strong, nonatomic) IBOutlet PreferencesController *preferencesController;
@property(strong, nonatomic) SEBOSXConfigFileController *configFileController;
@property(strong, nonatomic) IBOutlet SEBSystemManager *systemManager;
@property(strong, nonatomic) SEBBatteryController *batteryController;
@property(strong, nonatomic) SEBDockController *dockController;
@property(strong, nonatomic) SEBOSXBrowserController *browserController;
@property(strong, nonatomic) IBOutlet SEBOSXLockedViewController *sebLockedViewController;
@property(weak, nonatomic) IBOutlet AboutWindow *aboutWindow;
@property(strong, nonatomic) IBOutlet AboutWindowController *aboutWindowController;
@property (strong, nonatomic) WKWebView *temporaryWebView;

#pragma mark - Connecting to SEB Server
// Waiting for user to select exam from SEB Server and to successfully log in
@property(readwrite) BOOL establishingSEBServerConnection;
// Exam URL is opened in a webview (tab), waiting for user to log in
@property(readwrite) BOOL startingExamFromSEBServer;
// User logged in to LMS, monitored client is fully identified now
@property(readwrite) BOOL sebServerConnectionEstablished;
// The SEB Server exam list view is displayed
@property(readwrite) BOOL sebServerViewDisplayed;
@property(readwrite) BOOL sessionRunning;

@property (strong, nonatomic) ServerController *serverController;
@property (strong, nonatomic) NSWindowController *sebServerViewWindowController;
@property (strong, nonatomic) SEBServerOSXViewController *sebServerViewController;

/// Remote Proctoring
#define JitsiMeetProctoringSupported NO
#define ZoomProctoringSupported NO
@property (strong, nonatomic) SEBZoomController *zoomController;

@property(readwrite) BOOL previousSessionZoomEnabled;

@property(readwrite) BOOL zoomReceiveAudio;
@property(readwrite) BOOL zoomReceiveVideo;
@property(readwrite) BOOL zoomSendAudio;
@property(readwrite) BOOL zoomSendVideo;
@property(readwrite) NSUInteger remoteProctoringViewShowPolicy;

@property(readwrite) BOOL zoomUserRetryWasUsed;

- (void) startProctoringWithAttributes:(NSDictionary *)attributes;
- (void) reconfigureWithAttributes:(NSDictionary *)attributes;
- (void) lockSEBWithAttributes:(NSDictionary *)attributes;
- (void) confirmNotificationWithAttributes:(NSDictionary *)attributes;
- (void) toggleProctoringViewVisibility;
//- (BOOL) rtcAudioInputEnabled;
//- (BOOL) rtcAudioReceivingEnabled;
//- (BOOL) rtcVideoSendingEnabled;
//- (BOOL) rtcVideoReceivingEnabled;
//- (BOOL) rtcVideoTrackIsLocal:(RTCVideoTrack *)videoTrack;
//
//- (void) detectFace:(CMSampleBufferRef)sampleBuffer;
//- (RTCVideoFrame *) overlayFrame:(RTCVideoFrame *)frame;

@property(readwrite) BOOL raiseHandRaised;

@property(strong) NSDate *didLockSEBTime;
@property(strong) NSDate *didResignActiveTime;
@property(strong) NSDate *didBecomeActiveTime;
@property(strong) NSDate *didResumeExamTime;
@property(nonatomic, strong) NSMutableArray <NSNumber *> *sebServerPendingLockscreenEvents;

@property(readwrite) BOOL isAACEnabled;
@property(readwrite) BOOL overrideAAC;
@property(readwrite) BOOL wasAACEnabled;
@property(readwrite) BOOL allowSwitchToApplications;

@property(readwrite) BOOL reOpenedExamDetected;
@property(readwrite) BOOL userSwitchDetected;
@property(readwrite) BOOL screenSharingDetected;
@property(readwrite) BOOL screenSharingCheckOverride;
@property(readwrite) BOOL processesDetected;
@property(readwrite) BOOL processCheckSpecificOverride;
@property(readwrite) BOOL processCheckAllOverride;
@property(readwrite) BOOL siriDetected;
@property(readwrite) BOOL siriCheckOverride;
@property(readwrite) BOOL dictationCheckOverride;
@property(readwrite) BOOL dictationDetected;
@property(readwrite) BOOL SIGSTOPDetected;
@property(readwrite) BOOL noRequiredBuiltInScreenAvailable;
@property(readwrite) BOOL builtinDisplayNotAvailableDetected;
@property(readwrite) BOOL builtinDisplayEnforceOverride;
@property(readwrite) BOOL touchBarDetected;
@property(readwrite) BOOL proctoringFailedDetected;

@property(readwrite) BOOL f3Pressed;
@property(readwrite) BOOL alternateKeyPressed;
@property(readwrite) BOOL tabPressedWhileDockIsKeyWindow;
@property(readwrite) BOOL tabPressedWhileWebViewIsFirstResponder;
@property(readwrite) BOOL shiftTabPressedWhileDockIsKeyWindow;
@property(readwrite) BOOL shiftTabPressedWhileWebViewIsFirstResponder;
@property(readwrite) BOOL startingUp;
@property(readwrite) BOOL openedURL;
@property(readwrite) BOOL restarting;
@property(readwrite) BOOL openingSettings;
@property(readwrite) BOOL conditionalInitAfterProcessesChecked;
@property(readonly) BOOL examSession;
@property(readonly) BOOL secureClientSession;
@property(readwrite) BOOL quittingMyself;
@property(readwrite) BOOL isTerminating;
@property(strong) NSURL *openingSettingsFileURL;

@property(strong) NSMutableArray *capWindows;
@property(strong) NSMutableArray *lockdownWindows;
@property(strong) NSMutableArray *inactiveScreenWindows;
@property(strong) NSScreen *mainScreen;
@property(strong, atomic) NSMutableArray *modalAlertWindows;
@property(strong, nonatomic) HUDController *hudController ;
@property(strong) IBOutlet NSSecureTextField *enterPassword;

@property(strong, nonatomic) NSTimer *windowWatchTimer;
@property(readwrite, nonatomic) dispatch_source_t processWatchTimer;
@property(strong, atomic) NSArray <NSDictionary*> *runningProcesses;
@property(strong, nonatomic) ProcessListViewController *processListViewController;
@property(strong, nonatomic) NSWindowController *runningProcessesListWindowController;

@property(strong, nonatomic) NSMutableArray *systemProcessPIDs;
@property(strong, nonatomic) NSMutableArray *runningProhibitedProcesses;
@property(strong, nonatomic) NSMutableSet *terminatedProcessesExecutableURLs;
@property(strong, nonatomic) NSMutableArray *overriddenProhibitedProcesses;

@property(strong, nonatomic) SEBDockItemButton *dockButtonReload;
@property(strong, nonatomic) SEBDockItemButton *dockButtonBattery;
@property(strong, nonatomic) SEBDockItemButton *dockButtonProctoringView;
@property(strong, nonatomic) SEBDockItemButton *dockButtonRaiseHand;
@property (weak) IBOutlet NSWindow *enterRaiseHandMessageWindow;
@property (weak) IBOutlet NSTextField *raiseHandMessageTextField;

- (void)storeNewSEBSettings:(NSData *)sebData
            forEditing:(BOOL)forEditing
forceConfiguringClient:(BOOL)forceConfiguringClient
 showReconfiguredAlert:(BOOL)showReconfiguredAlert
              callback:(id)callback
                   selector:(SEL)selector;
- (void) didOpenSettings;

- (NSAlert *) newAlert;
- (void) removeAlertWindow:(NSWindow *)alertWindow;
- (void) runModalAlert:(NSAlert *)alert
conditionallyForWindow:(NSWindow *)window
     completionHandler:(void (^)(NSModalResponse returnCode))handler;

- (void) closeAboutWindow;
- (void) closeDocument:(id)sender;
- (void) coverScreens;
- (void) coverInactiveScreens:(NSArray *)inactiveScreens;
- (void) adjustScreenLocking:(id)sender;
- (void) startTask;
- (void) regainActiveStatus:(id)sender;
- (void) SEBgotActive:(id)sender;
- (void) startKioskMode;

- (NSRect) visibleFrameForScreen:(NSScreen *)screen;

- (NSModalResponse) showEnterPasswordDialog:(NSString *)text
                       modalForWindow:(NSWindow *)window
                          windowTitle:(NSString *)title;
- (NSModalResponse) showEnterPasswordDialogAttributedText:(NSAttributedString *)text
                                     modalForWindow:(NSWindow *)window
                                        windowTitle:(NSString *)title;

- (IBAction) okEnterPassword: (id)sender;
- (IBAction) cancelEnterPassword: (id)sender;

- (void) showEnterUsernamePasswordDialog:(NSAttributedString *)text
                          modalForWindow:(NSWindow *)window
                             windowTitle:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector;
- (void) hideEnterUsernamePasswordDialog;

- (IBAction) requestedQuit:(id)sender;

- (IBAction) openPreferences:(id)sender;
- (IBAction) showAbout:(id)sender;
- (IBAction) showHelp:(id)sender;

@property(readwrite, nonatomic) BOOL reloadButtonEnabled;
@property(strong, nonatomic) ReloadPageUIElement *reloadPageUIElement;

- (IBAction) searchText:(id)sender;
- (IBAction) searchTextNext:(id)sender;
- (IBAction) searchTextPrevious:(id)sender;

- (void) requestedRestart:(NSNotification *)notification;

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender;

- (BOOL) conditionallyLockExam:(NSString *)examURLString;

- (void) correctPasswordEntered;
- (void) closeLockdownWindowsAllowOverride:(BOOL)allowOverride;
- (void) openInfoHUD:(NSString *)lockedTimeInfo;

- (void) requestedExit:(NSNotification *)notification;

@end
