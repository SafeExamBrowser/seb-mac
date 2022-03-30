//
//  BrowserWindowController.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 17.01.12.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebView.h>
#import "SEBBrowserWindow.h"
#import "SEBBrowserWindowAccessoryView.h"
#import "SEBOSXBrowserController.h"

@class SEBBrowserWindow;
@class SEBBrowserWindowAccessoryView;
@class SEBOSXBrowserController;

@interface SEBBrowserWindowController : NSWindowController <NSWindowDelegate>
{
@private
    NSRect frameForNonFullScreenMode;
    BOOL dragStarted;
    NSPoint dragCursorStartPosition;
}

@property (assign) NSRect frameForNonFullScreenMode;
@property (weak) IBOutlet NSView *rootView;
@property (readonly, nonatomic) SEBBrowserWindow *browserWindow;
//@property (weak) IBOutlet SEBAbstractWebView *webView;
@property (weak) IBOutlet NSButton *toolbarGoToDockButton;
@property (strong, nonatomic) IBOutlet SEBBrowserWindowAccessoryView *accessoryView;
@property (weak) IBOutlet NSButton *accessoryViewGoToDockButton;
@property (nonatomic, readwrite) BOOL isAccessoryViewGoToDockButtonHidden;
@property (strong, nonatomic) NSTitlebarAccessoryViewController *accessoryViewController;
@property (weak) IBOutlet NSSegmentedControl *backForwardButtons;
@property (weak) IBOutlet NSSearchField *textSearchField;
@property (weak) IBOutlet NSSegmentedControl *textSearchPreviousNext;
- (void) searchTextNext;
- (void) searchTextPrevious;
@property (weak) IBOutlet NSButton *textSearchDone;
@property (weak) IBOutlet NSButton *toolbarReloadButton;
@property (weak) SEBOSXBrowserController *browserController;
@property (strong, nonatomic) NSScreen *previousScreen;
@property (strong, nonatomic) NSTimer *windowWatchTimer;

@property (strong, nonatomic) NSString *searchText;
- (void) searchTextMatchFound:(BOOL)matchFound;

- (void) activateInitialFirstResponder;

- (IBAction) backForward: (id)sender;
- (IBAction) zoomText: (id)sender;
- (IBAction) zoomPage: (id)sender;


@end
