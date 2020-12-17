//
//  BrowserWindowController.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 17.01.12.
//  Copyright (c) 2010-2020 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2020 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import "SEBBrowserWindowController.h"
#import "MyGlobals.h"
#import <WebKit/WebKit.h>
#import "SEBBrowserWindow.h"
#import "NSScreen+SEBScreen.h"
#import <Carbon/Carbon.h>
#import <Foundation/Foundation.h>

#include <stdio.h>
#include <unistd.h>
#include "CGSPrivate.h"


WindowRef FrontWindow(void);
void DisposeWindow (
                    WindowRef window
                    );


@implementation SEBBrowserWindowController

@synthesize webView;
@synthesize frameForNonFullScreenMode;


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        [self setShouldCascadeWindows:NO];
        if (@available(macOS 11, *)) {
            self.window.toolbarStyle = NSWindowToolbarStyleExpanded;
        }
    }
    
    return self;
}


#pragma mark Delegates

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    SEBBrowserWindow *browserWindow = (SEBBrowserWindow *)self.window;
    
    // Set the reference to the browser controller in the browser window instance
    browserWindow.browserController = _browserController;

    [browserWindow setCalculatedFrameOnScreen:[_browserController mainScreen]];
    self.browserController.activeBrowserWindow = (SEBBrowserWindow *)self.window;
    _previousScreen = self.window.screen;
    
    NSString *keyAllowNavigation;
    NSString *keyAllowReload;
    if (!self.browserController.mainBrowserWindow || browserWindow == self.browserController.mainBrowserWindow) {
        [browserWindow.webView bind:@"maintainsBackForwardList"
                  toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
               withKeyPath:@"values.org_safeexambrowser_SEB_allowBrowsingBackForward"
                   options:nil];
        keyAllowNavigation = @"org_safeexambrowser_SEB_allowBrowsingBackForward";
        keyAllowReload = @"org_safeexambrowser_SEB_browserWindowAllowReload";
    } else {
        [browserWindow.webView bind:@"maintainsBackForwardList"
                  toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
               withKeyPath:@"values.org_safeexambrowser_SEB_newBrowserWindowNavigation"
                   options:nil];
        keyAllowNavigation = @"org_safeexambrowser_SEB_newBrowserWindowNavigation";
        keyAllowReload = @"org_safeexambrowser_SEB_newBrowserWindowAllowReload";
    }
    
    BOOL allowNavigation = [[NSUserDefaults standardUserDefaults] secureBoolForKey:keyAllowNavigation];
    [self.backForwardButtons setHidden:!allowNavigation];
    BOOL allowReload = [[NSUserDefaults standardUserDefaults] secureBoolForKey:keyAllowReload];
    [self.toolbarReloadButton setHidden:!allowReload];
    
    NSApp.presentationOptions |= (NSApplicationPresentationDisableForceQuit | NSApplicationPresentationHideDock);
}


- (void)windowDidBecomeMain:(NSNotification *)notification
{
    DDLogDebug(@"BrowserWindow %@ did become main", self.window);
    if (self.browserController.reinforceKioskModeRequested) {
        self.browserController.reinforceKioskModeRequested = NO;
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestReinforceKioskMode" object:self];
    }
    self.browserController.activeBrowserWindow = (SEBBrowserWindow *)self.window;
    [self.browserController setStateForWindow:(SEBBrowserWindow *)self.window withWebView:self.webView];
    
    // If this is the main browser window, check if it's still on the same screen as when the dock was opened
    if (self.window == self.browserController.mainBrowserWindow) {
        if (self.window.screen != self.browserController.dockController.window.screen) {
            // Post a notification that the main screen changed
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"mainScreenChanged" object:self];
        }
    }
}


- (void)windowDidBecomeKey:(NSNotification *)notification
{
    self.browserController.activeBrowserWindow = (SEBBrowserWindow *)self.window;
    DDLogDebug(@"BrowserWindow %@ did become key", self.window);
}


- (void)windowDidResignKey:(NSNotification *)notification
{
    DDLogDebug(@"BrowserWindow %@ did resign key", self.window);
    
    NSWindow *keyWindow = [[NSApplication sharedApplication] keyWindow];
    DDLogDebug(@"Current key window: %@ with title %@", keyWindow, keyWindow.title);
    if (keyWindow) {
        if (keyWindow.isModalPanel) {
            DDLogWarn(@"Current key window is modal panel: %@", keyWindow);
        }
        if (keyWindow.isFloatingPanel) {
            DDLogWarn(@"Current key window is floating panel: %@", keyWindow);
        }
        if (keyWindow.isSheet) {
            DDLogWarn(@"Current key window is sheet: %@", keyWindow);
        }
    }
}


