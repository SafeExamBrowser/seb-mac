//
//  SEBAbstractWebView.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 04.11.20.
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

NS_ASSUME_NONNULL_BEGIN

@class SEBAbstractWebView;

@protocol SEBAbstractBrowserControllerDelegate <NSObject>

@required
- (id) nativeWebView;
- (nullable NSURL*) url;
- (nullable NSString*) pageTitle;
- (BOOL) canGoBack;
- (BOOL) canGoForward;

- (void) goBack;
- (void) goForward;
- (void) reload;
- (void) loadURL:(NSURL *)url;
- (void) stopLoading;

@optional
- (void) zoomPageIn;
- (void) zoomPageOut;
- (void) zoomPageReset;

- (void) textSizeIncrease;
- (void) textSizeDecrease;
- (void) textSizeReset;

- (void) loadView;
- (void) didMoveToParentViewController;
- (void) viewDidLayoutSubviews;
- (void) viewWillTransitionToSize;
- (void) viewWillAppear:(BOOL)animated;
- (void) viewDidAppear:(BOOL)animated;
- (void) viewWillDisappear:(BOOL)animated;

- (void) toggleScrollLock;
- (BOOL) isScrollLockActive;


- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url;
- (void) sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task;

@end


@protocol SEBAbstractWebViewNavigationDelegate <NSObject>

@required
@property (readonly, nonatomic) WKWebViewConfiguration *wkWebViewConfiguration;
- (void) setLoading:(BOOL)loading;
- (void) setTitle:(NSString *)title;
- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward;
- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies;

@optional
- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url;
- (SEBAbstractWebView *) openNewWebViewWindow;

- (void) makeActiveAndOrderFront;
- (void) showWebView:(SEBAbstractWebView *)webView;
- (void) closeWebView;
- (void) closeWebView:(SEBAbstractWebView *)webView;

@property (readonly, nonatomic) SEBAbstractWebView *abstractWebView;
@property (strong, nonatomic) NSString *currentMainHost;
@property (readonly, nonatomic) NSString *quitURL;
@property (readonly, nonatomic) NSString *pageJavaScript;
@property (readonly) BOOL directConfigDownloadAttempted;
@property (readonly) BOOL overrideAllowSpellCheck;
@property (readonly) BOOL allowSpellCheck;
- (NSURLRequest *) modifyRequest:(NSURLRequest *)request;
- (NSString *) browserExamKeyForURL:(NSURL *)url;
- (NSString *) configKeyForURL:(NSURL *)url;
- (NSString *) appVersion;

@property (readonly, nonatomic) NSString *customSEBUserAgent;
@property (nullable, readwrite, nonatomic) NSArray<NSData *> *privatePasteboardItems;

- (SEBBackgroundTintStyle) backgroundTintStyle;

@property (strong, nonatomic) id __nullable window;
@property (strong, nonatomic) id __nullable uiAlertController;

- (void)sebWebViewDidStartLoad;
- (void)sebWebViewDidFinishLoad;
- (void)sebWebViewDidFailLoadWithError:(NSError *)error;
- (BOOL)sebWebViewShouldStartLoadWithRequest:(NSURLRequest *)request
      navigationAction:(WKNavigationAction *)navigationAction
                                      newTab:(BOOL)newTab;
- (void)sebWebViewDidUpdateTitle:(nullable NSString *)title;
- (void)sebWebViewDidUpdateProgress:(double)progress;
- (BOOL)sebWebViewDecidePolicyForMIMEType:(nullable NSString*)mimeType
                                      url:(nullable NSURL *)url
                          canShowMIMEType:(BOOL)canShowMIMEType
                           isForMainFrame:(BOOL)isForMainFrame
                        suggestedFilename:(nullable NSString *)suggestedFilename
                                  cookies:(nullable NSArray <NSHTTPCookie *>*)cookies;
