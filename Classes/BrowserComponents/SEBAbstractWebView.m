//
//  SEBAbstractWebView.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 04.11.20.
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

#import "SEBAbstractWebView.h"
#import "SEBAbstractClassicWebView.h"
#import "SafeExamBrowser-Swift.h"
#if TARGET_OS_OSX
#import "NSPasteboard+SaveRestore.h"
#endif

@implementation SEBAbstractWebView

- (instancetype)initNewTabMainWebView:(BOOL)mainWebView
                       withCommonHost:(BOOL)commonHostTab
                        configuration:(WKWebViewConfiguration *)configuration
                   overrideSpellCheck:(BOOL)overrideSpellCheck
                             delegate:(nonnull id<SEBAbstractWebViewNavigationDelegate>)delegate
{
    self = [super init];
    _navigationDelegate = delegate;
    if (self) {
        _isMainBrowserWebView = mainWebView;
        _isReloadAllowed = [_navigationDelegate isReloadAllowedMainWebView:mainWebView];
        _showReloadWarning = [_navigationDelegate showReloadWarningMainWebView:mainWebView];
        _isNavigationAllowed = [_navigationDelegate isNavigationAllowedMainWebView:mainWebView];
        _overrideAllowSpellCheck = overrideSpellCheck;
        urlFilter = [SEBURLFilter sharedSEBURLFilter];
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        quitURLTrimmed = [[preferences secureStringForKey:@"org_safeexambrowser_SEB_quitURL"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        webViewSelectPolicies webViewSelectPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowWebView"];
        BOOL downloadingInTemporaryWebView = overrideSpellCheck;
        _downUploadsAllowed = _navigationDelegate.allowDownUploads;
#if TARGET_OS_OSX
        // Downloading PDF files on iOS is currently unsupported, they will always be displayed
        _downloadPDFFiles = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadPDFFiles"];
#endif
        _allowSpellCheck = !_overrideAllowSpellCheck && [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSpellCheck"];

        if (@available(macOS 10.13, iOS 11.0, *)) {
            if (webViewSelectPolicy != webViewSelectForceClassic || downloadingInTemporaryWebView) {
                BOOL sendBrowserExamKey = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"];
                
                if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_URLFilterEnableContentFilter"] || downloadingInTemporaryWebView) {
                    
                    if ((webViewSelectPolicy == webViewSelectAutomatic && !sendBrowserExamKey) ||
                        (webViewSelectPolicy == webViewSelectPreferModern) ||
                        (webViewSelectPolicy == webViewSelectPreferModernInForeignNewTabs && (!sendBrowserExamKey || !commonHostTab)) ||
                        downloadingInTemporaryWebView) {
                        
                        DDLogInfo(@"Opening modern WebView");
                        SEBAbstractModernWebView *sebAbstractModernWebView = [[SEBAbstractModernWebView alloc] initWithDelegate:self configuration:configuration];
                        self.browserControllerDelegate = sebAbstractModernWebView;
                        [self initGeneralProperties];
                        return self;
                    }
                }
            }
        }
        DDLogInfo(@"Opening classic WebView");
        SEBAbstractClassicWebView *sebAbstractClassicWebView = [[SEBAbstractClassicWebView alloc] initWithDelegate:self];
        self.browserControllerDelegate = sebAbstractClassicWebView;
        [self initGeneralProperties];
    }
    return self;
}

- (void) initGeneralProperties
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [self.browserControllerDelegate setPrivateClipboardEnabled:[preferences secureBoolForKey:@"org_safeexambrowser_SEB_enablePrivateClipboard"] ||
     [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enablePrivateClipboardMacEnforce"]];
    [self.browserControllerDelegate setAllowDictionaryLookup:[preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDictionaryLookup"]];
    [self.browserControllerDelegate setAllowPDFPlugIn:[preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPDFPlugIn"]];
}


#pragma mark - SEBAbstractBrowserControllerDelegate Methods

- (id)nativeWebView
{
    return self.browserControllerDelegate.nativeWebView;
}

- (void) closeWKWebView
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(closeWKWebView)]) {
        [self.browserControllerDelegate closeWKWebView];
    }
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
    if (self.isReloadAllowed == NO) {
        return;
    }
    [self.browserControllerDelegate reload];
}

- (void)loadURL:(NSURL *)url
{
    if (url) {
        [self.browserControllerDelegate loadURL:url];
    }
}

- (void)stopLoading
{
    [self.browserControllerDelegate stopLoading];
}

- (void) focusFirstElement
{
    [self.browserControllerDelegate focusFirstElement];
}

- (void) focusLastElement
{
    [self.browserControllerDelegate focusLastElement];
}

- (BOOL) zoomPageSupported
{
    return self.browserControllerDelegate.zoomPageSupported;
}

- (void) zoomPageIn
{
    [self.browserControllerDelegate zoomPageIn];
}

- (void) zoomPageOut
{
    [self.browserControllerDelegate zoomPageOut];
}

- (void) zoomPageReset
{
    [self.browserControllerDelegate zoomPageReset];
}

- (void) textSizeIncrease
{
    [self.browserControllerDelegate textSizeIncrease];
}

- (void) textSizeDecrease
{
    [self.browserControllerDelegate textSizeDecrease];
}

- (void) textSizeReset
{
    [self.browserControllerDelegate textSizeReset];
}


- (void) searchText:(NSString *)textToSearch backwards:(BOOL)backwards caseSensitive:(BOOL)caseSensitive
{
    [self.browserControllerDelegate searchText:textToSearch backwards:backwards caseSensitive:caseSensitive];
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


- (void) stopMediaPlaybackWithCompletionHandler:(void (^)(void))completionHandler
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(stopMediaPlaybackWithCompletionHandler:)]) {
        [self.browserControllerDelegate stopMediaPlaybackWithCompletionHandler:completionHandler];
    } else {
        completionHandler();
    }
}


- (void)toggleScrollLock
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(toggleScrollLock)]) {
        [self.browserControllerDelegate toggleScrollLock];
    }
}

