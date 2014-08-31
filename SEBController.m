//
//  SEBController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.04.10.
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
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright 
//  (c) 2010-2014 Daniel R. Schneider, ETH Zurich, Educational Development
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

#import "MyDocument.h"
#import "PrefsBrowserViewController.h"
#import "RNDecryptor.h"
#import "SEBKeychainManager.h"
#import "SEBCryptor.h"
#import "NSWindow+SEBWindow.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "SEBConfigFileManager.h"
#import "SEBWindowSizeValueTransformer.h"
#import "BoolValueTransformer.h"
#import "IsEmptyCollectionValueTransformer.h"
#import "MyGlobals.h"
#import "Constants.h"

#import "SEBSystemManager.h"

io_connect_t  root_port; // a reference to the Root Power Domain IOService


OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,id sender);
void MySleepCallBack(void * refCon, io_service_t service, natural_t messageType, void * messageArgument);
bool insideMatrix();

@implementation SEBController

@synthesize f3Pressed;	//create getter and setter for F3 key pressed flag
@synthesize quittingMyself;	//create getter and setter for flag that SEB is quitting itself
@synthesize webView;
@synthesize capWindows;

#pragma mark Application Delegate Methods

+ (void) initialize
{
    [[MyGlobals sharedMyGlobals] setStartKioskChangedPresentationOptions:NO];

    SEBWindowSizeValueTransformer *windowSizeTransformer = [[SEBWindowSizeValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:windowSizeTransformer
                                    forName:@"SEBWindowSizeTransformer"];

    BoolValueTransformer *boolValueTransformer = [[BoolValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:boolValueTransformer
                                    forName:@"BoolValueTransformer"];
    
    IsEmptyCollectionValueTransformer *isEmptyCollectionValueTransformer = [[IsEmptyCollectionValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:isEmptyCollectionValueTransformer
                                    forName:@"isEmptyCollectionValueTransformer"];

//    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}


- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    // Install the Get URL Handler when a SEB URL seb://... is called
//    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
}


// Tells the application delegate to open a single file.
// Returning YES if the file is successfully opened, and NO otherwise.
//
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    NSURL *sebFileURL = [NSURL fileURLWithPath:filename];

    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];

    // Check if preferences window is open
    if ([self.preferencesController preferencesAreOpen]) {

        /// Open settings file in preferences window for editing

        [self.preferencesController openSEBPrefsAtURL:sebFileURL];
    
    } else {
        
        /// Open settings file for exam/reconfiguring client
        
        // Check if SEB is in exam mode = private UserDefauls are switched on
        if (NSUserDefaults.userDefaultsPrivate) {
            NSRunAlertPanel(NSLocalizedString(@"Loading new SEB settings not allowed!", nil),
                            NSLocalizedString(@"SEB is already running in exam mode and it is not allowed to interupt this by starting another exam. Finish the exam and quit SEB before starting another exam.", nil),
                            NSLocalizedString(@"OK", nil), nil, nil);
            return YES;
        }
        
#ifdef DEBUG
        NSLog(@"Open file event: Loading .seb settings file with URL %@",sebFileURL);
#endif
        NSData *sebData = [NSData dataWithContentsOfURL:sebFileURL];
        
        SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
        
        // Get current config path
        NSURL *currentConfigPath = [[MyGlobals sharedMyGlobals] currentConfigURL];
        // Save the path to the file for possible editing in the preferences window
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:sebFileURL];
        
        // Decrypt and store the .seb config file
        if ([configFileManager storeDecryptedSEBSettings:sebData forEditing:NO]) {
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
        if ([url.pathExtension isEqualToString:@"seb"]) {
            // If we have a valid URL with the path for a .seb file, we download and open it (conditionally)
#ifdef DEBUG
            NSLog(@"Get URL event: Loading .seb settings file with URL %@", urlString);
#endif
            [browserWindow downloadAndOpenSebConfigFromURL:url];
        }
    }
}


#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) {

        [[MyGlobals sharedMyGlobals] setPreferencesReset:NO];
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:nil];
        
        [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
#ifdef DEBUG
        NSLog(@"Installed get URL event handler");
#endif

        // Add an observer for the request to unconditionally quit SEB
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(requestedQuit:)
                                                     name:@"requestQuitNotification" object:nil];
        
        
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        // Set flag for displaying alert to new users
        if ([preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"] == nil) {
            firstStart = YES;
        } else {
            firstStart = NO;
        }
        //
        // Set default preferences for the case there are no user prefs yet
        //
        NSDictionary *appDefaults = [preferences sebDefaultSettings];
        NSMutableDictionary *defaultSettings = [NSMutableDictionary dictionaryWithCapacity:appDefaults.count];
        // Encrypt default values
        for (NSString *key in appDefaults) {
            id value = [appDefaults objectForKey:key];
            if (value) [defaultSettings setObject:(id)[preferences secureDataForObject:value] forKey:key];
        }
        // Register default preferences
        [preferences registerDefaults:defaultSettings];
        
        // Check if originatorVersion flag is set and otherwise set it to the SEB current version
        if ([[preferences secureStringForKey:@"org_safeexambrowser_originatorVersion"] isEqualToString:@""]) {
            [preferences setSecureString:[NSString stringWithFormat:@"SEB_OSX_%@_%@",
                                          [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"],
                                          [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"]]
                                  forKey:@"org_safeexambrowser_originatorVersion"];
        }

        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
#ifdef DEBUG
        NSLog(@"Registred Defaults");
#endif        
    }
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
//    [self setElevateWindowLevels];
    return self;
}


- (void)awakeFromNib {	

    SEBSystemManager *systemManager = [[SEBSystemManager alloc] init];
	
    BOOL worked = [systemManager checkHTTPSProxySetting];
#ifdef DEBUG
    NSLog(@"Checking updating HTTPS proxy worked: %hhd", worked);
#endif
    
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
        if ((appBundleID != nil) & !isHidden) {
            [visibleApps addObject:appBundleID]; //add ID of the visible app
        }
        if ([iterApp ownsMenuBar]) {
#ifdef DEBUG
            NSLog(@"App %@ owns menu bar", iterApp);
#endif
        }
    }

// Setup Notifications and Kiosk Mode    
    
    // Add an observer for the notification that another application became active (SEB got inactive)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(regainActiveStatus:) 
												 name:NSApplicationDidResignActiveNotification 
                                               object:NSApp];
	
#ifndef DEBUG
    // Add an observer for the notification that another application was unhidden by the finder
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	[[workspace notificationCenter] addObserver:self
                                       selector:@selector(regainActiveStatus:)
                                           name:NSWorkspaceDidActivateApplicationNotification
                                         object:workspace];
	
    // Add an observer for the notification that another application was unhidden by the finder
	[[workspace notificationCenter] addObserver:self
                                       selector:@selector(regainActiveStatus:)
                                           name:NSWorkspaceDidUnhideApplicationNotification
                                         object:workspace];
	
    // Add an observer for the notification that another application was unhidden by the finder
	[[workspace notificationCenter] addObserver:self
                                       selector:@selector(regainActiveStatus:)
                                           name:NSWorkspaceWillLaunchApplicationNotification
                                         object:workspace];
	
    // Add an observer for the notification that another application was unhidden by the finder
	[[workspace notificationCenter] addObserver:self
                                       selector:@selector(regainActiveStatus:)
                                           name:NSWorkspaceDidLaunchApplicationNotification
                                         object:workspace];
	
//    // Add an observer for the notification that another application was unhidden by the finder
//	[[workspace notificationCenter] addObserver:self
//                                       selector:@selector(requestedReinforceKioskMode:)
//                                           name:NSWorkspaceActiveSpaceDidChangeNotification
//                                         object:workspace];
	
#endif
    // Add an observer for the notification that SEB became active
    // With third party apps and Flash fullscreen it can happen that SEB looses its 
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SEBgotActive:)
												 name:NSApplicationDidBecomeActiveNotification 
                                               object:NSApp];
	
    // Hide all other applications
	[[NSWorkspace sharedWorkspace] performSelectorOnMainThread:@selector(hideOtherApplications)
													withObject:NULL waitUntilDone:NO];
    
    // Cover all attached screens with cap windows to prevent clicks on desktop making finder active
