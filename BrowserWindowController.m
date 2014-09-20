//
//  BrowserWindowController.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 17.01.12.
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

#import "BrowserWindowController.h"
#import "MyGlobals.h"
#import <WebKit/WebKit.h>
#import "BrowserWindow.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"


@implementation BrowserWindowController

@synthesize webView;
@synthesize frameForNonFullScreenMode;


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        [self setShouldCascadeWindows:NO];
        // Display or don't display toolbar
//        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"] && ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_hideBrowserWindowToolbar"])
//        {
//            [self.window.toolbar setVisible:YES];
//        } else {
//            [self.window.toolbar setVisible:NO];
//        }
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    BrowserWindow *browserWindow = (BrowserWindow *)self.window;
    [browserWindow setCalculatedFrame];
    //[browserWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
//    [browserWindow setCollectionBehavior:NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];
//    [browserWindow setLevel:NSDockWindowLevel];
//    [browserWindow setLevel:kCGMainMenuWindowLevel-1];

    // Display or don't display toolbar
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"] && ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_hideBrowserWindowToolbar"])
    {
        [self.window.toolbar setVisible:YES];
    } else {
        [self.window.toolbar setVisible:NO];
    }
}


- (void)windowDidBecomeMain:(NSNotification *)notification {
#ifdef DEBUG
    NSLog(@"BrowserWindow %@ did become main", self);
#endif
    // Display or don't display toolbar
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"] && ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_hideBrowserWindowToolbar"]) {
        [self.window.toolbar setVisible:YES];
    } else {
        [self.window.toolbar setVisible:NO];
    }

    if ([[MyGlobals sharedMyGlobals] shouldGoFullScreen] == YES) {
#ifdef DEBUG
        NSLog(@"browserWindow shouldGoFullScreen == YES");
#endif
        if (!([self.window styleMask] & NSFullScreenWindowMask)) {
            if (!self.window.toolbar.isVisible) {
                [self.window setToolbar:nil];
            }
#ifdef DEBUG
            NSLog(@"browserWindow toggleFullScreen, setToolbar = nil.");
#endif
            [self.window toggleFullScreen:self];
            [[MyGlobals sharedMyGlobals] setShouldGoFullScreen: NO];
        }
    }
    
}


/*- (id)webView
{
    return webView;
}
*/

- (BOOL)shouldCloseDocument
{
    return YES;
}


// Overriding this method without calling super in OS X 10.7 Lion
// prevents the windows' position and size to be restored on restarting the app
- (void)restoreStateWithCoder:(NSCoder *)coder
{
#ifdef DEBUG
    NSLog(@"BrowserWindowController %@: Prevented windows' position and size to be restored!", self);
#endif
    return;
}


- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    // Check data source of web view
    if (![[[self webView] mainFrame] dataSource]) {
        NSString* appTitleString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
        appTitleString = [NSString stringWithFormat:@"Safe Exam Browser %@", appTitleString];
#ifdef DEBUG
        NSLog(@"BrowserWindow %@: Title of current Page: %@", self.window, appTitleString);
        NSLog(@"BrowserWindow (2) sharingType: %lx",(long)[self.window sharingType]);
#endif
        return appTitleString;
    }
    return @"";
}


- (IBAction) backForward: (id)sender
{
    if ([sender selectedSegment] == 0) {
        [self.webView goBack:self];
    } else {
        [self.webView goForward:self];
    }
}


- (IBAction) zoomText: (id)sender
{
    if ([sender selectedSegment] == 0) {
        [self.webView makeTextSmaller:self];
    } else {
        [self.webView makeTextLarger:self];
    }
}


// -------------------------------------------------------------------------------
//	window:willUseFullScreenContentSize:proposedSize
//
//  A window's delegate can optionally override this method, to specify a different
//  Full Screen size for the window. This delegate method override's the window's full
//  screen content size to include a border around it.
// -------------------------------------------------------------------------------
- (NSSize)window:(NSWindow *)window willUseFullScreenContentSize:(NSSize)proposedSize
{
    // leave a border around our full screen window
    //return NSMakeSize(proposedSize.width - 180, proposedSize.height - 100);
    NSSize idealWindowSize = NSMakeSize(proposedSize.width, proposedSize.height - 0);
    
    // Constrain that ideal size to the available area (proposedSize).
    NSSize customWindowSize;
    customWindowSize.width  = MIN(idealWindowSize.width,  proposedSize.width);
    customWindowSize.height = MIN(idealWindowSize.height, proposedSize.height);
    
    // Return the result.
    return customWindowSize;
}