- (BOOL)isScrollLockActive
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(isScrollLockActive)]) {
        return [self.browserControllerDelegate isScrollLockActive];
    }
    return NO;
}


- (void)disableFlashFullscreen
{
#if TARGET_OS_OSX
    [self.browserControllerDelegate disableFlashFullscreen];
#endif
}


- (void)setDownloadingSEBConfig:(BOOL)downloadingSEBConfig
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(downloadingSEBConfig)]) {
        self.browserControllerDelegate.downloadingSEBConfig = downloadingSEBConfig;
    }
}


#pragma mark - SEBAbstractWebViewNavigationDelegate Methods

- (WKWebViewConfiguration *) wkWebViewConfiguration
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
    [self.navigationDelegate examineCookies:cookies forURL:url];
}

- (void) examineHeaders:(NSDictionary<NSString *,NSString *>*)headerFields forURL:(NSURL *)url
{
    [self.navigationDelegate examineHeaders:headerFields forURL:url];
}

- (void) firstDOMElementDeselected
{
    if ([self.navigationDelegate respondsToSelector:@selector(firstDOMElementDeselected)]) {
        [self.navigationDelegate firstDOMElementDeselected];
   }
}

- (void) lastDOMElementDeselected
{
    if ([self.navigationDelegate respondsToSelector:@selector(lastDOMElementDeselected)]) {
        [self.navigationDelegate lastDOMElementDeselected];
    }
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
    [self.navigationDelegate closeWebView:self];
}

- (void) closeWebView:(SEBAbstractWebView *)webView
{
    [self.navigationDelegate closeWebView:webView];
}

- (void) addWebView:(id)nativeWebView
{
    if ([self.navigationDelegate respondsToSelector:@selector(addWebView:)]) {
        [self.navigationDelegate addWebView:nativeWebView];
    }
}

- (void) addWebViewController:(id)webViewController
{
    if ([self.navigationDelegate respondsToSelector:@selector(addWebViewController:)]) {
        [self.navigationDelegate addWebViewController:webViewController];
    }
}

- (SEBAbstractWebView *) abstractWebView
{
    return self;
}