//	[self coverScreens];

//// Switch to kiosk mode by setting the proper presentation options
	[self startKioskMode];
	
    // Add an observer for changes of the Presentation Options
	[NSApp addObserver:self
			forKeyPath:@"currentSystemPresentationOptions"
			   options:NSKeyValueObservingOptionNew
			   context:NULL];
//		
// Cover all attached screens with cap windows to prevent clicks on desktop making finder active
	[self coverScreens];
    
    // Add a observer for changes of the screen configuration
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustScreenLocking:) 
												 name:NSApplicationDidChangeScreenParametersNotification 
                                               object:NSApp];

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
                                             selector:@selector(requestedReinforceKioskMode:)
                                                 name:@"requestReinforceKioskMode" object:nil];
	
    // Add an observer for the request to reinforce the kiosk mode
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestedRegainActiveStatus:)
                                                 name:@"regainActiveStatus" object:nil];
	
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
    //[self startTask];

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
		NSLog(@"Display sleep is switched off now.");
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
		NSLog(@"Idle sleep is switched off now.");
	}
#endif		
*/	
	// Installing I/O Kit sleep/wake notification to cancel sleep
	
	IONotificationPortRef notifyPortRef; // notification port allocated by IORegisterForSystemPower
    io_object_t notifierObject; // notifier object, used to deregister later
    void* refCon; // this parameter is passed to the callback
	
    // register to receive system sleep notifications

    root_port = IORegisterForSystemPower( refCon, &notifyPortRef, MySleepCallBack, &notifierObject );
    if ( root_port == 0 )
    {
        NSLog(@"IORegisterForSystemPower failed");
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
#ifdef DEBUG
                NSLog(@"SERIOUS SECURITY ISSUE DETECTED: SEB was started up in a virtual machine! gestaltX86AdditionalFeatures = %X", myAttrs);
#endif
                NSRunAlertPanel(NSLocalizedString(@"Virtual Machine detected!", nil),
                                NSLocalizedString(@"You are not allowed to run SEB inside a virtual machine!", nil),
                                NSLocalizedString(@"Quit", nil), nil, nil);
                quittingMyself = TRUE; //SEB is terminating itself
                [NSApp terminate: nil]; //quit SEB
                
#ifdef DEBUG
            } else {
                NSLog(@"SEB is running on a native system (no VM) gestaltX86AdditionalFeatures = %X", myAttrs);
#endif
            }
        }
        
        bool    virtualMachine = false;
        // STR or SIDT code?
        virtualMachine = insideMatrix();
        if (virtualMachine) {
            NSLog(@"SERIOUS SECURITY ISSUE DETECTED: SEB was started up in a virtual machine (Test2)!");
        }
    }


