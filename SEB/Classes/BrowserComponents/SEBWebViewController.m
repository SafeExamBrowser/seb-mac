//
//  SEBWebViewController.m
//
//  Created by Daniel R. Schneider on 06/01/16.
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

#import "SEBWebViewController.h"
#import "UIWebView+SEBWebView.h"
#import "Constants.h"
#import "AppDelegate.h"


@implementation SEBWebViewController

// Get statusbar appearance depending on device type (traditional or iPhone X like)
- (NSUInteger)statusBarAppearance {
    SEBUIController *sebUIController = [(AppDelegate*)[[UIApplication sharedApplication] delegate] sebUIController];
    return [sebUIController statusBarAppearanceForDevice];
}


- (void)loadView
{
    // Create a webview to fit underneath the navigation view (=fill the whole screen).
    CGRect webFrame = [[UIScreen mainScreen] bounds];
    if (!_sebWebView) {
        _sebWebView = [[UIWebView alloc] initWithFrame:webFrame];
    }
    
    NSUInteger statusBarAppearance = [self statusBarAppearance];
    _sebWebView.backgroundColor = (statusBarAppearance == mobileStatusBarAppearanceNone || statusBarAppearance == mobileStatusBarAppearanceLight ||
                                   statusBarAppearance == mobileStatusBarAppearanceExtendedNoneDark) ? [UIColor blackColor] : [UIColor whiteColor];
    _sebWebView.dataDetectorTypes = UIDataDetectorTypeNone;
    _sebWebView.scalesPageToFit = YES;
    if (@available(iOS 11.0, *)) {
        _sebWebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    }
    _sebWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    _sebWebView.scrollView.scrollEnabled = YES;
    [_sebWebView setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    // Set media playback properties on new webview
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    _sebWebView.mediaPlaybackRequiresUserAction = ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserMediaAutoplay"];
    
    UIUserInterfaceIdiom currentDevice = UIDevice.currentDevice.userInterfaceIdiom;
    if (currentDevice == UIUserInterfaceIdiomPad) {
        _sebWebView.allowsInlineMediaPlayback = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileAllowInlineMediaPlayback"];
    } else {
        _sebWebView.allowsInlineMediaPlayback = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileCompactAllowInlineMediaPlayback"];
    }
    _sebWebView.allowsPictureInPictureMediaPlayback = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileAllowPictureInPictureMediaPlayback"];;
    _sebWebView.mediaPlaybackAllowsAirPlay = NO;

    _sebWebView.delegate = self;
    self.view = _sebWebView;
    
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


- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if (parent) {
        // Add the view to the parent view and position it if you want
        [[parent view] addSubview:self.view];
        CGRect viewFrame = parent.view.bounds;
        //viewFrame.origin.y += kNavbarHeight;
        //viewFrame.size.height -= kNavbarHeight;
        [self.view setFrame:viewFrame];
        [self adjustScrollPosition];
        openCloseSlider = YES;
    } else {
        [self.view removeFromSuperview];
    }
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _sebWebView.frame = self.view.bounds;
    if (openCloseSlider) {
        openCloseSlider = NO;
        [self.browserTabViewController openCloseSliderForNewTab];
    }
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
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
    [super viewWillAppear:animated];

    _sebWebView.delegate = self;	// setup the delegate as the web view is shown
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    allowSpellCheck = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSpellCheck"];
    quitURLTrimmed = [[preferences secureStringForKey:@"org_safeexambrowser_SEB_quitURL"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    mobileEnableGuidedAccessLinkTransform = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileEnableGuidedAccessLinkTransform"];
    enableDrawingEditor = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableDrawingEditor"];
    _urlFilter = [SEBURLFilter sharedSEBURLFilter];
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self becomeFirstResponder];
    
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.sebWebView stopLoading];	// in case the web view is still loading its content
    self.sebWebView.delegate = nil;	// disconnect the delegate as the webview is hidden
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_browserTabViewController setLoading:NO];
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

- (void)stopLoading {
    [_sebWebView stopLoading];
}


- (void)loadURL:(NSURL *)url
{
    [self.sebWebView loadRequest:[NSURLRequest requestWithURL:url]];
}



#pragma mark -
#pragma mark Overlay Display

- (void) showURLFilterMessage
{
    if (!_filterMessageHolder) {
        
        CGRect frameRect = CGRectMake(0,0,155,21); // This will change based on the size you need
        UILabel *message = [[UILabel alloc] initWithFrame:frameRect];
        
        // Set message for URL blocked according to settings
        switch ([SEBURLFilter sharedSEBURLFilter].urlFilterMessage) {
                
            case URLFilterMessageText:
                message.text = NSLocalizedString(@"URL Blocked!", nil);
                [message setFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
                [message setTextColor:[UIColor redColor]];
                
                break;
                
            case URLFilterMessageX:
                message.text = @"✕";
                [message setFont:[UIFont systemFontOfSize:20]];
                [message setTextColor:[UIColor darkGrayColor]];
                break;
        }
        
        [message sizeToFit];
        
        CGSize messageLabelSize = message.frame.size;
        CGFloat messageLabelWidth = messageLabelSize.width + messageLabelSize.height;
        CGFloat messageLabelHeight = messageLabelSize.height * 1.5;
        CGRect messageLabelFrame = CGRectMake(0, 0, messageLabelWidth, messageLabelHeight);
        
        _filterMessageHolder = [[UIView alloc] initWithFrame:messageLabelFrame];
        message.center = _filterMessageHolder.center;
        
        if (!UIAccessibilityIsReduceTransparencyEnabled()) {
            _filterMessageHolder.backgroundColor = [UIColor clearColor];
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurEffectView.frame = _filterMessageHolder.bounds;
            blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [_filterMessageHolder addSubview:blurEffectView];

            UIView *backgroundTintView = [UIView new];
            backgroundTintView.frame = _filterMessageHolder.bounds;
            backgroundTintView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            backgroundTintView.backgroundColor = [UIColor lightGrayColor];
            backgroundTintView.alpha = 0.5;
            [_filterMessageHolder addSubview:backgroundTintView];

        } else {
            _filterMessageHolder.backgroundColor = UIColor.lightGrayColor;
        }
        [_filterMessageHolder addSubview:message];
        _filterMessageHolder.layer.cornerRadius = messageLabelHeight / 2;
        _filterMessageHolder.clipsToBounds = YES;
    }

    CGFloat superviewWidth = self.view.bounds.size.width;
    CGFloat messageWidth = _filterMessageHolder.frame.size.width;
    CGFloat messageHeight = _filterMessageHolder.frame.size.height;
    
    if (@available(iOS 11.0, *)) {
        [_filterMessageHolder setFrame:CGRectMake(
                                                  superviewWidth - self.view.safeAreaInsets.right - messageWidth - 10,
                                                  self.view.safeAreaInsets.top + 10,
                                                  messageWidth,
                                                  messageHeight
                                                  )];
    } else {
        // Fallback on earlier versions
        CGFloat topLayoutGuide = self.topLayoutGuide.length;
        [_filterMessageHolder setFrame:CGRectMake(
                                                  superviewWidth - messageWidth - 10,
                                                  topLayoutGuide + 10,
                                                  messageWidth,
                                                  messageHeight
                                                  )];
    }
    
    // Show the message
    [self.sebWebView insertSubview:_filterMessageHolder aboveSubview:self.sebWebView];
    
    // Remove the URL filter message after a delay
    [self performSelector:@selector(hideURLFilterMessage) withObject: nil afterDelay: 1];
    
}

    
- (void) hideURLFilterMessage
{
    [_filterMessageHolder removeFromSuperview];
}


#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    // starting the load, show the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
//    [self.searchBarController setLoading:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    _currentRequest = nil;

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
    
    NSString *webPageTitle;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([MyGlobals sharedMyGlobals].currentWebpageIndexPathRow == 0) {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowShowURL"] == browserWindowShowURLAlways) {
            webPageTitle = [_sebWebView url].absoluteString;
        } else {
            webPageTitle = [_sebWebView title];
        }
    } else {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowShowURL"] == browserWindowShowURLAlways) {
                webPageTitle = [_sebWebView url].absoluteString;
            } else {
                webPageTitle = [_sebWebView title];
            }
    }
    [_browserTabViewController setTitle:webPageTitle forWebViewController:self];

    // finished loading, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_browserTabViewController setLoading:NO];
    [self setBackForwardAvailabilty];
    
    // Look for a user cookie if logging in to an exam system/LMS supporting SEB Server
    // ToDo: Only search for cookie when logging in to Open edX
    NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray<NSHTTPCookie *> *cookies = cookieJar.cookies;
    [_browserTabViewController examineCookies:cookies];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    _currentRequest = nil;
    
    if (error.code == -999) {
        DDLogError(@"%s: Load Error -999: Another request initiated before the previous request was completed (%@)", __FUNCTION__, error.description);
        return;
    }
    
    // Hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_browserTabViewController setLoading:NO];
    [self setBackForwardAvailabilty];
    
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

        NSString *failingURLString = [error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey];
        NSString *errorMessage = [NSString stringWithFormat:@"%@%@", error.localizedDescription, showURL ? [NSString stringWithFormat:@"\n%@", failingURLString] : @""];
        
        if (self.browserTabViewController.sebViewController.alertController) {
            [self.browserTabViewController.sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
        }

        self.browserTabViewController.sebViewController.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Load Error", nil)
                                                                                  message:errorMessage
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [self.browserTabViewController.sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", nil)
                                                            style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                NSURL *failingURL = [NSURL URLWithString:failingURLString];
                                                                if (failingURL) {
                                                                    [self loadURL:failingURL];
                                                                }
                                                                self.browserTabViewController.sebViewController.alertController = nil;
                                                            }]];
        
        [self.browserTabViewController.sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                            style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                                self.browserTabViewController.sebViewController.alertController = nil;
                                                            }]];
        
        [self.browserTabViewController.sebViewController.topMostController presentViewController:self.browserTabViewController.sebViewController.alertController animated:NO completion:nil];
    }
}


