//
//  SEBUIWebViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 05.03.21.
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

#import "SEBUIWebViewController.h"
#import "UIWebView+SEBWebView.h"
#import "Constants.h"
#import "AppDelegate.h"

@interface SEBUIWebViewController ()

@end

@implementation SEBUIWebViewController

- (instancetype)initWithDelegate:(id <SEBAbstractWebViewNavigationDelegate>)delegate
{
    self = [super init];
    if (self) {
        _navigationDelegate = delegate;
    }
    return self;
}


- (void)loadView
{
    // Create a webview to fit underneath the navigation view (=fill the whole screen).
    CGRect webFrame = [[UIScreen mainScreen] bounds];
    if (!_sebWebView) {
        _sebWebView = [[UIWebView alloc] initWithFrame:webFrame];
    }
    
    // Get statusbar appearance depending on device type (traditional or iPhone X like)
    SEBBackgroundTintStyle backgroundTintStyle = [self.navigationDelegate backgroundTintStyle];
    _sebWebView.backgroundColor = backgroundTintStyle == SEBBackgroundTintStyleDark ? [UIColor blackColor] : [UIColor whiteColor];
    _sebWebView.dataDetectorTypes = UIDataDetectorTypeNone;
    _sebWebView.scalesPageToFit = YES;
    if (@available(iOS 11.0, *)) {
        _sebWebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    }
    _sebWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _sebWebView.scrollView.scrollEnabled = YES;
    [_sebWebView setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    // Set media playback properties on new webview

    WKWebViewConfiguration *webViewConfiguration = self.navigationDelegate.wkWebViewConfiguration;
    
    _sebWebView.mediaPlaybackRequiresUserAction = webViewConfiguration.mediaTypesRequiringUserActionForPlayback != WKAudiovisualMediaTypeNone;
    
    _sebWebView.allowsInlineMediaPlayback = webViewConfiguration.allowsInlineMediaPlayback;
    _sebWebView.allowsPictureInPictureMediaPlayback = webViewConfiguration.allowsPictureInPictureMediaPlayback;
    _sebWebView.mediaPlaybackAllowsAirPlay = NO;

    _sebWebView.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIWindowDidBecomeKeyNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if (UIApplication.sharedApplication.keyWindow == self.view.window) {
            DDLogDebug(@"UIWindowDidBecomeKeyNotification with UIApplication.sharedApplication.keyWindow == self.view.window.");
            // ToDo: The possible fix below first has to be tested
            //[self reload];
        }
    }];
}


// Adjust scroll position so top of webpage is below the navigation bar (if enabled)
// and bottom is above the tool bar (if SEB dock is enabled)
- (void)adjustScrollPosition
{
    if (@available(iOS 11.0, *)) {
        // Not necessary for iOS 11 thanks to Safe Area
    } else {
        [_sebWebView.scrollView setContentInset:UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)];
        [_sebWebView.scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0)];
        [_sebWebView.scrollView setZoomScale:0 animated:YES];
    }
}


- (void)didMoveToParentViewController
{
    [self adjustScrollPosition];
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}


- (void)viewWillTransitionToSize
{
    if (@available(iOS 11.0, *)) {
        // Not necessary for iOS 11 thanks to Safe Area
    } else {
        // Allow the animation to complete
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // Adjust scroll position so top of webpage is below the navigation bar (if enabled)
            // and bottom is above the tool bar (if SEB dock is enabled)
            [self adjustScrollPosition];
        });
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    _sebWebView.delegate = self;    // setup the delegate as the web view is shown
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    allowSpellCheck = self.navigationDelegate.allowSpellCheck;
    mobileEnableGuidedAccessLinkTransform = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileEnableGuidedAccessLinkTransform"];
    enableDrawingEditor = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableDrawingEditor"];
}


- (void)viewDidAppear:(BOOL)animated
{
}


- (void)viewWillDisappear:(BOOL)animated
{
    self.sebWebView.delegate = nil;    // disconnect the delegate as the webview is hidden
}


#pragma mark -
#pragma mark Controller interface

