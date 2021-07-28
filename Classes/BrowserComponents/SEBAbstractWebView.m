//
//  SEBAbstractWebView.m
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

#import "SEBAbstractWebView.h"
#import "SEBAbstractClassicWebView.h"
#import "SafeExamBrowser-Swift.h"


@implementation SEBAbstractWebView

- (instancetype)initNewTabWithCommonHost:(BOOL)commonHostTab overrideSpellCheck:(BOOL)overrideSpellCheck
{
    self = [super init];
    if (self) {
        _overrideAllowSpellCheck = overrideSpellCheck;
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        webViewSelectPolicies webViewSelectPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowWebView"];
        BOOL downloadingInTemporaryWebView = overrideSpellCheck;
        _allowSpellCheck = !_overrideAllowSpellCheck && [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSpellCheck"];

        if (webViewSelectPolicy != webViewSelectForceClassic || downloadingInTemporaryWebView) {
            BOOL sendBrowserExamKey = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"];
            
            if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_URLFilterEnableContentFilter"] || downloadingInTemporaryWebView) {
                
                if ((webViewSelectPolicy == webViewSelectAutomatic && !sendBrowserExamKey) ||
                    (webViewSelectPolicy == webViewSelectPreferModern) ||
                    (webViewSelectPolicy == webViewSelectPreferModernInForeignNewTabs && (!sendBrowserExamKey || !commonHostTab)) ||
                    downloadingInTemporaryWebView) {
                    
                    SEBAbstractModernWebView *sebAbstractModernWebView = [SEBAbstractModernWebView new];
                    sebAbstractModernWebView.navigationDelegate = self;
                    self.browserControllerDelegate = sebAbstractModernWebView;
                    return self;
                }
            }
        }
        SEBAbstractClassicWebView *sebAbstractClassicWebView = [SEBAbstractClassicWebView new];
        sebAbstractClassicWebView.navigationDelegate = self;
        self.browserControllerDelegate = sebAbstractClassicWebView;
    }
    return self;
}


/// SEBAbstractBrowserControllerDelegate Methods

- (void)loadView
{
    [self.browserControllerDelegate loadView];
}

- (void)didMoveToParentViewController
{
    [self.browserControllerDelegate didMoveToParentViewController];
}

- (void)viewDidLayoutSubviews
{
    [self.browserControllerDelegate viewDidLayoutSubviews];
}
- (void)viewWillTransitionToSize
{
    [self.browserControllerDelegate viewWillTransitionToSize];
}
- (void)viewWillAppear:(BOOL)animated
{
    [self.browserControllerDelegate viewWillAppear:(BOOL)animated];
}
- (void)viewDidAppear:(BOOL)animated
{
    [self.browserControllerDelegate viewDidAppear:(BOOL)animated];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [self.browserControllerDelegate viewWillDisappear:(BOOL)animated];
}


- (id)nativeWebView
{
    return self.browserControllerDelegate.nativeWebView;
}

- (NSURL*)url
{
    return [self.browserControllerDelegate url];
}

- (NSString*)pageTitle
{
    return [self.browserControllerDelegate pageTitle];
}

- (BOOL)canGoBack
{
    return [self.browserControllerDelegate canGoBack];
}

- (BOOL)canGoForward;
{
    return [self.browserControllerDelegate canGoForward];
}

- (void)goBack
{
    [self.browserControllerDelegate goBack];
}

- (void)goForward
{
    [self.browserControllerDelegate goForward];
}

- (void)reload
{
    [self.browserControllerDelegate reload];
}

- (void)loadURL:(NSURL *)url
{
    [self.browserControllerDelegate loadURL:url];
}

- (void)stopLoading
{
    [self.browserControllerDelegate stopLoading];
}


- (void)toggleScrollLock
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(toggleScrollLock)]) {
        [self.browserControllerDelegate toggleScrollLock];
    }
}

- (BOOL) isScrollLockActive
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(isScrollLockActive)]) {
        return [self.browserControllerDelegate isScrollLockActive];
    }
    return NO;
}


/// SEBAbstractWebViewNavigationDelegate Methods

@synthesize wkWebViewConfiguration;

- (WKWebViewConfiguration *) wkWebViewConfiguration
{
    return self.navigationDelegate.wkWebViewConfiguration;
}


