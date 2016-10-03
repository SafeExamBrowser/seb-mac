//
//  SEBController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.04.10.
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

#include <Carbon/Carbon.h>
#import "SEBController.h"

#import <IOKit/pwr_mgt/IOPMLib.h>

#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>

#include <mach/mach_port.h>
#include <mach/mach_interface.h>
#include <mach/mach_init.h>

#import <objc/runtime.h>

#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/IOMessage.h>

#include <signal.h>
#include <unistd.h>

#import "PrefsBrowserViewController.h"
#import "SEBBrowserController.h"
#import "SEBURLFilter.h"

#import "RNDecryptor.h"
#import "SEBKeychainManager.h"
#import "SEBCryptor.h"
#import "SEBCertServices.h"
#import "NSWindow+SEBWindow.h"
#import "SEBConfigFileManager.h"

#import "SEBDockItemMenu.h"

#import "SEBWindowSizeValueTransformer.h"
#import "BoolValueTransformer.h"
#import "IsEmptyCollectionValueTransformer.h"
#import "NSTextFieldNilToEmptyStringTransformer.h"

#include <SystemConfiguration/SystemConfiguration.h>

#import "SEBUIUserDefaultsController.h"


io_connect_t  root_port; // a reference to the Root Power Domain IOService


OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,id sender);
void MySleepCallBack(void * refCon, io_service_t service, natural_t messageType, void * messageArgument);
bool insideMatrix();

@implementation SEBController

@synthesize f3Pressed;	//create getter and setter for F3 key pressed flag
@synthesize quittingMyself;	//create getter and setter for flag that SEB is quitting itself
@synthesize webView;
@synthesize capWindows;
@synthesize lockdownWindows;

@synthesize browserController;

#pragma mark Application Delegate Methods

+ (void) initialize
{
    [[MyGlobals sharedMyGlobals] setFinishedInitializing:NO];
    [[MyGlobals sharedMyGlobals] setStartKioskChangedPresentationOptions:NO];
    [[MyGlobals sharedMyGlobals] setLogLevel:DDLogLevelVerbose];

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


- (SEBOSXBrowserController *) browserController
{
    if (!browserController) {
        browserController = [[SEBOSXBrowserController alloc] init];
        browserController.sebController = self;
    }
    return browserController;
}


// Tells the application delegate to open a single file.
// Returning YES if the file is successfully opened, and NO otherwise.
//
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    NSURL *sebFileURL = [NSURL fileURLWithPath:filename];

    DDLogInfo(@"Open file event: Loading .seb settings file with URL %@",sebFileURL);

    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];

    // Check if preferences window is open
    if ([self.preferencesController preferencesAreOpen]) {

        /// Open settings file in preferences window for editing

        [self.preferencesController openSEBPrefsAtURL:sebFileURL];
    
    } else {
        
        /// Open settings file for exam/reconfiguring client
        
        // Check if SEB is in exam mode = private UserDefauls are switched on
        if (NSUserDefaults.userDefaultsPrivate) {
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Loading New SEB Settings Not Allowed!", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"SEB is already running in exam mode and it is not allowed to interupt this by starting another exam. Finish the exam and quit SEB before starting another exam.", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            [newAlert runModal];
            return YES;
        }
        
        NSData *sebData = [NSData dataWithContentsOfURL:sebFileURL];
        
        SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
        
        // Get current config path
        NSURL *currentConfigPath = [[MyGlobals sharedMyGlobals] currentConfigURL];
        // Save the path to the file for possible editing in the preferences window
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:sebFileURL];
        
        // Decrypt and store the .seb config file
        if ([configFileManager storeDecryptedSEBSettings:sebData forEditing:NO] == storeDecryptedSEBSettingsResultSuccess) {
            // if successfull restart with new settings
            [self requestedRestart:nil];
        } else {
            // if decrypting new settings wasn't successfull, we have to restore the path to the old settings
            [[MyGlobals sharedMyGlobals] setCurrentConfigURL:currentConfigPath];
        }
    }
    
    return YES;
}


- (void)handleGetURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        // If we have any URL, we try to download and open (conditionally) a .seb file
        // hopefully linked by this URL (also supporting redirections and authentification)
        DDLogInfo(@"Get URL event: Loading .seb settings file with URL %@", urlString);
        [self.browserController openConfigFromSEBURL:url];
    }
}


#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) {
        
        // Initialize console loggers
#ifdef DEBUG
        // We show log messages only in Console.app and the Xcode console in debug mode
        [DDLog addLogger:[DDASLLogger sharedInstance]];
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
#endif

        [[MyGlobals sharedMyGlobals] setPreferencesReset:NO];
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
        [MyGlobals sharedMyGlobals].reconfiguredWhileStarting = NO;
        
        [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
        DDLogDebug(@"Installed get URL event handler");

        // Add an observer for the request to unconditionally quit SEB
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(requestedQuit:)
                                                     name:@"requestQuitNotification" object:nil];
        
        
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        //[[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        // Set default preferences for the case there are no user prefs yet
        // and set flag for displaying alert to new users
        firstStart = [preferences setSEBDefaults];

        // Initialize file logger if it's enabled in settings
        [self initializeLogger];
        
        // Get default WebKit browser User Agent and create
        // default SEB User Agent
        NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
        NSString *defaultUserAgent = [[WebView new] userAgentForURL:[NSURL URLWithString:urlText]];
        [self.browserController createSEBUserAgentFromDefaultAgent:defaultUserAgent];
        
        // Update URL filter flags and rules
        [[SEBURLFilter sharedSEBURLFilter] updateFilterRules];
        // Update URL filter ignore rules
        [[SEBURLFilter sharedSEBURLFilter] updateIgnoreRuleList];
        
        // Regardless if switching to third party applications is allowed in current settings,
        // we need to first open the background cover windows with standard window levels
        [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
    }
    return self;
}


- (BOOL) isInApplicationsFolder:(NSString *)path
{
    // Check all the normal Application directories
    NSArray *applicationDirs = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSAllDomainsMask, YES);
    for (NSString *appDir in applicationDirs) {
        if ([path hasPrefix:appDir]) return YES;
    }
    return NO;
}


- (void)awakeFromNib
{
    self.systemManager = [[SEBSystemManager alloc] init];
    
    [self.systemManager preventSC];
	
//    BOOL worked = [systemManager checkHTTPSProxySetting];
//#ifdef DEBUG
//    DDLogDebug(@"Checking updating HTTPS proxy worked: %hhd", worked);
//#endif
    
    // Flag initializing
	quittingMyself = FALSE; //flag to know if quit application was called externally

    // Terminate invisibly running applications
    if ([NSRunningApplication respondsToSelector:@selector(terminateAutomaticallyTerminableApplications)]) {
        [NSRunningApplication terminateAutomaticallyTerminableApplications];
    }

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // If AirPlay isn't allowed in settings, kill the AirPlay agent
    // to stop a possibly running AirPlay connection
    [self conditionallyTerminateAirPlay];
    
    // Save the bundle ID of all currently running apps which are visible in a array
	NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
    NSRunningApplication *iterApp;
    visibleApps = [NSMutableArray array]; //array for storing bundleIDs of visible apps

    for (iterApp in runningApps)
    {
        BOOL isHidden = [iterApp isHidden];
        NSString *appBundleID = [iterApp valueForKey:@"bundleIdentifier"];
        DDLogInfo(@"Running app: %@, bundle ID: %@", iterApp.localizedName, appBundleID);
        if ((appBundleID != nil) & !isHidden) {
            [visibleApps addObject:appBundleID]; //add ID of the visible app
        }
        if ([iterApp ownsMenuBar]) {
            DDLogDebug(@"App %@ owns menu bar", iterApp);
        }
        // Check for activated screen sharing if settings demand it
        if ([appBundleID isEqualToString:@"com.apple.ScreenSharing"] &&
            ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowScreenSharing"]) {
            // Screen sharing is active
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Screen Sharing Detected!", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"You are not allowed to have screen sharing active while running SEB. Restart SEB after switching screen sharing off.\n\nTo avoid that SEB locks itself during an exam when it detects that screen sharing started, it's best to switch off 'Screen Sharing' and 'Remote Management' in System Preferences/Sharing.", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            [newAlert runModal];
            quittingMyself = TRUE; //SEB is terminating itself
            [NSApp terminate: nil]; //quit SEB
        }
    }

// Setup Notifications and Kiosk Mode
    
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
//	[[workspace notificationCenter] addObserver:self
//                                       selector:@selector(regainActiveStatus:)
//                                           name:NSWorkspaceWillLaunchApplicationNotification
//                                         object:nil];
//	
    // Add an observer for the notification that another application was launched
	[[workspace notificationCenter] addObserver:self
                                       selector:@selector(appLaunch:)
                                           name:NSWorkspaceDidLaunchApplicationNotification
                                         object:nil];
	
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

    
    // Hide all other applications
    [[NSWorkspace sharedWorkspace] performSelectorOnMainThread:@selector(hideOtherApplications)
                                                    withObject:NULL waitUntilDone:NO];
    
    // Cover all attached screens with cap windows to prevent clicks on desktop making finder active
	[self coverScreens];

    // Check if running on minimal macOS version
    [self checkMinMacOSVersion];
    
    // Check if launched SEB is placed ("installed") in an Applications folder
    [self installedInApplicationsFolder];
    
    // Check for command key being held down
    [self appSwitcherCheck];
    
    // Switch to kiosk mode by setting the proper presentation options
    [self startKioskMode];
    
    // Hide all other applications
    [[NSWorkspace sharedWorkspace] performSelectorOnMainThread:@selector(hideOtherApplications)
                                                    withObject:NULL waitUntilDone:NO];
    
//    // Cover all attached screens with cap windows to prevent clicks on desktop making finder active
//    [self coverScreens];
    
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
                                             selector:@selector(exitSEB:)
                                                 name:@"requestExitNotification" object:nil];
	
    // Add an observer for the request to conditionally quit SEB with asking quit password
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestedQuitWPwd:)
                                                 name:@"requestQuitWPwdNotification" object:nil];
	
    // Add an observer for the request to reload start URL
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestedRestart:)
                                                 name:@"requestRestartNotification" object:nil];
	
    // Add an observer for the request to reinforce the kiosk mode
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(performAfterStartActions:)
                                                 name:@"requestPerformAfterStartActions" object:nil];
    
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
    [[NSNotificationCenter defaultCenter] addObserver:aboutWindow
                                             selector:@selector(closeAboutWindow:)
                                                 name:@"requestCloseAboutWindowNotification" object:nil];
	
    // Add an observer for the request to show help
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestedShowHelp:)
                                                 name:@"requestShowHelpNotification" object:nil];

    // Add an observer for the request to switch plugins on
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(switchPluginsOn:)
                                                 name:@"switchPluginsOn" object:nil];
    
    // Add an observer for the notification that preferences were closed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferencesClosed:)
                                                 name:@"preferencesClosed" object:nil];

    // Add an observer for the notification that preferences were closed and SEB should be restarted
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(preferencesClosedRestartSEB:)
                                                 name:@"preferencesClosedRestartSEB" object:nil];
    // Add an observer for the notification that a screen sharing session become active
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(switchHandler:)
                                                 name:@"detectedScreenSharing" object:nil];
    [self forceTerminatePanelApps];

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
	