// Clear Pasteboard, but save the current content in case it is a NSString
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard]; 
    //NSArray *classes = [[NSArray alloc] initWithObjects:[NSString class], [NSAttributedString class], nil];
    NSArray *classes = [[NSArray alloc] initWithObjects:[NSString class], nil];
    NSDictionary *options = [NSDictionary dictionary];
    NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
    if ((copiedItems != nil) && [copiedItems count]) {
        // if there is a NSSting in the pasteboard, save it for later use
        //[[MyGlobals sharedMyGlobals] setPasteboardString:[copiedItems objectAtIndex:0]];
        [[MyGlobals sharedMyGlobals] setValue:[copiedItems objectAtIndex:0] forKey:@"pasteboardString"];
#ifdef DEBUG
        NSLog(@"String saved from pasteboard");
#endif
    } else {
        [[MyGlobals sharedMyGlobals] setValue:@"" forKey:@"pasteboardString"];
    }
#ifdef DEBUG
    NSString *stringFromPasteboard = [[MyGlobals sharedMyGlobals] valueForKey:@"pasteboardString"];
    NSLog(@"Saved string from Pasteboard: %@", stringFromPasteboard);
#endif
    //NSInteger changeCount = [pasteboard clearContents];
    [pasteboard clearContents];

    // Make SEB take over all screens, regardless if there is another app in fullscreen mode (in Mavericks)
    //[self toggleCapWindowsFullscreen:self];

    // Set up SEB Browser
    [self openMainBrowserWindow];
    
	// Due to the infamous Flash plugin we completely disable plugins in the 32-bit build
#ifdef __i386__        // 32-bit Intel build
	[[self.webView preferences] setPlugInsEnabled:NO];
#endif
	
    if ([[MyGlobals sharedMyGlobals] preferencesReset] == YES) {
#ifdef DEBUG
        NSLog(@"Presenting alert for local SEB settings have been reset");
#endif
        NSAlert *newAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Local SEB settings have been reset", nil) defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Local preferences were either created by an incompatible SEB version or manipulated. They have been reset to the default settings. Ask your exam supporter to re-configure SEB correctly.", nil)];
        [newAlert runModal];
#ifdef DEBUG
        NSLog(@"Dismissed alert for local SEB settings have been reset");
#endif
    }
        
