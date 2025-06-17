//
//  SEBiOSWebViewController.m
//
//  Created by Daniel R. Schneider on 06/01/16.
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

#import "SEBiOSWebViewController.h"
#import "UIWebView+SEBWebView.h"
#import "Constants.h"
#import "AppDelegate.h"


@implementation SEBiOSWebViewController

- (instancetype)initNewTabMainWebView:(BOOL)mainWebView
                       withCommonHost:(BOOL)commonHostTab
                        configuration:(WKWebViewConfiguration *)configuration
                   overrideSpellCheck:(BOOL)overrideSpellCheck
                             delegate:(nonnull id<SEBAbstractWebViewNavigationDelegate>)delegate
{
    self = [super init];
    _navigationDelegate = (SEBBrowserTabViewController *)delegate;
    if (self) {
        _urlFilter = [SEBURLFilter sharedSEBURLFilter];
        quitURLTrimmed = self.navigationDelegate.quitURL;
        // Get JavaScript code for modifying targets of hyperlinks in the webpage so can be open in new tabs
        _javaScriptFunctions = self.navigationDelegate.pageJavaScript;
        
        SEBAbstractWebView *sebAbstractWebView = [[SEBAbstractWebView alloc] initNewTabMainWebView:mainWebView withCommonHost:commonHostTab configuration:configuration overrideSpellCheck:(BOOL)overrideSpellCheck delegate:self];
        _sebWebView = sebAbstractWebView;
        firstAppearance = YES;
    }
    return self;
}


// Get statusbar appearance depending on device type (traditional or iPhone X like)
- (SEBBackgroundTintStyle)backgroundTintStyle {
    SEBUIController *sebUIController = [(AppDelegate*)[[UIApplication sharedApplication] delegate] sebUIController];
    return [sebUIController backgroundTintStyle];
}


- (void)loadView
{
    [_sebWebView loadView];
    self.view = _sebWebView.nativeWebView;
}


- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if (parent) {
        // Add the view to the parent view and position it if you want
        [[parent view] addSubview:self.view];
        CGRect viewFrame = parent.view.bounds;
        //viewFrame.origin.y += kNavbarHeight;
        //viewFrame.size.height -= kNavbarHeight;
        [self.view setFrame:viewFrame];
        [_sebWebView didMoveToParentViewController];
        _openCloseSlider = YES;
    } else {
        [self.view removeFromSuperview];
    }
}


- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    ((UIView *)_sebWebView.nativeWebView).frame = self.view.bounds;
    [_sebWebView viewDidLayoutSubviews];
    if (_openCloseSlider) {
        _openCloseSlider = NO;
        if ([self.navigationDelegate respondsToSelector:@selector(openCloseSliderForNewTab)]) {
            [self.navigationDelegate openCloseSliderForNewTab];
        }
    }
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [_sebWebView viewWillTransitionToSize];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [_sebWebView viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self becomeFirstResponder];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (firstAppearance) {
        firstAppearance = NO;
        if (([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowWebView"] == webViewSelectForceClassic ||
            ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowWebView"] != webViewSelectForceModern &&
            [preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"])) &&
            ![[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_browserWindowWebViewClassicHideDeprecationNote"]) {
            [self showTopOverlayMessage:[NSString stringWithFormat:NSLocalizedString(@"Classic WebView (UIWebView) is no longer supported on iOS/iPadOS! The used %@ assessment solution integration/settings might no longer work and need to be updated to support the modern WebView. Contact the vendor of your assessment solution or your exam provider.", @""), SEBShortAppName]];
        }
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopLoading];    // in case the web view is still loading its content
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self setLoading:NO];
    [_sebWebView viewWillDisappear:animated];
}


#pragma mark -
#pragma mark - SEBAbstractBrowserControllerDelegate Methods

//- (id)nativeWebView {
//    return _sebWebView.nativeWebView;
//}
//
//- (NSURL*)url {
//    return _sebWebView.url;
//}


- (nullable NSString*) pageTitle
{
    return [_sebWebView pageTitle];
}


- (void)toggleScrollLock {
    [_sebWebView toggleScrollLock];
}

- (BOOL) isScrollLockActive
{
    if ([_sebWebView respondsToSelector:@selector(isScrollLockActive)]) {
        return [_sebWebView isScrollLockActive];
    }
    return NO;
}


- (void)goBack {
    [_sebWebView goBack];
}

- (void)goForward {
    [_sebWebView goForward];
}

- (void)loadURL:(NSURL *)url
{
    [_sebWebView loadURL:url];
}

- (void)stopLoading {
    [_sebWebView stopLoading];
}

- (void)reload {
    [_sebWebView reload];
}

- (BOOL)zoomPageSupported {
    return _sebWebView.zoomPageSupported;
}

- (void)zoomPageIn
{
    if ([_sebWebView respondsToSelector:@selector(zoomPageIn)]) {
        [_sebWebView zoomPageIn];
    }
}

- (void)zoomPageOut
{
    if ([_sebWebView respondsToSelector:@selector(zoomPageOut)]) {
        [_sebWebView zoomPageOut];
    }
}

- (void)zoomPageReset
{
    if ([_sebWebView respondsToSelector:@selector(zoomPageReset)]) {
        [_sebWebView zoomPageReset];
    }
}


- (void)setDownloadingSEBConfig:(BOOL)downloadingSEBConfig {
    _sebWebView.downloadingSEBConfig = downloadingSEBConfig;
}


- (void)setBackForwardAvailabilty
{
    [self.navigationDelegate setCanGoBack:self.sebWebView.canGoBack canGoForward:self.sebWebView.canGoForward];
}


#pragma mark -
#pragma mark Overlay Display

- (UIView *) overlayViewForLabel:(UILabel *)message {
    [message sizeToFit];
    
    CGSize messageLabelSize = message.frame.size;
    CGFloat messageLabelWidth = messageLabelSize.width + messageLabelSize.height;
    CGFloat messageLabelHeight = messageLabelSize.height * 1.5;
    CGRect messageLabelFrame = CGRectMake(0, 0, messageLabelWidth, messageLabelHeight);
    
    UIView *overlayView = [[UIView alloc] initWithFrame:messageLabelFrame];
    message.center = overlayView.center;
    
    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        overlayView.backgroundColor = [UIColor clearColor];
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = overlayView.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [overlayView addSubview:blurEffectView];
        
        UIView *backgroundTintView = [UIView new];
        backgroundTintView.frame = overlayView.bounds;
        backgroundTintView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        backgroundTintView.backgroundColor = [UIColor lightGrayColor];
        backgroundTintView.alpha = 0.5;
        [overlayView addSubview:backgroundTintView];
        
    } else {
        overlayView.backgroundColor = UIColor.lightGrayColor;
    }
    [overlayView addSubview:message];
    overlayView.layer.cornerRadius = messageLabelHeight / 2;
    overlayView.clipsToBounds = YES;
    return overlayView;
}


- (UIView *) overlayViewForLabelConstraints:(UILabel *)message {
    [message sizeToFit];
    
    message.numberOfLines = 0;
    message.translatesAutoresizingMaskIntoConstraints = NO;
    message.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGSize messageLabelSize = message.frame.size;
    CGFloat messageLabelHeight = messageLabelSize.height * 1.5;
    
    UIView *overlayView = [UIView new];
    overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    message.center = overlayView.center;
    
    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        overlayView.backgroundColor = [UIColor clearColor];
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = overlayView.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [overlayView addSubview:blurEffectView];
        
        UIView *backgroundTintView = [UIView new];
        backgroundTintView.frame = overlayView.bounds;
        backgroundTintView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        backgroundTintView.backgroundColor = [UIColor lightGrayColor];
        backgroundTintView.alpha = 0.5;
        [overlayView addSubview:backgroundTintView];
        
    } else {
        overlayView.backgroundColor = UIColor.lightGrayColor;
    }
    
    overlayViewCloseButton = [[UIButton alloc] init];
    overlayViewCloseButton.translatesAutoresizingMaskIntoConstraints = NO;
    [overlayViewCloseButton setImage:[UIImage imageNamed:@"Cancel"] forState:UIControlStateNormal];
    [overlayViewCloseButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [overlayViewCloseButton setAccessibilityLabel:NSLocalizedString(@"Close Warning", @"")];
    [overlayViewCloseButton addTarget:self action:@selector(closeOverlayMessage) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *closeButtonStackView = [UIStackView new];
    closeButtonStackView.axis = UILayoutConstraintAxisVertical;
    closeButtonStackView.distribution = UIStackViewDistributionFill;
    closeButtonStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButtonStackView addArrangedSubview:overlayViewCloseButton];
    [closeButtonStackView addArrangedSubview:[UIView new]];

    UIStackView *overlayStackView = [UIStackView new];
    overlayStackView.axis = UILayoutConstraintAxisHorizontal;
    overlayStackView.spacing = 10;
    overlayStackView.distribution = UIStackViewDistributionFill;
    overlayStackView.translatesAutoresizingMaskIntoConstraints = NO;
    [overlayStackView addArrangedSubview:message];
    [overlayStackView addArrangedSubview:closeButtonStackView];
    CGFloat closeButtonWidth = overlayViewCloseButton.imageView.image.size.width;
    [overlayViewCloseButton.widthAnchor constraintEqualToConstant:closeButtonWidth].active = YES;
    [overlayViewCloseButton.leadingAnchor constraintEqualToAnchor:overlayViewCloseButton.superview.leadingAnchor].active = YES;
    [overlayViewCloseButton.trailingAnchor constraintEqualToAnchor:overlayViewCloseButton.superview.trailingAnchor].active = YES;
    [closeButtonStackView.topAnchor constraintEqualToAnchor:overlayStackView.topAnchor].active = YES;
    [closeButtonStackView.bottomAnchor constraintEqualToAnchor:overlayStackView.bottomAnchor].active = YES;

    [overlayView addSubview:overlayStackView];
    [overlayStackView.leadingAnchor constraintEqualToAnchor:overlayView.leadingAnchor constant: 10].active = YES;
    [overlayStackView.trailingAnchor constraintEqualToAnchor:overlayView.trailingAnchor constant: -10].active = YES;
    [overlayStackView.topAnchor constraintEqualToAnchor:overlayView.topAnchor constant: 7].active = YES;
    [overlayStackView.bottomAnchor constraintEqualToAnchor:overlayView.bottomAnchor constant: -7].active = YES;

    overlayView.layer.cornerRadius = messageLabelHeight / 2;
    overlayView.clipsToBounds = YES;
    return overlayView;
}


- (void) showURLFilterMessage
{
    if (!_filterMessageHolder) {
        
        CGRect frameRect = CGRectMake(0,0,155,21); // This will change based on the size you need
        UILabel *message = [[UILabel alloc] initWithFrame:frameRect];
        
        // Set message for URL blocked according to settings
        switch (_urlFilter.urlFilterMessage) {
                
            case URLFilterMessageText:
                message.text = NSLocalizedString(@"URL Blocked!", @"");
                [message setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
                [message setTextColor:[UIColor redColor]];
                
                break;
                
            case URLFilterMessageX:
                message.text = @"✕";
                [message setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCallout]];
                [message setTextColor:[UIColor darkGrayColor]];
                break;
        }
        message.adjustsFontForContentSizeCategory = YES;

        _filterMessageHolder = [self overlayViewForLabel:message];
    }

    CGFloat superviewWidth = self.view.bounds.size.width;
    CGFloat messageWidth = _filterMessageHolder.frame.size.width;
    CGFloat messageHeight = _filterMessageHolder.frame.size.height;
    
        [_filterMessageHolder setFrame:CGRectMake(
                                                  superviewWidth - self.view.safeAreaInsets.right - messageWidth - 10,
                                                  self.view.safeAreaInsets.top + 10,
                                                  messageWidth,
                                                  messageHeight
                                                  )];
    
    // Show the message
    UIView *nativeWebView = (UIView *)[_sebWebView nativeWebView];
    [nativeWebView insertSubview:_filterMessageHolder aboveSubview:nativeWebView];
    
    // Remove the URL filter message after a delay
    [self performSelector:@selector(hideURLFilterMessage) withObject: nil afterDelay: 1];
    
}

    
- (void) hideURLFilterMessage
{
    [_filterMessageHolder removeFromSuperview];
}


- (void) showTopOverlayMessage:(NSString *)text
{
    if (!_topOverlayMessageView) {
        
        UILabel *message = [UILabel new];
        
        message.text = text;
        [message setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
        message.adjustsFontForContentSizeCategory = YES;
        [message setTextColor:[UIColor redColor]];

        _topOverlayMessageView = [self overlayViewForLabelConstraints:message];
    }

    UIView *nativeWebView = (UIView *)[_sebWebView nativeWebView];
    _topOverlayMessageView.translatesAutoresizingMaskIntoConstraints = NO;
    [nativeWebView insertSubview:_topOverlayMessageView aboveSubview:nativeWebView];
    
    [_topOverlayMessageView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:10].active = YES;
    [_topOverlayMessageView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-10].active = YES;
    [_topOverlayMessageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10].active = YES;
}


- (void) closeOverlayMessage
{
    [_topOverlayMessageView removeFromSuperview];
}


#pragma mark -
#pragma mark SEBAbstractWebViewNavigationDelegate Methods

- (WKWebViewConfiguration *)wkWebViewConfiguration
{
    return self.navigationDelegate.wkWebViewConfiguration;
}


- (void) setLoading:(BOOL)loading
{
    [self.navigationDelegate setLoading:loading];
}

- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
{
    [self.navigationDelegate setCanGoBack:canGoBack canGoForward:canGoForward];
}


@synthesize customSEBUserAgent;

- (NSString *) customSEBUserAgent
{
    return self.navigationDelegate.customSEBUserAgent;
    
}


- (void) closeWebView:(SEBAbstractWebView *)webView
{
    [self.navigationDelegate closeWebView:webView];
}


- (void) addWebViewController:(id)webViewController
{
    [self.navigationDelegate addWebViewController:webViewController];
}


- (void) setPageTitle:(NSString *)title
{
    [self.navigationDelegate setTitle:title forWebViewController:self];
}


- (void) showAlertNotAllowedDownUploading:(BOOL)uploading
{
    [self.navigationDelegate showAlertNotAllowedDownUploading:uploading];
}


- (void)showAlertNotAllowedDownloadingAndOpeningSebConfig:(BOOL)downloading
{
    [self.navigationDelegate showAlertNotAllowedDownloadingAndOpeningSebConfig:downloading];
}


- (void)sebWebViewDidStartLoad
{
    // starting the load, show the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//    [self.searchBarController setLoading:YES];
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
    // finished loading, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.navigationDelegate setLoading:NO];
}


- (void)sebWebViewDidFailLoadWithError:(NSError *)error
{
    // Hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // Don't display the errors 102 "Frame load interrupted", this can be caused by
    // the URL filter canceling loading a blocked URL,
    // and 204 "Plug-in handled load"
    if (error.code != 102 && error.code != 204 && !(self.navigationDelegate.directConfigDownloadAttempted)) {
        NSString *failingURLString = [error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey];
        NSString *errorMessage = error.localizedDescription;
        DDLogError(@"%s: Load error with localized description: %@", __FUNCTION__, errorMessage);
        
        if (self.navigationDelegate.uiAlertController) {
            [self.navigationDelegate.uiAlertController dismissViewControllerAnimated:NO completion:nil];
        }
        
        self.navigationDelegate.uiAlertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Load Error", @"")
                                                                                         message:errorMessage
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
        [self.navigationDelegate.uiAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", @"")
                                                                                      style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSURL *failingURL = [NSURL URLWithString:failingURLString];
            if (failingURL && ![[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_browserConnectionErrorReload"]) {
                [self loadURL:failingURL];
            } else {
                [self reload];
            }
            self.navigationDelegate.uiAlertController = nil;
        }]];
        
        [self.navigationDelegate.uiAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                                                                      style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            self.navigationDelegate.uiAlertController = nil;
        }]];
        
        [self.navigationDelegate presentViewController:self.navigationDelegate.uiAlertController animated:NO completion:nil];
    }
}


- (void)sebWebViewDidUpdateTitle:(nullable NSString *)title
{
    NSString *webPageTitle = [self.navigationDelegate webPageTitle:title orURL:_sebWebView.url mainWebView:self.sebWebView.isMainBrowserWebView];
    [self.navigationDelegate setTitle:webPageTitle forWebViewController:self];
}


- (BOOL)canGoBack {
    return [_sebWebView canGoBack];
}


- (BOOL)canGoForward {
    return [_sebWebView canGoForward];
}


- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
                             configuration:(WKWebViewConfiguration *)configuration
{
    return [self.navigationDelegate openNewTabWithURL:url configuration:configuration];
}


- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies forURL:(NSURL *)url
{
    [self.navigationDelegate examineCookies:cookies forURL:url];
}

- (void) examineHeaders:(NSDictionary<NSString *,NSString *>*)headerFields forURL:(NSURL *)url
{
    [self.navigationDelegate examineHeaders:headerFields forURL:url];
}


- (void)webView:(WKWebView *)webView
runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(void))completionHandler
{
    if (self.navigationDelegate.uiAlertController) {
        [self.navigationDelegate.uiAlertController dismissViewControllerAnimated:NO completion:nil];
    }
    
    self.navigationDelegate.uiAlertController = [UIAlertController  alertControllerWithTitle:_sebWebView.pageTitle
                                                                                     message:message
                                                                              preferredStyle:UIAlertControllerStyleAlert];
    [self.navigationDelegate.uiAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                                                  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.navigationDelegate.uiAlertController = nil;
        completionHandler();
    }]];
    
    [self.navigationDelegate presentViewController:self.navigationDelegate.uiAlertController animated:NO completion:nil];
}


