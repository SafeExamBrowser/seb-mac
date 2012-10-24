    //
//  SEBController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.04.10.
//  Copyright (c) 2010-2012 Daniel R. Schneider, ETH Zurich, 
//  Educational Development and Technology (LET), 
//  based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, 
//  Dirk Bauer, Karsten Burger, Marco Lehre, 
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
//  (C) 2010-2012 Daniel R. Schneider, ETH Zurich, Educational Development
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

#include <IOKit/pwr_mgt/IOPMLib.h>
#include <IOKit/IOMessage.h>

#import "MyDocument.h"
#import "PrefsBrowserViewController.h"
#import "RNCryptor.h"
#import "NSWindow+SEBWindow.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "MyGlobals.h"
#import "Constants.h"

io_connect_t  root_port; // a reference to the Root Power Domain IOService


OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,id sender);
void MySleepCallBack(void * refCon, io_service_t service, natural_t messageType, void * messageArgument);
bool insideMatrix();

@implementation SEBController

@synthesize f3Pressed;	//create getter and setter for F3 key pressed flag
@synthesize quittingMyself;	//create getter and setter for flag that SEB is quitting itself


#pragma mark Application Delegate Methods

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    NSURL *sebFileURL = [NSURL fileURLWithPath:filename];
#ifdef DEBUG
    NSLog(@"Loading .seb settings file with URL %@",sebFileURL);
#endif
    NSDictionary *sebPreferencesDict=[NSDictionary dictionaryWithContentsOfURL:sebFileURL];
//    NSMutableDictionary *initialValuesDict = [NSMutableDictionary dictionaryWithCapacity:[sebPreferencesDict count]];
    // Use private UserDefaults
    NSMutableDictionary *privatePreferences = [NSUserDefaults privateUserDefaults];
    for (NSString *key in sebPreferencesDict) {
        NSString *keyWithPrefix = [NSString stringWithFormat:@"org_safeexambrowser_SEB_%@", key];
        [privatePreferences setObject:[sebPreferencesDict objectForKey:key] forKey:keyWithPrefix];
//        [initialValuesDict setObject:[preferences secureDataForObject:[sebPreferencesDict objectForKey:key]] forKey:keyWithPrefix];
    }
#ifdef DEBUG
    NSLog(@"Private preferences set: %@",privatePreferences);
#endif
    [NSUserDefaults setUserDefaultsPrivate:YES];
    // Set the initial values in the shared user defaults controller
//    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
    // Replace the values of all the user default properties with any corresponding values in the initialValues dictionary
//    [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:self];
    [self startKioskMode];
    [self requestedRestart:nil];
    return YES;
}


#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
        
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        // Set flag for displaying alert to new users
        if ([preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"] == nil) {
            firstStart = YES;
        } else {
            firstStart = NO;
        }
        // Set default preferences for the case there are no user prefs yet
        //SEBnewBrowserWindowLink newBrowserWindowLinkPolicy = openInNewWindow;
        NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [preferences secureDataForObject:(id)[NSData data]], @"org_safeexambrowser_SEB_hashedAdminPassword",
                                     [preferences secureDataForObject:(id)[NSData data]], @"org_safeexambrowser_SEB_hashedQuitPassword",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:YES]], @"org_safeexambrowser_SEB_allowQuit",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:YES]], @"org_safeexambrowser_SEB_allowSwitchToThirdPartyApps",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:NO]], @"org_safeexambrowser_SEB_allowDownUploads",
                                     [preferences secureDataForObject:(id)[NSHomeDirectory() stringByAppendingPathComponent: @"Downloads"]], @"org_safeexambrowser_SEB_downloadDirectory",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:NO]], @"org_safeexambrowser_SEB_openDownloads",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithInt:manuallyWithFileRequester]], @"org_safeexambrowser_SEB_chooseFileToUploadPolicy",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:NO]], @"org_safeexambrowser_SEB_downloadPDFFiles",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:NO]], @"org_safeexambrowser_SEB_prefsInBundle",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:YES]], @"org_safeexambrowser_SEB_enablePlugins",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:YES]], @"org_safeexambrowser_SEB_enableJava",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:YES]], @"org_safeexambrowser_SEB_enableJavaScript",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:NO]], @"org_safeexambrowser_SEB_blockPopUpWindows",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:NO]], @"org_safeexambrowser_SEB_allowFlashFullscreen",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:NO]], @"org_safeexambrowser_SEB_enableBrowsingBackForward",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithInt:openInNewWindow]], @"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:NO]], @"org_safeexambrowser_SEB_newBrowserWindowByLinkBlockForeign",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithInt:openInNewWindow]], @"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy",
                                     [preferences secureDataForObject:(id)[NSNumber numberWithBool:NO]], @"org_safeexambrowser_SEB_newBrowserWindowByScriptBlockForeign",
                                     [preferences secureDataForObject:(id)@"http://www.safeexambrowser.org/macosx"], @"org_safeexambrowser_SEB_startURL",
                                     nil];
        [preferences registerDefaults:appDefaults];
