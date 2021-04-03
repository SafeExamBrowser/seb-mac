//
//  SEBAbstractWebView.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 04.11.20.
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

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SEBAbstractWebView;

@protocol SEBAbstractBrowserControllerDelegate <NSObject>

@required
- (id)nativeWebView;
- (nullable NSURL*)url;
- (nullable NSString*)pageTitle;
- (BOOL)canGoBack;
- (BOOL)canGoForward;

- (void)goBack;
- (void)goForward;
- (void)reload;
- (void)loadURL:(NSURL *)url;
- (void)stopLoading;

@optional
- (void)loadView;
- (void)didMoveToParentViewController;
- (void)viewDidLayoutSubviews;
- (void)viewWillTransitionToSize;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;

- (void) toggleScrollLock;
- (BOOL) isScrollLockActive;


- (void) loadWebPageOrSearchResultWithString:(NSString *)webSearchString;
- (void) openCloseSliderForNewTab;
- (void) switchToTab:(nullable id)sender;
- (void) switchToNextTab;
- (void) switchToPreviousTab;
- (void) closeTab;

- (void) conditionallyDownloadAndOpenSEBConfigFromURL:(NSURL *)url;
- (void) conditionallyOpenSEBConfigFromData:(NSData *)sebConfigData;

- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url;
- (void) sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task;

- (void) presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion;

@end


@protocol SEBAbstractWebViewNavigationDelegate <NSObject>

@required
@property (readonly, nonatomic) WKWebViewConfiguration *wkWebViewConfiguration;
- (void) setLoading:(BOOL)loading;
- (void) setTitle:(NSString *)title;
- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward;
- (void) openNewTabWithURL:(NSURL *)url;
- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies;


@optional
- (void)sebWebViewDidStartLoad;
- (void)sebWebViewDidFinishLoad;
- (void)sebWebViewDidFailLoadWithError:(NSError *)error;
- (BOOL)sebWebViewShouldStartLoadWithRequest:(NSURLRequest *)request
      navigationAction:(WKNavigationAction *)navigationAction
                                      newTab:(BOOL)newTab;
- (void)sebWebViewDidUpdateTitle:(nullable NSString *)title;
- (void)sebWebViewDidUpdateProgress:(double)progress;

- (NSURLRequest *) modifyRequest:(NSURLRequest *)request;

@property (readonly, nonatomic) NSString *customSEBUserAgent;

- (SEBBackgroundTintStyle) backgroundTintStyle;
@property (strong, nonatomic) id __nullable uiAlertController;

@end


@interface SEBAbstractWebView : NSObject <SEBAbstractBrowserControllerDelegate, SEBAbstractWebViewNavigationDelegate>

@property (strong, nonatomic) id<SEBAbstractBrowserControllerDelegate> browserControllerDelegate;
@property (weak, nonatomic) id<SEBAbstractWebViewNavigationDelegate> navigationDelegate;

- (instancetype)initNewTabWithCommonHost:(BOOL)commonHostTab;

@end


@interface SEBWKNavigationAction : WKNavigationAction

@property (readwrite, nonatomic) WKNavigationType writableNavigationType;

@end

NS_ASSUME_NONNULL_END