/*	if (firstStart) {
		NSString *titleString = NSLocalizedString(@"Important Notice for First Time Users", nil);
		NSString *messageString = NSLocalizedString(@"FirstTimeUserNotice", nil);
		NSRunAlertPanel(titleString, messageString, NSLocalizedString(@"OK", nil), nil, nil);
#ifdef DEBUG
        NSLog(@"%@\n%@",titleString, messageString);
#endif
	}*/
    
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
    [aboutWindow showAboutWindowForSeconds:3];
    
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
    printf( "messageType %08lx, arg %08lx\n",
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


// Close the About Window
- (void) closeAboutWindow {
#ifdef DEBUG
    NSLog(@"Attempting to close about window %@", aboutWindow);
#endif
    [aboutWindow orderOut:self];
}


// Open background windows on all available screens to prevent Finder becoming active when clicking on the desktop background
- (void) coverScreens {
	NSArray *screens = [NSScreen screens];	// get all available screens
    if (!self.capWindows) {
        self.capWindows = [NSMutableArray arrayWithCapacity:1];	// array for storing our cap (covering) background windows
    } else {
        [self.capWindows removeAllObjects];
    }
    NSScreen *iterScreen;
    BOOL allowSwitchToThirdPartyApps = ![[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    for (iterScreen in screens)
    {
        //NSRect frame = size of the current screen;
        NSRect frame = [iterScreen frame];
        NSUInteger styleMask = NSBorderlessWindowMask;
        //NSUInteger styleMask = NSTitledWindowMask;
        NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
        //set origin of the window rect to left bottom corner (important for non-main screens, since they have offsets)
        rect.origin.x = 0;
        rect.origin.y = 0;
        CapWindow *window = [[CapWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered defer:NO screen:iterScreen];
        [window setReleasedWhenClosed:NO];
        [window setBackgroundColor:[NSColor blackColor]];
        [window setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
        //[window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenAuxiliary];
//        [window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary | NSWindowCollectionBehaviorCanJoinAllSpaces];
        //        [window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
        if (!allowSwitchToThirdPartyApps) {
            [window setLevel:NSTornOffMenuWindowLevel];
        }
        [self.capWindows addObject: window];
        NSView *superview = [window contentView];
        CapView *capview = [[CapView alloc] initWithFrame:rect];
        [superview addSubview:capview];
        
        //[window orderBack:self];
        CapWindowController *capWindowController = [[CapWindowController alloc] initWithWindow:window];
        //CapWindow *loadedCapWindow = capWindowController.window;
        [capWindowController showWindow:self];
        [window makeKeyAndOrderFront:self];
        //[window orderBack:self];
        //BOOL isWindowLoaded = capWindowController.isWindowLoaded;
#ifdef DEBUG
        //NSLog(@"Loaded capWindow %@, isWindowLoaded %@", loadedCapWindow, isWindowLoaded);
#endif
        
        //        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
        //                              [NSNumber numberWithBool:NO], NSFullScreenModeAllScreens,
        //                              nil];
        //
        //        [superview enterFullScreenMode:iterScreen withOptions:options];
        // Setup bindings to the preferences window close button
        
//        [window toggleFullScreen:self];
    }
}


// Open background windows on all available screens to prevent Finder becoming active when clicking on the desktop background
- (IBAction) toggleCapWindowsFullscreen:(id)sender
{
#ifdef DEBUG
    NSLog(@"toggleCapWindowsFullscreen");
#endif
	int windowIndex;
	int windowCount = [self.capWindows count];
    for (windowIndex = 0; windowIndex < windowCount; windowIndex++ )
    {
		[(NSWindow *)[self.capWindows objectAtIndex:windowIndex] toggleFullScreen:self];
	}
}


// Called when changes of the screen configuration occur
// (new display is contected or removed or display mirroring activated)

- (void) adjustScreenLocking: (id)sender {
    // Close the covering windows
	// (which most likely are no longer there where they should be)
    [self closeCapWindows];

	// Open new covering background windows on all currently available screens
	[self coverScreens];
}


- (void) closeCapWindows
{
    // Close the covering windows
	int windowIndex;
	int windowCount = [self.capWindows count];
    for (windowIndex = 0; windowIndex < windowCount; windowIndex++ )
    {
		[(NSWindow *)[self.capWindows objectAtIndex:windowIndex] close];
	}
}


- (void) startTask {
	// Start third party application from within SEB
	
	// Path to Excel
	NSString *pathToTask=@"/Applications/Preview.app/Contents/MacOS/Preview";
	
	// Parameter and path to XUL-SEB Application
	NSArray *taskArguments=[NSArray arrayWithObjects:nil];
	
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
		NSLog(@"Error.  Make sure you have a valid path and arguments.");
		
	}
	
}

- (void) terminateScreencapture {
#ifdef DEBUG
    NSLog(@"screencapture terminated");
#endif
}

- (void) regainActiveStatus: (id)sender {
	// hide all other applications if not in debug build setting
    //NSLog(@"regainActiveStatus!");
    /*/ Check if the
    if ([[sender name] isEqualToString:@"NSWorkspaceDidLaunchApplicationNotification"]) {
        NSDictionary *userInfo = [sender userInfo];
        if (userInfo) {
            NSRunningApplication *launchedApp = [userInfo objectForKey:NSWorkspaceApplicationKey];
#ifdef DEBUG
            NSLog(@"launched app localizedName: %@, executableURL: %@", [launchedApp localizedName], [launchedApp executableURL]);
#endif
            if ([[launchedApp localizedName] isEqualToString:@"iCab"]) {
                [launchedApp forceTerminate];
#ifdef DEBUG
                NSLog(@"screencapture terminated");
#endif
            }
        }
    }*/
    // Load preferences from the system's user defaults database
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    if (!allowSwitchToThirdPartyApps) {
		// if switching to ThirdPartyApps not allowed
#ifdef DEBUG
        NSLog(@"Regain active status after %@", [sender name]);
#endif
#ifndef DEBUG
//        [NSApp activateIgnoringOtherApps: YES];
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        [[NSWorkspace sharedWorkspace] performSelectorOnMainThread:@selector(hideOtherApplications) withObject:NULL waitUntilDone:NO];
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
                NSLog(@"Successfully hidden app %@: %@", appBundleID, [NSNumber numberWithBool:successfullyHidden]);
#endif
            }
        }
*/
    }
}


- (void) SEBgotActive: (id)sender {
#ifdef DEBUG
    NSLog(@"SEB got active");
#endif
//    [self startKioskMode];
}


// Method which sets the setting flag for elevating window levels according to the
// setting key allowSwitchToApplications
- (void) setElevateWindowLevels
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL allowSwitchToThirdPartyApps = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"];
    if (allowSwitchToThirdPartyApps) {
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
#ifdef DEBUG
    NSLog(@"startKioskMode switchToApplications %hhd", allowSwitchToThirdPartyApps);
#endif
    [self startKioskModeThirdPartyAppsAllowed:allowSwitchToThirdPartyApps overrideShowMenuBar:NO];

}


- (void) switchKioskModeAppsAllowed:(BOOL) allowApps overrideShowMenuBar:(BOOL)overrideShowMenuBar {
	// Switch the kiosk mode to either only browser windows or also third party apps allowed:
    // Change presentation options and windows levels without closing/reopening cap background and browser foreground windows
    [self startKioskModeThirdPartyAppsAllowed:allowApps overrideShowMenuBar:overrideShowMenuBar];
    
    // Change window level of cap windows
    CapWindow *capWindow;
    //[window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenAuxiliary];
    //        [window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary | NSWindowCollectionBehaviorCanJoinAllSpaces];
    //        [window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    for (capWindow in self.capWindows) {
        if (allowApps) {
            [capWindow newSetLevel:NSNormalWindowLevel];
        } else {
            [capWindow newSetLevel:NSTornOffMenuWindowLevel];
        }
    }
    
    // Change window level of all open browser windows
    
    NSArray *openWindowDocuments = [[NSDocumentController sharedDocumentController] documents];
    MyDocument *openWindowDocument;
    for (openWindowDocument in openWindowDocuments) {
        if (allowApps) {
            // Order new browser window to the front of our level
            [openWindowDocument.mainWindowController.window newSetLevel:NSNormalWindowLevel];
            [openWindowDocument.mainWindowController.window orderFront:self];
        } else {
            [openWindowDocument.mainWindowController.window newSetLevel:NSModalPanelWindowLevel];
        }
    }
	[browserWindow makeKeyAndOrderFront:self];
}


- (void) startKioskModeThirdPartyAppsAllowed:(BOOL) allowSwitchToThirdPartyApps overrideShowMenuBar:(BOOL)overrideShowMenuBar {
	// Switch to kiosk mode by setting the proper presentation options
    // Load preferences from the system's user defaults database
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	BOOL showMenuBar = overrideShowMenuBar || [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showMenuBar"];
	BOOL enableToolbar = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"];
	BOOL hideToolbar = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_hideBrowserWindowToolbar"];
    NSApplicationPresentationOptions options;
    
    if (allowSwitchToThirdPartyApps) {
        [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
    } else {
        [preferences setSecureBool:YES forKey:@"org_safeexambrowser_elevateWindowLevels"];
    }

    //    if (browserWindow.isFullScreen || [[MyGlobals sharedMyGlobals] transitioningToFullscreen] == YES)
    if (browserWindow.isFullScreen == YES)
    {
#ifdef DEBUG
        NSLog(@"browserWindow.isFullScreen");
#endif
        if ([[MyGlobals sharedMyGlobals] transitioningToFullscreen] == YES) {
            [[MyGlobals sharedMyGlobals] setTransitioningToFullscreen:NO];
        }
        if (!allowSwitchToThirdPartyApps) {
            // if switching to third party apps not allowed
            options =
            NSApplicationPresentationHideDock +
            NSApplicationPresentationFullScreen +
            (enableToolbar && hideToolbar ?
             NSApplicationPresentationAutoHideToolbar + NSApplicationPresentationAutoHideMenuBar :
             (showMenuBar ? NSApplicationPresentationDisableAppleMenu : NSApplicationPresentationHideMenuBar)) +
            NSApplicationPresentationDisableProcessSwitching +
            NSApplicationPresentationDisableForceQuit +
            NSApplicationPresentationDisableSessionTermination;
        } else {
            // if switching to third party apps allowed
            options =
            NSApplicationPresentationHideDock +
            NSApplicationPresentationFullScreen +
            (enableToolbar && hideToolbar ?
             NSApplicationPresentationAutoHideToolbar + NSApplicationPresentationAutoHideMenuBar :
             (showMenuBar ? NSApplicationPresentationDisableAppleMenu : NSApplicationPresentationHideMenuBar)) +
            NSApplicationPresentationDisableForceQuit +
            NSApplicationPresentationDisableSessionTermination;
        }
        
    } else {
        
#ifdef DEBUG
        NSLog(@"NOT browserWindow.isFullScreen");
#endif
        if (!allowSwitchToThirdPartyApps) {
            // if switching to third party apps not allowed
            options =
            NSApplicationPresentationHideDock +
            (showMenuBar ? NSApplicationPresentationDisableAppleMenu : NSApplicationPresentationHideMenuBar) +
            NSApplicationPresentationDisableProcessSwitching +
            NSApplicationPresentationDisableForceQuit +
            NSApplicationPresentationDisableSessionTermination;
        } else {
            options =
            (showMenuBar ? NSApplicationPresentationDisableAppleMenu : NSApplicationPresentationHideMenuBar) +
            NSApplicationPresentationHideDock +
            NSApplicationPresentationDisableForceQuit +
            NSApplicationPresentationDisableSessionTermination;
        }
    }
    
    @try {
        [[MyGlobals sharedMyGlobals] setStartKioskChangedPresentationOptions:YES];
        
        [NSApp setPresentationOptions:options];
        [[MyGlobals sharedMyGlobals] setPresentationOptions:options];
    }
    @catch(NSException *exception) {
        NSLog(@"Error.  Make sure you have a valid combination of presentation options.");
    }
}


- (void)openMainBrowserWindow {
    // Set up SEB Browser 
    
    /*/ Save current WebKit Cookie Policy
     NSHTTPCookieAcceptPolicy cookiePolicy = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookieAcceptPolicy];
     if (cookiePolicy == NSHTTPCookieAcceptPolicyAlways) NSLog(@"NSHTTPCookieAcceptPolicyAlways");
     if (cookiePolicy == NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain) NSLog(@"NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain"); */
    // Open and maximize the browser window
    // (this is done here, after presentation options are set,
    // because otherwise menu bar and dock are deducted from screen size)
    MyDocument *myDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"DocumentType" display:YES];
    self.webView = myDocument.mainWindowController.webView;
    browserWindow = (BrowserWindow *)myDocument.mainWindowController.window;
    [[MyGlobals sharedMyGlobals] setMainBrowserWindow:browserWindow]; //save a reference to this main browser window
#ifdef DEBUG
    NSLog(@"MainBrowserWindow (1) sharingType: %lx",(long)[browserWindow sharingType]);
#endif
    [browserWindow setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
#ifdef DEBUG
    NSLog(@"MainBrowserWindow (2) sharingType: %lx",(long)[browserWindow sharingType]);
#endif
	[(BrowserWindow *)browserWindow setCalculatedFrame];
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"]) {
        [browserWindow newSetLevel:NSModalPanelWindowLevel];
#ifdef DEBUG
        NSLog(@"MainBrowserWindow (3) sharingType: %lx",(long)[browserWindow sharingType]);
#endif
    }
//	[NSApp activateIgnoringOtherApps: YES];
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    
    // Setup bindings to the preferences window close button
    NSButton *closeButton = [browserWindow standardWindowButton:NSWindowCloseButton];

    [closeButton bind:@"enabled"
             toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
          withKeyPath:@"values.org_safeexambrowser_SEB_allowQuit" 
              options:nil];
    
    //[browserWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
	[browserWindow makeKeyAndOrderFront:self];
        
	// Load start URL from the system's user defaults database
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
#ifdef DEBUG
    NSLog(@"Open MainBrowserWindow with start URL: %@", urlText);
#endif

    // Add "SEB" to the browser's user agent, so the LMS SEB plugins recognize us
	NSString *customUserAgent = [self.webView userAgentForURL:[NSURL URLWithString:urlText]];
	[self.webView setCustomUserAgent:[customUserAgent stringByAppendingString:@" SEB"]];
    
	// Load start URL into browser window
	[[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlText]]];
    
//    BOOL allowSwitchToThirdPartyApps = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"];
//    [self startKioskModeThirdPartyAppsAllowed:allowSwitchToThirdPartyApps];
}


- (void)openResourceWithURL:(NSString *)URL andTitle:(NSString *)title
{
    MyDocument *myDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"DocumentType" display:YES];
    NSWindow *additionalBrowserWindow = myDocument.mainWindowController.window;
    [additionalBrowserWindow setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
	[(BrowserWindow *)additionalBrowserWindow setCalculatedFrame];
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"]) {
        [additionalBrowserWindow newSetLevel:NSModalPanelWindowLevel];
    }
//	[NSApp activateIgnoringOtherApps: YES];
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    
	//[additionalBrowserWindow makeKeyAndOrderFront:self];
    
#ifdef DEBUG
    NSLog(@"Open additional browser window with URL: %@", URL);
#endif
    
	// Load start URL into browser window
	[[myDocument.mainWindowController.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URL]]];
}