#ifdef DEBUG
        NSLog(@"Registred Defaults");
#endif        
        // Load initialValues from application bundle
        NSString *initialValuesPath;
        NSDictionary *initialValuesDict;
        // load the initialValues from a SEB preferences file optionally located in the application bundle
        initialValuesPath=[[NSBundle mainBundle] pathForResource:@"org.safeexambrowser.Safe-Exam-Browser"
                                                          ofType:@"plist"];
        if (initialValuesPath != nil) {
            // If there actually was a SEB preferences file in the app bundle
            initialValuesDict=[NSDictionary dictionaryWithContentsOfFile:initialValuesPath];
            
            /*/ Test for swizzled dataWithPropertyList
             NSData *xmlData;
             NSError **error;
             
             xmlData = [NSPropertyListSerialization dataWithPropertyList:initialValuesDict
             format:NSPropertyListXMLFormat_v1_0
             options:0
             error:error];
             NSPropertyListFormat format;
             NSError **error2;
             id plist;
             
             plist = [NSPropertyListSerialization propertyListWithData:xmlData options:NSPropertyListImmutable format:&format error:error2];
             */
            // Set the initial values in the shared user defaults controller
            [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
            // Replace the values of all the user default properties with any corresponding values in the initialValues dictionary
            [[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:self];
            // Set the flag for preferences in app bundle
            [preferences setSecureObject:[NSNumber numberWithBool:YES] forKey:@"org_safeexambrowser_SEB_prefsInBundle"];
        } else {
            // No preferences were saved in the app bundle
            // Reset the flag for preferences in app bundle
            [preferences setSecureObject:[NSNumber numberWithBool:NO] forKey:@"org_safeexambrowser_SEB_prefsInBundle"];
        }
        

    }
    return self;
}


- (void)awakeFromNib {	
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
    }

// Setup Notifications and Kiosk Mode    
    
    // Add an observer for the notification that another application became active (SEB got inactive)
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(regainActiveStatus:) 
												 name:NSApplicationDidResignActiveNotification 
                                               object:NSApp];
	
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
                                           name:NSWorkspaceDidLaunchApplicationNotification
                                         object:workspace];
	
    // Add an observer for the notification that SEB became active
    // With third party apps and Flash fullscreen it can happen that SEB looses its 
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SEBgotActive:)
												 name:NSApplicationDidBecomeActiveNotification 
                                               object:NSApp];
	
    // Hide all other applications
	[[NSWorkspace sharedWorkspace] performSelectorOnMainThread:@selector(hideOtherApplications)
													withObject:NULL waitUntilDone:NO];
	
// Switch to kiosk mode by setting the proper presentation options
	[self startKioskMode];
	
    // Add an observer for changes of the Presentation Options
	[NSApp addObserver:self
			forKeyPath:@"currentSystemPresentationOptions"
			   options:NSKeyValueObservingOptionNew
			   context:NULL];
		
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
	
    // Add an observer for the request to unconditionally quit SEB
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestedQuit:)
                                                 name:@"requestQuitNotification" object:nil];
	
    // Add an observer for the request to reload start URL
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestedRestart:)
                                                 name:@"requestRestartNotification" object:nil];
	
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
    NSString *stringFromPasteboard = [[MyGlobals sharedMyGlobals] pasteboardString];
    NSLog(@"Saved string from Pasteboard: %@", stringFromPasteboard);
#endif
    //NSInteger changeCount = [pasteboard clearContents];
    [pasteboard clearContents];
    
// Set up SEB Browser 
    [self openMainBrowserWindow];
    
	// Due to the infamous Flash plugin we completely disable plugins in the 32-bit build
#ifdef __i386__        // 32-bit Intel build
	[[webView preferences] setPlugInsEnabled:NO];
