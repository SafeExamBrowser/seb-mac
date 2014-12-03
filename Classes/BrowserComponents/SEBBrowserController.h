//
//  SEBBrowserController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06/10/14.
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

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "SEBBrowserWindow.h"
#import "SEBWebView.h"
#import "SEBDockController.h"
#import "SEBDockItemButton.h"
#import "SEBDockItemMenu.h"

@class SEBBrowserWindow;
@class SEBWebView;

@interface SEBBrowserController : NSObject

@property (strong) SEBWebView *webView;
@property (strong) SEBBrowserWindow *mainBrowserWindow;
@property (strong) SEBDockController *dockController;
@property (strong) SEBDockItemButton *sebDockItemButton;
@property (strong) NSString *currentMainHost;
@property (strong) NSMutableArray *openBrowserWindowsWebViews;
@property (strong) SEBDockItemMenu *openBrowserWindowsWebViewsMenu;
@property (readwrite) BOOL reinforceKioskModeRequested;

- (SEBWebView *) openWebView;
- (SEBWebView *) openAndShowWebView;
- (void) closeWebView:(SEBWebView *) webViewToClose;
- (void) webViewShow:(SEBWebView *)sender;
- (void) openMainBrowserWindow;
- (void) adjustMainBrowserWindow;
- (void) allBrowserWindowsChangeLevel:(BOOL)allowApps;

- (void) openResourceWithURL:(NSString *)URL andTitle:(NSString *)title;
- (void) downloadAndOpenSebConfigFromURL:(NSURL *)url;

- (void) setTitle:(NSString *)title forWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBWebView *)webView;
- (void) setStateForWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBWebView *)webView;

@end
