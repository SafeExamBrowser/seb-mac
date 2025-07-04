//
//  SEBController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.04.10.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#include <Carbon/Carbon.h>
#import "SEBController.h"

#import <IOKit/pwr_mgt/IOPMLib.h>

#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>

#include <mach/mach_port.h>
#include <mach/mach_interface.h>
#include <mach/mach_init.h>

#import <sys/sysctl.h>
#import <sys/mount.h>
#import <sys/stat.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

#import <objc/runtime.h>

#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/IOMessage.h>

#include <signal.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <libproc.h>
#include <assert.h>
#include <sys/sysctl.h>
#include <CoreGraphics/CGDirectDisplay.h>
#import "CGSPrivate.h"

#import "PrefsBrowserViewController.h"
#import "SEBBrowserController.h"
#import "SEBURLFilter.h"

#import "RNDecryptor.h"
#import "SEBKeychainManager.h"
#import "SEBCryptor.h"
#import "SEBCertServices.h"
#import "NSData+NSDataZIPExtension.h"
#import "NSScreen+SEBScreen.h"
#import "NSWindow+SEBWindow.h"
#import "SEBConfigFileManager.h"
#import "NSRunningApplication+SEB.h"
#import "ProcessManager.h"

#import "SEBDockItemMenu.h"
#import "SEBGoToDockButton.h"

#import "SEBWindowSizeValueTransformer.h"
#import "BoolValueTransformer.h"
#import "IsEmptyCollectionValueTransformer.h"
#import "NSTextFieldNilToEmptyStringTransformer.h"

#include <SystemConfiguration/SystemConfiguration.h>

#import "SEBUIUserDefaultsController.h"


@interface NSArray (ProcessArray)

- (NSArray *)containsProcessObject: (NSString *)processName;

@end

@implementation NSArray (ProcessArray)

- (NSArray *)containsProcessObject: (NSString *)processName
{
    NSPredicate *filterProcessName = [NSPredicate predicateWithFormat:@"name ==[cd] %@ ", processName];
    NSArray *foundProcesses = [self filteredArrayUsingPredicate:filterProcessName];
    return foundProcesses.count > 0 ? foundProcesses : nil;
}

@end


io_connect_t  root_port; // a reference to the Root Power Domain IOService

void MySleepCallBack(void * refCon, io_service_t service, natural_t messageType, void * messageArgument);
bool insideMatrix(void);


#pragma mark -

@implementation SEBController


#pragma mark - Properties and Accessors

@synthesize f3Pressed;	//create getter and setter for F3 key pressed flag
@synthesize quittingMyself;	//create getter and setter for flag that SEB is quitting itself
@synthesize quittingSession;
@synthesize capWindows;
@synthesize lockdownWindows;

- (NSString *)accessibilityMessageString {
    return [NSString stringWithFormat:NSLocalizedString(@"%@ needs Accessibility permissions to read the title of the active (frontmost) window of any app for screen proctoring. %@ is using these Accessiblilty permissions ONLY during screen proctoring sessions. Grant access to %@ in System Settings / Security & Privacy / Accessibility.", @""), SEBShortAppName, SEBShortAppName, SEBFullAppNameClassic];
}

- (NSString *)privacyFilesFoldersMessageString {
    return [NSString stringWithFormat:NSLocalizedString(@"Grant access in System Settings / Privacy & Security / Files & Folders / %@.", @""), SEBFullAppNameClassic];
}

- (SEBOSXSessionState *) sessionState
{
    if (!_sessionState) {
        _sessionState = [[SEBOSXSessionState alloc] init];
    }
    return _sessionState;
}


- (AssessmentConfigurationManager *) assessmentConfigurationManager
{
    if (!_assessmentConfigurationManager) {
        _assessmentConfigurationManager = [AssessmentConfigurationManager new];
    }
    return _assessmentConfigurationManager;
}


- (SEBFileManager *) sebFileManager
{
    if (!_sebFileManager) {
        _sebFileManager = [[SEBFileManager alloc] init];
    }
    return _sebFileManager;
}


- (SEBOSXConfigFileController *) configFileController
{
    if (!_configFileController) {
        _configFileController = [[SEBOSXConfigFileController alloc] init];
        _configFileController.sebController = self;
    }
    return _configFileController;
}


- (SEBOSXBrowserController *) browserController
{
    if (!_browserController) {
        _browserController = [[SEBOSXBrowserController alloc] init];
        _browserController.sebController = self;
    }
    return _browserController;
}


- (ProcessListViewController *) processListViewController
{
    if (!_processListViewController) {
        _processListViewController = [[ProcessListViewController alloc] initWithNibName:@"ProcessListView" bundle:nil];
        _processListViewController.delegate = self;
    }
    return _processListViewController;
}


- (SEBBatteryController *) batteryController
{
    if (!_batteryController) {
        _batteryController = [[SEBBatteryController alloc] init];
    }
    return _batteryController;
}


- (AboutWindowController *) aboutWindowController
{
    if (!_aboutWindowController) {
        _aboutWindowController = [[AboutWindowController alloc] initWithWindow:_aboutWindow];
    }
    return _aboutWindowController;
}


- (HUDController *) hudController
{
    if (!_hudController) {
        _hudController = [[HUDController alloc] init];
    }
    return _hudController;
}


- (SEBOSXLockedViewController*)sebLockedViewController
{
    _sebLockedViewController.sebController = self;
    return _sebLockedViewController;
}


- (ServerController *)serverController
{
    if (!_serverController) {
        _serverController = [[ServerController alloc] init];
        _serverController.delegate = self;
    }
    return _serverController;
}


- (SEBScreenProctoringController *)screenProctoringController
{
    if (!_screenProctoringController) {
        _screenProctoringController = [[SEBScreenProctoringController alloc] init];
        _screenProctoringController.delegate = self;
        _screenProctoringController.spsControllerUIDelegate = self;
    }
    return _screenProctoringController;
}


- (TransmittingCachedScreenShotsViewController *) transmittingCachedScreenShotsViewController
{
    if (!_transmittingCachedScreenShotsViewController) {
        _transmittingCachedScreenShotsViewController = [[TransmittingCachedScreenShotsViewController alloc] initWithNibName:@"TransmittingCachedScreenShotsView" bundle:nil];
        _transmittingCachedScreenShotsViewController.uiDelegate = self;
    }
    return _transmittingCachedScreenShotsViewController;
}


- (SEBZoomController *)zoomController
{
    if (!_zoomController) {
        _zoomController = [[SEBZoomController alloc] init];
//        _zoomController.proctoringUIDelegate = self;
    }
    return _zoomController;
}


#pragma mark - Class and Instance Initialization

+ (void) initialize
{
    [[MyGlobals sharedMyGlobals] setFinishedInitializing:NO];
    [[MyGlobals sharedMyGlobals] setStartKioskChangedPresentationOptions:NO];
    [[MyGlobals sharedMyGlobals] setLogLevel:DDLogLevelDebug];
    
    SEBWindowSizeValueTransformer *windowSizeTransformer = [[SEBWindowSizeValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:windowSizeTransformer
                                    forName:@"SEBWindowSizeTransformer"];
    
    BoolValueTransformer *boolValueTransformer = [[BoolValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:boolValueTransformer
                                    forName:@"BoolValueTransformer"];
    
    IsEmptyCollectionValueTransformer *isEmptyCollectionValueTransformer = [[IsEmptyCollectionValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:isEmptyCollectionValueTransformer
                                    forName:@"isEmptyCollectionValueTransformer"];
    
    NSTextFieldNilToEmptyStringTransformer *textFieldNilToEmptyStringTransformer = [[NSTextFieldNilToEmptyStringTransformer alloc] init];
    [NSValueTransformer setValueTransformer:textFieldNilToEmptyStringTransformer
                                    forName:@"NSTextFieldNilToEmptyStringTransformer"];
}


- (id)init {
    self = [super init];
    if (self) {
        // Get SEB's PID
        NSRunningApplication *sebRunningApp = [NSRunningApplication currentApplication];
        sebPID = [sebRunningApp processIdentifier];

        _modalAlertWindows = [NSMutableArray new];
        _startingUp = true;
        self.systemManager = [[SEBSystemManager alloc] init];
        
        // Initialize console loggers
#ifdef DEBUG
        // We show log messages only in Console.app and the Xcode console in debug mode
        [DDLog addLogger:[DDOSLogger sharedInstance]];
#endif
        
        // Initialize a temporary logger unconditionally with the Debug log level
        // and the standard log file path, so SEB can log startup events before
        // settings are initialized
        [self initializeTemporaryLogger];
        
        [[MyGlobals sharedMyGlobals] setPreferencesReset:NO];
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
        [MyGlobals sharedMyGlobals].reconfiguredWhileStarting = NO;
        
        if (!_inactiveScreenWindows) {
            _inactiveScreenWindows = [NSMutableArray new];
        }
        
        // Add an observer for the request to unconditionally exit SEB
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(requestedExit:)
                                                     name:@"requestExitNotification" object:nil];
        
        
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        // Set default preferences for the case there are no user prefs yet
        // and set flag for displaying alert to new users
        firstStart = [preferences setSEBDefaults];
        
        // Check if there is a SebClientSettings.seb file saved in the preferences directory
        [self.configFileController reconfigureClientWithSebClientSettings];
        
        // Initialize file logger if it's enabled in client (!) settings,
        // from this point on settings for log level and directory are considered
        [self initializeLogger];
        
        // Get default WebKit browser User Agent and create
        // default SEB User Agent
        _temporaryWebView = [WKWebView new];
        [_temporaryWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(NSString *defaultUserAgent, NSError * _Nullable error) {
            [SEBBrowserController createSEBUserAgentFromDefaultAgent:defaultUserAgent];
            self.temporaryWebView = nil;
            DDLogInfo(@"Default browser user agent string: %@", [[MyGlobals sharedMyGlobals] valueForKey:@"defaultUserAgent"]);
        }];

        // Cache current settings for Siri and dictation
        [_systemManager cacheCurrentSystemSettings];

        // Regardless if switching to third party applications is allowed in current settings,
        // we need to first open the background cover windows with standard window levels
        [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];

        _reloadPageUIElement = [ReloadPageUIElement new];
    }
    return self;
}


#pragma mark - Initialization When UI Is Available

- (void)awakeFromNib
{
    DDLogDebug(@"%s", __FUNCTION__);
    
//    NSApplicationPresentationOptions presentationOptions = (NSApplicationPresentationDisableForceQuit + NSApplicationPresentationHideDock);
//    DDLogDebug(@"NSApp setPresentationOptions: %lo", presentationOptions);
//    [NSApp setPresentationOptions:presentationOptions];

    // Flag initializing
    quittingMyself = false; //flag to know if quit application was called externally
    
    // Terminate invisibly running applications
    if ([NSRunningApplication respondsToSelector:@selector(terminateAutomaticallyTerminableApplications)]) {
        [NSRunningApplication terminateAutomaticallyTerminableApplications];
    }
    
    // Save the bundle ID of all currently running apps which are visible in a array
    NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    NSRunningApplication *iterApp;
    visibleApps = [NSMutableArray array]; //array for storing bundleIDs of visible apps
    
    for (iterApp in runningApps) {
        BOOL isHidden = [iterApp isHidden];
        NSString *appBundleID = [iterApp valueForKey:@"bundleIdentifier"];
        DDLogInfo(@"Running app: %@, bundle ID: %@", iterApp.localizedName, appBundleID);
        if ((appBundleID != nil) & !isHidden) {
            [visibleApps addObject:appBundleID]; //add ID of the visible app
        }
        if ([iterApp ownsMenuBar]) {
            DDLogDebug(@"App %@ owns menu bar", iterApp);
        }
    }
    
    [[ProcessManager sharedProcessManager] updateMonitoredProcesses];
    
    /// Setup Notifications
    
    // Add an observer for the notification that another application became active (SEB got inactive)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(regainActiveStatus:)
                                                 name:NSApplicationDidResignActiveNotification
                                               object:NSApp];
    
    //#ifndef DEBUG
    // Add an observer for the notification that another application was unhidden by the finder
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    [[workspace notificationCenter] addObserver:self
                                       selector:@selector(regainActiveStatus:)
                                           name:NSWorkspaceDidActivateApplicationNotification
                                         object:nil];
    
    // Add an observer for the notification that another application was unhidden by the finder
    [[workspace notificationCenter] addObserver:self
                                       selector:@selector(regainActiveStatus:)
                                           name:NSWorkspaceDidUnhideApplicationNotification
                                         object:nil];
    
    // Add an observer for the notification that another application was unhidden by the finder
    //    [[workspace notificationCenter] addObserver:self
    //                                       selector:@selector(regainActiveStatus:)
    //                                           name:NSWorkspaceWillLaunchApplicationNotification
    //                                         object:nil];
    //
    // Add an observer for the notification that another application was launched
    [[workspace notificationCenter] addObserver:self
                                       selector:@selector(appLaunch:)
                                           name:NSWorkspaceDidLaunchApplicationNotification
                                         object:nil];
    
    // Add key/value observing for any new application/process being run
    // also background apps or for apps that have the LSUIElement key in their Info.plist file
    static const void *kMyKVOContext = (void*)&kMyKVOContext;

    [[NSWorkspace sharedWorkspace] addObserver:self
                                    forKeyPath:@"runningApplications"
                                       options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                       context:NULL];
    
    [[NSWorkspace sharedWorkspace] addObserver:self
                                    forKeyPath:@"isTerminated"
                                       options:NSKeyValueObservingOptionNew // maybe | NSKeyValueObservingOptionInitial
                                       context:NULL];
    
    // Add an observer for the notification that another application was unhidden by the finder
    [[workspace notificationCenter] addObserver:self
                                       selector:@selector(spaceSwitch:)
                                           name:NSWorkspaceActiveSpaceDidChangeNotification
                                         object:nil];
    
    //#endif
    // Add an observer for the notification that SEB became active
    // With third party apps and Flash fullscreen it can happen that SEB looses its
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SEBgotActive:)
                                                 name:NSApplicationDidBecomeActiveNotification
                                               object:NSApp];
    
    // Add an observer for changes of the Presentation Options
    [NSApp addObserver:self
            forKeyPath:@"currentSystemPresentationOptions"
               options:NSKeyValueObservingOptionNew
               context:NULL];
    
    sebInstance = [NSRunningApplication currentApplication];
    
    [sebInstance addObserver:self
                  forKeyPath:@"isActive"
                     options:NSKeyValueObservingOptionNew
                     context:NULL];
    
    // Add a observer for changes of the screen configuration
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(adjustScreenLocking:)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:NSApp];
    
    // Add a observer for notification that the main browser window changed screen
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeMainScreen:)
                                                 name:@"mainScreenChanged" object:nil];
    
    // Add an observer for the request to conditionally exit SEB
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestedQuit:)
                                                 name:@"requestQuitNotification" object:nil];
    
    // Add an observer for the request to conditionally quit SEB with asking quit password
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(quitLinkDetected:)
                                                 name:@"quitLinkDetected" object:nil];
    
    // Add an observer for the request to reload start URL
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestedRestart:)
                                                 name:@"requestRestartNotification" object:nil];
    
    // Add an observer for the request to quit SEB or session unconditionally
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(quitSEBOrSession)
                                                 name:@"requestQuitSEBOrSession" object:nil];
    
    // Add an observer for the request to start the kiosk mode
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startKioskMode)
                                                 name:@"requestStartKioskMode" object:nil];
    
    // Add an observer for the request to reinforce the kiosk mode
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestedReinforceKioskMode:)
                                                 name:@"requestReinforceKioskMode" object:nil];
    
    // Add an observer for the request to show about panel
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestedShowAbout:)
                                                 name:@"requestShowAboutNotification" object:nil];
    
    // Add an observer for the request to close about panel
    [[NSNotificationCenter defaultCenter] addObserver:self.aboutWindowController
                                             selector:@selector(closeAboutWindow:)
                                                 name:@"requestCloseAboutWindowNotification" object:nil];
    
    // Add an observer for the request to show help
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestedShowHelp:)
                                                 name:@"requestShowHelpNotification" object:nil];
    
    // Add an observer for the notification that preferences were closed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferencesClosed:)
                                                 name:@"preferencesClosed" object:nil];
    
    // Add an observer for the notification that preferences were closed and SEB should be restarted
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferencesClosedRestartSEB:)
                                                 name:@"preferencesClosedRestartSEB" object:nil];
    // Add an observer for the notification that a previously interrupted exam was re-opened
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockSEB:)
                                                 name:@"detectedReOpeningExam" object:nil];
    // Add an observer for the notification that a screen sharing session become active
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockSEB:)
                                                 name:@"detectedScreenSharing" object:nil];
    // Add an observer for the notification that Siri was invoked
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockSEB:)
                                                 name:@"detectedSiri" object:nil];
    // Add an observer for the notification that dictation was invoked
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockSEB:)
                                                 name:@"detectedDictation" object:nil];
    // Add an observer for the notification that a prohibited process was started
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockSEB:)
                                                 name:@"detectedProhibitedProcess" object:nil];
    // Add an observer for the notification that a previously interrupted exam was re-opened
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockSEB:)
                                                 name:@"detectedSIGSTOP" object:nil];
    // Add an observer for the notification that a there is no required built-in display available
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockSEB:)
                                                 name:@"detectedRequiredBuiltinDisplayMissing" object:nil];
    // Add an observer for the notification that proctoring failed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockSEB:)
                                                 name:@"proctoringFailed" object:nil];
    // Add an observer for the notification when SEB is locked by SEB Server
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockSEB:)
                                                 name:@"lockSEB" object:nil];
    // Add an observer for the notification necessary for the correct key view loop
    // for tabbing/VoiceOver through the browser window (toolbar) and Dock
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goToDockButtonBecameFirstResponder)
                                                 name:@"goToDockButtonBecameFirstResponder" object:nil];

    
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event)
     {
        BOOL isLeftOption = (event.modifierFlags & NX_DEVICELALTKEYMASK) != 0;
        BOOL isLeftShift = (event.modifierFlags & NX_DEVICELSHIFTKEYMASK) != 0;
        BOOL isShift = (event.modifierFlags & NX_SHIFTMASK) != 0;
        BOOL isControl = (event.modifierFlags & NX_CONTROLMASK) != 0;
        self.tabPressedWhileDockIsKeyWindow = NO;
        self.tabPressedWhileWebViewIsFirstResponder = NO;
        self.shiftTabPressedWhileDockIsKeyWindow = NO;
        self.shiftTabPressedWhileWebViewIsFirstResponder = NO;
        if (isShift && event.keyCode == 48) { //Shift + Tab
            NSResponder *firstResponder = NSApp.keyWindow.firstResponder;
            if (NSApp.keyWindow == self.dockController.window) {
                self.shiftTabPressedWhileDockIsKeyWindow = YES;
            } else if (firstResponder.class == SEBOSXWKWebView.class || [firstResponder.className isEqualToString:@"WebHTMLView"]) {
                self.shiftTabPressedWhileWebViewIsFirstResponder = YES;
            } else if (firstResponder.class == SEBGoToDockButton.class && ([((NSButton *)firstResponder).identifier isEqualToString:@"toolbarGoToDockButton"] ||
                                                                           [((NSButton *)firstResponder).identifier isEqualToString:@"accessoryViewGoToDockButton"])) {
                [self.dockController activateDockFirstControl:NO];
                return nil;
            }
        } else if (event.keyCode == 48) { //Tab
            NSResponder *firstResponder = NSApp.keyWindow.firstResponder;
            id focusedUIElement = firstResponder.accessibilityFocusedUIElement;
            DDLogDebug(@"Tab key pressed, current key window: %@, current first responder: %@, current accessibilityFocusedUIElement: %@", NSApp.keyWindow, firstResponder, focusedUIElement);
            if (firstResponder.class == SEBBrowserWindow.class) {
                // This selects the first element on a web page directly after opening a new window
                // and pressing tab (without having to click the browser window first)
                [(SEBBrowserWindow *)firstResponder makeFirstResponder:[(SEBBrowserWindow *)firstResponder nativeWebView]];
            } else if (firstResponder.class == SEBOSXWKWebView.class || [firstResponder.className isEqualToString:@"WebHTMLView"]) {
                self.tabPressedWhileWebViewIsFirstResponder = YES;
            } else if (NSApp.keyWindow == self.dockController.window) {
                self.tabPressedWhileDockIsKeyWindow = YES;
            } else if (firstResponder.class == SEBGoToDockButton.class && [((NSButton *)firstResponder).identifier isEqualToString:@"accessoryViewGoToDockButton"]) {
                [self.browserController focusFirstElementInCurrentWindow];
                return nil;
            }
            
        }
        if (isLeftOption && !isLeftShift && event.keyCode == 48) {
            DDLogDebug(@"Left Option + Tab Key pressed!");
            [self.browserController activateNextOpenWindow];
            return nil;
        } else if (isLeftOption && isLeftShift && event.keyCode == 48) {
            DDLogDebug(@"Left Option + Left Shift + Tab Key pressed!");
            [self.browserController activatePreviousOpenWindow];
            return nil;
        } else if ((isControl || isShift) && event.keyCode == 0x63 ) {  //Ctrl/Shift + F3
            if (NSApp.keyWindow == self.dockController.window) {
                [self.browserController activateCurrentWindow];
            } else {
                [self.dockController activateDockFirstControl:YES];
            }
            return nil;
        } else if (event.keyCode == 0x63 ) {  //F3
            self->f3Pressed = YES;
            return nil;
        } else if (event.keyCode == 0x61 ) {  //F6
            if (self->f3Pressed) {    //if F3 got pressed before
                self->f3Pressed = NO;
                [self openPreferences:self]; //show preferences window
            }
            return nil;
        } else if (NSApp.keyWindow == self.dockController.window) {
            if (event.keyCode == kVK_UpArrow) {   //Cursor Up
                DDLogDebug(@"Cursor Up Key inside Dock pressed!");
                [self.dockController.window.firstResponder rightMouseDown:[NSEvent new]];
                return event;
            } else {
                return event;
            }
        }
        return event;
    }];
    
    
    // Prevent display sleep
#ifndef DEBUG
    IOPMAssertionCreateWithName(
                                kIOPMAssertionTypeNoDisplaySleep,
                                kIOPMAssertionLevelOn,
                                CFSTR("Safe Exam Browser Kiosk Mode"),
                                &assertionID1);
#else
    IOReturn success = IOPMAssertionCreateWithName(
                                                   kIOPMAssertionTypeNoDisplaySleep,
                                                   kIOPMAssertionLevelOn,
                                                   CFSTR("Safe Exam Browser Kiosk Mode"),
                                                   &assertionID1);
    if (success == kIOReturnSuccess) {
        DDLogDebug(@"Display sleep is switched off now.");
    }
#endif
    
    /*    // Prevent idle sleep
     success = IOPMAssertionCreateWithName(
     kIOPMAssertionTypeNoIdleSleep,
     kIOPMAssertionLevelOn,
     CFSTR("Safe Exam Browser Kiosk Mode"),
     &assertionID2);
     #ifdef DEBUG
     if (success == kIOReturnSuccess) {
     DDLogDebug(@"Idle sleep is switched off now.");
     }
     #endif
     */
    // Installing I/O Kit sleep/wake notification to cancel sleep
    
    IONotificationPortRef notifyPortRef; // notification port allocated by IORegisterForSystemPower
    io_object_t notifierObject; // notifier object, used to deregister later
    void* refCon = NULL; // this parameter is passed to the callback
    
    // register to receive system sleep notifications
    
    root_port = IORegisterForSystemPower( refCon, &notifyPortRef, MySleepCallBack, &notifierObject );
    if ( root_port == 0 )
    {
        DDLogError(@"IORegisterForSystemPower failed");
    } else {
        // add the notification port to the application runloop
        CFRunLoopAddSource( CFRunLoopGetCurrent(),
                           IONotificationPortGetRunLoopSource(notifyPortRef), kCFRunLoopCommonModes );
    }
    
    // Handling of Hotkeys for Preferences-Window
    f3Pressed = FALSE; //Initialize flag for first hotkey
}


- (void)removeKeyPathObservers
{
    [NSApp removeObserver:self
            forKeyPath:@"currentSystemPresentationOptions"];
    [[NSWorkspace sharedWorkspace] removeObserver:self
            forKeyPath:@"runningApplications"];
    [[NSWorkspace sharedWorkspace] removeObserver:self
            forKeyPath:@"isTerminated"];
//    [NSApp removeObserver:self
//            forKeyPath:@"isActive"];
}


- (void) firstDOMElementDeselected
{
    if (self.shiftTabPressedWhileWebViewIsFirstResponder) {
        [self.dockController activateDockFirstControl:NO];
    }
}

- (void) lastDOMElementDeselected
{
    if (self.tabPressedWhileWebViewIsFirstResponder) {
        [self.dockController activateDockFirstControl:YES];
    }
}

- (void) lastDockItemResignedFirstResponder
{
    if (self.tabPressedWhileDockIsKeyWindow) {
        [self.browserController activateInitialFirstResponderInCurrentWindow];
    }
}

- (void) firstDockItemResignedFirstResponder
{
    if (self.shiftTabPressedWhileDockIsKeyWindow) {
        [self.browserController focusLastElementInCurrentWindow];
    }
}

- (void) goToDockButtonBecameFirstResponder
{
    if (self.tabPressedWhileWebViewIsFirstResponder) {
        [self.dockController activateDockFirstControl:YES];
    }
}


- (id) currentDockAccessibilityParent
{
    return self.browserController.activeBrowserWindow.contentView;
}


#pragma mark - Application Delegate Methods
// (in order they are called)

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    // Create keyboard CGEvent for Return Key which is needed to close
    // a font download dialog which might be opened on some webpages
    keyboardEventReturnKey = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)36, true);
    
    [[[NSWorkspace sharedWorkspace] notificationCenter]
     addObserver:self
     selector:@selector(lockSEB:)
     name:NSWorkspaceSessionDidBecomeActiveNotification
     object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter]
     addObserver:self
     selector:@selector(lockSEB:)
     name:NSWorkspaceSessionDidResignActiveNotification
     object:nil];
}


// Prevent an untitled document to be opened at application launch
- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender {
    DDLogDebug(@"Invoked applicationShouldOpenUntitledFile with answer NO!");
    return NO;
}


// Tells the application delegate to open a single file.
// Returning YES if the file is successfully opened, and NO otherwise.
//
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    if (filename) {
        NSURL *fileURL = [NSURL fileURLWithPathString:filename];
        DDLogDebug(@"%s file URL: %@", __FUNCTION__, fileURL);

        if (!_openingSettings) {
            _openingSettings = YES;
            if (_startingUp && !_alternateKeyPressed && ![self.preferencesController preferencesAreOpen]) {
                _openedURL = YES;
                DDLogDebug(@"%s Delay opening file %@ while starting up.", __FUNCTION__, filename);
                _openingSettingsFileURL = fileURL;
            } else {
                [self openFile:fileURL];
            }
        }
        return YES;
    } else {
        return NO;
    }
}


- (void)application:(NSApplication *)sender openURLs:(nonnull NSArray<NSURL *> *)urls
{
    DDLogDebug(@"%s", __FUNCTION__);

    // Check if any alerts are open in SEB, abort opening if yes
    if (_modalAlertWindows.count) {
        DDLogError(@"%lu Modal window(s) displayed, aborting before opening new settings.", (unsigned long)_modalAlertWindows.count);
        return;
    }
    
    NSURL *url = urls.firstObject;
    if (url.isFileURL) {
        [self application:sender openFile:url.absoluteString];
    } else {
        if (url && !_openingSettings) {
            // If we have any URL, we try to download and open (conditionally) a .seb file
            // hopefully linked by this URL (also supporting redirections and authentification)
            _openingSettings = YES;
            _openedURL = YES;
            DDLogInfo(@"openURLs event: Loading .seb settings file with URL %@", url.absoluteString);
            [self.browserController openConfigFromSEBURL:url];
        }
    }
}


- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    DDLogDebug(@"%s", __FUNCTION__);
    NSApp.presentationOptions |= (NSApplicationPresentationDisableForceQuit | NSApplicationPresentationHideDock);
    
    NSArray <NSString *> *libraryDirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                              NSLocalDomainMask | NSUserDomainMask,
                                                              YES);
    NSFileManager *fileManager= [NSFileManager defaultManager];

    for (NSString *libraryDir in libraryDirs) {
        BOOL isDir;
        NSString *keyBindingsFilePath = [libraryDir stringByAppendingPathComponent:KeyBindingsPath];
        if ([fileManager fileExistsAtPath:keyBindingsFilePath isDirectory:&isDir]) {
            DDLogError(@"Cocoa Text System key bindings file detected: at path %@", keyBindingsFilePath);
            NSAlert *modalAlert = [self newAlert];
            [modalAlert setMessageText:NSLocalizedString(@"Custom Key Binding Detected", @"")];
            [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"%@ doesn't allow to use custom key bindings. Please delete or rename the file at the path %@ and restart %@", @""), SEBShortAppName, keyBindingsFilePath, SEBShortAppName]];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", @"")];
            [modalAlert setAlertStyle:NSAlertStyleCritical];
            void (^keyBindingDetectedHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                [self removeAlertWindow:modalAlert.window];
                [self quitSEBOrSession];
            };
            [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))keyBindingDetectedHandler];
            return;
        }
    }
    
    // Check if the font download alert was triggered from a web page
    // and SEB didn't had Accessibility permissions
    // and therefore was terminated to prevent a modal lock
    if (@available(macOS 10.9, *)) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        if ([preferences persistedSecureBoolForKey:fontDownloadAttemptedKey]) {
            
            NSDictionary *options = @{(__bridge id)
                                      kAXTrustedCheckOptionPrompt : @YES};
            // Check if we're trusted - and the option means "Prompt the user
            // to trust this app in System Preferences."
            NSAlert *modalAlert = nil;
            void (^accessibilityPermissionsAlertOK)(NSModalResponse) = ^void (NSModalResponse answer) {
                [self removeAlertWindow:modalAlert.window];
                [preferences setPersistedSecureBool:NO forKey:fontDownloadAttemptedKey];
                [preferences setPersistedSecureObject:@"" forKey:fontDownloadAttemptedOnPageTitleKey];
                [preferences setPersistedSecureObject:@"" forKey:fontDownloadAttemptedOnPageURLOrPlaceholderKey];
                [self applicationDidFinishLaunchingProceed];
            };
            if (!AXIsProcessTrustedWithOptions((CFDictionaryRef)options)) {
                modalAlert = [self newAlert];
                [modalAlert setMessageText:NSLocalizedString(@"Accessibility Permissions Required", @"")];
                [modalAlert setInformativeText:[NSString stringWithFormat:@"%@\n\n%@", [NSString stringWithFormat:NSLocalizedString(@"%@ needs Accessibility permissions to close the font download dialog displayed when a webpage tries to use a font not installed on your Mac. Grant access to %@ in Security & Privacy located in System Settings.", @""), SEBShortAppName, SEBFullAppNameClassic], [NSString stringWithFormat:NSLocalizedString(@"If you don't grant access to %@, you cannot use such webpages. Last time %@ was running, the webpage with the title '%@' (%@) tried to download a font.", @""), SEBShortAppName, SEBShortAppName, [preferences persistedSecureObjectForKey:fontDownloadAttemptedOnPageTitleKey], [preferences persistedSecureObjectForKey:fontDownloadAttemptedOnPageURLOrPlaceholderKey]]]];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
                [modalAlert setAlertStyle:NSAlertStyleCritical];
                [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow
                  completionHandler:(void (^)(NSModalResponse answer))accessibilityPermissionsAlertOK];
            } else {
                accessibilityPermissionsAlertOK(NSModalResponseOK);
            }
        }
    }
    
    // Show the About SEB Window
    _alternateKeyPressed = [self alternateKeyCheck];
    if (_alternateKeyPressed == NO) {
        [self.aboutWindowController showAboutWindowForSeconds:2];
    }

    [self applicationDidFinishLaunchingProceed];
}

- (void)applicationDidFinishLaunchingProceed
{
    if (_openingSettings && _openingSettingsFileURL) {
        DDLogDebug(@"%s Open file: %@", __FUNCTION__, _openingSettingsFileURL);
        [self openFile:_openingSettingsFileURL];
        _openingSettingsFileURL = nil;
    } else {
        [self didFinishLaunchingWithSettings];
    }
}


#pragma mark - Open configuration file

- (void)openFile:(NSURL *)sebFileURL
{
    DDLogDebug(@"%s Open file: %@", __FUNCTION__, sebFileURL.absoluteString);
    
    DDLogInfo(@"Open file event: Loading .seb settings file with URL %@", sebFileURL);
    
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    
    _alternateKeyPressed = [self alternateKeyCheck];
    
    // Check if preferences window is open
    if ([self.preferencesController preferencesAreOpen]) {
        
        /// Open settings file in preferences window for editing
        
        [self.preferencesController openSEBPrefsAtURL:sebFileURL];
        
    } else {
        
        /// Open settings file for exam/reconfiguring client
        
        // Check if any alerts are open in SEB, abort opening if yes
        if (_modalAlertWindows.count > 0) {
            DDLogError(@"%lu Modal window(s) displayed, aborting before opening new settings.", (unsigned long)_modalAlertWindows.count);
        }
        
        // Check if SEB is in an exam session and reconfiguring isn't allowed
        if (!_startingUp && ![self.browserController isReconfiguringAllowedFromURL:sebFileURL]) {
            _openingSettings = NO;
            return;
        }
        
        if (_alternateKeyPressed) {
            DDLogInfo(@"Option/alt key being held while SEB is started, will open Preferences window.");
            if (self.aboutWindow.isVisible) {
                DDLogDebug(@"%s About SEB window is visible, attempting to close it.", __FUNCTION__);
                [self closeAboutWindow];
            }
            [self.preferencesController openSEBPrefsAtURL:sebFileURL];
        }
        
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
            NSError *error = nil;
            NSData *sebData = [NSData dataWithContentsOfURL:sebFileURL options:NSDataReadingUncached error:&error];
            
            if (!error) {
                // Save the path to the file for possible editing in the preferences window
                [[MyGlobals sharedMyGlobals] setCurrentConfigURL:sebFileURL];
                
                // Decrypt and store the .seb config file
                [self.configFileController storeNewSEBSettings:sebData
                                                    forEditing:NO
                                                      callback:self
                                                      selector:@selector(storeNewSEBSettingsSuccessful:)];
                return;
            } else {
                //ToDo: Show alert for file loading error
            }
        } else {
            [self.browserController showAlertNotAllowedDownloadingAndOpeningSebConfig:YES];
        }
    }
    _openingSettings = NO;
}


- (void)storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
      showReconfiguredAlert:(BOOL)showReconfiguredAlert
                   callback:(id)callback
                   selector:(SEL)selector
{
    [self.configFileController storeNewSEBSettings:sebData
                                     forEditing:forEditing
                         forceConfiguringClient:forceConfiguringClient
                          showReconfiguredAlert:showReconfiguredAlert
                                       callback:callback
                                       selector:selector];
}


- (void) storeNewSEBSettingsSuccessful:(NSError *)error
{
    DDLogDebug(@"%s, error: %@", __FUNCTION__, error);
    
    if (!error) {
        // If successfull start/restart with new settings
        _openingSettings = NO;
        
        [self updateAACAvailablility];
        
        if (!_startingUp) {
            // SEB is being reconfigured by opening a config file
            [self requestedRestart:nil];
        } else {
            [self didFinishLaunchingWithSettings];
        }
        
    } else {
        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:[error.userInfo objectForKey:NSLocalizedDescriptionKey]];
        [modalAlert setInformativeText:[error.userInfo objectForKey:NSLocalizedFailureReasonErrorKey]];
        [modalAlert addButtonWithTitle:(!_establishingSEBServerConnection && !_startingUp) ? NSLocalizedString(@"OK", @"") : (!self.quittingSession ? [NSString stringWithFormat:NSLocalizedString(@"Quit %@", @""), SEBFullAppNameClassic] : NSLocalizedString(@"Quit Session", @""))];
        [modalAlert setAlertStyle:NSAlertStyleCritical];
        void (^storeNewSEBSettingsNotSuccessfulHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self removeAlertWindow:modalAlert.window];
            if (self.startingUp) {
                // we quit, as decrypting the config wasn't successful
                DDLogError(@"SEB was started with a SEB Config File as argument, but decrypting this configuration failed: Terminating.");
                [self requestedExit:nil]; // Quit SEB
            } else if (self.establishingSEBServerConnection) {
                [self sessionQuitRestart:NO];
            }
        };
        [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))storeNewSEBSettingsNotSuccessfulHandler];
        _openingSettings = NO;
    }
}


#pragma mark - Methods called after starting up by opening settings successfully

- (void)didOpenSettings
{
    DDLogDebug(@"%s", __FUNCTION__);
    _openingSettings = NO;
    [self updateAACAvailablility];

    if (_startingUp) {
        // If SEB was just started (by opening a config file)
        [self didFinishLaunchingWithSettings];
        
    } else {
        // SEB is being reconfigured by opening a config file
        [self requestedRestart:nil];
    }
}


- (void)didFinishLaunchingWithSettings
{
    DDLogDebug(@"%s", __FUNCTION__);
    _runningProhibitedProcesses = [NSMutableArray new];
    _terminatedProcessesExecutableURLs = [NSMutableSet new];

    _alternateKeyPressed = [self alternateKeyCheck];

    if (_alternateKeyPressed) {
        DDLogInfo(@"Option/alt key being held while SEB is started, will open Preferences window.");
        if (self.aboutWindow.isVisible) {
            DDLogDebug(@"%s About SEB window is visible, attempting to close it.", __FUNCTION__);
            [self closeAboutWindow];
        }
        [self saveCurrentPasteboardString];
        [self openPreferences:self];

    } else {
        [self updateAACAvailablility];
        DDLogInfo(@"isAACEnabled = %hhd", _isAACEnabled);

        // Reset SEB Browser
        [self.browserController resetBrowser];

        if (!_openingSettings) {
            // Initialize SEB according to client settings
            [self conditionallyInitSEBWithCallback:self
                                          selector:@selector(didFinishLaunchingWithSettingsProcessesChecked)];
        } else if (_isAACEnabled == NO) {
            // Cover all attached screens with cap windows to prevent clicks on desktop making finder active
            [self coverScreens];
        }
    }
}

- (void)didFinishLaunchingWithSettingsProcessesChecked
{
    if (_isAACEnabled == NO) {
        // Check for command key being held down
        [self appSwitcherCheck];
        
        // Cover all attached screens with cap windows to prevent clicks on desktop making finder active
        [self coverScreens];

        // Block screen shots
//        if ([NSUserDefaults standardUserDefaults].blockScreenShotsLegacy) {
//            [self killScreenCaptureAgent];
//        }
        [self.systemManager preventScreenCapture];
    }
    // Start system monitoring and prevent to start SEB if specific
    // system features are activated
    
    [self startSystemMonitoring];
    
    // Set up SEB Browser
    
    self.browserController.reinforceKioskModeRequested = YES;
    
    // Open the main browser window
    DDLogDebug(@"%s openMainBrowserWindow", __FUNCTION__);
    
    [self startExamWithFallback:NO];

    // SEB finished starting up, reset the flag for starting up
    _startingUp = false;

    [self performSelector:@selector(performAfterStartActions:) withObject: nil afterDelay: 2];
    
    if (_openingSettings && _openingSettingsFileURL) {
        DDLogDebug(@"%s Open file: %@", __FUNCTION__, _openingSettingsFileURL);
        [self performSelector:@selector(openFile:) withObject: _openingSettingsFileURL.copy afterDelay: 2.5];
        _openingSettingsFileURL = nil;
    }

}


- (void) startExamWithFallback:(BOOL)fallback
{
    DDLogInfo(@"%s", __FUNCTION__);
    if (_establishingSEBServerConnection == YES && !fallback) {
        _startingExamFromSEBServer = YES;
        [self.serverController startExamFromServer];
    } else {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebMode"] == sebModeSebServer &&
            !fallback) {
            NSString *sebServerURLString = [preferences secureStringForKey:@"org_safeexambrowser_SEB_sebServerURL"];
            NSDictionary *sebServerConfiguration = [preferences secureDictionaryForKey:@"org_safeexambrowser_SEB_sebServerConfiguration"];
            _establishingSEBServerConnection = YES;
            NSError *error = [self.serverController connectToServer:[NSURL URLWithString:sebServerURLString] withConfiguration:sebServerConfiguration];
            if (!error) {
                // All necessary information for connecting to SEB Server was available in settings:
                // try to connect to SEB Server and wait for delegate method to be called with success/failure
                [self showSEBServerView];
                return;
            } else {
                // Cannot connect as some SEB Server settings/API endpoints are missing
                [self didFailWithError:error fatal:YES];
                return;
            }
        }
        // ToDo: Implement Initial Configuration Assistant
        //        NSString *startURLString = [[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
        //        NSURL *startURL = [NSURL URLWithString:startURLString];
        //        if (startURLString.length == 0 ||
        //            (([startURL.host hasSuffix:@"safeexambrowser.org"] ||
        //              [startURL.host hasSuffix:SEBWebsiteShort]) &&
        //             [startURL.path hasSuffix:@"start"]))
        //        {
        //            // Start URL was set to the default value, show init assistant
        //            [self openInitAssistant];
        //        } else {
                    _sessionRunning = true;
                    
                    // Load all open web pages from the persistent store and re-create webview(s) for them
                    // or if no persisted web pages are available, load the start URL
                    [self.browserController openMainBrowserWindow];
                    
        // Persist start URL of a "secure" exam
        [self persistSecureExamStartURL:self.sessionState.startURL.absoluteString configKey:self.configKey];
        //        }

    }
}

// Persist start URL of a secure exam
- (void) persistSecureExamStartURL:(NSString *)startURLString configKey:(NSData *)configKey
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length != 0) {
        currentExamStartURL = startURLString;
        currentExamConfigKey = configKey;
        [self.sebLockedViewController addLockedExam:currentExamStartURL configKey: currentExamConfigKey];
    } else {
        currentExamStartURL = nil;
        currentExamConfigKey = nil;
    }
}

#pragma mark - Connecting to SEB Server

- (void) showSEBServerView
{
    _sebServerViewController = [SEBServerOSXViewController new];
    _sebServerViewController.sebServerController = self.serverController.sebServerController;
    self.serverController.sebServerController.serverControllerUIDelegate = _sebServerViewController;
    _sebServerViewController.serverControllerDelegate = self;
    NSWindow *sebServerViewWindow;
    sebServerViewWindow = [NSWindow windowWithContentViewController:_sebServerViewController];
    if (_allowSwitchToApplications) {
        [sebServerViewWindow setLevel:NSModalPanelWindowLevel-1];
    } else {
        [sebServerViewWindow setLevel:NSMainMenuWindowLevel+5];
    }
    sebServerViewWindow.title = NSLocalizedString(@"Connecting to SEB Server", @"");
    sebServerViewWindow.delegate = _sebServerViewController;
    NSWindowController *sebServerViewWindowController = [[NSWindowController alloc] initWithWindow:sebServerViewWindow];
    _sebServerViewWindowController = sebServerViewWindowController;
    [_sebServerViewWindowController showWindow:nil];

    _sebServerViewDisplayed = YES;
    [_sebServerViewController updateExamList];
}

- (void) closeServerView
{
    _sebServerViewWindowController.window.delegate = nil;
    [_sebServerViewWindowController close];
    _sebServerViewController = nil;
    _sebServerViewDisplayed = NO;
}


- (void) startBatteryMonitoringWithDelegate:(id)delegate
{
    [self.batteryController addDelegate:delegate];
    [self.batteryController startMonitoringBattery];
}


- (void) didSelectExamWithExamId:(NSString *)examId url:(NSString *)url
{
    [self.serverController examSelected:examId url:url];
}


- (void) storeNewSEBSettingsFromData:(NSData *)configData
{
    [self storeNewSEBSettings:configData forEditing:NO forceConfiguringClient:NO showReconfiguredAlert:NO callback:self selector:@selector(storeNewSEBSettingsSuccessful:)];
}


- (NSString * _Nullable)appSignatureKey {
    return [self.browserController.appSignatureKey base16String];
}


- (void)didReceiveExamSalt:(NSString * _Nonnull)examSalt connectionToken:(NSString * _Nonnull)connectionToken{
    if (examSalt.length > 0) {
        self.browserController.examSalt = [NSData dataWithBase16String:examSalt];
        self.browserController.connectionToken = connectionToken;
    } else {
        self.browserController.examSalt = nil;
        self.browserController.connectionToken = nil;
    }
}


- (void)didReceiveServerBEK:(NSString * _Nonnull)serverBEK {
    if (serverBEK.length > 0) {
        self.browserController.serverBrowserExamKey = [NSData dataWithBase16String:serverBEK];
    } else {
        self.browserController.serverBrowserExamKey = nil;
    }
}


- (void) loginToExam:(NSString *)url
{
    NSURL *examURL = [NSURL URLWithString:url];
    self.sessionState.sebServerExamStartURL = examURL;
    DDLogDebug(@"Session state: sebServerExamURL = %@", self.sessionState.sebServerExamStartURL);
    [self.browserController openMainBrowserWindowWithStartURL:examURL];
    [self persistSecureExamStartURL:url configKey:self.configKey];
    _sessionRunning = YES;
}


- (void) didEstablishSEBServerConnection
{
    _establishingSEBServerConnection = NO;
    _startingExamFromSEBServer = NO;
    _sebServerConnectionEstablished = YES;
}


- (void) didFailWithError:(NSError *)error fatal:(BOOL)fatal
{
    BOOL optionallyAttemptFallback = fatal && !_startingExamFromSEBServer && !_sebServerConnectionEstablished;
    DDLogError(@"SEB Server connection did fail with error: %@%@", [error.userInfo objectForKey:NSDebugDescriptionErrorKey], optionallyAttemptFallback ? @", optionally attempt failback" : @" This is a non-fatal error, no fallback necessary.");
    NSString *localizedRecoverySuggestion = [error.userInfo objectForKey:NSLocalizedRecoverySuggestionErrorKey];
    if (localizedRecoverySuggestion.length == 0) {
        localizedRecoverySuggestion = NSLocalizedString(@"Contact your exam administrator", comment: "");
    }
    NSString *informativeText = [NSString stringWithFormat:@"%@\n%@", [error.userInfo objectForKey:NSLocalizedDescriptionKey], localizedRecoverySuggestion];
    if (optionallyAttemptFallback) {
        if (!self.serverController.fallbackEnabled) {
            DDLogError(@"Aborting SEB Server connection as fallback isn't enabled");
            [self closeServerViewWithCompletion:^{
                NSAlert *modalAlert = [self newAlert];
                [modalAlert setMessageText:NSLocalizedString(@"Connection to SEB Server Failed", @"")];
                [modalAlert setInformativeText:informativeText];
                [modalAlert addButtonWithTitle:!self.quittingSession ? [NSString stringWithFormat:NSLocalizedString(@"Quit %@", @""), SEBFullAppNameClassic] : NSLocalizedString(@"Quit Session", @"")];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
                [modalAlert setAlertStyle:NSAlertStyleCritical];
                void (^closeServerViewHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                    [self removeAlertWindow:modalAlert.window];
                    switch(answer)
                    {
                        case NSAlertFirstButtonReturn:
                        {
                            [self closeServerViewAndRestart:self];
                            break;
                        }
                        default:
                            DDLogError(@"Alert was dismissed by the system with NSModalResponse %ld. Retrying to connect to SEB Server.", (long)answer);
                        case NSAlertSecondButtonReturn:
                        {
                            self.establishingSEBServerConnection = NO;
                            [self startExamWithFallback:NO];
                            break;
                        }
                    }
                };
                [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))closeServerViewHandler];
            }];
            return;;
        } else {
            [self closeServerViewWithCompletion:^{
                DDLogInfo(@"Server connection failed: Querying user if fallback should be used");
                NSAlert *modalAlert = [self newAlert];
                [modalAlert setMessageText:NSLocalizedString(@"Connection to SEB Server Failed: Fallback Option", @"")];
                [modalAlert setInformativeText:informativeText];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"Fallback", @"")];
                [modalAlert addButtonWithTitle:!self.quittingSession ? [NSString stringWithFormat:NSLocalizedString(@"Quit %@", @""), SEBFullAppNameClassic] : NSLocalizedString(@"Quit Session", @"")];
                [modalAlert setAlertStyle:NSAlertStyleCritical];
                void (^closeServerViewHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                    [self removeAlertWindow:modalAlert.window];
                    switch(answer)
                    {
                        default:
                            DDLogError(@"Alert was dismissed by the system with NSModalResponse %ld. Retrying to connect to SEB Server.", (long)answer);
                        case NSAlertFirstButtonReturn:
                        {
                            DDLogInfo(@"User selected Retry option");
                            self.establishingSEBServerConnection = NO;
                            [self startExamWithFallback:NO];
                            break;
                        }
                        case NSAlertSecondButtonReturn:
                        {
                            DDLogInfo(@"User selected Fallback option");
                            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
                            NSString *sebServerFallbackPasswordHash = [preferences secureStringForKey:@"org_safeexambrowser_SEB_sebServerFallbackPasswordHash"];
                            // If SEB Server fallback password is set, then restrict fallback
                            if (sebServerFallbackPasswordHash.length != 0) {
                                DDLogInfo(@"%s Displaying SEB Server fallback password alert", __FUNCTION__);
                                [self showEnterPasswordDialog:NSLocalizedString(@"Enter SEB Server fallback password:", @"") modalForWindow:self.browserController.mainBrowserWindow pseudoModal:NO windowTitle:@""];
                                NSString *password = [self.enterPassword stringValue];
                                
                                SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
                                if (password.length > 0 && [sebServerFallbackPasswordHash caseInsensitiveCompare:[keychainManager generateSHAHashString:password]] == NSOrderedSame) {
                                    DDLogInfo(@"Correct SEB Server fallback password entered");
                                    DDLogInfo(@"Open startURL as SEB Server fallback");
                                    self.establishingSEBServerConnection = NO;
                                    [self startExamWithFallback:YES];

                                } else {
                                    DDLogInfo(@"%@ SEB Server fallback password entered", password.length > 0 ? @"Wrong" : @"No");
                                    NSAlert *modalAlert = [self newAlert];
                                    [modalAlert setMessageText:password.length > 0 ? NSLocalizedString(@"Wrong SEB Server Fallback Password entered", @"") : NSLocalizedString(@"No SEB Server Fallback Password entered", @"")];
                                    [modalAlert setInformativeText:NSLocalizedString(@"If you don't enter the correct SEB Server fallback password, then you cannot invoke fallback.", @"")];
                                    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
                                    [modalAlert setAlertStyle:NSAlertStyleWarning];
                                    void (^wrongPasswordEnteredOK)(NSModalResponse) = ^void (NSModalResponse answer) {
                                        [self removeAlertWindow:modalAlert.window];
                                        [self didFailWithError:error fatal:fatal];
                                    };
                                    [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))wrongPasswordEnteredOK];
                                }
                            } else {
                                DDLogInfo(@"Open startURL as SEB Server fallback");
                                self.establishingSEBServerConnection = NO;
                                [self startExamWithFallback:YES];
                            }
                            break;
                        }
                        case NSAlertThirdButtonReturn:
                        {
                            DDLogInfo(@"User selected Quit option");
                            [self closeServerViewAndRestart:self];
                            break;
                        }
                    }
                };
                [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))closeServerViewHandler];
            }];
            return;
        }
    }
}


- (void) closeServerViewAndRestart:(id)sender
{
    [self closeServerViewWithCompletion:^{
        [self sessionQuitRestart:NO];
    }];
}


- (void) closeServerViewWithCompletion:(void (^)(void))completion
{
    [self closeServerView];
    completion();
}


- (void) serverSessionQuitRestart:(BOOL)restart
{
    self.establishingSEBServerConnection = NO;
    if (_sebServerViewDisplayed) {
        [self closeServerView];
    }
    // Check if Preferences are currently open
    if ([self.preferencesController preferencesAreOpen]) {
        // Close Preferences
        [self closePreferencesWindow];
    }
    [self sessionQuitRestart:restart];
}


- (void) didCloseSEBServerConnectionRestart:(BOOL)restart
{
    _establishingSEBServerConnection = NO;
    if (restart) {
        [self requestedRestart:nil];
    } else {
        [self quitSEBOrSession];
    }
}


- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies forURL:(NSURL *)url
{
    if (_establishingSEBServerConnection) {
        [self.serverController examineCookies:cookies forURL:url];
    }
}


- (void) examineHeaders:(NSDictionary<NSString *,NSString *>*)headerFields forURL:(NSURL *)url
{
    [self.serverController examineHeaders:headerFields forURL:url];
}


- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url
{
    if (_establishingSEBServerConnection) {
        [self.serverController shouldStartLoadFormSubmittedURL:url];
    }
}


#pragma mark - Remote Proctoring

- (void) openZoomView
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (@available(iOS 11.0, *)) {
        self.previousSessionZoomEnabled = YES;
        
        // Initialize Zoom settings
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        _zoomReceiveAudio = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomReceiveAudio"];
        _zoomReceiveVideo = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomReceiveVideo"];
        _zoomSendAudio = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomSendAudio"];
        _zoomSendVideo = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomSendVideo"];
        _remoteProctoringViewShowPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_remoteProctoringViewShow"];
    }
}

- (void) proctoringInstructionWithAttributes:(NSDictionary *)attributes
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    NSString *serviceType = attributes[@"service-type"];
    DDLogInfo(@"%s: Service type: %@", __FUNCTION__, serviceType);
    
    if ([serviceType isEqualToString:proctoringServiceTypeScreenProctoring]) {
        NSString *instructionConfirm = attributes[@"instruction-confirm"];
        if (![instructionConfirm isEqualToString:self.serverController.sebServerController.pingInstruction]) {
            self.serverController.sebServerController.pingInstruction = instructionConfirm;
            if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enableScreenProctoring"]) {
                [self.screenProctoringController proctoringInstructionWithAttributes:attributes];
            } else {
                DDLogError(@"%s: Received Screen Proctoring JOIN instruction, despite screen proctoring not being enabled in SEB Settings, ignoring it!", __FUNCTION__);
            }
        }
    } else {
        DDLogError(@"%s: Cannot execute proctoring instruction, unknown Service Type in attributes %@!", __FUNCTION__, attributes);
    }
}

- (void) reconfigureWithAttributes:(NSDictionary *)attributes
{
    DDLogDebug(@"%s: attributes: %@", __FUNCTION__, attributes);
}

- (void) lockSEBWithAttributes:(NSDictionary *)attributes
{
    DDLogDebug(@"%s: attributes: %@", __FUNCTION__, attributes);
    NSString *message = attributes[@"message"];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"lockSEB" object:self userInfo:@{@"lockReason" : message ? message : [NSString stringWithFormat:NSLocalizedString(@"%@ was locked by SEB Server. Please contact your exam support.", @""), SEBShortAppName]}];
}

- (void) confirmNotificationWithAttributes:(NSDictionary *)attributes
{
    DDLogDebug(@"%s: attributes: %@", __FUNCTION__, attributes);
    NSString *notificationType = attributes[@"type"];
    NSNumber *notificationIDNumber = [attributes objectForKey:@"id"];
    
    if ([notificationType isEqualToString:@"raisehand"]) {
        if (_raiseHandRaised && raiseHandUID == notificationIDNumber.integerValue) {
            [self toggleRaiseHandLoweredByServer:YES];
        }
    }
    
    if ([notificationType isEqualToString:@"lockscreen"]) {
        if (self.sebServerPendingLockscreenEvents.count > 0) {
#ifdef DEBUG
        DDLogDebug(@"sebServerPendingLockscreenEvents: %@", self.sebServerPendingLockscreenEvents);
#endif
            NSInteger notificationID = notificationIDNumber.integerValue;
            for (NSUInteger index = 0 ; index < self.sebServerPendingLockscreenEvents.count ; ++index) {
                if (self.sebServerPendingLockscreenEvents[index].integerValue == notificationID) {
                    [self.sebServerPendingLockscreenEvents removeObjectAtIndex:index];
                }
            }
    #ifdef DEBUG
            DDLogDebug(@"sebServerPendingLockscreenEvents after removing notificationID %@: %@", notificationIDNumber, self.sebServerPendingLockscreenEvents);
    #endif
            if (self.sebServerPendingLockscreenEvents.count == 0) {
                DDLogInfo(@"No pending lock screen events, closing lockdown windows invoked by SEB Server");
                [self closeLockdownWindowsAllowOverride:NO];
            }
        }
    }
}


- (void) stopProctoringWithCompletion:(void (^)(void))completionHandler
{
    if (_screenProctoringController) {
        [_screenProctoringController closeSessionWithCompletionHandler:^{
            self->_screenProctoringController = nil;
            completionHandler();
        }];
        return;
    }
    completionHandler();
}


- (void) proctoringFailedWithErrorMessage:(NSString *)errorMessage
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"proctoringFailed" object:self userInfo:@{NSLocalizedFailureReasonErrorKey : errorMessage}];
}


- (void) toggleProctoringViewVisibility
{
    DDLogDebug(@"%s", __FUNCTION__);
}


- (void) setProctoringViewButtonState:(remoteProctoringButtonStates)remoteProctoringButtonState
{
    [self setProctoringViewButtonState:remoteProctoringButtonState userFeedback:YES];
}


- (void) setProctoringViewButtonState:(remoteProctoringButtonStates)remoteProctoringButtonState
                         userFeedback:(BOOL)userFeedback
{
    NSImage *remoteProctoringButtonImage;
    NSColor *remoteProctoringButtonTintColor;
    switch (remoteProctoringButtonState) {
        case remoteProctoringButtonStateNormal:
//            remoteProctoringButtonImage = ProctoringIconNormalState;
            remoteProctoringButtonTintColor = ProctoringIconColorNormalState;
//            _sebViewController.proctoringStateIcon = ProctoringBadgeNormalState;
            break;
            
        case remoteProctoringButtonStateWarning:
//            remoteProctoringButtonImage = ProctoringIconWarningState;
            remoteProctoringButtonTintColor = ProctoringIconColorWarningState;
//            _sebViewController.proctoringStateIcon = ProctoringBadgeWarningState;
            break;
            
        case remoteProctoringButtonStateError:
//            remoteProctoringButtonImage = ProctoringIconErrorState;
            remoteProctoringButtonTintColor = ProctoringIconColorErrorState;
//            _sebViewController.proctoringStateIcon = ProctoringBadgeErrorState;
            break;
            
        case remoteProctoringButtonStateAIInactive:
            if (@available(macOS 10.14, *)) {
                _dockButtonProctoringView.image.template = YES;
                remoteProctoringButtonTintColor = ProctoringIconColorNormalState;
            } else {
                remoteProctoringButtonImage = ProctoringIconAIInactiveState;
            }
//            _sebViewController.proctoringStateIcon = nil;
            break;
            
        default:
            if (@available(macOS 10.14, *)) {
                remoteProctoringButtonImage.template = NO;
                remoteProctoringButtonTintColor = nil;
            } else {
                remoteProctoringButtonImage = ProctoringIconDefaultState;
            }
//            _sebViewController.proctoringStateIcon = nil;
            break;
    }
    if (userFeedback) {
        if (@available(macOS 10.14, *)) {
            _dockButtonProctoringView.contentTintColor = remoteProctoringButtonTintColor;
        } else {
            _dockButtonProctoringView.image = remoteProctoringButtonImage;
        }
    }
}


#pragma mark - Raise Hand Feature

- (void) toggleRaiseHand
{
    [self toggleRaiseHandLoweredByServer:NO];
}

- (void) toggleRaiseHandLoweredByServer:(BOOL)loweredByServer
{
    DDLogInfo(@"%s", __FUNCTION__);
    
    if (_raiseHandRaised) {
        _raiseHandRaised = NO;
        _dockButtonRaiseHand.image = RaisedHandIconDefaultState;
        if (@available(macOS 10.14, *)) {
            _dockButtonRaiseHand.contentTintColor = RaisedHandIconColorDefaultState;
        }
        if (!loweredByServer) {
            [self.serverController sendLowerHandNotificationWithUID:raiseHandUID];
        }
        
    } else {
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_raiseHandButtonAlwaysPromptMessage"]) {
            [self showEnterRaiseHandMessageWindow];
        } else {
            [self raiseHand];
        }
    }
}

- (void) raiseHand
{
    if (!_raiseHandRaised) {
        _raiseHandRaised = YES;
        _dockButtonRaiseHand.image = RaisedHandIconRaisedState;
        if (@available(macOS 10.14, *)) {
            _dockButtonRaiseHand.contentTintColor = RaisedHandIconColorRaisedState;
        }
        raiseHandUID = [self.serverController sendRaiseHandNotificationWithMessage:raiseHandNotification];
        raiseHandNotification = @"";
    }
}


- (void) showEnterRaiseHandMessageWindow
{
    if (!_raiseHandRaised) {
        NSWindow *windowToShowModalFor;

        if (@available(macOS 12.0, *)) {
        } else {
            if (@available(macOS 11.0, *)) {
                if (_isAACEnabled || _wasAACEnabled) {
                    windowToShowModalFor = self.browserController.mainBrowserWindow;
                }
            }
        }

        [NSApp beginSheet: _enterRaiseHandMessageWindow
           modalForWindow: windowToShowModalFor
            modalDelegate: nil
           didEndSelector: nil
              contextInfo: nil];
        [NSApp runModalForWindow: _enterRaiseHandMessageWindow];
        // Dialog is up here.
        [NSApp endSheet: _enterRaiseHandMessageWindow];
        self.raiseHandMessageTextField.stringValue = @"";
        [_enterRaiseHandMessageWindow orderOut: self];
        [self removeAlertWindow:_enterRaiseHandMessageWindow];
        if (raiseHandNotification) {
            [self raiseHand];
        }
    }
}


- (IBAction)sendEnteredRaiseHandMessage:(id)sender
{
    raiseHandNotification = self.raiseHandMessageTextField.stringValue;
    [NSApp stopModal];
}

- (IBAction)cancelEnteringRaiseHandMessage:(id)sender
{
    raiseHandNotification = nil;
    [NSApp stopModal];
}


#pragma mark - Screen Proctoring Delegate Methods

- (NSDictionary<NSString *,NSString *>*) getScreenProctoringMetadataActiveAppWindow
{
    NSString *activeBrowserWindowTitle; // = self.browserController.activeBrowserWindowTitle;

    // Get the process ID of the frontmost application.
    NSRunningApplication* app = [[NSWorkspace sharedWorkspace]
                                 frontmostApplication];
    pid_t pid = [app processIdentifier];
    
    // See if we have accessibility permissions, and if not, prompt the user to
    // visit System Preferences.
    NSDictionary *options = @{(id)CFBridgingRelease(kAXTrustedCheckOptionPrompt): @YES};
    Boolean appHasPermission = AXIsProcessTrustedWithOptions(
                                                             (__bridge CFDictionaryRef)options);
    if (!appHasPermission) {
        // we don't have accessibility permissions
        DDLogError(@"SEB is not trusted in Privacy / Accessibility, cannot read title of frontmost windows!");
    } else {
        // Get the accessibility element corresponding to the frontmost application.
        AXUIElementRef appElem = AXUIElementCreateApplication(pid);
        if (!appElem) {
            return nil;
        }
        
        // Get the accessibility element corresponding to the frontmost window
        // of the frontmost application.
        AXUIElementRef window = NULL;
        if (AXUIElementCopyAttributeValue(appElem,
                                          kAXFocusedWindowAttribute, (CFTypeRef*)&window) != kAXErrorSuccess) {
            CFRelease(appElem);
            return nil;
        } else {
            // Finally, get the title of the frontmost window.
            CFStringRef title = NULL;
            AXError result = AXUIElementCopyAttributeValue(window, kAXTitleAttribute,
                                                           (CFTypeRef*)&title);
            
            // At this point, we don't need window and appElem anymore.
            CFRelease(window);
            CFRelease(appElem);
            
            if (result == kAXErrorSuccess) {
                activeBrowserWindowTitle = CFBridgingRelease(title);
            }
        }
    }

    NSString *activeAppInfo = [NSString stringWithFormat:@"%@ (Bundle ID: %@, Path: %@)", app.localizedName, app.bundleIdentifier, app.bundleURL.path];
    
    if (activeBrowserWindowTitle == nil) {
        activeBrowserWindowTitle = @"";
    }
    
    if (sebPID == pid) {
        activeBrowserWindowTitle = [self.browserController windowTitleByRemovingSEBVersionString:activeBrowserWindowTitle];
    }
    
    NSDictionary *activeAppWindowMetadata = @{@"activeApp": activeAppInfo, @"activeWindow": activeBrowserWindowTitle};
    return activeAppWindowMetadata;
}


- (NSString *) getScreenProctoringMetadataURL
{
    return self.browserController.activeBrowserWindow.currentURL.absoluteString;
}

- (NSString *) getScreenProctoringMetadataBrowser
{
    return self.browserController.openWebpagesTitlesString;
}


#pragma mark - Screen Proctoring SPSControllerUIDelegate methods

- (void) updateStatusWithString:(NSString *)string append:(BOOL)append
{
    run_on_ui_thread(^{
        self.dockButtonScreenProctoring.toolTip = string;
    });
}


- (void) screenProctoringButtonAction
{
    DDLogDebug(@"%s", __FUNCTION__);
}


- (void) setScreenProctoringButtonState:(ScreenProctoringButtonStates)screenProctoringButtonState
{
    [self setScreenProctoringButtonState:screenProctoringButtonState userFeedback:YES];
}

- (void) setScreenProctoringButtonState:(ScreenProctoringButtonStates)screenProctoringButtonState
                           userFeedback:(BOOL)userFeedback
{
    run_on_ui_thread(^{
        NSImage *screenProctoringButtonImage;
        NSColor *screenProctoringButtonTintColor;
        DDLogDebug(@"[SEBController setScreenProctoringButtonState: %ld userFeedback: %@]", (long)screenProctoringButtonState, userFeedback ? @"YES" : @"NO");
        switch (screenProctoringButtonState) {
            case ScreenProctoringButtonStateActive:
                self.dockButtonScreenProctoringStateString = NSLocalizedString(@"Screen Proctoring Active",nil);
                self.dockButtonScreenProctoring.toolTip = self.dockButtonScreenProctoringStateString;
                screenProctoringButtonImage = self->ScreenProctoringIconActiveState;
                screenProctoringButtonTintColor = self->ScreenProctoringIconColorActiveState;
                break;
                
            case ScreenProctoringButtonStateActiveWarning:
                screenProctoringButtonImage = self->ScreenProctoringIconActiveWarningState;
                screenProctoringButtonTintColor = self->ScreenProctoringIconColorWarningState;
                break;
                
            case ScreenProctoringButtonStateActiveError:
                screenProctoringButtonImage = self->ScreenProctoringIconActiveErrorState;
                screenProctoringButtonTintColor = self->ScreenProctoringIconColorErrorState;
                break;
                
            case ScreenProctoringButtonStateInactive:
            default:
                self.dockButtonScreenProctoringStateString = NSLocalizedString(@"Screen Proctoring Inactive",nil);
                self.dockButtonScreenProctoring.toolTip = self.dockButtonScreenProctoringStateString;
                screenProctoringButtonImage = self->ScreenProctoringIconInactiveState;
                break;
        }
        if (userFeedback) {
            screenProctoringButtonImage.template = YES;
            self.dockButtonScreenProctoring.image = screenProctoringButtonImage;
            if (@available(macOS 10.14, *)) {
                self.dockButtonScreenProctoring.contentTintColor = screenProctoringButtonTintColor;
            }
        }
    });
}


- (void) setScreenProctoringButtonInfoString:(NSString *)infoString
{
    run_on_ui_thread(^{
        if (infoString.length == 0) {
            self.dockButtonScreenProctoring.toolTip = self.dockButtonScreenProctoringStateString;
        } else {
            self.dockButtonScreenProctoring.toolTip = [NSString stringWithFormat:@"%@ (%@)", self.dockButtonScreenProctoringStateString, infoString];
        }
    });
}


- (void)showTransmittingCachedScreenShotsWindowWithRemainingScreenShots:(NSInteger)remainingScreenShots message:(NSString * _Nullable)message operation:(NSString * _Nullable)operation
{
    run_on_ui_thread(^{
        if (self->_transmittingCachedScreenShotsViewController) {
            [self updateTransmittingCachedScreenShotsWindowWithRemainingScreenShots:self.latestNumberOfCachedScreenShotsWhileClosing message:nil operation:nil totalScreenShots:remainingScreenShots];
        } else {
            self.lockModalWindows = [self fillScreensWithCoveringWindows:coveringWindowModalAlert
                                                            windowLevel:NSScreenSaverWindowLevel
                                                         excludeMenuBar:false];

            NSWindow *transmittingCachedScreenShotsWindow;
            transmittingCachedScreenShotsWindow = [NSWindow windowWithContentViewController:self.transmittingCachedScreenShotsViewController];
            self.transmittingCachedScreenShotsViewController.progressBar.minValue = 0;
            self.transmittingCachedScreenShotsViewController.progressBar.maxValue = remainingScreenShots;
            self.transmittingCachedScreenShotsViewController.progressBar.doubleValue = remainingScreenShots;
            self.latestNumberOfCachedScreenShotsWhileClosing = remainingScreenShots;
            if (message) {
                self.transmittingCachedScreenShotsViewController.message.stringValue = message;
            }
            if (operation) {
                self.transmittingCachedScreenShotsViewController.operations.stringValue = operation;
            }

            [transmittingCachedScreenShotsWindow setLevel:NSScreenSaverWindowLevel+1];
            transmittingCachedScreenShotsWindow.styleMask  &= ~(NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable);
            transmittingCachedScreenShotsWindow.title = NSLocalizedString(@"Finalizing Screen Proctoring", @"");
            NSWindowController *windowController = [[NSWindowController alloc] initWithWindow:transmittingCachedScreenShotsWindow];
            self.transmittingCachedScreenShotsWindowController = windowController;
            [self.transmittingCachedScreenShotsWindowController showWindow:nil];
        }
    });
}


- (void)updateTransmittingCachedScreenShotsWindowWithRemainingScreenShots:(NSInteger)remainingScreenShots message:(NSString * _Nullable)message operation:(NSString * _Nullable)operation totalScreenShots:(NSInteger)totalScreenShots
{
    [self updateTransmittingCachedScreenShotsWindowWithRemainingScreenShots:remainingScreenShots message:message operation:operation append:NO totalScreenShots:totalScreenShots];
}

- (void)updateTransmittingCachedScreenShotsWindowWithRemainingScreenShots:(NSInteger)remainingScreenShots message:(NSString * _Nullable)message operation:(NSString * _Nullable)operation append:(BOOL)append totalScreenShots:(NSInteger)totalScreenShots
{
    self.latestNumberOfCachedScreenShotsWhileClosing = remainingScreenShots;
    run_on_ui_thread(^{
        if (self->_transmittingCachedScreenShotsViewController) {
            self.transmittingCachedScreenShotsViewController.progressBar.doubleValue = remainingScreenShots;
            self.transmittingCachedScreenShotsViewController.progressBar.maxValue = totalScreenShots;
            if (message) {
                self.transmittingCachedScreenShotsViewController.message.stringValue = message;
            }
            if (operation) {
                NSString *updatedOperations = operation;
                if (append && self.operationsString.length > 0) {
                    NSString *separator = [self.operationsString hasSuffix:@"."] ? @"" : @".";
                    updatedOperations = [NSString stringWithFormat:@"%@%@ %@", self.operationsString, separator, operation];
                }
                self.transmittingCachedScreenShotsViewController.operations.stringValue = updatedOperations;
                self.operationsString = updatedOperations;
            }
        }
    });
}


- (void)allowQuit:(BOOL)allowQuit
{
    run_on_ui_thread(^{
        if (self->_transmittingCachedScreenShotsViewController) {
            self.transmittingCachedScreenShotsViewController.quitButton.hidden = !allowQuit;
        }
    });
}

- (void)closeTransmittingCachedScreenShotsWindow:(void (^ _Nonnull)(void))completion
{
    run_on_ui_thread(^{
        self.transmittingCachedScreenShotsViewController.uiDelegate = nil;
        [self.transmittingCachedScreenShotsWindowController close];
        self.transmittingCachedScreenShotsViewController = nil;
        [self closeLockModalWindows];
        completion();
    });
}


#pragma mark - Initialization depending on client or opened settings

- (void) conditionallyInitSEBWithCallback:(id)callback
                                 selector:(SEL)selector;
{
    if (_openingSettings) {
        DDLogDebug(@"OpeningSettings = true, abort %s", __FUNCTION__);
        return;
    }
    DDLogDebug(@"%s", __FUNCTION__);
    
    /// Kiosk mode checks
    
    // Check if running on minimal macOS version
    [self checkMinMacOSVersion];
    
    // Check if launched SEB is placed ("installed") in an Applications folder
    [self installedInApplicationsFolder];
    
    
    // Check if any prohibited processes are running and terminate them
    
    [[ProcessManager sharedProcessManager] updateMonitoredProcesses];
    
    NSArray *prohibitedApplications = [ProcessManager sharedProcessManager].prohibitedApplications;
    NSArray *prohibitedBSDProcesses = [ProcessManager sharedProcessManager].prohibitedBSDProcesses;
    
    [self terminateApplications:prohibitedApplications processes:prohibitedBSDProcesses starting:YES restarting:NO callback:callback selector:selector];
}


- (void) terminateApplications:(NSArray *)prohibitedApplications
                     processes:(NSArray *)prohibitedBSDProcesses
                      starting:(BOOL)starting
                    restarting:(BOOL)restarting
                      callback:(id)callback
                      selector:(SEL)selector
{
    // Get all running processes, including daemons
    NSArray *allRunningProcesses = [self getProcessArray];
    self.runningProcesses = allRunningProcesses;
    
    NSMutableArray <NSRunningApplication *>*runningApplications = [NSMutableArray new];
    NSMutableArray <NSDictionary *>*runningProcesses = [NSMutableArray new];
    
    NSArray *permittedApplications = [ProcessManager sharedProcessManager].permittedApplications;
    if (permittedApplications && permittedApplications.count > 0) {
        DDLogInfo(@"There are permitted additional applications (which will be added to the list of apps to be quit before %@ the exam session): %@", starting ? @"starting" : @"ending", permittedApplications);
        prohibitedApplications = [prohibitedApplications arrayByAddingObjectsFromArray:permittedApplications];
    }
    BOOL autoQuitApplications = [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_autoQuitApplications"];
    
    // Check if any prohibited processes are running
    for (NSDictionary *process in allRunningProcesses) {
        NSNumber *PID = process[@"PID"];
        pid_t processPID = PID.intValue;
        NSRunningApplication *runningApplication = [NSRunningApplication runningApplicationWithProcessIdentifier:processPID];
        NSString *bundleID = runningApplication.bundleIdentifier;
        if (bundleID) {
            // NSRunningApplication
            NSPredicate *processFilter = [NSPredicate predicateWithFormat:@"%@ LIKE self", bundleID];
            NSArray *matchingProhibitedApplications = [prohibitedApplications filteredArrayUsingPredicate:processFilter];
            if (matchingProhibitedApplications.count != 0) {
                DDLogInfo(@"This %@ application is running and has to be quit first before %@ the exam session: %@", starting ? @"not allowed" : @"permitted", starting ? @"starting" : @"ending", matchingProhibitedApplications);
                NSURL *appURL = [self getBundleOrExecutableURL:runningApplication];
                if (appURL && starting) {
                    // Add the app's file URL, so we can restart it when exiting SEB
                    [_terminatedProcessesExecutableURLs addObject:appURL];
                }
                NSDictionary *prohibitedProcess = [[ProcessManager sharedProcessManager] prohibitedProcessWithIdentifier:bundleID];
                if ([prohibitedProcess[@"strongKill"] boolValue] == YES) {
                    DDLogInfo(@"Settings allow to force terminate this running application: %@", runningApplication);
                    if (![runningApplication kill]) {
                        [runningApplications addObject:runningApplication];
                    }
                } else {
                    [runningApplications addObject:runningApplication];
                    if (autoQuitApplications) {
                        [runningApplication terminate];
                    }
                }
            }
        } else {
            // BSD process
            NSPredicate *processNameFilter = [NSPredicate predicateWithFormat:@"%@ LIKE self", process[@"name"]];
            NSArray *filteredProcesses = [prohibitedBSDProcesses filteredArrayUsingPredicate:processNameFilter];
            if (filteredProcesses.count != 0) {
                NSDictionary *prohibitedProcess = [[ProcessManager sharedProcessManager] prohibitedProcessWithExecutable:process[@"name"]];
                DDLogInfo(@"This not allowed process is running and has to terminated before %@ the exam session: %@", starting ? @"starting" : @"ending", prohibitedProcess);
                if ([prohibitedProcess[@"strongKill"] boolValue] == YES) {
                    if (![NSRunningApplication killProcessWithPID:processPID error:nil]) {
                        [runningProcesses addObject:process];
                    } else {
                        NSString *executablePath = [ProcessManager getExecutablePathForPID:processPID];
                        if (executablePath) {
                            NSURL *processURL = [NSURL fileURLWithPath:executablePath isDirectory:NO];
                            // Add the process' file URL, so we can restart it when exiting SEB
                            [_terminatedProcessesExecutableURLs addObject:processURL];
                        }
                    }
                } else {
                    [runningProcesses addObject:process];
                }
            }
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Check if all prohibited processes did terminate and otherwise prompt the user
        if (runningApplications.count + runningProcesses.count > 0) {
            self.processListViewController.runningApplications = runningApplications;
            self.processListViewController.runningProcesses = runningProcesses;
            self.processListViewController.callback = callback;
            self.processListViewController.selector = selector;
            self.processListViewController.starting = starting;
            self.processListViewController.restarting = restarting;
            
            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
            
            NSWindow *runningProcessesListWindow;
            runningProcessesListWindow = [NSWindow windowWithContentViewController:self.processListViewController];
            [runningProcessesListWindow setLevel:NSMainMenuWindowLevel+5];
            runningProcessesListWindow.title = NSLocalizedString(@"Prohibited Processes Are Running", @"");
            NSWindowController *processListWindowController = [[NSWindowController alloc] initWithWindow:runningProcessesListWindow];
            self.runningProcessesListWindowController = processListWindowController;
            // Check if the process wasn't closed in the meantime (race condition)
            // important: processListViewController must be accessed with the instance variable
            // _processListViewController here and not using the property self.processListViewController
            // as otherwise a new instance of the controller will be allocated
            if (self->_processListViewController &&
                self->_processListViewController.runningApplications.count +
                self->_processListViewController.runningProcesses.count > 0) {
                runningProcessesListWindow.delegate = self.processListViewController;
                [self.runningProcessesListWindowController showWindow:nil];
                return;
            }
        } else {
            [self conditionallyContinueAfterTerminatingAppsWithCallback:callback restarting:restarting selector:selector starting:starting];
        }
    });
}


- (void) conditionallyContinueAfterTerminatingAppsWithCallback:(id)callback restarting:(BOOL)restarting selector:(SEL)selector starting:(BOOL)starting {
    if (starting) {
        [self conditionallyInitSEBProcessesCheckedWithCallback:callback selector:selector];
    } else {
        if (callback == nil) {
            [self sessionQuitRestartContinue:restarting];
        } else {
            DDLogDebug(@"%s, continue with callback: %@ selector: %@", __FUNCTION__, callback, NSStringFromSelector(selector));
            IMP imp = [callback methodForSelector:selector];
            void (*func)(id, SEL) = (void *)imp;
            func(callback, selector);
        }
    }
}


- (NSMutableArray *)checkProcessesRunning:(NSMutableArray *)runningProcesses
{
    // Get all running processes, including daemons
    NSArray *allRunningProcesses = [self getProcessArray];
    self.runningProcesses = allRunningProcesses;
    
    NSUInteger i=0;
    while (i < (runningProcesses).count) {
        NSDictionary *runningProcess = (runningProcesses)[i];
        if (![allRunningProcesses containsObject:runningProcess]) {
            DDLogDebug(@"Running process %@ did terminate", runningProcess[@"name"]);
            [runningProcesses removeObjectAtIndex:i];
        } else {
            i++;
        }
    }
    return runningProcesses;
}


- (void) conditionallyInitSEBProcessesCheckedWithCallback:(id)callback
                                                 selector:(SEL)selector
{
    if (_openingSettings) {
        DDLogDebug(@"OpeningSettings = true, abort %s", __FUNCTION__);
        return;
    }
    DDLogDebug(@"%s", __FUNCTION__);
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowVirtualMachine"]) {
        // Check if SEB is running inside a virtual machine
        SInt32        myAttrs;
        OSErr        myErr = noErr;
        
        // Get details for the present operating environment
        // by calling Gestalt (Userland equivalent to CPUID)
        myErr = Gestalt(gestaltX86AdditionalFeatures, &myAttrs);
        if ((myErr == noErr && ((myAttrs & (1UL << 31)) | (myAttrs == 0x209))) || [self.systemManager.systemInfo.sysModelID localizedCaseInsensitiveContainsString:[[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"dklyVFVhTA==" options:NSDataBase64DecodingIgnoreUnknownCharacters] encoding:NSUTF8StringEncoding]] || [self.systemManager.systemInfo.sysModelID localizedCaseInsensitiveContainsString:[[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"dk1XYVJF" options:NSDataBase64DecodingIgnoreUnknownCharacters] encoding:NSUTF8StringEncoding]] || [self.systemManager.systemInfo.sysModelID localizedCaseInsensitiveContainsString:[[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"cUVtVQ==" options:NSDataBase64DecodingIgnoreUnknownCharacters] encoding:NSUTF8StringEncoding]] || [self.systemManager.systemInfo.sysModelID localizedCaseInsensitiveContainsString:[[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:@"UEFyQWxsRWxT" options:NSDataBase64DecodingIgnoreUnknownCharacters] encoding:NSUTF8StringEncoding]]) {
            // Bit 31 is set: VMware Hypervisor running (?)
            // or gestaltX86AdditionalFeatures values of VirtualBox detected
            DDLogError(@"SERIOUS SECURITY ISSUE DETECTED: SEB was started up in a virtual machine! gestaltX86AdditionalFeatures = %X", myAttrs);
            NSAlert *modalAlert = [self newAlert];
            [modalAlert setMessageText:NSLocalizedString(@"Virtual Machine Detected!", @"")];
            [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"You are not allowed to run %@ inside a virtual machine!", @""), SEBShortAppName]];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", @"")];
            [modalAlert setAlertStyle:NSAlertStyleCritical];
            void (^vmDetectedHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                [self removeAlertWindow:modalAlert.window];
                [self quitSEBOrSession];
            };
            [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))vmDetectedHandler];
            return;
        } else {
            DDLogInfo(@"SEB is running on a native system (no VM) gestaltX86AdditionalFeatures = %X", myAttrs);
        }
        
        bool    virtualMachine = false;
        // STR or SIDT code?
        virtualMachine = insideMatrix();
        if (virtualMachine) {
            DDLogError(@"SERIOUS SECURITY ISSUE DETECTED: SEB was started up in a virtual machine (Test2)!");
        }
    }
    
    // Check for access control privacy permissions to access log folder
    NSString *logPath = [preferences secureStringForKey:@"org_safeexambrowser_SEB_logDirectoryOSX"];
    if (logPath.length > 0) {
        logPath = [logPath stringByExpandingTildeInPath];
        NSURL *logDirectory = [NSURL URLWithString:logPath];
        BOOL isLogDirectoryAccessible = [self directoryIsAccessible:logDirectory directoryType:@"log"];
        if (isLogDirectoryAccessible) {
            DDLogInfo(@"Configured log directory %@", logDirectory.path);
        } else {
            DDLogError(@"Can not access configured log directory %@, ask user to grant privacy access permission.", logDirectory.path);
            [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:pathToSecurityPrivacyPreferences]];
            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];

            NSAlert *modalAlert = [self newAlert];
            [modalAlert setMessageText:NSLocalizedString(@"Grant access to Folder", @"")];
            [modalAlert setInformativeText:[NSString stringWithFormat:@"%@ %@", [NSString stringWithFormat:NSLocalizedString(@"Current settings require access to the directory %@ for saving log files.", @""), logDirectory.path], self.privacyFilesFoldersMessageString]];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", @"")];
            [modalAlert setAlertStyle:NSAlertStyleWarning];
            void (^privacyGrantAccessFilesFolderHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                [self removeAlertWindow:modalAlert.window];
                switch(answer)
                {
                    case NSAlertFirstButtonReturn:
                    {
                        [self conditionallyInitSEBProcessesCheckedWithCallback:callback selector:selector];
                        return;
                    }
                        
                    case NSAlertSecondButtonReturn:
                    {
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"requestQuitSEBOrSession" object:self];
                        return;
                    }
                        
                    default:
                        // Can get invoked in case of NSModalResponseStop=-1000 or NSModalResponseAbort=-1001
                    {
                        DDLogError(@"Alert for granting access to log folder was dismissed by the system with NSModalResponse %ld. Retrying", (long)answer);
                        [self conditionallyInitSEBProcessesCheckedWithCallback:callback selector:selector];
                        return;
                    }
                }
            };
            [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))privacyGrantAccessFilesFolderHandler];
            return;
        }
    }
    
    // Check for access control privacy permissions to access download folders
    NSURL *downloadDirectory = [self.browserController downloadDirectoryURL];
    BOOL isAccessible = [self directoryIsAccessible:downloadDirectory directoryType:@"download"];
    if (isAccessible) {
        DDLogInfo(@"Configured download directory %@", downloadDirectory.path);
        [self conditionallyInitSEBPermissionsCheckWithCallback:callback selector:selector];
    } else {
        DDLogError(@"Can not access configured download directory %@, ask user to grant privacy access permission.", downloadDirectory.path);
        [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:pathToSecurityPrivacyPreferences]];
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];

        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:NSLocalizedString(@"Grant access to Folder", @"")];
        [modalAlert setInformativeText:[NSString stringWithFormat:@"%@ %@", [NSString stringWithFormat:NSLocalizedString(@"Current settings require access to the directory %@ for saving downloads.", @""), downloadDirectory.path], self.privacyFilesFoldersMessageString]];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", @"")];
        [modalAlert setAlertStyle:NSAlertStyleWarning];
        void (^privacyGrantAccessFilesFolderHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self removeAlertWindow:modalAlert.window];
            switch(answer)
            {
                case NSAlertFirstButtonReturn:
                {
                    [self conditionallyInitSEBProcessesCheckedWithCallback:callback selector:selector];
                    return;
                }
                    
                case NSAlertSecondButtonReturn:
                {
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"requestQuitSEBOrSession" object:self];
                    return;
                }
                    
                default:
                    // Can get invoked in case of NSModalResponseStop=-1000 or NSModalResponseAbort=-1001
                {
                    DDLogError(@"Alert for granting access to download folder was dismissed by the system with NSModalResponse %ld. Retrying", (long)answer);
                    [self conditionallyInitSEBProcessesCheckedWithCallback:callback selector:selector];
                    return;
                }
            }
        };
        [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))privacyGrantAccessFilesFolderHandler];
        return;
    }
}

- (BOOL) directoryIsAccessible:(NSURL *)directoryURL directoryType:(NSString *)directoryType
{
    BOOL isAccessible = NO;
    if (directoryURL) {
        NSFileManager *fileManager= [NSFileManager defaultManager];
        NSError *error;
        NSArray<NSURL *> *downloadDirectoryContents = [fileManager contentsOfDirectoryAtURL:directoryURL includingPropertiesForKeys:nil options:0 error:&error];
        DDLogInfo(@"%@ directory can %@be accessed%@.", [directoryType capitalizedString], downloadDirectoryContents ? @"" : @"not ", error ? [NSString stringWithFormat:@" with error: %@", error] : @"");
        if (error == nil) {
            isAccessible = YES;
        } else {
            DDLogError(@"Accessing %@ directory at %@ failed with error %@.%@", directoryType, directoryURL, error, error.code == 257 ? @" Likely the Privacy access control permissions for this folder are not yet granted or were denied (see System Settings / Privacy & Security / Files & Folders / Safe Exam Browser." : @"");
        }
    }
    return isAccessible;
}




- (void) conditionallyInitSEBPermissionsCheckWithCallback:(id)callback
                                                selector:(SEL)selector
{
    DDLogDebug(@"%s", __FUNCTION__);
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Check microphone/camera/screen capturing/proctoring permissions
    
    BOOL browserMediaCaptureCamera = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserMediaCaptureCamera"];
    BOOL browserMediaCaptureMicrophone = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserMediaCaptureMicrophone"];
    BOOL browserMediaCaptureScreen = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserMediaCaptureScreen"];
    
    BOOL screenProctoringEnable = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableScreenProctoring"];
    BOOL jitsiMeetEnable = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetEnable"];
    BOOL zoomEnable = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomEnable"];
    BOOL proctoringSession = jitsiMeetEnable || zoomEnable;
    BOOL webApplications = browserMediaCaptureCamera || browserMediaCaptureMicrophone;
    if (jitsiMeetEnable || zoomEnable) {
        browserMediaCaptureCamera = YES;
        browserMediaCaptureMicrophone = YES;
    }
    BOOL isETHExam = [self.sessionState.startURL.host hasSuffix:@"ethz.ch"] ||
    [_serverController.url.host hasSuffix:@"ethz.ch"];
    
    if ((zoomEnable && !ZoomProctoringSupported) || (jitsiMeetEnable && !JitsiMeetProctoringSupported)) {
        NSString *notAvailableRequiredRemoteProctoringService = [NSString stringWithFormat:@"%@%@", zoomEnable && !ZoomProctoringSupported ? @"Zoom " : @"",
                                                                 jitsiMeetEnable && !JitsiMeetProctoringSupported ? @"Jitsi Meet " : @""];
        DDLogError(@"%@Remote proctoring not available", notAvailableRequiredRemoteProctoringService);
        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:NSLocalizedString(@"Remote Proctoring Not Available", @"")];
        [modalAlert setInformativeText:[NSString stringWithFormat:@"%@%@", [NSString stringWithFormat:NSLocalizedString(@"Current settings require %@remote proctoring, which this %@ version doesn't support. Use the correct %@ version required by your exam organizer.", @""), notAvailableRequiredRemoteProctoringService, SEBShortAppName, SEBShortAppName], zoomEnable == NO ? @"" : [NSString stringWithFormat:@"\n\n%@", NSLocalizedString(@"Due to Zoom licensing issues, Zoom live proctoring is only available for SEB Alliance members. Please see https://safeexambrowser.org/alliance.", @"")]]];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [modalAlert setAlertStyle:NSAlertStyleWarning];
        void (^remoteProctoringDisclaimerHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self removeAlertWindow:modalAlert.window];
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"requestQuitSEBOrSession" object:self];
            return;
        };
        [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))remoteProctoringDisclaimerHandler];
        return;
    }
    
    if (browserMediaCaptureScreen || screenProctoringEnable) {
        if (@available(macOS 10.15, *)) {
            NSString *accessibilityPermissionsTitleString = @"";
            NSString *accessibilityPermissionsMessageString = @"";
            if (screenProctoringEnable) {
                // Check if also Accessibility permissions need to be granted
                NSDictionary *options = @{(__bridge id)
                                          kAXTrustedCheckOptionPrompt : @NO};
                if (!AXIsProcessTrustedWithOptions((CFDictionaryRef)options)) {
                    accessibilityPermissionsTitleString = accessibilityTitleString;
                    accessibilityPermissionsMessageString = [NSString stringWithFormat:@"\n\n%@", self.accessibilityMessageString];
                }
            }
            if (!CGPreflightScreenCaptureAccess()) {
                screenCapturePermissionsRequested = YES;
                if (self.examSession && self.secureClientSession) {
                    // When running an exam session and the client session is secure (has quit pw set), we need to quit the exam session first
                    // but the user or an exam admin will have to quit SEB from the client session manually
                    NSAlert *modalAlert = [self newAlert];
                    [modalAlert setMessageText:[NSString stringWithFormat:@"%@%@", NSLocalizedString(@"Permissions Required for Screen Capture", @""), accessibilityPermissionsTitleString]];
                    [modalAlert setInformativeText:[NSString stringWithFormat:@"%@%@", [NSString stringWithFormat:NSLocalizedString(@"For this exam session, screen capturing is required. You need to authorize Screen Recording for %@ in System Settings / Security & Privacy%@. Then restart %@ and your exam.", @""), SEBFullAppNameClassic, [NSString stringWithFormat:NSLocalizedString(@" (after quitting %@)", @""), SEBShortAppName], SEBShortAppName], accessibilityPermissionsMessageString]];
                    [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit Session", @"")];
                    [modalAlert setAlertStyle:NSAlertStyleCritical];
                    void (^permissionsForProctoringHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                        [self removeAlertWindow:modalAlert.window];
                        [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"requestQuitSEBOrSession" object:self];
                    };
                    [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))permissionsForProctoringHandler];
                    return;
                } else {
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"requestQuitSEBOrSession" object:self];
                    return;
                }
            }
        }
    }
    
    void (^conditionallyStartProctoring)(void);
    conditionallyStartProctoring =
    ^{
        // OK action handler
        void (^startRemoteProctoringOK)(void) =
        ^{
            if (screenProctoringEnable) {
                
            }
            if (zoomEnable) {
                [self openZoomView];
                [self.zoomController openZoomWithSender:self];
            }
            // Continue starting the exam session
            [self conditionallyStartAACWithCallback:callback selector:selector];
        };
        
        void (^conditionallyStartZoomProctoring)(void);
        conditionallyStartZoomProctoring =
        ^{
            if (zoomEnable) {
                // Check if previous SEB session already had proctoring active
                if (self.previousSessionZoomEnabled) {
                    run_on_ui_thread(startRemoteProctoringOK);
                } else {
                    NSAlert *modalAlert = [self newAlert];
                    [modalAlert setMessageText:NSLocalizedString(@"Remote Proctoring Session", @"")];
                    [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"The current session will be remote proctored using a live video and audio stream, which is sent to an individually configured server. Ask your examinator about their privacy policy. %@ itself doesn't connect to any centralized %@ proctoring server, your exam provider decides which proctoring service/server to use.", @""), SEBShortAppName, SEBShortAppName]];
                    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
                    [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
                    [modalAlert setAlertStyle:NSAlertStyleWarning];
                    void (^remoteProctoringDisclaimerHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                        [self removeAlertWindow:modalAlert.window];
                        switch(answer)
                        {
                            case NSAlertFirstButtonReturn:
                            {
                                run_on_ui_thread(startRemoteProctoringOK);
                                return;
                            }
                                
                            case NSAlertSecondButtonReturn:
                            {
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:@"requestQuitSEBOrSession" object:self];
                                return;
                            }
                                
                            default:
                                // Can get invoked in case of NSModalResponseStop=-1000 or NSModalResponseAbort=-1001
                            {
                                DDLogError(@"Alert was dismissed by the system with NSModalResponse %ld. Canceling session with enabled remote proctoring.", (long)answer);
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:@"requestRestartNotification" object:self];
                                return;
                            }
                        }
                    };
                    [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))remoteProctoringDisclaimerHandler];
                    return;
                }
            } else {
                // Continue starting the exam session
                startRemoteProctoringOK();
            }
        };
        
        void (^conditionallyStartScreenProctoring)(void);
        conditionallyStartScreenProctoring =
        ^{
            if (screenProctoringEnable) {
                NSDictionary *options = @{(__bridge id)
                                          kAXTrustedCheckOptionPrompt : @NO};
                NSAlert *modalAlert = nil;
                if (!AXIsProcessTrustedWithOptions((CFDictionaryRef)options)) {
                    DDLogWarn(@"SEB is not trusted in Privacy / Accessibility, prompt the user to grant access in Settings");
                    modalAlert = [self newAlert];
                    [modalAlert setMessageText:NSLocalizedString(@"Accessibility Permissions Required", @"")];
                    [modalAlert setInformativeText:[NSString stringWithFormat:@"%@ %@", self.accessibilityMessageString, [NSString stringWithFormat:NSLocalizedString(@"Then restart %@/the exam.", @""), SEBShortAppName]]];
                    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
                    [modalAlert setAlertStyle:NSAlertStyleCritical];
                    [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow
                      completionHandler:^(NSModalResponse returnCode) {
                        [self removeAlertWindow:modalAlert.window];
                        NSDictionary *options = @{(__bridge id)
                                                  kAXTrustedCheckOptionPrompt : @YES};
                        if (AXIsProcessTrustedWithOptions((CFDictionaryRef)options)) {
                            conditionallyStartZoomProctoring();
                        } else {
                            // Switch the kiosk mode off and override settings for menu bar: Show it while prefs are open
                            [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
                            [self switchKioskModeAppsAllowed:YES overrideShowMenuBar:YES];
                            // Close the black background covering windows
                            [self closeCapWindows];
                            
                            NSAlert *modalAlert = [self newAlert];
                            [modalAlert setMessageText:NSLocalizedString(@"Waiting for Accessibility Permissions", @"")];
                            [modalAlert setInformativeText:[NSString stringWithFormat:@"%@ %@", self.accessibilityMessageString, [NSString stringWithFormat:NSLocalizedString(@"Then restart %@/the exam.", @""), SEBShortAppName]]];
                            [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", @"")];
                            [modalAlert setAlertStyle:NSAlertStyleCritical];
                            [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow
                              completionHandler:^(NSModalResponse returnCode) {
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:@"requestQuitSEBOrSession" object:self];
                            }];
                        }
                    }];
                    return;
                }
            }
            conditionallyStartZoomProctoring();
        };
        

        if (screenProctoringEnable) {
            // Check if previous SEB session already had proctoring active
            if (!self.previousSessionScreenProctoringEnabled) {
                NSAlert *modalAlert = [self newAlert];
                [modalAlert setMessageText:NSLocalizedString(@"Screen Proctoring Session", @"")];
                [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Your screen will be recorded during this exam in accordance with the specifications and data privacy regulations of your exam provider. If you have any questions, please contact your exam provider.%@", @""), isETHExam ? @"":[NSString stringWithFormat:NSLocalizedString(@" %@ itself doesn't connect to any centralized %@ screen proctoring server, your exam provider decides which proctoring service/server to use.", @""), SEBShortAppName, SEBShortAppName]]];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
                [modalAlert setAlertStyle:NSAlertStyleWarning];
                void (^remoteProctoringDisclaimerHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                    [self removeAlertWindow:modalAlert.window];
                    switch(answer)
                    {
                        case NSAlertFirstButtonReturn:
                        {
                            self.previousSessionScreenProctoringEnabled = YES;
                            run_on_ui_thread(conditionallyStartScreenProctoring);
                            return;
                        }
                            
                        case NSAlertSecondButtonReturn:
                        {
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:@"requestQuitSEBOrSession" object:self];
                            return;
                        }
                            
                        default:
                            // Can get invoked in case of NSModalResponseStop=-1000 or NSModalResponseAbort=-1001
                        {
                            DDLogError(@"Alert was dismissed by the system with NSModalResponse %ld. Canceling session with enabled screen proctoring.", (long)answer);
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:@"requestRestartNotification" object:self];
                            return;
                        }
                    }
                };
                [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))remoteProctoringDisclaimerHandler];
                return;
            }
        } else {
            self.previousSessionScreenProctoringEnabled = NO;
        }
        conditionallyStartScreenProctoring();
    };
    
    if (browserMediaCaptureMicrophone ||
        browserMediaCaptureCamera) {
        
        if (@available(macOS 10.14, *)) {
            AVAuthorizationStatus audioAuthorization = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
            AVAuthorizationStatus videoAuthorization = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (((browserMediaCaptureMicrophone && (audioAuthorization != AVAuthorizationStatusAuthorized)) ||
                 (browserMediaCaptureCamera && (videoAuthorization != AVAuthorizationStatusAuthorized)))) {
                
                NSMutableArray <AVMediaType> *authorizationAccessRequests = [NSMutableArray new];
                
                NSString *microphone = (proctoringSession || browserMediaCaptureMicrophone) && audioAuthorization != AVAuthorizationStatusAuthorized ? NSLocalizedString(@"microphone", @"") : @"";
                NSString *camera = @"";
                if ((proctoringSession || browserMediaCaptureCamera) && videoAuthorization != AVAuthorizationStatusAuthorized) {
                    camera = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"camera", @""), microphone.length > 0 ? NSLocalizedString(@" and ", @"") : @""];
                    [authorizationAccessRequests addObject:AVMediaTypeVideo];
                }
                if (microphone.length > 0) {
                    [authorizationAccessRequests addObject:AVMediaTypeAudio];
                }
                NSString *permissionsRequiredFor = [NSString stringWithFormat:@"%@%@%@",
                                                    proctoringSession ? NSLocalizedString(@"remote proctoring", @"") : @"",
                                                    proctoringSession && webApplications ? NSLocalizedString(@" and ", @"") : @"",
                                                    webApplications ? NSLocalizedString(@"web applications", @"") : @""];
                NSString *resolveSuggestion;
                NSString *resolveSuggestion2;
                NSString *message;
                if ((browserMediaCaptureCamera && videoAuthorization == AVAuthorizationStatusDenied) ||
                    (browserMediaCaptureMicrophone && audioAuthorization == AVAuthorizationStatusDenied)) {
                    resolveSuggestion = NSLocalizedString(@"in System Preferences ", @"");
                    resolveSuggestion2 = [NSString stringWithFormat:NSLocalizedString(@"return to %@ and re", @""), SEBShortAppName];
                } else {
                    resolveSuggestion = @"";
                    resolveSuggestion2 = @"";
                }
                if ((browserMediaCaptureCamera && videoAuthorization == AVAuthorizationStatusRestricted) ||
                    (browserMediaCaptureMicrophone && audioAuthorization == AVAuthorizationStatusRestricted)) {
                    message = [NSString stringWithFormat:NSLocalizedString(@"For this session, %@%@ access for %@ is required. On this device, %@%@ access is restricted. Ask your IT support to provide you a device without these restrictions.", @""), camera, microphone, permissionsRequiredFor, camera, microphone];
                } else {
                    message = [NSString stringWithFormat:NSLocalizedString(@"For this session, %@%@ access for %@ is required. You need to authorize %@%@ access %@before you can %@start the session.", @""), camera, microphone, permissionsRequiredFor, camera, microphone, resolveSuggestion, resolveSuggestion2];
                }
                NSString *firstButtonTitle = ((browserMediaCaptureCamera && videoAuthorization == AVAuthorizationStatusDenied) ||
                                              (browserMediaCaptureMicrophone && audioAuthorization == AVAuthorizationStatusDenied)) ? NSLocalizedString(@"System Preferences", @"") : NSLocalizedString(@"OK", @"");
                
                NSAlert *modalAlert = [self newAlert];
                [modalAlert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Permissions Required for %@", @""), permissionsRequiredFor.localizedCapitalizedString]];
                [modalAlert setInformativeText:message];
                [modalAlert addButtonWithTitle:firstButtonTitle];
                if (NSUserDefaults.userDefaultsPrivate) {
                    [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
                }
                [modalAlert setAlertStyle:NSAlertStyleCritical];
                
                // Block for requesting access to camera and microphone
                void (^permissionsForProctoringHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                    [self removeAlertWindow:modalAlert.window];
                    switch(answer)
                    {
                        case NSAlertFirstButtonReturn:
                        {
                            if ((browserMediaCaptureCamera && videoAuthorization == AVAuthorizationStatusDenied) ||
                                (browserMediaCaptureMicrophone && audioAuthorization == AVAuthorizationStatusDenied)) {
                                [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:pathToSecurityPrivacyPreferences]];
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:@"requestQuitSEBOrSession" object:self];
                                return;
                            }
                            [AVCaptureDevice requestAccessForMediaType:authorizationAccessRequests[0] completionHandler:^(BOOL granted) {
                                if (granted){
                                    DDLogInfo(@"Granted access to %@", authorizationAccessRequests[0]);
                                    
                                    if (authorizationAccessRequests.count > 1) {
                                        [AVCaptureDevice requestAccessForMediaType:authorizationAccessRequests[1] completionHandler:^(BOOL granted) {
                                            if (granted){
                                                DDLogInfo(@"Granted access to %@", authorizationAccessRequests[1]);
                                                
                                                run_on_ui_thread(conditionallyStartProctoring);
                                                
                                            } else {
                                                DDLogError(@"Not granted access to %@", authorizationAccessRequests[1]);
                                                [[NSNotificationCenter defaultCenter]
                                                 postNotificationName:@"requestQuitSEBOrSession" object:self];
                                            }
                                        }];
                                    } else {
                                        run_on_ui_thread(conditionallyStartProctoring);
                                    }
                                    return;
                                    
                                } else {
                                    DDLogError(@"Not granted access to %@", authorizationAccessRequests[0]);
                                    [[NSNotificationCenter defaultCenter]
                                     postNotificationName:@"requestQuitSEBOrSession" object:self];
                                }
                            }];
                            return;
                        }
                            
                        case NSAlertSecondButtonReturn:
                        {
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:@"requestQuitSEBOrSession" object:self];
                            return;
                        }
                            
                        default:
                            // Can get invoked in case of NSModalResponseStop=-1000 or NSModalResponseAbort=-1001
                        {
                            DDLogError(@"Alert was dismissed by the system with NSModalResponse %ld. Canceling session with enabled remote proctoring.", (long)answer);
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:@"requestRestartNotification" object:self];
                            return;
                        }
                    }
                    
                };
                // End of Block
                
                [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))permissionsForProctoringHandler];
                return;
                
            } else {
                run_on_ui_thread(conditionallyStartProctoring);
                return;
            }
        } else {
            run_on_ui_thread(conditionallyStartProctoring);
            return;
        }
    } else {
        self.previousSessionZoomEnabled = NO;
    }
    // Continue starting the exam session
    run_on_ui_thread(conditionallyStartProctoring);
}


- (void) conditionallyStartAACWithCallback:(id)callback selector:(SEL)selector
{
    if (!_conditionalInitAfterProcessesChecked) {
        _conditionalInitAfterProcessesChecked = YES;
        /// Early kiosk mode setup (as these actions might take some time)
        
        /// When running on macOS 10.15.4 or newer, use AAC
        if (@available(macOS 10.15.4, *)) {
            DDLogDebug(@"Running on macOS 10.15.4 or newer, may use AAC if allowed in current settings.");
            [self updateAACAvailablility];
            DDLogDebug(@"_isAACEnabled == true, attempting to close cap (background covering) windows, which might have been open from a previous SEB session.");
            [self closeCapWindows];
            DDLogInfo(@"isAACEnabled = %hhd", _isAACEnabled);
            if (_isAACEnabled == YES && _wasAACEnabled == NO) {
                void (^startAssessmentMode)(void) =
                ^{
                    NSApp.presentationOptions |= (NSApplicationPresentationDisableForceQuit | NSApplicationPresentationHideDock);
                    DDLogDebug(@"_isAACEnabled = true && _wasAACEnabled == false");
                    AssessmentModeManager *assessmentModeManager = [[AssessmentModeManager alloc] initWithCallback:callback selector:selector fallback:NO];
                    self.assessmentModeManager = assessmentModeManager;
                    self.assessmentModeManager.delegate = self;
                    NSArray *permittedProcesses = [ProcessManager sharedProcessManager].permittedProcesses;
                    AEAssessmentConfiguration *configuration = [[AEAssessmentConfiguration alloc] initWithPermittedApplications:permittedProcesses];
                    if (@available(macOS 12.0, *)) {
                        if (permittedProcesses.count > 0 &&
                            configuration.configurationsByApplication.count != permittedProcesses.count) {
                            // Not all permitted applications were found or could be started, inform user and quit
                            DDLogError(@"Some permitted apps were not available, SEB will quit");
                            [self showModalQuitAlertTitle:NSLocalizedString(@"Additional Applications Not Available", @"")
                                                     text:[NSString stringWithFormat:@"%@\n%@\n%@", NSLocalizedString(@"This exam session requires the following additional applications to be available:", @""), [permittedProcesses valueForKeyPath:@"title"] , [NSString stringWithFormat:NSLocalizedString(@"%@ will quit now, install the required apps and then restart this exam.", @""), SEBShortAppName]]];
                            return;
                        }
                        if (permittedProcesses.count > 0 &&
                            ![self.assessmentConfigurationManager removeSavedAppWindowStateWithPermittedApplications:permittedProcesses]) {
                            DDLogError(@"Could not remove saved window state for permitted apps, SEB will quit");
                            [self showModalQuitAlertTitle:NSLocalizedString(@"Could Not Access Data of Additional Apps", @"")
                                                     text:[NSString stringWithFormat:NSLocalizedString(@"This exam session requires using additional applications. You have to allow access to their data, as %@ has to remove the saved state of previously open document windows in these apps (%@ is not accessing any of your data created in these apps). %@ will quit now, restart the exam and grant access to the data of additional apps next time.", @""), SEBShortAppName, SEBShortAppName, SEBShortAppName]];
                            return;
                        }
                    }
                    if ([self.assessmentModeManager beginAssessmentModeWithConfiguration:configuration] == NO) {
                        [self assessmentSessionDidEndWithCallback:callback selector:selector quittingToAssessmentMode:NO];
                    }
                };
                
                // Save current string from pasteboard for pasting start URL in Preferences Window
                // and clear pasteboard (latter acutally isn't necessary for AAC)
                [self clearPasteboardSavingCurrentString];
                
                if (@available(macOS 12.1, *)) {
                    // DNS pre-pinning not necessary on macOS 12.1 or newer, as the AAC bug is fixed there
                } else {
                    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
                    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_aacDnsPrePinning"]) {
                        NSArray *permittedDomains = SEBURLFilter.sharedSEBURLFilter.permittedDomains;
                        if (permittedDomains.count == 0) {
                            NSString *urlText = self.sessionState.startURL.absoluteString;
                            if (urlText.length == 0) {
                                urlText = SEBStartPage;
                            }
                            NSURL *startURL = [NSURL URLWithString:urlText];
                            permittedDomains = @[startURL.host];
                        }
                        BOOL result;
                        for (NSString *permittedDomain in permittedDomains) {
                            NSString *host = permittedDomain;
                            if ([permittedDomain hasPrefix:@"."] && permittedDomain.length > 1) {
                                host = [permittedDomain substringFromIndex:1];
                            }
                            CFHostRef hostRef;
                            hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)host);
                            if (hostRef) {
                                result = CFHostStartInfoResolution(hostRef, kCFHostAddresses, NULL); // pass an error instead of NULL here to find out why it failed
                                if (result) {
                                    DDLogDebug(@"Performed DNS pre-pinning of host %@", host);
                                } else {
                                    DDLogDebug(@"DNS pre-pinning of host %@ failed", host);
                                }
                            }
                        }
                    }
                }
                startAssessmentMode();
                return;
            } else if (_isAACEnabled == NO && _wasAACEnabled == YES) {
                DDLogDebug(@"_isAACEnabled = false && _wasAACEnabled == true");
                [self.assessmentModeManager endAssessmentModeWithCallback:callback selector:selector quittingToAssessmentMode:NO];
                return;
            }
        } else {
            _isAACEnabled = NO;
        }
    }
    [self initSEBProcessesCheckedWithCallback:callback selector:selector];
}


/// Assessment Mode Delegate Methods

- (void) assessmentSessionWillBegin
{
    DDLogDebug(@"%s", __FUNCTION__);
    [self.hudController showHUDProgressIndicator];
}

- (void) assessmentSessionWillEnd
{
    DDLogDebug(@"%s", __FUNCTION__);
    [self.hudController showHUDProgressIndicator];
}

- (void) assessmentSessionDidBeginWithCallback:(id)callback
                                      selector:(SEL)selector
                                      fallback:(BOOL)fallback
{
    _isAACEnabled = YES;
    _wasAACEnabled = YES;
    [NSMenu setMenuBarVisible:NO];
    [self.hudController hideHUDProgressIndicator];
    [self.assessmentConfigurationManager autostartAppsWithPermittedApplications:[ProcessManager sharedProcessManager].permittedProcesses];
    [self initSEBProcessesCheckedWithCallback:callback selector:selector];
}

- (void) assessmentSessionFailedToBeginWithError:(NSError *)error
                                        callback:(id)callback
                                        selector:(SEL)selector
                                        fallback:(BOOL)fallback
{
    [self.hudController hideHUDProgressIndicator];
    DDLogError(@"Could not start AAC Assessment Mode, falling back to SEB kiosk mode. Error: %@", error);
    // Use SEB kiosk mode
    _overrideAAC = YES;
    _isAACEnabled = NO;
    _wasAACEnabled = NO;
    [self initSEBProcessesCheckedWithCallback:callback selector:selector];
}


- (void) assessmentSessionDidEndWithCallback:(id)callback
                                    selector:(SEL)selector
                    quittingToAssessmentMode:(BOOL)quittingToAssessmentMode
{
    _wasAACEnabled = NO;
    [self.hudController hideHUDProgressIndicator];
    if (_isTerminating) {
        DDLogDebug(@"%s, continue with callback: %@ selector: %@", __FUNCTION__, callback, NSStringFromSelector(selector));
        IMP imp = [callback methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(callback, selector);
    } else {
        DDLogDebug(@"%s, continue with [self initSEBProcessesCheckedWithCallback:%@ selector: %@]", __FUNCTION__, callback, NSStringFromSelector(selector));
        [self initSEBProcessesCheckedWithCallback:callback selector:selector];
    }
}

- (void) assessmentSessionWasInterruptedWithError:(NSError *)error
{
    [self.hudController hideHUDProgressIndicator];
    DDLogError(@"AAC Assessment Mode was interrupted with error: %@", error);
    
    // Lock the exam down
    
    // Save current time for information about when Guided Access was switched off
    _didResignActiveTime = [NSDate date];
    
    // If there wasn't a lockdown covering view openend yet, initialize it
    [self openLockdownWindows];
    [self appendErrorString:[NSString stringWithFormat:@"%@%@!\n", NSLocalizedString(@"Assessment Mode was interrupted with error: ", @""), error] withTime:_didResignActiveTime repeated:NO];
}


void run_on_ui_thread(dispatch_block_t block)
{
    if ([NSThread isMainThread])
        block();
    else
        dispatch_sync(dispatch_get_main_queue(), block);
}


- (void) initSEBProcessesCheckedWithCallback:(id)callback selector:(SEL)selector
{
    if (_openingSettings) {
        DDLogDebug(@"OpeningSettings = true, abort %s", __FUNCTION__);
        return;
    }
    DDLogDebug(@"%s callback: %@ selector: %@", __FUNCTION__, callback, NSStringFromSelector(selector));
    
    /// Early kiosk mode setup (as these actions might take some time)
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (_isAACEnabled == NO) {
        DDLogDebug(@"%s: isAACEnabled = false, using SEB kiosk mode", __FUNCTION__);
        
        // Hide all other applications
        [[NSWorkspace sharedWorkspace] performSelectorOnMainThread:@selector(hideOtherApplications)
                                                        withObject:NULL waitUntilDone:YES];
        
        allowScreenCapture = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowScreenCapture"];
        allowDictionaryLookup = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDictionaryLookup"];
        allowOpenAndSavePanel = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowOpenAndSavePanel"];
        allowShareSheet = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowShareSheet"];
    }
    // Switch off display mirroring and find main active screen according to settings
    [self conditionallyTerminateDisplayMirroring];
    
    if (_isAACEnabled == NO) {
        
        // Switch off Siri and dictation if not allowed in settings
        [self conditionallyDisableSpeechInput];
        
        // Switch off TouchBar features
        [self disableTouchBarFeatures];
        
        // Switch to kiosk mode by setting the proper presentation options
        [self setElevateWindowLevels];
        [self startKioskMode];
        
        // Clear pasteboard and save current string for pasting start URL in Preferences Window
        [self clearPasteboardSavingCurrentString];
        
        // Check if the Force Quit window is open
        if (![self forceQuitWindowCheckContinue]) {
            return;
        }
        
        // Run watchdog event for windows and events which need to be observed
        // on the main (UI!) thread once, to initialize
        dispatch_async(dispatch_get_main_queue(), ^{
            [self windowWatcher];
        });
    }
    
    /// Update URL filter flags and rules
    [[SEBURLFilter sharedSEBURLFilter] updateFilterRulesWithStartURL:self.startURL];
    // Update URL filter ignore rules
    [[SEBURLFilter sharedSEBURLFilter] updateIgnoreRuleList];
    
    // Set up and open SEB Dock
    [self openSEBDock];
    self.browserController.dockController = self.dockController;
    self.dockController.dockButtonDelegate = self;
        
    // Continue starting the exam session
    IMP imp = [callback methodForSelector:selector];
    void (*func)(id, SEL) = (void *)imp;
    func(callback, selector);
}


- (void) startSystemMonitoring
{
    // Get all running processes, including daemons
    NSArray *allRunningProcesses = [self getProcessArray];
    NSArray *allRunningProcessNames = [allRunningProcesses valueForKey:@"name"];
    DDLogInfo(@"There are %lu running BSD processes: \n%@", (unsigned long)allRunningProcessNames.count, allRunningProcessNames);
    
    if (_isAACEnabled == NO) {
        // Check for activated screen sharing if settings demand it
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        allowScreenSharing = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowScreenSharing"] &&
        ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_screenSharingMacEnforceBlocked"];
        allowSiri = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSiri"];
        allowDictation = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDictation"];
        
        if (!allowScreenSharing &&
            ([allRunningProcessNames containsObject:screenSharingAgent] ||
             [allRunningProcessNames containsObject:AppleVNCAgent]))
        {
            // Screen sharing is active
            DDLogError(@"Screen Sharing Detected, SEB will quit");
            [self showModalQuitAlertTitle:NSLocalizedString(@"Screen Sharing Detected!", @"")
                                     text:[NSString stringWithFormat:@"%@\n\n%@",
                                           [NSString stringWithFormat:NSLocalizedString(@"You are not allowed to have screen sharing active while running %@. Restart %@ after switching screen sharing off.", @""), SEBShortAppName, SEBShortAppName],
                                           [NSString stringWithFormat:NSLocalizedString(@"To avoid that %@ locks itself during an exam when it detects that screen sharing started, it's best to switch off 'Screen Sharing' and 'Remote Management' in System Settings/Sharing. You can also ask your network administrators to block ports used for the VNC protocol.", @""), SEBShortAppName]]];
            return;
        }
        
        if (!allowSiri &&
            [allRunningProcessNames containsObject:SiriService] &&
            [[preferences valueForDefaultsDomain:SiriDefaultsDomain key:SiriDefaultsKey] boolValue])
        {
            // Siri is active
            DDLogError(@"Siri Detected, SEB will quit");
            [self showModalQuitAlertTitle:NSLocalizedString(@"Siri Detected!", @"")
                                     text:[NSString stringWithFormat:NSLocalizedString(@"You are not allowed to have Siri enabled while running %@. Restart %@ after switching Siri off in System Settings/Siri.", @""), SEBShortAppName, SEBShortAppName]];
            return;
        }
        
        if (!allowDictation &&
            [allRunningProcessNames containsObject:DictationProcess] &&
            ([[preferences valueForDefaultsDomain:DictationDefaultsDomain key:DictationDefaultsKey] boolValue] ||
             [[preferences valueForDefaultsDomain:RemoteDictationDefaultsDomain key:RemoteDictationDefaultsKey] boolValue]))
        {
            // Dictation is active
            DDLogError(@"Dictation Detected, SEB will quit");
            [self showModalQuitAlertTitle:NSLocalizedString(@"Dictation Detected!", @"")
                                     text:[NSString stringWithFormat:NSLocalizedString(@"You are not allowed to have dictation enabled while running %@. Restart %@ after switching dictation off in System Settings/Keyboard/Dictation.", @""), SEBShortAppName, SEBShortAppName]];
            return;
        }
    }
    [self startProcessWatcher];
    [self startWindowWatcher];
}


- (void)showModalQuitAlertTitle:(NSString *)title text:(NSString *)text
{
    NSAlert *modalAlert = [self newAlert];
    [modalAlert setMessageText:title];
    [modalAlert setInformativeText:text];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", @"")];
    [modalAlert setAlertStyle:NSAlertStyleCritical];
    void (^quitAlertConfirmed)(NSModalResponse) = ^void (NSModalResponse answer) {
        DDLogDebug(@"%s: %@: NSModalResponse: %ld", __FUNCTION__, title, (long)answer);
        [self removeAlertWindow:modalAlert.window];
        [self requestedExit:nil]; // Quit SEB
    };
    [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))quitAlertConfirmed];
}


#pragma mark - After Start Initialization

// Perform actions which require that SEB has finished setting up and has opened its windows
- (void) performAfterStartActions:(NSNotification *)notification
{
    DDLogDebug(@"%s", __FUNCTION__);
    DDLogInfo(@"Performing after start actions");
    
    if (_isAACEnabled == NO) {
        // Check for command key being held down
        [self appSwitcherCheck];
        
        // Reinforce the kiosk mode
        [self requestedReinforceKioskMode:nil];
    }
    
    if ([[MyGlobals sharedMyGlobals] preferencesReset] == YES) {
        DDLogError(@"Presenting alert for 'Local SEB settings have been reset' (which was triggered before)");
        [self presentPreferencesCorruptedError];
    }
    
    if (_isAACEnabled == NO) {
        // Check if the Force Quit window is open
        if (![self forceQuitWindowCheckContinue]) {
            return;
        }
    }
    
    if ([MyGlobals sharedMyGlobals].reconfiguredWhileStarting) {
        // Show alert that SEB was reconfigured
        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"%@ Re-Configured", @""), SEBShortAppName]];
         [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"New settings have been saved, they will be used when you start %@ next time again. Do you want to continue working with %@ or quit for now?", @""), SEBShortAppName, SEBShortAppName]];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"Continue", @"")];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", @"")];
        void (^reconfiguredAnswer)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self removeAlertWindow:modalAlert.window];
            switch(answer)
            {
                case NSAlertFirstButtonReturn:
                    
                    break; //Continue running SEB
                    
                case NSAlertSecondButtonReturn:
                {
                    [self performSelector:@selector(requestedExit:) withObject: nil afterDelay: 3];
                }
            }
        };
        [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))reconfiguredAnswer];
    }
    
    // Set flag that SEB is initialized: Now showing alerts is allowed
    [[MyGlobals sharedMyGlobals] setFinishedInitializing:YES];
}


#pragma mark - Logger Initialization

// Initializes a temporary logger unconditionally with the Debug log level
// and the standard log file path, so SEB can log startup events before
// settings are initialized
- (void) initializeTemporaryLogger
{
    _myLogger = [MyGlobals initializeFileLoggerWithDirectory:nil];
    [DDLog addLogger:_myLogger];
    
    DDLogInfo(@"---------- STARTING UP SEB - INITIALIZE SETTINGS -------------");
    DDLogInfo(@"(log after start up is finished may continue in another file, according to current settings)");
    [MyGlobals logSystemInfo];
}

- (void) initializeLogger
{
    // Initialize file logger if logging enabled
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableLogging"] == NO) {
        [DDLog removeLogger:_myLogger];
        _myLogger = nil;
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebMode"] == sebModeSebServer) {
            [DDLog removeLogger:ServerLogger.sharedInstance];
        }
    } else {
        //Set log directory
        NSString *logPath = [[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_logDirectoryOSX"];
        [DDLog removeLogger:_myLogger];
        if (logPath.length == 0) {
            // No log directory indicated: We use the standard one
            logPath = nil;
        } else {
            logPath = [logPath stringByExpandingTildeInPath];
            // Add subdirectory with the name of the computer
        }
        _myLogger = [MyGlobals initializeFileLoggerWithDirectory:logPath];
        [DDLog addLogger:_myLogger];
        
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebMode"] == sebModeSebServer ||
            _establishingSEBServerConnection || _sebServerConnectionEstablished) {
            if (![DDLog.allLoggers containsObject:ServerLogger.sharedInstance]) {
                [DDLog addLogger:ServerLogger.sharedInstance];
                ServerLogger.sharedInstance.delegate = self;
            }
        }
        
        DDLogInfo(@"---------- INITIALIZING SEB - STARTING SESSION -------------");
        [MyGlobals logSystemInfo];
    }
}


- (void) sendLogEventWithLogLevel:(NSUInteger)logLevel
                        timestamp:(NSString *)timestamp
                     numericValue:(double)numericValue
                          message:(NSString *)message
{
    [self.serverController sendLogEventWithLogLevel:logLevel timestamp:timestamp numericValue:numericValue message:message];
}


#pragma mark - Process Monitoring

- (NSArray *) getProcessNameArray {
    NSMutableArray *ProcList = [[NSMutableArray alloc] init];
    
    kinfo_proc *mylist;
    size_t mycount = 0;
    mylist = (kinfo_proc *)malloc(sizeof(kinfo_proc));
    GetBSDProcessList(&mylist, &mycount);
    BOOL numberRunningBSDProcessesChanged = false;
    if ((NSUInteger)mycount != lastNumberRunningBSDProcesses) {
        numberRunningBSDProcessesChanged = true;
        lastNumberRunningBSDProcesses = (NSUInteger)mycount;
        DDLogVerbose(@"There are %lu running BSD processes.", (unsigned long)lastNumberRunningBSDProcesses);
    }
    int k;
    for(k = 0; k < mycount; k++) {
        kinfo_proc *proc = NULL;
        proc = &mylist[k];
        pid_t processPID = proc-> kp_proc.p_pid;
        NSString * processName = [self getProcessName:processPID];
        [ProcList addObject:processName];
        if (numberRunningBSDProcessesChanged) {
            DDLogVerbose(@"PID: %d - Name: %s", proc->kp_proc.p_pid, proc-> kp_proc.p_comm);
        }
    }
    free(mylist);
    
    return ProcList;
}


- (NSArray <NSDictionary *>*) getProcessArray {
    NSMutableArray *ProcList = [[NSMutableArray alloc] init];
    
    kinfo_proc *mylist;
    size_t mycount = 0;
    mylist = (kinfo_proc *)malloc(sizeof(kinfo_proc));
    GetBSDProcessList(&mylist, &mycount);
    BOOL numberRunningBSDProcessesChanged = false;
    if ((NSUInteger)mycount != lastNumberRunningBSDProcesses) {
        numberRunningBSDProcessesChanged = true;
        lastNumberRunningBSDProcesses = (NSUInteger)mycount;
        DDLogVerbose(@"There are %lu running BSD processes.", (unsigned long)lastNumberRunningBSDProcesses);
    }
    NSDictionary *processDetails;
    int k;
    for(k = 0; k < mycount; k++) {
        kinfo_proc *proc = NULL;
        proc = &mylist[k];
        pid_t processPID = proc-> kp_proc.p_pid;
        NSString * processName = [self getProcessName:processPID];
        processDetails = @{
                           @"name" : processName,
                           @"PID" : [NSNumber numberWithInt:processPID]
                           };
        [ProcList addObject:processDetails];
        if (numberRunningBSDProcessesChanged) {
            DDLogVerbose(@"PID: %d - Name: %@", processPID, processName);
        }
    }
    free(mylist);
    
    return ProcList;
}



-(NSString*) getProcessName:(pid_t) pid {
    char executablePath[PROC_PIDPATHINFO_MAXSIZE];
    NSString *executableStringPath = [[NSString alloc] init];
    bzero(executablePath, PROC_PIDPATHINFO_MAXSIZE);
    proc_pidpath(pid, executablePath, sizeof(executablePath));
    if (sizeof(executablePath) > 0) {
        executableStringPath = @(executablePath);
    }
    return executableStringPath.lastPathComponent;
}


// Obsolete
- (NSDictionary *) getProcessDictionary {
    NSMutableDictionary *ProcList = [[NSMutableDictionary alloc] init];
    
    kinfo_proc *mylist;
    size_t mycount = 0;
    mylist = (kinfo_proc *)malloc(sizeof(kinfo_proc));
    GetBSDProcessList(&mylist, &mycount);
    BOOL numberRunningBSDProcessesChanged = false;
    if ((NSUInteger)mycount != lastNumberRunningBSDProcesses) {
        numberRunningBSDProcessesChanged = true;
        lastNumberRunningBSDProcesses = (NSUInteger)mycount;
        DDLogVerbose(@"There are %lu running BSD processes: ", (unsigned long)lastNumberRunningBSDProcesses);
    }
    int k;
    for(k = 0; k < mycount; k++) {
        kinfo_proc *proc = NULL;
        proc = &mylist[k];
        NSString *processName = [NSString stringWithFormat: @"%s",proc-> kp_proc.p_comm];
        if (processName == nil) {
            processName = @"";
        }
        [ ProcList setObject: processName forKey: @"name" ];
        [ ProcList setObject: [NSNumber numberWithInt:proc->kp_proc.p_pid] forKey: @"PID"];
    }
    free(mylist);
    
    if (numberRunningBSDProcessesChanged) {
        DDLogVerbose(@"%@", ProcList);
    }
    return ProcList;
}


typedef struct kinfo_proc kinfo_proc;

static int GetBSDProcessList(kinfo_proc **procList, size_t *procCount)
// Returns a list of all BSD processes on the system.  This routine
// allocates the list and puts it in *procList and a count of the
// number of entries in *procCount.  You are responsible for freeing
// this list (use "free" from System framework).
// On success, the function returns 0.
// On error, the function returns a BSD errno value.
{
    int                 err;
    kinfo_proc *        result;
    bool                done;
    static const int    name[] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    // Declaring name as const requires us to cast it when passing it to
    // sysctl because the prototype doesn't include the const modifier.
    size_t              length;
    
    *procCount = 0;
    
    // We start by calling sysctl with result == NULL and length == 0.
    // That will succeed, and set length to the appropriate length.
    // We then allocate a buffer of that size and call sysctl again
    // with that buffer.  If that succeeds, we're done.  If that fails
    // with ENOMEM, we have to throw away our buffer and loop.  Note
    // that the loop causes use to call sysctl with NULL again; this
    // is necessary because the ENOMEM failure case sets length to
    // the amount of data returned, not the amount of data that
    // could have been returned.
    
    result = NULL;
    done = false;
    do {
        
        // Call sysctl with a NULL buffer.
        
        length = 0;
        err = sysctl( (int *) name, (sizeof(name) / sizeof(*name)) - 1,
                     NULL, &length,
                     NULL, 0);
        if (err == -1) {
            err = errno;
        }
        
        // Allocate an appropriately sized buffer based on the results
        // from the previous call.
        
        if (err == 0) {
            result = malloc(length);
            if (result == NULL) {
                err = ENOMEM;
            }
        }
        
        // Call sysctl again with the new buffer.  If we get an ENOMEM
        // error, toss away our buffer and start again.
        
        if (err == 0) {
            err = sysctl( (int *) name, (sizeof(name) / sizeof(*name)) - 1,
                         result, &length,
                         NULL, 0);
            if (err == -1) {
                err = errno;
            }
            if (err == 0) {
                done = true;
            } else if (err == ENOMEM) {
                free(result);
                result = NULL;
                err = 0;
            }
        }
    } while (err == 0 && ! done);
    
    // Clean up and establish post conditions.
    
    if (err != 0 && result != NULL) {
        free(result);
        result = NULL;
    }
    *procList = result;
    if (err == 0) {
        *procCount = length / sizeof(kinfo_proc);
    }
    
    return err;
}


#pragma mark - Window/Panel Monitoring

// Start the process watcher if it's not yet running
- (void)startProcessWatcher
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (!_processWatchTimer) {
        dispatch_source_t newProcessWatchTimer =
        [ProcessManager createDispatchTimerWithInterval:0.25 * NSEC_PER_SEC
                                                 leeway:(0.25 * NSEC_PER_SEC) / 10
                                          dispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                                          dispatchBlock:^{
            [self processWatcher];
        }];
        _processWatchTimer = newProcessWatchTimer;
    }
}


// Start the process watcher if it's not yet running
- (void)stopProcessWatcher
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (_processWatchTimer) {
        dispatch_source_cancel(_processWatchTimer);
        _processWatchTimer = 0;
    }
}


// Start the windows watcher if it's not yet running
- (void)startWindowWatcher
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (!_windowWatchTimer) {
        NSDate *dateNextMinute = [NSDate date];
        
        _windowWatchTimer = [[NSTimer alloc] initWithFireDate: dateNextMinute
                                                     interval: 0.25
                                                       target: self
                                                     selector:@selector(windowWatcher)
                                                     userInfo:nil repeats:YES];
        
        NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
        [currentRunLoop addTimer:_windowWatchTimer forMode: NSRunLoopCommonModes];
    }
}


// Start the windows watcher if it's not yet running
- (void)stopWindowWatcher
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (_windowWatchTimer) {
        [_windowWatchTimer invalidate];
        _windowWatchTimer = nil;
    }
}


-(void)processWatcher
{
    if (checkingRunningProcesses) {
        DDLogDebug(@"Check for prohibited processes still ongoing, return");
        return;
    }
    checkingRunningProcesses = true;
    
    NSDate *lastTimeProcessCheckBeforeSIGSTOP = lastTimeProcessCheck;
    NSTimeInterval timeSinceLastProcessCheck = [lastTimeProcessCheckBeforeSIGSTOP timeIntervalSinceNow];
    if (!_systemSleeping && detectSIGSTOP && -timeSinceLastProcessCheck > 3 && timeSinceLastProcessCheck <= 0) {
        DDLogError(@"Detected SIGSTOP! SEB was stopped for %f seconds", -timeSinceLastProcessCheck);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.SIGSTOPDetected) {
                self.SIGSTOPDetected = YES;
                self->timeProcessCheckBeforeSIGSTOP = lastTimeProcessCheckBeforeSIGSTOP;
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"detectedSIGSTOP" object:self];
            }
        });
    }
    
    // Check if not allowed/prohibited processes were activated
    // Get all running processes, including daemons
    NSArray *allRunningProcesses = [self getProcessArray];
    self.runningProcesses = allRunningProcesses;
    NSPredicate *processNameFilter;
    NSArray *filteredProcesses;
    
    // Check for font download process
    if (!_allowSwitchToApplications || _isAACEnabled) {
        processNameFilter = [NSPredicate predicateWithFormat:@"name ==[cd] %@ ", fontRegistryUIAgent];
        filteredProcesses = [allRunningProcesses filteredArrayUsingPredicate:processNameFilter];
        if (filteredProcesses.count > 0) {
            if (!fontRegistryUIAgentRunning) {
                fontRegistryUIAgentRunning = YES;
                fontRegistryUIAgentDialogClosed = NO;
                fontRegistryUIAgentSkipDownloadCounter = 20;
            }
            if (fontRegistryUIAgentSkipDownloadCounter > 0 && !fontRegistryUIAgentDialogClosed) {
                
                DDLogWarn(@"%@ is running, and most likely opened dialog to ask user if a font used on the current webpage should be downloaded or skipped. SEB is sending an Event Tap for the key Return (Carriage Return) to close that dialog (invoke default button Skip)", fontRegistryUIAgent);

                if (@available(macOS 10.9, *)) {
                    
                    NSDictionary *options = @{(__bridge id)
                                              kAXTrustedCheckOptionPrompt : @YES};
                    // Check if we're trusted - and the option means "Prompt the user
                    // to trust this app in System Preferences."
                    if (AXIsProcessTrustedWithOptions((CFDictionaryRef)options)) {
                        DDLogDebug(@"SEB is trusted in Privacy / Accessibility");
                        // Now you can use the accessibility APIs
                        DDLogDebug(@"Sending an Event Tap for the key Return (Carriage Return) to close the font donwload dialog (invoking default button Skip)");
                        CGEventPost(kCGSessionEventTap, keyboardEventReturnKey);
                        fontRegistryUIAgentSkipDownloadCounter--;

                    } else {
                        DDLogError(@"SEB is not trusted in Privacy / Accessibility, terminating SEB");
                        
                        // Persist that this event happened and details
                        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
                        [preferences setPersistedSecureBool:YES forKey:fontDownloadAttemptedKey];
                        [preferences setPersistedSecureObject:self.browserController.activeBrowserWindowTitle forKey:fontDownloadAttemptedOnPageTitleKey];
                        [preferences setPersistedSecureObject:[self.browserController placeholderTitleOrURLForActiveWebpage] forKey:fontDownloadAttemptedOnPageURLOrPlaceholderKey];

                        exit(0); //quit SEB
                    }
                } else {
                    // Pre macOS 10.9: Most likely there was no font registry UI agent yet, so this code would be obsolete
                    CGEventPost(kCGSessionEventTap, keyboardEventReturnKey);
                }
                
            } else if (!fontRegistryUIAgentDialogClosed) {
                DDLogError(@"%@ is still running, and the dialog to ask user if a font used on the current webpage should be downloaded or skipped couldn't be closed by SEB. SEB is being force terminated to avoid locking/freezing the Mac completely!", fontRegistryUIAgent);

                exit(0); //quit SEB
            }
        } else {
            if (fontRegistryUIAgentRunning) {
                fontRegistryUIAgentRunning = NO;
                DDLogWarn(@"%@ stopped running", fontRegistryUIAgent);
            }
        }
    }
    // Check for running screen capture process
    if (!allowScreenCapture || _isAACEnabled) {
        NSDictionary *processDetails = nil;
        NSError *error = [self runningProcessCheckForName:screenCaptureAgent inRunningProcesses:&allRunningProcesses processDetails:&processDetails];
        if (processDetails) {
            DDLogDebug(@"Terminating %@ was %@successfull (error: %@)", processDetails, error ? @"not " : @"", error);
        }
    }
    
    if (@available(macOS 13.0, *)) {
        if (!allowDictionaryLookup) {
            NSDictionary *processDetails = nil;
            NSError *error = [self runningProcessCheckForName:lookupQuicklookHelper inRunningProcesses:&allRunningProcesses processDetails:&processDetails];
            if (processDetails) {
                DDLogDebug(@"Lookup is not allowed in settings: Terminating %@ was %@successfull (error: %@)", processDetails, error ? @"not " : @"", error);
                processDetails = nil;
            }

            error = [self runningProcessCheckForName:lookupViewService inRunningProcesses:&allRunningProcesses processDetails:&processDetails];
            if (processDetails) {
                DDLogDebug(@"Lookup is not allowed in settings: Terminating %@ was %@successfull (error: %@)", processDetails, error ? @"not " : @"", error);
            }
        }
    }
    // Kill Passwords menu bar extra if running
    NSDictionary *processDetails = nil;
    NSError *error = [self runningProcessCheckForName:PasswordsMenuBarExtraExecutable inRunningProcesses:&allRunningProcesses processDetails:&processDetails];
    if (processDetails) {
        DDLogDebug(@"Terminating %@ was %@successfull (error: %@)", processDetails, error ? @"not " : @"", error);
    }
    
    if (@available(macOS 15.1, *)) {
        // Kill AI Writing Tools if running
        processDetails = nil;
        error = [self runningProcessCheckForName:WritingToolsExecutable inRunningProcesses:&allRunningProcesses processDetails:&processDetails];
        if (processDetails) {
            DDLogDebug(@"Terminating %@ was %@successfull (error: %@)", processDetails, error ? @"not " : @"", error);
        }
    }
    
    // Check for prohibited BSD processes
    NSArray *prohibitedProcesses = [ProcessManager sharedProcessManager].prohibitedBSDProcesses.copy;
    for (NSString *executableName in prohibitedProcesses) {
        // Wildcards are allowed when filtering process names
        processNameFilter = [NSPredicate predicateWithFormat:@"name LIKE %@", executableName];
        filteredProcesses = [allRunningProcesses filteredArrayUsingPredicate:processNameFilter];
        if (filteredProcesses.count > 0) {
            for (NSDictionary *runningProhibitedProcess in filteredProcesses) {
                NSNumber *PID = [runningProhibitedProcess objectForKey:@"PID"];
                [self killProcessWithPID:PID.intValue];
            }
        }
    }
    
    lastTimeProcessCheck = [NSDate date];
    checkingRunningProcesses = NO;
}

- (NSError *)runningProcessCheckForName:(NSString *)name inRunningProcesses:(NSArray **)allRunningProcesses processDetails:(NSDictionary **)processDetails
{
    NSPredicate *processNameFilter = [NSPredicate predicateWithFormat:@"name ==[cd] %@ ", name];
    NSArray *filteredProcesses = [*allRunningProcesses filteredArrayUsingPredicate:processNameFilter];

    NSError *error = nil;
    if (filteredProcesses.count > 0) {
        *processDetails = filteredProcesses[0];
        NSNumber *PID = [*processDetails objectForKey:@"PID"];
        error = [self killProcessWithPID:PID.intValue];
    }
    return error;
}


- (void)windowWatcher
{
    // Check if the font download dialog (if displayed) was successfully closed
    if (fontRegistryUIAgentRunning && !fontRegistryUIAgentDialogClosed) {
        // The dialog was probably displayed and the main thread (and this timer) blocked a while
        // But now the dialog was successfully closed and the main thread is running again
        // stop the process watcher from trying to close the dialog by sending
        // a return key tap
        fontRegistryUIAgentDialogClosed = YES;
        DDLogWarn(@"%@ is still running, but the displayed dialog to ask user if a font used on the current webpage should be downloaded or skipped was most likely closed by SEB.", fontRegistryUIAgent);
    }

    if (checkingForWindows) {
        DDLogDebug(@"Check for prohibited windows still ongoing, returning");
        return;
    }
    checkingForWindows = YES;
    
    if (_isAACEnabled == NO && _wasAACEnabled == NO) {
        CGWindowListOption options;
        BOOL firstScan = NO;
        BOOL fishyWindowWasOpened = NO;
        if (!_systemProcessPIDs) {
            // When this method is called the first time, we scan all windows
            firstScan = YES;
            _systemProcessPIDs = [NSMutableArray new];
            options = kCGWindowListOptionAll;
            fishyWindowWasOpened = YES;

        } else {
            // otherwise only those which are visible (on screen)
            options = kCGWindowListOptionOnScreenOnly; // | kCGWindowListExcludeDesktopElements
        }
        
        NSArray *windowList = CFBridgingRelease(CGWindowListCopyWindowInfo(options, kCGNullWindowID));
        for (NSDictionary *window in windowList) {
            NSString *windowName = [window objectForKey:@"kCGWindowName" ];
            NSString *windowOwner = [window objectForKey:@"kCGWindowOwnerName" ];
    #ifdef DEBUG
            NSString *windowNumber = [window objectForKey:@"kCGWindowNumber" ];
    #endif

            // Close Control Center windows or the Notification Center panel (older macOS versions)
            if ((([windowOwner isEqualToString:@"Notification Center"] && !_allowSwitchToApplications) || [windowName isEqualToString:@"NotificationTableWindow"]) &&
                ![_preferencesController preferencesAreOpen]) {
                DDLogWarn(@"Control/Notification Center was opened (owning process name: %@", windowOwner);
                NSArray *notificationCenterSearchResult =[NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.notificationcenterui"];
                if (notificationCenterSearchResult.count > 0) {
                    NSRunningApplication *notificationCenter = notificationCenterSearchResult[0];
                    [notificationCenter forceTerminate];
                }
                continue;
            }
            
            NSString *windowLevelString = [window objectForKey:@"kCGWindowLayer" ];
            NSInteger windowLevel = windowLevelString.integerValue;
            if (windowLevel >= NSMainMenuWindowLevel+2) {
                NSString *windowOwnerPIDString = [window objectForKey:@"kCGWindowOwnerPID"];
                pid_t windowOwnerPID = windowOwnerPIDString.intValue;
                // If this isn't a SEB window
                if (windowOwnerPID != sebPID) {
                    if (![_systemProcessPIDs containsObject:windowOwnerPIDString]) {
                        // If this process isn't in the list of previously scanned and verified
                        // running legit Apple executables
                        NSRunningApplication *appWithPanel = [NSRunningApplication runningApplicationWithProcessIdentifier:windowOwnerPID];
                        NSString *appWithPanelBundleID = appWithPanel.bundleIdentifier;
#ifndef DEBUG
                        DDLogWarn(@"Application %@ with bundle ID %@ has opened a window with level %@", windowOwner, appWithPanelBundleID, windowLevelString);
#endif
    #ifdef DEBUG
                        CGSConnection connection = _CGSDefaultConnection();
                        int workspace;
                        int windowID = windowNumber.intValue;
                        CGSGetWindowWorkspace(connection, windowID, &workspace);
                        DDLogVerbose(@"Window %@ is on space %d", windowName, workspace);
    #endif
                        if (!_allowSwitchToApplications && ![_preferencesController preferencesAreOpen]) {
                            if (appWithPanelBundleID && ![appWithPanelBundleID hasPrefix:@"com.apple."]) {
                                // Application hasn't a com.apple. bundle ID prefix
                                // The app which opened the window or panel is no system process
                                if (firstScan) {
                                    DDLogVerbose(@"First scan, don't terminate application %@ (%@)", windowOwner, appWithPanelBundleID);
                                    //[appWithPanel terminate];
                                } else {
                                    DDLogWarn(@"Application %@ is being force terminated because its bundle ID doesn't have the prefix com.apple.", windowOwner);
                                    [self killApplication:appWithPanel];
                                    fishyWindowWasOpened = YES;
                                }
                            } else {
#ifdef DEBUG
                                if ([appWithPanelBundleID isEqualToString:XcodeBundleID]) {
                                    DDLogVerbose(@"Don't terminate application %@ (%@)", windowOwner, appWithPanelBundleID);
                                    [_systemProcessPIDs addObject:windowOwnerPIDString];
                                    continue;
                                }
#else
                                if ([appWithPanelBundleID isEqualToString:FinderBundleID]) {
                                    DDLogWarn(@"Application %@ is being force terminated because it displayed a window in the foreground and this might be used for previewing files!", windowOwner);
                                    [self killProcessWithPID:windowOwnerPID];
                                }
#endif
                                // There is either no bundle ID or the prefix is com.apple.
                                // Check if application with Bundle ID com.apple. is a legit Apple system executable
                                DDLogDebug(@"Check if application %@ (%@) is a signed system executable", windowOwner, appWithPanelBundleID);
                                if ([self signedSystemExecutable:windowOwnerPID]) {
                                    // Cache this executable PID
                                    DDLogDebug(@"Yes, application %@ (%@) is a signed system executable", windowOwner, appWithPanelBundleID);
                                    [_systemProcessPIDs addObject:windowOwnerPIDString];
                                } else {
                                    // The app which opened the window or panel is no system process
                                    if (firstScan) {
                                        DDLogDebug(@"First scan, don't terminate application %@ (%@)", windowOwner, appWithPanelBundleID);
                                        //[appWithPanel terminate];
                                    } else {
                                        DDLogWarn(@"Application %@ is being force terminated because it isn't macOS system software!", windowOwner);
                                        [self killProcessWithPID:windowOwnerPID];
                                        fishyWindowWasOpened = YES;
                                    }
                                }
                            }
                        } else {
#ifndef DEBUG
                            DDLogDebug(@"%@%@don't terminate application %@ (%@)", _allowSwitchToApplications ? @"Switching to applications is allowed, " : @"",
                                       _preferencesController.preferencesAreOpen ? @"Preferences are open, " : @"", windowOwner, appWithPanelBundleID);
#endif
                        }
                    }
                }
            }
        }
        if (fishyWindowWasOpened) {
            DDLogVerbose(@"Window list: %@", windowList);
        }
    }
    
    // Check if not allowed/prohibited processes was activated
    // Get all running processes, including daemons
    NSArray *allRunningProcesses = [self.runningProcesses copy];
    
    // Check for activated screen sharing if settings demand it
    if (!_isAACEnabled && _wasAACEnabled == NO && !allowScreenSharing && !self.sessionState.screenSharingCheckOverride &&
        ([allRunningProcesses containsProcessObject:screenSharingAgent] ||
         [allRunningProcesses containsProcessObject:AppleVNCAgent])) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"detectedScreenSharing" object:self];
        }
    
    // Check for activated Siri if settings demand it
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (!_isAACEnabled && _wasAACEnabled == NO && !_startingUp && !allowSiri && !self.sessionState.siriCheckOverride &&
        [allRunningProcesses containsProcessObject:SiriService] &&
        [[preferences valueForDefaultsDomain:SiriDefaultsDomain key:SiriDefaultsKey] boolValue]) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"detectedSiri" object:self];
        }
    
    // Check for activated dictation if settings demand it
    if (!_isAACEnabled && _wasAACEnabled == NO && !_startingUp && !allowDictation && !self.sessionState.dictationCheckOverride &&
        [allRunningProcesses containsProcessObject:DictationProcess] &&
        ([[preferences valueForDefaultsDomain:DictationDefaultsDomain key:DictationDefaultsKey] boolValue] ||
         [[preferences valueForDefaultsDomain:RemoteDictationDefaultsDomain key:RemoteDictationDefaultsKey] boolValue])) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"detectedDictation" object:self];
        }
    
    checkingForWindows = false;
    
    // Kill TouchBar Tool if it's running
    NSArray *runningProcessInstances = [allRunningProcesses containsProcessObject:BTouchBarRestartAgent];
    if (runningProcessInstances.count > 0) {
        [self killProcess:runningProcessInstances[0]];
    }
    runningProcessInstances = [allRunningProcesses containsProcessObject:BTouchBarAgent];
    if (runningProcessInstances.count > 0) {
        [self killProcess:runningProcessInstances[0]];
    }
}


// Get URL (path) to either bundle or executable of a running application
- (NSURL *)getBundleOrExecutableURL:(NSRunningApplication *)runningApp
{
    NSURL *runningAppURL = runningApp.bundleURL;
    if (!runningAppURL) {
        // If this didn't work then it's probably an app without bundle, get executable URL
        runningAppURL = runningApp.executableURL;
    }
    DDLogVerbose(@"NSRunningApplication %@ bundle or executable URL: %@", runningApp, runningAppURL);
    return runningAppURL;
}


// Check if application is a legit Apple system executable
- (BOOL)signedSystemExecutable:(pid_t)runningExecutablePID
{
    NSString * executablePath = [ProcessManager getExecutablePathForPID:runningExecutablePID];
    if (executablePath) {
        NSURL * executableURL = [NSURL fileURLWithPath:executablePath isDirectory:NO];

        DDLogDebug(@"Evaluating code signature of %@", executablePath);
        
        OSStatus status;
        SecStaticCodeRef ref = NULL;
        
        // obtain the cert info from the executable
        status = SecStaticCodeCreateWithPath((__bridge CFURLRef)executableURL, kSecCSDefaultFlags, &ref);
        
        if (ref == NULL) {
            DDLogDebug(@"Couldn't obtain certificate info from executable %@", executablePath);
            return NO;
        }
        if (status != noErr) {
            DDLogDebug(@"Couldn't obtain certificate info from executable %@", executablePath);
            if (ref) {
                CFRelease(ref);
            }
            return NO;
        }
        
        SecRequirementRef req = NULL;
        NSString * reqStr;
        
        if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_14 ) {
            // Public SHA1 fingerprint of the CA certificate
            // for macOS system software signed by Apple this is the
            // "Software Signing" certificate (use Max Inspect from App Store or similar)
            reqStr = [NSString stringWithFormat:@"%@ %@ = %@%@%@",
                      @"certificate",
                      @"leaf",
                      @"H\"EFDBC9139DD98D",
                      @"BAE5A9C7165A09",
                      @"6511B15EAEF9\""
                      ];
            // create the requirement to check against
            status = SecRequirementCreateWithString((__bridge CFStringRef)reqStr, kSecCSDefaultFlags, &req);
            
            if (status == noErr && req != NULL) {
                status = SecStaticCodeCheckValidity(ref, kSecCSCheckAllArchitectures, req);
                DDLogDebug(@"Returned from checking code signature of executable %@ with status %d", executablePath, (int)status);
            }
        }

        if (status != noErr) {
            if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_9) {
                // Public SHA1 fingerprint of the CA cert match string
                reqStr = [NSString stringWithFormat:@"%@ %@ = %@%@%@",
                          @"certificate",
                          @"leaf",
                          @"H\"013E2787748A74",
                          @"103D62D2CDBF77",
                          @"A1345517C482\""
                ];
            } else {
                reqStr = [NSString stringWithFormat:@"%@ %@ = %@%@%@",
                          @"certificate",
                          @"leaf",
                          @"H\"2203029E85EFB1",
                          @"828B928C3B6545",
                          @"F003CC0E515C\""
                ];
            }
            
            // create the requirement to check against
            status = SecRequirementCreateWithString((__bridge CFStringRef)reqStr, kSecCSDefaultFlags, &req);
            
            if (status == noErr && req != NULL) {
                status = SecStaticCodeCheckValidity(ref, kSecCSCheckAllArchitectures, req);
                DDLogDebug(@"Returned from checking code signature of executable %@ with status %d", executablePath, (int)status);
            }
        }
        
        if (ref) {
            CFRelease(ref);
        }
        if (req) {
            CFRelease(req);
        }
            
        if (status != noErr) {
            DDLogDebug(@"Code signature suggests that %@ isn't correctly signed macOS system software.", executablePath);
            return NO;
        }

        DDLogDebug(@"Code signature of %@ was checked and it positively identifies macOS system software.", executablePath);
        
        return YES;
    } else {
        DDLogDebug(@"Couldn't determine executable path of process with PID %d.", runningExecutablePID);
        return NO;
    }
}


#pragma mark - Monitoring of Prohibited System Functions

// Switch off display mirroring if it isn't allowed in settings
- (void)conditionallyTerminateDisplayMirroring
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    BOOL allowDisplayMirroring = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDisplayMirroring"];
    
    // Also set flags for screen sharing
    allowScreenSharing = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowScreenSharing"] &&
       ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_screenSharingMacEnforceBlocked"];

    // Also set flag for SIGSTOP detection
    detectSIGSTOP = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_detectStoppedProcess"];
    
    // Get list of all displays
    CGDisplayCount maxDisplays = 16;
    CGDirectDisplayID onlineDisplays[maxDisplays];
    CGDisplayCount displayCount = 0;
    CGError error = CGGetOnlineDisplayList(maxDisplays, onlineDisplays, &displayCount);
    if (error != kCGErrorSuccess) {
        DDLogError(@"CGGetOnlineDisplayList error: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:NULL]);
        return;
    }
    CGDirectDisplayID builtinDisplay = kCGNullDirectDisplay;
    CGDirectDisplayID mainDisplay = kCGNullDirectDisplay;
    BOOL useBuiltin = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowedDisplayBuiltin"];
    BOOL useBuiltinEnforced = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowedDisplayBuiltinEnforce"];
    BOOL useBuiltinEnforcedExceptDesktop = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowedDisplayBuiltinExceptDesktop"];
    BOOL hasBuiltinDisplay = [self.systemManager hasBuiltinDisplay];
    NSUInteger maxAllowedDisplays = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowedDisplaysMaxNumber"];
    DDLogInfo(@"Current Settings: Maximum allowed displays: %lu, %suse built-in display.", maxAllowedDisplays, useBuiltin ? "" : "don't ");

    for (int i = 0; i < displayCount; i++)
    {
        CGDirectDisplayID display = onlineDisplays[i];
        CGRect bounds = CGDisplayBounds(display);
        BOOL isBuiltin = CGDisplayIsBuiltin(display);
        BOOL isMain = CGDisplayIsMain(display);
        BOOL isMirrored = CGDisplayIsInMirrorSet(display);
        BOOL isHWMirrored = CGDisplayIsInHWMirrorSet(display);
        BOOL isAlwaysMirrored = CGDisplayIsAlwaysInMirrorSet(display);
        uint32_t vendorID = CGDisplayVendorNumber(display);
        NSString *displayName = [NSScreen displayNameForID:display];
        
        DDLogInfo(@"Display %@ (ID %u) from vendor %u with Resolution %f x %f\n is %sbuilt-in\n is %smain\n is %smirrored\n is %sHW mirrored\n is %salways mirrored",
                  displayName,
                  display,
                  vendorID,
                  bounds.size.width,
                  bounds.size.height,
                  isBuiltin ? "" : "not ",
                  isMain ? "" : "not ",
                  isMirrored ? "" : "not ",
                  isHWMirrored ? "" : "not ",
                  isAlwaysMirrored ? "" : "not ");
        
        if (!_isAACEnabled && !_wasAACEnabled && !allowDisplayMirroring && (isMirrored || isHWMirrored)) {
            CGDisplayConfigRef displayConfigRef;
            
            error = CGBeginDisplayConfiguration(&displayConfigRef);
            if (error != kCGErrorSuccess) {
                DDLogError(@"CGBeginDisplayConfiguration error: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:NULL]);
                continue;
            }
            
            error = CGConfigureDisplayMirrorOfDisplay(displayConfigRef, display, kCGNullDirectDisplay);
            if (error != kCGErrorSuccess) {
                DDLogError(@"CGConfigureDisplayMirrorOfDisplay error: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:NULL]);
                continue;
            }
            
            error = CGCompleteDisplayConfiguration(displayConfigRef, kCGConfigureForAppOnly);
            if (error != kCGErrorSuccess) {
                DDLogError(@"CGCompleteDisplayConfiguration error: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:NULL]);
                continue;
            } else {
                // Switching off mirroring worked, we can abort here
                // and wait for this method to be called again after mirroring is actually off
                return;
            }
        }
        
        // Has the display the built-in flag set?
        if (isBuiltin) {
            DDLogInfo(@"Display %@ (ID %u) is claiming to be built-in", displayName, display);
            // Check if we already found another display which claims (maybe untruthfully) to be built-in
            if (builtinDisplay != kCGNullDirectDisplay) {
                // Another display claimed to be built-in, check if this one has the Apple vendor number
                if (vendorID == 1552) {
                    // This seems to be the real built-in display, rembember it
                    DDLogInfo(@"Display %@ (ID %u) seems to be the real built-in display, as its vendor ID is 1552", displayName, display);
                    builtinDisplay = display;
                }
            } else {
                // this is the first display which claims to be built-in, so save its ID
                builtinDisplay = display;
            }
        }
    }

    NSScreen *mainScreen = nil;
    NSMutableArray *screens = [NSScreen screens].mutableCopy;	// get all available screens
    DDLogDebug(@"All available screens: %@", screens);
    
    // Check if the the built-in display should be the main display according to settings
    self.sessionState.noRequiredBuiltInScreenAvailable = NO;
    if (useBuiltin) {
        DDLogInfo(@"Use built-in option set, using display with ID %u", builtinDisplay);
        // we find the matching main screen
        for (NSUInteger i = 0; i < screens.count; i++)
        {
            NSScreen *iterScreen = screens[i];
            CGDirectDisplayID screenDisplayID = iterScreen.displayID.intValue;
            if (screenDisplayID == builtinDisplay) {
                DDLogInfo(@"Found matching screen (%@) for main display (ID %u)", iterScreen, mainDisplay);
                mainScreen = iterScreen;
                mainScreen.inactive = false;
                [screens removeObjectAtIndex:i];
            }
        }
        if (!mainScreen && ((useBuiltinEnforced && hasBuiltinDisplay) ||
                            (useBuiltinEnforced && !hasBuiltinDisplay && !useBuiltinEnforcedExceptDesktop))) {
            // A built-in display is required, but not available!
            // We still have to find a main display in case of a manual override
            // of the allowedDisplayBuiltinEnforce = true setting
            self.sessionState.noRequiredBuiltInScreenAvailable = YES;
        } else if (mainScreen && self.sessionState.builtinDisplayNotAvailableDetected == YES) {
            // Now there is again a built-in display available
            // lock screen might be closed (if no other lock reason active)
            DDLogInfo(@"Built-in display is again available, lock screen might be closed.");
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"detectedRequiredBuiltinDisplayMissing" object:self];
        }
    }
    
    // If no main display has been identified, we take the first non-built-in
    if (!mainScreen) {
        for (NSUInteger i = 0; i < screens.count; i++)
        {
            NSScreen *iterScreen = screens[i];
            CGDirectDisplayID screenDisplayID = iterScreen.displayID.intValue;
            if (screenDisplayID != builtinDisplay) {
                DDLogInfo(@"Found matching non built-in screen (%@) for main display", iterScreen);
                mainScreen = iterScreen;
                mainScreen.inactive = false;
                [screens removeObjectAtIndex:i];
                break;
            }
        }
    }
    
    // If we still don't have a screen, then useBuiltin was false and all available screens
    // (probably only one) is built-in, we just take that screen
    if (!mainScreen && screens.count > 0) {
        mainScreen = screens[0];
        mainScreen.inactive = false;
        [screens removeObjectAtIndex:0];
    }
    
    // Flag remaining screens active or inactive
    NSUInteger displaysCounter = (mainScreen != nil);
    for (NSScreen *iterScreen in screens)
    {
        if (displaysCounter < maxAllowedDisplays) {
            iterScreen.inactive = false;
            DDLogInfo(@"Flagged screen %@ as active", iterScreen);
        } else {
            iterScreen.inactive = true;
            DDLogInfo(@"Flagged screen %@ as inactive", iterScreen);
        }
        displaysCounter++;
    }
    
    _mainScreen = mainScreen;
    // Move all browser windows to the previous main screen (if they aren't on it already)
    DDLogInfo(@"Move all browser windows to new main screen %@.", mainScreen);
    [self.browserController moveAllBrowserWindowsToScreen:mainScreen];
    
    if (self.sessionState.noRequiredBuiltInScreenAvailable) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"detectedRequiredBuiltinDisplayMissing" object:self];
    }
}


- (BOOL) noRequiredBuiltInScreenAvailable
{
    DDLogDebug(@"%s %d", __FUNCTION__, self.sessionState.noRequiredBuiltInScreenAvailable);
    return self.sessionState.noRequiredBuiltInScreenAvailable;
}


// Switch off Siri and dictation if not allowed in settings
- (void)conditionallyDisableSpeechInput
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    allowSiri = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSiri"];
    allowDictation = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDictation"];
    
    // If settings demand it, switch off dictation
    if (allowDictation !=
        ([[preferences valueForDefaultsDomain:DictationDefaultsDomain key:DictationDefaultsKey] boolValue] |
         [[preferences valueForDefaultsDomain:RemoteDictationDefaultsDomain key:RemoteDictationDefaultsKey] boolValue]))
    {
        // We set the master system setting for dictation
        // to the SEB setting value (allow/disallow)
        [preferences setValue:[NSNumber numberWithBool:allowDictation]
                       forKey:DictationDefaultsKey
            forDefaultsDomain:DictationDefaultsDomain];
        
        // If dictation isn't allowed in SEB settings, we switch off
        // remote dictation (running on Apple's servers)
        // We don't change the setting for remote dictation in case
        // SEB settings allow dictation, as the user needs to confirm
        // that audio data is sent to Apple (using system settings
        // before starting SEB)!
        if (allowDictation == NO) {
            [preferences setValue:[NSNumber numberWithBool:NO]
                           forKey:RemoteDictationDefaultsKey
                forDefaultsDomain:RemoteDictationDefaultsDomain];
        }
    }

    // If settings demand it, switch off Siri
    if (allowSiri !=
        [[preferences valueForDefaultsDomain:SiriDefaultsDomain key:SiriDefaultsKey] boolValue]) {
        [preferences setValue:[NSNumber numberWithBool:allowSiri]
                       forKey:SiriDefaultsKey
            forDefaultsDomain:SiriDefaultsDomain];
    }
}


- (void)disableTouchBarFeatures
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // Setting "Touch bar shows = F1, F2, etc. Keys" in System Preferences / Keyboard
    [preferences setValue:TouchBarGlobalDefaultsValue
                   forKey:TouchBarGlobalDefaultsKey
        forDefaultsDomain:TouchBarDefaultsDomain];

    // Setting "Press Fn key to = Show App Controls" in System Preferences / Keyboard
    [preferences setValue:@{TouchBarGlobalDefaultsValue : TouchBarFnDefaultsValue}
                   forKey:TouchBarFnDictionaryDefaultsKey
        forDefaultsDomain:TouchBarDefaultsDomain];

    [self killTouchBarAgent];
}


- (void)killAirPlayUIAgent
{
    NSArray *runningAirPlayAgents = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.AirPlayUIAgent"];
    if (runningAirPlayAgents.count != 0) {
        for (NSRunningApplication *airPlayAgent in runningAirPlayAgents) {
            DDLogDebug(@"Terminating AirPlayUIAgent %@", airPlayAgent);
            BOOL killSuccess = [airPlayAgent kill];
            DDLogVerbose(@"Success of terminating AirPlayUIAgent: %ld", (long)killSuccess);
        }
    }
}


- (void)killTouchBarAgent
{
    NSArray *runningTouchBarAgents = [NSRunningApplication runningApplicationsWithBundleIdentifier:TouchBarAgent];
    if (runningTouchBarAgents.count != 0) {
        _touchBarDetected = YES;
        for (NSRunningApplication *touchBarAgent in runningTouchBarAgents) {
            DDLogDebug(@"Terminating TouchBarAgent %@", touchBarAgent);
            BOOL killSuccess = [touchBarAgent kill];
            DDLogVerbose(@"Success of terminating TouchBarAgent: %ld", (long)killSuccess);
        }
    }
}


- (void)killScreenCaptureAgent
{
    NSArray *allRunningProcesses = [self getProcessArray];
    NSDictionary *processDetails = nil;
    NSError *error = [self runningProcessCheckForName:screenCaptureAgent inRunningProcesses:&allRunningProcesses processDetails:&processDetails];
    if (processDetails) {
        DDLogDebug(@"Terminating %@ was %@successfull (error: %@)", processDetails, error ? @"not " : @"", error);
    }
}


// Clear Pasteboard, but save the current content in case it is a NSString
- (void)clearPasteboardSavingCurrentString
{
    [self saveCurrentPasteboardString];
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    //NSInteger changeCount = [pasteboard clearContents];
    [pasteboard clearContents];
}

- (void)saveCurrentPasteboardString
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    //NSArray *classes = [[NSArray alloc] initWithObjects:[NSString class], [NSAttributedString class], nil];
    NSArray *classes = [[NSArray alloc] initWithObjects:[NSString class], nil];
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
    if ((copiedItems != nil) && [copiedItems count]) {
        // if there is a NSSting in the pasteboard, save it for later use
        //[[MyGlobals sharedMyGlobals] setPasteboardString:[copiedItems objectAtIndex:0]];
        [[MyGlobals sharedMyGlobals] setValue:[copiedItems objectAtIndex:0] forKey:@"pasteboardString"];
        DDLogDebug(@"String saved from pasteboard");
    } else {
        [[MyGlobals sharedMyGlobals] setValue:@"" forKey:@"pasteboardString"];
    }
#ifdef DEBUG
    //    NSString *stringFromPasteboard = [[MyGlobals sharedMyGlobals] valueForKey:@"pasteboardString"];
    //    DDLogDebug(@"Saved string from Pasteboard: %@", stringFromPasteboard);
#endif
}


// Clear Pasteboard when quitting/restarting SEB,
// If selected in Preferences, then the current Browser Exam Key is copied to the pasteboard instead
- (void)clearPasteboardCopyingBrowserExamKey
{
    // Clear Pasteboard
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    
    // Write Browser Exam Key to clipboard if enabled in prefs
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *hashKey;
    NSMutableArray *pasteboardStrings = NSMutableArray.new;
    BOOL copyBrowserExamKeyToClipboard = [preferences secureBoolForKey:@"org_safeexambrowser_copyBrowserExamKeyToClipboardWhenQuitting"];
    BOOL copyConfigKeyToClipboard = [preferences secureBoolForKey:@"org_safeexambrowser_copyConfigKeyToClipboardWhenQuitting"];
    BOOL moreThanOneKey = copyBrowserExamKeyToClipboard && copyConfigKeyToClipboard;
    if (copyBrowserExamKeyToClipboard) {
        hashKey = self.browserController.browserExamKey;
        [pasteboardStrings addObject:[NSString stringWithFormat:@"%@%@", (moreThanOneKey ? @"Browser Exam Key: " : @""), [hashKey base16String]]];
    }
    if (copyConfigKeyToClipboard) {
        hashKey = self.configKey;
        [pasteboardStrings addObject:[NSString stringWithFormat:@"%@%@", (moreThanOneKey ? @"Config Key: " : @""), [hashKey base16String]]];
    }

    if (pasteboardStrings.count > 0) {
        [pasteboard writeObjects:[NSArray arrayWithObject:[pasteboardStrings componentsJoinedByString:@"\n"]]];
    }
}


#pragma mark - Checks for System Environment

// Check if running on minimal allowed macOS version or a newer version
- (void)checkMinMacOSVersion
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    enforceMinMacOSVersion = NO;
    
    // Check if running on older macOS version than the one allowed in settings
    NSUInteger currentOSMajorVersion = NSProcessInfo.processInfo.operatingSystemVersion.majorVersion;
    NSUInteger currentOSMinorVersion = NSProcessInfo.processInfo.operatingSystemVersion.minorVersion;
    NSUInteger currentOSPatchVersion = NSProcessInfo.processInfo.operatingSystemVersion.patchVersion;

    NSUInteger allowMacOSVersionMajor = SEBMinMacOSVersionSupportedMajor;
    NSUInteger allowMacOSVersionMinor = SEBMinMacOSVersionSupportedMinor;
    NSUInteger allowMacOSVersionPatch = SEBMinMacOSVersionSupportedPatch;

    if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberCheckFull"]) {
        // Manage old check only for allowed major version
        SEBMinMacOSVersion minMacOSVersion = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_minMacOSVersion"];
        switch (minMacOSVersion) {
            case SEBMinMacOS10_14:
                allowMacOSVersionMajor = 10;
                allowMacOSVersionMinor = 14;
                allowMacOSVersionPatch = 0;
                break;
                
            case SEBMinMacOS10_15:
                allowMacOSVersionMajor = 10;
                allowMacOSVersionMinor = 15;
                allowMacOSVersionPatch = 0;
                break;
                
            case SEBMinMacOS11:
                allowMacOSVersionMajor = 11;
                allowMacOSVersionMinor = 0;
                allowMacOSVersionPatch = 0;
                break;
                
            case SEBMinMacOS12:
                allowMacOSVersionMajor = 12;
                allowMacOSVersionMinor = 0;
                allowMacOSVersionPatch = 0;
                break;
                
            case SEBMinMacOS13:
                allowMacOSVersionMajor = 13;
                allowMacOSVersionMinor = 0;
                allowMacOSVersionPatch = 0;
                break;
                
            case SEBMinMacOS14:
                allowMacOSVersionMajor = 14;
                allowMacOSVersionMinor = 0;
                allowMacOSVersionPatch = 0;
                break;
                
            case SEBMinMacOS15:
                allowMacOSVersionMajor = 15;
                allowMacOSVersionMinor = 0;
                allowMacOSVersionPatch = 0;
                break;
                
            default:
                break;
        }
        DDLogInfo(@"%s: Is running on macOS version with index %lu allowed?", __FUNCTION__, (unsigned long)minMacOSVersion);

    } else {
        // Full granular check for allowed major, minor and patch version
        allowMacOSVersionMajor = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberMajor"];
        allowMacOSVersionMinor = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberMinor"];
        allowMacOSVersionPatch = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberPatch"];
    }
    
    DDLogInfo(@"%s: Is running on macOS version with allow major version %lu, minor version %lu, patch version %lu allowed?", __FUNCTION__, allowMacOSVersionMajor, allowMacOSVersionMinor, allowMacOSVersionPatch);

    // Check for minimal macOS version requirements of this SEB version
    if (allowMacOSVersionMajor < SEBMinMacOSVersionSupportedMajor) {
        allowMacOSVersionMajor = SEBMinMacOSVersionSupportedMajor;
        allowMacOSVersionMinor = SEBMinMacOSVersionSupportedMinor;
        allowMacOSVersionPatch = SEBMinMacOSVersionSupportedPatch;
    } else if (allowMacOSVersionMajor == SEBMinMacOSVersionSupportedMajor) {
        if (allowMacOSVersionMinor < SEBMinMacOSVersionSupportedMinor) {
            allowMacOSVersionMinor = SEBMinMacOSVersionSupportedMinor;
            allowMacOSVersionPatch = SEBMinMacOSVersionSupportedPatch;
        } else if (allowMacOSVersionMinor == SEBMinMacOSVersionSupportedMinor && allowMacOSVersionPatch < SEBMinMacOSVersionSupportedPatch) {
            allowMacOSVersionPatch = SEBMinMacOSVersionSupportedPatch;
        }
    }

    if (currentOSMajorVersion < allowMacOSVersionMajor ||
        (currentOSMajorVersion == allowMacOSVersionMajor &&
         currentOSMinorVersion < allowMacOSVersionMinor) ||
        (currentOSMajorVersion == allowMacOSVersionMajor &&
         currentOSMinorVersion == allowMacOSVersionMinor &&
         currentOSPatchVersion < allowMacOSVersionPatch)
        )
    {
        NSString *allowedMacOSVersionMinorString = @"";
        NSString *allowedMacOSVersionPatchString = @"";
        if (allowMacOSVersionPatch > 0 || allowMacOSVersionMinor > 0) {
            allowedMacOSVersionMinorString = [NSString stringWithFormat:@".%lu", (unsigned long)allowMacOSVersionMinor];
        }
        if (allowMacOSVersionPatch > 0) {
            allowedMacOSVersionPatchString = [NSString stringWithFormat:@".%lu", (unsigned long)allowMacOSVersionPatch];
        }
        NSString *alertMessageMacOSVersion = [NSString stringWithFormat:@"%@%@%lu%@%@",
                                            SEBShortAppName,
                                            NSLocalizedString(@" settings don't allow to run on the macOS version installed on this device. Update to latest macOS version or at least macOS ", @""),
                                            (unsigned long)allowMacOSVersionMajor,
                                            allowedMacOSVersionMinorString,
                                            allowedMacOSVersionPatchString];
        DDLogError(@"%s %@", __FUNCTION__, alertMessageMacOSVersion);
        
        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Running on Current macOS Version Not Allowed!", @"")]];
        [modalAlert setInformativeText:alertMessageMacOSVersion];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [modalAlert setAlertStyle:NSAlertStyleCritical];
        void (^terminateSEBAlertOK)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self removeAlertWindow:modalAlert.window];
            self->enforceMinMacOSVersion = YES;
            if (self.startingUp) {
                [self requestedExit:nil]; // Quit SEB
            } else {
                [self quitSEBOrSession];
            }
        };
        [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))terminateSEBAlertOK];
    } else {
        DDLogInfo(@"%s: Running on current macOS version is allowed.", __FUNCTION__);
    }
}


// Check if SEB is placed ("installed") in an Applications folder
- (BOOL)installedInApplicationsFolder
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *currentSEBBundlePath =[[NSBundle mainBundle] bundlePath];
    BOOL installedInApplicationsFolder = false;
    DDLogDebug(@"SEB was started up from this path: %@", currentSEBBundlePath);
    if (![self isInApplicationsFolder:currentSEBBundlePath]) {
        // Has SEB to be installed in an Applications folder?
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_forceAppFolderInstall"]) {
#ifndef DEBUG
            DDLogError(@"Current settings require SEB to be installed in an Applications folder, but it isn't! SEB will therefore quit!");
            _forceAppFolder = YES;
            [self quitSEBOrSession]; // Quit SEB or the exam session
#else
            DDLogDebug(@"Current settings require SEB to be installed in an Applications folder, but it isn't! SEB would quit if not Debug build.");
#endif
        }
    } else {
        DDLogInfo(@"SEB was started up from an Applications folder.");
        installedInApplicationsFolder = true;
    }
    return installedInApplicationsFolder;
}


- (BOOL) isInApplicationsFolder:(NSString *)path
{
    NSArray *applicationDirs;
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowUserAppFolderInstall"]) {
        // Allow also user's ~/Applications directories
        applicationDirs = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory,
                                                              NSLocalDomainMask | NSUserDomainMask,
                                                              YES);
    } else {
        applicationDirs = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory,
                                                              NSLocalDomainMask,
                                                              YES);
    }
    for (NSString *appDir in applicationDirs) {
        if ([path hasPrefix:appDir]) return YES;
    }
    return NO;
}


// Check for command key being held down
- (BOOL)alternateKeyCheck
{
    NSEventModifierFlags modifierFlags = [NSEvent modifierFlags];
    BOOL altKeyDown = (0 != (modifierFlags & NSEventModifierFlagOption));
    return (altKeyDown && [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"]);
}


// Check for command key being held down
- (void)appSwitcherCheck
{
    NSEventModifierFlags modifierFlags = [NSEvent modifierFlags];
    _cmdKeyDown = (0 != (modifierFlags & NSEventModifierFlagCommand));
    if (_cmdKeyDown) {
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enableAppSwitcherCheck"]) {
            DDLogError(@"Command key is pressed and forbidden, SEB cannot continue");
            [self requestedExit:nil]; // Quit SEB
        } else {
            DDLogWarn(@"Command key is pressed, but not forbidden in current settings");
        }
    }
}


// Check if the Force Quit window is open
- (BOOL)forceQuitWindowCheckContinue
{
    while ([self forceQuitWindowOpen]) {
        // Show alert that the Force Quit window is open
        DDLogError(@"Force Quit window is open!");
            DDLogError(@"Show error message and ask user to close it or quit SEB.");
            NSAlert *modalAlert = [self newAlert];
            [modalAlert setMessageText:NSLocalizedString(@"Close Force Quit Window", @"")];
        [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"%@ cannot run when the Force Quit window or another system frontmost dialog is open. Close the window or quit %@. If the window isn't open and this alert is displayed anyways, restart your Mac.", @""), SEBShortAppName, SEBShortAppName]];
            [modalAlert setAlertStyle:NSAlertStyleCritical];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Retry", @"")];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", @"")];
            NSInteger answer = [modalAlert runModal];
            [self removeAlertWindow:modalAlert.window];
            switch(answer)
            {
                case NSAlertFirstButtonReturn:
                    DDLogError(@"Force Quit window was open, user clicked retry");
                    break; // Test if window is closed now
                    
                case NSAlertSecondButtonReturn:
                {
                    // Quit SEB
                    DDLogError(@"Force Quit window was open, user decided to quit SEB.");
                    [self requestedExit:nil]; // Quit SEB
                    return NO;
                }
            }
    }
    return YES;
}


// Check if the Force Quit window is open
- (BOOL)forceQuitWindowOpen
{
    BOOL forceQuitWindowOpen = false;
    NSArray *windowList = CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID));
    for (NSDictionary *windowInformation in windowList) {
        if ([[windowInformation valueForKey:@"kCGWindowOwnerName"] isEqualToString:@"loginwindow"]) {
            forceQuitWindowOpen = true;
            break;
        }
    }
    return forceQuitWindowOpen;
}


#pragma mark - System Lock Down Functionalities

static bool _systemSleeping;

// Method called by I/O Kit power management
void MySleepCallBack( void * refCon, io_service_t service, natural_t messageType, void * messageArgument )
{
    DDLogDebug(@"messageType %08lx, arg %08lx\n",
		   (long unsigned int)messageType,
		   (long unsigned int)messageArgument );
	
    switch ( messageType )
    {
			
        case kIOMessageCanSystemSleep:
            /* Idle sleep is about to kick in. This message will not be sent for forced sleep.
			 Applications have a chance to prevent sleep by calling IOCancelPowerChange.
			 Most applications should not prevent idle sleep.
			 
			 Power Management waits up to 30 seconds for you to either allow or deny idle sleep.
			 If you don't acknowledge this power change by calling either IOAllowPowerChange
			 or IOCancelPowerChange, the system will wait 30 seconds then go to sleep.
			 */
			
            // cancel idle sleep
            DDLogDebug(@"kIOMessageCanSystemSleep: IOCancelPowerChange");
            IOCancelPowerChange( root_port, (long)messageArgument );
            // uncomment to allow idle sleep
            //IOAllowPowerChange( root_port, (long)messageArgument );
            break;
			
        case kIOMessageSystemWillSleep:
            /* The system WILL go to sleep. If you do not call IOAllowPowerChange or
			 IOCancelPowerChange to acknowledge this message, sleep will be
			 delayed by 30 seconds.
			 
			 NOTE: If you call IOCancelPowerChange to deny sleep it returns kIOReturnSuccess,
			 however the system WILL still go to sleep. 
			 */
            DDLogDebug(@"kIOMessageSystemWillSleep");
            _systemSleeping = true;

			//IOCancelPowerChange( root_port, (long)messageArgument );
			//IOAllowPowerChange( root_port, (long)messageArgument );
            break;
			
        case kIOMessageSystemWillPowerOn:
            //System has started the wake up process...
            DDLogDebug(@"kIOMessageSystemWillPowerOn");
            break;
			
        case kIOMessageSystemHasPoweredOn:
            //System has finished waking up...
            DDLogDebug(@"kIOMessageSystemHasPoweredOn");
            _systemSleeping = false;
			break;
			
        default:
            break;
			
    }
}


bool insideMatrix(void){
	unsigned char mem[4] = {0,0,0,0};
	//__asm ("str mem");
	if ( (mem[0]==0x00) && (mem[1]==0x40))
		return true; //printf("INSIDE MATRIX!!\n");
	else
		return false; //printf("OUTSIDE MATRIX!!\n");
	return false;
}


// Close the About Window
- (void) closeAboutWindow {
    DDLogInfo(@"Attempting to close About SEB window %@", self.aboutWindow);
    [self.aboutWindow orderOut:self];
}


// Open background windows on all available screens to prevent Finder becoming active when clicking on the desktop background
- (void) coverScreens {
    DDLogDebug(@"%s Open background windows on all available screens", __FUNCTION__);
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    NSUInteger windowLevel;
    if (!allowSwitchToThirdPartyApps) {
        windowLevel = NSMainMenuWindowLevel+2;
    } else {
        windowLevel = NSNormalWindowLevel;
    }

    BOOL excludeMenuBar = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showMenuBar"];
    
    NSArray *backgroundCoveringWindows = [self fillScreensWithCoveringWindows:coveringWindowBackground windowLevel:windowLevel excludeMenuBar:excludeMenuBar];
    if (!self.capWindows) {
        self.capWindows = [NSMutableArray arrayWithArray:backgroundCoveringWindows];	// array for storing our cap (covering) background windows
    } else {
        [self.capWindows removeAllObjects];
        [self.capWindows addObjectsFromArray:backgroundCoveringWindows];
    }
}

                           
- (NSMutableArray *) fillScreensWithCoveringWindows:(coveringWindowKind)coveringWindowKind windowLevel:(NSUInteger)windowLevel excludeMenuBar:(BOOL)excludeMenuBar {
    NSMutableArray *coveringWindows = [NSMutableArray new];	// array for storing our cap (covering)  windows
    NSArray *screens = [NSScreen screens];	// get all available screens
    NSScreen *iterScreen;

    for (iterScreen in screens)
    {
        NSDictionary *screenDeviceDescription = iterScreen.deviceDescription;
        BOOL inactive = iterScreen.inactive;
        DDLogDebug(@"Screen is %@active, device description: %@", inactive ? @"in" : @"", screenDeviceDescription);
        
        // NSRect frame = size of the current screen
        NSRect frame = [iterScreen frame];
        NSUInteger styleMask = NSWindowStyleMaskBorderless;
        NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
        
        // Set origin of the window rect to left bottom corner (important for non-main screens, since they have offsets)
        rect.origin.x = 0;
        rect.origin.y = 0;

        // If showing menu bar
        // On OS X >= 10.10 we exclude the menu bar on all screens from the covering windows
        // On OS X <= 10.9 we exclude the menu bar only on the screen which actually displays the menu bar
        if (excludeMenuBar && (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_10 || iterScreen == screens[0])) {
            // Reduce size of covering background windows to not cover the menu bar
            rect.size.height -= iterScreen.menuBarHeight;
        }
        DDLogDebug(@"Opening %@ covering window with frame %@ and window level %ld",
                   coveringWindowKind == coveringWindowBackground ? @"background" : @"lockdown alert",
                   (NSDictionary *)CFBridgingRelease(CGRectCreateDictionaryRepresentation(rect)), windowLevel);
        id window;
        id capview;
        NSColor *windowColor;
        switch (coveringWindowKind) {
            case coveringWindowBackground: {
                window = [[NSWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered defer:NO screen:iterScreen];
                capview = [[CapView alloc] initWithFrame:rect];
                windowColor = [NSColor blackColor];
                [window setAccessibilityElement:NO];
                break;
            }
                
            case coveringWindowLockdownAlert: {
                window = [[CapWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered defer:NO screen:iterScreen];
                capview = [[NSView alloc] initWithFrame:rect];
                windowColor = [NSColor redColor];
                break;
            }
                
            case coveringWindowModalAlert: {
                window = [[CapWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered defer:NO screen:iterScreen];
                capview = [[NSView alloc] initWithFrame:rect];
                windowColor = [NSColor blackColor];
                ((NSWindow *)window).alphaValue = 0.4;
                break;
            }
                
            default:
                return nil;
        }
        
        [window setReleasedWhenClosed:YES];
        [window setBackgroundColor:windowColor];
        if ([NSUserDefaults standardUserDefaults].allowWindowCapture == NO) {
            [window setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
        }
        [window newSetLevel:windowLevel];
        //[window orderBack:self];
        [coveringWindows addObject: window];
        NSView *superview = [window contentView];
        [superview addSubview:capview];
        
        //[window orderBack:self];
        CapWindowController *capWindowController = [[CapWindowController alloc] initWithWindow:window];
        //CapWindow *loadedCapWindow = capWindowController.window;
        [capWindowController showWindow:self];
        [window makeKeyAndOrderFront:self];
        //[window orderBack:self];
        //BOOL isWindowLoaded = capWindowController.isWindowLoaded;
#ifdef DEBUG
        //DDLogDebug(@"Loaded capWindow %@, isWindowLoaded %@", loadedCapWindow, isWindowLoaded);
#endif
    }
    return coveringWindows;
}


// Cover currently intersected inactive screens and
// remove cover windows of no longer intersected screens
- (void) coverInactiveScreens:(NSArray *)inactiveScreens
{
    NSMutableArray *newCoverWindows = [NSMutableArray new];
    for (NSScreen *screen in inactiveScreens) {
        // Check if this screen is already covered
        BOOL isAlreadyCovered = false;
        NSUInteger i = 0;
        while (i < _inactiveScreenWindows.count) {
            CapWindow *coverWindow = _inactiveScreenWindows[i];
            if (coverWindow.screen == screen) {
                isAlreadyCovered = true;
                [newCoverWindows addObject:coverWindow];
                [_inactiveScreenWindows removeObject:coverWindow];
                break;
            } else {
                i++;
            }
        }
        if (!isAlreadyCovered) {
            CapWindow *newCoverWindow = [self coverInactiveScreen:screen];
            [newCoverWindows addObject:newCoverWindow];
        }
    }
    // Close covering windows if necessary
    for (CapWindow *coverWindowToClose in _inactiveScreenWindows) {
        [coverWindowToClose close];
    }
    _inactiveScreenWindows = newCoverWindows;
}


- (CapWindow *) coverInactiveScreen:(NSScreen *)screen
{
    NSRect frame = screen.frame;
    NSUInteger styleMask = NSWindowStyleMaskBorderless;
    NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
    
    // Set origin of the window rect to left bottom corner (important for non-main screens, since they have offsets)
    rect.origin.x = 0;
    rect.origin.y = 0;

    DDLogDebug(@"Opening inactive screen covering window with frame %@ ",
               (NSDictionary *)CFBridgingRelease(CGRectCreateDictionaryRepresentation(rect)));
    
    CapWindow *window = [[CapWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered defer:NO screen:screen];
    NSView *capview = [[NSView alloc] initWithFrame:rect];
    [window setReleasedWhenClosed:YES];
    [window setBackgroundColor:[NSColor orangeColor]];
    [window newSetLevel:NSScreenSaverWindowLevel];
    NSView *superview = [window contentView];
    [superview addSubview:capview];
    CapWindowController *capWindowController = [[CapWindowController alloc] initWithWindow:window];
    [capWindowController showWindow:self];
    [window makeKeyAndOrderFront:self];

    NSView *coveringView = window.contentView;
    [coveringView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [coveringView setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    [coveringView addSubview:inactiveScreenCoverLabel];
    
    DDLogVerbose(@"Frame of superview: %f, %f", inactiveScreenCoverLabel.superview.frame.size.width, inactiveScreenCoverLabel.superview.frame.size.height);
    NSMutableArray *constraints = [NSMutableArray new];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:inactiveScreenCoverLabel
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:inactiveScreenCoverLabel.superview
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:inactiveScreenCoverLabel
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:inactiveScreenCoverLabel.superview
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0
                                                         constant:0.0]];
    
    [inactiveScreenCoverLabel.superview addConstraints:constraints];

    return window;
}


// Called when changes of the screen configuration occur
// (new display is contected or removed or display mirroring activated)

- (void) adjustScreenLocking: (id _Nullable)sender
{
    // This should only be done when the preferences window isn't open
    if (sender) {
        DDLogDebug(@"%s NSApplicationDidChangeScreenParametersNotification sender: %@", __FUNCTION__, sender);
    } else {
        DDLogDebug(@"%s", __FUNCTION__);
    }
    
    if (!_isTerminating && ![self.preferencesController preferencesAreOpen]) {
        
        // Close inactive screen covering windows if some are open
        for (CapWindow *coverWindowToClose in _inactiveScreenWindows) {
            [coverWindowToClose close];
        }
        
        // Switch off display mirroring if it isn't allowed
        [self conditionallyTerminateDisplayMirroring];
        DDLogDebug(@"Adjusting screen locking");
        
        // Check if lockdown windows are open and adjust those too
        if (self.lockdownWindows.count > 0) {
            DDLogDebug(@"Adjusting lockdown windows");
            NSDate *originalDidLockSEBTime = self.didLockSEBTime;
            [self closeCoveringWindows:self.lockdownWindows];
            [self openCoveringWindows];
            self.didLockSEBTime = originalDidLockSEBTime;
            DDLogDebug(@"Adjusting screen locking: didLockSEBTime %@, didBecomeActiveTime %@", self.didLockSEBTime, self.didBecomeActiveTime);
        }
        
        // Close the covering windows
        // (which most likely are no longer there where they should be)
        [self closeCapWindows];
        
        if (_isAACEnabled == NO && _wasAACEnabled == NO && !_startingUp) {
            
            // Open new covering background windows on all currently available screens
            [self coverScreens];
        }
        
        // We adjust position and size of the SEB Dock
        [self.dockController adjustDock];
        
        // We adjust the size of the main browser window
        [self.browserController adjustMainBrowserWindow];
    }
}


// Called when main browser window changed screen
- (void) changeMainScreen: (id)sender
{
    [self.dockController moveDockToScreen:self.browserController.mainBrowserWindow.screen];
}


- (void) closeCapWindows
{
    [self closeCoveringWindows:self.capWindows];
}


#pragma mark - Managing Modal Alerts

- (NSAlert *) newAlert
{
    NSAlert *newAlert = [[NSAlert alloc] init];
    DDLogDebug(@"Adding modal alert window %@", newAlert.window);
    [_modalAlertWindows addObject:newAlert.window];
    if (self.aboutWindow.isVisible) {
        DDLogDebug(@"%s About SEB window is visible, attempting to close it.", __FUNCTION__);
        [self closeAboutWindow];
    }
    return newAlert;
}


- (void) removeAlertWindow:(NSWindow *)alertWindow
{
    if (alertWindow) {
        DDLogDebug(@"All modal alert windows %@", _modalAlertWindows);
        DDLogDebug(@"Removing modal alert window %@", alertWindow);
        [_modalAlertWindows removeObject:alertWindow];
        DDLogDebug(@"All modal alert windows after removing: %@", _modalAlertWindows);
    }
}


- (void) runModalAlert:(NSAlert *)alert
conditionallyForWindow:(NSWindow *)window
     completionHandler:(void (^)(NSModalResponse returnCode))handler
{
    if (@available(macOS 12.0, *)) {
    } else {
        if (@available(macOS 11.0, *)) {
            if (_isAACEnabled || _wasAACEnabled) {
                [alert beginSheetModalForWindow:window completionHandler:(void (^)(NSModalResponse answer))handler];
                return;
            }
        }
    }
    NSModalResponse answer = [alert runModal];
    if (handler) {
        handler(answer);
    }
}


#pragma mark - Displaying Specific Alerts

- (void)presentPreferencesCorruptedError
{
    DDLogError(@"Local SEB Settings Have Been Reset");
    
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    NSAlert *modalAlert = [self newAlert];
    
    [modalAlert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Local %@ Settings Have Been Reset", @""), SEBShortAppName]];
    [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Local preferences were created by an incompatible %@ version, damaged or manipulated. They have been reset to the default settings. Ask your exam supporter to re-configure %@ correctly.", @""), SEBShortAppName, SEBShortAppName]];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
    [modalAlert setAlertStyle:NSAlertStyleCritical];
    void (^preferencesCorruptedErrorOK)(NSModalResponse) = ^void (NSModalResponse answer) {
        [self removeAlertWindow:modalAlert.window];
        DDLogInfo(@"Dismissed alert for local SEB settings have been reset");
    };
    [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))preferencesCorruptedErrorOK];
}


#pragma mark - Lockdown Windows

// Handler called when SEB needs to be locked
- (void) lockSEB:(NSNotification*) notification
{
    self.didBecomeActiveTime = [NSDate date];
    DDLogDebug(@"lockSEB: %@", notification.name);
        
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Handler called when SEB resigns active state (by user switch / switch to login window)
        
        if ([[notification name] isEqualToString:
             NSWorkspaceSessionDidResignActiveNotification])
        {
            self.didResignActiveTime = [NSDate date];
            self.sessionState.userSwitchDetected = YES;
            
            // Set alert title and message strings
            [self.sebLockedViewController setLockdownAlertTitle: [NSString stringWithFormat:NSLocalizedString(@"User Switch Locked %@!", @"Lockdown alert title text for switching the user"), SEBShortAppName]
                                                        Message: [NSString stringWithFormat:NSLocalizedString(@"%@ is locked because it was attempted to switch the user. Enter the quit/unlock password, which usually exam supervision/support knows.", @"Lockdown alert message text for switching the user"), SEBShortAppName]];
            
            DDLogError(@"SessionDidResignActive: User switch / switch to login window detected!");
            [self openLockdownWindows];
            
            // Add log string for resign active
            [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"User switch / switch to login window detected", @"")] withTime:self.didResignActiveTime repeated:NO];
            
        }
        
        // Handler called when SEB becomes active again (after user switch / switch to login window)
        
        else if ([[notification name] isEqualToString:
                  NSWorkspaceSessionDidBecomeActiveNotification])
        {
            // Perform activation tasks here.
            
            DDLogError(@"SessionDidBecomeActive: Switched back after user switch / login window!");
            
            // Calculate time difference between session resigning active and becoming active again
            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *components = [calendar components:NSCalendarUnitMinute | NSCalendarUnitSecond
                                                       fromDate:self.didResignActiveTime
                                                         toDate:self.didBecomeActiveTime
                                                        options:NSCalendarWrapComponents];
            NSString *lockedTimeInfo = [NSString stringWithFormat:NSLocalizedString(@"%@ session was inactive for %ld:%.2ld(minutes:seconds)", @""), SEBShortAppName, components.minute, components.second];
            DDLogError(@"SessionDidBecomeActive: %@, didLockSEBTime %@, didBecomeActiveTime %@", lockedTimeInfo, self.didLockSEBTime, self.didBecomeActiveTime);
            
            // Add log string for becoming active
            [self appendErrorString:[NSString stringWithFormat:@"%@\n%@\n", NSLocalizedString(@"Switched back after user switch / login window", @""), lockedTimeInfo] withTime:self.didBecomeActiveTime repeated:NO];
            [self.sebLockedViewController.view.window makeKeyAndOrderFront:self];
        }
        
        // Handler called when attempting to re-open an exam which was interrupted before
        
        else if ([[notification name] isEqualToString:
                  @"detectedReOpeningExam"])
        {
            self.sessionState.reOpenedExamDetected = YES;
            
            [self.sebLockedViewController setLockdownAlertTitle: NSLocalizedString(@"Re-Opening Locked Exam!", @"Lockdown alert title text for re-opening a locked exam")
                                                        Message:[NSString stringWithFormat:@"%@\n\n%@",
                                                                 NSLocalizedString(@"This exam was interrupted before and not finished properly. Enter the quit/unlock password from the current session's settings, which usually exam supervision/support knows.", @""),
                                                                 [NSString stringWithFormat:NSLocalizedString(@"To avoid that %@ locks an exam, you have to always use a quit/unlock link after the exam was submitted or the quit button. Never restart your Mac while %@ is still running.", @""), SEBShortAppName, SEBShortAppName]
                                                                 ]];
            
            // Add log string for trying to re-open a locked exam
            [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Re-opening an exam which was locked before", @"")] withTime:self.didBecomeActiveTime repeated:NO];
            
            [self openLockdownWindows];
        }
        
        // Handler called when screen sharing was detected
        
        else if ([[notification name] isEqualToString:
                  @"detectedScreenSharing"])
        {
            if (!self.sessionState.screenSharingDetected) {
                self.sessionState.screenSharingDetected = YES;
                self.sebLockedViewController.overrideCheckForScreenSharing.state = NO;
                self.sebLockedViewController.overrideCheckForScreenSharing.hidden = NO;
                
                // Set custom alert message string
                [self.sebLockedViewController setLockdownAlertTitle: [NSString stringWithFormat:NSLocalizedString(@"Screen Sharing Locked %@!", @"Lockdown alert title text for screen sharing"), SEBShortAppName]
                                                            Message:[NSString stringWithFormat:@"%@\n\n%@",
                                                                     NSLocalizedString(@"Screen sharing detected. Enter the quit/unlock password, which usually exam supervision/support knows.", @""),
                                                                     [NSString stringWithFormat:NSLocalizedString(@"To avoid that %@ locks itself during an exam when it detects that screen sharing started, it's best to switch off 'Screen Sharing' and 'Remote Management' in System Preferences/Sharing and 'Back to My Mac' in System Preferences/iCloud. You can also ask your network administrators to block ports used for the VNC protocol.", @""), SEBShortAppName]
                                                                     ]];
                
                // Report screen sharing is still active every 3rd second
                self->screenSharingLogCounter = logReportCounter;
                DDLogError(@"Screen sharing was activated!");
                
                if (self.sessionState.screenSharingCheckOverride == NO) {
                    [self openLockdownWindows];
                }
                
                // Add log string for screen sharing active
                [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Screen sharing was activated", @"")] withTime:self.didBecomeActiveTime repeated:NO];
            } else {
                if (!self.lockdownWindows) {
                    self.sebLockedViewController.overrideCheckForScreenSharing.hidden = false;
                    [self openLockdownWindows];
                }
                // Add log string for screen sharing still active
                if (!self->screenSharingLogCounter--) {
                    [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Screen sharing is still active", @"")] withTime:self.didBecomeActiveTime repeated:YES];
                    self->screenSharingLogCounter = logReportCounter;
                }
            }
        }
        
        // Handler called when Siri was detected
        
        else if ([[notification name] isEqualToString:
                  @"detectedSiri"])
        {
            if (!self.sessionState.siriDetected) {
                self.sessionState.siriDetected = YES;
                self.sebLockedViewController.overrideCheckForSiri.state = NO;
                self.sebLockedViewController.overrideCheckForSiri.hidden = NO;
                
                // Set custom alert message string
                [self.sebLockedViewController setLockdownAlertTitle:[NSString stringWithFormat:NSLocalizedString(@"Siri Locked %@!", @"Lockdown alert title text for Siri"), SEBShortAppName]
                                                            Message:NSLocalizedString(@"Siri activity detected. Enter the quit/unlock password, which usually exam supervision/support knows.", @"")];
                
                // Report Siri is still active every 3rd second
                self->siriLogCounter = logReportCounter;
                DDLogError(@"Siri activity detected!");
                
                if (self.sessionState.siriCheckOverride == NO) {
                    [self openLockdownWindows];
                }
                
                // Add log string for Siri active
                [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Siri was activated", @"")] withTime:self.didBecomeActiveTime repeated:NO];
            } else {
                if (!self.lockdownWindows) {
                    self.sebLockedViewController.overrideCheckForSiri.hidden = false;
                    [self openLockdownWindows];
                }
                // Add log string for Siri still active
                if (!self->siriLogCounter--) {
                    [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Siri is still active", @"")] withTime:self.didBecomeActiveTime repeated:YES];
                    self->siriLogCounter = logReportCounter;
                }
            }
        }
        
        // Handler called when dictation was detected
        
        else if ([[notification name] isEqualToString:
                  @"detectedDictation"])
        {
            if (!self.sessionState.dictationDetected) {
                self.sessionState.dictationDetected = YES;
                self.sebLockedViewController.overrideCheckForDictation.state = NO;
                self.sebLockedViewController.overrideCheckForDictation.hidden = NO;
                
                // Set custom alert message string
                [self.sebLockedViewController setLockdownAlertTitle:[NSString stringWithFormat:NSLocalizedString(@"Dictation Locked %@!", @"Lockdown alert title text for Siri"), SEBShortAppName]
                                                            Message:NSLocalizedString(@"Dictation activity detected. Enter the quit/unlock password, which usually exam supervision/support knows.", @"")];
                
                // Report dictation is still active every 3rd second
                self->dictationLogCounter = logReportCounter;
                DDLogError(@"Dictation was activated!");
                
                if (self.sessionState.dictationCheckOverride == NO) {
                    [self openLockdownWindows];
                }
                
                // Add log string for dictation active
                [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Dictation was activated", @"")] withTime:self.didBecomeActiveTime repeated:NO];
            } else {
                if (!self.lockdownWindows) {
                    self.sebLockedViewController.overrideCheckForDictation.hidden = false;
                    [self openLockdownWindows];
                }
                // Add log string for dictation still active
                if (!self->dictationLogCounter--) {
                    [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Dictation is still active", @"")] withTime:self.didBecomeActiveTime repeated:YES];
                    self->dictationLogCounter = logReportCounter;
                }
            }
        }
        
        // Handler called when a prohibited process was detected
        
        else if ([[notification name] isEqualToString:
                  @"detectedProhibitedProcess"])
        {
            
            // Add log string for detected prohibited processes
            NSArray *allRunningProhibitedProcesses = self.runningProhibitedProcesses.copy;
            NSMutableSet *runningProhibitedProcesses = NSMutableSet.new;
            NSMutableSet *runningOverriddenProhibitedProcesses = NSMutableSet.new;
            for (NSDictionary* runningProhibitedProcess in allRunningProhibitedProcesses) {
                if ([self isOverriddenProhibitedProcess:runningProhibitedProcess]) {
                    [runningOverriddenProhibitedProcesses addObject:runningProhibitedProcess[@"name"]];
                } else {
                    [runningProhibitedProcesses addObject:runningProhibitedProcess];
                }
            }
                        
            if (!self.sessionState.processesDetected) {
                self.sessionState.processesDetected = YES;
                self.sebLockedViewController.overrideCheckForSpecifcProcesses.state = NO;
                self.sebLockedViewController.overrideCheckForSpecifcProcesses.hidden = NO;
                self.sebLockedViewController.overrideCheckForAllProcesses.state = NO;
                self.sebLockedViewController.overrideCheckForAllProcesses.hidden = NO;
                
                // Set custom alert message string
                [self.sebLockedViewController setLockdownAlertTitle:[NSString stringWithFormat:NSLocalizedString(@"Prohibited Process Locked %@!", @"Lockdown alert title text for prohibited process"), SEBShortAppName]
                                                            Message:[NSString stringWithFormat:NSLocalizedString(@"%@ is locked because a process, which isn't allowed to run cannot be terminated. Enter the quit/unlock password, which usually exam supervision/support knows.", @""), SEBShortAppName]];
                
                // Report processes are still active every 3rd second
                self->prohibitedProcessesLogCounter = logReportCounter;
                DDLogError(@"Prohibited processes detected: %@", allRunningProhibitedProcesses);
                
                if (self.sessionState.processCheckAllOverride == NO) {
                    if (self.sessionState.overriddenProhibitedProcesses.count > 0) {
                        // If checking of some processes was overriden, check if newly reported processes are overridden
                        for (NSDictionary* runningProhibitedProcess in allRunningProhibitedProcesses) {
                            if (![self isOverriddenProhibitedProcess:runningProhibitedProcess]) {
                                // Check for newly reported prohibited process was not overridden before: Open lock screen
                                DDLogDebug(@"Check for running prohibited process %@ was not overridden before", runningProhibitedProcess);
                                [self openLockdownWindows];
                                break;
                            } else {
                                DDLogDebug(@"Check for running prohibited process %@ was overridden before", runningProhibitedProcess);
                            }
                        }
                    } else {
                        // No previously overridden processes: Open lock screen
                        [self openLockdownWindows];
                    }
                }
                // Add log string for prohibited process detected
                [self appendErrorStringsFor:runningOverriddenProhibitedProcesses runningProhibitedProcesses:runningProhibitedProcesses repeated:NO];
                
            } else {
                if (!self.lockdownWindows) {
                    self.sebLockedViewController.overrideCheckForSpecifcProcesses.hidden = NO;
                    self.sebLockedViewController.overrideCheckForAllProcesses.hidden = NO;
                    [self openLockdownWindows];
                }
                
                if (!self->prohibitedProcessesLogCounter--) {
                    [self appendErrorStringsFor:runningOverriddenProhibitedProcesses runningProhibitedProcesses:runningProhibitedProcesses repeated:YES];
                    self->prohibitedProcessesLogCounter = logReportCounter;
                }
            }
        }
        
        // Handler called when a SIGSTOP was detected
        
        else if ([[notification name] isEqualToString:
                  @"detectedSIGSTOP"])
        {
#ifndef DEBUG
            
            [self.sebLockedViewController setLockdownAlertTitle: [NSString stringWithFormat:NSLocalizedString(@"%@ Process Was Stopped!", @"Lockdown alert title text for SEB process was stopped"), SEBShortAppName]
                                                        Message:[NSString stringWithFormat:NSLocalizedString(@"The %@ process was interrupted, which can indicate manipulation. Enter the quit/unlock password, which usually exam supervision/support knows.", @""), SEBShortAppName]];
            // Add log string for trying to re-open a locked exam
            // Calculate time difference between session resigning active and becoming active again
            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *components = [calendar components:NSCalendarUnitMinute | NSCalendarUnitSecond
                                                       fromDate:self->timeProcessCheckBeforeSIGSTOP
                                                         toDate:self.didBecomeActiveTime
                                                        options:NSCalendarWrapComponents];
            [self appendErrorString:[NSString stringWithFormat:@"%@\n", [NSString stringWithFormat:NSLocalizedString(@"%@ process was stopped for %ld:%.2ld (minutes:seconds)", @""), SEBShortAppName, components.minute, components.second]] withTime:self.didBecomeActiveTime repeated:NO];
            
            if (!self.lockdownWindows) {
                [self openLockdownWindows];
                self.didLockSEBTime = self->timeProcessCheckBeforeSIGSTOP;
            }
#endif
        }
        
        // Handler called when there is no required built-in display available
        
        else if ([[notification name] isEqualToString:
                  @"detectedRequiredBuiltinDisplayMissing"])
        {
            if (self.sessionState.builtinDisplayNotAvailableDetected == NO) {
                if (![self.preferencesController preferencesAreOpen] && !self.openingSettings) {
                    // Don't display the alert or lock screen while opening new settings
                    if ((self.startingUp || self.restarting)) {
                        // SEB is starting, we give the option to quit
                        NSAlert *modalAlert = [self newAlert];
                        [modalAlert setMessageText:NSLocalizedString(@"No Built-In Display Available!", @"")];
                        [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"A built-in display is required, but not available. If you're using a MacBook, use its internal display and start %@ again.", @""), SEBShortAppName]];
                        [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", @"")];
                        [modalAlert setAlertStyle:NSAlertStyleCritical];
                        void (^vmDetectedHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                            [self removeAlertWindow:modalAlert.window];
                            [self quitSEBOrSession];
                        };
                        [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))vmDetectedHandler];
                        return;
                    }
                    self.sessionState.builtinDisplayNotAvailableDetected = YES;
                    if (self.sessionState.builtinDisplayEnforceOverride == NO && ![self.preferencesController preferencesAreOpen]) {
                        self.sebLockedViewController.overrideEnforcingBuiltinScreen.state = false;
                        self.sebLockedViewController.overrideEnforcingBuiltinScreen.hidden = false;
                        [self.sebLockedViewController setLockdownAlertTitle: NSLocalizedString(@"No Built-In Display Available!", @"Lockdown alert title text for no required built-in display available")
                                                                    Message:NSLocalizedString(@"A built-in display is required, but not available. If you're using a MacBook, use its internal display. To override this requirement, select the option below and enter the quit/unlock password, which usually exam supervision/support knows.", @"")];
                    }
                    [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"No built-in display available, although required in settings!", @"")] withTime:self.didBecomeActiveTime repeated:NO];
                    
                    if (self.sessionState.builtinDisplayEnforceOverride == NO) {
                        [self openLockdownWindows];
                    }
                }
            } else {
                DDLogDebug(@"%s: self.sessionState.builtinDisplayNotAvailableDetected == YES", __FUNCTION__);
                if (self.sessionState.noRequiredBuiltInScreenAvailable == NO) {
                    DDLogDebug(@"%s: self.sessionState.noRequiredBuiltInScreenAvailable == NO", __FUNCTION__);
                    // Previously there was no built-in display detected and SEB locked, now there is one available
                    // this can happen on a MacBook when the display lid was closed and now opened again
                    // if there was no previous lock message, we can close the lockdown screen
                    self.sessionState.builtinDisplayNotAvailableDetected = NO;
                    self.sebLockedViewController.overrideEnforcingBuiltinScreen.hidden = YES;
                    DDLogDebug(@"%s: _sebLockedViewController %@, quitInsteadUnlockingButton.state: %ld", __FUNCTION__, self.sebLockedViewController, (long)self.sebLockedViewController.quitInsteadUnlockingButton.state);
                    self.sebLockedViewController.quitInsteadUnlockingButton.state = NO;
                    DDLogDebug(@"%s: _sebLockedViewController.quitInsteadUnlockingButton.state: %ld", __FUNCTION__, (long)self.sebLockedViewController.quitInsteadUnlockingButton.state);
                    [self conditionallyCloseLockdownWindows];
                }
            }
        }
        
        // Handler called when dictation was detected
        
        else if ([[notification name] isEqualToString:
                  @"proctoringFailed"])
        {
            self.sessionState.proctoringFailedDetected = YES;
            // Set custom alert message string
            NSString *proctoringFailedErrorString = [notification.userInfo objectForKey:NSLocalizedFailureReasonErrorKey];
            [self.sebLockedViewController setLockdownAlertTitle:[NSString stringWithFormat:NSLocalizedString(@"Proctoring Error Locked %@!", @"Lockdown alert title text for proctoring failure"), SEBShortAppName]
                                                        Message:[NSString stringWithFormat:NSLocalizedString(@"Proctoring failed with error '%@'. Enter the quit/unlock password, which usually exam supervision/support knows.", @""), proctoringFailedErrorString]];
            self.sebLockedViewController.retryButton.hidden = NO;
            
            // Add log string for proctoring failed
            [self appendErrorString:[NSString stringWithFormat:@"%@%@\n", NSLocalizedString(@"Proctoring failed: ", @""), proctoringFailedErrorString] withTime:self.didBecomeActiveTime repeated:self.zoomUserRetryWasUsed];
            
            [self openLockdownWindows];
        } else {
            NSString *lockReason;
            BOOL isDisabled = NO;
            NSDictionary *userInfo = notification.userInfo;
            if (userInfo) {
                lockReason = [userInfo valueForKey:@"lockReason"];
                isDisabled = [[userInfo valueForKey:@"isDisabled"] boolValue];
            }
            NSString *message;
            NSString *logMessage;
            if (isDisabled) {
                message = [NSString stringWithFormat:NSLocalizedString(@"%@ is disabled. Enable %@ and restart %@.", @""), lockReason, lockReason, SEBShortAppName];
                logMessage = [NSString stringWithFormat:NSLocalizedString(@"%@ is disabled!", @""), lockReason];
            } else {
                message = [NSString stringWithFormat:@"%@", lockReason ? lockReason : NSLocalizedString(@"Please contact your exam support.", @"")];
                logMessage = lockReason;
            }
            DDLogError(@"Lock Reason: %@", lockReason);
            [self.sebLockedViewController setLockdownAlertTitle: [NSString stringWithFormat:NSLocalizedString(@"%@ is Locked!", @""), SEBShortAppName]
                                                        Message:message];
            [self appendErrorString:[NSString stringWithFormat:@"%@\n", logMessage] withTime:self.didBecomeActiveTime repeated:NO];
            [self openLockdownWindowsQuitOnly:isDisabled];
        }

    });
}


- (void) appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime repeated:(BOOL)repeated
{
    if (!repeated &&
        (_establishingSEBServerConnection || _sebServerConnectionEstablished)) {
        NSInteger notificationID = [self.serverController sendLockscreenWithMessage:[NSString stringWithFormat:@"%@", errorString]];
        NSNumber *notificationIDNumber = [NSNumber numberWithInteger:notificationID];
        [self.sebServerPendingLockscreenEvents addObject:notificationIDNumber];
    }
    [self.sebLockedViewController appendErrorString:errorString withTime:errorTime];
}


- (void)appendErrorStringsFor:(NSMutableSet *)runningOverriddenProhibitedProcesses
   runningProhibitedProcesses:(NSMutableSet *)runningProhibitedProcesses
                     repeated:(BOOL)repeated {
    if (runningProhibitedProcesses.count > 0) {
        NSArray *runningProhibitedProcessesArray = repeated ? [runningProhibitedProcesses valueForKey:@"name"] : [runningProhibitedProcesses allObjects];
        [self appendErrorString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"Prohibited processes detected", @""), runningProhibitedProcessesArray] withTime:self.didBecomeActiveTime repeated:repeated];
    }
    if (runningOverriddenProhibitedProcesses.count > 0) {
        [self appendErrorString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"Prohibited processes (check overridden) still running", @""), runningOverriddenProhibitedProcesses] withTime:self.didBecomeActiveTime repeated:repeated];
    }
}


- (NSMutableArray *) sebServerPendingLockscreenEvents
{
    if (!_sebServerPendingLockscreenEvents) {
        _sebServerPendingLockscreenEvents = [NSMutableArray new];
    }
    return _sebServerPendingLockscreenEvents;
}


- (BOOL) conditionallyLockExam:(NSString *)examURLString configKey:(NSData *)configKey
{
    if ([self.sebLockedViewController isStartingLockedExam:examURLString configKey:configKey]) {
        if ([[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length != 0) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"detectedReOpeningExam" object:self];
            return YES;
        } else {
            // Remove a previously locked exam
            DDLogWarn(@"Re-opening an exam which was locked before, but now doesn't have a quit password set, therefore doesn't run in secure mode.");
            [self.sebLockedViewController removeLockedExam:[[NSUserDefaults standardUserDefaults] secureStringForKey:examURLString] configKey:configKey];
        }
    }
    return NO;
}


- (void) openLockdownWindows
{
    [self openLockdownWindowsQuitOnly:NO];
}

- (void) openLockdownWindowsQuitOnly:(BOOL)quitOnly
{
    if (!self.lockdownWindows) {
        self.didLockSEBTime = [NSDate date];
        DDLogDebug(@"openLockdownWindows: didLockSEBTime %@, didBecomeActiveTime %@", self.didLockSEBTime, self.didBecomeActiveTime);

        DDLogError(@"Locking SEB with red frontmost covering windows");
        [self openCoveringWindows];
        NSAccessibilityPostNotification(_sebLockedViewController.view.window, NSAccessibilityFocusedWindowChangedNotification);
        if (quitOnly) {
            _sebLockedViewController.quitUnlockPasswordUI.hidden = YES;
            _sebLockedViewController.quitOnlyButton.hidden = NO;
        } else {
            _sebLockedViewController.quitUnlockPasswordUI.hidden = NO;
            _sebLockedViewController.quitOnlyButton.hidden = YES;
        }
        lockdownModalSession = [NSApp beginModalSessionForWindow:self.lockdownWindows[0]];
        [NSApp runModalSession:lockdownModalSession];
    }
}


- (NSData *)configKey {
    return self.browserController.configKey;
}


- (void) retryButtonPressed
{
    DDLogDebug(@"%s", __FUNCTION__);
}

- (void) successfullyRetriedToConnect
{
    self.sessionState.proctoringFailedDetected = NO;
    [self conditionallyCloseLockdownWindows];
}


- (void) correctPasswordEntered
{
#ifdef DEBUG
    DDLogInfo(@"%s, _sebLockedViewController %@", __FUNCTION__, _sebLockedViewController);
#endif
    [_sebLockedViewController shouldCloseLockdownWindows];
}


- (NSURL *) startURL
{
    return self.sessionState.startURL;
}


- (void) conditionallyCloseLockdownWindows
{
    if (_sebLockedViewController.overrideCheckForScreenSharing.hidden &&
        _sebLockedViewController.overrideEnforcingBuiltinScreen.hidden &&
        _sebLockedViewController.overrideCheckForSiri.hidden &&
        _sebLockedViewController.overrideCheckForDictation.hidden &&
        _sebLockedViewController.overrideCheckForSpecifcProcesses.hidden &&
        _sebLockedViewController.overrideCheckForAllProcesses.hidden &&
        !self.sessionState.proctoringFailedDetected &&
        !self.sessionState.userSwitchDetected) {
        DDLogDebug(@"%s: close lockdown windows", __FUNCTION__);
        [self closeLockdownWindowsAllowOverride:YES];
    }
}

- (void) closeLockdownWindowsAllowOverride:(BOOL)allowOverride
{
    if (self.lockdownWindows) {
        DDLogError(@"Unlocking SEB, removing red frontmost covering windows");

        [NSApp endModalSession:lockdownModalSession];

        if (_sebLockedViewController.overrideCheckForScreenSharing.state == YES) {
            DDLogInfo(@"%s: overrideCheckForScreenSharing selected", __FUNCTION__);
            self.sessionState.screenSharingCheckOverride = allowOverride;
            _sebLockedViewController.overrideCheckForScreenSharing.state = NO;
            _sebLockedViewController.overrideCheckForScreenSharing.hidden = YES;
        }

        if (_sebLockedViewController.overrideEnforcingBuiltinScreen.state == YES) {
            DDLogInfo(@"%s: overrideEnforcingBuiltinScreen selected", __FUNCTION__);
            if (allowOverride) {
                self.sessionState.builtinDisplayEnforceOverride = YES;
                self.sessionState.builtinDisplayNotAvailableDetected = NO;
            }
            _sebLockedViewController.overrideEnforcingBuiltinScreen.state = NO;
            _sebLockedViewController.overrideEnforcingBuiltinScreen.hidden = YES;
        }

        if (_sebLockedViewController.overrideCheckForSiri.state == YES) {
            DDLogInfo(@"%s: overrideCheckForSiri selected", __FUNCTION__);
            self.sessionState.siriCheckOverride = allowOverride;
            _sebLockedViewController.overrideCheckForSiri.state = NO;
            _sebLockedViewController.overrideCheckForSiri.hidden = YES;
        }
        
        if (_sebLockedViewController.overrideCheckForDictation.state == YES) {
            DDLogInfo(@"%s: overrideCheckForDictation selected", __FUNCTION__);
            self.sessionState.dictationCheckOverride = allowOverride;
            _sebLockedViewController.overrideCheckForDictation.state = NO;
            _sebLockedViewController.overrideCheckForDictation.hidden = YES;
        }
        
        if (_sebLockedViewController.overrideCheckForSpecifcProcesses.state == YES) {
            DDLogInfo(@"%s: overrideCheckForSpecifcProcesses selected", __FUNCTION__);
            if (allowOverride) {
                self.sessionState.processCheckSpecificOverride = YES;
                if (_runningProhibitedProcesses.count > 0) {
                    if (!self.sessionState.overriddenProhibitedProcesses) {
                        self.sessionState.overriddenProhibitedProcesses = _runningProhibitedProcesses.copy;
                    } else {
                        self.sessionState.overriddenProhibitedProcesses = [self.sessionState.overriddenProhibitedProcesses arrayByAddingObjectsFromArray:_runningProhibitedProcesses];
                    }
                    // Check if overridden processes are prohibited BSD processes from settings
                    // and remove them from the list of the periodically called process watcher checks
                    [[ProcessManager sharedProcessManager] removeOverriddenProhibitedBSDProcesses:self.sessionState.overriddenProhibitedProcesses];
                    DDLogInfo(@"%s: overrideCheckForSpecifcProcesses: %@", __FUNCTION__, self.sessionState.overriddenProhibitedProcesses);
                }
            }
            _sebLockedViewController.overrideCheckForSpecifcProcesses.state = NO;
            _sebLockedViewController.overrideCheckForSpecifcProcesses.hidden = YES;
            self.sessionState.processesDetected = NO;
        }
        
        if (_sebLockedViewController.overrideCheckForAllProcesses.state == YES) {
            DDLogInfo(@"%s: overrideCheckForAllProcesses selected", __FUNCTION__);
            self.sessionState.processCheckAllOverride = allowOverride;
            _sebLockedViewController.overrideCheckForAllProcesses.state = NO;
            _sebLockedViewController.overrideCheckForAllProcesses.hidden = YES;
        }
        
        if (self.sessionState.screenSharingCheckOverride == NO) {
            self.sessionState.screenSharingDetected = NO;
        }
        lastTimeProcessCheck = [NSDate date];
        _SIGSTOPDetected = NO;
        
        self.sessionState.proctoringFailedDetected = NO;
        _zoomUserRetryWasUsed = NO;
        self.sessionState.userSwitchDetected = NO;
        _sebLockedViewController.retryButton.hidden = YES;
        if (self.sebServerPendingLockscreenEvents.count > 0) {
            [self.serverController confirmLockscreensWithUIDs:self.sebServerPendingLockscreenEvents.copy];
            [self.sebServerPendingLockscreenEvents removeAllObjects];
        }
        
        if (allowOverride) {
            DDLogDebug(@"%s: _sebLockedViewController %@, quitInsteadUnlockingButton.state: %ld", __FUNCTION__, _sebLockedViewController, (long)_sebLockedViewController.quitInsteadUnlockingButton.state);
            if (_sebLockedViewController.quitInsteadUnlockingButton.state == YES) {
                DDLogInfo(@"%s: overrideCheckForDictation selected", __FUNCTION__);
                _sebLockedViewController.quitInsteadUnlockingButton.state = NO;
                [self quitSEBOrSession];
            }
        } else {
            _sebLockedViewController.quitInsteadUnlockingButton.state = NO;
        }

        [_sebLockedViewController.view removeFromSuperview];
        [self closeCoveringWindows:self.lockdownWindows];
        self.lockdownWindows = nil;
    } else {
        DDLogDebug(@"%s but there are no open lockdown windows anymore, returning.", __FUNCTION__);
    }
}


- (void) openCoveringWindows
{
    DDLogDebug(@"%s", __FUNCTION__);

    self.lockdownWindows = [self fillScreensWithCoveringWindows:coveringWindowLockdownAlert
                                                    windowLevel:NSScreenSaverWindowLevel
                                                 excludeMenuBar:false];
    NSWindow *coveringWindow = self.lockdownWindows[0];
    NSView *coveringView = coveringWindow.contentView;
    [coveringView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [coveringView setTranslatesAutoresizingMaskIntoConstraints:true];
    
    _sebLockedViewController.sebController = self;
    
    [coveringView addSubview:_sebLockedViewController.view];
    
    DDLogVerbose(@"Frame of superview: %f, %f", _sebLockedViewController.view.superview.frame.size.width, _sebLockedViewController.view.superview.frame.size.height);
    NSMutableArray *constraints = [NSMutableArray new];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_sebLockedViewController.view
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_sebLockedViewController.view.superview
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:_sebLockedViewController.view
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:_sebLockedViewController.view.superview
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0
                                                         constant:0.0]];

    [_sebLockedViewController.view.superview addConstraints:constraints];
}


- (void) closeCoveringWindows:(NSMutableArray *)windows
{
    DDLogDebug(@"%s: %@", __FUNCTION__, windows);

    // Close the covering windows
	NSUInteger windowIndex;
	NSUInteger windowCount = [windows count];
    for (windowIndex = 0; windowIndex < windowCount; windowIndex++ )
    {
		[(NSWindow *)[windows objectAtIndex:windowIndex] close];
	}
    [windows removeAllObjects];
}


- (void) openInfoHUD:(NSString *)lockedTimeInfo
{
    informationHUDLabel.font = [NSFont boldSystemFontOfSize:[NSFont systemFontSize]];   
    informationHUDLabel.textColor = [NSColor whiteColor];
    NSMutableString *informationText = [NSMutableString stringWithString:(lockedTimeInfo)];
    
    if (self.sessionState.reOpenedExamDetected) {
        informationHUDLabel.textColor = [NSColor redColor];
        [informationText appendString:[NSString stringWithFormat:@"\n\n%@",
                                       NSLocalizedString(@"Previously interrupted exam was re-opened!", @"")]];
        self.sessionState.reOpenedExamDetected = NO;
    }
    
    if (self.sessionState.screenSharingCheckOverride) {
        informationHUDLabel.textColor = [NSColor redColor];
        [informationText appendString:[NSString stringWithFormat:@"\n\n%@",
                                       NSLocalizedString(@"Detecting screen sharing was disabled!", @"")]];
    }
    
    if (self.sessionState.siriCheckOverride) {
        informationHUDLabel.textColor = [NSColor redColor];
        [informationText appendString:[NSString stringWithFormat:@"\n\n%@",
                                       NSLocalizedString(@"Detecting Siri was disabled!", @"")]];
    }
    
    if (self.sessionState.dictationCheckOverride) {
        informationHUDLabel.textColor = [NSColor redColor];
        [informationText appendString:[NSString stringWithFormat:@"\n\n%@",
                                       NSLocalizedString(@"Detecting dictation was disabled!", @"")]];
    }
    
    if (self.sessionState.processCheckAllOverride) {
        informationHUDLabel.textColor = [NSColor redColor];
        [informationText appendString:[NSString stringWithFormat:@"\n\n%@",
                                       NSLocalizedString(@"Detecting processes was completely disabled!", @"")]];
    } else if (self.sessionState.processCheckSpecificOverride) {
        informationHUDLabel.textColor = [NSColor redColor];
        [informationText appendString:[NSString stringWithFormat:@"\n\n%@",
                                       NSLocalizedString(@"Detecting specific processes was disabled!", @"")]];
    }
    
    NSString *informationTextFinal = [informationText copy];
    [informationHUDLabel setStringValue:informationTextFinal];
    NSArray *screens = [NSScreen screens];    // get all available screens
    NSScreen *mainScreen = screens[0];
    
    NSPoint topLeftPoint;
    topLeftPoint.x = mainScreen.frame.origin.x + mainScreen.frame.size.width - informationHUD.frame.size.width - mainScreen.menuBarHeight;
    topLeftPoint.y = mainScreen.frame.origin.y + mainScreen.frame.size.height - 44;
    [informationHUD setFrameTopLeftPoint:topLeftPoint];
    
    informationHUD.becomesKeyOnlyIfNeeded = YES;
    [informationHUD setLevel:NSModalPanelWindowLevel];
    DDLogDebug(@"Opening info HUD: %@", informationTextFinal);
    [informationHUD makeKeyAndOrderFront:nil];
}


- (void) openLockModalWindows
{
    self.lockModalWindows = [self fillScreensWithCoveringWindows:coveringWindowModalAlert
                                                    windowLevel:NSScreenSaverWindowLevel
                                                 excludeMenuBar:false];
}

- (void) closeLockModalWindows
{
    [self closeCoveringWindows:self.lockModalWindows];
}


#pragma mark - Managing Other Running Applications

- (void) startTask {
	// Start third party application from within SEB
	
	// Path to Excel
	NSString *pathToTask=@"/Applications/Preview.app/Contents/MacOS/Preview";
	
	// Parameter and path to XUL-SEB Application
	NSArray *taskArguments=[NSArray arrayWithObjects:@"", nil];
	
	// Allocate and initialize a new NSTask
    NSTask *task=[[NSTask alloc] init];
	
	// Tell the NSTask what the path is to the binary it should launch
    [task setLaunchPath:pathToTask];
    
    // The argument that we pass to XULRunner (in the form of an array) is the path to the SEB-XUL-App
    [task setArguments:taskArguments];
    	
	// Launch the process asynchronously
	@try {
		[task launch];
	}
	@catch (NSException * e) {
		DDLogError(@"Error.  Make sure you have a valid path and arguments.");
		
	}
}


// hide all other applications if not in debug build setting
// Check if the app is listed in prohibited processes
- (void) regainActiveStatus: (id _Nullable)sender
{
#ifdef DEBUG
    DDLogInfo(@"%s: Notification:  %@", __FUNCTION__, [sender name]);
#endif
    
    NSDictionary *userInfo = [sender userInfo];
    if (userInfo) {
        NSRunningApplication *launchedApp = [userInfo objectForKey:NSWorkspaceApplicationKey];
#ifdef DEBUG
        DDLogInfo(@"Activated app localizedName: %@, bundle ID: %@, executableURL: %@", launchedApp.localizedName, launchedApp.bundleIdentifier, launchedApp.executableURL);
#endif
        if (systemPreferencesOpenedForScreenRecordingPermissions && [launchedApp.bundleIdentifier isEqualToString:systemPreferencesBundleID]) {
            systemPreferencesOpenedForScreenRecordingPermissions = NO;
            [NSApp abortModal];
        }
    }
    
    // Load preferences from the system's user defaults database
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    if (!allowSwitchToThirdPartyApps && ![self.preferencesController preferencesAreOpen] && !fontRegistryUIAgentRunning) {
        // if switching to ThirdPartyApps not allowed
        DDLogDebug(@"Regain active status after %@", [sender name]);
#ifndef DEBUG
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        if (_isAACEnabled == NO && _wasAACEnabled == NO) {
            [[NSWorkspace sharedWorkspace] performSelectorOnMainThread:@selector(hideOtherApplications) withObject:NULL waitUntilDone:NO];
        }
#endif
        [self.browserController.mainBrowserWindow makeKeyAndOrderFront:self];
//        [self.browserController.mainBrowserWindow makeMainWindow];
//        [self.browserController.mainBrowserWindow makeActiveAndOrderFront];
//        [self.browserController.mainBrowserWindow makeContentFirstResponder];
        DDLogDebug(@"Active window: %@", NSApp.mainWindow);
//        NSAccessibilityPostNotification(self.browserController.mainBrowserWindow, NSAccessibilityFocusedWindowChangedNotification);
        
        if (NSApp.mainWindow) {
            NSDictionary *userInfo = @{
                NSAccessibilityUIElementsKey: @[NSApp.mainWindow],
                NSAccessibilityFocusedWindowAttribute: NSApp.mainWindow
            };
            NSAccessibilityPostNotificationWithUserInfo(NSApp.mainWindow, NSAccessibilityFocusedUIElementChangedNotification, userInfo);
        }
    }
}


- (void) appLaunch: (id)sender
{
#ifdef DEBUG
    DDLogInfo(@"%s: Notification:  %@", __FUNCTION__, [sender name]);
#endif
    
    if ([[sender name] isEqualToString:@"NSWorkspaceDidLaunchApplicationNotification"]) {
        NSDictionary *userInfo = [sender userInfo];
        if (userInfo) {
            // Save the information which app was started
            launchedApplication = [userInfo objectForKey:NSWorkspaceApplicationKey];
            NSString *launchedAppBundleID = launchedApplication.bundleIdentifier;
            DDLogInfo(@"launched app localizedName: %@, bundleID: %@ executableURL: %@", [launchedApplication localizedName], launchedAppBundleID, [launchedApplication executableURL]);
        }
    }
}


- (void) spaceSwitch: (id)sender
{
#ifdef DEBUG
    DDLogInfo(@"%s: Notification:  %@", __FUNCTION__, [sender name]);
#endif
    
    NSDictionary *userInfo = [sender userInfo];
    NSRunningApplication *workspaceSwitchingApp;
    if (userInfo) {
        workspaceSwitchingApp = [userInfo objectForKey:NSWorkspaceApplicationKey];
        DDLogInfo(@"App which switched Space localized name: %@, executable URL: %@", [workspaceSwitchingApp localizedName], [workspaceSwitchingApp executableURL]);
    }
    // If an app was started since SEB was running
    if (_isAACEnabled == NO && _wasAACEnabled == NO && launchedApplication && ![launchedApplication isEqual:[NSRunningApplication currentApplication]]) {
        // Yes: We assume it's the app which switched the space and force terminate it!
        DDLogError(@"An app was started and switched the Space. SEB will force terminate it! (app localized name: %@, executable URL: %@)", [launchedApplication localizedName], [launchedApplication executableURL]);
        
        DDLogDebug(@"Reinforcing the kiosk mode was requested");
        // Switch the strict kiosk mode temporarily off
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
        [self switchKioskModeAppsAllowed:YES overrideShowMenuBar:NO];
        
        // Close the black background covering windows
        [self closeCapWindows];
        
        [self killApplication:launchedApplication];
        launchedApplication = nil;

        // Reopen the covering Windows and reset the windows elevation levels
        DDLogDebug(@"requestedReinforceKioskMode: Reopening cap windows.");
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        if (self.browserController.mainBrowserWindow.isVisible) {
            [self.browserController.mainBrowserWindow makeKeyAndOrderFront:self];
        }
        
        // Open new covering background windows on all currently available screens
        [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
        [self coverScreens];
        
        // Switch the proper kiosk mode on again
        [self setElevateWindowLevels];
        
        BOOL allowSwitchToThirdPartyApps = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"];
        [self switchKioskModeAppsAllowed:allowSwitchToThirdPartyApps overrideShowMenuBar:NO];
        
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        [self.browserController.mainBrowserWindow makeKeyAndOrderFront:self];

        if (NSApp.mainWindow) {
            NSDictionary *userInfo = @{
                NSAccessibilityUIElementsKey: @[NSApp.mainWindow],
                NSAccessibilityFocusedWindowAttribute: NSApp.mainWindow
            };
            NSAccessibilityPostNotificationWithUserInfo(NSApp.mainWindow, NSAccessibilityFocusedUIElementChangedNotification, userInfo);
        }
    }
}


- (BOOL) killApplication:(NSRunningApplication *)application
{
    NSString *appLocalizedName = application.localizedName;
    appLocalizedName = appLocalizedName ? appLocalizedName : application.executableURL.path;
    NSURL *appURL = [self getBundleOrExecutableURL:application];
    appURL = appURL ? appURL : NSURL.new;
    NSString *appBundleID = application.bundleIdentifier;
    appBundleID = appBundleID ? appBundleID : application.bundleURL.path;
    NSDictionary *processDetails = @{
        @"name" : appLocalizedName,
        @"PID" : [NSNumber numberWithInt:application.processIdentifier],
        @"URL": appURL,
        @"bundleID" : appBundleID
    };
    if (!self.sessionState.processCheckAllOverride && ![self isOverriddenProhibitedProcess:processDetails]) {
        BOOL killSuccess = [application kill];
        if (!killSuccess) {
            DDLogError(@"Couldn't terminate app with localized name (error %ld): %@, bundle or executable URL: %@", (long)killSuccess, appLocalizedName, appURL);
            [_runningProhibitedProcesses addObject:processDetails];
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"detectedProhibitedProcess" object:self];
        } else {
            if ([appBundleID isEqualToString:WebKitNetworkingProcessBundleID] || [appBundleID isEqualToString:UniversalControlBundleID]) {
                DDLogVerbose(@"Successfully terminated app with localized name: %@, bundle or executable URL: %@", appLocalizedName, appURL);
            } else {
                DDLogDebug(@"Successfully terminated app with localized name: %@, bundle or executable URL: %@", appLocalizedName, appURL);
            }
            if (appURL) {
                // Add the app's file URL, so we can restart it when exiting SEB
                [_terminatedProcessesExecutableURLs addObject:appURL];
            }
        }
        return killSuccess;
    } else {
        DDLogWarn(@"Didn't terminate app with localized name: %@, bundle or executable URL: %@, because a user did override it with the quit/unlock password.", appLocalizedName, appURL);
        return YES;
    }
}


- (NSError * _Nullable) killProcessWithPID:(pid_t)processPID
{
    NSString * processName = [self getProcessName:processPID];
    NSDictionary *processDetails = @{
        @"name" : processName,
        @"PID" : [NSNumber numberWithInt:processPID]
    };
    return [self killProcess:processDetails];
}


- (NSError * _Nullable) killProcess:(NSDictionary *)processDictionary
{
    NSNumber *PID = [processDictionary objectForKey:@"PID"];
    pid_t processPID = PID.intValue;
    
    NSRunningApplication *application = [NSRunningApplication runningApplicationWithProcessIdentifier:processPID];
    NSURL *appURL = processDictionary[@"URL"];
    NSMutableDictionary *processDetails = [NSMutableDictionary new];
    NSString *processName = processDictionary[@"name"];
    if (processName) {
        [processDetails setValue:processName forKey:@"name"];
    }
    if (application) {
        appURL = [self getBundleOrExecutableURL:application];
        [processDetails setValue:application.bundleIdentifier forKey:@"bundleID"];
    } else if (!appURL) {
        NSString *executablePath = [ProcessManager getExecutablePathForPID:processPID];
        if (executablePath) {
            appURL = [NSURL fileURLWithPath:executablePath isDirectory:NO];
        }
    }
    if (appURL) {
        [processDetails setValue:appURL forKey:@"URL"];
    }

    NSError *error = nil;
    if (!self.sessionState.processCheckAllOverride && ![self isOverriddenProhibitedProcess:processDetails]) {
        BOOL killSuccess = [NSRunningApplication killProcessWithPID:processPID error:&error];
        if (killSuccess) {
            DDLogDebug(@"Successfully terminated application/process: %@", processDetails);
            if (appURL) {
                [_terminatedProcessesExecutableURLs addObject:appURL];
            }
        } else {
            DDLogError(@"Couldn't terminate application/process: %@, error code: %ld", processDetails, (long)killSuccess);
            if (![_runningProhibitedProcesses containsObject:processDetails.copy]) {
                [_runningProhibitedProcesses addObject:processDetails.copy];
            }
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"detectedProhibitedProcess" object:self];
        }
    } else {
        DDLogWarn(@"Didn't terminate app with localized name '%@' or process with bundle or executable URL '%@', because a user did override it with the quit/unlock password.", application.localizedName, appURL);
    }
    return error;
}


- (BOOL) isOverriddenProhibitedProcess:(NSDictionary *)processDetails
{
    if (self.sessionState.overriddenProhibitedProcesses) {
        NSArray *filteredOverriddenProcesses = self.sessionState.overriddenProhibitedProcesses.copy;
        NSString *bundleID = processDetails[@"bundleID"];
        if (bundleID) {
            NSPredicate *processFilter = [NSPredicate predicateWithFormat:@"bundleID ==[cd] %@", bundleID];
            filteredOverriddenProcesses = [filteredOverriddenProcesses filteredArrayUsingPredicate:processFilter];
            if (filteredOverriddenProcesses.count == 0) {
                return NO;
            }
        }
        NSURL* processURL = processDetails[@"URL"];
        if (processURL) {
            NSPredicate *processFilter = [NSPredicate predicateWithFormat:@"URL ==[cd] %@", processURL];
            filteredOverriddenProcesses = [filteredOverriddenProcesses filteredArrayUsingPredicate:processFilter];
            if (filteredOverriddenProcesses.count == 0) {
                return NO;
            }
        }
        NSString *processName = processDetails[@"name"];
        NSPredicate *processFilter = [NSPredicate predicateWithFormat:@"name ==[cd] %@", processName];
        filteredOverriddenProcesses = [filteredOverriddenProcesses filteredArrayUsingPredicate:processFilter];
        if (filteredOverriddenProcesses.count != 0) {
            return YES;
        }
    }
    return NO;
}


- (void) SEBgotActive: (id)sender {
    DDLogDebug(@"SEB got active");
//    [self startKioskMode];
}


#pragma mark - Kiosk Mode

- (void) updateAACAvailablility
{
    NSUInteger currentOSMajorVersion = NSProcessInfo.processInfo.operatingSystemVersion.majorVersion;
    NSUInteger currentOSMinorVersion = NSProcessInfo.processInfo.operatingSystemVersion.minorVersion;
    NSUInteger currentOSPatchVersion = NSProcessInfo.processInfo.operatingSystemVersion.patchVersion;

    BOOL aacDnsPrePinning = [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_aacDnsPrePinning"];
    // Determine on which macOS versions AAC is possible:
    BOOL aacPossible = ((currentOSMajorVersion == 10 && currentOSMinorVersion == 15 && currentOSPatchVersion >= 4) && //>= Catalina 10.15.4
    !(currentOSMajorVersion == 10 && currentOSMinorVersion == 15 && currentOSPatchVersion == 5)) || //except 10.15.5 connectivity broken
    (aacDnsPrePinning && currentOSMajorVersion == 11) || //Big Sur 11 with DNS pre-pinning
    (aacDnsPrePinning && currentOSMajorVersion == 12 && currentOSMinorVersion == 1) || //Monterey 12.1 with DNS pre-pinning
    (currentOSMajorVersion == 12 && currentOSMinorVersion > 1) || //>12.1 without bugs (hopefully)
    currentOSMajorVersion > 12;
    
    if (aacPossible) {
        DDLogDebug(@"Running on supported macOS version where AAC isn't buggy (or with DNS pre-pinning enabled), may use AAC if allowed in current settings.");
        _isAACEnabled = [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enableMacOSAAC"] && !_overrideAAC;
    } else {
        _isAACEnabled = NO;
    }
    DDLogDebug(@"Updated _isAACEnabled to %d (_overrideAAC = %d)", _isAACEnabled, _overrideAAC);
}


// Method which sets the setting flag for elevating window levels according to the
// setting key allowSwitchToApplications
- (void) setElevateWindowLevels
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    _allowSwitchToApplications = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"];
    if (_allowSwitchToApplications || _isAACEnabled || _wasAACEnabled) {
        DDLogDebug(@"%s: false", __FUNCTION__);
        [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
    } else {
        DDLogDebug(@"%s: true", __FUNCTION__);
        [preferences setSecureBool:YES forKey:@"org_safeexambrowser_elevateWindowLevels"];
    }
}


- (void) startKioskMode {
    DDLogDebug(@"%s", __FUNCTION__);
	// Switch to kiosk mode by setting the proper presentation options
    // Load preferences from the system's user defaults database
//    [self startKioskModeThirdPartyAppsAllowed:YES];
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    DDLogDebug(@"startKioskMode switchToApplications %hhd", allowSwitchToThirdPartyApps);
    [self startKioskModeThirdPartyAppsAllowed:allowSwitchToThirdPartyApps overrideShowMenuBar:NO];

}


- (void) switchKioskModeAppsAllowed:(BOOL)allowApps overrideShowMenuBar:(BOOL)overrideShowMenuBar
{
    DDLogDebug(@"%s allowApps: %hhd overrideShowMenuBar: %hhd", __FUNCTION__, allowApps, overrideShowMenuBar);
	// Switch the kiosk mode to either only browser windows or also third party apps allowed:
    // Change presentation options and windows levels without closing/reopening cap background and browser foreground windows
    [self startKioskModeThirdPartyAppsAllowed:allowApps overrideShowMenuBar:overrideShowMenuBar];
    [self changeWindowLevels:allowApps];
}


// Change window levels without closing/reopening cap background and browser foreground windows
- (void) changeWindowLevels:(BOOL)allowApps
{
    DDLogDebug(@"%s allowApps: %hhd", __FUNCTION__, allowApps);
    
    // Change window level of cap windows
    CapWindow *capWindow;
    BOOL allowAppsUserDefaultsSetting = [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"];
    
    for (capWindow in self.capWindows) {
        if (allowApps || _isAACEnabled) {
            [capWindow newSetLevel:NSNormalWindowLevel];
            if (allowAppsUserDefaultsSetting) {
                capWindow.collectionBehavior = NSWindowCollectionBehaviorStationary + NSWindowCollectionBehaviorFullScreenAuxiliary +NSWindowCollectionBehaviorFullScreenDisallowsTiling;
            }
        } else {
            [capWindow newSetLevel:NSMainMenuWindowLevel+2];
        }
    }
    
    // Change window level of all open browser windows
    [self.browserController browserWindowsChangeLevelAllowApps:allowApps];
    
    // Change window level of a modal window (like an alert) if one is displayed
    [self adjustModalAlertWindowLevels:allowAppsUserDefaultsSetting];
    
    // Change window level of the about window if it is displayed
    if (self.aboutWindow.isVisible) {
        DDLogWarn(@"About window displayed");
        if (allowApps  || _isAACEnabled) {
            [self.aboutWindow newSetLevel:NSModalPanelWindowLevel-1];
        } else {
            [self.aboutWindow newSetLevel:NSMainMenuWindowLevel+5];
        }
    }
}


- (void) startKioskModeThirdPartyAppsAllowed:(BOOL)allowSwitchToThirdPartyApps overrideShowMenuBar:(BOOL)overrideShowMenuBar
{
    DDLogDebug(@"%s", __FUNCTION__);
    // Switch to kiosk mode by setting the proper presentation options
    // Load preferences from the system's user defaults database
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL showMenuBar = overrideShowMenuBar || [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showMenuBar"];
    NSApplicationPresentationOptions presentationOptions;
    
        if (allowSwitchToThirdPartyApps) {
            [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
        } else {
            [preferences setSecureBool:YES forKey:@"org_safeexambrowser_elevateWindowLevels"];
        }
        
        if (!allowSwitchToThirdPartyApps) {
            // if switching to third party apps not allowed
            presentationOptions =
            NSApplicationPresentationDisableAppleMenu +
            NSApplicationPresentationHideDock +
            (showMenuBar ? 0 : NSApplicationPresentationHideMenuBar) +
            NSApplicationPresentationDisableProcessSwitching +
            NSApplicationPresentationDisableForceQuit +
            NSApplicationPresentationDisableSessionTermination;
        } else {
            presentationOptions =
            (showMenuBar ? 0 : NSApplicationPresentationHideMenuBar) +
            NSApplicationPresentationHideDock +
            NSApplicationPresentationDisableAppleMenu +
            NSApplicationPresentationDisableForceQuit +
            NSApplicationPresentationDisableSessionTermination;
        }
    
    @try {
        [[MyGlobals sharedMyGlobals] setStartKioskChangedPresentationOptions:YES];
        
        DDLogDebug(@"NSApp setPresentationOptions: %lo", presentationOptions);
        
        [NSApp setPresentationOptions:presentationOptions];
        [[MyGlobals sharedMyGlobals] setPresentationOptions:presentationOptions];
    }
    @catch(NSException *exception) {
        DDLogError(@"Error.  Make sure you have a valid combination of presentation options.");
    }
    
        // Change window level of a modal window (like an alert) if one is displayed
        [self adjustModalAlertWindowLevels:allowSwitchToThirdPartyApps];
        
        // Change window level of the about window if it is displayed
        if (self.aboutWindow.isVisible) {
            DDLogWarn(@"About window displayed");
            if (allowSwitchToThirdPartyApps || _isAACEnabled) {
                [self.aboutWindow newSetLevel:NSModalPanelWindowLevel-1];
            } else {
                [self.aboutWindow newSetLevel:NSMainMenuWindowLevel+5];
            }
        }
    }


// Change window level of a modal window (like an alert) if one is displayed
- (void)adjustModalAlertWindowLevels:(BOOL)allowSwitchToThirdPartyApps
{
    DDLogDebug(@"%s allowSwitchToThirdPartyApps: %hhd", __FUNCTION__, allowSwitchToThirdPartyApps);

    if (_modalAlertWindows.count) {
        DDLogWarn(@"Modal window(s) displayed");
        for (NSWindow *alertWindow in _modalAlertWindows)
        {
            if (allowSwitchToThirdPartyApps || _isAACEnabled) {
                [alertWindow newSetLevel:NSModalPanelWindowLevel];
            } else {
                [alertWindow newSetLevel:NSMainMenuWindowLevel+6];
            }
        }
    }
}


- (void)requestedReinforceKioskMode:(NSNotification *)notification
{
    [self reinforceKioskMode];
}

- (void)reinforceKioskMode
{
    if (![self.preferencesController preferencesAreOpen]) {
        DDLogDebug(@"Reinforcing the kiosk mode was requested");
        
        if (_isAACEnabled == NO && _wasAACEnabled == NO) {
            // Switch the strict kiosk mode temporary off
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
            [self switchKioskModeAppsAllowed:YES overrideShowMenuBar:NO];
            
            // Close the black background covering windows
            [self closeCapWindows];
            
            // Reopen the covering Windows and reset the windows elevation levels
            DDLogDebug(@"requestedReinforceKioskMode: Reopening cap windows.");
            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
            if (self.browserController.mainBrowserWindow.isVisible) {
                [self.browserController.mainBrowserWindow makeKeyAndOrderFront:self];
            }
            
            // Open new covering background windows on all currently available screens
            [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
            [self coverScreens];
            
            // Switch the proper kiosk mode on again
            [self setElevateWindowLevels];
            
            BOOL allowSwitchToThirdPartyApps = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"];
            [self switchKioskModeAppsAllowed:allowSwitchToThirdPartyApps overrideShowMenuBar:NO];
            
            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
            [self.browserController.mainBrowserWindow makeKeyAndOrderFront:self];
            
            if (NSApp.mainWindow) {
                NSDictionary *userInfo = @{
                    NSAccessibilityUIElementsKey: @[NSApp.mainWindow],
                    NSAccessibilityFocusedWindowAttribute: NSApp.mainWindow
                };
                NSAccessibilityPostNotificationWithUserInfo(NSApp.mainWindow, NSAccessibilityFocusedUIElementChangedNotification, userInfo);
            }
        }
        [self.browserController.mainBrowserWindow setCalculatedFrame];
    }
}


#pragma mark - Handling Additional Apps



#pragma mark - Setup Main User Interface

- (IBAction) reload:(id)sender
{
    if (!(_screenProctoringController && _screenProctoringController.sessionIsClosing)) {
        [self reloadButtonPressed];
    }
}

// Customized cut, copy, paste Menu commands

- (IBAction) copy:(id)sender
{
    if (![self.preferencesController preferencesAreOpen]) {
        [self.browserController privateCopy:sender];
    } else {
        [NSApp.keyWindow.firstResponder tryToPerform:@selector(copy:) with:sender];
    }
}


- (IBAction) cut:(id)sender
{
    if (![self.preferencesController preferencesAreOpen]) {
        [self.browserController privateCut:sender];
    } else {
        [NSApp.keyWindow.firstResponder tryToPerform:@selector(cut:) with:sender];
    }
}


- (IBAction) paste:(id)sender
{
    if (![self.preferencesController preferencesAreOpen]) {
        [self.browserController privatePaste:sender];
    } else {
        [NSApp.keyWindow.firstResponder tryToPerform:@selector(paste:) with:sender];
    }
}


// Find the real visible frame of a screen SEB is running on
- (NSRect) visibleFrameForScreen:(NSScreen *)screen
{
    if (!screen) {
        screen = self.browserController.mainBrowserWindow.screen;
    }
    // Get frame of the usable screen (considering if menu bar is enabled)
    NSRect screenFrame = screen.usableFrame;
    // Check if SEB Dock is displayed and reduce visibleFrame accordingly
    // Also check if mainBrowserWindow exists, because when starting with a temporary
    // browser window for loading a seb(s):// link from a authenticated server, there
    // is no main browser window open yet
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ((!self.browserController.mainBrowserWindow || screen == self.browserController.mainBrowserWindow.screen) && [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"]) {
        double dockHeight = [preferences secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
        screenFrame.origin.y += dockHeight;
        screenFrame.size.height -= dockHeight;
    }
    return screenFrame;
}


// Set up and display SEB Dock
- (void) openSEBDock
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (self.dockController) {
        [self.dockController hideDock];
        self.dockController = nil;
    }

    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"]) {
        
        DDLogDebug(@"SEBController openSEBDock: dock enabled");
        // Initialize the Dock
        SEBDockController *newDockController = [[SEBDockController alloc] init];
        self.dockController = newDockController;
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableSebBrowser"]) {
            SEBDockItem *dockItemSEB = [[SEBDockItem alloc] initWithTitle:SEBFullAppNameClassic
                                                                 bundleID:nil
                                                         allowManualStart:NO
                                                                     icon:[NSApp applicationIconImage]
                                                          highlightedIcon:[NSApp applicationIconImage]
                                                                  toolTip:nil
                                                                     menu:self.browserController.openBrowserWindowsWebViewsMenu
                                                                   target:self
                                                                   action:@selector(sebButtonPressed)
                                                          secondaryAction:nil];
            NSArray *dockButtons = [self.dockController setLeftItems:[NSArray arrayWithObjects:dockItemSEB, nil]];
            [self setUpDockLeftButtons:dockButtons];
        }
        
        // Initialize center dock items (allowed third party applications)
        if (_isAACEnabled || _allowSwitchToApplications) {
            NSMutableArray *centerDockItems = [NSMutableArray array];
            NSArray *permittedProcesses = [ProcessManager sharedProcessManager].permittedProcesses;
            DDLogDebug(@"%@%@ enabled: Check if there are permitted apps: %@", _isAACEnabled ? @"AAC" : @"", _allowSwitchToApplications ? @"Switching to applications" : @"", permittedProcesses);
            for (NSDictionary *permittedProcess in permittedProcesses) {
                if ([permittedProcess[@"iconInTaskbar"] boolValue] == YES) {
                    NSString *appName = permittedProcess[@"title"];
                    NSString *appBundleID = permittedProcess[@"identifier"];
                    if (appName.length == 0) {
                        appName = permittedProcess[@"executable"];
                    }
                    if (appName.length == 0) {
                        appName = appBundleID;
                    }
                    BOOL allowManualStart = [permittedProcess[@"allowManualStart"] boolValue];
                    NSImage *appIcon = [[NSWorkspace sharedWorkspace] iconForFile:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:appBundleID]];

                    SEBDockItem *dockItemApp = [[SEBDockItem alloc] initWithTitle:appName
                                                                         bundleID:appBundleID
                                                                 allowManualStart:allowManualStart
                                                                             icon:appIcon
                                                                  highlightedIcon:appIcon
                                                                          toolTip:nil
                                                                             menu:nil
                                                                           target:self
                                                                           action:@selector(appButtonPressed:)
                                                                  secondaryAction:nil];
                    [centerDockItems addObject:dockItemApp];
                }
            }
            if (centerDockItems.count > 0) {
                [self.dockController setCenterItems:centerDockItems.copy];
            }
        }
        
        // Initialize right dock items (controlls and info widgets)
        NSMutableArray *rightDockItems = [NSMutableArray array];
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowQuit"] &&
            [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showQuitButton"]) {
            SEBDockItem *dockItemShutDown = [[SEBDockItem alloc] initWithTitle:nil
                                                                      bundleID:nil
                                                              allowManualStart:NO
                                                                          icon:[NSImage imageNamed:@"SEBShutDownIcon"]
                                                               highlightedIcon:[NSImage imageNamed:@"SEBShutDownIconHighlighted"]
                                                                       toolTip:[NSString stringWithFormat:NSLocalizedString(@"Quit %@",nil), SEBShortAppName]
                                                                          menu:nil
                                                                        target:self
                                                                        action:@selector(quitButtonPressed)
                                                               secondaryAction:nil];
            [rightDockItems addObject:dockItemShutDown];
        }
        
        if (_isAACEnabled || ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_showMenuBar"]) {
            SEBDockItemBattery *dockItemBattery = sebDockItemBattery;
            
            if ([dockItemBattery batteryLevel] != -1.0) {
                [dockItemBattery setToolTip:NSLocalizedString(@"Battery Status",nil)];
                [dockItemBattery startDisplayingBattery];
                [rightDockItems addObject:dockItemBattery];
                [self startBatteryMonitoringWithDelegate:dockItemBattery];
            }
        }

        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableScreenProctoring"]) {
            ScreenProctoringIconInactiveState = [NSImage imageNamed:@"SEBScreenProctoringIcon_inactive"];
            if (@available(macOS 10.14, *)) {
                ScreenProctoringIconActiveState = [NSImage imageNamed:@"SEBScreenProctoringIcon_active"];
                ScreenProctoringIconActiveWarningState = [NSImage imageNamed:@"SEBScreenProctoringIcon_active_warning"];
                ScreenProctoringIconActiveErrorState = [NSImage imageNamed:@"SEBScreenProctoringIcon_active_error"];
                ScreenProctoringIconInactiveErrorState = [NSImage imageNamed:@"SEBScreenProctoringIcon_inactive_error"];
            } else {
                ScreenProctoringIconActiveState = [NSImage imageNamed:@"SEBScreenProctoringIcon_active_green"];
                ScreenProctoringIconActiveWarningState = [NSImage imageNamed:@"SEBScreenProctoringIcon_active_warning_orange"];
                ScreenProctoringIconActiveErrorState = [NSImage imageNamed:@"SEBScreenProctoringIcon_active_error_red"];
                ScreenProctoringIconInactiveErrorState = [NSImage imageNamed:@"SEBScreenProctoringIcon_inactive_error_red"];

            }
            ScreenProctoringIconColorActiveState = [NSColor systemGreenColor];
            ScreenProctoringIconColorWarningState = [NSColor systemOrangeColor];
            ScreenProctoringIconColorErrorState = [NSColor systemRedColor];

            SEBDockItem *dockItemProctoringView = [[SEBDockItem alloc] initWithTitle:nil
                                                                            bundleID:nil
                                                                    allowManualStart:NO
                                                                          icon:ScreenProctoringIconInactiveState
                                                               highlightedIcon:ScreenProctoringIconInactiveState
                                                                       toolTip:NSLocalizedString(@"Screen Proctoring Inactive",nil)
                                                                          menu:nil
                                                                        target:self
                                                                        action:@selector(screenProctoringButtonAction)
                                                                     secondaryAction:nil];
            [rightDockItems addObject:dockItemProctoringView];
        }
        
        if (ZoomProctoringSupported && [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomEnable"]) {
            ProctoringIconDefaultState = [NSImage imageNamed:@"SEBProctoringViewIcon"];
//            ProctoringIconDefaultState.template = YES;
            ProctoringIconAIInactiveState = [NSImage imageNamed:@"SEBProctoringViewIcon_green"];
            ProctoringIconNormalState = [NSImage imageNamed:@"SEBProctoringViewIcon_checkmark"];
            ProctoringIconColorNormalState = [NSColor systemGreenColor];
//            ProctoringBadgeNormalState = [[CIImage alloc] initWithCGImage:[UIImage imageNamed:@"SEBBadgeCheckmark"].CGImage];
            ProctoringIconWarningState = [NSImage imageNamed:@"SEBProctoringViewIcon_warning"];
            ProctoringIconColorWarningState = [NSColor systemOrangeColor];
//            ProctoringBadgeWarningState = [[CIImage alloc] initWithCGImage:[UIImage imageNamed:@"SEBBadgeWarning"].CGImage];
            ProctoringIconErrorState = [NSImage imageNamed:@"SEBProctoringViewIcon_error"];
            ProctoringIconColorErrorState = [NSColor systemRedColor];
//            ProctoringBadgeErrorState = [[CIImage alloc] initWithCGImage:[UIImage imageNamed:@"SEBBadgeError"].CGImage];

            NSUInteger remoteProctoringViewShowPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_remoteProctoringViewShow"];
            BOOL allowToggleProctoringView = (remoteProctoringViewShowPolicy == remoteProctoringViewShowAllowToHide ||
                                              remoteProctoringViewShowPolicy == remoteProctoringViewShowAllowToShow);

            SEBDockItem *dockItemProctoringView = [[SEBDockItem alloc] initWithTitle:nil
                                                                            bundleID:nil
                                                                    allowManualStart:NO
                                                                          icon:[NSImage imageNamed:@"SEBProctoringViewIcon"]
                                                               highlightedIcon:[NSImage imageNamed:@"SEBProctoringViewIcon"]
                                                                       toolTip:allowToggleProctoringView ?
                                                   NSLocalizedString(@"Toggle Proctoring View",nil) :
                                                   NSLocalizedString(@"Remote Proctoring",nil)
                                                                          menu:nil
                                                                        target:self
                                                                        action:@selector(toggleProctoringViewVisibility)
                                                                     secondaryAction:nil];
            [rightDockItems addObject:dockItemProctoringView];
        }
        
        if (([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebMode"] == sebModeSebServer ||
            _establishingSEBServerConnection || _sebServerConnectionEstablished) &&
            [preferences secureBoolForKey:@"org_safeexambrowser_SEB_raiseHandButtonShow"]) {
            RaisedHandIconDefaultState = [NSImage imageNamed:@"SEBRaiseHandIcon"];
            RaisedHandIconColorDefaultState = nil;
//            RaisedHandIconDefaultState.template = YES;
            if (@available(macOS 10.14, *)) {
                RaisedHandIconRaisedState = [NSImage imageNamed:@"SEBRaiseHandIcon_raised"];
                RaisedHandIconRaisedState.template = YES;
                RaisedHandIconColorRaisedState = [NSColor systemYellowColor];
            } else {
                RaisedHandIconRaisedState = [NSImage imageNamed:@"SEBRaiseHandIcon_raised_yellow"];
            }
            SEBDockItem *dockItemRaiseHand = [[SEBDockItem alloc] initWithTitle:nil
                                                                       bundleID:nil
                                                               allowManualStart:NO
                                                                          icon:[NSImage imageNamed:@"SEBRaiseHandIcon"]
                                                               highlightedIcon:[NSImage imageNamed:@"SEBRaiseHandIcon"]
                                                                       toolTip:NSLocalizedString(@"Raise Hand",nil)
                                                                          menu:nil
                                                                        target:self
                                                                         action:@selector(toggleRaiseHand)
                                                                secondaryAction:@selector(showEnterRaiseHandMessageWindow)];
            [rightDockItems addObject:dockItemRaiseHand];
        }
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableSebBrowser"] &&
            [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showBackToStartButton"] &&
            ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamUseStartURL"] ||
            [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamURL"].length > 0)) {
            NSString *restartButtonToolTip = [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamText"];
            if (restartButtonToolTip.length == 0) {
                restartButtonToolTip = NSLocalizedString(@"Back to Start",nil);
            }
            SEBDockItem *dockItemSkipBack = [[SEBDockItem alloc] initWithTitle:nil
                                                                      bundleID:nil
                                                              allowManualStart:NO
                                                                          icon:[NSImage imageNamed:@"SEBSkipBackIcon"]
                                                               highlightedIcon:[NSImage imageNamed:@"SEBSkipBackIconHighlighted"]
                                                                       toolTip:restartButtonToolTip
                                                                          menu:nil
                                                                        target:self
                                                                        action:@selector(restartButtonPressed)
                                                               secondaryAction:nil];
            [rightDockItems addObject:dockItemSkipBack];
        }
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableSebBrowser"] &&
            ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserWindowAllowReload"] ||
             [preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowAllowReload"]) &&
            [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showReloadButton"]) {
            SEBDockItem *dockItemReload = [[SEBDockItem alloc] initWithTitle:nil
                                                                    bundleID:nil
                                                            allowManualStart:NO
                                                                          icon:[NSImage imageNamed:@"SEBReloadIcon"]
                                                               highlightedIcon:[NSImage imageNamed:@"SEBReloadIconHighlighted"]
                                                                       toolTip:NSLocalizedString(@"Reload Current Page",nil)
                                                                          menu:nil
                                                                        target:self
                                                                        action:@selector(reloadButtonPressed)
                                                             secondaryAction:nil];
            [rightDockItems addObject:dockItemReload];
        }
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTime"]) {
            SEBDockItemTime *dockItemTime = sebDockItemTime;
            [dockItemTime startDisplayingTime];
            
            [rightDockItems addObject:dockItemTime];
        }
        
        // Set right dock items
        NSArray *dockButtons = [self.dockController setRightItems:rightDockItems];
        [self setUpDockRightButtons:dockButtons];
        
        // Display the dock
        [self.dockController showDockOnScreen:_mainScreen];

    } else {
        DDLogDebug(@"SEBController openSEBDock: dock disabled");
    }
}


- (void)setUpDockLeftButtons: (NSArray *)dockButtons
{
    for (SEBDockItemButton *dockButton in dockButtons) {
        if (dockButton.action == @selector(sebButtonPressed)) {
            dockButton.accessibilityTitle = [NSString stringWithFormat:NSLocalizedString(@"Activates %@ browser. Right click displays menu with open webpages.", @""), SEBShortAppName];
        }
    }
}


- (void)setUpDockRightButtons: (NSArray *)dockButtons
{
    for (SEBDockItemButton *dockButton in dockButtons) {
        if (dockButton.action == @selector(reloadButtonPressed)) {
            _dockButtonReload = dockButton;
        }
        else if (dockButton.action == @selector(screenProctoringButtonAction)) {
            _dockButtonScreenProctoring = dockButton;
            _dockButtonScreenProctoring.image.template = YES;
            _dockButtonScreenProctoring.bezelStyle = NSBezelStyleInline;
            _dockButtonScreenProctoring.bordered = NO;
        }
        else if (dockButton.action == @selector(toggleProctoringViewVisibility)) {
            _dockButtonProctoringView = dockButton;
            _dockButtonProctoringView.image.template = YES;
            _dockButtonProctoringView.bezelStyle = NSBezelStyleInline;
            _dockButtonProctoringView.bordered = NO;
        }
        else if (dockButton.action == @selector(toggleRaiseHand)) {
            _dockButtonRaiseHand = dockButton;
            _dockButtonRaiseHand.image.template = YES;
            _dockButtonRaiseHand.bezelStyle = NSBezelStyleInline;
            _dockButtonRaiseHand.bordered = NO;
        }
    }
}


- (void) sebButtonPressed
{
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [self.browserController.mainBrowserWindow makeKeyAndOrderFront:self];
    
    if (NSApp.mainWindow) {
        NSDictionary *userInfo = @{
            NSAccessibilityUIElementsKey: @[NSApp.mainWindow],
            NSAccessibilityFocusedWindowAttribute: NSApp.mainWindow
        };
        NSAccessibilityPostNotificationWithUserInfo(NSApp.mainWindow, NSAccessibilityFocusedUIElementChangedNotification, userInfo);
    }
}


- (void) appButtonPressed:(id)sender
{
    SEBDockItemButton *appButton = (SEBDockItemButton *)sender;
    NSString *bundleID = appButton.bundleID;
    DDLogInfo(@"Dock button pressed for app: %@", bundleID);
    NSURL *appURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:bundleID];
    NSArray<NSRunningApplication *> *applicationInstances = [NSRunningApplication runningApplicationsWithBundleIdentifier: bundleID];
    if (applicationInstances.count == 1) {
        DDLogInfo(@"Application with Bundle ID %@ (%@) was already running", bundleID, applicationInstances[0]);
        BOOL activationSuccess = [applicationInstances[0] activateWithOptions:NSApplicationActivateAllWindows];
        DDLogInfo(@"Activating application %@ was %@successful", applicationInstances[0], activationSuccess ? @"" : @"not ");
    } else {
        if (appButton.allowManualStart == YES) {
            if (@available(macOS 10.15, *)) {
                NSWorkspaceOpenConfiguration *openConfiguration = [NSWorkspaceOpenConfiguration new];
                openConfiguration.activates = YES;
                openConfiguration.addsToRecentItems = NO;
                openConfiguration.allowsRunningApplicationSubstitution = NO;
                [[NSWorkspace sharedWorkspace] openApplicationAtURL:appURL configuration:openConfiguration completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
                    if (error) {
                        DDLogError(@"Application with Bundle ID %@ at %@ couldn't be opened with error %@", bundleID, appURL, error);
                    } else {
                        DDLogInfo(@"Application with Bundle ID %@ at %@ was opened successfully.", bundleID, appURL);
                    }
                }];
            }
        } else {
            // Manual start not allowed, show alert (TODO)
            DDLogInfo(@"Manually starting application with Bundle ID %@ at %@ is not allowed in current settings.", bundleID, appURL);
        }
    }
}


- (void) restartButtonPressed
{
    // Get custom (if it was set) or standard restart exam text
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *restartExamText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamText"];
    if (restartExamText.length == 0) {
        restartExamText = NSLocalizedString(@"Back to Start",nil);
    }
    
    // Check if restarting is protected with the quit/unlock password (and one is set)
    NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamPasswordProtected"] && ![hashedQuitPassword isEqualToString:@""])
    {
        // if quit/unlock password is set, then restrict quitting
        NSMutableParagraphStyle *textParagraph = [[NSMutableParagraphStyle alloc] init];
        textParagraph.lineSpacing = 5.0;
        NSMutableAttributedString *dialogText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Enter quit/unlock password:",nil)] attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:NSFont.systemFontSize], NSParagraphStyleAttributeName:textParagraph}].mutableCopy;
        
        NSAttributedString *information = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"(This function doesn't log you out if you are logged in on a website)", @"") attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:NSFont.smallSystemFontSize]}];
        [dialogText appendAttributedString:information];
        
        if ([self showEnterPasswordDialogAttributedText:dialogText.copy
                                         modalForWindow:self.browserController.mainBrowserWindow
                                            pseudoModal:NO
                                            windowTitle:restartExamText] == SEBEnterPasswordCancel) {
            return;
        }
        NSString *password = [self.enterPassword stringValue];
        
        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
        if (hashedQuitPassword && [hashedQuitPassword caseInsensitiveCompare:[keychainManager generateSHAHashString:password]] == NSOrderedSame) {
            // if the correct quit/unlock password was entered, restart the exam
            [self.browserController backToStartCommand];
        } else {
            // Wrong quit password was entered
            NSAlert *modalAlert = [self newAlert];
            [modalAlert setMessageText:restartExamText];
            [modalAlert setInformativeText:NSLocalizedString(@"Wrong quit/unlock password.", @"")];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
            [modalAlert setAlertStyle:NSAlertStyleCritical];
            void (^backToStartButtonOK)(NSModalResponse) = ^void (NSModalResponse answer) {
                [self removeAlertWindow:modalAlert.window];
            };
            [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))backToStartButtonOK];
        };
    } else {
        // If no quit password is required, then confirm quitting
        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:restartExamText];
        [modalAlert setInformativeText:[NSString stringWithFormat:@"%@\n\n%@",
                                        NSLocalizedString(@"Are you sure?", @""),
                                        NSLocalizedString(@"(This function doesn't log you out if you are logged in on a website)", @"")
                                        ]];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [modalAlert setAlertStyle:NSAlertStyleWarning];
        void (^backToStartConfirmed)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self removeAlertWindow:modalAlert.window];
            switch(answer)
            {
                case NSAlertFirstButtonReturn:
                    return; //Cancel: don't restart exam
                default:
                    DDLogError(@"Alert was dismissed by the system with NSModalResponse %ld. Not invoking Back to Start.", (long)answer);
                case NSAlertSecondButtonReturn:
                {
                    [self.browserController backToStartCommand];
                }
            }
        };
        [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))backToStartConfirmed];
    }
}


- (void) reloadButtonPressed
{
    [self.browserController reloadCommand];
}


- (void) setReloadButtonEnabled:(BOOL)enabled
{
    _reloadPageUIElement.enabled = enabled;
}


- (void) batteryButtonPressed
{
    
}


- (void) quitButtonPressed
{
    // Post a notification that SEB should conditionally quit
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestQuitNotification" object:self];
}


- (IBAction) searchText:(id)sender
{
    [self.browserController.activeBrowserWindow searchText];
}

- (IBAction) searchTextNext:(id)sender
{
    [self.browserController.activeBrowserWindow searchTextNext];
}

- (IBAction) searchTextPrevious:(id)sender
{
    [self.browserController.activeBrowserWindow searchTextPrevious];
}


- (void) openURLs:(NSArray<NSURL *> *)urls withAppAtURL:(NSURL *)appURL bundleID:(NSString *)bundleID
{
    if (@available(macOS 10.15, *)) {
        if (!appURL) {
            appURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:bundleID];
        }
        if (appURL) {
            NSWorkspaceOpenConfiguration *openConfiguration = [NSWorkspaceOpenConfiguration new];
            openConfiguration.activates = YES;
            openConfiguration.addsToRecentItems = NO;
            openConfiguration.allowsRunningApplicationSubstitution = NO;
            if (urls.count > 0) {
                [[NSWorkspace sharedWorkspace] openURLs:urls withApplicationAtURL:appURL configuration:openConfiguration completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
                    if (error) {
                        DDLogError(@"URLs %@ couldn't be opened with application Bundle ID %@ at %@! Error: %@", urls, bundleID, appURL, error);
                    } else {
                        DDLogInfo(@"URLs %@ were opened successfully with application Bundle ID %@ at %@.", urls, bundleID, appURL);
                    }
                }];
            } else {
                [[NSWorkspace sharedWorkspace] openApplicationAtURL:appURL configuration:openConfiguration completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
                    if (error) {
                        DDLogError(@"Application with Bundle ID %@ at %@ couldn't be opened with error %@", bundleID, appURL, error);
                    } else {
                        DDLogInfo(@"Application with Bundle ID %@ at %@ was opened successfully.", bundleID, appURL);
                    }
                }];
            }
        }
    }
}


- (NSModalResponse) showEnterPasswordDialog:(NSString *)text 
                             modalForWindow:(NSWindow *_Nullable)window
                                pseudoModal:(BOOL)pseudoModal
                                windowTitle:(NSString *)title
{
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:NSFont.systemFontSize]}];
    return [self showEnterPasswordDialogAttributedText:attributedText modalForWindow:window pseudoModal:pseudoModal windowTitle:title];
}
    
    
- (NSModalResponse) showEnterPasswordDialogAttributedText:(NSAttributedString *)text 
                                           modalForWindow:(NSWindow *)window
                                              pseudoModal:(BOOL)pseudoModal
                                              windowTitle:(NSString *)title
{
    [self.enterPassword setStringValue:@""]; //reset the enterPassword NSSecureTextField

    // If the (main) browser window is full screen, we don't show the dialog as sheet
    if (window == self.browserController.mainBrowserWindow && self.browserController.mainBrowserWindow.isFullScreen) {
        DDLogDebug(@"%s Not showing the dialog on a full screen browser window", __FUNCTION__);
        window = nil;
    }
    
    if (@available(macOS 12.0, *)) {
    } else {
        if (@available(macOS 11.0, *)) {
            if (!window && (_isAACEnabled || _wasAACEnabled)) {
                window = self.browserController.mainBrowserWindow;
            }
        }
    }

    // If the dialog needs to be shown application modal
    if (!window) {
        // block opening other modal alerts while the password dialog is open
        [_modalAlertWindows addObject:enterPasswordDialogWindow];
    }
    
    // Add the alert title string to the dialog text if the alert will be presented as sheet on a window
    if (window && title.length > 0) {
        NSMutableParagraphStyle *textParagraph = [[NSMutableParagraphStyle alloc] init];
        textParagraph.lineSpacing = 5.0;
        NSMutableAttributedString *dialogText = [[NSAttributedString alloc] initWithString:
                                                 [NSString stringWithFormat:@"%@\n", title]
                                                                                attributes:@{NSFontAttributeName:[NSFont boldSystemFontOfSize:NSFont.systemFontSize], NSParagraphStyleAttributeName:textParagraph}].mutableCopy;
        
        [dialogText appendAttributedString:text];
        text = dialogText.copy;
    } else if (title) {
        enterPasswordDialogWindow.title = title;
    }
    [enterPasswordDialog setAttributedStringValue:text];
    
    NSInteger returnCode = NSModalResponseCancel;
    if (!pseudoModal) {
        _pseudoModalWindow = NO;
        NSWindow *windowToShowModalFor;
        if (@available(macOS 12.0, *)) {
        } else {
            if (@available(macOS 11.0, *)) {
                windowToShowModalFor = window;
            }
        }
        [NSApp beginSheet: enterPasswordDialogWindow
           modalForWindow: windowToShowModalFor
            modalDelegate: nil
           didEndSelector: nil
              contextInfo: nil];
        returnCode = [NSApp runModalForWindow: enterPasswordDialogWindow];
        // Dialog is up here.
        [NSApp endSheet: enterPasswordDialogWindow];
        [enterPasswordDialogWindow orderOut: self];
        [self removeAlertWindow:enterPasswordDialogWindow];
    } else {
        _pseudoModalWindow = YES;
        [enterPasswordDialogWindow setLevel:NSScreenSaverWindowLevel+2];
        NSWindowController *windowController = [[NSWindowController alloc] initWithWindow:enterPasswordDialogWindow];
        [windowController showWindow:nil];
        returnCode = SEBEnterPasswordCancel;
    }
    return returnCode;
}

- (void) showEnterPasswordDialogClose
{
    NSString *password = [self.enterPassword stringValue];
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    if (hashedQuitPassword && [hashedQuitPassword caseInsensitiveCompare:[keychainManager generateSHAHashString:password]] == NSOrderedSame) {
        // if the correct quit password was entered
        DDLogInfo(@"Correct quit password entered");
        [self exitSEB]; // Force quit SEB
    }
}


- (IBAction) okEnterPassword: (id)sender {
    if (!self.pseudoModalWindow) {
        [NSApp stopModalWithCode:SEBEnterPasswordOK];
    } else {
        [self showEnterPasswordDialogClose];
    }
}


- (IBAction) cancelEnterPassword: (id)sender {
    [NSApp stopModalWithCode:SEBEnterPasswordCancel];
    [enterPasswordDialogWindow orderOut: self];
    [self.enterPassword setStringValue:@""];
}


- (void) showEnterUsernamePasswordDialog:(NSString *)text
                          modalForWindow:(NSWindow *)window
                             windowTitle:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector
{
    // Remember the delegate and selector of the sender
    senderModalDelegate = modalDelegate;
    senderDidEndSelector = didEndSelector;
    
    // Preset (or clear) the username field
    [usernameTextField setStringValue:username];
    // Reset the password field
    [passwordSecureTextField setStringValue:@""];
    
    // If there isn't a preset username (from a previous, failed attempt), move cursor
    // to the username field, otherwise to the password field
    if (username.length == 0) {
        [enterUsernamePasswordDialogWindow makeFirstResponder:usernameTextField];
    } else {
        [enterUsernamePasswordDialogWindow makeFirstResponder:passwordSecureTextField];
    }
    if (title) enterUsernamePasswordDialogWindow.title = title;
    [enterUsernamePasswordText setStringValue:text];
    
    // If the (main) browser window is full screen, we don't show the dialog as sheet
    if (window && (self.browserController.mainBrowserWindow.isFullScreen || [self.preferencesController preferencesAreOpen])) {
        window = nil;
    }
    
    // If the dialog needs to be shown application modal
    if (!window) {
        // Add password dialog to open modal alerts
        [_modalAlertWindows addObject:enterPasswordDialogWindow];
    }
    
    if (@available(macOS 12.0, *)) {
    } else {
        if (@available(macOS 11.0, *)) {
            if (!window && (_isAACEnabled || _wasAACEnabled)) {
                window = self.browserController.mainBrowserWindow;
            }
        }
    }

    [NSApp beginSheet: enterUsernamePasswordDialogWindow
       modalForWindow: window
        modalDelegate: self
       didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
}


- (IBAction) okEnterUsernamePassword: (id)sender {
    [NSApp endSheet:enterUsernamePasswordDialogWindow returnCode:SEBEnterPasswordOK];
    [self removeAlertWindow:enterPasswordDialogWindow];
}


- (IBAction) cancelEnterUsernamePassword: (id)sender {
    [NSApp endSheet:enterUsernamePasswordDialogWindow returnCode:SEBEnterPasswordCancel];
    // Reset the username field (password is always reset whenever the dialog is displayed)
    [usernameTextField setStringValue:@""];
    [self removeAlertWindow:enterPasswordDialogWindow];
}


- (void) hideEnterUsernamePasswordDialog
{
    [NSApp endSheet:enterUsernamePasswordDialogWindow returnCode:SEBEnterPasswordAborted];
    // Reset the user name field (password is always reset whenever the dialog is displayed)
    [usernameTextField setStringValue:@""];
    [self removeAlertWindow:enterPasswordDialogWindow];
}


- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    DDLogDebug(@"sheetDidEnd with return code: %ld", (long)returnCode);
    
    [sheet orderOut: self];
    [self removeAlertWindow:enterPasswordDialogWindow];

    IMP imp = [senderModalDelegate methodForSelector:senderDidEndSelector];
    void (*func)(id, SEL, NSString*, NSString*, NSInteger) = (void *)imp;
    func(senderModalDelegate, senderDidEndSelector, usernameTextField.stringValue, passwordSecureTextField.stringValue, returnCode);
}


#pragma mark - Open/Close Preferences

- (IBAction) openPreferences:(id)sender {
    if (!(_screenProctoringController && _screenProctoringController.sessionIsClosing)) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        if (lockdownWindows.count == 0 && [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"]) {
            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
            if (![self.preferencesController preferencesAreOpen]) {
                // Load admin password from the system's user defaults database
                NSString *hashedAdminPW = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
                if (![hashedAdminPW isEqualToString:@""]) {
                    // If admin password is set, then restrict access to the preferences window
                    if ([self showEnterPasswordDialog:NSLocalizedString(@"Enter administrator password:",nil) modalForWindow:self.browserController.mainBrowserWindow pseudoModal:NO windowTitle:@""] == SEBEnterPasswordCancel) {
                        return;
                    }
                    NSString *password = [self.enterPassword stringValue];
                    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
                    if ([hashedAdminPW caseInsensitiveCompare:[keychainManager generateSHAHashString:password]] != NSOrderedSame) {
                        //if hash of entered password is not equal to the one in preferences
                        // Wrong admin password was entered
                        NSAlert *modalAlert = [self newAlert];
                        [modalAlert setMessageText:NSLocalizedString(@"Wrong Admin Password", @"")];
                        [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"If you don't enter the correct %@ administrator password, then you cannot open preferences.", @""), SEBShortAppName]];
                        [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
                        [modalAlert setAlertStyle:NSAlertStyleWarning];
                        void (^wrongPasswordEnteredOK)(NSModalResponse) = ^void (NSModalResponse answer) {
                            [self removeAlertWindow:modalAlert.window];
                        };
                        [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))wrongPasswordEnteredOK];
                        return;
                    }
                }
                if (_isAACEnabled == NO) {
                    // Switch the kiosk mode temporary off and override settings for menu bar: Show it while prefs are open
                    [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
                    [self switchKioskModeAppsAllowed:YES overrideShowMenuBar:YES];
                    // Close the black background covering windows
                    [self closeCapWindows];
                    // Show the Config menu (in menu bar)
                    [configMenu setHidden:NO];
                }
                
                // Check if the running prohibited processes window is open and close it if yes
                if (_processListViewController) {
                    [self closeProcessListWindow];
                }
                
                // Show preferences window
                [self.preferencesController openPreferencesWindow];
                
            } else {
                // Show preferences window
                DDLogDebug(@"openPreferences: Preferences already open, just show Window");
                // Release preferences window so buttons get enabled properly for the local client settings mode
                [self.preferencesController releasePreferencesWindow];
                // Re-initialize and open preferences window
                [self.preferencesController initPreferencesWindow];
                [self.preferencesController reopenPreferencesWindow];
                [self.preferencesController showPreferencesWindow:nil];
            }
        }
    }
}


- (void)closePreferencesWindow
{
    // Release preferences window so buttons get enabled properly for the local client settings mode
    [self.preferencesController releasePreferencesWindow];
    [self.preferencesController initPreferencesWindow];
}


- (void)preferencesClosed:(NSNotification *)notification
{
    DDLogInfo(@"Preferences window closed, no reconfiguration necessary");
    [configMenu setHidden:YES];

    [self updateAACAvailablility];
    if (_startingUp) {
        [self preferencesOpenedWhileStartingUpNowClosing];
    } else {
        [self performAfterPreferencesClosedActions];
        
        // Update URL filter flags and rules
        [[SEBURLFilter sharedSEBURLFilter] updateFilterRulesWithStartURL:self.startURL];
        // Update URL filter ignore rules
        [[SEBURLFilter sharedSEBURLFilter] updateIgnoreRuleList];
        
        // Reinforce kiosk mode after a delay, so eventually visible fullscreen apps get hidden again
        [self performSelector:@selector(reinforceKioskMode) withObject: nil afterDelay: 1];
    }
}


- (void)preferencesClosedRestartSEB:(NSNotification *)notification
{
    [configMenu setHidden:YES];
    
    [self updateAACAvailablility];
    if (_startingUp) {
        [self preferencesOpenedWhileStartingUpNowClosing];
    } else {
        DDLogInfo(@"Preferences window closed, reconfiguring to new settings");

        [self performAfterPreferencesClosedActions];
        
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestRestartNotification" object:self];

        // Reinforce kiosk mode after a delay, so eventually visible fullscreen apps get hidden again
        [self performSelector:@selector(reinforceKioskMode) withObject: nil afterDelay: 1];
    }
}


- (void)preferencesOpenedWhileStartingUpNowClosing
{
    if (!quittingMyself) {
        DDLogInfo(@"Preferences window was opened while starting up SEB, continue now to start up.");
        // We need to reset this flag, as settings to be opened are already active
        _openingSettings = NO;
        [self didFinishLaunchingWithSettings];
    } else {
        DDLogInfo(@"Preferences window was opened while starting up SEB, and quit was selected while the Preferences window was still open.");
    }
}


- (void)performAfterPreferencesClosedActions
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
    
    if (_isAACEnabled == NO) {
        // Open new covering background windows on all currently available screens
        DDLogInfo(@"Preferences window closed, reopening cap windows.");
        [self coverScreens];
    }
    
    // Change window level of all open browser windows to normal levels
    // this helps to get rid of full screen apps on separate spaces (on other displays)
    [self.browserController browserWindowsChangeLevelAllowApps:YES];
    
    if (_isAACEnabled == NO) {
        // Switch the kiosk mode on again
        [self setElevateWindowLevels];
        
        BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
        [self switchKioskModeAppsAllowed:allowSwitchToThirdPartyApps overrideShowMenuBar:NO];
    }
}


- (void) requestedShowAbout:(NSNotification *)notification
{
    [self showAbout:self];
}

- (IBAction)showAbout:(id)sender
{
    if (_alternateKeyPressed == NO) {
        [self.aboutWindow setStyleMask:NSWindowStyleMaskBorderless];
        [self.aboutWindow center];
        //[self.aboutWindow orderFront:self];
        //[self.aboutWindow setLevel:NSMainMenuWindowLevel];
        [NSApp runModalForWindow:self.aboutWindow];
    }
}


- (void) requestedShowHelp:(NSNotification *)notification
{
    [self showHelp:self];
}


// Load manual page URL in new browser window
- (IBAction) showHelp: (id)sender
{
    NSString *urlString = SEBHelpPage;
    // Open new browser window containing WebView and show it
    [self.browserController openAndShowWebViewWithURL:[NSURL URLWithString:urlString] configuration:nil];
}


- (void) closeDocument:(id)document
{
    [document close];
}


- (IBAction)shareConfigFormatSelected:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setSecureInteger:_shareConfigFormatPopUpButton.indexOfSelectedItem forKey:@"org_safeexambrowser_shareConfigFormat"];
    _shareConfigUncompressedButton.hidden = !_preferencesController.canSavePlainText;
}

- (IBAction)shareConfigUncompressedSelected:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setSecureBool:_shareConfigUncompressedButton.state forKey:@"org_safeexambrowser_shareConfigUncompressed"];
}


#pragma mark - Quitting/Restarting Sessions and SEB

- (IBAction) requestedQuit:(id)sender
{
    BOOL quittingFromSPSCacheUpload = NO;
    id senderObject;
    if ([sender respondsToSelector:@selector(object)]) {
        senderObject = [sender object];
        Class senderClass = [senderObject class];
        DDLogDebug(@"%s sender.object: %@, object.class: %@", __FUNCTION__, senderObject, senderClass);
        quittingFromSPSCacheUpload = [senderClass isEqualTo:TransmittingCachedScreenShotsViewController.class];
    }
    if (!quittingFromSPSCacheUpload && _screenProctoringController && _screenProctoringController.sessionIsClosing) {
        return;
    }
    // Load quitting preferences from the system's user defaults database
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowQuit"] == YES) {
        NSWindow *currentMainWindow = self.browserController.mainBrowserWindow;
        if ([self.preferencesController preferencesAreOpen] ) {
            currentMainWindow = self.preferencesController.preferencesWindow;
            DDLogDebug(@"Preferences are open, displaying according alerts as sheet on window %@", currentMainWindow);
        }
        // if quitting SEB is allowed
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];

        if (quittingFromSPSCacheUpload) {
            currentMainWindow = nil;
        }
        
        if (![hashedQuitPassword isEqualToString:@""]) {
            DDLogInfo(@"%s Displaying quit password alert", __FUNCTION__);
            // if quit password is set, then restrict quitting
            if ([self showEnterPasswordDialog:NSLocalizedString(@"Enter quit password:", @"") modalForWindow:currentMainWindow pseudoModal:quittingFromSPSCacheUpload windowTitle:@""] == SEBEnterPasswordCancel) return;
            NSString *password = [self.enterPassword stringValue];
            
            SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
            if (hashedQuitPassword && [hashedQuitPassword caseInsensitiveCompare:[keychainManager generateSHAHashString:password]] == NSOrderedSame) {
                // if the correct quit password was entered
                DDLogInfo(@"Correct quit password entered");
                if (!quittingFromSPSCacheUpload) {
                    [self quitSEBOrSession]; // Quit SEB or the exam session
                } else {
                    // Quit from uploading cached screen shots: Don't confirm quitting
                    [self quitFromTransmittingCachedScreenShots];
                }

            } else {
                // Wrong quit password was entered
                DDLogInfo(@"Wrong quit password entered");
                if (!quittingFromSPSCacheUpload) {
                    NSAlert *modalAlert = [self newAlert];
                    [modalAlert setMessageText:NSLocalizedString(@"Wrong Quit Password", @"")];
                    [modalAlert setInformativeText:NSLocalizedString(@"If you don't enter the correct quit password, then you cannot quit.", @"")];
                    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
                    [modalAlert setAlertStyle:NSAlertStyleWarning];
                    void (^wrongPasswordEnteredOK)(NSModalResponse) = ^void (NSModalResponse answer) {
                        [self removeAlertWindow:modalAlert.window];
                    };
                    [self runModalAlert:modalAlert conditionallyForWindow:currentMainWindow completionHandler:(void (^)(NSModalResponse answer))wrongPasswordEnteredOK];
                }
            }
        } else {
            // If no quit password is required, then confirm quitting, with default option "Quit"
            DDLogInfo(@"%s No quit password required, continue", __FUNCTION__);
            if (!quittingFromSPSCacheUpload) {
                [self sessionQuitRestartIgnoringQuitPW:NO];
            } else {
                // Quit from uploading cached screen shots: Don't confirm quitting
                [self quitFromTransmittingCachedScreenShots];
            }
        }
    }
}

// Quit from uploading cached screen shots and don't confirm quitting SEB/Session
- (void) quitFromTransmittingCachedScreenShots
{
    [self closeTransmittingCachedScreenShotsWindow:^{
        [self.screenProctoringController continueClosingSessionWithCompletionHandler:^{
            self->_screenProctoringController = nil;
            [self sessionQuitRestart:NO];
        }];
    }];
}


- (void) quitLinkDetected:(NSNotification *)notification
{
    DDLogInfo(@"Quit Link invoked");
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL restart = NO;
    if (!(self.startingExamFromSEBServer || self.establishingSEBServerConnection || self.sebServerConnectionEstablished)) {
        restart = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_quitURLRestart"];
    }
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_quitURLConfirm"]) {
        [self sessionQuitRestartIgnoringQuitPW:restart];
    } else {
        [self sessionQuitRestart:restart];
    }
}


// Confirm quitting, with default option "Quit"
- (void)sessionQuitRestartIgnoringQuitPW:(BOOL)restart
{
    DDLogDebug(@"%s Displaying confirm quit alert", __FUNCTION__);
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    NSAlert *modalAlert = [self newAlert];
    [modalAlert setMessageText:restart ? NSLocalizedString(@"Restart Session", @"") : (!self.quittingSession ? [NSString stringWithFormat:NSLocalizedString(@"Quit %@", @""), SEBFullAppNameClassic] : NSLocalizedString(@"Quit Session", @""))];
    [modalAlert setInformativeText:restart ? NSLocalizedString(@"Are you sure you want to restart this session?", @"") : (!self.quittingSession ? [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to quit %@?", @""), SEBFullAppNameClassic] : NSLocalizedString(@"Are you sure you want to quit this session?", @""))];
    [modalAlert addButtonWithTitle:restart ? NSLocalizedString(@"Restart", @"") : NSLocalizedString(@"Quit", @"")];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    [modalAlert setAlertStyle:NSAlertStyleWarning];
    void (^quitSEBAnswer)(NSModalResponse) = ^void (NSModalResponse answer) {
        [self removeAlertWindow:modalAlert.window];
        switch(answer)
        {
            case NSAlertFirstButtonReturn:
                if ([self.preferencesController preferencesAreOpen]) {
                    DDLogInfo(@"Confirmed to quit, preferences window is open");
                    [self.preferencesController quitSEB:self];
                } else {
                    DDLogInfo(@"Confirmed to %@ %@", restart ? @"restart" : @"quit", !self.quittingSession ? SEBShortAppName : @"exam session");
                    [self sessionQuitRestart:restart];
                }
                return;
            default:
            {
                DDLogDebug(@"%s canceled quit alert with NSModalResponse %ld.", __FUNCTION__, (long)answer);
                return; //Cancel: don't quit
            }
        }
    };
    [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))quitSEBAnswer];
}


// Quit or restart session without asking for confirmation

- (void) sessionQuitRestart:(BOOL)restart
{
    _openingSettings = NO;

    // In case of AAC Multi App Mode, we have to terminate running permitted applications
    [self terminateApplications:@[] processes:@[] starting:NO restarting:restart callback:nil selector:nil];
}

- (void) sessionQuitRestartContinue:(BOOL)restart
{
    NSArray *permittedProcesses = [ProcessManager sharedProcessManager].permittedProcesses;
    if (permittedProcesses.count > 0) {
        BOOL removedSavedWindowState = [self.assessmentConfigurationManager removeSavedAppWindowStateWithPermittedApplications:permittedProcesses];
        DDLogInfo(@"Removing saved window state for permitted applications before quitting SEB was %@successful.", removedSavedWindowState ? @"" : @"not ");
    }
    // Stop/Reset proctoring
    [self stopProctoringWithCompletion:^{
        DDLogDebug(@"%s Conditionally closed (optional) proctoring", __FUNCTION__);
        [self conditionallyCloseSEBServerConnectionWithRestart:NO completion:^(BOOL restart) {
            self.establishingSEBServerConnection = NO;
            DDLogDebug(@"%s Conditionally closed (optional) SEB Server connection (restart: %d)", __FUNCTION__, restart);
            run_on_ui_thread(^{
                [self didCloseSEBServerConnectionRestart:restart];
            });
        }];
    }];
}


- (void) quitSEBOrSession
{
    DDLogDebug(@"[SEBController quitSEBOrSession]");
    if (self.quittingSession) {
        [NSUserDefaults setUserDefaultsPrivate:NO];
        [self updateAACAvailablility];
        [self requestedRestart:nil];
    } else {
        [self requestedExit:nil];
    }
}


/// Restart SEB
///
- (void)requestedRestart:(NSNotification *_Nullable)notification
{
    DDLogInfo(@"---------- RESTARTING SEB SESSION -------------");
    _restarting = YES;
    _conditionalInitAfterProcessesChecked = NO;
    _openedURL = NO;

    // If this was a secured exam, we remove it from the list of running exams,
    // otherwise it would be locked next time it is started again
    if (currentExamConfigKey) {
        [self.sebLockedViewController removeLockedExam:currentExamStartURL configKey: currentExamConfigKey];
    }
    
    // Check if the running prohibited processes window is open and close it if yes
    if (_processListViewController) {
        [self closeProcessListWindow];
    }

    // Reset SEB Browser
    [self.browserController resetBrowser];
    
    // Clear private pasteboard
    [self.browserController clearPrivatePasteboard];
    
    if (_batteryController && !_establishingSEBServerConnection) {
        [_batteryController stopMonitoringBattery];
        _batteryController = nil;
    }
    
    // Re-Initialize file logger if logging enabled
    [self initializeLogger];
    [self conditionallyInitSEBWithCallback:self selector:@selector(requestedRestartProcessesChecked)];
}


- (void)requestedRestartProcessesChecked
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    // Check for command key being held down
    NSEventModifierFlags modifierFlags = [NSEvent modifierFlags];
    BOOL cmdKeyDown = (0 != (modifierFlags & NSEventModifierFlagCommand));
    if (cmdKeyDown) {
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enableAppSwitcherCheck"]) {
            // Show alert that keys were hold while starting SEB
            DDLogError(@"Command key is pressed while restarting SEB, show dialog asking to release it.");
            NSAlert *modalAlert = [self newAlert];
            [modalAlert setMessageText:NSLocalizedString(@"Holding Command Key Not Allowed!", @"")];
            [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Holding the Command key down while restarting %@ is not allowed, release it to continue.", @""), SEBShortAppName]];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
            [modalAlert setAlertStyle:NSAlertStyleCritical];
            void (^cmdKeyHeldProceed)(NSModalResponse) = ^void (NSModalResponse answer) {
                [self removeAlertWindow:modalAlert.window];
                [self requestedRestartProcessesChecked];
            };
            [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))cmdKeyHeldProceed];
            return;
        } else {
            DDLogWarn(@"Command key is pressed, but not forbidden in current settings");
        }
    }
    [self requestedRestartProcessesCmdKeyChecked];
}


- (void)requestedRestartProcessesCmdKeyChecked
{
    // Adjust screen shot blocking
    [self.systemManager adjustScreenCapture];
    
    [self setElevateWindowLevels];

    // Reopen main browser window and load start URL
    DDLogDebug(@"%s re-openMainBrowserWindow", __FUNCTION__);
    
    // Reset session state here, to prevent overriden lock screens for Siri etc. to appear too early
    self.sessionState = nil;
    
    [self startExamWithFallback:NO];

    // Adjust screen locking
    [self adjustScreenLocking:nil];
    
    // ToDo: Opening of additional resources (but not only here, also when starting SEB)
    //    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    //    NSArray *additionalResources = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_additionalResources"];
    //    for (NSDictionary *resource in additionalResources) {
    //        if ([resource valueForKey:@"active"] == [NSNumber numberWithBool:YES]) {
    //            NSString *resourceURL = [resource valueForKey:@"URL"];
    //            NSString *resourceTitle = [resource valueForKey:@"title"];
    //            if ([resource valueForKey:@"autoOpen"] == [NSNumber numberWithBool:YES]) {
    //                [self openResourceWithURL:resourceURL andTitle:resourceTitle];
    //            }
    //        }
    //    }
    _restarting = NO;
}


- (void) conditionallyCloseSEBServerConnectionWithRestart:(BOOL)restart completion:(void (^)(BOOL))completion
{
    if (self.startingExamFromSEBServer || self.establishingSEBServerConnection || self.sebServerConnectionEstablished) {

        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Disconnecting from SEB Server", @""), SEBShortAppName]];
        [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"If SEB Server doesn't respond for a while, you can forcibly close the connection", @""), SEBShortAppName, SEBShortAppName]];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"Force Close", @"")];
        [modalAlert setAlertStyle:NSAlertStyleCritical];

        void (^forceCloseConnection)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self removeAlertWindow:modalAlert.window];
            DDLogInfo(@"User decided to force close SEB Server connection");
            [self.serverController cancelQuitSessionWithRestart:restart completion:completion];
        };
        
        void (^closeDisconnetingAlertCompletion)(BOOL) = ^void (BOOL restart) {
            DDLogInfo(@"SEB Server connection was closed, closing Disconnecting alert.");
            dispatch_block_cancel(self->cancelableBlock);
            [modalAlert.window orderOut:self];
            [self removeAlertWindow:modalAlert.window];
            completion(restart);
        };

        cancelableBlock = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^{
            [modalAlert beginSheetModalForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))forceCloseConnection];
        });
        
        dispatch_time_t dispachTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC));
        dispatch_after(dispachTime, dispatch_get_main_queue(), cancelableBlock);

        if (self.startingExamFromSEBServer || self.establishingSEBServerConnection) {
            self.establishingSEBServerConnection = NO;
            self.startingExamFromSEBServer = NO;
            [self.serverController loginToExamAbortedWithCompletion:closeDisconnetingAlertCompletion];
        } else if (self.sebServerConnectionEstablished) {
            self.sebServerConnectionEstablished = NO;
            [self.serverController quitSessionWithRestart:restart completion:closeDisconnetingAlertCompletion];
        }
    } else {
        completion(restart);
    }
}


- (BOOL) quittingSession
{
    BOOL secureClientSession = NO;
    if (self.examSession) {
        secureClientSession = self.secureClientSession;
    }
    BOOL quittingSession = !_startingUp && self.examSession && secureClientSession && !_openedURL;
    DDLogInfo(@"%s: %d", __FUNCTION__, quittingSession);
    return quittingSession;
}

- (BOOL) examSession
{
    return NSUserDefaults.userDefaultsPrivate;
}

- (BOOL) secureClientSession
{
    [NSUserDefaults setUserDefaultsPrivate:NO];
    BOOL secureClientSession = [[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length != 0;
    [NSUserDefaults setUserDefaultsPrivate:YES];
    return secureClientSession;
}


/// Exit SEB
///
- (void)requestedExit:(NSNotification *_Nullable)notification
{
    DDLogInfo(@"%s", __FUNCTION__);
    // Stop/Reset proctoring
    [self stopProctoringWithCompletion:^{
        DDLogDebug(@"%s Conditionally closed (optional) proctoring", __FUNCTION__);
        [self conditionallyCloseSEBServerConnectionWithRestart:NO completion:^(BOOL restart) {
            self.establishingSEBServerConnection = NO;
            DDLogDebug(@"%s Conditionally closed (optional) SEB Server connection (restart: %d)", __FUNCTION__, restart);
            [self exitSEB];
        }];
    }];
}

- (void)exitSEB
{
    DDLogInfo(@"%s", __FUNCTION__);
    quittingMyself = YES; //quit SEB without asking for confirmation or password

    if (_browserController) {
        // Empties all cookies, caches and credential stores, removes disk files, flushes in-progress
        // downloads to disk, and ensures that future requests occur on a new socket.
        [self.browserController resetAllCookiesWithCompletionHandler:^{
            DDLogInfo(@"%s All cookies have been reset, continue terminating", __FUNCTION__);
            [NSApp terminate: nil]; //quit (exit) SEB
        }];
    } else {
        DDLogInfo(@"%s Continue terminating", __FUNCTION__);
        [NSApp terminate: nil]; //quit (exit) SEB
    }
}


#pragma mark - Action and Application Delegates for Quitting SEB

// Called when SEB should be terminated
- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	if (quittingMyself || systemPreferencesOpenedForScreenRecordingPermissions) {
        DDLogDebug(@"%s: quttingMyself = true", __FUNCTION__);
        if (_isAACEnabled && _wasAACEnabled && !_isTerminating) {
            // Don't try to switch AAC off if it didn't switch on yet
            if (@available(macOS 10.15.4, *)) {
                _isTerminating = YES; //prevent trying to switch AAC off twice

                if (self.browserController) {
                    [self.browserController closeAllBrowserWindows];
                }

                [self.assessmentModeManager endAssessmentModeWithCallback:self selector:@selector(terminateSEB) quittingToAssessmentMode:NO];
                return NSTerminateCancel;
            }
        }
		return NSTerminateNow; //SEB wants to quit, ok, so it should happen
	} else { //SEB should be terminated externally(!)
		return NSTerminateCancel; //this we can't allow, sorry...
	}
}


- (void) terminateSEB
{
    DDLogInfo(@"Terminating SEB after ending Assessment Mode");
    [self exitSEB];
}


// Called just before SEB will be terminated
- (void) applicationWillTerminate:(NSNotification *)aNotification
{
    DDLogDebug(@"%s", __FUNCTION__);

    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];

    if (self.browserController) {
        [self.browserController closeAllBrowserWindows];
    }
    BOOL success = [self.sebFileManager removeTempDownUploadDirectory];
    DDLogInfo(@"Removing temporary down/upload directory was %@successfull.", success ? @"":@"not ");

    // If this was a secured exam, we remove it from the list of running exams,
    // otherwise it would be locked next time it is started again
    if (currentExamConfigKey) {
        [self.sebLockedViewController removeLockedExam:currentExamStartURL configKey: currentExamConfigKey];
    }
    
    if (enforceMinMacOSVersion) {
        [self applicationWillTerminateProceed];
    } else if (_forceAppFolder) {
        // Show alert that SEB is not placed in Applications folder
        NSString *applicationsDirectoryName = @"Applications";
        NSString *localizedApplicationDirectoryName = [[NSFileManager defaultManager] displayNameAtPath:NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSLocalDomainMask, YES).lastObject];
        NSString *localizedAndInternalApplicationDirectoryName;
        if ([localizedApplicationDirectoryName isEqualToString:applicationsDirectoryName]) {
            // System language is English or the Applications folder is named identically in user's current language
            localizedAndInternalApplicationDirectoryName = applicationsDirectoryName;
        } else {
            NSBundle *preferredLanguageBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:[[NSLocale preferredLanguages] objectAtIndex:0] ofType:@"lproj"]];
            if (preferredLanguageBundle) {
                localizedAndInternalApplicationDirectoryName = [NSString stringWithFormat:@"'%@' ('%@')", localizedApplicationDirectoryName, applicationsDirectoryName];
            } else {
                // User selected language is one which SEB doesn't support
                localizedAndInternalApplicationDirectoryName = [NSString stringWithFormat:@"%@ ('%@')", applicationsDirectoryName, localizedApplicationDirectoryName];
                localizedApplicationDirectoryName = applicationsDirectoryName;
            }
        }
        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"%@ Not in %@ Folder!", @""), SEBShortAppName, localizedApplicationDirectoryName]];
        [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"%@ has to be placed in the %@ folder in order for all features to work correctly. Move the '%@' app to your %@ folder and make sure that you don't have any other versions of %@ installed on your system. %@ will quit now.", @""), SEBShortAppName, localizedApplicationDirectoryName, SEBFullAppNameClassic, localizedAndInternalApplicationDirectoryName, SEBShortAppName, SEBShortAppName]];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [modalAlert setAlertStyle:NSAlertStyleCritical];
        void (^terminateSEBAlertOK)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self removeAlertWindow:modalAlert.window];
            [self applicationWillTerminateProceed];
        };
        [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))terminateSEBAlertOK];
    } else if (screenCapturePermissionsRequested) {
        screenCapturePermissionsRequested = NO;
        if (@available(macOS 10.15, *)) {
            NSString *accessibilityPermissionsTitleString = @"";
            NSString *accessibilityPermissionsMessageString = @"";
            if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enableScreenProctoring"]) {
                // Check if also Accessibility permissions need to be granted
                NSDictionary *options = @{(__bridge id)
                                          kAXTrustedCheckOptionPrompt : @NO};
                if (!AXIsProcessTrustedWithOptions((CFDictionaryRef)options)) {
                    accessibilityPermissionsTitleString = accessibilityTitleString;
                    accessibilityPermissionsMessageString = [NSString stringWithFormat:@"\n\n%@", self.accessibilityMessageString];
                }
            }
            if (CGRequestScreenCaptureAccess()) {
                DDLogInfo(@"Screen capture access has been granted");
            } else {
                DDLogError(@"User has to grant screen capture access, display authorization dialog or open System Settings");
                systemPreferencesOpenedForScreenRecordingPermissions = YES;

                NSAlert *modalAlert = [self newAlert];
                [modalAlert setMessageText:[NSString stringWithFormat:@"%@%@", NSLocalizedString(@"Permissions Required for Screen Capture", @""), accessibilityPermissionsTitleString]];
                [modalAlert setInformativeText:[NSString stringWithFormat:@"%@%@", [NSString stringWithFormat:NSLocalizedString(@"For this exam session, screen capturing is required. You need to authorize Screen Recording for %@ in System Settings / Security & Privacy%@. Then restart %@ and your exam.", @""), SEBFullAppNameClassic, @"", SEBShortAppName], accessibilityPermissionsMessageString]];

                [modalAlert addButtonWithTitle:NSLocalizedString(@"Authorize", @"")];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", @"")];
                [modalAlert setAlertStyle:NSAlertStyleCritical];
                void (^permissionsForProctoringHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                    [self removeAlertWindow:modalAlert.window];
                    switch(answer)
                    {
                        case NSAlertFirstButtonReturn:
                        {
                            DDLogDebug(@"User selected Authorize Screen Recording%@ in System Settings", accessibilityPermissionsTitleString.length == 0 ? @"" : @" and Accessibility");
                            [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:pathToSecurityPrivacyPreferences]];
                            return;
                        }
                        default:
                            DDLogError(@"Alert was dismissed by the system with NSModalResponse %ld. Quitting SEB", (long)answer);
                        case NSAlertSecondButtonReturn:
                        {
                            DDLogDebug(@"No permissions for screen capture: Quitting");
                        }
                    }
                    [self applicationWillTerminateProceed];

                };
                [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))permissionsForProctoringHandler];
                return;
            }
        } else {
            [self applicationWillTerminateProceed];
        }

    } else if (_cmdKeyDown) {
        // Show alert that keys were hold while starting SEB
        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:NSLocalizedString(@"Holding Command Key Not Allowed!", @"")];
        [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Holding the Command key down while starting %@ is not allowed. Restart %@ without holding any keys.", @""), SEBShortAppName, SEBShortAppName]];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [modalAlert setAlertStyle:NSAlertStyleCritical];
        void (^terminateSEBAlertOK)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self removeAlertWindow:modalAlert.window];
            [self applicationWillTerminateProceed];
        };
        [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))terminateSEBAlertOK];
    } else {
        if ([ProcessManager sharedProcessManager].permittedApplications.count > 0) {
            // In case of permitted additional applications, we have to terminate running permitted applications (will be added in that method)
            [self terminateApplications:@[] processes:@[] starting:NO restarting:NO callback:self selector:@selector(applicationWillTerminateProceed)];
        } else {
            [self applicationWillTerminateProceed];
        }
    }
}

- (void) applicationWillTerminateProceed
{
    DDLogDebug(@"%s", __FUNCTION__);

//    [self killScreenCaptureAgent];
    BOOL success = [self.systemManager restoreScreenCapture];
    DDLogDebug(@"Success of restoring SC: %hhd", success);
    
    [self stopWindowWatcher];
    [self stopProcessWatcher];
    DDLogDebug(@"Returned after stopProcessWatcher");

    [self removeKeyPathObservers];
    DDLogDebug(@"Returned after removeKeyPathObservers");

    if (keyboardEventReturnKey != NULL) {
        DDLogDebug(@"%s CFRelease(keyboardEventReturnKey)", __FUNCTION__);
        CFRelease(keyboardEventReturnKey);
    }
    
    BOOL touchBarRestoreSuccess;
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enableMacOSAAC"] == NO) {
        touchBarRestoreSuccess = [_systemManager restoreSystemSettings];
        DDLogDebug(@"Restored system settings. Restoring TouchBar settings (if available) %@", touchBarRestoreSuccess ? @"was successfull" : @"failed");
        [self killTouchBarAgent];
    }
    
    // Restart terminated apps
    DDLogInfo(@"These processes were terminated by SEB during this session: %@", _terminatedProcessesExecutableURLs);
    
    for (NSURL *executableURL in _terminatedProcessesExecutableURLs) {
        
//        NSArray *taskArguments = [NSArray arrayWithObjects:@"", nil];
        
        if ([executableURL.pathExtension isEqualToString:@"app"] && ![executableURL.path.lastPathComponent isEqualToString:PasswordsMenuBarExtraApp]) {
            NSError *error;
            DDLogInfo(@"Trying to restart terminated process with bundle URL %@", executableURL.path);
            [[NSWorkspace sharedWorkspace] launchApplicationAtURL:executableURL options:NSWorkspaceLaunchDefault configuration:@{} error:&error];
            if (error) {
                DDLogError(@"Error %@", error);
            }
//        } else {
//            // Allocate and initialize a new NSTask
//            NSTask *task = [NSTask new];
//            
//            // Tell the NSTask what the path is to the binary it should launch
//            //        NSString *path = [executableURL.path stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
//            [task setLaunchPath:executableURL.path];
//            
//            [task setArguments:taskArguments];
//            
//            // Launch the process asynchronously
//            @try {
//                DDLogInfo(@"Trying to restart terminated process %@", executableURL.path);
//                [task launch];
//            }
//            @catch (NSException* error) {
//                DDLogError(@"Error %@.  Make sure you have a valid path and arguments.", error);
//            }
        }
    }
    
    runningAppsWhileTerminating = [[NSWorkspace sharedWorkspace] runningApplications];
    NSRunningApplication *iterApp;
    for (iterApp in runningAppsWhileTerminating)
    {
        NSString *appBundleID = [iterApp valueForKey:@"bundleIdentifier"];
        if ([visibleApps indexOfObject:appBundleID] != NSNotFound) {
            [iterApp unhide]; //unhide the originally visible application
        }
    }
    [self clearPasteboardCopyingBrowserExamKey];
    
	// Clear the current Browser Exam Key
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureObject:[NSData data] forKey:@"org_safeexambrowser_currentData"];

	// Clear the browser cache in ~/Library/Caches/org.safeexambrowser.SEB.Safe-Exam-Browser/
	NSURLCache *cache = [NSURLCache sharedURLCache];
	[cache removeAllCachedResponses];
    
	// Allow display and system to sleep again
	//IOReturn success = IOPMAssertionRelease(assertionID1);
	IOPMAssertionRelease(assertionID1);
	/*// Allow system to sleep again
	success = IOPMAssertionRelease(assertionID2);*/
    
    // Display alert in case TouchBar mode AppControl was active
    // before SEB was started as this mode cannot be automatically restored
    // and open System Preferences / Keyboard to allow user to restore
    // TouchBar mode manually
    if (_touchBarDetected && !touchBarRestoreSuccess) {
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:NSLocalizedString(@"Cannot Restore Touch Bar Mode",nil)];
        [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Before running %@, you had the Touch Bar mode 'App Controls' set. %@ cannot restore this setting automatically. You either have to restart your Mac or change the setting manually in System Settings / Keyboard / 'Touch Bar shows'. %@ will open this System Settings tab for you.", @""), SEBShortAppName, SEBShortAppName, SEBShortAppName]];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
        [modalAlert setAlertStyle:NSAlertStyleWarning];
        DDLogInfo(@"Cannot Restore Touch Bar Mode 'App Controls'");
        void (^cannotRestoreTouchBarAlertOK)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self removeAlertWindow:modalAlert.window];
            switch(answer)
            {
                case NSAlertFirstButtonReturn:
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:pathToKeyboardPreferences isDirectory:NO]];
                    DDLogInfo(@"User selected to open System Settings / Keyboard / 'Touch Bar shows'");
                    break;
                default:
                    DDLogError(@"Alert was dismissed by the system with NSModalResponse %ld.", (long)answer);
                case NSAlertSecondButtonReturn:
                    DDLogInfo(@"Exiting SEB without opening System Settings / Keyboard / 'Touch Bar shows'");
            }
            DDLogInfo(@"---------- EXITING SEB - ENDING SESSION -------------");
            return;
        };
        [self runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))cannotRestoreTouchBarAlertOK];
    } else {
        DDLogInfo(@"---------- EXITING SEB - ENDING SESSION -------------");
    }
}


// Called when currentPresentationOptions change
// Called when "isActive" propery of [NSRunningApplication currentApplication] changes

- (void) observeValueForKeyPath:(NSString *)keyPath
					  ofObject:id
                        change:(NSDictionary *)change
                       context:(void *)context
{
    DDLogVerbose(@"Value for key path %@ changed: %@", keyPath, change);
    
    // If the startKioskMode method changed presentation options, then we don't do nothing here
    if (_isAACEnabled == NO && _wasAACEnabled == NO && [keyPath isEqualToString:@"currentSystemPresentationOptions"]) {
        if ([[MyGlobals sharedMyGlobals] startKioskChangedPresentationOptions]) {
            [[MyGlobals sharedMyGlobals] setStartKioskChangedPresentationOptions:NO];
            return;
        }
        // Current Presentation Options changed, so make SEB active and reset them
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
        if (!allowSwitchToThirdPartyApps && ![self.preferencesController preferencesAreOpen] && !launchedApplication && !fontRegistryUIAgentRunning) {
            // If third party Apps are not allowed, we switch back to SEB
            DDLogInfo(@"Switched back to SEB after currentSystemPresentationOptions changed!");
            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
            
            [self regainActiveStatus:nil];
        }
    } else if (_isAACEnabled == NO && _wasAACEnabled == NO && [keyPath isEqualToString:@"isActive"]) {
        DDLogWarn(@"isActive property of SEB changed!");
        [self regainActiveStatus:nil];
    } else if ([keyPath isEqualToString:@"runningApplications"]) {
        NSArray *startedProcesses = [change objectForKey:@"new"];
        if (startedProcesses.count > 0) {
            NSArray *prohibitedApplications = [ProcessManager sharedProcessManager].prohibitedApplications;
            
            for (NSRunningApplication *startedApplication in startedProcesses) {
                
                NSString *bundleID = startedApplication.bundleIdentifier;
                if (bundleID && ([bundleID isEqualToString:WebKitNetworkingProcessBundleID] ||
                                 [bundleID isEqualToString:UniversalControlBundleID])) {
                    DDLogVerbose(@"Started application with bundle ID: %@", bundleID);
                } else {
                    DDLogDebug(@"Started application with bundle ID: %@", bundleID);
                }
                
                // Check for running Open and Save Panel Service
                if (!allowOpenAndSavePanel && _isAACEnabled && bundleID &&
                    [bundleID isEqualToString:openAndSavePanelServiceBundleID]) {
                    [self killApplication:startedApplication];
                }
                
                // Check for Share Sheet UI
                if (!allowShareSheet && _isAACEnabled && bundleID &&
                    [bundleID isEqualToString:shareSheetBundleID]) {
                    [self killApplication:startedApplication];
                }
                
                NSPredicate *processFilter = [NSPredicate predicateWithFormat:@"%@ LIKE self", bundleID];
                
                NSArray *matchingProhibitedApplications = [prohibitedApplications filteredArrayUsingPredicate:processFilter];
                if (matchingProhibitedApplications.count != 0) {
                    if ([bundleID isEqualToString:WebKitNetworkingProcessBundleID]) {
                        pid_t processPID = startedApplication.processIdentifier;
                        typedef pid_t (*pidResolver)(pid_t pid);
                        pidResolver resolver = dlsym(RTLD_NEXT, "responsibility_get_pid_responsible_for_pid");
                        pid_t trueParentPid = resolver(processPID);
                        DDLogVerbose(@"PID: %d - Bundle ID: %@ - True Parent PID: %d", processPID, bundleID, trueParentPid);
                        if (trueParentPid == sebPID) {
                            DDLogDebug(@"Not terminating instance of WebKit networking process started by SEB");
                            return;
                        }
                    }
                    [self killApplication:startedApplication];
                }
            }
        } else {
            NSArray *terminatedProcesses = [change objectForKey:@"old"];
            if (terminatedProcesses.count > 0 && _processListViewController != nil) {
                [_processListViewController didTerminateRunningApplications:terminatedProcesses];
            }
        }
    }
}


- (void)closeProcessListWindow
{
    _runningProcessesListWindowController.window.delegate = nil;
    [_runningProcessesListWindowController close];
    _processListViewController = nil;
}

- (void)closeProcessListWindowWithCallback:(id)callback selector:(SEL)selector
{
    DDLogDebug(@"%s callback: %@ selector: %@", __FUNCTION__, callback, NSStringFromSelector(selector));
    BOOL starting = self.processListViewController.starting;
    BOOL restarting = self.processListViewController.restarting;
    [self closeProcessListWindow];
    // Continue to initializing SEB and then starting the exam session
    [self conditionallyContinueAfterTerminatingAppsWithCallback:callback restarting:restarting selector:selector starting:starting];
}


- (NSURL *) getTempDownUploadDirectory
{
    return [self.sebFileManager getTempDownUploadDirectoryWithConfigKey:self.configKey];
}

- (BOOL) removeTempDownUploadDirectory
{
    return [self.sebFileManager removeTempDownUploadDirectory];
}


@end
