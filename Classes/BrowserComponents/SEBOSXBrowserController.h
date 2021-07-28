//
//  SEBOSXBrowserController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06/10/14.
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
@class SEBBrowserWindowDocument;
@class SEBBrowserWindow;
@class SEBWebView;

@interface SEBOSXBrowserController : SEBBrowserController <WebResourceLoadDelegate, NSURLSessionTaskDelegate, SEBBrowserControllerDelegate, SEBAbstractWebViewNavigationDelegate>
{
    @private
    NSURL *currentConfigPath;

}

@property (weak, nonatomic) SEBController *sebController;
@property (readwrite) BOOL openingSettings;

@property (weak, nonatomic) SEBAbstractWebView *mainWebView;
@property (strong, nonatomic) SEBBrowserWindow *mainBrowserWindow;

@property (weak, nonatomic) SEBBrowserWindow *activeBrowserWindow;
@property (weak, nonatomic) SEBDockController *dockController;
@property (strong, nonatomic) NSString *activeBrowserWindowTitle;

@property (strong, nonatomic) NSString *currentMainHost;
@property (strong) NSMutableArray *openBrowserWindowsWebViews;
@property (strong) SEBDockItemMenu *openBrowserWindowsWebViewsMenu;
@property (readwrite) BOOL reinforceKioskModeRequested;
@property (readwrite) BOOL allowSpellCheck;
@property (strong, nonatomic) NSArray *privatePasteboardItems;
@property (strong) NSTimer *panelWatchTimer;

- (NSScreen *) mainScreen;

- (void) resetBrowser;

// Save the default user agent of the installed WebKit version
- (void) createSEBUserAgentFromDefaultAgent:(NSString *)defaultUserAgent;
- (SEBAbstractWebView *) openAndShowWebView;
- (void) checkForClosingTemporaryWebView:(SEBAbstractWebView *) webViewToClose;
- (void) webViewShow:(SEBAbstractWebView *)sender;
- (void) openMainBrowserWindow;

- (NSRect) visibleFrameForScreen:(NSScreen *)screen;
- (void) adjustMainBrowserWindow;
- (void) moveAllBrowserWindowsToScreen:(NSScreen *)screen;
- (void) browserWindowsChangeLevelAllowApps:(BOOL)allowApps;
- (void) closeAllBrowserWindows;
- (void) closeAllAdditionalBrowserWindows;

- (void) openURLString:(NSString *)urlText withSEBUserAgentInWebView:(SEBAbstractWebView *)webView;
- (void) openResourceWithURL:(NSString *)URL andTitle:(NSString *)title;

- (NSString *) placeholderTitleOrURLForActiveWebpage;

- (BOOL) isReconfiguringAllowedFromURL:(NSURL *)url;
- (void) openConfigFromSEBURL:(NSURL *)url;
- (void) openingConfigURLFailed;

- (void) downloadSEBConfigFileFromURL:(NSURL *)url originalURL:(NSURL *)originalURL;

- (void) openDownloadedSEBConfigData:(NSData *)sebFileData fromURL:(NSURL *)url originalURL:(NSURL *)originalURL;
- (void) openingConfigURLRoleBack;

- (void) setTitle:(NSString *)title forWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBAbstractWebView *)webView;
- (void) setStateForWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBAbstractWebView *)webView;
- (void) activateNextOpenWindow;
- (void) activatePreviousOpenWindow;

- (void) backToStartCommand;
- (void) reloadCommand;

- (void) showEnterUsernamePasswordDialog:(NSString *)text
                          modalForWindow:(NSWindow *)window
                             windowTitle:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector;


/// SEBBrowserControllerDelegate Methods

- (void) showEnterUsernamePasswordDialog:(NSString *)text
                                   title:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector;


@end