- (void) setLoading:(BOOL)loading
{
    [self.navigationDelegate setLoading:loading];
}

- (void) setTitle:(NSString *)title
{
    [self.navigationDelegate setTitle:title];
}

- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
{
    [self.navigationDelegate setCanGoBack:canGoBack canGoForward:canGoForward];
}

- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies
{
    [self.navigationDelegate examineCookies:cookies];
}

- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
{
    return [self.navigationDelegate openNewTabWithURL:url];
}

- (SEBAbstractWebView *) openNewWebViewWindow
{
    return [self.navigationDelegate openNewWebViewWindow];
}

- (void) makeActiveAndOrderFront
{
    [self.navigationDelegate makeActiveAndOrderFront];
}

- (void) showWebView:(SEBAbstractWebView *)webView
{
    [self.navigationDelegate showWebView:webView];
}

- (SEBAbstractWebView *) abstractWebView
{
    return self;
}


- (NSString *)currentMainHost
{
    return self.navigationDelegate.currentMainHost;
}

- (void)setCurrentMainHost:(NSString *)currentMainHost
{
    self.navigationDelegate.currentMainHost = currentMainHost;
}

- (NSString *) pageJavaScript
{
    return self.navigationDelegate.pageJavaScript;
}

- (BOOL) overrideAllowSpellCheck
{
    return _overrideAllowSpellCheck;
}

- (NSURLRequest *)modifyRequest:(NSURLRequest *)request
{
    return [self.navigationDelegate modifyRequest:request];
}

- (NSString *) browserExamKeyForURL:(NSURL *)url
{
    return [self.navigationDelegate browserExamKeyForURL:url];
}

- (NSString *) configKeyForURL:(NSURL *)url
{
    return [self.navigationDelegate configKeyForURL:url];
}

- (NSString *) appVersion
{
    return [self.navigationDelegate appVersion];
}


@synthesize customSEBUserAgent;

- (NSString *) customSEBUserAgent
{
    return self.navigationDelegate.customSEBUserAgent;
    
}


- (NSArray <NSData *> *) privatePasteboardItems
{
    return self.navigationDelegate.privatePasteboardItems;
}

- (void) setPrivatePasteboardItems:(NSArray<NSData *> *)privatePasteboardItems
{
    self.navigationDelegate.privatePasteboardItems = privatePasteboardItems;
}


- (void)sebWebViewDidStartLoad
{
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray<NSHTTPCookie *> *cookies = cookieJar.cookies;
    [self.navigationDelegate examineCookies:cookies];

    [self.navigationDelegate sebWebViewDidStartLoad];
}

- (void)webView:(WKWebView *)webView
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    [self.navigationDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
}

- (void)sebWebViewDidFinishLoad
{
    [self.navigationDelegate sebWebViewDidFinishLoad];
}

- (void)sebWebViewDidFailLoadWithError:(NSError *)error
{
    if (error.code == -999) {
        DDLogError(@"%s: Load Error -999: Another request initiated before the previous request was completed (%@)", __FUNCTION__, error.description);
        return;
    }
    [self.navigationDelegate setLoading:NO];
    // Enable back/forward buttons according to availablility for this webview
    [self.navigationDelegate setCanGoBack:self.canGoBack canGoForward:self.canGoForward];

    // Don't display the error 102 "Frame load interrupted", this can be caused by
    // the URL filter canceling loading a blocked URL
    if (error.code == 102) {
        DDLogDebug(@"%s: Reported Error 102: %@", __FUNCTION__, error.description);
        
    // Don't display the error 204 "Plug-in handled load"
    } else if (error.code == 204) {
        DDLogDebug(@"%s: Reported Error 204: %@", __FUNCTION__, error.description);

    } else {
        
        DDLogError(@"%s: Load Error: %@", __FUNCTION__, error.description);
        
        // Decide if of failed load should be displayed in the alert
        // (according to current ShowURL policy settings for exam/additional tab)
        BOOL showURL = false;
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        if ([MyGlobals sharedMyGlobals].currentWebpageIndexPathRow == 0) {
            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowShowURL"] >= browserWindowShowURLOnlyLoadError) {
                showURL = true;
            }
        } else {
            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowShowURL"] >= browserWindowShowURLOnlyLoadError) {
                showURL = true;
            }
        }
        NSMutableDictionary<NSErrorUserInfoKey,id> *userInfo = error.userInfo.mutableCopy;
        NSString *failingURLString = [error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey];
        NSString *errorMessage = [NSString stringWithFormat:@"%@%@", error.localizedDescription, showURL ? [NSString stringWithFormat:@"\n%@", failingURLString] : @""];
        [userInfo setValue:errorMessage forKey:NSLocalizedDescriptionKey];
        NSError *updatedError = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:userInfo.copy];
        error = updatedError;
    }
    
    [self.navigationDelegate sebWebViewDidFailLoadWithError:error];
}

