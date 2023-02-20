//
//  SEBAbstractClassicWebView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03.03.21.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBAbstractClassicWebView.h"
#if TARGET_OS_IPHONE
#import "SEBUIWebViewController.h"
#else
#import "SEBWebViewController.h"
#endif

@implementation SEBAbstractClassicWebView

- (instancetype)initWithDelegate:(id <SEBAbstractWebViewNavigationDelegate>)delegate
{
    self = [super init];
    if (self) {
        _navigationDelegate = delegate;
#if TARGET_OS_IPHONE
        SEBUIWebViewController *sebUIWebViewController = [[SEBUIWebViewController alloc] initWithDelegate:self];
        self.browserControllerDelegate = sebUIWebViewController;
#else
        SEBWebViewController *sebWebViewController = [[SEBWebViewController alloc] initWithDelegate:self];
        self.browserControllerDelegate = sebWebViewController;
#endif
    }
    return self;
}


#pragma mark - SEBAbstractBrowserControllerDelegate Methods

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

- (void) focusFirstElement
{
    [self.browserControllerDelegate stringByEvaluatingJavaScriptFromString:@"SEB_FocusFirstElement()"];
}

- (void) focusLastElement
{
    [self.browserControllerDelegate stringByEvaluatingJavaScriptFromString:@"SEB_FocusLastElement()"];
}

- (BOOL) zoomPageSupported
{
    return [self.browserControllerDelegate respondsToSelector:@selector(zoomPageIn)];
}

- (void) zoomPageIn
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(zoomPageIn)]) {
        [self.browserControllerDelegate zoomPageIn];
    }
}

- (void) zoomPageOut
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(zoomPageOut)]) {
        [self.browserControllerDelegate zoomPageOut];
    }
}

- (void) zoomPageReset
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(zoomPageReset)]) {
        [self.browserControllerDelegate zoomPageReset];
    }
}

- (void) textSizeIncrease
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(textSizeIncrease)]) {
        [self.browserControllerDelegate textSizeIncrease];
    }
}

- (void) textSizeDecrease
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(textSizeDecrease)]) {
        [self.browserControllerDelegate textSizeDecrease];
    }
}

- (void) textSizeReset
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(textSizeReset)]) {
        [self.browserControllerDelegate textSizeReset];
    }
}


- (void) searchText:(NSString *)textToSearch backwards:(BOOL)backwards caseSensitive:(BOOL)caseSensitive
{
    if (textToSearch.length == 0) {
        previousSearchText = textToSearch;
        [self.browserControllerDelegate stringByEvaluatingJavaScriptFromString:@"SEB_RemoveAllHighlights()"];
        [self.navigationDelegate searchTextMatchFound:NO];
    } else {
        if ([previousSearchText isEqualToString:textToSearch]) {
            if (backwards) {
                [self.browserControllerDelegate stringByEvaluatingJavaScriptFromString:@"SEB_SearchPrevious()"];
            } else {
                [self.browserControllerDelegate stringByEvaluatingJavaScriptFromString:@"SEB_SearchNext()"];
            }
            [self.navigationDelegate searchTextMatchFound:YES];
        } else {
            previousSearchText = textToSearch;
            NSString *searchString = [NSString stringWithFormat:@"SEB_HighlightAllOccurencesOfString('%@')", textToSearch];
            [self.browserControllerDelegate stringByEvaluatingJavaScriptFromString:searchString];
            if (backwards) {
                [self.browserControllerDelegate stringByEvaluatingJavaScriptFromString:@"SEB_SearchPrevious()"];
            } else {
                [self.browserControllerDelegate stringByEvaluatingJavaScriptFromString:@"SEB_SearchNext()"];
            }
            NSString *result = [self.browserControllerDelegate stringByEvaluatingJavaScriptFromString:@"SEB_SearchResultCount"];
            if (result.length > 0) {
                NSInteger count = result.integerValue;
                if (count > 0) {
                    [self.navigationDelegate searchTextMatchFound:YES];
                    return;
                }
            }
            [self.browserControllerDelegate stringByEvaluatingJavaScriptFromString:@"SEB_RemoveAllHighlights()"];
            [self.navigationDelegate searchTextMatchFound:NO];
        }
    }
}


- (void) privateCopy:(id)sender
{
    [self.browserControllerDelegate privateCopy:sender];
}

- (void) privateCut:(id)sender
{
    [self.browserControllerDelegate privateCut:sender];
}