- (void)webView:(WKWebView *)webView
runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(BOOL result))completionHandler
{
    if (self.navigationDelegate.uiAlertController) {
        [self.navigationDelegate.uiAlertController dismissViewControllerAnimated:NO completion:nil];
    }
    
    self.navigationDelegate.uiAlertController = [UIAlertController  alertControllerWithTitle:_sebWebView.pageTitle
                                                                                     message:message
                                                                              preferredStyle:UIAlertControllerStyleAlert];
    [self.navigationDelegate.uiAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                                                  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.navigationDelegate.uiAlertController = nil;
        completionHandler(YES);
    }]];
    
    [self.navigationDelegate.uiAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                                                                  style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        self.navigationDelegate.uiAlertController = nil;
        completionHandler(NO);
    }]];
    
    [self.navigationDelegate presentViewController:self.navigationDelegate.uiAlertController animated:NO completion:nil];
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
runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSArray<NSURL *> *URLs))completionHandler
API_AVAILABLE(ios(18.4)){
    [self.navigationDelegate webView:webView runOpenPanelWithParameters:parameters initiatedByFrame:frame completionHandler:completionHandler];
}


- (BOOL) showURLFilterAlertForRequest:(NSURLRequest *)request
                     forContentFilter:(BOOL)contentFilter
                       filterResponse:(URLFilterRuleActions)filterResponse
{
    if (contentFilter == NO) {
        // The filter Response is block or the URL filter learning mode isn't switched on
        // Display "URL Blocked" (or red "X") top/right in window title bar
        [self showURLFilterMessage];
    }
    return NO;
}


