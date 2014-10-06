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
}


- (void)windowDidBecomeMain:(NSNotification *)notification {
#ifdef DEBUG
    NSLog(@"BrowserWindow %@ did become main", self);
#endif
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
    
    // Post a notification that the main screen changed
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"mainScreenChanged" object:self];

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

@end