- (void)toggleScrollLock {
    _isScrollLockActive = !_isScrollLockActive;
    _sebWebView.scrollView.scrollEnabled = !_isScrollLockActive;
    _sebWebView.scrollView.bounces = !_isScrollLockActive;
    if (_isScrollLockActive) {
        // Disable text/content selection
        [_sebWebView stringByEvaluatingJavaScriptFromString: @"document.documentElement.style.webkitUserSelect='none';"];
        // Disable selection context popup (copy/paste etc.)
        [_sebWebView stringByEvaluatingJavaScriptFromString: @"document.documentElement.style.webkitTouchCallout='none';"];
        // Disable magnifier glass
        [_sebWebView stringByEvaluatingJavaScriptFromString: @"document.body.style.webkitUserSelect='none';"];
    } else {
        // Enable text/content selection
        [_sebWebView stringByEvaluatingJavaScriptFromString: @"document.documentElement.style.webkitUserSelect='text';"];
        // Enable selection context popup (copy/paste etc.)
        [_sebWebView stringByEvaluatingJavaScriptFromString: @"document.documentElement.style.webkitTouchCallout='default';"];
        // Enable magnifier glass
        [_sebWebView stringByEvaluatingJavaScriptFromString: @"document.body.style.webkitUserSelect='default';"];
    }
}

- (void)backToStart {
    [_sebWebView goBack];
}

- (void)goBack {
    [_sebWebView goBack];
}

- (void)goForward {
    [_sebWebView goForward];
}

- (void)reload {
    [_sebWebView reload];
}

- (void)loadURL:(NSURL *)url
{
    [self.sebWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)stopLoading {
    [_sebWebView stopLoading];
}


- (NSString *) stringByEvaluatingJavaScriptFromString:(NSString *)js
{
    return [_sebWebView stringByEvaluatingJavaScriptFromString:js];
}


- (void) setPrivateClipboardEnabled:(BOOL)privateClipboardEnabled
{
    return;
}

- (void)setAllowDictionaryLookup:(BOOL)allowDictionaryLookup
{
    return;
}

- (void)setAllowPDFPlugIn:(BOOL)allowPDFPlugIn
{
    return;
}


#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.navigationDelegate sebWebViewDidStartLoad];

}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_sebWebView stringByEvaluatingJavaScriptFromString:self.navigationDelegate.pageJavaScript];
    
    [_sebWebView stringByEvaluatingJavaScriptFromString:@"SEB_ModifyLinkTargets()"];
    [_sebWebView stringByEvaluatingJavaScriptFromString:@"SEB_ModifyWindowOpen()"];
    
    [_sebWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"SEB_AllowSpellCheck(%@)", allowSpellCheck ? @"true" : @"false"]];
    
    //[webView stringByEvaluatingJavaScriptFromString:@"SEB_increaseMaxZoomFactor()"];
    
    //[self highlightAllOccurencesOfString:@"SEB" inWebView:webView];
    //[self speakWebView:webView];
    
    [self.navigationDelegate sebWebViewDidFinishLoad];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.navigationDelegate sebWebViewDidFailLoadWithError:error];

}


/// Request handling
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    if (UIAccessibilityIsGuidedAccessEnabled()) {
        if (navigationType == UIWebViewNavigationTypeLinkClicked &&
            mobileEnableGuidedAccessLinkTransform) {
            navigationType = UIWebViewNavigationTypeOther;
            DDLogVerbose(@"%s: navigationType changed to UIWebViewNavigationTypeOther (%ld)", __FUNCTION__, (long)navigationType);
            [webView loadRequest:request];
            return NO;
        }
    }
    BOOL newTabRequested = NO;
    SEBWKNavigationAction *navigationAction = [SEBWKNavigationAction new];
    switch (navigationType) {
        case UIWebViewNavigationTypeFormSubmitted:
            navigationAction.writableNavigationType = WKNavigationTypeFormSubmitted;
            break;
            
        case UIWebViewNavigationTypeLinkClicked:
            navigationAction.writableNavigationType = WKNavigationTypeLinkActivated;
            break;
            
        case UIWebViewNavigationTypeBackForward:
            navigationAction.writableNavigationType = WKNavigationTypeBackForward;
            break;
            
        case UIWebViewNavigationTypeReload:
            navigationAction.writableNavigationType = WKNavigationTypeReload;
            break;
            
        case UIWebViewNavigationTypeFormResubmitted:
            navigationAction.writableNavigationType = WKNavigationTypeFormResubmitted;
            break;
            
        case UIWebViewNavigationTypeOther:
            navigationAction.writableNavigationType = WKNavigationTypeOther;
            break;
            
        default:
            break;
    }

    NSURL *url = [request URL];
    NSString *httpMethod = request.HTTPMethod;
    NSDictionary<NSString *,NSString *> *allHTTPHeaderFields = request.allHTTPHeaderFields;
    DDLogDebug(@"HTTP method for URL %@: %@", url, httpMethod);
