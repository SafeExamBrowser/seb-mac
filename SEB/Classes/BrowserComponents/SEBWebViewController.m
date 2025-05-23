//
//  SEBWebViewController.m
//
//  Created by Daniel R. Schneider on 06/01/16.
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

#import "SEBWebViewController.h"
#import "UIWebView+SEBWebView.h"
#import "Constants.h"
#import "AppDelegate.h"


@implementation SEBWebViewController

- (instancetype)initNewTabWithCommonHost:(BOOL)commonHostTab overrideSpellCheck:(BOOL)overrideSpellCheck
{
    self = [super init];
    if (self) {
        SEBAbstractWebView *sebAbstractWebView = [[SEBAbstractWebView alloc] initNewTabWithCommonHost:commonHostTab overrideSpellCheck:(BOOL)overrideSpellCheck];
        sebAbstractWebView.navigationDelegate = self;
        _sebWebView = sebAbstractWebView;
        _urlFilter = [SEBURLFilter sharedSEBURLFilter];
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        quitURLTrimmed = [[preferences secureStringForKey:@"org_safeexambrowser_SEB_quitURL"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        // Get JavaScript code for modifying targets of hyperlinks in the webpage so can be open in new tabs
        NSString *path = [[NSBundle mainBundle] pathForResource:@"ModifyPages" ofType:@"js"];
        _javaScriptFunctions = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
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
        openCloseSlider = YES;
    } else {
        [self.view removeFromSuperview];
    }
}


- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    ((UIView *)_sebWebView.nativeWebView).frame = self.view.bounds;
    [_sebWebView viewDidLayoutSubviews];
    if (openCloseSlider) {
        openCloseSlider = NO;
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

    [_sebWebView viewDidAppear:animated];
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
#pragma mark Controller interface

//- (id)nativeWebView {
//    return _sebWebView.nativeWebView;
//}
//
//- (NSURL*)url {
//    return _sebWebView.url;
//}
//
//
//- (NSString*)title {
//    return _sebWebView.title;
//}
//
//
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


//- (void)backToStart {
//    [_sebWebView goBack];
//}
//
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
    [_sebWebView loadURL:url];
}


/// SEBAbstractWebViewNavigationDelegate Methods

@synthesize wkWebViewConfiguration;

- (WKWebViewConfiguration *)wkWebViewConfiguration
{
    return self.navigationDelegate.wkWebViewConfiguration;
}


@synthesize customSEBUserAgent;

- (NSString *) customSEBUserAgent
{
    return self.navigationDelegate.customSEBUserAgent;
    
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
    UIView *nativeWebView = (UIView *)[_sebWebView nativeWebView];
    [nativeWebView insertSubview:_filterMessageHolder aboveSubview:nativeWebView];
    
    // Remove the URL filter message after a delay
    [self performSelector:@selector(hideURLFilterMessage) withObject: nil afterDelay: 1];
    
}

    
- (void) hideURLFilterMessage
{
    [_filterMessageHolder removeFromSuperview];
}


#pragma mark -
#pragma mark SEBAbstractWebViewNavigationDelegate Methods

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
    [self.navigationDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
}

- (void)sebWebViewDidFinishLoad
{
    NSString *webPageTitle;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([MyGlobals sharedMyGlobals].currentWebpageIndexPathRow == 0) {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowShowURL"] == browserWindowShowURLAlways) {
            webPageTitle = [_sebWebView url].absoluteString;
        } else {
            webPageTitle = [_sebWebView pageTitle];
        }
    } else {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowShowURL"] == browserWindowShowURLAlways) {
                webPageTitle = [_sebWebView url].absoluteString;
            } else {
                webPageTitle = [_sebWebView pageTitle];
            }
    }
    [self.navigationDelegate setTitle:webPageTitle forWebViewController:self];

    // finished loading, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.navigationDelegate setLoading:NO];
    [self setBackForwardAvailabilty];
}


- (void)sebWebViewDidFailLoadWithError:(NSError *)error
{
    _currentRequest = nil;
    
    if (error.code == -999) {
        DDLogError(@"%s: Load Error -999: Another request initiated before the previous request was completed (%@)", __FUNCTION__, error.description);
        return;
    }
    
    // Hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.navigationDelegate setLoading:NO];
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
        
        if (self.navigationDelegate.uiAlertController) {
            [self.navigationDelegate.uiAlertController dismissViewControllerAnimated:NO completion:nil];
        }

        self.navigationDelegate.uiAlertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Load Error", nil)
                                                                                  message:errorMessage
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [self.navigationDelegate.uiAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", nil)
                                                            style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                NSURL *failingURL = [NSURL URLWithString:failingURLString];
                                                                if (failingURL) {
                                                                    [self loadURL:failingURL];
                                                                }
            self.navigationDelegate.uiAlertController = nil;
                                                            }]];
        
        [self.navigationDelegate.uiAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                            style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            self.navigationDelegate.uiAlertController = nil;
                                                            }]];
        
        [self.navigationDelegate presentViewController:self.navigationDelegate.uiAlertController animated:NO completion:nil];
    }
}