- (NSInteger) showEnterPasswordDialog:(NSString *)text modalForWindow:(NSWindow *)window windowTitle:(NSString *)title {
    // User has asked to see the dialog. Display it.
    [self.enterPassword setStringValue:@""]; //reset the enterPassword NSSecureTextField
    if (title) enterPasswordDialogWindow.title = title;
    [enterPasswordDialog setStringValue:text];
    
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


- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
#ifdef DEBUG
    NSLog(@"sheetDidEnd");
#endif
}


- (IBAction) exitSEB:(id)sender {
	// Load quitting preferences from the system's user defaults database
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowQuit"] == YES) {
		// if quitting SEB is allowed
		
        if (![hashedQuitPassword isEqualToString:@""]) {
			// if quit password is set, then restrict quitting
            if ([self showEnterPasswordDialog:NSLocalizedString(@"Enter quit password:",nil)  modalForWindow:browserWindow windowTitle:nil] == SEBEnterPasswordCancel) return;
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
            int answer = NSRunAlertPanel(NSLocalizedString(@"Quit Safe Exam Browser",nil), NSLocalizedString(@"Are you sure you want to quit SEB?",nil),
                                         NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Quit",nil), nil);
            switch(answer)
            {
                case NSAlertDefaultReturn:
                    return; //Cancel: don't quit
                default:
					quittingMyself = TRUE; //SEB is terminating itself
                    [NSApp terminate: nil]; //quit SEB
            }
        }
    } 
}