- (void) privatePaste:(id)sender
{
    [self.browserControllerDelegate privatePaste:sender];
}


- (void)loadView
{
    [self.browserControllerDelegate loadView];
}

- (void)didMoveToParentViewController
{
    [self.browserControllerDelegate didMoveToParentViewController];
}

- (void)viewDidLayout
{
    [self.browserControllerDelegate viewDidLayout];
}

- (void)viewDidLayoutSubviews
{
    [self.browserControllerDelegate viewDidLayoutSubviews];
}

- (void)viewWillTransitionToSize
{
    [self.browserControllerDelegate viewWillTransitionToSize];
}

- (void) viewDidLoad
{
    [self.browserControllerDelegate viewDidLoad];
}

- (void)viewWillAppear
{
    [self.browserControllerDelegate viewWillAppear];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.browserControllerDelegate viewWillAppear:(BOOL)animated];
}

- (void)viewDidAppear
{
    [self.browserControllerDelegate viewDidAppear];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.browserControllerDelegate viewDidAppear:(BOOL)animated];
}

- (void)viewWillDisappear
{
    [self.browserControllerDelegate viewWillDisappear];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.browserControllerDelegate viewWillDisappear:(BOOL)animated];
}

- (void)viewWDidDisappear
{
    [self.browserControllerDelegate viewDidDisappear];
}

