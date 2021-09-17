//
//  SEBWebViewController.m
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 02.07.21.
//

#import "SEBWebViewController.h"
#import "WebKit+WebKitExtensions.h"
#include "WebStorageManagerPrivate.h"
#include "WebPreferencesPrivate.h"
#import "WebPluginDatabase.h"

@implementation SEBWebViewController


- (void)loadView
{
    if (!_sebWebView) {
        _sebWebView = [[SEBWebView alloc] initWithFrame:CGRectZero];
        _sebWebView.navigationDelegate = self;
        
        // Suppress right-click with own delegate method for context menu
        [_sebWebView setUIDelegate:self];
        
        // The Policy Delegate is needed to catch opening links in new windows
        [_sebWebView setPolicyDelegate:self];
        
        // The Frame Load Delegate is needed to monitor frame loads
        [_sebWebView setFrameLoadDelegate:self];
        
        // The Resource Load Delegate is needed to monitor the progress of loading individual resources
        [_sebWebView setResourceLoadDelegate:self];
        
        // Set group name to group related frames (so not to open several new windows)
        [_sebWebView setGroupName:@"SEBBrowserDocument"];

        // Close webView when the last document window is closed
        [_sebWebView setShouldCloseWithWindow:YES];
        
        [_sebWebView setContinuousSpellCheckingEnabled:self.navigationDelegate.allowSpellCheck];

        // Set bindings to web preferences
        WebPreferences *webPrefs = [WebPreferences standardPreferences];
    #ifndef __i386__        // Plugins can't be switched on in the 32-bit Intel build
        [webPrefs bind:@"plugInsEnabled"
              toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
           withKeyPath:@"values.org_safeexambrowser_SEB_enablePlugIns"
               options:nil];
    #endif
        [webPrefs bind:@"javaEnabled"
              toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
           withKeyPath:@"values.org_safeexambrowser_SEB_enableJava"
               options:nil];
        
        [webPrefs bind:@"javaScriptEnabled"
              toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
           withKeyPath:@"values.org_safeexambrowser_SEB_enableJavaScript"
               options:nil];

        NSDictionary *bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:@"NSNegateBoolean",NSValueTransformerNameBindingOption,nil];
        [webPrefs bind:@"javaScriptCanOpenWindowsAutomatically"
              toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
           withKeyPath:@"values.org_safeexambrowser_SEB_blockPopUpWindows"
               options:bindingOptions];
        
        WebCacheModel defaultWebCacheModel = [webPrefs cacheModel];
        DDLogDebug(@"Default WebPreferences cacheModel: %lu", defaultWebCacheModel);
        [webPrefs setCacheModel:WebCacheModelPrimaryWebBrowser];
        
        [webPrefs setWebAudioEnabled:YES];
        
        [_sebWebView setPreferences:webPrefs];
        
        // Create custom WebPreferences with bugfix for local storage not persisting application quit/start
        [self setCustomWebPreferencesForWebView:_sebWebView];
        
        if (self.navigationDelegate.isMainBrowserWebViewActive) {
            [_sebWebView bind:@"maintainsBackForwardList"
                      toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
                   withKeyPath:@"values.org_safeexambrowser_SEB_allowBrowsingBackForward"
                       options:nil];
        } else {
            [_sebWebView bind:@"maintainsBackForwardList"
                      toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
                   withKeyPath:@"values.org_safeexambrowser_SEB_newBrowserWindowNavigation"
                       options:nil];
        }
        
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        _allowDownloads = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDownUploads"];
        _allowDeveloperConsole = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDeveloperConsole"];

        urlFilter = [SEBURLFilter sharedSEBURLFilter];
        quitURLTrimmed = [[preferences secureStringForKey:@"org_safeexambrowser_SEB_quitURL"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        sendBrowserExamKey = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"];
        // Display all MIME types the WebView can display as HTML
        NSArray* MIMETypes = [WebView MIMETypesShownAsHTML];
        NSUInteger i, count = [MIMETypes count];
        for (i=0; i<count; i++) {
            DDLogDebug(@"MIME type shown as HTML: %@", [MIMETypes objectAtIndex:i]);
        }
    }
}


- (void)viewDidAppear {
    
    if (@available(macOS 10.10.3, *)) {
        
        NSPressureConfiguration* pressureConfiguration;
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDictionaryLookup"]) {
            pressureConfiguration = [[NSPressureConfiguration alloc]
                                     initWithPressureBehavior:NSPressureBehaviorPrimaryDefault];
        } else {
            pressureConfiguration = [[NSPressureConfiguration alloc]
                                     initWithPressureBehavior:NSPressureBehaviorPrimaryClick];
        }
        
        for (NSView *subview in [self.view subviews]) {
            if ([subview respondsToSelector:@selector(setPressureConfiguration:)]) {
                subview.pressureConfiguration = pressureConfiguration;
            }
        }
    }
}