- (IBAction) openPreferences:(id)sender {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPreferencesWindow"]) {
        if (![self.preferencesController preferencesAreOpen]) {
            // Load admin password from the system's user defaults database
            NSString *hashedAdminPW = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
            if (![hashedAdminPW isEqualToString:@""]) {
                // If admin password is set, then restrict access to the preferences window
                if ([self showEnterPasswordDialog:NSLocalizedString(@"Enter administrator password:",nil)  modalForWindow:browserWindow windowTitle:nil] == SEBEnterPasswordCancel) return;
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
    }
}


- (void)preferencesClosed:(NSNotification *)notification
{
    // Hide the Config menu (in menu bar)
    [configMenu setHidden:YES];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

#ifdef DEBUG
    NSLog(@"Preferences window closed, reopening cap windows.");
#endif

    // 
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [browserWindow makeKeyAndOrderFront:self];

    // Open new covering background windows on all currently available screens
    [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
	[self coverScreens];

    // Switch the kiosk mode on again
    [self setElevateWindowLevels];
    
    [self startKioskMode];

    // Reinforce kiosk mode after a delay, so eventually visible fullscreen apps get hidden again
//    [aboutWindow showAboutWindowForSeconds:1];
    [self performSelector:@selector(requestedReinforceKioskMode:) withObject: nil afterDelay: 1];

}


- (void)requestedQuitWPwd:(NSNotification *)notification
{
    int answer = NSRunAlertPanel(NSLocalizedString(@"Quit",nil), NSLocalizedString(@"Are you sure you want to quit SEB?",nil),
                                 NSLocalizedString(@"Cancel",nil), NSLocalizedString(@"Quit",nil), nil);
    switch(answer)
    {
        case NSAlertDefaultReturn:
            return; //Cancel: don't quit
        default:
            quittingMyself = TRUE; //SEB is terminating itself
            [NSApp terminate: nil]; //quit SEB
    }
}


- (void)requestedQuit:(NSNotification *)notification
{
    quittingMyself = TRUE; //SEB is terminating itself
    [NSApp terminate: nil]; //quit SEB
}


- (void)requestedRestart:(NSNotification *)notification
{
    // Set kiosk/presentation mode in case it changed
    [self startKioskMode];
    // Close all browser windows (documents)

    [[NSDocumentController sharedDocumentController] closeAllDocumentsWithDelegate:nil
                                                               didCloseAllSelector:nil contextInfo: nil];
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"requestDocumentClose" object:self];
    [[MyGlobals sharedMyGlobals] setCurrentMainHost:nil];
    // Adjust screen locking
#ifdef DEBUG
    NSLog(@"Requested Restart");
#endif
    [self adjustScreenLocking:self];
    // Reopen main browser window and load start URL
    [self openMainBrowserWindow];

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    NSArray *additionalResources;
//    additionalResources = [NSArray arrayWithArray:[preferences secureArrayForKey:@"org_safeexambrowser_SEB_additionalResources"]];
    NSArray *additionalResources = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_additionalResources"];
    for (NSDictionary *resource in additionalResources) {
        if ([resource valueForKey:@"active"] == [NSNumber numberWithBool:YES]) {
            NSString *resourceURL = [resource valueForKey:@"URL"];
            NSString *resourceTitle = [resource valueForKey:@"title"];
            if ([resource valueForKey:@"autoOpen"] == [NSNumber numberWithBool:YES]) {
                [self openResourceWithURL:resourceURL andTitle:resourceTitle];
            }
        }
    }
}


- (void)requestedReinforceKioskMode:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"Reinforcing the kiosk mode was requested");
#endif
    // Switch the kiosk mode temporary off
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
    [self switchKioskModeAppsAllowed:YES overrideShowMenuBar:NO];
    // Close the black background covering windows
    [self closeCapWindows];
    // Reopen the covering Windows and reset the windows elevation levels