/// Request handling
- (BOOL)sebWebViewShouldStartLoadWithRequest:(NSURLRequest *)request
                            navigationAction:(WKNavigationAction *)navigationAction
                                      newTab:(BOOL)newTab
{
    NSURL *url = [request URL];
    WKNavigationType navigationType = navigationAction.navigationType;
    NSString *httpMethod = request.HTTPMethod;
    NSDictionary<NSString *,NSString *> *allHTTPHeaderFields = request.allHTTPHeaderFields;
    DDLogVerbose(@"Navigation type for URL %@: %ld", url, (long)navigationType);
    DDLogVerbose(@"HTTP method for URL %@: %@", url, httpMethod);
    DDLogVerbose(@"All HTTP header fields for URL %@: %@", url, allHTTPHeaderFields);

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    NSURL *originalURL = url;
    
    // This is currently used for SEB Server handshake after logging in to Moodle
    if (navigationType == WKNavigationTypeFormSubmitted) {
        [self.navigationDelegate shouldStartLoadFormSubmittedURL:url];
    }
    
    // Check if quit URL has been clicked (regardless of current URL Filter)
    if ([[originalURL.absoluteString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]] isEqualToString:quitURLTrimmed]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"quitLinkDetected" object:self];
        return NO;
    }
    
    if (_urlFilter.enableURLFilter) {
        URLFilterRuleActions filterActionResponse = [_urlFilter testURLAllowed:originalURL];
        if (filterActionResponse != URLFilterActionAllow) {
            /// Content is not allowed: Show teach URL alert if activated or just indicate URL is blocked filterActionResponse == URLFilterActionBlock ||
            //            if (![self showURLFilterAlertSheetForWindow:self forRequest:request forContentFilter:YES filterResponse:filterActionResponse]) {
            /// User didn't allow the content, don't load it
            
            // We show the URL blocked overlay message only if a link was actively tapped by the user
            if (navigationType == WKNavigationTypeLinkActivated) {
                [self showURLFilterMessage];
            }
            
            DDLogWarn(@"This link was blocked by the URL filter: %@", originalURL.absoluteString);
            return NO;
            // }
        }
    }

    NSString *fileExtension = [url pathExtension];

    if (newTab) {
        
        // First check if links requesting to be opened in a new windows are generally blocked
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] != getGenerallyBlocked) {
            // load link only if it's on the same host like the one of the current page
            if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkBlockForeign"] ||
                [_currentMainHost isEqualToString:[[request mainDocumentURL] host]]) {
                if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] == openInNewWindow) {
                    // Open in new tab
                    [self.navigationDelegate openNewTabWithURL:url];
                    return NO;
                }
                if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] == openInSameWindow) {
                    // Load URL request in existing tab
                    request = [NSURLRequest requestWithURL:url];
                    [_sebWebView loadURL:request.URL];
                    return NO;
                }
            }
        }
        // Opening links in new windows is not allowed by current policies
        // We show the URL blocked overlay message only if a link was actively tapped by the user
        if (navigationType == WKNavigationTypeLinkActivated) {
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
                [self.navigationDelegate conditionallyOpenSEBConfigFromData:sebConfigData];
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
                    [self.navigationDelegate.sebViewController alertWithTitle:NSLocalizedString(@"Download Finished", nil)
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
        if (![self.navigationDelegate downloadingInTemporaryWebView]) {
            [self.navigationDelegate conditionallyDownloadAndOpenSEBConfigFromURL:url];
            return NO;
        }
    }

    // Downloading image files for the freehand drawing functionality
    if(navigationType == WKNavigationTypeLinkActivated || navigationType == WKNavigationTypeOther) {
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
                        [self.navigationDelegate openNewTabWithURL:drawingURL image:processedImage];
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


- (BOOL)sebWebViewDecidePolicyForMIMEType:(NSString*)mimeType
                                      url:(NSURL *)url
                          canShowMIMEType:(BOOL)canShowMIMEType
                           isForMainFrame:(BOOL)isForMainFrame
                        suggestedFilename:(NSString *)suggestedFilename
                                  cookies:(NSArray<NSHTTPCookie *> *)cookies
{
    return [self.navigationDelegate sebWebView:_sebWebView decidePolicyForMIMEType:mimeType url:url canShowMIMEType:canShowMIMEType isForMainFrame:isForMainFrame suggestedFilename:suggestedFilename cookies:cookies];
}

    
- (void)setBackForwardAvailabilty
{
    [self.navigationDelegate setCanGoBack:_sebWebView.canGoBack canGoForward:_sebWebView.canGoForward];
}

- (BOOL)canGoBack {
    return [_sebWebView canGoBack];
}


- (BOOL)canGoForward {
    return [_sebWebView canGoForward];
}


- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
{
    return [self.navigationDelegate openNewTabWithURL:url];
}


- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies
{
    [self.navigationDelegate examineCookies:cookies];
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
    [self.navigationDelegate.uiAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
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
    [self.navigationDelegate.uiAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                                  style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.navigationDelegate.uiAlertController = nil;
        completionHandler(YES);
    }]];
    
    [self.navigationDelegate.uiAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
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
//    [self.navigationDelegate webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
}


- (void)webView:(WKWebView *)webView
runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSArray<NSURL *> *URLs))completionHandler
{
//    [self.navigationDelegate webView:webView runOpenPanelWithParameters:parameters initiatedByFrame:frame completionHandler:completionHandler];
}


- (BOOL) downloadingInTemporaryWebView
{
    return [self.navigationDelegate downloadingInTemporaryWebView];
}


- (void) transferCookiesToWKWebViewWithCompletionHandler:(void (^)(void))completionHandler
{
    [self.navigationDelegate transferCookiesToWKWebViewWithCompletionHandler:completionHandler];
}


- (NSString *) pageJavaScript
{
    return _javaScriptFunctions;
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
