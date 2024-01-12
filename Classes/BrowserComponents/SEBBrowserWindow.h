//
//  BrowserWindow.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 06.12.10.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Browser window class, also containing all the web view delegates

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "SEBBrowserWindowController.h"
#import "SEBOSXWebViewController.h"
#import "SEBAbstractWebView.h"
#import "SEBEncryptedUserDefaultsController.h"
#import "SEBOSXBrowserController.h"
#import "SEBTextField.h"

NS_ASSUME_NONNULL_BEGIN

@class SEBOSXWebViewController;
@class SEBAbstractWebView;
@class SEBOSXBrowserController;


@interface SEBBrowserWindow : NSWindow <NSWindowDelegate, NSTextViewDelegate, SEBAbstractBrowserControllerDelegate, SEBAbstractWebViewNavigationDelegate>

@property (strong, nonatomic) id<SEBAbstractBrowserControllerDelegate> browserControllerDelegate;
@property (weak) SEBOSXBrowserController *browserController;
@property (nonatomic, strong) SEBOSXWebViewController<SEBAbstractBrowserControllerDelegate> *visibleWebViewController;
@property (nullable, strong, nonatomic) SEBAbstractWebView *webView;
@property (nullable, strong, nonatomic) NSURL *currentURL;
@property (strong, nonatomic) NSString *javaScriptFunctions;
@property (readwrite) BOOL isMainBrowserWindow;
@property (strong) IBOutlet NSWindow *URLFilterAlert;
@property (strong) IBOutlet NSWindow *customAlert;
@property (weak) IBOutlet SEBTextField *customAlertText;
@property (weak) IBOutlet SEBTextField *URLFilterAlertText;
@property (strong) IBOutlet NSURL *URLFilterAlertURL;
@property (strong) NSString *filterExpression;
@property (weak) IBOutlet NSMatrix *filterPatternMatrix;
@property (strong) IBOutlet NSTextView *filterExpressionField;
@property BOOL isFullScreen;
@property BOOL isPanel;
@property (weak) IBOutlet NSButton *domainPatternButton;
@property (weak) IBOutlet NSButton *hostPatternButton;
@property (weak) IBOutlet NSButton *hostPathPatternButton;
@property (weak) IBOutlet NSButton *directoryPatternButton;
@property (strong) NSView *progressIndicatorHolder;
@property (strong) NSView *filterMessageHolder;
@property (strong) NSPanel *filterMessageHUD;

- (void)addConstraintsToWebView:(NSView*) nativeWebView;

- (void) performFindPanelAction:(id)sender;
- (void) searchText;
- (void) searchTextNext;
- (void) searchTextPrevious;

@property (readwrite) BOOL toolbarWasHidden;
- (void) conditionallyDisplayToolbar;

- (void) setCalculatedFrame;
- (void) setCalculatedFrameOnScreen:(NSScreen *)screen;
- (void) setCalculatedFrameOnScreen:(NSScreen *)screen mainBrowserWindow:(BOOL)mainBrowserWindow temporaryWindow:(BOOL)temporaryWindow;

- (void) startProgressIndicatorAnimation;
- (void) stopProgressIndicatorAnimation;
- (void) activateInitialFirstResponder;
- (void) makeContentFirstResponder;
- (void) goToDock;


@end

NS_ASSUME_NONNULL_END