/*	// Prevent idle sleep
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

	if (![[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowVirtualMachine"]) {
        // Check if SEB is running inside a virtual machine
        SInt32		myAttrs;
        OSErr		myErr = noErr;
        
        // Get details for the present operating environment
        // by calling Gestalt (Userland equivalent to CPUID)
        myErr = Gestalt(gestaltX86AdditionalFeatures, &myAttrs);
        if (myErr == noErr) {
            if ((myAttrs & (1UL << 31)) | (myAttrs == 0x209)) {
                // Bit 31 is set: VMware Hypervisor running (?)
                // or gestaltX86AdditionalFeatures values of VirtualBox detected
                DDLogError(@"SERIOUS SECURITY ISSUE DETECTED: SEB was started up in a virtual machine! gestaltX86AdditionalFeatures = %X", myAttrs);
                NSAlert *newAlert = [[NSAlert alloc] init];
                [newAlert setMessageText:NSLocalizedString(@"Virtual Machine Detected!", nil)];
                [newAlert setInformativeText:NSLocalizedString(@"You are not allowed to run SEB inside a virtual machine!", nil)];
                [newAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
                [newAlert setAlertStyle:NSCriticalAlertStyle];
                [newAlert runModal];
                quittingMyself = TRUE; //SEB is terminating itself
                [NSApp terminate: nil]; //quit SEB
                
            } else {
                DDLogInfo(@"SEB is running on a native system (no VM) gestaltX86AdditionalFeatures = %X", myAttrs);
            }
        }
        
        bool    virtualMachine = false;
        // STR or SIDT code?
        virtualMachine = insideMatrix();
        if (virtualMachine) {
            DDLogError(@"SERIOUS SECURITY ISSUE DETECTED: SEB was started up in a virtual machine (Test2)!");
        }
    }


    [self clearPasteboardSavingCurrentString];

    /// Set up SEB Browser

    self.browserController.reinforceKioskModeRequested = YES;
    
    // Set up and open SEB Dock
    [self openSEBDock];
    self.browserController.dockController = self.dockController;
    
    // Open the main browser window
    [self.browserController openMainBrowserWindow];
    
// Handling of Hotkeys for Preferences-Window
	
	// Register Carbon event handlers for the required hotkeys
	f3Pressed = FALSE; //Initialize flag for first hotkey
	EventHotKeyRef gMyHotKeyRef;
	EventHotKeyID gMyHotKeyID;
	EventTypeSpec eventType;
	eventType.eventClass=kEventClassKeyboard;
	eventType.eventKind=kEventHotKeyPressed;
	InstallApplicationEventHandler((void*)MyHotKeyHandler, 1, &eventType, (__bridge void*)(SEBController*)self, NULL);
    //Pass pointer to flag for F3 key to the event handler
	// Register F3 as a hotkey
	gMyHotKeyID.signature='htk1';
	gMyHotKeyID.id=1;
	RegisterEventHotKey(99, 0, gMyHotKeyID,
						GetApplicationEventTarget(), 0, &gMyHotKeyRef);
	// Register F6 as a hotkey
	gMyHotKeyID.signature='htk2';
	gMyHotKeyID.id=2;
	RegisterEventHotKey(97, 0, gMyHotKeyID,
						GetApplicationEventTarget(), 0, &gMyHotKeyRef);
    

    // Show the About SEB Window
    [aboutWindow showAboutWindowForSeconds:2];
}


- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [[[NSWorkspace sharedWorkspace] notificationCenter]
     addObserver:self
     selector:@selector(switchHandler:)
     name:NSWorkspaceSessionDidBecomeActiveNotification
     object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter]
     addObserver:self
     selector:@selector(switchHandler:)
     name:NSWorkspaceSessionDidResignActiveNotification
     object:nil];

    CGEventMask mask = CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventLeftMouseUp);
    
    CFMachPortRef leftMouseEventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, mask, leftMouseTapCallback, NULL);
    
    if (leftMouseEventTap) {
        CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, leftMouseEventTap, 0);
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        CGEventTapEnable(leftMouseEventTap, true);
    }

    [self conditionallyStartWindowWatcher];
    
    [self performSelector:@selector(performAfterStartActions:) withObject: nil afterDelay: 2];
}


// Start the windows watcher if it's not yet running
- (void)conditionallyStartWindowWatcher
{
    if (![[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"]) {
        if (!_windowWatchTimer) {
            NSDate *dateNextMinute = [NSDate date];
            
            _windowWatchTimer = [[NSTimer alloc] initWithFireDate: dateNextMinute
                                                         interval: 0.25
                                                           target: self
                                                         selector:@selector(forceTerminatePanelApps)
                                                         userInfo:nil repeats:YES];
            
            NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
            [currentRunLoop addTimer:_windowWatchTimer forMode: NSRunLoopCommonModes];
        }
    } else {
        // We're (currently) not running the windows watcher when switching to third party apps is allowed
        if (_windowWatchTimer) {
            [_windowWatchTimer invalidate];
            _windowWatchTimer = nil;
        }
    }
}


- (void)forceTerminatePanelApps
{
    CGWindowListOption options;
    BOOL firstScan = false;
    if (!_systemProcessPIDs) {
        // When this method is called the first time, we scan all windows
        firstScan = true;
        _systemProcessPIDs = [NSMutableArray new];
        options = kCGWindowListOptionAll;
        // Get SEB's PID
        NSRunningApplication *sebRunningApp = [NSRunningApplication currentApplication];
        sebPID = [sebRunningApp processIdentifier];

    } else {
        // otherwise only those which are visible (on screen)
        options = kCGWindowListOptionOnScreenOnly;
    }
    
    NSArray *windowList = CFBridgingRelease(CGWindowListCopyWindowInfo(options, kCGNullWindowID));
#ifdef DEBUG
    DDLogVerbose(@"Window list: %@", windowList);
#endif
    for (NSDictionary *window in windowList) {
        NSString *windowName = [window objectForKey:@"kCGWindowName" ];
        NSString *windowOwner = [window objectForKey:@"kCGWindowOwnerName" ];
        if (_allowSwitchToApplications && [windowName isEqualToString:@"NotificationTableWindow"]) {
            // If switching to applications is allowed and the Notification Center was opened
            DDLogWarn(@"Notification Center panel was openend (owning process name: %@", windowOwner);
            
            NSRunningApplication *notificationCenter = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.notificationcenterui"][0];
            [notificationCenter forceTerminate];
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
                    DDLogWarn(@"Application %@ with bundle ID %@ has openend a window with level %@", windowOwner, appWithPanelBundleID, windowLevelString);
                    if (appWithPanelBundleID && ![appWithPanelBundleID hasPrefix:@"com.apple."]) {
                        // Application hasn't a com.apple. bundle ID prefix
                        // The app which opened the window or panel is no system process
                        if (firstScan) {
                            //[appWithPanel terminate];
                        } else {
                            DDLogWarn(@"Application %@ is being force terminated!", windowOwner);
                            [appWithPanel forceTerminate];
                        }
                    } else {
                        // There is either no bundle ID or the prefix is com.apple.
                        // Check if application with Bundle ID com.apple. is a legit Apple system executable
                        if ([self signedSystemExecutable:appWithPanel]) {
                            // Cache this executable PID
                            [_systemProcessPIDs addObject:windowOwnerPIDString];
                            // Return without terminating
                            return;
                        } else {
                            // The app which opened the window or panel is no system process
                            if (firstScan) {
                                //[appWithPanel terminate];
                            } else {
                                DDLogWarn(@"Application %@ is being force terminated!", windowOwner);
                                [appWithPanel forceTerminate];
                            }
                        }
                    }
                }
            }
        }
    }
}


// Perform actions which require that SEB has finished setting up and has opened its windows
- (void) performAfterStartActions:(NSNotification *)notification
{
    DDLogInfo(@"Performing after start actions");
    
    // Check for command key being held down
    [self appSwitcherCheck];
    
    // Reinforce the kiosk mode
    [self requestedReinforceKioskMode:nil];
    
//    [[NSNotificationCenter defaultCenter]
//     postNotificationName:@"requestReinforceKioskMode" object:self];
    
    if ([[MyGlobals sharedMyGlobals] preferencesReset] == YES) {
        DDLogError(@"Triggering present alert for 'Local SEB settings have been reset'");
        [self presentPreferencesCorruptedError];
    }
    
    // Check if the Force Quit window is open
    [self forceQuitWindowCheck];

    // Check if there is a SebClientSettings.seb file saved in the preferences directory
    SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
    if (![configFileManager reconfigureClientWithSebClientSettings] && [MyGlobals sharedMyGlobals].reconfiguredWhileStarting) {
        // Show alert that SEB was reconfigured
        NSAlert *newAlert = [[NSAlert alloc] init];
        [newAlert setMessageText:NSLocalizedString(@"SEB Re-Configured", nil)];
        [newAlert setInformativeText:NSLocalizedString(@"Local settings of this SEB client have been reconfigured. Do you want to start working with SEB now or quit?", nil)];
        [newAlert addButtonWithTitle:NSLocalizedString(@"Start", nil)];
        [newAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
        NSInteger answer = [newAlert runModal];
        switch(answer)
        {
            case NSAlertFirstButtonReturn:
                
                break; //Continue running SEB
                
            case NSAlertSecondButtonReturn:
            {
//                [[NSNotificationCenter defaultCenter]
//                 postNotificationName:@"requestQuitNotification" object:self];
                [self performSelector:@selector(requestedQuit:) withObject: nil afterDelay: 3];
            }
                
        }
    }
    
    // Set flag that SEB is initialized: Now showing alerts is allowed
    [[MyGlobals sharedMyGlobals] setFinishedInitializing:YES];
}


// Check if application is a legit Apple system executable
- (NSRunningApplication *)signedSystemExecutable:(NSRunningApplication *)runningExecutable
{
    SecStaticCodeRef ref = NULL;
    
    NSURL * url = runningExecutable.executableURL;
    
    OSStatus status;
    
    // obtain the cert info from the executable
    status = SecStaticCodeCreateWithPath((__bridge CFURLRef)url, kSecCSDefaultFlags, &ref);
    
    if (ref == NULL) return false;
    if (status != noErr) return false;
    
    SecRequirementRef req = NULL;
    
    // this is the public SHA1 fingerprint of the cert match string
    NSString * reqStr = [NSString stringWithFormat:@"%@ %@ = %@%@%@",
                         @"certificate",
                         @"leaf",
                         @"H\"013E2787748A74",
                         @"103D62D2CDBF77",
                         @"A1345517C482\""
                         ];
    
    // create the requirement to check against
    status = SecRequirementCreateWithString((__bridge CFStringRef)reqStr, kSecCSDefaultFlags, &req);
    
    if (status != noErr) return nil;
    if (req == NULL) return nil;
    
    status = SecStaticCodeCheckValidity(ref, kSecCSCheckAllArchitectures, req);
    
    if (status != noErr) return nil;
    
    CFRelease(ref);
    CFRelease(req);
    
    DDLogDebug(@"Code signature of %@ was checked and it positively identifies Apple software.", url);
    
    return runningExecutable;
}


// If AirPlay isn't allowed in settings, kill the AirPlay agent
// to stop a possibly running AirPlay connection
- (void)conditionallyTerminateAirPlay
{
    if (![[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowAirPlay"]) {
        NSArray *runningAirPlayAgents = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.AirPlayUIAgent"];
        if (runningAirPlayAgents.count != 0) {
            for (NSRunningApplication *airPlayAgent in runningAirPlayAgents) {
                DDLogWarn(@"Terminating AirPlayUIAgent %@", airPlayAgent);
                kill([airPlayAgent processIdentifier], 9);
            }
        }
    }
}


// Check if running on minimal allowed macOS version or a newer version
- (void)checkMinMacOSVersion
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    SEBMinMacOSVersion minMacOSVersion = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_minMacOSVersion"];
    _enforceMinMacOSVersion = SEBMinMacOSVersionSupported;
    switch (minMacOSVersion) {
        case SEBMinOSX10_8:
            _enforceMinMacOSVersion = floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_8 ? SEBMinOSX10_8 : _enforceMinMacOSVersion;
            break;
            
        case SEBMinOSX10_9:
            _enforceMinMacOSVersion = floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_9 ? SEBMinOSX10_9 : _enforceMinMacOSVersion;
            break;
            
        case SEBMinOSX10_10:
            _enforceMinMacOSVersion = floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_10 ? SEBMinOSX10_10 : _enforceMinMacOSVersion;
            break;
            
        case SEBMinOSX10_11:
            _enforceMinMacOSVersion = floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_11 ? SEBMinOSX10_11 : _enforceMinMacOSVersion;
            break;
            
        case SEBMinMacOS10_12:
            _enforceMinMacOSVersion = floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_11 ? SEBMinMacOS10_12 : _enforceMinMacOSVersion;
            break;
            
        default:
            break;
    }
    if (_enforceMinMacOSVersion != SEBMinMacOSVersionSupported) {
        DDLogError(@"Current settings require SEB to be running at least on %@, but it isn't! SEB will therefore quit!", [[SEBUIUserDefaultsController sharedSEBUIUserDefaultsController] org_safeexambrowser_SEB_minMacOSVersions][_enforceMinMacOSVersion]);
        quittingMyself = TRUE; //SEB is terminating itself
        [NSApp terminate: nil]; //quit SEB
    } else {
        DDLogInfo(@"SEB is running at least on the minimal macOS version %@ required by current settings (actually on version %f)", [[SEBUIUserDefaultsController sharedSEBUIUserDefaultsController] org_safeexambrowser_SEB_minMacOSVersions][_enforceMinMacOSVersion], floor(NSAppKitVersionNumber));
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
            quittingMyself = TRUE; //SEB is terminating itself
            [NSApp terminate: nil]; //quit SEB
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


// Check for command key being held down
- (void)appSwitcherCheck
{
    int modifierFlags = [NSEvent modifierFlags];
    _cmdKeyDown = (0 != (modifierFlags & NSCommandKeyMask));
    if (_cmdKeyDown) {
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enableAppSwitcherCheck"]) {
            DDLogError(@"Command key is pressed and forbidden, SEB cannot restart");
            quittingMyself = TRUE; //SEB is terminating itself
            [NSApp terminate: nil]; //quit SEB
        } else {
            DDLogWarn(@"Command key is pressed, but not forbidden in current settings");
        }
    }
}


-(BOOL)commandKeyPressed
{
    int modifierFlags = [NSEvent modifierFlags];
    BOOL cmdKeyDown = (0 != (modifierFlags & NSCommandKeyMask));
    if (cmdKeyDown) {
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enableAppSwitcherCheck"]) {
            // Show alert that keys were hold while starting SEB
            DDLogError(@"Command key is pressed while restarting SEB, show dialog asking to release it.");
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Holding Command Key Not Allowed!", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"Holding the Command key down while restarting SEB is not allowed, release it to continue.", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            [newAlert runModal];
        } else {
            DDLogWarn(@"Command key is pressed, but not forbidden in current settings");
        }
    }
    return cmdKeyDown;
}


// Check if the Force Quit window is open
- (void)forceQuitWindowCheck
{
    while ([self forceQuitWindowOpen]) {
        // Show alert that the Force Quit window is open
        DDLogError(@"Force Quit window is open, show error message and ask user to close it or quit SEB.");
        NSAlert *newAlert = [[NSAlert alloc] init];
        [newAlert setMessageText:NSLocalizedString(@"Close Force Quit Window", nil)];
        [newAlert setInformativeText:NSLocalizedString(@"SEB cannot run when the Force Quit window is open. Close the window or quit SEB.", nil)];
        [newAlert setAlertStyle:NSCriticalAlertStyle];
        [newAlert addButtonWithTitle:NSLocalizedString(@"Retry", nil)];
        [newAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
        NSInteger answer = [newAlert runModal];
        switch(answer)
        {
            case NSAlertFirstButtonReturn:
                DDLogError(@"Force Quit window was open, user clicked retry");
                break; // Test if window is closed now
                
            case NSAlertSecondButtonReturn:
            {
                // Quit SEB
                DDLogError(@"Force Quit window was open, user decided to quit SEB.");
                quittingMyself = TRUE; //SEB is terminating itself
                [NSApp terminate: nil]; //quit SEB
            }
        }
    }
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


- (void)presentPreferencesCorruptedError
{
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    NSAlert *newAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Local SEB Settings Have Been Reset", nil) defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Local preferences were created by an incompatible SEB version, damaged or manipulated. They have been reset to the default settings. Ask your exam supporter to re-configure SEB correctly.", nil)];
    [newAlert setAlertStyle:NSCriticalAlertStyle];
    [newAlert runModal];
    newAlert = nil;

    DDLogInfo(@"Dismissed alert for local SEB settings have been reset");

    //    NSDictionary *newDict = @{ NSLocalizedDescriptionKey :
    //                                   NSLocalizedString(@"Local SEB settings are corrupted!", nil),
    //                               /*NSLocalizedFailureReasonErrorKey :
    //                                NSLocalizedString(@"Either an incompatible version of SEB has been used on this computer or the preferences file has been manipulated. In the first case you can quit SEB now and use the previous version to export settings as a .seb config file for reconfiguring the new version. Otherwise local settings need to be reset to the default values in order for SEB to continue running.", nil),*/
    //                               //NSURLErrorKey : furl,
    //                               NSRecoveryAttempterErrorKey : self,
    //                               NSLocalizedRecoverySuggestionErrorKey :
    //                                   NSLocalizedString(@"Local preferences have either been manipulated or created by an incompatible SEB version. You can reset settings now or quit and try to use your previous SEB version to review or export settings as a .seb file for configuring the new version.\n\nReset local settings and continue?", @""),
    //                               NSLocalizedRecoveryOptionsErrorKey :
    //                                   @[NSLocalizedString(@"Continue", @""), NSLocalizedString(@"Quit", @"")] };
    //
    //    NSError *newError = [[NSError alloc] initWithDomain:sebErrorDomain
    //                                                   code:1 userInfo:newDict];
    
    
    // Reset settings to the default values
    //	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    //    [preferences resetSEBUserDefaults];
    //    [preferences storeSEBDefaultSettings];
    //    // Update Exam Browser Key
    //    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    //#ifdef DEBUG
    //    DDLogError(@"Local preferences have been reset!");
    //#endif
}