- (void)windowWillMove:(NSNotification *)notification
{
    DDLogDebug(@"BrowserWindow %@ will move", self.window);
    [self startWindowWatcher];
}


- (void)windowDidMove:(NSNotification *)notification
{
    DDLogDebug(@"BrowserWindow %@ did move", self.window);
    dragStarted = false;
}


- (void)windowWillClose:(NSNotification *)notification
{
    DDLogDebug(@"BrowserWindow %@ will close", self.window);
    
    if (_windowWatchTimer) {
        [_windowWatchTimer invalidate];
        _windowWatchTimer = nil;
    }
    self.window = nil;
    _browserController.activeBrowserWindow = nil;
}


// Start the windows watcher if it's not yet running
- (void)startWindowWatcher
{
#ifdef DEBUG
    DDLogDebug(@"%s", __FUNCTION__);
#endif
    
    if (!_windowWatchTimer) {
        NSDate *dateNow = [NSDate date];
        
        _windowWatchTimer = [[NSTimer alloc] initWithFireDate:dateNow
                                                     interval: 0.05
                                                       target: self
                                                     selector:@selector(windowScreenWatcher)
                                                     userInfo:nil repeats:YES];
        
        NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
        
        [currentRunLoop addTimer:_windowWatchTimer forMode: NSRunLoopCommonModes];
    }
}


// Start the windows watcher if it's not yet running
- (void)stopWindowWatcher
{
#ifdef DEBUG
    DDLogDebug(@"%s on thread %@", __FUNCTION__, [NSThread currentThread]);
#endif
    
    if (_windowWatchTimer) {
        [_windowWatchTimer invalidate];
        _windowWatchTimer = nil;
    }
    dragStarted = false;
    [self updateCoveringIntersectingInactiveScreens];
    // If window is still intersecting inactive screens (which are covered therefore)
    // or if it is outside of any screen
#ifdef DEBUG
    DDLogDebug(@"%s number of inactive screen covering windows %lu", __FUNCTION__, (unsigned long)_browserController.sebController.inactiveScreenWindows.count);
    DDLogDebug(@"%s window is currently on screen %@", __FUNCTION__, self.window.screen);
#endif
    
    NSScreen *currentScreen = self.window.screen;
    // Check if window is off-screen or the new screen is inactive
    if (currentScreen.inactive) {
        // Yes: Move the window back to the screen it has been on before
        currentScreen = _previousScreen;
#ifdef DEBUG
        DDLogDebug(@"Screen is inactive, move window back to previous screen %@", currentScreen);
#endif
    }

    // Move the window back to the screen is has been on previously
    [self adjustWindowForScreen:currentScreen moveBack:(_browserController.sebController.inactiveScreenWindows.count > 0)];
    [self updateCoveringIntersectingInactiveScreens];
}


- (void)windowScreenWatcher
{
    [self updateCoveringIntersectingInactiveScreens];

    NSUInteger pressedButtons = [NSEvent pressedMouseButtons];
    if ((pressedButtons & (1 << 0)) != (1 << 0)) {
        [self stopWindowWatcher];
    }
}


- (void)updateCoveringIntersectingInactiveScreens
{
    
    NSPoint cursorPosition = [NSEvent mouseLocation];
    
    if (!dragStarted) {
        dragStarted = true;
        // Save mouse position when starting dragging
        dragCursorStartPosition = cursorPosition;
    }
    NSRect windowFrame = self.window.frame;
    
    NSPoint cursorDisplacement = NSMakePoint(cursorPosition.x - dragCursorStartPosition.x, cursorPosition.y - dragCursorStartPosition.y);
    NSRect actualWindowFrame = NSMakeRect(windowFrame.origin.x + cursorDisplacement.x,
                                          windowFrame.origin.y + cursorDisplacement.y,
                                          windowFrame.size.width,
                                          windowFrame.size.height);

    // Get screens which the window frame intersects
    NSArray *allScreens = [NSScreen screens];
    NSMutableArray *intersectingScreens = [NSMutableArray new];
    for (NSScreen *screen in allScreens) {
        if (CGRectIntersectsRect(actualWindowFrame, screen.frame) && screen.inactive) {
            [intersectingScreens addObject:screen];
        }
    }
    
#ifdef DEBUG
    DDLogDebug(@"Window is on %lu inactive screen(s) and has frame %@",
               (unsigned long)intersectingScreens.count,
               (NSDictionary *)CFBridgingRelease(CGRectCreateDictionaryRepresentation(actualWindowFrame)));
#endif

    // Cover currently intersected inactive screens and
    // remove cover windows of no longer intersected screens
    [_browserController.sebController coverInactiveScreens:[intersectingScreens copy]];
    
}