// Create custom WebPreferences with bugfix for local storage not persisting application quit/start
- (void) setCustomWebPreferencesForWebView:(SEBWebView *)webView
{
    // Set browser user agent according to settings
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString* versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
    NSString *overrideUserAgent;
    NSString *browserUserAgentSuffix = [[preferences secureStringForKey:@"org_safeexambrowser_SEB_browserUserAgent"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (browserUserAgentSuffix.length != 0) {
        browserUserAgentSuffix = [NSString stringWithFormat:@" %@", browserUserAgentSuffix];
    }
    if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserUserAgentMac"] == browserUserAgentModeMacDefault) {
        overrideUserAgent = [[MyGlobals sharedMyGlobals] valueForKey:@"defaultUserAgent"];
    } else {
        overrideUserAgent = [preferences secureStringForKey:@"org_safeexambrowser_SEB_browserUserAgentMacCustom"];
    }
    // Add "SEB <version number>" to the browser's user agent, so the LMS SEB plugins recognize us
    overrideUserAgent = [overrideUserAgent stringByAppendingString:[NSString stringWithFormat:@" %@/%@%@", SEBUserAgentDefaultSuffix, versionString, browserUserAgentSuffix]];
    [webView setCustomUserAgent:overrideUserAgent];
    
    WebPreferences* prefs = [webView preferences];

    DDLogDebug(@"Testing if WebStorageManager respondsToSelector:@selector(_storageDirectoryPath)");
    if ([WebStorageManager respondsToSelector: @selector(_storageDirectoryPath)]) {
        NSString* dbPath = [WebStorageManager _storageDirectoryPath];
        if (![prefs respondsToSelector:@selector(_localStorageDatabasePath)]) {
            DDLogError(@"WebPreferences did not respond to selector _localStorageDatabasePath. Local Storage won't be available!");
            return;
        }
        NSString* localDBPath = [prefs _localStorageDatabasePath];
        [prefs setAutosaves:YES];  //SET PREFS AUTOSAVE FIRST otherwise settings aren't saved.
        [prefs setWebGLEnabled:YES];
        
        // Check if paths match and if not, create a new local storage database file
        // (otherwise localstorage file is erased when starting program)
        // Thanks to Derek Wade!
        if ([localDBPath isEqualToString:dbPath] == NO) {
            // Define application cache quota
            static const unsigned long long defaultTotalQuota = 10 * 1024 * 1024; // 10MB
            static const unsigned long long defaultOriginQuota = 5 * 1024 * 1024; // 5MB
            [prefs setApplicationCacheTotalQuota:defaultTotalQuota];
            [prefs setApplicationCacheDefaultOriginQuota:defaultOriginQuota];
            
            [prefs setOfflineWebApplicationCacheEnabled:YES];
            
            [prefs setDatabasesEnabled:YES];
            [prefs _setLocalStorageDatabasePath:dbPath];
            [prefs setLocalStorageEnabled:YES];
        } else {
            [prefs setLocalStorageEnabled:YES];
        }
    } else {
        DDLogError(@"WebStorageManager did not respond to selector _storageDirectoryPath. Local Storage won't be available!");
    }
    [prefs setDeveloperExtrasEnabled:[preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDeveloperConsole"]];

    [webView setPreferences:prefs];

}


- (BOOL)canGoBack
{
    return _sebWebView.canGoBack;
}

- (BOOL)canGoForward
{
    return _sebWebView.canGoForward;
}

- (void)goBack
{
    [_sebWebView goBack];
}

- (void)goForward
{
    [_sebWebView goForward];
}

- (void)reload
{
    [_sebWebView.mainFrame reload];
}

- (void)loadURL:(nonnull NSURL *)url
{
    [_sebWebView.mainFrame loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)stopLoading
{
    [_sebWebView.mainFrame stopLoading];
}

- (void) zoomPageIn
{
    SEL selector = NSSelectorFromString(@"zoomPageIn:");
    [[NSApplication sharedApplication] sendAction:selector to:_sebWebView from:self];
}

- (void) zoomPageOut
{
    SEL selector = NSSelectorFromString(@"zoomPageOut:");
    [[NSApplication sharedApplication] sendAction:selector to:_sebWebView from:self];
}

- (void) zoomPageReset
{
    SEL selector = NSSelectorFromString(@"zoomPageStandard:");
    [[NSApplication sharedApplication] sendAction:selector to:_sebWebView from:self];
}

- (void) textSizeIncrease
{
    [_sebWebView makeTextLarger:self];
}

- (void) textSizeDecrease
{
    [_sebWebView makeTextSmaller:self];
}

- (void) textSizeReset
{
    [_sebWebView makeTextStandardSize:self];
}


- (void) privateCopy:(id)sender
{
    [_sebWebView privateCopy:sender];
}

- (void) privateCut:(id)sender
{
    [_sebWebView privateCut:sender];
}

- (void) privatePaste:(id)sender
{
    [_sebWebView privatePaste:sender];
}


- (nonnull id)nativeWebView
{
    return _sebWebView;
}

- (nullable NSString *)pageTitle
{
    return _sebWebView.mainFrameTitle;
}

- (nullable NSURL *)url
{
    return [NSURL URLWithString:_sebWebView.mainFrameURL];
}


- (void)setPrivateClipboardEnabled:(BOOL)privateClipboardEnabled
{
    _privateClipboardEnabled = privateClipboardEnabled;
}

- (void)setAllowDictionaryLookup:(BOOL)allowDictionaryLookup
{
    _allowDictionaryLookup = allowDictionaryLookup;
}

- (void)setAllowPDFPlugIn:(BOOL)allowPDFPlugIn
{
    _allowPDFPlugIn = allowPDFPlugIn;
}


- (void) disableFlashFullscreen
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL allowSwitchToThirdPartyApps = ![preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    DDLogInfo(@"currentSystemPresentationOptions changed!");
    // If plugins are enabled and there is a Flash view in the webview ...
    if ([[self.sebWebView preferences] arePlugInsEnabled]) {
        NSView* flashView = [self findFlashViewInView:self.sebWebView];
        if (flashView) {
            if (!allowSwitchToThirdPartyApps || ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowFlashFullscreen"]) {
                // and either third party Apps or Flash fullscreen is allowed
                //... then we switch plugins off and on again to prevent
                //the security risk Flash full screen video
                [[self.sebWebView preferences] setPlugInsEnabled:NO];
                [[self.sebWebView preferences] setPlugInsEnabled:YES];
            } else {
                //or we set the flag that Flash tried to switch presentation options
                [[MyGlobals sharedMyGlobals] setFlashChangedPresentationOptions:YES];
            }
        }
    }
}

- (NSView*)findFlashViewInView:(NSView*)view
{
    NSString* className = [view className];
    
    // WebHostedNetscapePluginView showed up in Safari 4.x,
    // WebNetscapePluginDocumentView is Safari 3.x.
    if ([className isEqual:@"WebHostedNetscapePluginView"] ||
        [className isEqual:@"WebNetscapePluginDocumentView"])
    {
        // Do any checks to make sure you've got the right player
        return view;
    }
    
    // Okay, this view isn't a plugin, keep going
    for (NSView* subview in [view subviews])
    {
        NSView* result = [self findFlashViewInView:subview];
        if (result) return result;
    }
    
    return nil;
}


#pragma mark SEBAbstractWebViewNavigationDelegate Methods

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

- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
{
    return [self.navigationDelegate openNewTabWithURL:url];
}

- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies
{
    [self.navigationDelegate examineCookies:cookies];
}

- (BOOL) allowSpellCheck
{
    return self.navigationDelegate.allowSpellCheck;
}


- (NSString *)currentMainHost
{
    if (_currentWebViewMainHost) {
        return _currentWebViewMainHost;
    } else {
        return self.navigationDelegate.currentMainHost;
    }
}

- (void)setCurrentMainHost:(NSString *)currentMainHost
{
    _currentWebViewMainHost = currentMainHost;
    self.navigationDelegate.currentMainHost = currentMainHost;
}


- (void) storePasteboard
{
    [self.navigationDelegate storePasteboard];
}

- (void) restorePasteboard
{
    [self.navigationDelegate restorePasteboard];
}


#pragma mark WebView Delegates

#pragma mark WebUIDelegates

// Handling of requests to open a link in a new window from Javascript (and plugins)
- (SEBWebView *)webView:(SEBWebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    // Multiple browser windows
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    newBrowserWindowPolicies newBrowserWindowPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"];
    if (newBrowserWindowPolicy != getGenerallyBlocked) {
        NSApplicationPresentationOptions presentationOptions = [NSApp currentSystemPresentationOptions];
        DDLogDebug(@"Current System Presentation Options: %lx",(long)presentationOptions);
        DDLogDebug(@"Saved System Presentation Options: %lx",(long)[[MyGlobals sharedMyGlobals] presentationOptions]);
        if ((presentationOptions != [[MyGlobals sharedMyGlobals] presentationOptions]) || ([[MyGlobals sharedMyGlobals] flashChangedPresentationOptions])) {
            // request to open link in new window came from the flash plugin context menu while playing video in full screen mode
            DDLogDebug(@"Cancel opening link from Flash plugin context menu");
            return nil; // cancel opening link
        }
        if (newBrowserWindowPolicy == openInNewWindow) {
            SEBAbstractWebView *newWindowAbstractWebView = [self.navigationDelegate openNewWebViewWindowWithURL:request.URL];
            newWindowAbstractWebView.creatingWebView = self.navigationDelegate.abstractWebView;
            SEBWebView *newWindowWebView = newWindowAbstractWebView.nativeWebView;
            DDLogDebug(@"Now opening new document browser window. %@", newWindowWebView);
            DDLogDebug(@"Reqested from %@",sender);
            return newWindowWebView;
        }
        return nil;
    } else {
        return nil;
    }
}


// Show new window containing webView
- (void)webViewShow:(SEBWebView *)sender
{
    [self.navigationDelegate showWebView:self.navigationDelegate.abstractWebView];
}


/*
 - (void)orderOut:(id)sender {
 //we prevent the browser window to be hidden
 }
 */


// Downloading and Uploading of Files //

- (void)webView:(SEBWebView *)sender runOpenPanelForFileButtonWithResultListener:(id < WebOpenPanelResultListener >)resultListener allowMultipleFiles:(BOOL)allowMultipleFiles;
// Choose file for upload
{
    if (_allowDownloads == YES) {
        void (^completionHandler)(NSArray<NSURL *> *URLs) = ^void (NSArray<NSURL *> *URLs) {
            NSMutableArray *filenames = [NSMutableArray new];
            for (NSURL *fileURL in URLs) {
                [filenames addObject:fileURL.path];
            }
            [resultListener chooseFilenames:filenames.copy];
        };
        [self.navigationDelegate webView:nil runOpenPanelWithParameters:[NSNumber numberWithBool:allowMultipleFiles] initiatedByFrame:nil completionHandler:completionHandler];
    }
}


// Delegate method for disabling right-click context menu
- (NSArray *)webView:(SEBWebView *)sender contextMenuItemsForElement:(NSDictionary *)element
    defaultMenuItems:(NSArray *)defaultMenuItems {
    
    if (_allowDeveloperConsole) {
            for (NSMenuItem *menuItem in defaultMenuItems) {
                // If "Inspect Element" is being offered for the current element
                if (menuItem.tag == 2024) {
                    //... we pass it as an item to the context menu
                    // unfortunately the menu always contains the "Services" submenu
                    // that's why it should be completely disabled when not using the dev console
                    return [NSArray arrayWithObject:menuItem];
                }
            }
    }
    // Disable right-click context menu completely
    return [NSArray array];
}


// Delegate method for JavaScript alert panel
- (void)webView:(SEBWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WebFrame *)frame
{
    NSString *pageTitle = [sender stringByEvaluatingJavaScriptFromString:@"document.title"];
    [self.navigationDelegate pageTitle:pageTitle runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame];
}


// Delegate method for JavaScript confirmation panel
- (BOOL)webView:(SEBWebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WebFrame *)frame
{
    NSString *pageTitle = [sender stringByEvaluatingJavaScriptFromString:@"document.title"];
    return [self.navigationDelegate pageTitle:pageTitle runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame];
}


- (NSString *)webView:(WebView *)sender
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
          defaultText:(NSString *)defaultText
     initiatedByFrame:(WebFrame *)frame
{
    NSString *pageTitle = [sender stringByEvaluatingJavaScriptFromString:@"document.title"];
    return [self.navigationDelegate pageTitle:pageTitle runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame];
}


- (void)webView:(WebView *)sender frame:(WebFrame *)frame exceededDatabaseQuotaForSecurityOrigin:(id)origin database:(NSString *)databaseIdentifier
{
    static const unsigned long long defaultQuota = 5 * 1024 * 1024;
    SEL selector = NSSelectorFromString(@"setQuota:");
    if ([origin respondsToSelector:selector]) {
        IMP imp = [origin methodForSelector:selector];
        void (*func)(id, SEL, NSNumber *) = (void *)imp;
        func(origin, selector, [NSNumber numberWithLongLong: defaultQuota]);

    } else {
        DDLogError(@"Could not increase quota to %llu bytes for database %@", defaultQuota, databaseIdentifier);
    }
}


#pragma mark WebFrameLoadDelegates

// Get the URL of the page being loaded
// Invoked when a page load is in progress in a given frame
- (void)webView:(SEBWebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    DDLogInfo(@"didStartProvisionalLoadForFrame request URL: %@", [[[[frame provisionalDataSource] request] URL] absoluteString]);
    
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]){
        self.currentMainHost = [[[[frame provisionalDataSource] request] URL] host];
        //reset the flag for presentation option changes by flash
        [[MyGlobals sharedMyGlobals] setFlashChangedPresentationOptions:NO];
        
        [self.navigationDelegate sebWebViewDidStartLoad];
    }
}


// Invoked when a page load completes
- (void)webView:(SEBWebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    if (frame == [sender mainFrame]){
        [self.navigationDelegate setCanGoBack:sender.canGoBack canGoForward:sender.canGoForward];
        
        [self.navigationDelegate sebWebViewDidFinishLoad];
    }
}


// Invoked when a client redirect is cancelled
- (void)webView:(SEBWebView *)sender didCancelClientRedirectForFrame:(WebFrame *)frame
{
    DDLogInfo(@"webView: %@ didCancelClientRedirectForFrame: %@", sender, frame);
}


// Invoked when a frame receives a client redirect and before it is fired
- (void)webView:(SEBWebView *)sender
willPerformClientRedirectToURL:(NSURL *)URL
          delay:(NSTimeInterval)seconds
       fireDate:(NSDate *)date
       forFrame:(WebFrame *)frame
{
    DDLogInfo(@"willPerformClientRedirectToURL: %@", URL);
}


// Update the URL of the current page in case of a server redirect
- (void)webView:(SEBWebView *)sender didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame
{
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]){
        self.currentMainHost = [[[[frame provisionalDataSource] request] URL] host];
        //reset the flag for presentation option changes by flash
        [[MyGlobals sharedMyGlobals] setFlashChangedPresentationOptions:NO];
    }
}