- (void) initializeLogger
{
    // Initialize file logger if logging enabled
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableLogging"] == NO) {
        [DDLog removeLogger:_myLogger];
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
        DDLogFileManagerDefault* logFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:logPath];
        _myLogger = [[DDFileLogger alloc] initWithLogFileManager:logFileManager];
        _myLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
        _myLogger.logFileManager.maximumNumberOfLogFiles = 7; // keep logs for 7 days
        [DDLog addLogger:_myLogger];
        
        NSString *localHostname = (NSString *)CFBridgingRelease(SCDynamicStoreCopyLocalHostName(NULL));
        NSString *computerName = (NSString *)CFBridgingRelease(SCDynamicStoreCopyComputerName(NULL, NULL));
        NSString *userName = NSUserName();
        NSString *fullUserName = NSFullUserName();

        // To Do: Find out domain of the current host address
        // This has to be processed asynchronously with GCD
//        NSHost *host;
//        host = [NSHost currentHost];

        DDLogInfo(@"---------- INITIALIZING SEB - STARTING SESSION -------------");
        DDLogInfo(@"Local hostname: %@", localHostname);
        DDLogInfo(@"Computer name: %@", computerName);
        DDLogInfo(@"User name: %@", userName);
        DDLogInfo(@"Full user name: %@", fullUserName);
    }
}