- (NSURL *) downloadPathURL
{
    return self.navigationDelegate.downloadPathURL;
}


- (void) conditionallyDownloadAndOpenSEBConfigFromURL:(NSURL *)url
{
    [self.navigationDelegate conditionallyDownloadAndOpenSEBConfigFromURL:url];
}


- (void) openSEBConfigFromData:(NSData *)sebConfigData;
{
    [self.navigationDelegate openSEBConfigFromData:sebConfigData];
}


- (void) downloadSEBConfigFileFromURL:(NSURL *)url originalURL:(NSURL *)originalURL cookies:(NSArray <NSHTTPCookie *>*)cookies
{
    [self.navigationDelegate downloadSEBConfigFileFromURL:url originalURL:originalURL cookies:cookies];
}


- (void) downloadFileFromURL:(NSURL *)url filename:(NSString *)filename cookies:(NSArray <NSHTTPCookie *>*)cookies
{
    [self.navigationDelegate downloadFileFromURL:url filename:filename cookies:cookies];
}


- (void) fileDownloadedSuccessfully:(NSString *)path
{
    [self.navigationDelegate fileDownloadedSuccessfully:path];
}


- (BOOL) downloadingInTemporaryWebView
{
    return self.navigationDelegate.downloadingInTemporaryWebView;
}


- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url
{
    [self.navigationDelegate shouldStartLoadFormSubmittedURL:url];
}


- (void) transferCookiesToWKWebViewWithCompletionHandler:(void (^)(void))completionHandler
{
    [self.navigationDelegate transferCookiesToWKWebViewWithCompletionHandler:completionHandler];
}


- (BOOL) isNavigationAllowed
{
    if (_sebWebView) {
        return _sebWebView.isNavigationAllowed;
    } else {
        return [self isNavigationAllowedMainWebView:self.navigationDelegate.isMainBrowserWebViewActive];
    }
}

- (BOOL) isNavigationAllowedMainWebView:(BOOL)mainWebView
{
    return [self.navigationDelegate isNavigationAllowedMainWebView:mainWebView];
}

- (BOOL) isReloadAllowed
{
    if (_sebWebView) {
        return _sebWebView.isReloadAllowed;
    } else {
        return [self isReloadAllowedMainWebView:self.navigationDelegate.isMainBrowserWebViewActive];
    }
}

- (BOOL) isReloadAllowedMainWebView:(BOOL)mainWebView
{
    return [self.navigationDelegate isReloadAllowedMainWebView:mainWebView];
}

- (BOOL) showReloadWarning
{
    if (_sebWebView) {
        return _sebWebView.showReloadWarning;
    } else {
        return [self showReloadWarningMainWebView:self.navigationDelegate.isMainBrowserWebViewActive];
    }
}