- (void)webView:(SEBWebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
    // Report feedback only for the main frame.
    if (frame == [sender mainFrame]){
        NSString* versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
        NSString* appTitleString = [NSString stringWithFormat:@"Safe Exam Browser %@  —  %@",
                                    versionString,
                                    title];
        CGFloat windowWidth = [NSWindow minFrameWidthWithTitle:appTitleString styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask];
        if (windowWidth > [[sender window] frame].size.width) {
            appTitleString = [NSString stringWithFormat:@"SEB %@  —  %@",
                                        [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"],
                                        title];
        }
        DDLogInfo(@"BrowserWindow %@: Title of current Page: %@", self, appTitleString);
        [self.navigationDelegate sebWebViewDidUpdateTitle:title];
    }
}


/// Handle WebView load errors

// Invoked if an error occurs when starting to load data for a page
- (void)webView:(SEBWebView *)sender didFailProvisionalLoadWithError:(NSError *)error
       forFrame:(WebFrame *)frame
{
    DDLogError(@"%s: %@ error: %@ forFrame: %@", __FUNCTION__, sender, error, frame);
    // Process/show error only if load of the main frame failed
    if (frame == [sender mainFrame]) {
        [self.navigationDelegate sebWebViewDidFailLoadWithError:error];
    }
}


// Invoked when an error occurs loading a committed data source
- (void)webView:(SEBWebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    DDLogError(@"%s: %@ error: %@ forFrame: %@", __FUNCTION__, sender, error, frame);
    // Process/show error only if load of the main frame failed
    if (frame == [sender mainFrame]) {
        [self.navigationDelegate sebWebViewDidFailLoadWithError:error];
    }
}


// Invoked when the JavaScript window object in a frame is ready for loading
- (void)webView:(SEBWebView *)sender didClearWindowObject:(WebScriptObject *)windowObject
       forFrame:(WebFrame *)frame
{
    DDLogDebug(@"webView: %@ didClearWindowObject: %@ forFrame: %@", sender, windowObject, frame);
}


#pragma mark WebResourceLoadDelegate Protocol

// Generate and send the Browser Exam Key in modified header
// Invoked before a request is initiated for a resource and returns a possibly modified request
- (NSURLRequest *)webView:(SEBWebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
    NSString *absoluteRequestURL = [[request URL] absoluteString];
    
    // Trim a possible trailing slash "/"
    NSString *absoluteRequestURLTrimmed = [absoluteRequestURL stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];

    // Check if quit URL has been clicked (regardless of current URL Filter)
    if ([absoluteRequestURLTrimmed isEqualTo:quitURLTrimmed]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"quitLinkDetected" object:self];
        return request;
    }
    
    //// If enabled, filter content
    if (urlFilter.enableURLFilter &&
        urlFilter.enableContentFilter &&
        !self.navigationDelegate.downloadingInTemporaryWebView) {
        URLFilterRuleActions filterActionResponse = [urlFilter testURLAllowed:request.URL];
        if (filterActionResponse != URLFilterActionAllow) {
            /// Content is not allowed: Show teach URL alert if activated or just indicate URL is blocked filterActionResponse == URLFilterActionBlock ||
            if (@available(macOS 11, *)) {
                if (urlFilter.learningMode && !urlFilterContentLearningAlertDisplayed) {
                    if ([urlFilter testURLIgnored:request.URL] == NO) {
                        urlFilterContentLearningAlertDisplayed = YES;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self stopLoading];
                            [self.navigationDelegate showURLFilterAlertForRequest:request forContentFilter:YES filterResponse:filterActionResponse];
                            self->urlFilterContentLearningAlertDisplayed = NO;
                            [self reload];
                        });
                    }
                }
                DDLogVerbose(@"This content was blocked by the content filter: %@", request.URL.absoluteString);
                // Return nil instead of request
                return nil;
            } else {
                if (![self.navigationDelegate showURLFilterAlertForRequest:request forContentFilter:YES filterResponse:filterActionResponse]) {
                    /// User didn't allow the content, don't load it
                    DDLogWarn(@"This content was blocked by the content filter: %@", request.URL.absoluteString);
                    // Return nil instead of request
                    return nil;
                }
            }
        }
    }

    if (sendBrowserExamKey) {
        NSMutableURLRequest *modifiedRequest = [request mutableCopy];
        // Browser Exam Key
        [modifiedRequest setValue:[self.navigationDelegate browserExamKeyForURL:request.URL] forHTTPHeaderField:SEBBrowserExamKeyHeaderKey];
        // Config Key
        [modifiedRequest setValue:[self.navigationDelegate configKeyForURL:request.URL] forHTTPHeaderField:SEBConfigKeyHeaderKey];
        return modifiedRequest;
    } else {
        return request;
    }
}


