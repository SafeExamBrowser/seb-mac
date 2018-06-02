//
//  SEBController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.04.10.
//  Copyright (c) 2010-2018 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2018 Daniel R. Schneider, ETH Zurich, Educational Development
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
#import "NSScreen+SEBScreen.h"
#import "NSWindow+SEBWindow.h"
#import "SEBConfigFileManager.h"
#import "NSRunningApplication+SEB.h"

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
bool insideMatrix(void);

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
    if (!_openingSettings) {
        _openingSettings = true;
        DDLogDebug(@"%s Open file: %@", __FUNCTION__, filename);
        
        NSURL *sebFileURL = [NSURL fileURLWithPath:filename];
        
        DDLogInfo(@"Open file event: Loading .seb settings file with URL %@",sebFileURL);
        
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        
        // Check if preferences window is open
        if ([self.preferencesController preferencesAreOpen]) {
            
            /// Open settings file in preferences window for editing
            
            [self.preferencesController openSEBPrefsAtURL:sebFileURL];
            _openingSettings = false;
            
        } else {
            
            /// Open settings file for exam/reconfiguring client
            
            // Check if SEB is in exam mode = private UserDefauls are switched on
            if (NSUserDefaults.userDefaultsPrivate) {
                NSAlert *modalAlert = [self newAlert];
                [modalAlert setMessageText:NSLocalizedString(@"Loading New SEB Settings Not Allowed!", nil)];
                [modalAlert setInformativeText:NSLocalizedString(@"SEB is already running in exam mode and it is not allowed to interrupt this by starting another exam. Finish the exam and quit SEB before starting another exam.", nil)];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [modalAlert setAlertStyle:NSCriticalAlertStyle];
                [modalAlert runModal];
                [self removeAlertWindow:modalAlert.window];
                _openingSettings = false;
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
                
                // SEB finished starting up, reset the flag for starting up
                _startingUp = false;
                _openingSettings = false;

                [self requestedRestart:nil];
            } else {
                // If SEB was just started (by opening a config file)
                if (_startingUp) {
                    // we quit, as decrypting the config wasn't successful
                    DDLogError(@"SEB was started with a SEB Config File as argument, but decrypting this configuration failed: Terminating.");
                    quittingMyself = TRUE; // SEB is terminating itself
                    [NSApp terminate: nil]; // Quit SEB
                } else {
                    // otherwise, if decrypting new settings wasn't successfull, we have to restore the path to the old settings
                    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:currentConfigPath];
                }
                _openingSettings = false;
            }
        }
    }
    
    return YES;
}


- (void)handleGetURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url && !_openingSettings) {
        // If we have any URL, we try to download and open (conditionally) a .seb file
        // hopefully linked by this URL (also supporting redirections and authentification)
        _openingSettings = true;
        DDLogInfo(@"Get URL event: Loading .seb settings file with URL %@", urlString);
        [self.browserController openConfigFromSEBURL:url];
    }
}


#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) {
        _modalAlertWindows = [NSMutableArray new];
        _startingUp = true;
        self.systemManager = [[SEBSystemManager alloc] init];

        // Initialize console loggers
#ifdef DEBUG
        // We show log messages only in Console.app and the Xcode console in debug mode
        [DDLog addLogger:[DDASLLogger sharedInstance]];
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
#endif

        [self initializeTemporaryLogger];
        
        [[MyGlobals sharedMyGlobals] setPreferencesReset:NO];
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
        [MyGlobals sharedMyGlobals].reconfiguredWhileStarting = NO;
        
        if (!_inactiveScreenWindows) {
            _inactiveScreenWindows = [NSMutableArray new];
        }

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

        // Check if there is a SebClientSettings.seb file saved in the preferences directory
        SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
        [configFileManager reconfigureClientWithSebClientSettings];

        // Initialize file logger if it's enabled in settings
        [self initializeLogger];
        
        // Get default WebKit browser User Agent and create
        // default SEB User Agent
        NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
        NSString *defaultUserAgent = [[WebView new] userAgentForURL:[NSURL URLWithString:urlText]];
        [self.browserController createSEBUserAgentFromDefaultAgent:defaultUserAgent];
        DDLogError(@"Default browser user agent string: %@", [[MyGlobals sharedMyGlobals] valueForKey:@"defaultUserAgent"]);
        
        // Update URL filter flags and rules
        [[SEBURLFilter sharedSEBURLFilter] updateFilterRules];
        // Update URL filter ignore rules
        [[SEBURLFilter sharedSEBURLFilter] updateIgnoreRuleList];
        
        // Regardless if switching to third party applications is allowed in current settings,
        // we need to first open the background cover windows with standard window levels
        [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
        
        // Switch off display mirroring and find main active screen according to settings
        [self conditionallyTerminateDisplayMirroring];
        
        // Cache current settings for Siri and dictation
        [_systemManager cacheCurrentSystemSettings];
        
        // Switch off Siri and dictation if not allowed in settings
        [self conditionallyDisableSpeechInput];
    }
    return self;
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


- (NSAlert *) newAlert
{
    NSAlert *newAlert = [[NSAlert alloc] init];
    DDLogDebug(@"Adding modal alert window %@", newAlert.window);
    [_modalAlertWindows addObject:newAlert.window];
    if (aboutWindow.isVisible) {
        [self closeAboutWindow];
    }
    return newAlert;
}


- (void) removeAlertWindow:(NSWindow *)alertWindow
{
    DDLogDebug(@"All modal alert windows %@", _modalAlertWindows);
    DDLogDebug(@"Removing modal alert window %@", alertWindow);
    [_modalAlertWindows removeObject:alertWindow];
    DDLogDebug(@"All modal alert windows after removing: %@", _modalAlertWindows);
}


- (void)showModalQuitAlertTitle:(NSString *)title text:(NSString *)text
{
        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:title];
        [modalAlert setInformativeText:text];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
        [modalAlert setAlertStyle:NSCriticalAlertStyle];
        [modalAlert runModal];
        [self removeAlertWindow:modalAlert.window];
}