#pragma mark Methods

// Method executed when hotkeys are pressed
OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
						  id userData)
{
	EventHotKeyID hkCom;
	GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,
					  sizeof(hkCom),NULL,&hkCom);
	int l = hkCom.id;
	id self = userData;
	
	switch (l) {
		case 1: //F3 pressed
			[self setF3Pressed:TRUE];	//F3 was pressed
			
			break;
		case 2: //F6 pressed
			if ([self f3Pressed]) {	//if F3 got pressed before
				[self setF3Pressed:FALSE];
				[self openPreferences:self]; //show preferences window
			}
			break;
	}
	return noErr;
}


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
			
			//IOCancelPowerChange( root_port, (long)messageArgument );
			//IOAllowPowerChange( root_port, (long)messageArgument );
            break;
			
        case kIOMessageSystemWillPowerOn:
            //System has started the wake up process...
            break;
			
        case kIOMessageSystemHasPoweredOn:
            //System has finished waking up...
			break;
			
        default:
            break;
			
    }
}


bool insideMatrix(){
	unsigned char mem[4] = {0,0,0,0};
	//__asm ("str mem");
	if ( (mem[0]==0x00) && (mem[1]==0x40))
		return true; //printf("INSIDE MATRIX!!\n");
	else
		return false; //printf("OUTSIDE MATRIX!!\n");
	return false;
}


CGEventRef leftMouseTapCallback(CGEventTapProxy aProxy, CGEventType aType, CGEventRef aEvent, void* aRefcon)
{
    CGPoint theLocation = CGEventGetLocation(aEvent);
    if (theLocation.y <= kMenuBarHeight && theLocation.x < ([NSScreen screens][0].visibleFrame.size.width - 46)) {
        [[MyGlobals sharedMyGlobals] setClickedMenuBar:true];
        DDLogDebug(@"Clicked inside the menu bar");
    } else {
        [[MyGlobals sharedMyGlobals] setClickedMenuBar:false];
    }
    
    return aEvent;
}


// Close the About Window
- (void) closeAboutWindow {
    DDLogInfo(@"Attempting to close about window %@", aboutWindow);
    [aboutWindow orderOut:self];
}