//    DDLogDebug(@"All HTTP header fields for URL %@: %@", url, allHTTPHeaderFields);
    if (url) {
        [self.navigationDelegate examineHeaders:allHTTPHeaderFields forURL:url];
        NSArray<NSHTTPCookie *> *cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies;
        [self.navigationDelegate examineCookies:cookies forURL:url];
    }

    if ([url.scheme isEqualToString:@"newtab"]) {
        NSString *urlString = [[url resourceSpecifier] stringByRemovingPercentEncoding];
        NSURL *originalURL = [NSURL URLWithString:urlString relativeToURL:[_sebWebView url]];
        request = [NSURLRequest requestWithURL:originalURL];
        newTabRequested = YES;
    }
    
    navigationAction.writableRequest = request;

    NSString *fileExtension = [url pathExtension];

    // Check if this is a seb:// or sebs:// link or a .seb file link
    if ((fileExtension && [fileExtension caseInsensitiveCompare:SEBFileExtension] == NSOrderedSame) &&
        self.navigationDelegate.downloadingInTemporaryWebView) {
        if (!waitingForConfigDownload) {
            waitingForConfigDownload = YES;
            if (![self.navigationDelegate originalURLIsEqualToURL:url]) {
                // If the scheme is seb(s):// or the file extension .seb,
                // we (conditionally) download and open the linked .seb file
                [self.navigationDelegate decidePolicyForMIMEType:@"" url:url canShowMIMEType:NO isForMainFrame:YES suggestedFilename:nil cookies:@[]];
                return NO;

            }
        } else if ([self.navigationDelegate originalURLIsEqualToURL:url]){
            waitingForConfigDownload = NO;
            // If the scheme is seb(s):// or the file extension .seb,
            // we (conditionally) download and open the linked .seb file
            [self.navigationDelegate decidePolicyForMIMEType:@"" url:url canShowMIMEType:NO isForMainFrame:YES suggestedFilename:nil cookies:@[]];
            return NO;
        }
    }

    if (!url.hasDirectoryPath &&
        ((url.pathExtension && [url.pathExtension caseInsensitiveCompare:filenameExtensionPDF] == NSOrderedSame) &&
         self.downloadFilename.length == 0)) {
        NSString *javaScript = [NSString stringWithFormat:@"document.querySelector('[href=\"%@\"]')?.download", url.absoluteString];
        self.downloadFilename = [webView stringByEvaluatingJavaScriptFromString:javaScript];
    } else {
        self.downloadFilename = nil;
    }
    if (self.downloadFilename.length != 0) {
        BOOL displayPDF = self.downloadFilename.pathExtension && [self.downloadFilename.pathExtension caseInsensitiveCompare:filenameExtensionPDF] == NSOrderedSame;
        if (displayPDF) {
            newTabRequested = YES;
        }
    }

    SEBNavigationAction *delegateNavigationAction = [self.navigationDelegate decidePolicyForNavigationAction:navigationAction newTab:newTabRequested configuration:nil downloadFilename:self.downloadFilename];
    SEBNavigationActionPolicy navigationActionPolicy = delegateNavigationAction.policy;
    if (navigationActionPolicy == SEBNavigationActionPolicyAllow) {
        return YES;
    } else {
        return NO;
    }
}


- (BOOL)canGoBack {
    return _sebWebView.canGoBack;
}


- (BOOL)canGoForward {
    return _sebWebView.canGoForward;
}


- (nonnull id)nativeWebView {
    return _sebWebView;
}


- (NSURL *)url {
    return [_sebWebView url];
}


- (NSString*)pageTitle
{
    return [_sebWebView title];
}




#pragma mark - Search in WebView

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
