//
//  SEBOSXBrowserController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06/10/14.
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

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "SEBController.h"
#import "SEBBrowserWindow.h"
#import "SEBWebView.h"
#import "SEBDockController.h"
#import "SEBDockItemButton.h"
#import "SEBDockItemMenu.h"
#import "SEBBrowserController.h"
#import "SEBBrowserWindowDocument.h"

@class SEBController;
@class SEBBrowserController;
@class SEBBrowserWindowDocument;
@class SEBBrowserWindow;
@class SEBWebView;

@interface SEBOSXBrowserController : NSObject <WebResourceLoadDelegate, NSURLSessionTaskDelegate, SEBBrowserControllerDelegate>
{
    NSString *lastUsername;
}

@property (weak) SEBController *sebController;
@property (strong) SEBBrowserController *browserController;
@property (weak) SEBWebView *mainWebView;
@property (weak) SEBBrowserWindowDocument *temporaryBrowserWindowDocument;
@property (weak) SEBWebView *temporaryWebView;
@property (strong) SEBBrowserWindow *mainBrowserWindow;
@property (weak) SEBBrowserWindow *activeBrowserWindow;
@property (weak) SEBDockController *dockController;
@property (strong) NSString *currentMainHost;
@property (strong) NSMutableArray *openBrowserWindowsWebViews;
@property (strong) SEBDockItemMenu *openBrowserWindowsWebViewsMenu;
@property (readwrite) BOOL reinforceKioskModeRequested;
@property (readwrite) BOOL directConfigDownloadAttempted;
@property (readwrite) BOOL allowSpellCheck;
@property (strong) NSURL *originalURL;
@property (strong) NSURLCredential *enteredCredential;
@property (strong) id URLSession;
@property (strong) void (^pendingChallengeCompletionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential);
@property (strong) NSArray *privatePasteboardItems;
@property(strong) NSTimer *panelWatchTimer;


- (NSScreen *) mainScreen;

- (void) resetBrowser;

// Save the default user agent of the installed WebKit version
- (void) createSEBUserAgentFromDefaultAgent:(NSString *)defaultUserAgent;

- (SEBWebView *) openAndShowWebView;
- (void) closeWebView:(SEBWebView *) webViewToClose;
- (void) webViewShow:(SEBWebView *)sender;
- (void) openMainBrowserWindow;
- (void) clearBackForwardList;

- (NSRect) visibleFrameForScreen:(NSScreen *)screen;
- (void) adjustMainBrowserWindow;
- (void) moveAllBrowserWindowsToScreen:(NSScreen *)screen;
- (void) allBrowserWindowsChangeLevel:(BOOL)allowApps;
- (void) closeAllBrowserWindows;
- (void) closeAllAdditionalBrowserWindows;

- (void) openURLString:(NSString *)urlText withSEBUserAgentInWebView:(SEBWebView *)webView;
- (void) openResourceWithURL:(NSString *)URL andTitle:(NSString *)title;

- (void) openConfigFromSEBURL:(NSURL *)url;
- (void) openingConfigURLFailed;

- (void) downloadSEBConfigFileFromURL:(NSURL *)url;

- (void) setTitle:(NSString *)title forWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBWebView *)webView;
- (void) setStateForWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBWebView *)webView;

- (void) backToStartCommand;
- (void) reloadCommand;

- (void) showEnterUsernamePasswordDialog:(NSString *)text
                          modalForWindow:(NSWindow *)window
                             windowTitle:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector;
- (void) hideEnterUsernamePasswordDialog;


/// SEBBrowserControllerDelegate Methods

- (void) showEnterUsernamePasswordDialog:(NSString *)text
                                   title:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector;


@end
