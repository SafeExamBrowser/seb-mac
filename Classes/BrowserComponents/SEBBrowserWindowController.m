//
//  BrowserWindowController.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 17.01.12.
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

#import "SEBBrowserWindowController.h"
#import <WebKit/WebKit.h>
#import "SEBBrowserWindow.h"


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
//    [self.browserController setStateForWindow:(SEBBrowserWindow *)self.window withWebView:self.webView];
    self.browserController.activeBrowserWindow = (SEBBrowserWindow *)self.window;
    DDLogDebug(@"BrowserWindow %@ did become key", self.window);
}


- (void)windowDidChangeScreen:(NSNotification *)notification
{
    // Check if Window is too heigh for the new screen
    // Get screen visible frame
    NSRect newFrame = self.window.screen.visibleFrame;
    
    // Check if SEB Dock is displayed and reduce visibleFrame accordingly
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"]) {
        CGFloat dockHeight = [preferences secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
        newFrame.origin.y += dockHeight;
        newFrame.size.height -= dockHeight;
    }
    NSRect oldWindowFrame = self.window.frame;
    if (oldWindowFrame.size.height > newFrame.size.height) {
        NSRect newWindowFrame = NSMakeRect(oldWindowFrame.origin.x, newFrame.origin.y, oldWindowFrame.size.width, newFrame.size.height);
        [self.window setFrame:newWindowFrame display:YES animate:YES];
    }
   
    // If this is the main browser window, check if it's still on the same screen as when the dock was opened
    if (self.window == self.browserController.mainBrowserWindow) {
        // Post a notification that the main screen changed
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"mainScreenChanged" object:self];
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
        [[NSApplication sharedApplication] sendAction:@selector(zoomPageOut:) to:self.webView from:self];
    } else {
        [[NSApplication sharedApplication] sendAction:@selector(zoomPageIn:) to:self.webView from:self];
    }
}

@end