/// Request handling
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // Check if quit URL has been clicked (regardless of current URL Filter)
    if ([[url.absoluteString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]] isEqualToString:quitURLTrimmed]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"quitLinkDetected" object:self];
        return NO;
    }
    
    NSURL *originalURL = url;
    
    // This is currently used for SEB Server handshake after logging in to Moodle
    if (navigationType == UIWebViewNavigationTypeFormSubmitted) {
        [_browserTabViewController shouldStartLoadFormSubmittedURL:url];
    }
    
    if ([url.scheme isEqualToString:@"newtab"]) {
        NSString *urlString = [[url resourceSpecifier] stringByRemovingPercentEncoding];
        originalURL = [NSURL URLWithString:urlString relativeToURL:[webView url]];
    }

    if (_urlFilter.enableURLFilter) {
        URLFilterRuleActions filterActionResponse = [_urlFilter testURLAllowed:originalURL];
        if (filterActionResponse != URLFilterActionAllow) {
            /// Content is not allowed: Show teach URL alert if activated or just indicate URL is blocked filterActionResponse == URLFilterActionBlock ||
            //            if (![self showURLFilterAlertSheetForWindow:self forRequest:request forContentFilter:YES filterResponse:filterActionResponse]) {
            /// User didn't allow the content, don't load it
            
            // We show the URL blocked overlay message only if a link was actively tapped by the user
            if (navigationType == UIWebViewNavigationTypeLinkClicked) {
                [self showURLFilterMessage];
            }
            
            DDLogWarn(@"This link was blocked by the URL filter: %@", originalURL.absoluteString);
            return NO;
            // }
        }
    }

    if (UIAccessibilityIsGuidedAccessEnabled()) {
        if (navigationType == UIWebViewNavigationTypeLinkClicked &&
            mobileEnableGuidedAccessLinkTransform) {
            navigationType = UIWebViewNavigationTypeOther;
            DDLogVerbose(@"%s: navigationType changed to UIWebViewNavigationTypeOther (%ld)", __FUNCTION__, (long)navigationType);
            [webView loadRequest:request];
            return NO;
        }
    }

    NSString *fileExtension = [url pathExtension];

    if ([url.scheme isEqualToString:@"newtab"]) {
        
        // First check if links requesting to be opened in a new windows are generally blocked
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] != getGenerallyBlocked) {
            // load link only if it's on the same host like the one of the current page
            if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkBlockForeign"] ||
                [_currentMainHost isEqualToString:[[request mainDocumentURL] host]]) {
                if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] == openInNewWindow) {
                    // Open in new tab
                    [_browserTabViewController openNewTabWithURL:originalURL];
                    return NO;
                }
                if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] == openInSameWindow) {
                    // Load URL request in existing tab
                    request = [NSURLRequest requestWithURL:originalURL];
                    [webView loadRequest:request];
                    return NO;
                }
            }
        }
        // Opening links in new windows is not allowed by current policies
        // We show the URL blocked overlay message only if a link was actively tapped by the user
        if (navigationType == UIWebViewNavigationTypeLinkClicked) {
            [self showURLFilterMessage];
        }
        return NO;
    }
    
    if ([url.scheme isEqualToString:@"about"]) {
        return NO;
    }
    
    if ([url.scheme isEqualToString:@"data"]) {
        NSString *urlResourceSpecifier = [[url resourceSpecifier] stringByRemovingPercentEncoding];
        DDLogDebug(@"resourceSpecifier of data: URL is %@", urlResourceSpecifier);
        NSRange mediaTypeRange = [urlResourceSpecifier rangeOfString:@","];
        if (mediaTypeRange.location != NSNotFound && urlResourceSpecifier.length > mediaTypeRange.location > 0) {
            NSString *mediaType = [urlResourceSpecifier substringToIndex:mediaTypeRange.location];
            NSArray *mediaTypeParameters = [mediaType componentsSeparatedByString:@";"];
            if ([mediaTypeParameters indexOfObject:SEBMIMEType] != NSNotFound &&
                [preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
                NSString *sebConfigString = [urlResourceSpecifier substringFromIndex:mediaTypeRange.location+1];
                NSData *sebConfigData;
                if ([mediaTypeParameters indexOfObject:@"base64"] == NSNotFound) {
                    sebConfigData = [sebConfigString dataUsingEncoding:NSUTF8StringEncoding];
                } else {
                    sebConfigData = [[NSData alloc] initWithBase64EncodedString:sebConfigString options:NSDataBase64DecodingIgnoreUnknownCharacters];
                }
                [_browserTabViewController conditionallyOpenSEBConfigFromData:sebConfigData];
            } else if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDownUploads"]) {
                NSString *fileDataString = [urlResourceSpecifier substringFromIndex:mediaTypeRange.location+1];
                NSData *fileData;
                if ([mediaTypeParameters indexOfObject:@"base64"] == NSNotFound) {
                    fileData = [fileDataString dataUsingEncoding:NSUTF8StringEncoding];
                } else {
                    fileData = [[NSData alloc] initWithBase64EncodedString:fileDataString options:NSDataBase64DecodingIgnoreUnknownCharacters];
                }
                NSString *filename = [self saveData:fileData];
                if (filename) {
                    DDLogInfo(@"Successfully saved website generated data: %@", url);
                    [self.browserTabViewController.sebViewController alertWithTitle:NSLocalizedString(@"Download Finished", nil)
                                                                            message:[NSString stringWithFormat:NSLocalizedString(@"Saved file '%@'", nil), filename]
                                                                       action1Title:NSLocalizedString(@"OK", nil)
                                                                     action1Handler:^{}
                                                                       action2Title:nil
                                                                     action2Handler:^{}];
                } else {
                    DDLogError(@"Failed to save website generated data: %@", url);
                }
            }
        }
        return NO;
    }
    
    // Check if this is a seb:// or sebs:// link or a .seb file link
    if (([url.scheme isEqualToString:SEBProtocolScheme] ||
        [url.scheme isEqualToString:SEBSSecureProtocolScheme] ||
        [fileExtension isEqualToString:SEBFileExtension]) &&
        [preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
        // If the scheme is seb(s):// or the file extension .seb,
        // we (conditionally) download and open the linked .seb file
        [_browserTabViewController conditionallyDownloadAndOpenSEBConfigFromURL:url];
        return NO;
    }

    // Downloading image files for the freehand drawing functionality
    if(navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeOther) {
        if ([fileExtension isEqualToString:@"png"] || [fileExtension isEqualToString:@"jpg"] || [fileExtension isEqualToString:@"tif"] || [fileExtension isEqualToString:@"xls"]) {
            if (enableDrawingEditor) {
                // Get the filename of the loaded ressource form the UIWebView's request URL
                NSString *filename = [url lastPathComponent];
                DDLogInfo(@"%s: Filename: %@", __FUNCTION__, filename);
                // Get the path to the App's Documents directory
                NSString *docPath = [self tempDirectoryPath];
                // Combine the filename and the path to the documents dir into the full path
                NSString *pathToDownloadTo = [NSString stringWithFormat:@"%@/%@", docPath, filename];
                
                
                // Load the file from the remote server
                NSData *tmp = [NSData dataWithContentsOfURL:url];
                // Save the loaded data if loaded successfully
                if (tmp != nil) {
                    NSError *error = nil;
                    UIImage *sourceImage = [UIImage imageWithData: tmp];
                    // ToDo: Process image if necessary
                    UIImage *processedImage = sourceImage;
                    
                    NSData *dataForPNGFile = UIImagePNGRepresentation(processedImage);
                    
                    // Write the contents of our tmp object into a file
                    [dataForPNGFile writeToFile:pathToDownloadTo options:NSDataWritingAtomic error:&error];
                    if (error != nil) {
                        DDLogError(@"%s: Failed to save the file: %@", __FUNCTION__, [error description]);
                    } else {
                        //                    NSString *base64PNGData = [dataForPNGFile base64EncodedStringWithOptions:0];
                        //                    NSString *simulateDropFunction = [NSString stringWithFormat:@"SEB_replaceImage('%@')", base64PNGData];
                        //                    NSString *result =[_sebWebView stringByEvaluatingJavaScriptFromString:simulateDropFunction];
                        //                    NSString *result = [_sebWebView stringByEvaluatingJavaScriptFromString:@"SEB_replaceImage()"];
                        // Display an UIAlertView that shows the users we saved the file :)
                        NSURL *drawingURL = [NSURL fileURLWithPath:pathToDownloadTo];
                        // Replace file:// scheme with drawing://
                        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:drawingURL resolvingAgainstBaseURL:NO];
                        // Download the .seb file directly into memory (not onto disc like other files)
                        urlComponents.scheme = @"drawing";
                        drawingURL = urlComponents.URL;
                        //                    NSURL *drawingURL = [NSURL URLWithString:[NSString stringWithFormat:@"drawing://%@", pathToDownloadTo]];
                        [_browserTabViewController openNewTabWithURL:drawingURL image:processedImage];
                        //                    UIAlertView *filenameAlert = [[UIAlertView alloc] initWithTitle:@"File saved" message:[NSString stringWithFormat:@"The file %@ has been saved. Result: %@", filename, result] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        //                    [filenameAlert show];
                        return NO;
                    }
                } else {
                    // File could notbe loaded -> handle errors
                }
            }
        } else {
            // File type not supported
        }

    }
    _currentRequest = request;
    _currentURL = url.absoluteString;
    _currentMainHost = url.host;
    return YES;
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
    [_browserTabViewController setCanGoBack:_sebWebView.canGoBack canGoForward:_sebWebView.canGoForward];
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