- (void)awakeFromNib
{
    [self.systemManager preventSC];
    
    // Flag initializing
	quittingMyself = FALSE; //flag to know if quit application was called externally

    // Terminate invisibly running applications
    if ([NSRunningApplication respondsToSelector:@selector(terminateAutomaticallyTerminableApplications)]) {
        [NSRunningApplication terminateAutomaticallyTerminableApplications];
    }

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

    // Set up and open SEB Dock
    [self openSEBDock];
    self.browserController.dockController = self.dockController;
    
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

    _runningProhibitedProcesses = [NSMutableArray new];
    _terminatedProcessesExecutableURLs = [NSMutableArray new];
    [self windowWatcher];

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
                    NSAlert *modalAlert = [self newAlert];
                    [modalAlert setMessageText:NSLocalizedString(@"Virtual Machine Detected!", nil)];
                    [modalAlert setInformativeText:NSLocalizedString(@"You are not allowed to run SEB inside a virtual machine!", nil)];
                    [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
                    [modalAlert setAlertStyle:NSCriticalAlertStyle];
                    [modalAlert runModal];
                    [self removeAlertWindow:modalAlert.window];
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
    DDLogDebug(@"%s", __FUNCTION__);

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

    CGEventMask mask = CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventLeftMouseUp);
    
    CFMachPortRef leftMouseEventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, mask, leftMouseTapCallback, NULL);
    
    if (leftMouseEventTap) {
        CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, leftMouseEventTap, 0);
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
        CGEventTapEnable(leftMouseEventTap, true);
    }

    [self startProcessWatcher];
    [self startWindowWatcher];

    if (!_openingSettings)
    {
        // Get all running processes, including daemons
        NSArray *allRunningProcesses = [self getProcessArray];
        DDLogInfo(@"There are %lu running BSD processes: \n%@", (unsigned long)allRunningProcesses.count, allRunningProcesses);

        // Check for activated screen sharing if settings demand it
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        allowScreenSharing = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowScreenSharing"];
        allowSiri = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSiri"];
        allowDictation = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDictation"];

        if (!allowScreenSharing &&
            ([allRunningProcesses containsObject:screenSharingAgent] ||
             [allRunningProcesses containsObject:AppleVNCAgent] ||
             [allRunningProcesses containsObject:ARDAgent]))
        {
            // Screen sharing is active
            DDLogError(@"Screen Sharing Detected, SEB will quit");
            [self showModalQuitAlertTitle:NSLocalizedString(@"Screen Sharing Detected!", nil)
                                     text:[NSString stringWithFormat:@"%@\n\n%@",
                                           NSLocalizedString(@"You are not allowed to have screen sharing active while running SEB. Restart SEB after switching screen sharing off.", nil),
                                           NSLocalizedString(@"To avoid that SEB locks itself during an exam when it detects that screen sharing started, it's best to switch off 'Screen Sharing' and 'Remote Management' in System Preferences/Sharing and 'Back to My Mac' in System Preferences/iCloud. You can also ask your network administrators to block ports used for the VNC protocol.", nil)]];
            quittingMyself = TRUE; //SEB is terminating itself
            [NSApp terminate: nil]; //quit SEB
        }

        if (!allowSiri &&
            [allRunningProcesses containsObject:SiriService] &&
            [[preferences valueForDefaultsDomain:SiriDefaultsDomain key:SiriDefaultsKey] boolValue])
        {
            // Siri is active
            DDLogError(@"Siri Detected, SEB will quit");
            [self showModalQuitAlertTitle:NSLocalizedString(@"Siri Detected!", nil)
                                     text:NSLocalizedString(@"You are not allowed to have Siri enabled while running SEB. Restart SEB after switching Siri off in System Preferences/Siri.", nil)];
            quittingMyself = TRUE; //SEB is terminating itself
            [NSApp terminate: nil]; //quit SEB
        }

        if (!allowDictation &&
            [allRunningProcesses containsObject:DictationProcess] &&
            ([[preferences valueForDefaultsDomain:DictationDefaultsDomain key:DictationDefaultsKey] boolValue] ||
             [[preferences valueForDefaultsDomain:AppleDictationDefaultsDomain key:AppleDictationDefaultsKey] integerValue] != 0))
        {
            // Dictation is active
            DDLogError(@"Dictation Detected, SEB will quit");
            [self showModalQuitAlertTitle:NSLocalizedString(@"Dictation Detected!", nil)
                                     text:NSLocalizedString(@"You are not allowed to have dictation enabled while running SEB. Restart SEB after switching dictation off in System Preferences/Keyboard/Dictation.", nil)];
            quittingMyself = TRUE; //SEB is terminating itself
            [NSApp terminate: nil]; //quit SEB
        }

        // SEB finished starting up, reset the flag for starting up
        _startingUp = false;

        // Set up SEB Browser

        self.browserController.reinforceKioskModeRequested = YES;

        // Open the main browser window
        DDLogDebug(@"%s openMainBrowserWindow", __FUNCTION__);
        
        [self.browserController openMainBrowserWindow];

        // Persist start URL of a "secure" exam
        if ([preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length != 0) {
            currentExamStartURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
            [self.sebLockedViewController addLockedExam:currentExamStartURL];
        } else {
            currentExamStartURL = nil;
        }
    }
    
    [self performSelector:@selector(performAfterStartActions:) withObject: nil afterDelay: 2];
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
    
    //        uint32_t autoActivationSetting = CTFontManagerGetAutoActivationSetting((__bridge CFStringRef)@"com.apple.WebKit");
    //        CTFontManagerSetAutoActivationSetting((__bridge CFStringRef)@"com.apple.WebKit", kCTFontManagerAutoActivationEnabled);
    //        autoActivationSetting = CTFontManagerGetAutoActivationSetting((__bridge CFStringRef)@"com.apple.WebKit");
    
//    uint32_t autoActivationSetting = CTFontManagerGetAutoActivationSetting((__bridge CFStringRef)[[NSBundle mainBundle] bundleIdentifier]);
//    CTFontManagerSetAutoActivationSetting((__bridge CFStringRef)[[NSBundle mainBundle] bundleIdentifier], kCTFontManagerAutoActivationEnabled);
//    autoActivationSetting = CTFontManagerGetAutoActivationSetting((__bridge CFStringRef)[[NSBundle mainBundle] bundleIdentifier]);
//
//    NSFontManager *fontManager = [NSFontManager sharedFontManager];
//    NSArray *availableFonts = [fontManager availableFonts];
//    NSArray *availableFontFamilies = [fontManager availableFontFamilies];
//    DDLogDebug(@"Available fonts: %@", availableFonts);
//    DDLogDebug(@"Available font families: %@", availableFontFamilies);
//    CTFontRef newFont = CTFontCreateWithNameAndOptions((__bridge CFStringRef)@"STHeiti", 12.0, nil, kCTFontOptionsDefault); //("Osaka" as CFString, 12.0, nil, CTFontOptions.preventAutoActivation)
//    availableFonts = [fontManager availableFonts];
//    availableFontFamilies = [fontManager availableFontFamilies];
//    DDLogDebug(@"New font: %@", newFont);
//    DDLogDebug(@"Available fonts: %@", availableFonts);
//    DDLogDebug(@"Available font families: %@", availableFontFamilies);
    
    if ([MyGlobals sharedMyGlobals].reconfiguredWhileStarting) {
        // Show alert that SEB was reconfigured
            NSAlert *modalAlert = [self newAlert];
            [modalAlert setMessageText:NSLocalizedString(@"SEB Re-Configured", nil)];
            [modalAlert setInformativeText:NSLocalizedString(@"New settings have been saved, they will be used when you start SEB next time again. Do you want to start working with SEB or quit for now?", nil)];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Start", nil)];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
            NSInteger answer = [modalAlert runModal];
            [self removeAlertWindow:modalAlert.window];
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


- (void)presentPreferencesCorruptedError
{
    DDLogError(@"Local SEB Settings Have Been Reset");
    
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    NSAlert *modalAlert = [self newAlert];
    
    [modalAlert setMessageText:NSLocalizedString(@"Local SEB Settings Have Been Reset", nil)];
    [modalAlert setInformativeText:NSLocalizedString(@"Local preferences were created by an incompatible SEB version, damaged or manipulated. They have been reset to the default settings. Ask your exam supporter to re-configure SEB correctly.", nil)];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [modalAlert setAlertStyle:NSCriticalAlertStyle];
    [modalAlert runModal];
    [self removeAlertWindow:modalAlert.window];
    
    DDLogInfo(@"Dismissed alert for local SEB settings have been reset");
}


// Initializes a temporary logger unconditionally with the Debug log level
// and the standard log file path, so SEB can log startup events before
// settings are initialized
- (void) initializeTemporaryLogger
{
    DDLogFileManagerDefault* logFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:nil];
    _myLogger = [[DDFileLogger alloc] initWithLogFileManager:logFileManager];
    _myLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    _myLogger.logFileManager.maximumNumberOfLogFiles = 7; // keep logs for 7 days
    [DDLog addLogger:_myLogger];
    
    DDLogError(@"---------- STARTING UP SEB - INITIALIZE SETTINGS -------------");
    DDLogError(@"(log after start up is finished may continue in another file, according to current settings)");
    NSString *localHostname = (NSString *)CFBridgingRelease(SCDynamicStoreCopyLocalHostName(NULL));
    NSString *computerName = (NSString *)CFBridgingRelease(SCDynamicStoreCopyComputerName(NULL, NULL));
    NSString *userName = NSUserName();
    NSString *fullUserName = NSFullUserName();
    NSString *displayName = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleDisplayName"];
    NSString *versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"];
    NSString *bundleID = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleIdentifier"];
    NSString *bundleExecutable = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleExecutable"];
    DDLogError(@"%@ Version %@ (Build %@)", displayName, versionString, buildNumber);
    DDLogError(@"Bundle ID: %@, executable: %@", bundleID, bundleExecutable);
    
    DDLogInfo(@"Local hostname: %@", localHostname);
    DDLogInfo(@"Computer name: %@", computerName);
    DDLogInfo(@"User name: %@", userName);
    DDLogInfo(@"Full user name: %@", fullUserName);
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
        
        DDLogError(@"---------- INITIALIZING SEB - STARTING SESSION -------------");
        NSString *localHostname = (NSString *)CFBridgingRelease(SCDynamicStoreCopyLocalHostName(NULL));
        NSString *computerName = (NSString *)CFBridgingRelease(SCDynamicStoreCopyComputerName(NULL, NULL));
        NSString *userName = NSUserName();
        NSString *fullUserName = NSFullUserName();
        
        // To Do: Find out domain of the current host address
        // This has to be processed asynchronously with GCD
        //        NSHost *host;
        //        host = [NSHost currentHost];
        
        NSString *displayName = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleDisplayName"];
        NSString *versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
        NSString *buildNumber = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"];
        NSString *bundleID = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleIdentifier"];
        NSString *bundleExecutable = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleExecutable"];
        DDLogError(@"%@ Version %@ (Build %@)", displayName, versionString, buildNumber);
        DDLogError(@"Bundle ID: %@, executable: %@", bundleID, bundleExecutable);
        
        DDLogInfo(@"Local hostname: %@", localHostname);
        DDLogInfo(@"Computer name: %@", computerName);
        DDLogInfo(@"User name: %@", userName);
        DDLogInfo(@"Full user name: %@", fullUserName);
    }
}