- (BOOL)sebWebViewShouldStartLoadWithRequest:(NSURLRequest *)request
      navigationAction:(WKNavigationAction *)navigationAction
                                      newTab:(BOOL)newTab
{
    return [self.navigationDelegate sebWebViewShouldStartLoadWithRequest:request navigationAction:navigationAction newTab:newTab];
}

- (void)sebWebViewDidUpdateTitle:(nullable NSString *)title
{
    if ([self.navigationDelegate respondsToSelector:@selector(sebWebViewDidUpdateTitle:)]) {
        [self.navigationDelegate sebWebViewDidUpdateTitle:title];
    }
}

- (void)sebWebViewDidUpdateProgress:(double)progress
{
    if ([self.navigationDelegate respondsToSelector:@selector(sebWebViewDidUpdateProgress:)]) {
        [self.navigationDelegate sebWebViewDidUpdateProgress:progress];
    }
}

- (BOOL)sebWebViewDecidePolicyForMIMEType:(NSString*)mimeType
                                      url:(NSURL *)url
                          canShowMIMEType:(BOOL)canShowMIMEType
                           isForMainFrame:(BOOL)isForMainFrame
                        suggestedFilename:(NSString *)suggestedFilename
                                  cookies:(NSArray<NSHTTPCookie *> *)cookies
{
    return [self.navigationDelegate sebWebViewDecidePolicyForMIMEType:mimeType url:url canShowMIMEType:canShowMIMEType isForMainFrame:isForMainFrame suggestedFilename:suggestedFilename cookies:cookies];
}

- (void)webView:(WKWebView *)webView
runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(void))completionHandler
{
    [self.navigationDelegate webView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
}

- (void)pageTitle:(NSString *)pageTitle
runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WebFrame *)frame
{
    [self.navigationDelegate pageTitle:pageTitle runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame];
}

- (void)webView:(WKWebView *)webView
runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(BOOL result))completionHandler
{
    [self.navigationDelegate webView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
}

- (BOOL)pageTitle:(NSString *)pageTitle
runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WebFrame *)frame
{
    return [self.navigationDelegate pageTitle:pageTitle runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame];
}

- (void)webView:(WKWebView *)webView
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
    defaultText:(nullable NSString *)defaultText
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSString *result))completionHandler
{
    [self.navigationDelegate webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
}

- (NSString *)pageTitle:(NSString *)pageTitle
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
          defaultText:(NSString *)defaultText
     initiatedByFrame:(WebFrame *)frame
{
    return [self.navigationDelegate pageTitle:pageTitle runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame];
}

- (void)webView:(WKWebView *)webView
runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSArray<NSURL *> *URLs))completionHandler
{
    [self.navigationDelegate webView:webView runOpenPanelWithParameters:parameters initiatedByFrame:frame completionHandler:completionHandler];
}


- (SEBBackgroundTintStyle) backgroundTintStyle
{
    return [self.navigationDelegate backgroundTintStyle];
}


- (BOOL) downloadingInTemporaryWebView
{
    return [self.navigationDelegate downloadingInTemporaryWebView];
}

- (BOOL) originalURLIsEqualToURL:(NSURL *)url
{
    return [_originalURL isEqual:url];
}

@end


@implementation SEBWKNavigationAction

- (void)setNavigationType:(WKNavigationType)navigationType
{
    _writableNavigationType = navigationType;
}

- (WKNavigationType)navigationType
{
    if (_writableNavigationType) {
        return _writableNavigationType;
    } else {
        return super.navigationType;
    }
}

@end