//    [self preferencesClosed:nil];
#ifdef DEBUG
    NSLog(@"requestedReinforceKioskMode: Reopening cap windows.");
#endif
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [browserWindow makeKeyAndOrderFront:self];
    // Open new covering background windows on all currently available screens
    [preferences setSecureBool:NO forKey:@"org_safeexambrowser_elevateWindowLevels"];
	[self coverScreens];
    
    // Switch the kiosk mode on again
    [self setElevateWindowLevels];
    
    BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    [self switchKioskModeAppsAllowed:allowSwitchToThirdPartyApps overrideShowMenuBar:NO];
}


/*- (void)documentController:(NSDocumentController *)docController  didCloseAll: (BOOL)didCloseAll contextInfo:(void *)contextInfo {
#ifdef DEBUG
    NSLog(@"All documents closed: %@", [NSNumber numberWithBool:didCloseAll]);
#endif
    return;
}*/

- (void)requestedShowAbout:(NSNotification *)notification
{
    [self showAbout:self];
}

- (IBAction)showAbout: (id)sender
{
    [aboutWindow setStyleMask:NSBorderlessWindowMask];
	[aboutWindow center];
	//[aboutWindow orderFront:self];
    //[aboutWindow setLevel:NSScreenSaverWindowLevel];
    [[NSApplication sharedApplication] runModalForWindow:aboutWindow];
}