#pragma mark Process Monitoring

- (NSArray *) getProcessArray {
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


#pragma mark Window/Panel Monitoring

dispatch_source_t CreateDispatchTimer(uint64_t interval, uint64_t leeway, dispatch_queue_t queue, dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}


// Start the process watcher if it's not yet running
- (void)startProcessWatcher
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (!_processWatchTimer) {
        _processWatchTimer = CreateDispatchTimer(0.25 * NSEC_PER_SEC, (0.25 * NSEC_PER_SEC) / 10, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self processWatcher];
        });
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
    
    NSDate *timeProcessCheckBeforeSIGSTOP = lastTimeProcessCheck;
    if (detectSIGSTOP && -[timeProcessCheckBeforeSIGSTOP timeIntervalSinceNow] > 3) {
        DDLogError(@"Detected SIGSTOP! SEB was stopped for %f seconds", -[timeProcessCheckBeforeSIGSTOP timeIntervalSinceNow]);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!_SIGSTOPDetected) {
                _SIGSTOPDetected = true;
                self.didResignActiveTime = timeProcessCheckBeforeSIGSTOP;
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"detectedSIGSTOP" object:self];
            }
        });
    }
    
    // Check if not allowed/prohibited processes were activated
    // Get all running processes, including daemons
    NSArray *allRunningProcesses = [self getProcessArray];
    self.runningProcesses = allRunningProcesses;
    
    // Check for font download process
    if ([allRunningProcesses containsObject:fontRegistryUIAgent]) {
        if (!_allowSwitchToApplications && !fontRegistryUIAgentDisplayed) {
            fontRegistryUIAgentDisplayed = true;
            DDLogWarn(@"%@ is running, and most likely opened dialog to ask user if a font used on the current webpage should be downloaded or skipped. SEB is sending an Event Tap for the key Return (Carriage Return) to close that dialog (invoke default button Skip)", fontRegistryUIAgent);
            CGEventRef event = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)36, true);
            CGEventPost(kCGSessionEventTap, event);
            CFRelease(event);
        }
    } else {
        if (fontRegistryUIAgentDisplayed) {
            fontRegistryUIAgentDisplayed = false;
            DDLogWarn(@"%@ stopped running", fontRegistryUIAgent);
        }
    }
    lastTimeProcessCheck = [NSDate date];
    checkingRunningProcesses = false;
}

- (void)windowWatcher
{
    if (checkingForWindows) {
        DDLogDebug(@"Check for prohibited windows still ongoing, returning");
        return;
    }
    checkingForWindows = true;
    
    CGWindowListOption options;
    BOOL firstScan = false;
    BOOL fishyWindowWasOpened = false;
    if (!_systemProcessPIDs) {
        // When this method is called the first time, we scan all windows
        firstScan = true;
        _systemProcessPIDs = [NSMutableArray new];
        options = kCGWindowListOptionAll;
        // Get SEB's PID
        NSRunningApplication *sebRunningApp = [NSRunningApplication currentApplication];
        sebPID = [sebRunningApp processIdentifier];
        fishyWindowWasOpened = true;

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

        // Close the Notification Center panel in case switching to applications is allowed
        if (_allowSwitchToApplications && [windowName isEqualToString:@"NotificationTableWindow"] && ![_preferencesController preferencesAreOpen]) {
            // If switching to applications is allowed and the Notification Center was opened
            DDLogWarn(@"Notification Center panel was opened (owning process name: %@", windowOwner);
            
            NSRunningApplication *notificationCenter = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.notificationcenterui"][0];
            [notificationCenter forceTerminate];
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
                    DDLogWarn(@"Application %@ with bundle ID %@ has opened a window with level %@", windowOwner, appWithPanelBundleID, windowLevelString);
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
                                //[appWithPanel terminate];
                            } else {
                                DDLogWarn(@"Application %@ is being force terminated because its bundle ID doesn't have the prefix com.apple.", windowOwner);
                                NSURL *appURL = [self getBundleOrExecutableURL:appWithPanel];
                                if (appURL) {
                                    [_terminatedProcessesExecutableURLs addObject:appURL];
                                }
                                [self killApplication:appWithPanel];
                                fishyWindowWasOpened = true;
                            }
                        } else {
                            // There is either no bundle ID or the prefix is com.apple.
                            // Check if application with Bundle ID com.apple. is a legit Apple system executable
                            if ([self signedSystemExecutable:windowOwnerPID]) {
                                // Cache this executable PID
                                [_systemProcessPIDs addObject:windowOwnerPIDString];
                            } else {
                                // The app which opened the window or panel is no system process
                                if (firstScan) {
                                    //[appWithPanel terminate];
                                } else {
                                    DDLogWarn(@"Application %@ is being force terminated because it isn't macOS system software!", windowOwner);
                                    NSURL *appURL = [self getBundleOrExecutableURL:appWithPanel];
                                    if (appURL) {
                                        [_terminatedProcessesExecutableURLs addObject:appURL];
                                    }
                                    [self killApplication:appWithPanel];
                                    fishyWindowWasOpened = true;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if (fishyWindowWasOpened) {
        DDLogVerbose(@"Window list: %@", windowList);
    }
    
    // Check if not allowed/prohibited processes was activated
    // Get all running processes, including daemons
    NSArray *allRunningProcesses = [self.runningProcesses copy];
    
    // Check for activated screen sharing if settings demand it
    if (!allowScreenSharing && !_screenSharingCheckOverride &&
        ([allRunningProcesses containsObject:screenSharingAgent] ||
         [allRunningProcesses containsObject:AppleVNCAgent] ||
         [allRunningProcesses containsObject:ARDAgent])) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"detectedScreenSharing" object:self];
        }
    
    // Check for activated Siri if settings demand it
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (!_startingUp && !allowSiri && !_siriCheckOverride &&
        [allRunningProcesses containsObject:SiriService] &&
        [[preferences valueForDefaultsDomain:SiriDefaultsDomain key:SiriDefaultsKey] boolValue]) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"detectedSiri" object:self];
        }
    
    // Check for activated dictation if settings demand it
    if (!_startingUp && !allowDictation && !_dictationCheckOverride &&
        [allRunningProcesses containsObject:DictationProcess] &&
        ([[preferences valueForDefaultsDomain:DictationDefaultsDomain key:DictationDefaultsKey] boolValue] ||
         [[preferences valueForDefaultsDomain:AppleDictationDefaultsDomain key:AppleDictationDefaultsKey] integerValue] != 0)) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"detectedDictation" object:self];
        }
    
    checkingForWindows = false;
}