- (void)windowDidChangeScreen:(NSNotification *)notification
{
    NSScreen *currentScreen = self.window.screen;
    BOOL movingWindowBack = false;
    DDLogDebug(@"windowDidChangeScreen to %@", currentScreen);
    // Check if window is off-screen or the new screen is inactive
    if (currentScreen.inactive) {
        // Yes: Move the window back to the screen it has been on before
        currentScreen = _previousScreen;
        movingWindowBack = true;
        DDLogDebug(@"Screen is inactive, move window back to previous screen %@", currentScreen);
    }
    [self adjustWindowForScreen:currentScreen moveBack:movingWindowBack];
}


- (void)adjustWindowForScreen:(NSScreen *)newScreen moveBack:(BOOL)movingWindowBack
{
    DDLogDebug(@"%s newScreen: %@ moveBack: %hhd (current screen: %@)", __FUNCTION__, newScreen, movingWindowBack, self.window.screen);
    NSUInteger pressedButtons = [NSEvent pressedMouseButtons];
    if (((pressedButtons & (1 << 0)) != (1 << 0))) {
        
        if (newScreen && !newScreen.inactive) {
            _previousScreen = newScreen;
        }
        
        // Check if Window is too heigh for the new screen
        // Get frame of the usable screen (considering if menu bar or SEB dock is enabled)
        NSRect newFrame = [_browserController visibleFrameForScreen:newScreen];
        
        if (movingWindowBack) {
            NSRect recalculatedFrame = NSMakeRect(newFrame.origin.x, newFrame.origin.y, self.window.frame.size.width, newFrame.size.height);
            [self.window setFrame:recalculatedFrame display:YES animate:YES];
            DDLogDebug(@"Moved browser window back to previous screen, frame: %@",
                       (NSDictionary *)CFBridgingRelease(CGRectCreateDictionaryRepresentation(recalculatedFrame)));
            
        } else {
            NSRect oldWindowFrame = self.window.frame;
            NSRect newWindowFrame = oldWindowFrame;
            if (oldWindowFrame.size.height > newFrame.size.height) {
                newWindowFrame = NSMakeRect(oldWindowFrame.origin.x, newFrame.origin.y, oldWindowFrame.size.width, newFrame.size.height);
                oldWindowFrame = newWindowFrame;
            }
            if (oldWindowFrame.size.width > newFrame.size.width) {
                newWindowFrame = NSMakeRect(newFrame.origin.x, oldWindowFrame.origin.y, newFrame.size.width, oldWindowFrame.size.height);
            }
            // Check if top of window is hidden below the dock (if visible)
            // or just slightly (20 points) above the bottom edge of the visible screen space
            if ((newWindowFrame.origin.y + newWindowFrame.size.height) < (newFrame.origin.y + kMenuBarHeight)) { //showDock * dockHeight +
                // In this case shift the window up
                newWindowFrame = NSMakeRect(newWindowFrame.origin.x, newFrame.origin.y, newWindowFrame.size.width, newWindowFrame.size.height);
            }
            
            [self.window setFrame:newWindowFrame display:YES animate:YES];
            DDLogDebug(@"Adjusted window frame for new screen to: %@",
                       (NSDictionary *)CFBridgingRelease(CGRectCreateDictionaryRepresentation(newWindowFrame)));
        }
        
        // If this is the main browser window, check if it's still on the same screen as when the dock was opened
        if (!movingWindowBack && self.window == self.browserController.mainBrowserWindow) {
            // Post a notification that the main screen changed
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"mainScreenChanged" object:self];
        }
        
    }
}


- (BOOL)shouldCloseDocument
{
    return YES;
}


// Overriding this method without calling super in OS X 10.7 Lion
// prevents the windows' position and size to be restored on restarting the app
- (void)restoreStateWithCoder:(NSCoder *)coder
{
    DDLogDebug(@"BrowserWindowController %@: Prevented windows' position and size to be restored!", self);
    return;
}


- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    // Check data source of web view
    if (![[[self webView] mainFrame] dataSource]) {
        NSString* appTitleString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
        appTitleString = [NSString stringWithFormat:@"Safe Exam Browser %@", appTitleString];
        DDLogInfo(@"BrowserWindow %@: Title of current Page: %@", self.window, appTitleString);
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


- (IBAction) zoomPage: (id)sender
{
    if ([sender selectedSegment] == 0) {
        SEL selector = NSSelectorFromString(@"zoomPageOut:");
        [[NSApplication sharedApplication] sendAction:selector to:self.webView from:self];
    } else {
        SEL selector = NSSelectorFromString(@"zoomPageIn:");
        [[NSApplication sharedApplication] sendAction:selector to:self.webView from:self];
    }
}

@end
