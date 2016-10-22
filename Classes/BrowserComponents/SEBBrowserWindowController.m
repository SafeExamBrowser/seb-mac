//
//  BrowserWindowController.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 17.01.12.
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

#import "SEBBrowserWindowController.h"
#import "MyGlobals.h"
#import <WebKit/WebKit.h>
#import "SEBBrowserWindow.h"
#import "NSScreen+DisplayInfo.h"
#import <Carbon/Carbon.h>
#import <Foundation/Foundation.h>

#include <stdio.h>
#include <unistd.h>
#include "CGSPrivate.h"


WindowRef FrontWindow();
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
    }
    
    return self;
}


#pragma mark Delegates

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    SEBBrowserWindow *browserWindow = (SEBBrowserWindow *)self.window;
    [browserWindow setCalculatedFrame];
    self.browserController.activeBrowserWindow = (SEBBrowserWindow *)self.window;
    _previousScreen = self.window.screen;
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
    DDLogDebug(@"Current key window: %@", keyWindow);
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


// Start the windows watcher if it's not yet running
- (void)startWindowWatcher
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (!_windowWatchTimer) {
        NSDate *dateNextMinute = [NSDate date];
        
        _windowWatchTimer = [[NSTimer alloc] initWithFireDate: dateNextMinute
                                                     interval: 0.25
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
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (_windowWatchTimer) {
        [_windowWatchTimer invalidate];
        _windowWatchTimer = nil;
    }
    // If window is still intersecting inactive screens (which are covered therefore)
    if (_browserController.sebController.inactiveScreenWindows.count > 0) {
        // Move the window back to the screen is has been on previously
        [self adjustWindowForScreen:_previousScreen moveBack:true];
        [self updateCoveringIntersectingInactiveScreens];
    }
}


- (void)windowScreenWatcher
{
    [self updateCoveringIntersectingInactiveScreens];

    NSUInteger pressedButtons = [NSEvent pressedMouseButtons];
    if ((pressedButtons & (1 << 0)) != (1 << 0)) {
        [self stopWindowWatcher];
        dragStarted = false;
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
    
#define MAX_DISPLAYS (16)
    NSRect windowFrame;
    CGDirectDisplayID intersectingDisplays[MAX_DISPLAYS];
    CGDisplayCount displayCount;
    
    windowFrame = self.window.frame;
    
    NSPoint cursorDisplacement = NSMakePoint(cursorPosition.x - dragCursorStartPosition.x, cursorPosition.y - dragCursorStartPosition.y);
    NSRect actualWindowFrame = NSMakeRect(windowFrame.origin.x + cursorDisplacement.x,
                                          windowFrame.origin.y + cursorDisplacement.y,
                                          windowFrame.size.width,
                                          windowFrame.size.height);
    
    // Get online displays which the window frame intersects
    CGGetDisplaysWithRect(actualWindowFrame, MAX_DISPLAYS, intersectingDisplays, &displayCount);
#ifdef DEBUG
    DDLogDebug(@"Window is on %u screen(s) and has frame %@", displayCount,CGRectCreateDictionaryRepresentation(actualWindowFrame));
#endif
    NSMutableArray *inactiveScreensToCover = [NSMutableArray new];
    
    for(int i = 0; i < displayCount; i++)
    {
        CGDirectDisplayID display = intersectingDisplays[i];
        NSArray *inactiveDisplays = _browserController.sebController.inactiveDisplays.copy;
        NSUInteger indexOfDisplay = [inactiveDisplays indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([[obj valueForKey:@"displayID"] isEqualTo:[NSNumber numberWithInt:display]]) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        if (indexOfDisplay != NSNotFound) {
            [inactiveScreensToCover addObject:[inactiveDisplays[indexOfDisplay] valueForKey:@"screen"]];
        }
    }
    // Cover currently intersected inactive screens and
    // remove cover windows of no longer intersected screens
    [_browserController.sebController coverInactiveScreens:[inactiveScreensToCover copy]];
}


- (void)windowDidChangeScreen:(NSNotification *)notification
{
    NSScreen *currentScreen = self.window.screen;
    BOOL movingWindowBack = false;
    // Check if the new screen is inactive
    if (currentScreen.inactive) {
        // Yes: Move the window back to the screen it has been on before
        currentScreen = _previousScreen;
        movingWindowBack = true;
    }
    [self adjustWindowForScreen:currentScreen moveBack:movingWindowBack];
}


- (void)adjustWindowForScreen:(NSScreen *)currentScreen moveBack:(BOOL)movingWindowBack
{
    _previousScreen = currentScreen;
    
    // Check if Window is too heigh for the new screen
    // Get screen visible frame
    NSRect newFrame = currentScreen.visibleFrame;
    
    
    // Check if SEB Dock is displayed and reduce visibleFrame accordingly
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"]) {
        CGFloat dockHeight = [preferences secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
        newFrame.origin.y += dockHeight;
        newFrame.size.height -= dockHeight;
    }
    if (movingWindowBack) {
        [self.window setFrameOrigin:newFrame.origin];
        DDLogDebug(@"Moved browser window back to previous screen");
        
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
        [self.window setFrame:newWindowFrame display:YES animate:YES];
    }
    
    // If this is the main browser window, check if it's still on the same screen as when the dock was opened
    if (!movingWindowBack && self.window == self.browserController.mainBrowserWindow) {
        // Post a notification that the main screen changed
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"mainScreenChanged" object:self];
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