// Get URL (path) to either bundle or executable of a running application
- (NSURL *)getBundleOrExecutableURL:(NSRunningApplication *)runningApp
{
    NSURL *runningAppURL = runningApp.bundleURL;
    if (!runningAppURL) {
        // If this didn't work then it's probably an app without bundle, get executable URL
        runningAppURL = runningApp.executableURL;
    }
    DDLogDebug(@"NSRunningApplication %@ bundle or executable URL: %@", runningApp, runningAppURL);
    return runningAppURL;
}


// Check if application is a legit Apple system executable
- (BOOL)signedSystemExecutable:(pid_t)runningExecutablePID
{
    SecStaticCodeRef ref = NULL;
    
    int ret;
    char pathbuf[PROC_PIDPATHINFO_MAXSIZE];
    
    ret = proc_pidpath (runningExecutablePID, pathbuf, sizeof(pathbuf));
    if ( ret <= 0 ) {
        fprintf(stderr, "PID %d: proc_pidpath ();\n", runningExecutablePID);
        fprintf(stderr, "    %s\n", strerror(errno));
    } else {
#ifdef DEBUG
        printf("proc %d: %s\n", runningExecutablePID, pathbuf);
#endif
    }

    NSString *executablePath = [NSString stringWithCString:pathbuf encoding:NSUTF8StringEncoding];
    NSURL * executableURL = [NSURL fileURLWithPath:executablePath isDirectory:NO];

    DDLogDebug(@"Evaluating code signature of %@", executablePath);
    
    OSStatus status;
    
    // obtain the cert info from the executable
    status = SecStaticCodeCreateWithPath((__bridge CFURLRef)executableURL, kSecCSDefaultFlags, &ref);
    
    if (ref == NULL) return false;
    if (status != noErr) return false;
    
    SecRequirementRef req = NULL;
    NSString * reqStr;
    
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
    
    if (status != noErr) return false;
    if (req == NULL) return false;
    
    status = SecStaticCodeCheckValidity(ref, kSecCSCheckAllArchitectures, req);
    
    if (status != noErr) return false;
    
    CFRelease(ref);
    CFRelease(req);
    
    DDLogDebug(@"Code signature of %@ was checked and it positively identifies macOS system software.", executablePath);
    
    return true;
}


#pragma mark Monitoring of Prohibited System Functions

// Switch off display mirroring if it isn't allowed in settings
- (void)conditionallyTerminateDisplayMirroring
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    BOOL allowDisplayMirroring = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDisplayMirroring"];
    
    // Also set flags for screen sharing
    allowScreenSharing = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowScreenSharing"];

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
        BOOL isCaptured = CGDisplayIsCaptured(display);
        uint32_t vendorID = CGDisplayVendorNumber(display);
        NSString *displayName = [NSScreen displayNameForID:display];
        
        DDLogInfo(@"Display %@ (ID %u) from vendor %u with Resolution %f x %f\n is %sbuilt-in\n is %smain\n is %smirrored\n is %sHW mirrored\n is %salways mirrored\n is %scaptured",
                  displayName,
                  display,
                  vendorID,
                  bounds.size.width,
                  bounds.size.height,
                  isBuiltin ? "" : "not ",
                  isMain ? "" : "not ",
                  isMirrored ? "" : "not ",
                  isHWMirrored ? "" : "not ",
                  isAlwaysMirrored ? "" : "not ",
                  isCaptured ? "" : "not ");
        
        if (!allowDisplayMirroring && (isMirrored || isHWMirrored)) {
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
            DDLogInfo(@"Display %@ (ID %u) is claming to be built-in", displayName, display);
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
    
    // Check if the the built-in display should be the main display according to settings
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
            }
        }
    }
    
    // If we still don't have a screen, then useBuiltin was false and all available screens
    // (probably only one) is built-in, we just take that screen
    if (!mainScreen) {
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
}


// Switch off Siri and dictation if not allowed in settings
- (void)conditionallyDisableSpeechInput
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    allowSiri = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSiri"];
    allowDictation = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDictation"];
    
    // If settings demand it, switch off dictation
    if (allowDictation !=
        [[preferences valueForDefaultsDomain:DictationDefaultsDomain key:DictationDefaultsKey] boolValue]) {
        [preferences setValue:[NSNumber numberWithBool:allowDictation] forKey:DictationDefaultsKey forDefaultsDomain:DictationDefaultsDomain];
    }
    
    // If settings demand it, switch off Siri
    if (allowSiri !=
        [[preferences valueForDefaultsDomain:SiriDefaultsDomain key:SiriDefaultsKey] boolValue]) {
        [preferences setValue:[NSNumber numberWithBool:allowSiri] forKey:SiriDefaultsKey forDefaultsDomain:SiriDefaultsDomain];
    }
}