// Invoked when a resource failed to load
- (void)webView:(SEBWebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error
 fromDataSource:(WebDataSource *)dataSource
{
    DDLogError(@"webView: %@ resource: %@ didFailLoadingWithError: %@ fromDataSource URL: %@", sender, identifier, error.description, dataSource.unreachableURL);

    // Close a temporary browser window which might have been opened for loading a config file from a SEB URL
//    [_browserController openingConfigURLFailed];
}


// Invoked when a plug-in fails to load
- (void)webView:(SEBWebView *)sender plugInFailedWithError:(NSError *)error
     dataSource:(WebDataSource *)dataSource
{
    DDLogError(@"webView: %@ plugInFailedWithError: %@ dataSource: %@", sender, error.description, dataSource);
}


// Invoked when an authentication challenge has been received for a resource
- (void)webView:(SEBWebView *)sender
       resource:(id)identifier
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
 fromDataSource:(WebDataSource *)dataSource
{
    DDLogInfo(@"webView: %@ resource: %@ didReceiveAuthenticationChallenge: %@ fromDataSource: %@", sender, identifier, challenge, dataSource);

    self.pendingChallenge = challenge;

    void (^completionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential) = ^void(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential) {
        switch (disposition) {
            case NSURLSessionAuthChallengeUseCredential:
                [self.pendingChallenge.sender useCredential:credential forAuthenticationChallenge:self.pendingChallenge];
                self.pendingChallenge = nil;
                break;
                
            case NSURLSessionAuthChallengeCancelAuthenticationChallenge:
            {
                if (self.pendingChallenge == challenge) {
                    DDLogDebug(@"_pendingChallenge is same as current challenge");
                } else {
                    DDLogDebug(@"_pendingChallenge is not same as current challenge");
                }
                [challenge.sender cancelAuthenticationChallenge:challenge];
                self.pendingChallenge = nil;
                break;
            }
                
            case NSURLSessionAuthChallengePerformDefaultHandling:
                [self.pendingChallenge.sender useCredential:credential forAuthenticationChallenge:self.pendingChallenge];
                self.pendingChallenge = nil;
                break;
                
            default:
                [self.pendingChallenge.sender useCredential:credential forAuthenticationChallenge:self.pendingChallenge];
                self.pendingChallenge = nil;
                break;
        }
    };

    [self.navigationDelegate webView:nil didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
}


// Invoked when an authentication challenge for a resource was canceled
- (void)webView:(SEBWebView *)sender
       resource:(id)identifier
didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
 fromDataSource:(WebDataSource *)dataSource
{
    DDLogInfo(@"webView: %@ resource: %@ didCancelAuthenticationChallenge: %@ fromDataSource: %@", sender, identifier, challenge, dataSource);
//    [_browserController hideEnterUsernamePasswordDialog];
}


// Helper method to extract a filename from an anchor element with a "download" attribute
- (NSString *) getFilenameFromHTMLAnchorElement:(DOMHTMLAnchorElement *)parentNode
{
    NSString *filename;
    if ([parentNode respondsToSelector:@selector(outerHTML)]) {
#ifdef DEBUG
        DDLogDebug(@"NSString *parentOuterHTML = parentNode.outerHTML;");
#endif
        NSString *parentOuterHTML = parentNode.outerHTML;
#ifdef DEBUG
        DDLogDebug(@"Successfully got parentNode.outerHTML");
#endif
        NSRange rangeOfDownloadAttribute = [parentOuterHTML rangeOfString:@" download='"];
        if (rangeOfDownloadAttribute.location != NSNotFound) {
            filename = [parentOuterHTML substringFromIndex:rangeOfDownloadAttribute.location + rangeOfDownloadAttribute.length];
            filename = [filename substringToIndex:[filename rangeOfString:@"'"].location];
        } else {
            rangeOfDownloadAttribute = [parentOuterHTML rangeOfString:@" download=\""];
            if (rangeOfDownloadAttribute.location != NSNotFound) {
                filename = [parentOuterHTML substringFromIndex:rangeOfDownloadAttribute.location + rangeOfDownloadAttribute.length];
                filename = [filename substringToIndex:[filename rangeOfString:@"\""].location];
            }
        }
    }
    return filename;
}


- (SEBWKNavigationAction *) navigationActionForActionInformation:(NSDictionary *)actionInformation
{
    WebNavigationType navigationType = [[actionInformation objectForKey:@"WebActionNavigationTypeKey"] intValue];

    SEBWKNavigationAction *navigationAction = [SEBWKNavigationAction new];
    switch (navigationType) {
        case WebNavigationTypeFormSubmitted:
            navigationAction.writableNavigationType = WKNavigationTypeFormSubmitted;
            break;
            
        case WebNavigationTypeLinkClicked:
            navigationAction.writableNavigationType = WKNavigationTypeLinkActivated;
            break;
            
        case WebNavigationTypeBackForward:
            navigationAction.writableNavigationType = WKNavigationTypeBackForward;
            break;
            
        case WebNavigationTypeReload:
            navigationAction.writableNavigationType = WKNavigationTypeReload;
            break;
            
        case WebNavigationTypeFormResubmitted:
            navigationAction.writableNavigationType = WKNavigationTypeFormResubmitted;
            break;
            
        case WebNavigationTypeOther:
            navigationAction.writableNavigationType = WKNavigationTypeOther;
            break;
            
        default:
            break;
    }
    return navigationAction;
}


// Opening Links in New Windows //
// Handling of requests from JavaScript and web plugins to open a link in a new window
- (void)webView:(SEBWebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
decisionListener:(id <WebPolicyDecisionListener>)listener {

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    newBrowserWindowPolicies newBrowserWindowPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"];
    DDLogDebug(@"decidePolicyForNavigationAction request URL: %@", [[request URL] absoluteString]);
    //NSString *requestedHost = [[request mainDocumentURL] host];
    
    SEBWKNavigationAction *navigationAction = [self navigationActionForActionInformation:actionInformation];
    navigationAction.writableRequest = request;
    
    // When downloading is allowed, check for the "download" attribute on an anchor
#ifdef DEBUG
    DDLogDebug(@"%s: Downloading allowed: %hhd", __FUNCTION__, _allowDownloads);
#endif
    if (_allowDownloads) {
        // Get the DOMNode from the information about the action that triggered the navigation request
        self.downloadFilename = nil;
        NSDictionary *webElementDict = [actionInformation valueForKey:@"WebActionElementKey"];
        if (webElementDict) {
#ifdef DEBUG
            DDLogDebug(@"DOMNode *webElementDOMNode = [webElementDict valueForKey:@\"WebElementDOMNode\"];");
#endif
            DOMNode *webElementDOMNode = [webElementDict valueForKey:@"WebElementDOMNode"];
#ifdef DEBUG
            DDLogDebug(@"Successfully got webElementDOMNode");
#endif

            // Do we have a parentNode?
            if ([webElementDOMNode respondsToSelector:@selector(parentNode)]) {
                
                // Is the parent an anchor?
#ifdef DEBUG
                DDLogDebug(@"DOMHTMLAnchorElement *parentNode = (DOMHTMLAnchorElement *)webElementDOMNode.parentNode;");
#endif
                DOMHTMLAnchorElement *parentNode = (DOMHTMLAnchorElement *)webElementDOMNode.parentNode;
#ifdef DEBUG
                DDLogDebug(@"Successfully got webElementDOMNode.parentNode");
#endif
                if ([parentNode respondsToSelector:@selector(nodeName)]) {
#ifdef DEBUG
                    DDLogDebug(@"if ([parentNode.nodeName isEqualToString:@\"A\"]) {");
#endif
                    if ([parentNode.nodeName isEqualToString:@"A"]) {
#ifdef DEBUG
                        DDLogDebug(@"Successfully compared parentNode.nodeName to A");
#endif
                        self.downloadFilename = [self getFilenameFromHTMLAnchorElement:parentNode];
                    }
                }
                
                // Check if one of the children of the parent node is an anchor
                if ([parentNode respondsToSelector:@selector(children)]) {
                    // We had to check if we get children, bad formatted HTML and
                    // older WebKit versions would throw an exception here
#ifdef DEBUG
                    DDLogDebug(@"DOMHTMLCollection *childrenNodes = parentNode.children;");
#endif
                    DOMHTMLCollection *childrenNodes = parentNode.children;
#ifdef DEBUG
                    DDLogDebug(@"Successfully got childrenNodes = parentNode.children");
#endif
                    uint i;
                    for (i = 0; i < childrenNodes.length; i++) {
#ifdef DEBUG
                        DDLogDebug(@"DOMHTMLAnchorElement *childNode = (DOMHTMLAnchorElement *)[childrenNodes item:i];");
#endif
                        DOMHTMLAnchorElement *childNode = (DOMHTMLAnchorElement *)[childrenNodes item:i];
#ifdef DEBUG
                        DDLogDebug(@"Successfully got childNode");
#endif
                        if ([childNode respondsToSelector:@selector(nodeName)]) {
#ifdef DEBUG
                            DDLogDebug(@"if ([childNode.nodeName isEqualToString:@\"A\"]) {");
#endif
                            if ([childNode.nodeName isEqualToString:@"A"]) {
#ifdef DEBUG
                                DDLogDebug(@"Successfully got childNode.nodeName");
#endif
                                self.downloadFilename = [self getFilenameFromHTMLAnchorElement:childNode];
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    
    SEBNavigationActionPolicy delegateNavigationActionPolicy = [self.navigationDelegate decidePolicyForNavigationAction:navigationAction newTab:NO];
    if (delegateNavigationActionPolicy != SEBNavigationResponsePolicyAllow) {
        // If the URL filter is enabled, we might need to close a temporary window
        if (urlFilter.enableURLFilter && ![self.navigationDelegate downloadingInTemporaryWebView]) {
            // URL filter enabled and the request which was supposed to be opened in a new window was blocked
            // a temporary webview or a new browser window might have to be closed
            SEBAbstractWebView *creatingWebView = self.navigationDelegate.abstractWebView.creatingWebView;
            if (creatingWebView) {
                if (newBrowserWindowPolicy == openInNewWindow) {
                    // We have to close the new browser window which already has been opened by WebKit
                    // Get the document for my web view
                    DDLogDebug(@"Originating browser window %@", sender);
                    // Close document and therefore also window
                    //Workaround: Flash crashes after closing window and then clicking some other link
                    [[sender preferences] setPlugInsEnabled:NO];
                    DDLogDebug(@"newBrowserWindowPolicy == openInNewWindow: closing new document browser window for: %@", self.sebWebView);
                    [self.navigationDelegate closeWebView];
                } else if (newBrowserWindowPolicy == openInSameWindow) {
                    if (self.sebWebView) {
                        DDLogDebug(@"newBrowserWindowPolicy == openInSameWindow: closing the temporary WebView: %@", self.sebWebView);
                        [sender close]; //close the temporary webview
                    }
                }
            }
        }
        // Don't load the request
        [listener ignore];
        return;
    }
    [listener use];
}


// Open the link requesting to be opened in a new window according to settings
- (void)webView:(SEBWebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
   newFrameName:(NSString *)frameName
decisionListener:(id <WebPolicyDecisionListener>)listener
{
    SEBWKNavigationAction *navigationAction = [self navigationActionForActionInformation:actionInformation];
    navigationAction.writableRequest = request;

    [self.navigationDelegate decidePolicyForNavigationAction:navigationAction newTab:YES];

    [listener ignore];
}


#pragma mark WebPolicyDelegates
#pragma mark Downloading

- (void)webView:(SEBWebView *)sender decidePolicyForMIMEType:(NSString*)type
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
decisionListener:(id < WebPolicyDecisionListener >)listener
{
    DDLogDebug(@"decidePolicyForMIMEType: %@ requestURL: %@", type, request.URL.absoluteString);
    
    // Check if this link had the "download" attribute, then we download the linked resource and don't try to display it
    if (self.downloadFilename) {
        DDLogInfo(@"Link to resource %@ had the 'download' attribute, force download it.", request.URL.absoluteString);
        [listener download];
        [self.navigationDelegate downloadFileFromURL:request.URL filename:self.downloadFilename cookies:@[]];
        self.downloadFilename = nil;
        return;
    }

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    newBrowserWindowPolicies newBrowserWindowPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"];

    // Check if it is a data: scheme to support the W3C saveAs() FileSaver interface
    if ([request.URL.scheme isEqualToString:@"data"]) {
        CFStringRef mimeType = (__bridge CFStringRef)type;
        CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, NULL);
        CFStringRef extension = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
        NSString *downloadFileExtension = (__bridge NSString *)(extension);
        if (uti) CFRelease(uti);
        if (extension) CFRelease(extension);
        DDLogInfo(@"data: content MIME type to download is %@, the file extension will be %@", type, extension);
        [listener download];
        [self.navigationDelegate downloadFileFromURL:request.URL filename:[NSString stringWithFormat:@".%@", downloadFileExtension] cookies:@[]];
        
        // Close the temporary Window or WebView which has been opend by the data: download link
        SEBAbstractWebView *creatingWebView = self.navigationDelegate.abstractWebView.creatingWebView;
        if (creatingWebView) {
            if (newBrowserWindowPolicy == openInNewWindow) {
                // we have to close the new browser window which already has been opened by WebKit
                // Get the document for my web view
                DDLogDebug(@"Originating browser window %@", sender);
                // Close document and therefore also window
                //Workaround: Flash crashes after closing window and then clicking some other link
                [[self.sebWebView preferences] setPlugInsEnabled:NO];
                DDLogDebug(@"Now closing new document browser window for: %@", self.sebWebView);
                [self.navigationDelegate closeWebView];
            }
            if (newBrowserWindowPolicy == openInSameWindow) {
                if (self.sebWebView) {
                    [sender close]; //close the temporary webview
                }
            }
        }
        return;
    }
    
    SEBNavigationActionPolicy delegateNavigationActionPolicy = [self.navigationDelegate decidePolicyForMIMEType:type url:request.URL canShowMIMEType:[WebView canShowMIMEType:type] isForMainFrame:(frame == sender.mainFrame) suggestedFilename:self.downloadFilename cookies:@[]];
    if (delegateNavigationActionPolicy == SEBNavigationResponsePolicyAllow) {
        [listener use];
    } else {
        [listener ignore];
    }
}


- (void)webView:(SEBWebView *)sender unableToImplementPolicyWithError:(NSError *)error
          frame:(WebFrame *)frame
{
    DDLogError(@"webView: %@ unableToImplementPolicyWithError: %@ frame: %@", sender, error.description, frame);
}


@end