// -------------------------------------------------------------------------------
//	window:willUseFullScreenPresentationOptions:proposedOptions
//
//  Delegate method to determine the presentation options the window will use when
//  transitioning to full-screen mode.
// -------------------------------------------------------------------------------
- (NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions
{
    // customize the appearance when entering full screen:
    // Set a global flag that we're transitioning to full screen
    [[MyGlobals sharedMyGlobals] setTransitioningToFullscreen:YES];

	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
	BOOL showMenuBar = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showMenuBar"];
	BOOL enableToolbar = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"];
	BOOL hideToolbar = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_hideBrowserWindowToolbar"];
    NSApplicationPresentationOptions presentationOptions;

    if (!allowSwitchToThirdPartyApps) {
		// if switching to third party apps not allowed
        presentationOptions =
        NSApplicationPresentationDisableAppleMenu +
        NSApplicationPresentationHideDock +
        NSApplicationPresentationFullScreen +
        (enableToolbar && hideToolbar ?
         NSApplicationPresentationAutoHideToolbar + NSApplicationPresentationAutoHideMenuBar :
         (showMenuBar ? 0 : NSApplicationPresentationHideMenuBar)) +
        NSApplicationPresentationDisableProcessSwitching +
        NSApplicationPresentationDisableForceQuit +
        NSApplicationPresentationDisableSessionTermination;
    } else {
		// if switching to third party apps allowed
        presentationOptions =
        NSApplicationPresentationDisableAppleMenu +
        NSApplicationPresentationHideDock +
        NSApplicationPresentationFullScreen +
        (enableToolbar && hideToolbar ?
         NSApplicationPresentationAutoHideToolbar + NSApplicationPresentationAutoHideMenuBar :
         (showMenuBar ? 0 : NSApplicationPresentationHideMenuBar)) +
        NSApplicationPresentationDisableForceQuit +
        NSApplicationPresentationDisableSessionTermination;
    }
#ifdef DEBUG
    NSLog(@"browserWindow willUseFullScreenPresentationOptions: %lo", presentationOptions);
#endif
    [[MyGlobals sharedMyGlobals] setPresentationOptions:presentationOptions];
    return presentationOptions;
}


#pragma mark -
#pragma mark Enter Full Screen

// as a window delegate, window delegate we provide a list of windows involved in our custom animation,
// in our case we animate just the one primary window.
//
- (NSArray *)customWindowsToEnterFullScreenForWindow:(NSWindow *)window
{
    return [NSArray arrayWithObject:window];
}

- (void)window:(NSWindow *)window startCustomAnimationToEnterFullScreenWithDuration:(NSTimeInterval)duration
{
#ifdef DEBUG
    NSLog(@"NSWindow %@ startCustomAnimationToEnterFullScreenWithDuration:", window);
#endif

    self.frameForNonFullScreenMode = [window frame];
    [self invalidateRestorableState];
    
//    NSInteger previousWindowLevel = [window level];
//    [window setLevel:(NSModalPanelWindowLevel + 1)];
//    [window setLevel:NSScreenSaverWindowLevel];
    //[window setLevel:previousWindowLevel + 1];
    
    [window setStyleMask:([window styleMask] | NSFullScreenWindowMask)];
    
    NSScreen *screen = [[NSScreen screens] objectAtIndex:0];
    NSRect screenFrame = [screen frame];
    
    NSRect proposedFrame = screenFrame;
    proposedFrame.size = [self window:window willUseFullScreenContentSize:proposedFrame.size];
    
    proposedFrame.origin.x += floor(0.5 * (NSWidth(screenFrame) - NSWidth(proposedFrame)));
    proposedFrame.origin.y += floor(0.5 * (NSHeight(screenFrame) - NSHeight(proposedFrame)));
    
    // The center frame for each window is used during the 1st half of the fullscreen animation and is
    // the window at its original size but moved to the center of its eventual full screen frame.
    NSRect centerWindowFrame = [window frame];
    centerWindowFrame.origin.x = proposedFrame.size.width/2 - centerWindowFrame.size.width/2;
    centerWindowFrame.origin.y = proposedFrame.size.height/2 - centerWindowFrame.size.height/2;
    
    // If our window animation takes the same amount of time as the system's animation,
    // a small black flash will occur atthe end of your animation.  However, if we
    // leave some extra time between when our animation completes and when the system's animation
    // completes we can avoid this.
    duration -= 0.2;
    
    // Our animation will be broken into two stages.  First, we'll move the window to the center
    // of the primary screen and then we'll enlarge it its full screen size.
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        
        [context setDuration:duration/2];
        [[window animator] setFrame:centerWindowFrame display:YES];
        
    } completionHandler:^{
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            
            [context setDuration:duration/2];
            [[window animator] setFrame:proposedFrame display:YES];
            
        } completionHandler:^{
            
            //  [self.window setLevel:previousWindowLevel];
        }];
    }];
}

