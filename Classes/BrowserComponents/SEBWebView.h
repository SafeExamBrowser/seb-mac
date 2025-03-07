//
//  SEBWebView.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 02.12.14.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <WebKit/WebKit.h>
#include "WebViewInternal.h"
#import "SEBWebViewController.h"
#import "SEBOSXBrowserController.h"

@class WebBasePluginPackage;
@class SEBWebViewController;
@class SEBOSXBrowserController;

@interface SEBWebView : WebView <NSTouchBarProvider>

@property (weak, nonatomic) SEBWebViewController <SEBAbstractWebViewNavigationDelegate>* navigationDelegate;

@property (weak, nonatomic) SEBWebView *creatingWebView;
@property (strong, nonatomic) NSURL *originalURL;
@property (strong, nonatomic) NSMutableArray *notAllowedURLs;
@property (readwrite) BOOL dismissAll;

@property (strong, readonly) NSTouchBar *touchBar;

- (instancetype)initWithFrame:(NSRect)frameRect delegate:(SEBWebViewController <SEBAbstractWebViewNavigationDelegate>*)delegate;

- (NSArray *)plugins;

+ (BOOL)_canShowMIMEType:(NSString *)MIMEType allowingPlugins:(BOOL)allowPlugins;

- (WebBasePluginPackage *)_pluginForMIMEType:(NSString *)MIMEType;

- (void) privateCopy:(id)sender;
- (void) privateCut:(id)sender;
- (void) privatePaste:(id)sender;

@end