- (BOOL)sebWebView:(SEBAbstractWebView*)webView
decidePolicyForMIMEType:(nullable NSString*)mimeType
               url:(nullable NSURL *)url
   canShowMIMEType:(BOOL)canShowMIMEType
    isForMainFrame:(BOOL)isForMainFrame
 suggestedFilename:(nullable NSString *)suggestedFilename
           cookies:(NSArray <NSHTTPCookie *>*)cookies;

- (void)didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
                        completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler;

- (void)webView:(WKWebView *)webView
didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation;

- (void)webView:(WKWebView *)webView
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler;

- (void)webView:(WKWebView *)webView
didCommitNavigation:(WKNavigation *)navigation;

- (void)webView:(WKWebView *)webView
didFinishNavigation:(WKNavigation *)navigation;

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse
decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;

- (void)webView:(WKWebView *)webView
runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(void))completionHandler;

- (void)pageTitle:(NSString *)pageTitle
runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WebFrame *)frame;

- (void)webView:(WKWebView *)webView
runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(BOOL result))completionHandler;

- (BOOL)pageTitle:(NSString *)pageTitle
runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WebFrame *)frame;

- (void)webView:(WKWebView *)webView
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
    defaultText:(nullable NSString *)defaultText
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSString *result))completionHandler;

- (NSString *)pageTitle:(NSString *)pageTitle
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
          defaultText:(NSString *)defaultText
     initiatedByFrame:(WebFrame *)frame;

- (void)webView:(nullable WKWebView *)webView
runOpenPanelWithParameters:(id)parameters
initiatedByFrame:(nullable WKFrameInfo *)frame
completionHandler:(void (^)(NSArray<NSURL *> *URLs))completionHandler;

- (void) transferCookiesToWKWebViewWithCompletionHandler:(void (^)(void))completionHandler;
#if TARGET_OS_IPHONE
- (void) presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion;
#endif
- (BOOL) showURLFilterAlertForRequest:(NSURLRequest *)request
                     forContentFilter:(BOOL)contentFilter
                       filterResponse:(URLFilterRuleActions)filterResponse;
- (void) loadWebPageOrSearchResultWithString:(NSString *)webSearchString;

- (void) openCloseSliderForNewTab;
- (void) switchToTab:(nullable id)sender;
- (void) switchToNextTab;
- (void) switchToPreviousTab;
- (void) closeTab;
- (void) closeTabWithIndex:(NSUInteger)tabIndex;

- (void) conditionallyDownloadAndOpenSEBConfigFromURL:(NSURL *)url;
- (void) conditionallyOpenSEBConfigFromData:(NSData *)sebConfigData;
@property (readonly) BOOL downloadingInTemporaryWebView;
- (BOOL) originalURLIsEqualToURL:(NSURL *)url;

@end


@interface SEBAbstractWebView : NSObject <SEBAbstractBrowserControllerDelegate, SEBAbstractWebViewNavigationDelegate>

@property (strong, nonatomic) id<SEBAbstractBrowserControllerDelegate> browserControllerDelegate;
@property (weak, nonatomic) id<SEBAbstractWebViewNavigationDelegate> navigationDelegate;

@property (strong, nonatomic) NSURL *originalURL;
@property (readwrite, nonatomic) BOOL allowSpellCheck;
@property (readwrite, nonatomic) BOOL overrideAllowSpellCheck;
@property (weak, nonatomic) SEBAbstractWebView *creatingWebView;
@property (strong, nonatomic) NSMutableArray *notAllowedURLs;
@property (readwrite) BOOL dismissAll;


- (instancetype)initNewTabWithCommonHost:(BOOL)commonHostTab overrideSpellCheck:(BOOL)overrideSpellCheck;

@end


@interface SEBWKNavigationAction : WKNavigationAction

@property (readwrite, nonatomic) WKNavigationType writableNavigationType;

@end

NS_ASSUME_NONNULL_END