- (BOOL) showReloadWarningMainWebView:(BOOL)mainWebView
{
    return [self.navigationDelegate showReloadWarningMainWebView:mainWebView];
}


- (NSString *) pageJavaScript
{
    return _javaScriptFunctions;
}

- (BOOL)allowDownloads
{
    return self.navigationDelegate.allowDownloads;
}

- (BOOL)allowUploads
{
    return self.navigationDelegate.allowUploads;
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


- (void) presentAlertWithTitle:(NSString *)title
                       message:(NSString *)message
{
    [self.navigationDelegate presentAlertWithTitle:title message:message];
}


#pragma mark - Search in WebView

- (void) searchText:(NSString *)textToSearch backwards:(BOOL)backwards caseSensitive:(BOOL)caseSensitive
{
    if (!textToSearch) {
        textToSearch = self.searchText;
    }
    [self.sebWebView searchText:textToSearch backwards:backwards caseSensitive:caseSensitive];
}


- (void) searchTextMatchFound:(BOOL)matchFound
{
//    [self.sebWebView.nativeWebView becomeFirstResponder];
    _searchMatchFound = matchFound;
    [self.navigationDelegate searchTextMatchFound:matchFound];
}


- (UIImage *)invertImage:(UIImage *)originalImage
{
    UIGraphicsBeginImageContext(originalImage.size);
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeCopy);
    CGRect imageRect = CGRectMake(0, 0, originalImage.size.width, originalImage.size.height);
    [originalImage drawInRect:imageRect];
    
    
    CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeDifference);
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, originalImage.size.height);
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
    //mask the image
    CGContextClipToMask(UIGraphicsGetCurrentContext(), imageRect,  originalImage.CGImage);
    CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(),[UIColor whiteColor].CGColor);
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, originalImage.size.width, originalImage.size.height));
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return returnImage;
}

- (NSInteger)highlightAllOccurencesOfString:(NSString*)searchString inWebView:(UIWebView *)webView
{
    //    NSString *path = [[NSBundle mainBundle] pathForResource:@"SearchWebView" ofType:@"js"];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SearchWebView" ofType:@"js"];
    NSString *jsCodeSearch = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [webView stringByEvaluatingJavaScriptFromString:jsCodeSearch];
    
    NSString *startSearch = [NSString stringWithFormat:@"MyApp_HighlightAllOccurencesOfString('%@')", searchString];
    [webView stringByEvaluatingJavaScriptFromString:startSearch];
    
    NSString *result = [webView stringByEvaluatingJavaScriptFromString:@"MyApp_SearchResultCount"];
    return [result integerValue];
}


- (void)removeAllHighlightsInWebView:(UIWebView *)webView
{
    [webView stringByEvaluatingJavaScriptFromString:@"MyApp_RemoveAllHighlights()"];
}


- (void)loadWebPageOrSearchResultWithString:(NSString *)webSearchString
{
    [self loadURL:[NSURL URLWithString:webSearchString]];
    
}


// Read Info.plist values from bundle
- (id) infoValueForKey:(NSString*)key
{
    if ([[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key])
        return [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key];
    
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
}


- (NSString *)tempDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    return documentsDirectoryPath;
}


@end