- (void)viewWDidDisappear:(BOOL)animated
{
    [self.browserControllerDelegate viewDidDisappear:(BOOL)animated];
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


- (void)setPrivateClipboardEnabled:(BOOL)privateClipboardEnabled
{
    [self.browserControllerDelegate setPrivateClipboardEnabled: privateClipboardEnabled];
}

- (void)setAllowDictionaryLookup:(BOOL)allowDictionaryLookup
{
    [self.browserControllerDelegate setAllowDictionaryLookup:allowDictionaryLookup];
}

- (void)setAllowPDFPlugIn:(BOOL)allowPDFPlugIn
{
    [self.browserControllerDelegate setAllowPDFPlugIn:allowPDFPlugIn];
}


- (void)disableFlashFullscreen
{
#if TARGET_OS_OSX
    [self.browserControllerDelegate disableFlashFullscreen];
#endif
}


#pragma mark - SEBAbstractWebViewNavigationDelegate Methods

- (WKWebViewConfiguration *)wkWebViewConfiguration
{
    return self.navigationDelegate.wkWebViewConfiguration;
}

- (id) accessibilityDock
{
    return self.navigationDelegate.accessibilityDock;
}

- (void) setLoading:(BOOL)loading
{
    [self.navigationDelegate setLoading:loading];
}

- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
{
    [self.navigationDelegate setCanGoBack:canGoBack canGoForward:canGoForward];
}

- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies forURL:(NSURL *)url
{
    if (cookies.count == 0) {
        cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies;
    }
    [self.navigationDelegate examineCookies:cookies forURL:url];
}

- (void) examineHeaders:(NSDictionary<NSString *,NSString *>*)headerFields forURL:(NSURL *)url
{
    [self.navigationDelegate examineHeaders:headerFields forURL:url];
}

- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
                             configuration:(WKWebViewConfiguration *)configuration
{
    return [self.navigationDelegate openNewTabWithURL:url configuration:configuration];
}

- (SEBAbstractWebView *) openNewWebViewWindowWithURL:(NSURL *)url
                                       configuration:(WKWebViewConfiguration *)configuration
{
    return [self.navigationDelegate openNewWebViewWindowWithURL:url configuration:configuration];
}

- (void) makeActiveAndOrderFront
{
    [self.navigationDelegate makeActiveAndOrderFront];
}

- (void) showWebView:(SEBAbstractWebView *)webView
{
    [self.navigationDelegate showWebView:webView];
}

- (void) closeWebView
{
    [self.navigationDelegate closeWebView];
}

- (void) closeWebView:(SEBAbstractWebView *)webView
{
    [self.navigationDelegate closeWebView:webView];
}

- (SEBAbstractWebView *) abstractWebView
{
    return self.navigationDelegate.abstractWebView;
}

- (NSString *)currentMainHost
{
    return self.navigationDelegate.currentMainHost;
}

- (void)setCurrentMainHost:(NSString *)currentMainHost
{
    self.navigationDelegate.currentMainHost = currentMainHost;
}

- (BOOL) isMainBrowserWebView
{
    return self.navigationDelegate.isMainBrowserWebView;
}

- (BOOL) isMainBrowserWebViewActive
{
    return self.navigationDelegate.isMainBrowserWebViewActive;
}

- (NSString *)quitURL
{
    return self.navigationDelegate.quitURL;
}

- (NSString *) pageJavaScript
{
    return self.navigationDelegate.pageJavaScript;
}

- (BOOL)allowDownUploads
{
    return self.navigationDelegate.allowDownUploads;
}

- (void) showAlertNotAllowedDownUploading:(BOOL)uploading
{
    [self.navigationDelegate showAlertNotAllowedDownUploading:uploading];
}

- (BOOL) allowSpellCheck
{
    return self.navigationDelegate.allowSpellCheck;
}

- (BOOL) overrideAllowSpellCheck
{
    return self.navigationDelegate.overrideAllowSpellCheck;
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

- (void) storePasteboard
{
    [self.navigationDelegate storePasteboard];
}

- (void) restorePasteboard
{
    [self.navigationDelegate restorePasteboard];
}


- (void)sebWebViewDidStartLoad
{
    [self.navigationDelegate sebWebViewDidStartLoad];
}

- (void)webView:(WKWebView *)webView
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    if (self.navigationDelegate == nil) {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    } else {
        [self.navigationDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    }
}

- (void)sebWebViewDidFinishLoad
{
    [self.navigationDelegate sebWebViewDidFinishLoad];
    
    // Look for a user cookie if logging in to an exam system/LMS supporting SEB Server
    // ToDo: Only search for cookie when logging in to Open edX
//    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//    NSArray<NSHTTPCookie *> *cookies = cookieJar.cookies;
//    [self.navigationDelegate examineCookies:cookies];
}

- (void)sebWebViewDidFailLoadWithError:(NSError *)error
{
    [self.navigationDelegate sebWebViewDidFailLoadWithError:error];
}

- (SEBNavigationAction *)decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                                                      newTab:(BOOL)newTab
                                           configuration:(WKWebViewConfiguration *)configuration
                                        downloadFilename:(nullable NSString *)downloadFilename
{
    return [self.navigationDelegate decidePolicyForNavigationAction:navigationAction newTab:newTab configuration:configuration downloadFilename:downloadFilename];
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

- (SEBNavigationResponsePolicy)decidePolicyForMIMEType:(NSString*)mimeType
                                                   url:(NSURL *)url
                                       canShowMIMEType:(BOOL)canShowMIMEType
                                        isForMainFrame:(BOOL)isForMainFrame
                                     suggestedFilename:(NSString *)suggestedFilename
                                               cookies:(NSArray<NSHTTPCookie *> *)cookies
{
    return [self.navigationDelegate decidePolicyForMIMEType:mimeType url:url canShowMIMEType:canShowMIMEType isForMainFrame:isForMainFrame suggestedFilename:suggestedFilename cookies:cookies];
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
{
    [self.navigationDelegate pageTitle:pageTitle runJavaScriptAlertPanelWithMessage:message];
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
{
    return [self.navigationDelegate pageTitle:pageTitle runJavaScriptConfirmPanelWithMessage:message];
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
{
    return [self.navigationDelegate pageTitle:pageTitle runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText];
}

- (void)webView:(WKWebView *)webView
runOpenPanelWithParameters:(id)parameters
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSArray<NSURL *> *URLs))completionHandler
{
    [self.navigationDelegate webView:webView runOpenPanelWithParameters:parameters initiatedByFrame:frame completionHandler:completionHandler];
}


- (BOOL) showURLFilterAlertForRequest:(NSURLRequest *)request
                     forContentFilter:(BOOL)contentFilter
                       filterResponse:(URLFilterRuleActions)filterResponse
{
    return [self.navigationDelegate showURLFilterAlertForRequest:request forContentFilter:contentFilter filterResponse:filterResponse];
}


- (void) downloadFileFromURL:(NSURL *)url filename:(NSString *)filename cookies:(NSArray <NSHTTPCookie *>*)cookies
{
    [self.navigationDelegate downloadFileFromURL:url filename:filename cookies:cookies];
}

- (BOOL) downloadingInTemporaryWebView
{
    return self.navigationDelegate.downloadingInTemporaryWebView;
}

- (BOOL) originalURLIsEqualToURL:(NSURL *)url
{
    return [self.navigationDelegate originalURLIsEqualToURL:url];
}


- (SEBBackgroundTintStyle) backgroundTintStyle
{
    return [self.navigationDelegate backgroundTintStyle];
}

@end