- (NSURL *)currentURL
{
    return self.navigationDelegate.currentURL;
}

- (NSString *)currentMainHost
{
    return self.navigationDelegate.currentMainHost;
}

- (void)setCurrentMainHost:(NSString *)currentMainHost
{
    self.navigationDelegate.currentMainHost = currentMainHost;
}

- (BOOL)isMainBrowserWebViewActive
{
    return self.isMainBrowserWebView;
}

- (NSString *)quitURL
{
    return self.navigationDelegate.quitURL;
}

- (NSString *)pageJavaScript
{
    return self.navigationDelegate.pageJavaScript;
}

- (BOOL)allowDownUploads
{
    return _downUploadsAllowed;
}

- (void) showAlertNotAllowedDownUploading:(BOOL)uploading
{
    [self.navigationDelegate showAlertNotAllowedDownUploading:uploading];
}

- (BOOL)overrideAllowSpellCheck
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


- (void) searchTextMatchFound:(BOOL)matchFound
{
    [self.navigationDelegate searchTextMatchFound:matchFound];
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

- (void) storePasteboard {
#if TARGET_OS_OSX
    NSPasteboard *generalPasteboard = [NSPasteboard generalPasteboard];
    NSArray *archive = [generalPasteboard archiveObjects];
    self.navigationDelegate.privatePasteboardItems = archive;
    [generalPasteboard clearContents];
#endif
}

- (void) restorePasteboard {
#if TARGET_OS_OSX
    NSPasteboard *generalPasteboard = [NSPasteboard generalPasteboard];
    [generalPasteboard clearContents];
    NSArray *archive = self.navigationDelegate.privatePasteboardItems;
    [generalPasteboard restoreArchive:archive];
#endif
}


- (void) presentAlertWithTitle:(NSString *)title
                       message:(NSString *)message
{
    [self.navigationDelegate presentAlertWithTitle:title message:message];
}


- (SEBBackgroundTintStyle) backgroundTintStyle
{
    return [self.navigationDelegate backgroundTintStyle];
}


- (id) window
{
    return self.navigationDelegate.window;
}

- (BOOL) isAACEnabled
{
    return self.navigationDelegate.isAACEnabled;
}

- (void)sebWebViewDidStartLoad
{
//    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
//    NSArray<NSHTTPCookie *> *cookies = cookieJar.cookies;
//    [self.navigationDelegate examineCookies:cookies];

    [self.navigationDelegate sebWebViewDidStartLoad];
    if (self.isNavigationAllowed == NO && [self.browserControllerDelegate respondsToSelector:@selector(clearBackForwardList)]) {
        [self.browserControllerDelegate clearBackForwardList];
    }
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

    NSURL *pageURL = self.url;
    NSString *pageTitle = self.pageTitle;
    if (pageTitle.length == 0) {
        if (pageURL.pathExtension && [pageURL.pathExtension caseInsensitiveCompare:filenameExtensionPDF] == NSOrderedSame) {
            pageTitle = pageURL.lastPathComponent;
        } else {
            pageTitle = @"";
        }
    }
    [self.navigationDelegate setPageTitle:pageTitle];

    [self.navigationDelegate setCanGoBack:self.canGoBack canGoForward:self.canGoForward];
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
        if (self.isMainBrowserWebView) {
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


- (SEBNavigationAction *)decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                                                      newTab:(BOOL)newTab
                                           configuration:(WKWebViewConfiguration *)configuration
                                        downloadFilename:(nullable NSString *)downloadFilename
{
    NSURLRequest *request = navigationAction.request;
    NSURL *url = request.URL;
    DDLogVerbose(@"[SEBAbstractWebView decidePolicyForNavigationAction: %@ newTab: %hhd configuration:%@ downloadFilename:%@]: request = %@, URL = %@", navigationAction, newTab, configuration, downloadFilename, request, url);
    WKNavigationType navigationType = navigationAction.navigationType;
    NSString *httpMethod = request.HTTPMethod;
    //    NSDictionary<NSString *,NSString *> *allHTTPHeaderFields = request.allHTTPHeaderFields;
    DDLogVerbose(@"Navigation type for URL %@: %ld", url, (long)navigationType);
    DDLogVerbose(@"HTTP method for URL %@: %@", url, httpMethod);
    //    DDLogVerbose(@"All HTTP header fields for URL %@: %@", url, allHTTPHeaderFields);
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    NSURL *originalURL = url;
    SEBNavigationAction *newNavigationAction = [SEBNavigationAction new];
    newNavigationAction.policy = SEBNavigationActionPolicyCancel;
    
    // This is currently used for SEB Server handshake after logging in to Moodle
    if (navigationType == WKNavigationTypeFormSubmitted) {
        [self.navigationDelegate shouldStartLoadFormSubmittedURL:url];
    }
    
    // Check if quit URL has been clicked (regardless of current URL Filter)
    if ([[originalURL.absoluteString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]] isEqualToString:quitURLTrimmed]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"quitLinkDetected" object:self];
        return newNavigationAction;
    }
    
    if (urlFilter.enableURLFilter && ![self.navigationDelegate downloadingInTemporaryWebView]) {
        URLFilterRuleActions filterActionResponse = [urlFilter testURLAllowed:originalURL];
        if (filterActionResponse != URLFilterActionAllow) {
            /// Content is not allowed: Show teach URL alert if activated or just indicate URL is blocked filterActionResponse == URLFilterActionBlock ||
            // We show the URL blocked overlay message only if a link was actively tapped by the user
            if ((navigationType == WKNavigationTypeLinkActivated || urlFilter.learningMode)) {
                if ([self.navigationDelegate showURLFilterAlertForRequest:request forContentFilter:NO filterResponse:filterActionResponse] == NO) {
                    /// User didn't allow the content, don't load it
                    DDLogWarn(@"A clicked link was blocked by the URL filter");
                    DDLogDebug(@"This clicked link was blocked by the URL filter: %@", originalURL.absoluteString);
                    return newNavigationAction;
                }
            } else {
                DDLogDebug(@"This resource was blocked by the URL filter: %@", originalURL.absoluteString);
                return newNavigationAction;
            }
        }
    }
    
    NSString *fileExtension = [url pathExtension];
    
    if (newTab) {
        newBrowserWindowPolicies newBrowserWindowPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"];
        
        // First check if links requesting to be opened in a new windows are generally blocked
        if (newBrowserWindowPolicy != getGenerallyBlocked) {
            // load link only if it's on the same host like the one of the current page
            if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkBlockForeign"] ||
                [self.navigationDelegate.currentMainHost isEqualToString:request.URL.host]) {
                if (newBrowserWindowPolicy == openInNewWindow) {
                    // Open in new tab
                    DDLogInfo(@"Open new window/tab URL in new window");
                    newNavigationAction.openedWebView = [self.navigationDelegate openNewTabWithURL:url configuration:(WKWebViewConfiguration *)configuration];
                    if (configuration) {
                        // Special case of window opened with Javascript .open()
                        newNavigationAction.policy = SEBNavigationActionPolicyJSOpen;
                        return newNavigationAction;
                    }
                    return newNavigationAction;
                }
                if (newBrowserWindowPolicy == openInSameWindow) {
                    // Load URL request in existing tab
                    DDLogInfo(@"Open new window/tab URL in same window (selected in current settings)");
                    if (configuration) {
                        // Special case of window opened with Javascript .open()
                        newNavigationAction.policy = SEBNavigationActionPolicyJSOpen;
                    }
                    [self loadURL:url];
                    //                    newNavigationAction.openedWebView = self;
                    return newNavigationAction;
                }
            }
        }
        // Opening links in new windows is not allowed by current policies
        // We show the URL blocked overlay message only if a link was actively tapped by the user
        if (navigationType == WKNavigationTypeLinkActivated) {
            [self.navigationDelegate showURLFilterAlertForRequest:request forContentFilter:NO filterResponse:SEBURLFilterAlertBlock];
        }
        DDLogInfo(@"Opening new window/tab URL generally blocked in current settings");
        return newNavigationAction;
    }
    BOOL WKDownloadSupported = NO;
    if (@available(macOS 11.3, iOS 14.5, *)) {
        WKDownloadSupported = YES;
    }
    if (![[self.browserControllerDelegate class] isEqual:SEBAbstractModernWebView.class]) {
        WKDownloadSupported = NO;
    }
    if (!WKDownloadSupported) {
        if ([url.scheme isEqualToString:@"data"]) {
            NSString *urlResourceSpecifier = [[url resourceSpecifier] stringByRemovingPercentEncoding];
            DDLogDebug(@"resourceSpecifier of data: URL is %@", urlResourceSpecifier);
            NSRange mediaTypeRange = [urlResourceSpecifier rangeOfString:@","];
            if (mediaTypeRange.location != NSNotFound && urlResourceSpecifier.length > mediaTypeRange.location > 0) {
                NSString *mediaType = [[urlResourceSpecifier substringToIndex:mediaTypeRange.location] lowercaseString];
                NSArray *mediaTypeParameters = [mediaType componentsSeparatedByString:@";"];
                if ([mediaTypeParameters indexOfObject:SEBConfigMIMEType] != NSNotFound &&
                    [preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
                    NSString *sebConfigString = [urlResourceSpecifier substringFromIndex:mediaTypeRange.location+1];
                    NSData *sebConfigData;
                    if ([mediaTypeParameters indexOfObject:@"base64"] == NSNotFound) {
                        sebConfigData = [sebConfigString dataUsingEncoding:NSUTF8StringEncoding];
                    } else {
                        sebConfigData = [[NSData alloc] initWithBase64EncodedString:sebConfigString options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    }
                    [self.navigationDelegate openSEBConfigFromData:sebConfigData];
                } else if (self.allowDownUploads) {
                    NSString *fileDataString = [urlResourceSpecifier substringFromIndex:mediaTypeRange.location+1];
                    NSData *fileData;
                    if ([mediaTypeParameters indexOfObject:@"base64"] == NSNotFound) {
                        fileData = [fileDataString dataUsingEncoding:NSUTF8StringEncoding];
                    } else {
                        fileData = [[NSData alloc] initWithBase64EncodedString:fileDataString options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    }
                    NSString *filename = [self saveData:fileData downloadFilename:downloadFilename];
                    if (filename) {
                        DDLogInfo(@"Successfully saved website generated data: %@", url);
                        [self.navigationDelegate presentAlertWithTitle:NSLocalizedString(@"Download Finished", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Saved file '%@'", nil), filename]];
                    } else {
                        DDLogError(@"Failed to save website generated data: %@", url);
                        [self.navigationDelegate presentAlertWithTitle:NSLocalizedString(@"Download Failed", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Could not save downloaded data, probably a wrong download directory was used in %@ settings.", nil), SEBShortAppName]];
                    }
                } else if (!self.allowDownUploads && navigationType == WKNavigationTypeLinkActivated) {
                    [self.navigationDelegate showAlertNotAllowedDownUploading:NO];
                }
            }
            newNavigationAction.policy = SEBNavigationActionPolicyCancel;
            return newNavigationAction;
        }

    }
    // Check if this is a seb:// or sebs:// link or a .seb file link
    if (((url.scheme && [url.scheme caseInsensitiveCompare:SEBProtocolScheme] == NSOrderedSame) ||
        (url.scheme && [url.scheme caseInsensitiveCompare:SEBSSecureProtocolScheme] == NSOrderedSame) ||
        (fileExtension && [fileExtension caseInsensitiveCompare:SEBFileExtension] == NSOrderedSame)) &&
        [preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
        // If the scheme is seb(s):// or the file extension .seb,
        // we (conditionally) download and open the linked .seb file
        if (!self.navigationDelegate.downloadingInTemporaryWebView) {
            [self.navigationDelegate conditionallyDownloadAndOpenSEBConfigFromURL:url];
            return newNavigationAction;
        }
    }

    self.navigationDelegate.currentURL = url;
    self.navigationDelegate.currentMainHost = url.host;
    newNavigationAction.policy = SEBNavigationResponsePolicyAllow;
    return newNavigationAction;
}


- (NSString *)saveData:(NSData *)data downloadFilename:(nullable NSString *)downloadFilename
{
    // Get the path to the App's Documents directory
    NSString *filename;
    if (downloadFilename.length > 0) {
        filename = downloadFilename;
    } else {
        filename = NSLocalizedString(@"Untitled", @"untitled filename");
        NSDate *time = [NSDate date];
        NSDateFormatter* dateFormatter = [NSDateFormatter new];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [dateFormatter setDateFormat:@"yyyy-MM-dd_hh-mm-ss"];
        NSString *timeString = [dateFormatter stringFromDate:time];
        filename = [NSString stringWithFormat:@"%@_%@", filename, timeString];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    int fileIndex = 1;
    NSURL *directory = self.downloadPathURL;
    NSString* filenameWithoutExtension = [filename stringByDeletingPathExtension];
    NSString* fileExtension = [filename pathExtension];

    while ([fileManager fileExistsAtPath:[directory URLByAppendingPathComponent:filename isDirectory:NO].path]) {
        filename = [NSString stringWithFormat:@"%@-%d.%@", filenameWithoutExtension, fileIndex, fileExtension];
        fileIndex++;
    }
    BOOL success = [fileManager createFileAtPath:[directory URLByAppendingPathComponent:filename isDirectory:NO].path contents:data attributes:nil];
    if (success) {
        DDLogInfo(@"%s at file path: %@", __FUNCTION__, [directory URLByAppendingPathComponent:filename isDirectory:NO].path);
        return filename;
    } else {
        return nil;
    }
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
                                               cookies:(NSArray <NSHTTPCookie *>*)cookies
{
    DDLogVerbose(@"decidePolicyForMIMEType: %@, URL: %@, canShowMIMEType: %d, isForMainFrame: %d, suggestedFilename %@", mimeType, url.absoluteString, canShowMIMEType, isForMainFrame, suggestedFilename);
    
    [self.navigationDelegate examineCookies:cookies forURL:url];
    
    if ((mimeType && [mimeType caseInsensitiveCompare:SEBConfigMIMEType] == NSOrderedSame) ||
        (mimeType && [mimeType caseInsensitiveCompare:SEBUnencryptedConfigMIMEType] == NSOrderedSame) ||
        (url.pathExtension && [url.pathExtension caseInsensitiveCompare:SEBFileExtension] == NSOrderedSame)) {
        // If MIME-Type or extension of the file indicates a .seb file, we (conditionally) download and open it
        NSURL *originalURL = self.originalURL;
        self.downloadingSEBConfig = YES;
        [self.navigationDelegate downloadSEBConfigFileFromURL:url originalURL:originalURL cookies:cookies];
        return SEBNavigationActionPolicyCancel;
    }

    // Check for PDF file and according to settings either download or display it inline in the SEB browser
    if (!((mimeType && [mimeType caseInsensitiveCompare:mimeTypePDF] == NSOrderedSame) && _downUploadsAllowed && _downloadPDFFiles)) {
        // MIME type isn't PDF or downloading of PDFs isn't allowed
        if (canShowMIMEType) {
            return SEBNavigationActionPolicyAllow;
        }
    }
    // If MIME type cannot be displayed by the WebView, then we download it
    DDLogInfo(@"MIME type to download is %@", mimeType);
    return SEBNavigationActionPolicyDownload;
}


- (void)webViewDidClose:(WKWebView *)webView
{
    [self.navigationDelegate closeWebView:self];
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


- (NSURL *) downloadPathURL
{
    return self.navigationDelegate.downloadPathURL;
}

- (void) downloadFileFromURL:(NSURL *)url filename:(NSString *)filename cookies:(NSArray <NSHTTPCookie *>*)cookies
{
    [self.navigationDelegate downloadFileFromURL:url filename:filename cookies:cookies];
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

- (void)setRequest:(NSURLRequest *)request
{
    _writableRequest = request;
}

- (NSURLRequest *)request
{
    if (_writableRequest) {
        return _writableRequest;
    } else {
        return super.request;
    }
}

@end


@implementation SEBNavigationAction

@end
