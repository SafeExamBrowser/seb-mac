//
//  SEBUIWebViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 05.03.21.
//

#import "SEBUIWebViewController.h"
#import "UIWebView+SEBWebView.h"
#import "Constants.h"
#import "AppDelegate.h"

@interface SEBUIWebViewController ()

@end

@implementation SEBUIWebViewController

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
    allowSpellCheck = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSpellCheck"];
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


#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.navigationDelegate sebWebViewDidStartLoad];

}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Get JavaScript code for modifying targets of hyperlinks in the webpage so can be open in new tabs
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ModifyPages" ofType:@"js"];
    jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    [_sebWebView stringByEvaluatingJavaScriptFromString:jsCode];
    
    [_sebWebView stringByEvaluatingJavaScriptFromString:@"SEB_ModifyLinkTargets()"];
    [_sebWebView stringByEvaluatingJavaScriptFromString:@"SEB_ModifyWindowOpen()"];
    
    [_sebWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"SEB_AllowSpellCheck(%@)", allowSpellCheck ? @"true" : @"false"]];
    
    //[webView stringByEvaluatingJavaScriptFromString:@"SEB_increaseMaxZoomFactor()"];
    
    //[self highlightAllOccurencesOfString:@"SEB" inWebView:webView];
    //[self speakWebView:webView];
    
    [self.navigationDelegate sebWebViewDidFinishLoad];

    // Look for a user cookie if logging in to an exam system/LMS supporting SEB Server
    // ToDo: Only search for cookie when logging in to Open edX
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray<NSHTTPCookie *> *cookies = cookieJar.cookies;
    [self.navigationDelegate examineCookies:cookies];
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

    if ([url.scheme isEqualToString:@"newtab"]) {
        NSString *urlString = [[url resourceSpecifier] stringByRemovingPercentEncoding];
        NSURL *originalURL = [NSURL URLWithString:urlString relativeToURL:[_sebWebView url]];
        request = [NSURLRequest requestWithURL:originalURL];
        newTabRequested = YES;
    }
    
    return [self.navigationDelegate sebWebViewShouldStartLoadWithRequest:request navigationAction:navigationAction newTab:newTabRequested];
}


- (NSString *)saveData:(NSData *)data
{
    // Get the path to the App's Documents directory
    NSURL *documentsDirectory = [NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSString *filename = NSLocalizedString(@"Untitled", @"untitled filename");
    
    NSDate *time = [NSDate date];
    NSDateFormatter* dateFormatter = [NSDateFormatter new];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_hh-mm-ssZZZZZ"];
    NSString *timeString = [dateFormatter stringFromDate:time];
    filename = [NSString stringWithFormat:@"%@_%@", filename, timeString];
    
    NSString *fullPath = [documentsDirectory URLByAppendingPathComponent:filename].path;
    DDLogInfo(@"%s File path: %@", __FUNCTION__, fullPath);
    
    BOOL success = [NSFileManager.defaultManager createFileAtPath:fullPath contents:data attributes:nil];
    if (success) {
        return filename;
    } else {
        return nil;
    }
}


- (void)setBackForwardAvailabilty
{
    [self.navigationDelegate setCanGoBack:_sebWebView.canGoBack canGoForward:_sebWebView.canGoForward];
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


// Create a UIWebView to hold new webpages
- (UIWebView *)createNewWebView {
    // Create a webview to fit underneath the navigation view (=fill the whole screen).
    CGRect webFrame = [[UIScreen mainScreen] bounds];
    UIWebView *newWebView = [[UIWebView alloc] initWithFrame:webFrame];
    
    newWebView.backgroundColor = [UIColor lightGrayColor];
    newWebView.scalesPageToFit = YES;
    newWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    newWebView.scrollView.scrollEnabled = YES;
    [newWebView setTranslatesAutoresizingMaskIntoConstraints:YES];
    newWebView.delegate = self;
    return newWebView;
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