- (void)requestedShowHelp:(NSNotification *)notification
{
    [self showHelp:self];
}

- (IBAction)showHelp: (id)sender
{
    // Load manual page URL into browser window
    NSString *urlText = @"http://www.safeexambrowser.org/macosx";
	[[self.webView mainFrame] loadRequest:
     [NSURLRequest requestWithURL:[NSURL URLWithString:urlText]]];
}


- (void)closeDocument:(id) document
{
    [document close];
}

- (void)switchPluginsOn:(NSNotification *)notification
{
#ifndef __i386__        // Plugins can't be switched on in the 32-bit Intel build
    [[self.webView preferences] setPlugInsEnabled:YES];
#endif
}


- (NSData*) generateSHAHash:(NSString*)inputString {
    unsigned char hashedChars[32];
    CC_SHA256([inputString UTF8String],
              [inputString lengthOfBytesUsingEncoding:NSUTF8StringEncoding], 
              hashedChars);
    NSData *hashedData = [NSData dataWithBytes:hashedChars length:32];
    return hashedData;
}


#pragma mark Delegates

// Called when SEB should be terminated
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	if (quittingMyself) {
		return NSTerminateNow; //SEB wants to quit, ok, so it should happen
	} else { //SEB should be terminated externally(!)
		return NSTerminateCancel; //this we can't allow, sorry...
	}
}


// Called just before SEB will be terminated
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    runningAppsWhileTerminating = [[NSWorkspace sharedWorkspace] runningApplications];
    NSRunningApplication *iterApp;
    for (iterApp in runningAppsWhileTerminating) 
    {
        NSString *appBundleID = [iterApp valueForKey:@"bundleIdentifier"];
        if ([visibleApps indexOfObject:appBundleID] != NSNotFound) {
            [iterApp unhide]; //unhide the originally visible application
        }
    }
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
    
	// Clear the current Browser Exam Key
    [preferences setSecureObject:[NSData data] forKey:@"org_safeexambrowser_currentData"];

	// Clear the browser cache in ~/Library/Caches/org.safeexambrowser.SEB.Safe-Exam-Browser/
	NSURLCache *cache = [NSURLCache sharedURLCache];
	[cache removeAllCachedResponses];
    
	// Allow display and system to sleep again
	//IOReturn success = IOPMAssertionRelease(assertionID1);
	IOPMAssertionRelease(assertionID1);
	/*// Allow system to sleep again
	success = IOPMAssertionRelease(assertionID2);*/
}


// Prevent an untitled document to be opened at application launch
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
#ifdef DEBUG
    NSLog(@"Invoked applicationShouldOpenUntitledFile with answer NO!");
#endif
    return NO;
}

/*- (void)windowDidResignKey:(NSNotification *)notification {
	[NSApp activateIgnoringOtherApps: YES];
	[browserWindow 
	 makeKeyAndOrderFront:self];
	#ifdef DEBUG
	NSLog(@"[browserWindow makeKeyAndOrderFront]");
	NSBeep();
	#endif
	
}
*/


// Called when currentPresentationOptions change
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:id
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"currentSystemPresentationOptions"]) {
        if ([[MyGlobals sharedMyGlobals] startKioskChangedPresentationOptions]) {
            [[MyGlobals sharedMyGlobals] setStartKioskChangedPresentationOptions:NO];
            return;
        }

		//the current Presentation Options changed, so make SEB active and reset them
        // Load preferences from the system's user defaults database
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
#ifdef DEBUG
        NSLog(@"currentSystemPresentationOptions changed!");
#endif
        // If plugins are enabled and there is a Flash view in the webview ...
        if ([[self.webView preferences] arePlugInsEnabled]) {
            NSView* flashView = [(BrowserWindow*)[[MyGlobals sharedMyGlobals] mainBrowserWindow] findFlashViewInView:webView];
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
        //[(BrowserWindow*)browserWindow setCalculatedFrame];
        if (!allowSwitchToThirdPartyApps) {
            // If third party Apps are not allowed, we switch back to SEB
#ifdef DEBUG
            NSLog(@"Switched back to SEB after currentSystemPresentationOptions changed!");
#endif
            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
//            [NSApp activateIgnoringOtherApps: YES];

//            [[NSNotificationCenter defaultCenter] postNotificationName:@"requestRegainActiveStatus" object:self];

            [browserWindow makeKeyAndOrderFront:self];
            //[self startKioskMode];
            [self regainActiveStatus:nil];
            //[browserWindow setFrame:[[browserWindow screen] frame] display:YES];
        }
    }	
}
 
@end