#endif
	
	if (firstStart) {
		NSString *titleString = NSLocalizedString(@"Important Notice for First Time Users", nil);
#ifdef __i386__        // 32-bit Intel build needs more information
		NSString *messageString = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"32bitDisclaimer", nil), NSLocalizedString(@"FirstTimeUserNotice", nil)];
#else
		NSString *messageString = NSLocalizedString(@"FirstTimeUserNotice", nil);
#endif
		NSRunAlertPanel(titleString, messageString, NSLocalizedString(@"OK", nil), nil, nil);
#ifdef DEBUG
        NSLog(@"%@\n%@",titleString, messageString);
#endif
	}
    
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


- (void) coverScreens {
	// Open background windows on all available screens to prevent Finder becoming active when clicking on the desktop background
	NSArray *screens = [NSScreen screens];	// get all available screens
    capWindows = [NSMutableArray array];	// array for storing our cap (covering) background windows
		// don't autorelease the array
    NSScreen *iterScreen;
    NSUInteger screenIndex = 1;
	BOOL allowSwitchToThirdPartyApps = [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToThirdPartyApps"];
    for (iterScreen in screens)
    {
		//NSRect frame = size of the current screen;
		NSRect frame = [iterScreen frame];
		NSUInteger styleMask = NSBorderlessWindowMask;
		NSRect rect = [NSWindow contentRectForFrameRect:frame styleMask:styleMask];
		//set origin of the window rect to left bottom corner (important for non-main screens, since they have offsets)
		rect.origin.x = 0;
		rect.origin.y = 0;
		NSWindow *window =  [[NSWindow alloc] initWithContentRect:rect styleMask:styleMask backing: NSBackingStoreBuffered defer:false screen:iterScreen];
		[window setBackgroundColor:[NSColor blackColor]];
		[window setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
        if (!allowSwitchToThirdPartyApps) {
            [window newSetLevel:NSModalPanelWindowLevel];
        }
		[window orderBack:self];
		[capWindows addObject: window];
        NSView *superview = [window contentView];
        CapView *capview = [[CapView alloc] initWithFrame:rect];
        [superview addSubview:capview];
		
        screenIndex++;
    }
}	


// Called when changes of the screen configuration occur 
// (new display is contected or removed or display mirroring activated)

- (void) adjustScreenLocking: (id)sender {
    // Close the covering windows
	// (which most likely are no longer there where they should be)
	int windowIndex;
	int windowCount = [capWindows count];
    for (windowIndex = 0; windowIndex < windowCount; windowIndex++ )
    {
		[[capWindows objectAtIndex:windowIndex] close];

	}
	// Open new covering background windows on all currently available screens
	[self coverScreens];
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


- (void) regainActiveStatus: (id)sender {
	// hide all other applications if not in debug build setting
    //NSLog(@"regainActiveStatus!");
#ifdef DEBUG
    NSLog(@"Regain active status");
#endif
    // Load preferences from the system's user defaults database
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	BOOL allowSwitchToThirdPartyApps = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToThirdPartyApps"];
    if (!allowSwitchToThirdPartyApps) {
		// if switching to ThirdPartyApps not allowed
#ifndef DEBUG
        [NSApp activateIgnoringOtherApps: YES];
        [[NSWorkspace sharedWorkspace] performSelectorOnMainThread:@selector(hideOtherApplications) withObject:NULL waitUntilDone:NO];
#endif
    } else {
        // Save the bundle ID of all currently running apps which are visible in a array
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

    }
}


- (void) SEBgotActive: (id)sender {
#ifdef DEBUG
    NSLog(@"SEB got active");
#endif
    [self startKioskMode];
}

- (void) startKioskMode {
	// Switch to kiosk mode by setting the proper presentation options
    // Load preferences from the system's user defaults database
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	BOOL allowSwitchToThirdPartyApps = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToThirdPartyApps"];
    if (!allowSwitchToThirdPartyApps) {
		// if switching to ThirdPartyApps not allowed
	@try {
		NSApplicationPresentationOptions options = 
		NSApplicationPresentationHideDock + 
		NSApplicationPresentationHideMenuBar + 
		NSApplicationPresentationDisableProcessSwitching + 
		NSApplicationPresentationDisableForceQuit + 
		NSApplicationPresentationDisableSessionTermination;
		[NSApp setPresentationOptions:options];
        [[MyGlobals sharedMyGlobals] setPresentationOptions:options];
	}
	@catch(NSException *exception) {
		NSLog(@"Error.  Make sure you have a valid combination of presentation options.");
	}
    } else {
        @try {
            NSApplicationPresentationOptions options =
            NSApplicationPresentationHideMenuBar +
            NSApplicationPresentationHideDock +
            NSApplicationPresentationDisableForceQuit + 
            NSApplicationPresentationDisableSessionTermination;
            [NSApp setPresentationOptions:options];
            [[MyGlobals sharedMyGlobals] setPresentationOptions:options];
        }
        @catch(NSException *exception) {
            NSLog(@"Error.  Make sure you have a valid combination of presentation options.");
        }
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
    webView = myDocument.mainWindowController.webView;
    browserWindow = myDocument.mainWindowController.window;
#ifdef DEBUG
    NSLog(@"MainBrowserWindow (1) sharingType: %lx",(long)[browserWindow sharingType]);
#endif
    [browserWindow setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
#ifdef DEBUG
    NSLog(@"MainBrowserWindow (2) sharingType: %lx",(long)[browserWindow sharingType]);
#endif
    // Set window and webView delegates to the main browser window
    [browserWindow setDelegate:mainBrowserWindow];
    [mainBrowserWindow setWebView:webView];
    [webView setFrameLoadDelegate:mainBrowserWindow];
	[webView setPolicyDelegate:mainBrowserWindow];
    /*	[browserWindow
	 setFrame:[browserWindow frameRectForContentRect:[[browserWindow screen] frame]]
	 display:YES]; // REMOVE wrong frame for window!*/
	[browserWindow setFrame:[[browserWindow screen] frame] display:YES];
    if (![[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToThirdPartyApps"]) {
        [browserWindow newSetLevel:NSModalPanelWindowLevel];
        //[browserWindow newSetLevel:NSScreenSaverWindowLevel];
#ifdef DEBUG
        NSLog(@"MainBrowserWindow (3) sharingType: %lx",(long)[browserWindow sharingType]);
#endif
    }
	[NSApp activateIgnoringOtherApps: YES];
    
    // Setup bindings to the preferences window close button
    NSButton *closeButton = [browserWindow standardWindowButton:NSWindowCloseButton];
    //NSDictionary *bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:nil];
    //NSDictionary *bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:
    //@"NSIsNil",NSValueTransformerNameBindingOption,nil];
    [closeButton bind:@"enabled"
             toObject:sebEncryptedUDController 
          withKeyPath:@"values.org_safeexambrowser_SEB_allowQuit" 
              options:nil];
    
	[browserWindow makeKeyAndOrderFront:self];
        
	// Load start URL from the system's user defaults database
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	//NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];

    // Add "SEB" to the browser's user agent, so the LMS SEB plugins recognize us
	NSString *customUserAgent = [webView userAgentForURL:[NSURL URLWithString:urlText]];
	[webView setCustomUserAgent:[customUserAgent stringByAppendingString:@" SEB"]];
    
    // We prevent the web view from maintaining any history, cache, or AutoFill information for the pages being visited
    [[webView preferences] setPrivateBrowsingEnabled:NO];
    
	// Load start URL into browser window
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlText]]];
}


- (NSString*) showEnterPasswordDialog: (NSWindow *)window {
// User has asked to see the dialog. Display it.
    [enterPassword setStringValue:@""]; //reset the enterPassword NSSecureTextField
    
    [NSApp beginSheet: enterPasswordDialog
       modalForWindow: window
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    [NSApp runModalForWindow: enterPasswordDialog];
    // Dialog is up here.
    [NSApp endSheet: enterPasswordDialog];
    [enterPasswordDialog orderOut: self];
    return ([enterPassword stringValue]);
}


- (IBAction) okEnterPassword: (id)sender {
    [NSApp stopModal];
}


- (IBAction) cancelEnterPassword: (id)sender {
    [NSApp stopModal];
    [enterPassword setStringValue:@""];
}


- (IBAction) exitSEB:(id)sender {
	// Load quitting preferences from the system's user defaults database
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	NSData *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowQuit"] == YES) {
		// if quitting SEB is allowed
		
        if (![hashedQuitPassword isEqualToData:[NSData data]]) {
			// if quit password is set, then restrict quitting
            NSString *password = [self showEnterPasswordDialog:browserWindow];
			
            if ([hashedQuitPassword isEqualToData:[self generateSHAHash:password]]) {
				// if the correct quit password was entered
				quittingMyself = TRUE; //SEB is terminating itself
                [NSApp terminate: nil]; //quit SEB
            }
        } else {
        // if no quit password is required, then confirm quitting
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
    } 
}


- (void) openPreferences:(id)sender {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (![preferencesController preferencesAreOpen]) {
        // Load admin password from the system's user defaults database
        NSData *hashedAdminPW = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
        if (![hashedAdminPW isEqualToData:[NSData data]]) {
            // If admin password is set, then restrict access to the preferences window  
            NSString *password = [self showEnterPasswordDialog:browserWindow];
            if (![hashedAdminPW isEqualToData:[self generateSHAHash:password]]) {
                //if hash of entered password is not equal to the one in preferences
                return;
            }         
        }
    }
    //savedStartURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    savedStartURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    savedAllowSwitchToThirdPartyAppsFlag = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToThirdPartyApps"];
	[preferencesController showPreferences:self];
}


- (void)preferencesClosed:(NSNotification *)notification
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (savedAllowSwitchToThirdPartyAppsFlag != [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToThirdPartyApps"]) {
        //preferences were closed and the third party app setting was changed
        //so we adjust the kiosk settings
        [self startKioskMode];
        [self requestedRestart:nil];
    } else {
        //if (![savedStartURL isEqualToString:[preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"]]) 
        if (![savedStartURL isEqualToString:[preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"]]) 
        {
            [self requestedRestart:nil];
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
}


- (void)requestedShowAbout:(NSNotification *)notification
{
    [aboutWindow setStyleMask:NSBorderlessWindowMask];
	[aboutWindow center];
	//[aboutWindow orderFront:self];
    //[aboutWindow setLevel:NSScreenSaverWindowLevel];
    [[NSApplication sharedApplication] runModalForWindow:aboutWindow];
}


- (void)requestedShowHelp:(NSNotification *)notification
{
    // Load manual page URL into browser window
    NSString *urlText = @"http://www.safeexambrowser.org/macosx";
	[[webView mainFrame] loadRequest:
     [NSURLRequest requestWithURL:[NSURL URLWithString:urlText]]];
    
}


- (void)closeDocument:(id) document
{
    [document close];
}

- (void)switchPluginsOn:(NSNotification *)notification
{
#ifndef __i386__        // Plugins can't be switched on in the 32-bit Intel build
    [[webView preferences] setPlugInsEnabled:YES];
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
	
	// Clear the browser cache in ~/Library/Caches/org.safeexambrowser.SEB.Safe-Exam-Browser/
	NSURLCache *cache = [NSURLCache sharedURLCache];
	[cache removeAllCachedResponses];
    
    // Clear Pasteboard
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard]; 
    [pasteboard clearContents];

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
		//the current Presentation Options changed, so make SEB active and reset them
        // Load preferences from the system's user defaults database
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        BOOL allowSwitchToThirdPartyApps = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToThirdPartyApps"];
#ifdef DEBUG
        NSLog(@"currentSystemPresentationOptions changed!");
#endif
        // If plugins are enabled and there is a Flash view in the webview ...
        if ([[webView preferences] arePlugInsEnabled]) {
            NSView* flashView = [mainBrowserWindow findFlashViewInView:webView];
            if (flashView) {
                if (!allowSwitchToThirdPartyApps || ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowFlashFullscreen"]) {
                    // and either third party Apps or Flash fullscreen is allowed
                    //... then we switch plugins off and on again to prevent 
                    //the security risk Flash full screen video
#ifndef __i386__        // Plugins can't be switched on in the 32-bit Intel build
                    [[webView preferences] setPlugInsEnabled:NO];
                    [[webView preferences] setPlugInsEnabled:YES];
#endif
                } else {
                    //or we set the flag that Flash tried to switch presentation options
                    [[MyGlobals sharedMyGlobals] setFlashChangedPresentationOptions:YES];
                }
            }
        }
        [self startKioskMode];
        [browserWindow setFrame:[[browserWindow screen] frame] display:YES];
        if (!allowSwitchToThirdPartyApps) {
            // If third party Apps are not allowed, we switch back to SEB
            [NSApp activateIgnoringOtherApps: YES];
            [browserWindow makeKeyAndOrderFront:self];
            //[self startKioskMode];
            [self regainActiveStatus:nil];
            //[browserWindow setFrame:[[browserWindow screen] frame] display:YES];
        }
    }	
}
 
@end