// Open background windows on all available screens to prevent Finder becoming active when clicking on the desktop background
- (void) coverScreens {
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
        //NSRect frame = size of the current screen;
        NSRect frame = [iterScreen frame];
        NSUInteger styleMask = NSBorderlessWindowMask;
        NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
        
        //set origin of the window rect to left bottom corner (important for non-main screens, since they have offsets)
        rect.origin.x = 0;
        rect.origin.y = 0;

        // If showing menu bar
        // On OS X >= 10.10 we exclude the menu bar on all screens from the covering windows
        // On OS X <= 10.9 we exclude the menu bar only on the screen which actually displays the menu bar
        if (excludeMenuBar && (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_10 || iterScreen == screens[0])) {
            // Reduce size of covering background windows to not cover the menu bar
            rect.size.height -= 22;
        }
        DDLogDebug(@"Opening %@ covering window with frame %@ and window level %ld", coveringWindowKind == coveringWindowBackground ? @"background" : @"lockdown alert", CGRectCreateDictionaryRepresentation(rect), windowLevel);
        id window;
        id capview;
        NSColor *windowColor;
        switch (coveringWindowKind) {
            case coveringWindowBackground: {
                window = [[NSWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered defer:NO screen:iterScreen];
                capview = [[CapView alloc] initWithFrame:rect];
                windowColor = [NSColor blackColor];
                break;
            }
                
            case coveringWindowLockdownAlert: {
                window = [[CapWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered defer:NO screen:iterScreen];
                capview = [[NSView alloc] initWithFrame:rect];
                windowColor = [NSColor redColor];
                break;
            }
                
            default:
                return nil;
        }
        
        [window setReleasedWhenClosed:YES];
        [window setBackgroundColor:windowColor];
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrintScreen"] == NO) {
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


// Called when changes of the screen configuration occur
// (new display is contected or removed or display mirroring activated)

- (void) adjustScreenLocking: (id)sender {
    // This should only be done when the preferences window isn't open
    if (![self.preferencesController preferencesAreOpen]) {

        DDLogDebug(@"Adjusting screen locking");

        // Check if lockdown windows are open and adjust those too
        if (self.lockdownWindows.count > 0) {
            DDLogDebug(@"Adjusting lockdown windows");
            [self closeLockdownWindows];
            [self openLockdownWindows];
        }
        
        // Close the covering windows
        // (which most likely are no longer there where they should be)
        [self closeCapWindows];
        
        // Open new covering background windows on all currently available screens
        [self coverScreens];
        
        // We adjust position and size of the SEB Dock
        [self.dockController adjustDock];
        
        // We adjust the size of the main browser window
        [self.browserController adjustMainBrowserWindow];
    }
}


// Called when main browser window changed screen
- (void) changeMainScreen: (id)sender {
    [self.dockController moveDockToScreen:self.browserController.mainBrowserWindow.screen];
}


- (void) closeCapWindows
{
    [self closeCoveringWindows:self.capWindows];
}


- (void) openLockdownWindows
{
    self.lockdownWindows = [self fillScreensWithCoveringWindows:coveringWindowLockdownAlert windowLevel:NSScreenSaverWindowLevel excludeMenuBar:false];
    NSWindow *coveringWindow = self.lockdownWindows[0];
    NSView *coveringView = coveringWindow.contentView;
    [coveringView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [coveringView setTranslatesAutoresizingMaskIntoConstraints:true];
    
    sebLockedViewController.sebController = self;
    
    [coveringView addSubview:sebLockedViewController.view];
    
    DDLogVerbose(@"Frame of superview: %f, %f", sebLockedViewController.view.superview.frame.size.width, sebLockedViewController.view.superview.frame.size.height);
    NSMutableArray *constraints = [NSMutableArray new];
    [constraints addObject:[NSLayoutConstraint constraintWithItem:sebLockedViewController.view
                                                        attribute:NSLayoutAttributeCenterX
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:sebLockedViewController.view.superview
                                                        attribute:NSLayoutAttributeCenterX
                                                       multiplier:1.0
                                                         constant:0.0]];
    
    [constraints addObject:[NSLayoutConstraint constraintWithItem:sebLockedViewController.view
                                                        attribute:NSLayoutAttributeCenterY
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:sebLockedViewController.view.superview
                                                        attribute:NSLayoutAttributeCenterY
                                                       multiplier:1.0
                                                         constant:0.0]];
    
    [sebLockedViewController.view.superview addConstraints:constraints];
    
    [coveringWindow makeKeyAndOrderFront:self];
}


- (void) closeLockdownWindows
{
    [sebLockedViewController.view removeFromSuperview];
    [self closeCoveringWindows:self.lockdownWindows];
}


- (void) closeCoveringWindows:(NSMutableArray *)windows
{
    // Close the covering windows
	NSUInteger windowIndex;
	NSUInteger windowCount = [windows count];
    for (windowIndex = 0; windowIndex < windowCount; windowIndex++ )
    {
		[(NSWindow *)[windows objectAtIndex:windowIndex] close];
	}
    [windows removeAllObjects];
}


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


- (void) regainActiveStatus: (id)sender {
	// hide all other applications if not in debug build setting
    // Check if the app is listed in prohibited processes
#ifdef DEBUG
    DDLogInfo(@"Notification:  %@", [sender name]);
#endif

//    if ([[sender name] isEqualToString:@"NSWorkspaceDidLaunchApplicationNotification"]) {
        NSDictionary *userInfo = [sender userInfo];
        if (userInfo) {
            NSRunningApplication *launchedApp = [userInfo objectForKey:NSWorkspaceApplicationKey];
#ifdef DEBUG
            DDLogInfo(@"Activated app localizedName: %@, executableURL: %@", [launchedApp localizedName], [launchedApp executableURL]);
#endif
//            if ([launchedApp isEqual:launchedApplication]) {
//                launchedApplication = nil;
//            }
//            if ([[launchedApp localizedName] isEqualToString:@""]) {
//                [launchedApp forceTerminate];
//            }
        }
//    }
    // Load preferences from the system's user defaults database
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    if (!allowSwitchToThirdPartyApps && ![self.preferencesController preferencesAreOpen]) {
		// if switching to ThirdPartyApps not allowed
        DDLogDebug(@"Regain active status after %@", [sender name]);
#ifndef DEBUG
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        [[NSWorkspace sharedWorkspace] performSelectorOnMainThread:@selector(hideOtherApplications) withObject:NULL waitUntilDone:NO];
//        [self startKioskMode];
#endif
    } else {
        /*/ Save the bundle ID of all currently running apps which are visible in a array
        NSArray *runningApps = [[NSWorkspace sharedWorkspace] runningApplications];
        NSRunningApplication *iterApp;
        NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *bundleId = [bundleInfo objectForKey: @"CFBundleIdentifier"];
        for (iterApp in runningApps)
        {
            BOOL isActive = [iterApp isActive];
            NSString *appBundleID = [iterApp valueForKey:@"bundleIdentifier"];
            if ((appBundleID != nil) & ![appBundleID isEqualToString:bundleId] & ![appBundleID isEqualToString:@"com.apple.Preview"]) {
                //& isActive
                BOOL successfullyHidden = [iterApp hide]; //hide the active app
#ifdef DEBUG
                DDLogInfo(@"Successfully hidden app %@: %@", appBundleID, [NSNumber numberWithBool:successfullyHidden]);
#endif
            }
        }
*/
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
            
            // Check for activated screen sharing if settings demand it
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            if ([launchedAppBundleID isEqualToString:@"com.apple.ScreenSharing"] && ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowScreenSharing"]) {
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"detectedScreenSharing" object:self];
            }
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
    if (launchedApplication) {
        // Yes: We assume it's the app which switched the space and force terminate it!
        DDLogError(@"An app was started and switched the Space. SEB will force terminate it! (app localized name: %@, executable URL: %@)", [launchedApplication localizedName], [launchedApplication executableURL]);
        [launchedApplication forceTerminate];
        launchedApplication = nil;
    }
}


- (void) SEBgotActive: (id)sender {
    DDLogDebug(@"SEB got active");
//    [self startKioskMode];
}


// Method which sets the setting flag for elevating window levels according to the
// setting key allowSwitchToApplications
- (void) setElevateWindowLevels
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    _allowSwitchToApplications = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"];
    if (_allowSwitchToApplications) {
        [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
    } else {
        [preferences setSecureBool:YES forKey:@"org_safeexambrowser_elevateWindowLevels"];
    }
}


- (void) startKioskMode {
	// Switch to kiosk mode by setting the proper presentation options
    // Load preferences from the system's user defaults database
//    [self startKioskModeThirdPartyAppsAllowed:YES];
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    DDLogDebug(@"startKioskMode switchToApplications %hhd", allowSwitchToThirdPartyApps);
    [self startKioskModeThirdPartyAppsAllowed:allowSwitchToThirdPartyApps overrideShowMenuBar:NO];

}


- (void) switchKioskModeAppsAllowed:(BOOL)allowApps overrideShowMenuBar:(BOOL)overrideShowMenuBar {
	// Switch the kiosk mode to either only browser windows or also third party apps allowed:
    // Change presentation options and windows levels without closing/reopening cap background and browser foreground windows
    [self startKioskModeThirdPartyAppsAllowed:allowApps overrideShowMenuBar:overrideShowMenuBar];
    
    // Change window level of cap windows
    CapWindow *capWindow;
    BOOL allowAppsUserDefaultsSetting = [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"];

    for (capWindow in self.capWindows) {
        if (allowApps) {
            [capWindow newSetLevel:NSNormalWindowLevel];
            if (allowAppsUserDefaultsSetting) {
                capWindow.collectionBehavior = NSWindowCollectionBehaviorStationary + NSWindowCollectionBehaviorFullScreenAuxiliary +NSWindowCollectionBehaviorFullScreenDisallowsTiling;
            }
        } else {
            [capWindow newSetLevel:NSMainMenuWindowLevel+2];
        }
    }
    
    // Change window level of all open browser windows
    [self.browserController allBrowserWindowsChangeLevel:allowApps];
}


- (void) startKioskModeThirdPartyAppsAllowed:(BOOL)allowSwitchToThirdPartyApps overrideShowMenuBar:(BOOL)overrideShowMenuBar {
    // Switch to kiosk mode by setting the proper presentation options
    // Load preferences from the system's user defaults database
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL showMenuBar = overrideShowMenuBar || [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showMenuBar"];
//    BOOL enableToolbar = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"];
//    BOOL hideToolbar = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_hideBrowserWindowToolbar"];
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
}


// Clear Pasteboard, but save the current content in case it is a NSString
- (void)clearPasteboardSavingCurrentString
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
    //NSInteger changeCount = [pasteboard clearContents];
    [pasteboard clearContents];
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
    if ([preferences secureBoolForKey:@"org_safeexambrowser_copyBrowserExamKeyToClipboardWhenQuitting"]) {
        NSData *browserExamKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
        unsigned char hashedChars[32];
        [browserExamKey getBytes:hashedChars length:32];
        NSMutableString* browserExamKeyString = [[NSMutableString alloc] init];
        for (int i = 0 ; i < 32 ; ++i) {
            [browserExamKeyString appendFormat: @"%02x", hashedChars[i]];
        }
        [pasteboard writeObjects:[NSArray arrayWithObject:browserExamKeyString]];
    }
}


// Set up and display SEB Dock
- (void) openSEBDock
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"]) {
        
        DDLogDebug(@"SEBController openSEBDock: dock enabled");
        // Initialize the Dock
        self.dockController = [[SEBDockController alloc] init];
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableSebBrowser"]) {
            SEBDockItem *dockItemSEB = [[SEBDockItem alloc] initWithTitle:@"Safe Exam Browser"
                                                                     icon:[NSApp applicationIconImage]
                                                          highlightedIcon:nil
                                                                  toolTip:nil
                                                                     menu:self.browserController.openBrowserWindowsWebViewsMenu
                                                                   target:self
                                                                   action:@selector(buttonPressed)];
            [self.dockController setLeftItems:[NSArray arrayWithObjects:dockItemSEB, nil]];
        }
        
        // Initialize right dock items (controlls and info widgets)
        NSMutableArray *rightDockItems = [NSMutableArray array];
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowQuit"]) {
            SEBDockItem *dockItemShutDown = [[SEBDockItem alloc] initWithTitle:nil
                                                                          icon:[NSImage imageNamed:@"SEBShutDownIcon"]
                                                               highlightedIcon:[NSImage imageNamed:@"SEBShutDownIconHighlighted"]
                                                                       toolTip:NSLocalizedString(@"Quit SEB",nil)
                                                                          menu:nil
                                                                        target:self
                                                                        action:@selector(quitButtonPressed)];
            [rightDockItems addObject:dockItemShutDown];
        }
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableSebBrowser"] &&
            ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamUseStartURL"] ||
            [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamURL"].length > 0)) {
            NSString *restartButtonToolTip = [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamText"];
            if (restartButtonToolTip.length == 0) {
                restartButtonToolTip = NSLocalizedString(@"Restart Exam",nil);
            }
            SEBDockItem *dockItemShutDown = [[SEBDockItem alloc] initWithTitle:nil
                                                                          icon:[NSImage imageNamed:@"SEBRestartIcon"]
                                                               highlightedIcon:[NSImage imageNamed:@"SEBRestartIconHighlighted"]
                                                                       toolTip:restartButtonToolTip
                                                                          menu:nil
                                                                        target:self
                                                                        action:@selector(restartButtonPressed)];
            [rightDockItems addObject:dockItemShutDown];
        }
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableSebBrowser"] &&
            [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showReloadButton"]) {
            SEBDockItem *dockItemShutDown = [[SEBDockItem alloc] initWithTitle:nil
                                                                          icon:[NSImage imageNamed:@"SEBReloadIcon"]
                                                               highlightedIcon:[NSImage imageNamed:@"SEBReloadIconHighlighted"]
                                                                       toolTip:NSLocalizedString(@"Reload Current Page",nil)
                                                                          menu:nil
                                                                        target:self
                                                                        action:@selector(reloadButtonPressed)];
            [rightDockItems addObject:dockItemShutDown];
        }
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTime"]) {
            SEBDockItemTime *dockItemTime = sebDockItemTime;
            [dockItemTime startDisplayingTime];
            
            [rightDockItems addObject:dockItemTime];
        }
        
        // Set right dock items
        
//        [self.dockController setCenterItems:[NSArray arrayWithObjects:dockItemSEB, dockItemShutDown, nil]];
        
        [self.dockController setRightItems:rightDockItems];
        
        // Display the dock
        [self.dockController showDock];

    } else {
        DDLogDebug(@"SEBController openSEBDock: dock disabled");
        if (self.dockController) {
            [self.dockController hideDock];
            self.dockController = nil;
        }
    }
}


- (void) buttonPressed
{
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [self.browserController.mainBrowserWindow makeKeyAndOrderFront:self];
}


- (void) restartButtonPressed
{
    // Get custom (if it was set) or standard restart exam text
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *restartExamText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamText"];
    if (restartExamText.length == 0) {
        restartExamText = NSLocalizedString(@"Restart Exam",nil);
    }

    // Check if restarting is protected with the quit/restart password (and one is set)
    NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamPasswordProtected"] && ![hashedQuitPassword isEqualToString:@""]) {
        // if quit/restart password is set, then restrict quitting
        if ([self showEnterPasswordDialog:NSLocalizedString(@"Enter quit/restart password:",nil) modalForWindow:self.browserController.mainBrowserWindow windowTitle:restartExamText] == SEBEnterPasswordCancel) return;
        NSString *password = [self.enterPassword stringValue];
        
        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
        if ([hashedQuitPassword caseInsensitiveCompare:[keychainManager generateSHAHashString:password]] == NSOrderedSame) {
            // if the correct quit/restart password was entered, restart the exam
            [self.browserController restartDockButtonPressed];
            return;
        } else {
            // Wrong quit password was entered
            NSAlert *newAlert = [NSAlert alertWithMessageText:restartExamText
                                                defaultButton:NSLocalizedString(@"OK", nil)
                                              alternateButton:nil
                                                  otherButton:nil
                                    informativeTextWithFormat:NSLocalizedString(@"Wrong quit/restart password.", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            [newAlert runModal];
            return;
        }
    }
    
    // if no quit password is required, then confirm quitting
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:restartExamText];
    [newAlert setInformativeText:NSLocalizedString(@"Are you sure?", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [newAlert setAlertStyle:NSWarningAlertStyle];
    NSInteger answer = [newAlert runModal];
    switch(answer)
    {
        case NSAlertFirstButtonReturn:
            return; //Cancel: don't restart exam
        default:
        {
            [self.browserController restartDockButtonPressed];
        }
    }
}


- (void) reloadButtonPressed
{
    [self.browserController reloadDockButtonPressed];
}


- (void) quitButtonPressed
{
    // Post a notification that SEB should conditionally quit
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestExitNotification" object:self];
}


- (NSInteger) showEnterPasswordDialog:(NSString *)text modalForWindow:(NSWindow *)window windowTitle:(NSString *)title {
    
    [self.enterPassword setStringValue:@""]; //reset the enterPassword NSSecureTextField
    if (title) enterPasswordDialogWindow.title = title;
    [enterPasswordDialog setStringValue:text];
    
    // If the (main) browser window is full screen, we don't show the dialog as sheet
    if (window && (self.browserController.mainBrowserWindow.isFullScreen || [self.preferencesController preferencesAreOpen])) {
        window = nil;
    }
    
    [NSApp beginSheet: enterPasswordDialogWindow
       modalForWindow: window
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    NSInteger returnCode = [NSApp runModalForWindow: enterPasswordDialogWindow];
    // Dialog is up here.
    [NSApp endSheet: enterPasswordDialogWindow];
    [enterPasswordDialogWindow orderOut: self];
    return returnCode;
}


- (IBAction) okEnterPassword: (id)sender {
    [NSApp stopModalWithCode:SEBEnterPasswordOK];
}


- (IBAction) cancelEnterPassword: (id)sender {
    [NSApp stopModalWithCode:SEBEnterPasswordCancel];
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
    
    [NSApp beginSheet: enterUsernamePasswordDialogWindow
       modalForWindow: window
        modalDelegate: self
       didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo: nil];
}


- (IBAction) okEnterUsernamePassword: (id)sender {
    [NSApp endSheet:enterUsernamePasswordDialogWindow returnCode:SEBEnterPasswordOK];
}


- (IBAction) cancelEnterUsernamePassword: (id)sender {
    [NSApp endSheet:enterUsernamePasswordDialogWindow returnCode:SEBEnterPasswordCancel];
    // Reset the username field (password is always reset whenever the dialog is displayed)
    [usernameTextField setStringValue:@""];
}


- (void) hideEnterUsernamePasswordDialog
{
    [NSApp endSheet:enterUsernamePasswordDialogWindow returnCode:SEBEnterPasswordAborted];
    // Reset the user name field (password is always reset whenever the dialog is displayed)
    [usernameTextField setStringValue:@""];
}


- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    DDLogDebug(@"sheetDidEnd with return code: %ld", (long)returnCode);
    
    [sheet orderOut: self];

    IMP imp = [senderModalDelegate methodForSelector:senderDidEndSelector];
    void (*func)(id, SEL, NSString*, NSString*, NSInteger) = (void *)imp;
    func(senderModalDelegate, senderDidEndSelector, usernameTextField.stringValue, passwordSecureTextField.stringValue, returnCode);
}


- (IBAction) exitSEB:(id)sender {
	// Load quitting preferences from the system's user defaults database
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowQuit"] == YES) {
		// if quitting SEB is allowed
		
        if (![hashedQuitPassword isEqualToString:@""]) {
			// if quit password is set, then restrict quitting
            if ([self showEnterPasswordDialog:NSLocalizedString(@"Enter quit password:",nil)  modalForWindow:self.browserController.mainBrowserWindow windowTitle:@""] == SEBEnterPasswordCancel) return;
            NSString *password = [self.enterPassword stringValue];
			
            SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
            if ([hashedQuitPassword caseInsensitiveCompare:[keychainManager generateSHAHashString:password]] == NSOrderedSame) {
				// if the correct quit password was entered
				quittingMyself = TRUE; //SEB is terminating itself
                [NSApp terminate: nil]; //quit SEB
            } else {
                // Wrong quit password was entered
                NSAlert *newAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Wrong Quit Password", nil)
                                                    defaultButton:NSLocalizedString(@"OK", nil)
                                                  alternateButton:nil
                                                      otherButton:nil
                                        informativeTextWithFormat:NSLocalizedString(@"If you don't enter the correct quit password, then you cannot quit SEB.", nil)];
                [newAlert setAlertStyle:NSWarningAlertStyle];
                [newAlert runModal];
            }
        } else {
        // if no quit password is required, then confirm quitting
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Quit Safe Exam Browser",nil)];
            [newAlert setInformativeText:NSLocalizedString(@"Are you sure you want to quit SEB?", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
            [newAlert setAlertStyle:NSWarningAlertStyle];
            NSInteger answer = [newAlert runModal];
            switch(answer)
            {
                case NSAlertFirstButtonReturn:
                    return; //Cancel: don't quit
                default:
                {
                    if ([self.preferencesController preferencesAreOpen]) {
                        [self.preferencesController quitSEB:self];
                    } else {
                        quittingMyself = TRUE; //SEB is terminating itself
                        [NSApp terminate: nil]; //quit SEB
                    }
                }
            }
        }
    } 
}


- (IBAction) openPreferences:(id)sender {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"]) {
        if (floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_7) {
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Preferences Window Not Available on OS X 10.7", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"On OS X 10.7 SEB can only be used as an exam client. Run SEB on OS X 10.8 or higher to create a .seb configuration file to configure this SEB client as well.", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            [newAlert runModal];
            return;
        }
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        if (![self.preferencesController preferencesAreOpen]) {
            // Load admin password from the system's user defaults database
            NSString *hashedAdminPW = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
            if (![hashedAdminPW isEqualToString:@""]) {
                // If admin password is set, then restrict access to the preferences window
                if ([self showEnterPasswordDialog:NSLocalizedString(@"Enter administrator password:",nil)  modalForWindow:self.browserController.mainBrowserWindow windowTitle:@""] == SEBEnterPasswordCancel) return;
                NSString *password = [self.enterPassword stringValue];
                SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
                if ([hashedAdminPW caseInsensitiveCompare:[keychainManager generateSHAHashString:password]] != NSOrderedSame) {
                    //if hash of entered password is not equal to the one in preferences
                    // Wrong admin password was entered
                    NSAlert *newAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Wrong Admin Password", nil)
                                                        defaultButton:NSLocalizedString(@"OK", nil)
                                                      alternateButton:nil                                                      otherButton:nil
                                            informativeTextWithFormat:NSLocalizedString(@"If you don't enter the correct SEB administrator password, then you cannot open preferences.", nil)];
                    [newAlert setAlertStyle:NSWarningAlertStyle];
                    [newAlert runModal];

                    return;
                }
            }
            // Switch the kiosk mode temporary off and override settings for menu bar: Show it while prefs are open
            [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
            [self switchKioskModeAppsAllowed:YES overrideShowMenuBar:YES];
            // Close the black background covering windows
            [self closeCapWindows];

            // Show preferences window
            [self.preferencesController openPreferencesWindow];
            
            // Show the Config menu (in menu bar)
            [configMenu setHidden:NO];
        } else {
            // Show preferences window
            DDLogDebug(@"openPreferences: Preferences already open, just show Window");
            [self.preferencesController showPreferencesWindow:nil];
        }
    }
}


- (void)preferencesClosed:(NSNotification *)notification
{
    [self performAfterPreferencesClosedActions];

    // Reinforce kiosk mode after a delay, so eventually visible fullscreen apps get hidden again
    [self performSelector:@selector(requestedReinforceKioskMode:) withObject: nil afterDelay: 1];
}


- (void)performAfterPreferencesClosedActions
{
    // Hide the Config menu (in menu bar)
    [configMenu setHidden:YES];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    DDLogInfo(@"Preferences window closed, reopening cap windows.");
    
    // Open new covering background windows on all currently available screens
    [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
    [self coverScreens];
    
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [self.browserController.mainBrowserWindow makeKeyAndOrderFront:self];
    
    // Switch the kiosk mode on again
    [self setElevateWindowLevels];
    
//    [self startKioskMode];
    BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    [self switchKioskModeAppsAllowed:allowSwitchToThirdPartyApps overrideShowMenuBar:NO];

    // Update URL filter flags and rules
    [[SEBURLFilter sharedSEBURLFilter] updateFilterRules];    
    // Update URL filter ignore rules
    [[SEBURLFilter sharedSEBURLFilter] updateIgnoreRuleList];
}


- (void)preferencesClosedRestartSEB:(NSNotification *)notification
{
    [self performAfterPreferencesClosedActions];
    
    [self requestedRestart:nil];

    // Reinforce kiosk mode after a delay, so eventually visible fullscreen apps get hidden again
    [self performSelector:@selector(requestedReinforceKioskMode:) withObject: nil afterDelay: 1];
}


- (void)requestedQuitWPwd:(NSNotification *)notification
{
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Quit Safe Exam Browser",nil)];
    [newAlert setInformativeText:NSLocalizedString(@"Are you sure you want to quit SEB?", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
    [newAlert setAlertStyle:NSWarningAlertStyle];
    NSInteger answer = [newAlert runModal];
    switch(answer)
    {
        case NSAlertFirstButtonReturn:
            return; //Cancel: don't quit
        default:
        {
            if ([self.preferencesController preferencesAreOpen]) {
                [self.preferencesController quitSEB:self];
            } else {
                quittingMyself = TRUE; //SEB is terminating itself
                [NSApp terminate: nil]; //quit SEB
            }
        }
    }
}


- (void)requestedQuit:(NSNotification *)notification
{
    quittingMyself = TRUE; //SEB is terminating itself
    [NSApp terminate: nil]; //quit SEB
}


- (void)requestedRestart:(NSNotification *)notification
{
    DDLogInfo(@"---------- RESTARTING SEB SESSION -------------");

    // If AirPlay isn't allowed in settings, kill the AirPlay agent
    // to stop a possibly running AirPlay connection
    [self conditionallyTerminateAirPlay];
    
    [self conditionallyStartWindowWatcher];

    // Clear Pasteboard
    [self clearPasteboardSavingCurrentString];
    
    // Clear private pasteboard
    self.browserController.privatePasteboardItems = [NSArray array];
    
    // Check if running on minimal macOS version
    [self checkMinMacOSVersion];
    
    // Check if launched SEB is placed ("installed") in an Applications folder
    [self installedInApplicationsFolder];
    
    // Adjust screen shot blocking
    [self.systemManager adjustSC];

    // Close all browser windows (documents)
    [[NSDocumentController sharedDocumentController] closeAllDocumentsWithDelegate:self
                                                               didCloseAllSelector:@selector(documentController:didCloseAll:contextInfo:)
                                                                       contextInfo: nil];
    // Re-Initialize file logger if logging enabled
    [self initializeLogger];
    
    // Update URL filter flags and rules
    [[SEBURLFilter sharedSEBURLFilter] updateFilterRules];
    // Update URL filter ignore rules
    [[SEBURLFilter sharedSEBURLFilter] updateIgnoreRuleList];
    
    // Check for command key being held down
    while ([self commandKeyPressed]) {
        DDLogError(@"Command key was pressed and forbidden, retest");
    }
    
    // Set kiosk/presentation mode in case it changed
    [self setElevateWindowLevels];
    [self startKioskMode];
    
    // Check if the Force Quit window is open
    [self forceQuitWindowCheck];
    
    // Reset SEB Browser
    [self.browserController resetBrowser];
    
    // Reopen SEB Dock
    [self openSEBDock];
    self.browserController.dockController = self.dockController;

    // Reopen main browser window and load start URL
    [self.browserController openMainBrowserWindow];

    // Adjust screen locking
    [self adjustScreenLocking:self];
    
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
}


- (void)documentController:(NSDocumentController *)docController  didCloseAll: (BOOL)didCloseAll contextInfo:(void *)contextInfo
{
    DDLogDebug(@"documentController: %@ didCloseAll: %hhd contextInfo: %@", docController, didCloseAll, contextInfo);
}


- (void)requestedReinforceKioskMode:(NSNotification *)notification
{
    [self reinforceKioskMode];
}

- (void)reinforceKioskMode
{
    if (![self.preferencesController preferencesAreOpen]) {
        DDLogDebug(@"Reinforcing the kiosk mode was requested");
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
        
//            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        
        BOOL allowSwitchToThirdPartyApps = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"];
        [self switchKioskModeAppsAllowed:allowSwitchToThirdPartyApps overrideShowMenuBar:NO];
        
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        [self.browserController.mainBrowserWindow makeKeyAndOrderFront:self];
    }
}


- (void) requestedShowAbout:(NSNotification *)notification
{
    [self showAbout:self];
}

- (IBAction)showAbout:(id)sender
{
    [aboutWindow setStyleMask:NSBorderlessWindowMask];
	[aboutWindow center];
	//[aboutWindow orderFront:self];
    //[aboutWindow setLevel:NSMainMenuWindowLevel];
    [[NSApplication sharedApplication] runModalForWindow:aboutWindow];
}


- (void) requestedShowHelp:(NSNotification *)notification
{
    [self showHelp:self];
}

- (IBAction) showHelp: (id)sender
{
    // Open new browser window containing WebView and show it
    SEBWebView *newWebView = [self.browserController openAndShowWebView];
    // Load manual page URL in new browser window
    NSString *urlText = @"http://www.safeexambrowser.org/macosx";
	[[newWebView mainFrame] loadRequest:
     [NSURLRequest requestWithURL:[NSURL URLWithString:urlText]]];
}


- (void) closeDocument:(id)document
{
    [document close];
}

- (void) switchPluginsOn:(NSNotification *)notification
{
#ifndef __i386__        // Plugins can't be switched on in the 32-bit Intel build
    [[self.webView preferences] setPlugInsEnabled:YES];
#endif
}


// Handler called when user switch happens
- (void) switchHandler:(NSNotification*) notification
{
    if ([[notification name] isEqualToString:
         NSWorkspaceSessionDidResignActiveNotification])
    {
        // Set standard message string
        [sebLockedViewController setLockdownAlertMessage:nil];
        
        if (!sebLockedViewController.resignActiveLogString) {
            sebLockedViewController.resignActiveLogString = [[NSAttributedString alloc] initWithString:@""];
        }
        self.didResignActiveTime = [NSDate date];
        DDLogError(@"SessionDidResignActive: User switch / switch to login window detected!");
        [self openLockdownWindows];
        
        // Add log string for resign active
        [sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"User switch / switch to login window detected", nil)] withTime:self.didResignActiveTime];
        
    }
    else if ([[notification name] isEqualToString:
              NSWorkspaceSessionDidBecomeActiveNotification])
    {
        // Perform activation tasks here.
        
        DDLogError(@"SessionDidBecomeActive: Switched back after user switch / login window!");
        
        // Add log string for becoming active
        self.didBecomeActiveTime = [NSDate date];
        [sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Switched back after user switch / login window", nil)] withTime:self.didBecomeActiveTime];
        
        // Calculate time difference between session resigning active and becoming active again
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [calendar components:NSMinuteCalendarUnit | NSSecondCalendarUnit
                                                   fromDate:self.didResignActiveTime
                                                     toDate:self.didBecomeActiveTime
                                                    options:false];
        [sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", [NSString stringWithFormat:NSLocalizedString(@"  SEB session was inactive for %ld:%.2ld (minutes:seconds)", nil), components.minute, components.second]] withTime:nil];
    }
    else if ([[notification name] isEqualToString:
                @"detectedScreenSharing"])
    {
        // Set custom alert message string
        [sebLockedViewController setLockdownAlertMessage:NSLocalizedString(@"Screen sharing detected. SEB can only be unlocked by entering the restart/quit password, which usually exam supervision/support knows..\n\nTo avoid that SEB locks itself during an exam when it detects that screen sharing started, it's best to switch off 'Screen Sharing' and 'Remote Management' in System Preferences/Sharing.", nil)];
        
        if (!sebLockedViewController.resignActiveLogString) {
            sebLockedViewController.resignActiveLogString = [[NSAttributedString alloc] initWithString:@""];
        }
        self.didResignActiveTime = [NSDate date];
        DDLogError(@"Screen sharing was activated!");
        [self openLockdownWindows];
        
        // Add log string for resign active
        [sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Screen sharing was activated", nil)] withTime:self.didResignActiveTime];
    }
}


- (void) openInfoHUD:(NSString *)lockedTimeInfo
{
    [informationHUDLabel setStringValue:lockedTimeInfo];
    //[informationHUD center];
    NSArray *screens = [NSScreen screens];	// get all available screens
    NSScreen *mainScreen = screens[0];
    
    NSPoint topLeftPoint;
    topLeftPoint.x = mainScreen.frame.origin.x + mainScreen.frame.size.width - informationHUD.frame.size.width - 22;
    topLeftPoint.y = mainScreen.frame.origin.y + mainScreen.frame.size.height - 44;
    [informationHUD setFrameTopLeftPoint:topLeftPoint];
    
    informationHUD.becomesKeyOnlyIfNeeded = YES;
    [informationHUD setLevel:NSModalPanelWindowLevel];
    DDLogDebug(@"Opening info HUD: %@", informationHUD);
    [informationHUD makeKeyAndOrderFront:nil];

}


#pragma mark Delegates

// Called when SEB should be terminated
- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender {
	if (quittingMyself) {
		return NSTerminateNow; //SEB wants to quit, ok, so it should happen
	} else { //SEB should be terminated externally(!)
		return NSTerminateCancel; //this we can't allow, sorry...
	}
}


// Called just before SEB will be terminated
- (void) applicationWillTerminate:(NSNotification *)aNotification
{
    if (_enforceMinMacOSVersion != SEBMinMacOSVersionSupported) {
        NSAlert *newAlert = [[NSAlert alloc] init];
        [newAlert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Not Running Minimal macOS Version!", nil)]];
        [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Current SEB settings require at least %@, but your system is older. SEB will quit!", nil), [[SEBUIUserDefaultsController sharedSEBUIUserDefaultsController] org_safeexambrowser_SEB_minMacOSVersions][_enforceMinMacOSVersion]]];
        [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [newAlert setAlertStyle:NSCriticalAlertStyle];
        [newAlert runModal];
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
        NSAlert *newAlert = [[NSAlert alloc] init];
        [newAlert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"SEB Not in %@ Folder!", nil), localizedApplicationDirectoryName]];
        [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"SEB has to be placed in the %@ folder in order for all features to work correctly. Move the 'Safe Exam Browser' app to your %@ folder and make sure that you don't have any other versions of SEB installed on your system. SEB will quit now.", nil), localizedApplicationDirectoryName, localizedAndInternalApplicationDirectoryName]];
        [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [newAlert setAlertStyle:NSCriticalAlertStyle];
        [newAlert runModal];
    } else if (_cmdKeyDown) {
        // Show alert that keys were hold while starting SEB
        NSAlert *newAlert = [[NSAlert alloc] init];
        [newAlert setMessageText:NSLocalizedString(@"Holding Command Key Not Allowed!", nil)];
        [newAlert setInformativeText:NSLocalizedString(@"Holding the Command key down while starting SEB is not allowed. Restart SEB without holding any keys.", nil)];
        [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [newAlert setAlertStyle:NSCriticalAlertStyle];
        [newAlert runModal];
    }
    
    BOOL success = [self.systemManager restoreSC];
    DDLogDebug(@"Success of restoring SC: %hhd", success);
    
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
    DDLogInfo(@"---------- EXITING SEB - ENDING SESSION -------------");
}


// Prevent an untitled document to be opened at application launch
- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender {
    DDLogDebug(@"Invoked applicationShouldOpenUntitledFile with answer NO!");
    return NO;
}

/*- (void)windowDidResignKey:(NSNotification *)notification {
	[NSApp activateIgnoringOtherApps: YES];
	[self.browserController.browserWindow 
	 makeKeyAndOrderFront:self];
	#ifdef DEBUG
	DDLogDebug(@"[self.browserController.browserWindow makeKeyAndOrderFront]");
	NSBeep();
	#endif
	
}
*/


// Called when currentPresentationOptions change
// Called when "isActive" propery of [NSRunningApplication currentApplication] changes

- (void) observeValueForKeyPath:(NSString *)keyPath
					  ofObject:id
                        change:(NSDictionary *)change
                       context:(void *)context
{
    DDLogInfo(@"Value for key path %@ changed: %@", keyPath, change);

    // If the startKioskMode method changed presentation options, then we don't do nothing here
    if ([keyPath isEqual:@"currentSystemPresentationOptions"]) {
        if ([[MyGlobals sharedMyGlobals] startKioskChangedPresentationOptions]) {
            [[MyGlobals sharedMyGlobals] setStartKioskChangedPresentationOptions:NO];
            return;
        }

		// Current Presentation Options changed, so make SEB active and reset them
        // Load preferences from the system's user defaults database
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
        DDLogInfo(@"currentSystemPresentationOptions changed!");
        // If plugins are enabled and there is a Flash view in the webview ...
        if ([[self.webView preferences] arePlugInsEnabled]) {
            NSView* flashView = [self.browserController.mainBrowserWindow findFlashViewInView:webView];
            if (flashView) {
                if (!allowSwitchToThirdPartyApps || ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowFlashFullscreen"]) {
                    // and either third party Apps or Flash fullscreen is allowed
                    //... then we switch plugins off and on again to prevent 
                    //the security risk Flash full screen video
#ifndef __i386__        // Plugins can't be switched on in the 32-bit Intel build
                    [[self.webView preferences] setPlugInsEnabled:NO];
                    [[self.webView preferences] setPlugInsEnabled:YES];
#endif
                } else {
                    //or we set the flag that Flash tried to switch presentation options
                    [[MyGlobals sharedMyGlobals] setFlashChangedPresentationOptions:YES];
                }
            }
        }
        //[self startKioskMode];
        //We don't reset the browser window size and position anymore
        //[(BrowserWindow*)self.browserController.browserWindow setCalculatedFrame];
        if (!allowSwitchToThirdPartyApps && ![self.preferencesController preferencesAreOpen] && !launchedApplication) {
            // If third party Apps are not allowed, we switch back to SEB
            DDLogInfo(@"Switched back to SEB after currentSystemPresentationOptions changed!");
            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];

            [self regainActiveStatus:nil];
            //[self.browserController.browserWindow setFrame:[[self.browserController.browserWindow screen] frame] display:YES];
        }
    } else {
        if ([keyPath isEqual:@"isActive"]) {
            DDLogWarn(@"isActive property of SEB changed!");
            [self regainActiveStatus:nil];
//            [self appLaunch:nil];
        }
    }
}


@end