- (void)killAirPlayUIAgent
{
    NSArray *runningAirPlayAgents = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.AirPlayUIAgent"];
    if (runningAirPlayAgents.count != 0) {
        NSInteger killSuccess;
        for (NSRunningApplication *airPlayAgent in runningAirPlayAgents) {
            DDLogWarn(@"Terminating AirPlayUIAgent %@", airPlayAgent);
            killSuccess = [airPlayAgent kill];
            DDLogWarn(@"Success of terminating AirPlayUIAgent: %ld", (long)killSuccess);
        }
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


#pragma mark Checks for System Environment

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
                NSAlert *modalAlert = [self newAlert];
                [modalAlert setMessageText:NSLocalizedString(@"Holding Command Key Not Allowed!", nil)];
                [modalAlert setInformativeText:NSLocalizedString(@"Holding the Command key down while restarting SEB is not allowed, release it to continue.", nil)];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [modalAlert setAlertStyle:NSCriticalAlertStyle];
                [modalAlert runModal];
                [self removeAlertWindow:modalAlert.window];
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
        DDLogError(@"Force Quit window is open!");
            DDLogError(@"Show error message and ask user to close it or quit SEB.");
            NSAlert *modalAlert = [self newAlert];
            [modalAlert setMessageText:NSLocalizedString(@"Close Force Quit Window", nil)];
            [modalAlert setInformativeText:NSLocalizedString(@"SEB cannot run when the Force Quit window is open. Close the window or quit SEB. If the window isn't open and this alert is displayed anyways, restart your Mac.", nil)];
            [modalAlert setAlertStyle:NSCriticalAlertStyle];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Retry", nil)];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
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


#pragma mark System Lock Down Functionalities

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
        NSDictionary *screenDeviceDescription = iterScreen.deviceDescription;
        BOOL inactive = iterScreen.inactive;
        DDLogDebug(@"Screen is %@active, device description: %@", inactive ? @"in" : @"", screenDeviceDescription);
        
        // NSRect frame = size of the current screen
        NSRect frame = [iterScreen frame];
        NSUInteger styleMask = NSBorderlessWindowMask;
        NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
        
        // Set origin of the window rect to left bottom corner (important for non-main screens, since they have offsets)
        rect.origin.x = 0;
        rect.origin.y = 0;

        // If showing menu bar
        // On OS X >= 10.10 we exclude the menu bar on all screens from the covering windows
        // On OS X <= 10.9 we exclude the menu bar only on the screen which actually displays the menu bar
        if (excludeMenuBar && (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_10 || iterScreen == screens[0])) {
            // Reduce size of covering background windows to not cover the menu bar
            rect.size.height -= 22;
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
    NSUInteger styleMask = NSBorderlessWindowMask;
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
    [coveringView setTranslatesAutoresizingMaskIntoConstraints:true];
    
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

- (void) adjustScreenLocking: (id)sender {
    // This should only be done when the preferences window isn't open
    DDLogDebug(@"NSApplicationDidChangeScreenParametersNotification");
    
    if (![self.preferencesController preferencesAreOpen]) {

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


#pragma mark - Lockdown windows

/// Handler called when SEB needs to be locked
- (void) lockSEB:(NSNotification*) notification
{
    self.didBecomeActiveTime = [NSDate date];

    if ([[notification name] isEqualToString:
         NSWorkspaceSessionDidResignActiveNotification])
    {
        // Set alert title and message strings
        [_sebLockedViewController setLockdownAlertTitle: NSLocalizedString(@"User Switch Locked SEB!", @"Lockdown alert title text for switching the user")
                                                Message: NSLocalizedString(@"SEB is locked because it was attempted to switch the user. SEB can only be unlocked by entering the quit/unlock password, which usually exam supervision/support knows.", @"Lockdown alert message text for switching the user")];
        
        self.didResignActiveTime = [NSDate date];
        DDLogError(@"SessionDidResignActive: User switch / switch to login window detected!");
        [self openLockdownWindows];
        
        // Add log string for resign active
        [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"User switch / switch to login window detected", nil)] withTime:self.didResignActiveTime];
        
    }
    else if ([[notification name] isEqualToString:
              NSWorkspaceSessionDidBecomeActiveNotification])
    {
        // Perform activation tasks here.
        
        DDLogError(@"SessionDidBecomeActive: Switched back after user switch / login window!");
        
        // Add log string for becoming active
        [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Switched back after user switch / login window", nil)] withTime:self.didBecomeActiveTime];
        
        // Calculate time difference between session resigning active and becoming active again
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [calendar components:NSMinuteCalendarUnit | NSSecondCalendarUnit
                                                   fromDate:self.didResignActiveTime
                                                     toDate:self.didBecomeActiveTime
                                                    options:false];
        [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", [NSString stringWithFormat:NSLocalizedString(@"  SEB session was inactive for %ld:%.2ld (minutes:seconds)", nil), components.minute, components.second]] withTime:nil];
    }
    
    /// Handler called when attempting to re-open an exam which was interrupted before
    
    else if ([[notification name] isEqualToString:
              @"detectedReOpeningExam"])
    {
        _reOpenedExamDetected = true;

        [_sebLockedViewController setLockdownAlertTitle: NSLocalizedString(@"Re-Opening Locked Exam!", @"Lockdown alert title text for re-opening a locked exam")
                                                Message:[NSString stringWithFormat:@"%@\n\n%@",
                                                         NSLocalizedString(@"This exam was interrupted before and not finished properly. SEB can only be unlocked by entering the quit/unlock password, which usually exam supervision/support knows.", nil),
                                                         NSLocalizedString(@"To avoid that SEB locks an exam, you have to always use a quit/unlock link after the exam was submitted or the quit button. Never restart your Mac while SEB is still running.", nil)
                                                         ]];

        // Add log string for trying to re-open a locked exam
        [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Re-opening an exam which was locked before", nil)] withTime:self.didBecomeActiveTime];

        [self openLockdownWindows];
    }
    
    /// Handler called when screen sharing was detected
    
    else if ([[notification name] isEqualToString:
              @"detectedScreenSharing"])
    {
        if (!_screenSharingDetected) {
            _screenSharingDetected = true;
            _sebLockedViewController.overrideCheckForScreenSharing.state = false;
            _sebLockedViewController.overrideCheckForScreenSharing.hidden = false;
            
            // Set custom alert message string
            [_sebLockedViewController setLockdownAlertTitle: NSLocalizedString(@"Screen Sharing Locked SEB!", @"Lockdown alert title text for screen sharing")
                                                    Message:[NSString stringWithFormat:@"%@\n\n%@",
                                                             NSLocalizedString(@"Screen sharing detected. SEB can only be unlocked by entering the quit/unlock password, which usually exam supervision/support knows.", nil),
                                                             NSLocalizedString(@"To avoid that SEB locks itself during an exam when it detects that screen sharing started, it's best to switch off 'Screen Sharing' and 'Remote Management' in System Preferences/Sharing and 'Back to My Mac' in System Preferences/iCloud. You can also ask your network administrators to block ports used for the VNC protocol.", nil)
                                                             ]];
            
            // Report screen sharing is still active every 3rd second
            screenSharingLogCounter = logReportCounter;
            DDLogError(@"Screen sharing was activated!");
            
            if (_screenSharingCheckOverride == false) {
                [self openLockdownWindows];
            }
            
            // Add log string for screen sharing active
            [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Screen sharing was activated", nil)] withTime:self.didBecomeActiveTime];
        } else {
            if (!self.lockdownWindows) {
                _sebLockedViewController.overrideCheckForScreenSharing.hidden = false;
                [self openLockdownWindows];
            }
            // Add log string for screen sharing still active
            if (!screenSharingLogCounter--) {
                [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Screen sharing is still active", nil)] withTime:self.didBecomeActiveTime];
                screenSharingLogCounter = logReportCounter;
            }
        }
    }
    
    /// Handler called when Siri was detected
    
    else if ([[notification name] isEqualToString:
              @"detectedSiri"])
    {
        if (!_siriDetected) {
            _siriDetected = true;
            _sebLockedViewController.overrideCheckForSiri.state = false;
            _sebLockedViewController.overrideCheckForSiri.hidden = false;
            
            // Set custom alert message string
            [_sebLockedViewController setLockdownAlertTitle: NSLocalizedString(@"Siri Locked SEB!", @"Lockdown alert title text for Siri")
                                                    Message:NSLocalizedString(@"Siri activity detected. SEB can only be unlocked by entering the quit/unlock password, which usually exam supervision/support knows.", nil)];
            
            // Report Siri is still active every 3rd second
            siriLogCounter = logReportCounter;
            DDLogError(@"Screen sharing was activated!");
            
            if (_siriCheckOverride == false) {
                [self openLockdownWindows];
            }
            
            // Add log string for Siri active
            [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Siri was activated", nil)] withTime:self.didBecomeActiveTime];
        } else {
            if (!self.lockdownWindows) {
                _sebLockedViewController.overrideCheckForSiri.hidden = false;
                [self openLockdownWindows];
            }
            // Add log string for Siri still active
            if (!siriLogCounter--) {
                [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Siri is still active", nil)] withTime:self.didBecomeActiveTime];
                siriLogCounter = logReportCounter;
            }
        }
    }
    
    /// Handler called when dictation was detected
    
    else if ([[notification name] isEqualToString:
              @"detectedDictation"])
    {
        if (!_dictationDetected) {
            _dictationDetected = true;
            _sebLockedViewController.overrideCheckForDictation.state = false;
            _sebLockedViewController.overrideCheckForDictation.hidden = false;
            
            // Set custom alert message string
            [_sebLockedViewController setLockdownAlertTitle: NSLocalizedString(@"Dictation Locked SEB!", @"Lockdown alert title text for Siri")
                                                    Message:NSLocalizedString(@"Dictation activity detected. SEB can only be unlocked by entering the quit/unlock password, which usually exam supervision/support knows.", nil)];
            
            // Report dictation is still active every 3rd second
            dictationLogCounter = logReportCounter;
            DDLogError(@"Dictation was activated!");
            
            if (_dictationCheckOverride == false) {
                [self openLockdownWindows];
            }
            
            // Add log string for dictation active
            [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Dictation was activated", nil)] withTime:self.didBecomeActiveTime];
        } else {
            if (!self.lockdownWindows) {
                _sebLockedViewController.overrideCheckForDictation.hidden = false;
                [self openLockdownWindows];
            }
            // Add log string for dictation still active
            if (!dictationLogCounter--) {
                [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Dictation is still active", nil)] withTime:self.didBecomeActiveTime];
                dictationLogCounter = logReportCounter;
            }
        }
    }
    
    /// Handler called when a prohibited process was detected
    
    else if ([[notification name] isEqualToString:
              @"detectedProhibitedProcess"])
    {
        if (!_processesDetected) {
            _processesDetected = true;
            _sebLockedViewController.overrideCheckForSpecifcProcesses.state = false;
            _sebLockedViewController.overrideCheckForSpecifcProcesses.hidden = false;
            _sebLockedViewController.overrideCheckForAllProcesses.state = false;
            _sebLockedViewController.overrideCheckForAllProcesses.hidden = false;
            
            // Set custom alert message string
            [_sebLockedViewController setLockdownAlertTitle: NSLocalizedString(@"Prohibited Process Locked SEB!", @"Lockdown alert title text for prohibited process")
                                                    Message:NSLocalizedString(@"SEB is locked because a process, which isn't allowed to run cannot be terminated. It's only possible to unlock SEB with the quit/unlock password, which usually exam supervision/support knows.", nil)];
            
            // Report processes are still active every 3rd second
            prohibitedProcessesLogCounter = logReportCounter;
            DDLogError(@"Prohibited processes detected!");
            
            if (_processCheckAllOverride == false) {
                [self openLockdownWindows];
            }
            
            // Add log string for prohibited process detected
            [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@: %@\n", NSLocalizedString(@"Prohibited processes detected", nil), _runningProhibitedProcesses] withTime:self.didBecomeActiveTime];
        } else {
            if (!self.lockdownWindows) {
                _sebLockedViewController.overrideCheckForSpecifcProcesses.hidden = false;
                _sebLockedViewController.overrideCheckForAllProcesses.hidden = false;
                [self openLockdownWindows];
            }
            // Add log string for detected prohibited process
            if (!prohibitedProcessesLogCounter--) {
                [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Prohibited processes still running", nil)] withTime:self.didBecomeActiveTime];
                prohibitedProcessesLogCounter = logReportCounter;
            }
        }
    }
    
    /// Handler called when a SIGSTOP was detected
    
    else if ([[notification name] isEqualToString:
              @"detectedSIGSTOP"])
    {
#ifndef DEBUG

        [_sebLockedViewController setLockdownAlertTitle: NSLocalizedString(@"SEB Process Was Stopped!", @"Lockdown alert title text for SEB process was stopped")
                                                Message:NSLocalizedString(@"The SEB process was interrupted, which can indicate manipulation. SEB can only be unlocked by entering the quit/unlock password, which usually exam supervision/support knows.", nil)];
        // Add log string for trying to re-open a locked exam
        // Calculate time difference between session resigning active and becoming active again
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [calendar components:NSMinuteCalendarUnit | NSSecondCalendarUnit
                                                   fromDate:self.didResignActiveTime
                                                     toDate:self.didBecomeActiveTime
                                                    options:false];
        [_sebLockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", [NSString stringWithFormat:NSLocalizedString(@"SEB process was stopped for %ld:%.2ld (minutes:seconds)", nil), components.minute, components.second]] withTime:self.didBecomeActiveTime];
        
        [self openLockdownWindows];
#endif
    }
    
}


- (void) conditionallyLockExam
{
    if ([_sebLockedViewController shouldOpenLockdownWindows]) {
        if ([[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length != 0) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"detectedReOpeningExam" object:self];
        } else {
            // Remove a previously locked exam
            DDLogWarn(@"Re-opening an exam which was locked before, but now doesn't have a quit password set, therefore doesn't run in secure mode.");
            [_sebLockedViewController removeLockedExam:[[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_startURL"]];
        }
    }
}


- (void) openLockdownWindows
{
    if (!self.lockdownWindows) {
        self.didResignActiveTime = [NSDate date];

        DDLogError(@"Locking SEB with red frontmost covering windows");

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
        
        lockdownModalSession = [NSApp beginModalSessionForWindow:coveringWindow];
        [NSApp runModalSession:lockdownModalSession];
    }
}


- (void) correctPasswordEntered
{
#ifdef DEBUG
    DDLogInfo(@"%s, _sebLockedViewController %@", __FUNCTION__, _sebLockedViewController);
#endif
    [_sebLockedViewController shouldCloseLockdownWindows];
}


- (void) closeLockdownWindows
{
    DDLogError(@"Unlocking SEB, removing red frontmost covering windows");

    [NSApp endModalSession:lockdownModalSession];
    
    if (_sebLockedViewController.overrideCheckForScreenSharing.state == true) {
        _screenSharingCheckOverride = true;
        _sebLockedViewController.overrideCheckForScreenSharing.state = false;
        _sebLockedViewController.overrideCheckForScreenSharing.hidden = true;
    }

    if (_sebLockedViewController.overrideCheckForSiri.state == true) {
        _siriCheckOverride = true;
        _sebLockedViewController.overrideCheckForSiri.state = false;
        _sebLockedViewController.overrideCheckForSiri.hidden = true;
    }
    
    if (_sebLockedViewController.overrideCheckForDictation.state == true) {
        _dictationCheckOverride = true;
        _sebLockedViewController.overrideCheckForDictation.state = false;
        _sebLockedViewController.overrideCheckForDictation.hidden = true;
    }
    
    if (_sebLockedViewController.overrideCheckForSpecifcProcesses.state == true) {
        _processCheckSpecificOverride = true;
        _sebLockedViewController.overrideCheckForSpecifcProcesses.state = false;
        _sebLockedViewController.overrideCheckForSpecifcProcesses.hidden = true;
    }
    
    if (_sebLockedViewController.overrideCheckForAllProcesses.state == true) {
        _processCheckAllOverride = true;
        _sebLockedViewController.overrideCheckForAllProcesses.state = false;
        _sebLockedViewController.overrideCheckForAllProcesses.hidden = true;
    }
    
    [_sebLockedViewController.view removeFromSuperview];
    [self closeCoveringWindows:self.lockdownWindows];
    self.lockdownWindows = nil;
    if (_screenSharingCheckOverride == false) {
        _screenSharingDetected = false;
    }
    lastTimeProcessCheck = [NSDate date];
    _SIGSTOPDetected = false;
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


- (void) openInfoHUD:(NSString *)lockedTimeInfo
{
    informationHUDLabel.font = [NSFont boldSystemFontOfSize:[NSFont systemFontSize]];
    informationHUDLabel.textColor = [NSColor whiteColor];
    NSMutableString *informationText = [NSMutableString stringWithString:(lockedTimeInfo)];
    
    if (_reOpenedExamDetected) {
        informationHUDLabel.textColor = [NSColor redColor];
        [informationText appendString:[NSString stringWithFormat:@"\n\n%@",
                                       NSLocalizedString(@"Previously interrupted exam was re-opened!", nil)]];
        _reOpenedExamDetected = false;
    }
    
    if (_screenSharingCheckOverride) {
        informationHUDLabel.textColor = [NSColor redColor];
        [informationText appendString:[NSString stringWithFormat:@"\n\n%@",
                                       NSLocalizedString(@"Detecting screen sharing was disabled!", nil)]];
    }
    
    if (_siriCheckOverride) {
        informationHUDLabel.textColor = [NSColor redColor];
        [informationText appendString:[NSString stringWithFormat:@"\n\n%@",
                                       NSLocalizedString(@"Detecting Siri was disabled!", nil)]];
    }
    
    if (_dictationCheckOverride) {
        informationHUDLabel.textColor = [NSColor redColor];
        [informationText appendString:[NSString stringWithFormat:@"\n\n%@",
                                       NSLocalizedString(@"Detecting dictation was disabled!", nil)]];
    }
    
    if (_processCheckAllOverride) {
        informationHUDLabel.textColor = [NSColor redColor];
        [informationText appendString:[NSString stringWithFormat:@"\n\n%@",
                                       NSLocalizedString(@"Detecting processes was completely disabled!", nil)]];
    } else if (_processCheckSpecificOverride) {
        informationHUDLabel.textColor = [NSColor redColor];
        [informationText appendString:[NSString stringWithFormat:@"\n\n%@",
                                       NSLocalizedString(@"Detecting specific processes was disabled!", nil)]];
    }
    
    [informationHUDLabel setStringValue:[informationText copy]];
    NSArray *screens = [NSScreen screens];    // get all available screens
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


#pragma mark Managing Other Running Applications

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
#ifdef DEBUG
            NSRunningApplication *launchedApp = [userInfo objectForKey:NSWorkspaceApplicationKey];
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
    if (launchedApplication && ![launchedApplication isEqual:[NSRunningApplication currentApplication]]) {
        // Yes: We assume it's the app which switched the space and force terminate it!
        DDLogError(@"An app was started and switched the Space. SEB will force terminate it! (app localized name: %@, executable URL: %@)", [launchedApplication localizedName], [launchedApplication executableURL]);
        [self performSelector:@selector(killApplication:) withObject:launchedApplication afterDelay:1];
        launchedApplication = nil;
    }
}


- (NSInteger) killApplication:(NSRunningApplication *)application
{
    NSInteger killSuccess = [application kill];
    if (killSuccess != ERR_SUCCESS && !_processCheckAllOverride) {
        [_runningProhibitedProcesses addObject:application];
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"detectedProhibitedProcess" object:self];
    }
    return killSuccess;
}


- (void) SEBgotActive: (id)sender {
    DDLogDebug(@"SEB got active");
//    [self startKioskMode];
}


#pragma mark Kiosk Mode

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
    [self changeWindowLevels:allowApps];
}


// Change window levels without closing/reopening cap background and browser foreground windows
- (void) changeWindowLevels:(BOOL)allowApps
{
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
    
    // Change window level of a modal window (like an alert) if one is displayed
    [self adjustModalAlertWindowLevels:allowAppsUserDefaultsSetting];
    
    // Change window level of the about window if it is displayed
    if (aboutWindow.isVisible) {
        DDLogWarn(@"About window displayed");
        if (allowApps) {
            [aboutWindow newSetLevel:NSModalPanelWindowLevel-1];
        } else {
            [aboutWindow newSetLevel:NSMainMenuWindowLevel+5];
        }
    }
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
    
    // Change window level of a modal window (like an alert) if one is displayed
    [self adjustModalAlertWindowLevels:allowSwitchToThirdPartyApps];
    
    // Change window level of the about window if it is displayed
    if (aboutWindow.isVisible) {
        DDLogWarn(@"About window displayed");
        if (allowSwitchToThirdPartyApps) {
            [aboutWindow newSetLevel:NSModalPanelWindowLevel-1];
        } else {
            [aboutWindow newSetLevel:NSMainMenuWindowLevel+5];
        }
    }
}


// Change window level of a modal window (like an alert) if one is displayed
- (void)adjustModalAlertWindowLevels:(BOOL)allowSwitchToThirdPartyApps
{
    if (_modalAlertWindows.count) {
        DDLogWarn(@"Modal window(s) displayed");
        for (NSWindow *alertWindow in _modalAlertWindows)
        {
            if (allowSwitchToThirdPartyApps) {
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


#pragma mark Setup Main User Interface

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
                restartButtonToolTip = NSLocalizedString(@"Back to Start",nil);
            }
            SEBDockItem *dockItemSkipBack = [[SEBDockItem alloc] initWithTitle:nil
                                                                          icon:[NSImage imageNamed:@"SEBSkipBackIcon"]
                                                               highlightedIcon:[NSImage imageNamed:@"SEBSkipBackIconHighlighted"]
                                                                       toolTip:restartButtonToolTip
                                                                          menu:nil
                                                                        target:self
                                                                        action:@selector(restartButtonPressed)];
            [rightDockItems addObject:dockItemSkipBack];
        }
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableSebBrowser"] &&
            [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showReloadButton"]) {
            SEBDockItem *dockItemReload = [[SEBDockItem alloc] initWithTitle:nil
                                                                          icon:[NSImage imageNamed:@"SEBReloadIcon"]
                                                               highlightedIcon:[NSImage imageNamed:@"SEBReloadIconHighlighted"]
                                                                       toolTip:NSLocalizedString(@"Reload Current Page",nil)
                                                                          menu:nil
                                                                        target:self
                                                                        action:@selector(reloadButtonPressed)];
            [rightDockItems addObject:dockItemReload];
        }
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTime"]) {
            SEBDockItemTime *dockItemTime = sebDockItemTime;
            [dockItemTime startDisplayingTime];
            
            [rightDockItems addObject:dockItemTime];
        }
        
        // Set right dock items
        
//        [self.dockController setCenterItems:[NSArray arrayWithObjects:dockItemSEB, dockItemShutDown, nil]];
        
        NSArray *dockButtons = [self.dockController setRightItems:rightDockItems];
        for (SEBDockItemButton *dockButton in dockButtons)
        {
            if (dockButton.action == @selector(reloadButtonPressed)) {
                _dockButtonReload = dockButton;
            }
        }
        
        // Display the dock
        [self.dockController showDockOnScreen:_mainScreen];

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
        restartExamText = NSLocalizedString(@"Back to Start",nil);
    }

    // Check if restarting is protected with the quit/unlock password (and one is set)
    NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamPasswordProtected"] && ![hashedQuitPassword isEqualToString:@""]) {
        // if quit/unlock password is set, then restrict quitting
        NSMutableParagraphStyle *textParagraph = [[NSMutableParagraphStyle alloc] init];
        textParagraph.lineSpacing = 5.0;
        NSMutableAttributedString *dialogText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Enter quit/unlock password:",nil)] attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:NSFont.systemFontSize], NSParagraphStyleAttributeName:textParagraph}].mutableCopy;
        
        NSAttributedString *information = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"(This function doesn't log you out if you are logged in on a website)", nil) attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:NSFont.smallSystemFontSize]}];
        [dialogText appendAttributedString:information];
        
        if ([self showEnterPasswordDialog:dialogText.copy
                           modalForWindow:self.browserController.mainBrowserWindow
                              windowTitle:restartExamText] == SEBEnterPasswordCancel) {
           return;
        }
        NSString *password = [self.enterPassword stringValue];
        
        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
        if ([hashedQuitPassword caseInsensitiveCompare:[keychainManager generateSHAHashString:password]] == NSOrderedSame) {
            // if the correct quit/unlock password was entered, restart the exam
            [self.browserController restartDockButtonPressed];
            return;
        } else {
            // Wrong quit password was entered
            NSAlert *modalAlert = [self newAlert];
            [modalAlert setMessageText:restartExamText];
            [modalAlert setInformativeText:NSLocalizedString(@"Wrong quit/unlock password.", nil)];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [modalAlert setAlertStyle:NSCriticalAlertStyle];
            [modalAlert runModal];
            [self removeAlertWindow:modalAlert.window];
            return;
        }
    }
    
    // If no quit password is required, then confirm quitting
    NSAlert *modalAlert = [self newAlert];
    [modalAlert setMessageText:restartExamText];
    [modalAlert setInformativeText:[NSString stringWithFormat:@"%@\n\n%@",
                                         NSLocalizedString(@"Are you sure?", nil),
                                         NSLocalizedString(@"(This function doesn't log you out if you are logged in on a website)", nil)
                                         ]];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [modalAlert setAlertStyle:NSWarningAlertStyle];
    NSInteger answer = [modalAlert runModal];
    [self removeAlertWindow:modalAlert.window];
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


- (void) reloadButtonEnabled:(BOOL)enabled
{
    _dockButtonReload.enabled = enabled;
}


- (void) quitButtonPressed
{
    // Post a notification that SEB should conditionally quit
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestExitNotification" object:self];
}


- (NSInteger) showEnterPasswordDialog:(NSAttributedString *)text modalForWindow:(NSWindow *)window windowTitle:(NSString *)title {
    
    [self.enterPassword setStringValue:@""]; //reset the enterPassword NSSecureTextField

    // If the (main) browser window is full screen, we don't show the dialog as sheet
    if (window && (self.browserController.mainBrowserWindow.isFullScreen || [self.preferencesController preferencesAreOpen])) {
        window = nil;
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
    
    [NSApp beginSheet: enterPasswordDialogWindow
       modalForWindow: window
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    NSInteger returnCode = [NSApp runModalForWindow: enterPasswordDialogWindow];
    // Dialog is up here.
    [NSApp endSheet: enterPasswordDialogWindow];
    [enterPasswordDialogWindow orderOut: self];
    [self removeAlertWindow:enterPasswordDialogWindow];
    
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
    
    // If the dialog needs to be shown application modal
    if (!window) {
        // Add password dialog to open modal alerts
        [_modalAlertWindows addObject:enterPasswordDialogWindow];
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
                NSAlert *modalAlert = [self newAlert];
                [modalAlert setMessageText:NSLocalizedString(@"Wrong Quit Password", nil)];
                [modalAlert setInformativeText:NSLocalizedString(@"If you don't enter the correct quit password, then you cannot quit SEB.", nil)];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [modalAlert setAlertStyle:NSWarningAlertStyle];
                [modalAlert runModal];
                [self removeAlertWindow:modalAlert.window];
            }
        } else {
        // if no quit password is required, then confirm quitting
            NSAlert *modalAlert = [self newAlert];
            [modalAlert setMessageText:NSLocalizedString(@"Quit Safe Exam Browser",nil)];
            [modalAlert setInformativeText:NSLocalizedString(@"Are you sure you want to quit SEB?", nil)];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
            [modalAlert setAlertStyle:NSWarningAlertStyle];
            NSInteger answer = [modalAlert runModal];
            [self removeAlertWindow:modalAlert.window];
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


#pragma mark Open/Close Preferences

- (IBAction) openPreferences:(id)sender {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (lockdownWindows.count == 0 && [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"]) {
        if (floor(NSAppKitVersionNumber) < NSAppKitVersionNumber10_9) {
            NSAlert *modalAlert = [self newAlert];
            [modalAlert setMessageText:NSLocalizedString(@"Preferences Window Not Available on macOS 10.7/10.8", nil)];
            [modalAlert setInformativeText:NSLocalizedString(@"On macOS 10.7 and 10.8 SEB can only be used as an exam client. Run SEB on macOS 10.9 or higher to create a .seb configuration file to configure this SEB client as well.", nil)];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [modalAlert setAlertStyle:NSCriticalAlertStyle];
            [modalAlert runModal];
            [self removeAlertWindow:modalAlert.window];
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
                    NSAlert *modalAlert = [self newAlert];
                    [modalAlert setMessageText:NSLocalizedString(@"Wrong Admin Password", nil)];
                    [modalAlert setInformativeText:NSLocalizedString(@"If you don't enter the correct SEB administrator password, then you cannot open preferences.", nil)];
                    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                    [modalAlert setAlertStyle:NSWarningAlertStyle];
                    [modalAlert runModal];
                    [self removeAlertWindow:modalAlert.window];
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
    NSAlert *modalAlert = [self newAlert];
    [modalAlert setMessageText:NSLocalizedString(@"Quit Safe Exam Browser",nil)];
    [modalAlert setInformativeText:NSLocalizedString(@"Are you sure you want to quit SEB?", nil)];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"Quit", nil)];
    [modalAlert setAlertStyle:NSWarningAlertStyle];
    NSInteger answer = [modalAlert runModal];
    [self removeAlertWindow:modalAlert.window];
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
    DDLogError(@"---------- RESTARTING SEB SESSION -------------");

    // If this was a secured exam, we remove it from the list of running exams,
    // otherwise it would be locked next time it is started again
    if (currentExamStartURL) {
        [self.sebLockedViewController removeLockedExam:currentExamStartURL];
    }
    
    // Switch off display mirroring if it isn't allowed in settings
    [self conditionallyTerminateDisplayMirroring];
    
    // Switch off Siri and dictation if not allowed in settings
    [self conditionallyDisableSpeechInput];

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
    DDLogDebug(@"%s re-openMainBrowserWindow", __FUNCTION__);
    
    [self.browserController openMainBrowserWindow];

    // Persist start URL of a "secure" exam
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length != 0) {
        currentExamStartURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
        [self.sebLockedViewController addLockedExam:currentExamStartURL];
    } else {
        currentExamStartURL = nil;
    }

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
    NSString *urlText = SEBHelpPage;
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
        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Not Running Minimal macOS Version!", nil)]];
        [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Current SEB settings require at least %@, but your system is older. SEB will quit!", nil),
                                        [[SEBUIUserDefaultsController sharedSEBUIUserDefaultsController] org_safeexambrowser_SEB_minMacOSVersions][_enforceMinMacOSVersion]]];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [modalAlert setAlertStyle:NSCriticalAlertStyle];
        [modalAlert runModal];
        [self removeAlertWindow:modalAlert.window];
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
        [modalAlert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"SEB Not in %@ Folder!", nil), localizedApplicationDirectoryName]];
        [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"SEB has to be placed in the %@ folder in order for all features to work correctly. Move the 'Safe Exam Browser' app to your %@ folder and make sure that you don't have any other versions of SEB installed on your system. SEB will quit now.", nil), localizedApplicationDirectoryName, localizedAndInternalApplicationDirectoryName]];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [modalAlert setAlertStyle:NSCriticalAlertStyle];
        [modalAlert runModal];
        [self removeAlertWindow:modalAlert.window];
    } else if (_cmdKeyDown) {
        // Show alert that keys were hold while starting SEB
        NSAlert *modalAlert = [self newAlert];
        [modalAlert setMessageText:NSLocalizedString(@"Holding Command Key Not Allowed!", nil)];
        [modalAlert setInformativeText:NSLocalizedString(@"Holding the Command key down while starting SEB is not allowed. Restart SEB without holding any keys.", nil)];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [modalAlert setAlertStyle:NSCriticalAlertStyle];
        [modalAlert runModal];
        [self removeAlertWindow:modalAlert.window];
    }
    
    BOOL success = [self.systemManager restoreSC];
    DDLogDebug(@"Success of restoring SC: %hhd", success);
    
    [self stopWindowWatcher];
    [self stopProcessWatcher];

    [_systemManager restoreSystemSettings];
    
    // If this was a secured exam, we remove it from the list of running exams,
    // otherwise it would be locked next time it is started again
    if (currentExamStartURL) {
        [self.sebLockedViewController removeLockedExam:currentExamStartURL];
    }
    
    // Restart terminated apps
    DDLogInfo(@"These processes were terminated by SEB during this session: %@", _terminatedProcessesExecutableURLs);
    NSArray *uniqueTerminatedProcessesURLs = [_terminatedProcessesExecutableURLs valueForKeyPath:@"@distinctUnionOfObjects.self"];
    DDLogInfo(@"These unique processes were terminated by SEB during this session: %@", uniqueTerminatedProcessesURLs);
    
    for (NSURL *executableURL in uniqueTerminatedProcessesURLs) {
        
        // Parameter and path to XUL-SEB Application
        NSArray *taskArguments = [NSArray arrayWithObjects:@"", nil];
        
        if ([executableURL.pathExtension isEqualToString:@"app"]) {
            NSError *error;
            DDLogInfo(@"Trying to restart terminated process with bundle URL %@", executableURL.path);
            [[NSWorkspace sharedWorkspace] launchApplicationAtURL:executableURL options:NSWorkspaceLaunchDefault configuration:@{} error:&error];
            if (error) {
                DDLogError(@"Error %@", error);
            }
        } else {
            // Allocate and initialize a new NSTask
            NSTask *task = [NSTask new];
            
            // Tell the NSTask what the path is to the binary it should launch
            //        NSString *path = [executableURL.path stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];
            [task setLaunchPath:executableURL.path];
            
            // The argument that we pass to XULRunner (in the form of an array) is the path to the SEB-XUL-App
            [task setArguments:taskArguments];
            
            // Launch the process asynchronously
            @try {
                DDLogInfo(@"Trying to restart terminated process %@", executableURL.path);
                [task launch];
            }
            @catch (NSException* error) {
                DDLogError(@"Error %@.  Make sure you have a valid path and arguments.", error);
            }
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
    DDLogError(@"---------- EXITING SEB - ENDING SESSION -------------");
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