- (void)windowDidFailToEnterFullScreen:(NSWindow *)window
{
    // If we had any cleanup to perform in the event of failure to enter Full Screen,
    // this would be the place to do it.
    //
    // One case would be if the user attempts to move to full screen but then
    // immediately switches to Dashboard.
#ifdef DEBUG
    NSLog(@"windowDidFailToEnterFullScreen: %@", window);
#endif
    // Set toolbar after window failed to enter full screen, as there is a bug
    // not respecting toolbar.isVisible when entering full screen
    [self.window setToolbar:self.toolbar];

    // Display or don't display toolbar
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"] && ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_hideBrowserWindowToolbar"])
    {
        [self.window.toolbar setVisible:YES];
    } else {
        [self.window.toolbar setVisible:NO];
    }
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"windowDidEnterFullScreen, setToolbar again.");
#endif
    // Set toolbar after window entered full screen, as there is a bug
    // not respecting toolbar.isVisible when entering full screen
    [self.window setToolbar:self.toolbar];

    // Display or don't display toolbar
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"] && ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_hideBrowserWindowToolbar"])
    {
        [self.window.toolbar setVisible:YES];
    } else {
        [self.window.toolbar setVisible:NO];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"requestStartKioskMode" object:self];
}


#pragma mark -
#pragma mark Exit Full Screen

- (NSArray *)customWindowsToExitFullScreenForWindow:(NSWindow *)window
{
    return [NSArray arrayWithObject:window];
}

- (void)window:(NSWindow *)window startCustomAnimationToExitFullScreenWithDuration:(NSTimeInterval)duration
{
#ifdef DEBUG
    NSLog(@"NSWindow %@ startCustomAnimationToExitFullScreenWithDuration:", window);
#endif
    
    [(BrowserWindow *)window setConstrainingToScreenSuspended:YES];
    
//    NSInteger previousWindowLevel = [window level];
//    [window setLevel:(NSModalPanelWindowLevel + 1)];
//    [window setLevel:NSScreenSaverWindowLevel];
    //[window setLevel:previousWindowLevel + 1];

    [window setStyleMask:([window styleMask] & ~NSFullScreenWindowMask)];
    
    // The center frame for each window is used during the 1st half of the fullscreen animation and is
    // the window at its original size but moved to the center of its eventual full screen frame.
    NSRect centerWindowFrame = self.frameForNonFullScreenMode;
    centerWindowFrame.origin.x = window.frame.size.width/2 - self.frameForNonFullScreenMode.size.width/2;
    centerWindowFrame.origin.y = window.frame.size.height/2 - self.frameForNonFullScreenMode.size.height/2;
    
    // Our animation will be broken into two stages.  First, we'll restore the window
    // to its original size while centering it and then we'll move it back to its initial
    // position.
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context)
     {
         [context setDuration:duration/2];
         [[window animator] setFrame:centerWindowFrame display:YES];
         
     } completionHandler:^{
         
         [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
             [context setDuration:duration/2];
             [[window animator] setFrame:self.frameForNonFullScreenMode display:YES];
             
         } completionHandler:^{
             
             [(BrowserWindow *)window setConstrainingToScreenSuspended:NO];
             
             //[self.window setLevel:previousWindowLevel];
         }];
         
     }];
}

- (void)windowDidFailToExitFullScreen:(NSWindow *)window
{
    // If we had any cleanup to perform in the event of failure to exit Full Screen,
    // this would be the place to do it.
    // ...
#ifdef DEBUG
    NSLog(@"windowDidFailToExitFullScreen: %@", window);
#endif
}

- (void)windowDidExitFullScreen:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"windowDidExitFullScreen");
#endif
//    [[NSNotificationCenter defaultCenter]
//     postNotificationName:@"requestReinforceKioskMode" object:self];
}


#pragma mark -
#pragma mark Full Screen Support: Persisting and Restoring Window's Non-FullScreen Frame

+ (NSArray *)restorableStateKeyPaths
{
    return [[super restorableStateKeyPaths] arrayByAddingObject:@"frameForNonFullScreenMode"];
}


@end
