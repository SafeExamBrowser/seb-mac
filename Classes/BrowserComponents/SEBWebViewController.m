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
#import "SEBAbstractClassicWebView.h"

@implementation SEBWebViewController


- (instancetype)initWithDelegate:(id <SEBAbstractWebViewNavigationDelegate>)delegate
{
    self = [super init];
    if (self) {
        _navigationDelegate = delegate;
    }
    return self;
}


- (SEBWebView *)sebWebView
{
    if (!_sebWebView) {
        _sebWebView = [[SEBWebView alloc] initWithFrame:CGRectZero delegate: self];
        
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

        [webPrefs bind:@"tabsToLinks"
              toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
           withKeyPath:@"values.org_safeexambrowser_SEB_tabFocusesLinks"
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
        
        if (self.navigationDelegate.isMainBrowserWebView) {
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
        _allowDownloads = self.navigationDelegate.allowDownUploads;
        _allowDeveloperConsole = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDeveloperConsole"];

        urlFilter = [SEBURLFilter sharedSEBURLFilter];
        quitURLTrimmed = [[preferences secureStringForKey:@"org_safeexambrowser_SEB_quitURL"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        sendBrowserExamKey = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"];
#ifdef DEBUG
        // Display all MIME types the WebView can display as HTML
        NSArray* MIMETypes = [WebView MIMETypesShownAsHTML];
        NSUInteger i, count = [MIMETypes count];
        for (i=0; i<count; i++) {
            DDLogVerbose(@"MIME type shown as HTML: %@", [MIMETypes objectAtIndex:i]);
        }
#endif
    }
    return _sebWebView;
}


- (void)loadView
{
    self.view = self.sebWebView;
}


- (void)viewDidAppear {
    
    if (@available(macOS 10.10.3, *)) {
        
        NSPressureConfiguration* pressureConfiguration;
        if (_allowDictionaryLookup) {
            pressureConfiguration = [[NSPressureConfiguration alloc]
                                     initWithPressureBehavior:NSPressureBehaviorPrimaryDefault];
        } else {
            pressureConfiguration = [[NSPressureConfiguration alloc]
                                     initWithPressureBehavior:NSPressureBehaviorPrimaryClick];
        }
        
        for (NSView *subview in [self.view subviews]) {
            if ([subview respondsToSelector:@selector(setPressureConfiguration:)]) {
                subview.pressureConfiguration = pressureConfiguration;
                DDLogVerbose(@"NSPressureConfiguration %@ set for subview %@", pressureConfiguration == NSPressureBehaviorPrimaryDefault ? @"NSPressureBehaviorPrimaryDefault" : @"NSPressureBehaviorPrimaryClick", subview);
            }
        }
    }
}


// Create custom WebPreferences with bugfix for local storage not persisting application quit/start
- (void) setCustomWebPreferencesForWebView:(SEBWebView *)webView
{
    // Set browser user agent according to settings
    NSString *overrideUserAgent = self.navigationDelegate.customSEBUserAgent;
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
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [prefs setDeveloperExtrasEnabled:[preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDeveloperConsole"]];

    [webView setPreferences:prefs];

}


- (BOOL)canGoBack
{
    return self.sebWebView.canGoBack;
}

- (BOOL)canGoForward
{
    return self.sebWebView.canGoForward;
}

- (void)goBack
{
    [self.sebWebView goBack];
}

- (void)goForward
{
    [self.sebWebView goForward];
}

- (void)reload
{
    [self.sebWebView.mainFrame reload];
}

- (void)loadURL:(nonnull NSURL *)url
{
    [self.sebWebView.mainFrame loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)stopLoading
{
    [self.sebWebView.mainFrame stopLoading];
}

- (void) zoomPageIn
{
    SEL selector = NSSelectorFromString(@"zoomPageIn:");
    [[NSApplication sharedApplication] sendAction:selector to:self.sebWebView from:self];
}

- (void) zoomPageOut
{
    SEL selector = NSSelectorFromString(@"zoomPageOut:");
    [[NSApplication sharedApplication] sendAction:selector to:self.sebWebView from:self];
}

- (void) zoomPageReset
{
    SEL selector = NSSelectorFromString(@"zoomPageStandard:");
    [[NSApplication sharedApplication] sendAction:selector to:self.sebWebView from:self];
}

- (void) textSizeIncrease
{
    [self.sebWebView makeTextLarger:self];
}

- (void) textSizeDecrease
{
    [self.sebWebView makeTextSmaller:self];
}

- (void) textSizeReset
{
    [self.sebWebView makeTextStandardSize:self];
}


- (NSString *) stringByEvaluatingJavaScriptFromString:(NSString *)js
{
    return [_sebWebView stringByEvaluatingJavaScriptFromString:js];
}


- (void) privateCopy:(id)sender
{
    [self.sebWebView privateCopy:sender];
}

- (void) privateCut:(id)sender
{
    [self.sebWebView privateCut:sender];
}

- (void) privatePaste:(id)sender
{
    [self.sebWebView privatePaste:sender];
}


- (nonnull id)nativeWebView
{
    return self.sebWebView;
}

- (nullable NSString *)pageTitle
{
    return self.sebWebView.mainFrameTitle;
}

- (nullable NSURL *)url
{
    return [NSURL URLWithString:self.sebWebView.mainFrameURL];
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

- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
{
    [self.navigationDelegate setCanGoBack:canGoBack canGoForward:canGoForward];
}

- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
                             configuration:(nullable WKWebViewConfiguration *)configuration
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
    DDLogDebug(@"%s request: %@, newBrowserWindowPolicy: %lu", __FUNCTION__, request, (unsigned long)newBrowserWindowPolicy);
    
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
            SEBWKNavigationAction *sebWKNavigationAction = [SEBWKNavigationAction new];
            sebWKNavigationAction.writableNavigationType = WKNavigationTypeLinkActivated;
            
            SEBNavigationAction *navigationAction = [self.navigationDelegate decidePolicyForNavigationAction:sebWKNavigationAction newTab:YES configuration:nil downloadFilename:self.downloadFilename];
            if (navigationAction.policy == SEBNavigationActionPolicyJSOpen) {
                SEBAbstractWebView *newAbstractWebView = navigationAction.openedWebView;
                DDLogInfo(@"Opening classic WebView after Javascript .open()");
                SEBAbstractClassicWebView <SEBAbstractBrowserControllerDelegate> *sebAbstractClassicWebView = [[SEBAbstractClassicWebView alloc] initWithDelegate:newAbstractWebView];
                newAbstractWebView.browserControllerDelegate = sebAbstractClassicWebView;
                [newAbstractWebView initGeneralProperties];
                return newAbstractWebView.nativeWebView;
            }
        }
        SEBWebView *tempWebView = [[SEBWebView alloc] init];
        DDLogDebug(@"Opened new temporary WebView: %@", tempWebView);
        DDLogDebug(@"Requested from %@ (self.sebWebView: %@)", sender, self.sebWebView);
        //create a new temporary, invisible WebView
        [tempWebView setPolicyDelegate:self];
        [tempWebView setUIDelegate:self];
        [tempWebView setFrameLoadDelegate:self];
        [tempWebView setGroupName:@"SEBBrowserDocument"];
        tempWebView.creatingWebView = self.sebWebView;
        return tempWebView;
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
    } else {
        [self.navigationDelegate showAlertNotAllowedDownUploading:YES];
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
    [self.navigationDelegate pageTitle:pageTitle runJavaScriptAlertPanelWithMessage:message];
}


// Delegate method for JavaScript confirmation panel
- (BOOL)webView:(SEBWebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WebFrame *)frame
{
    NSString *pageTitle = [sender stringByEvaluatingJavaScriptFromString:@"document.title"];
    return [self.navigationDelegate pageTitle:pageTitle runJavaScriptConfirmPanelWithMessage:message];
}


- (NSString *)webView:(WebView *)sender
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
          defaultText:(NSString *)defaultText
     initiatedByFrame:(WebFrame *)frame
{
    NSString *pageTitle = [sender stringByEvaluatingJavaScriptFromString:@"document.title"];
    return [self.navigationDelegate pageTitle:pageTitle runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText];
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
        [_sebWebView stringByEvaluatingJavaScriptFromString:self.navigationDelegate.pageJavaScript];
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
        DDLogInfo(@"Did receive title of current Page: %@", title);
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
    NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)redirectResponse;
    NSDictionary<NSString *,NSString *>*headerFields = httpURLResponse.allHeaderFields;
    if (headerFields) {
        [self.navigationDelegate examineHeaders:httpURLResponse.allHeaderFields forURL:httpURLResponse.URL];
    }

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


- (void)webView:(WebView *)sender
       resource:(id)identifier
didReceiveResponse:(NSURLResponse *)response
 fromDataSource:(WebDataSource *)dataSource
{
    NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
    [self.navigationDelegate examineHeaders:httpURLResponse.allHeaderFields forURL:httpURLResponse.URL];
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
    DDLogVerbose(@"[SEBWebViewController webView: %@ decidePolicyForNavigationAction request URL: %@ ...]", sender, [[request URL] absoluteString]);
    DDLogVerbose(@"self.sebWebView: %@", self.sebWebView);
    //NSString *requestedHost = [[request mainDocumentURL] host];
    
    SEBWKNavigationAction *navigationAction = [self navigationActionForActionInformation:actionInformation];
    navigationAction.writableRequest = request;
    if (request) {
        // When downloading is allowed, check for the "download" attribute on an anchor
    #ifdef DEBUG
        DDLogDebug(@"%s: Downloading allowed: %hhd", __FUNCTION__, _allowDownloads);
    #endif
        if (_allowDownloads || (request.URL.pathExtension && [request.URL.pathExtension caseInsensitiveCompare:filenameExtensionPDF] == NSOrderedSame)) {
            // Get the DOMNode from the information about the action that triggered the navigation request
            self.downloadFilename = nil;
            NSDictionary *webElementDict = [actionInformation valueForKey:@"WebActionElementKey"];
            if (webElementDict) {
    #ifdef DEBUG
                DDLogVerbose(@"DOMNode *webElementDOMNode = [webElementDict valueForKey:@\"WebElementDOMNode\"];");
    #endif
                DOMNode *webElementDOMNode = [webElementDict valueForKey:@"WebElementDOMNode"];
    #ifdef DEBUG
                DDLogVerbose(@"Successfully got webElementDOMNode");
    #endif

                // Do we have a parentNode?
                if ([webElementDOMNode respondsToSelector:@selector(parentNode)]) {
                    
                    // Is the parent an anchor?
    #ifdef DEBUG
                    DDLogVerbose(@"DOMHTMLAnchorElement *parentNode = (DOMHTMLAnchorElement *)webElementDOMNode.parentNode;");
    #endif
                    DOMHTMLAnchorElement *parentNode = (DOMHTMLAnchorElement *)webElementDOMNode.parentNode;
    #ifdef DEBUG
                    DDLogVerbose(@"Successfully got webElementDOMNode.parentNode");
    #endif
                    if ([parentNode respondsToSelector:@selector(nodeName)]) {
    #ifdef DEBUG
                        DDLogVerbose(@"if ([parentNode.nodeName isEqualToString:@\"A\"]) {");
    #endif
                        if ([parentNode.nodeName isEqualToString:@"A"]) {
    #ifdef DEBUG
                            DDLogVerbose(@"Successfully compared parentNode.nodeName to A");
    #endif
                            self.downloadFilename = [self getFilenameFromHTMLAnchorElement:parentNode];
                        }
                    }
                    
                    // Check if one of the children of the parent node is an anchor
                    if ([parentNode respondsToSelector:@selector(children)]) {
                        // We had to check if we get children, bad formatted HTML and
                        // older WebKit versions would throw an exception here
    #ifdef DEBUG
                        DDLogVerbose(@"DOMHTMLCollection *childrenNodes = parentNode.children;");
    #endif
                        DOMHTMLCollection *childrenNodes = parentNode.children;
    #ifdef DEBUG
                        DDLogVerbose(@"Successfully got childrenNodes = parentNode.children");
    #endif
                        uint i;
                        for (i = 0; i < childrenNodes.length; i++) {
    #ifdef DEBUG
                            DDLogVerbose(@"DOMHTMLAnchorElement *childNode = (DOMHTMLAnchorElement *)[childrenNodes item:i];");
    #endif
                            DOMHTMLAnchorElement *childNode = (DOMHTMLAnchorElement *)[childrenNodes item:i];
    #ifdef DEBUG
                            DDLogVerbose(@"Successfully got childNode");
    #endif
                            if ([childNode respondsToSelector:@selector(nodeName)]) {
    #ifdef DEBUG
                                DDLogVerbose(@"if ([childNode.nodeName isEqualToString:@\"A\"]) {");
    #endif
                                if ([childNode.nodeName isEqualToString:@"A"]) {
    #ifdef DEBUG
                                    DDLogVerbose(@"Successfully got childNode.nodeName");
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
        SEBNavigationActionPolicy delegateNavigationActionPolicy;
        SEBNavigationAction *delegateNavigationAction;
        if (!_allowDownloads && self.downloadFilename && (self.downloadFilename.pathExtension && [self.downloadFilename.pathExtension caseInsensitiveCompare:filenameExtensionPDF] == NSOrderedSame)) {
            delegateNavigationAction = [self.navigationDelegate decidePolicyForNavigationAction:navigationAction newTab:([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] != openInSameWindow) configuration:nil downloadFilename:self.downloadFilename];
            delegateNavigationActionPolicy = delegateNavigationAction.policy;
        } else {
            delegateNavigationAction = [self.navigationDelegate decidePolicyForNavigationAction:navigationAction newTab:NO configuration:nil downloadFilename:self.downloadFilename];
            delegateNavigationActionPolicy = delegateNavigationAction.policy;
        }
    #ifdef DEBUG
        DDLogDebug(@"%s: [self.navigationDelegate decidePolicyForNavigationAction:navigationAction newTab:NO] = (SEBNavigationActionPolicy) %lu", __FUNCTION__, (unsigned long)delegateNavigationActionPolicy);
    #endif
        if (delegateNavigationActionPolicy != SEBNavigationResponsePolicyAllow) {
            // If the URL filter is enabled, we might need to close a temporary window
            if (urlFilter.enableURLFilter && ![self.navigationDelegate downloadingInTemporaryWebView]) {
                // URL filter enabled and the request which was supposed to be opened in a new window was blocked
                // a temporary WebView might have to be closed
                SEBWebView *creatingWebView = self.sebWebView.creatingWebView;
                if (creatingWebView) {
                    DDLogDebug(@"Originating WebView %@ (creatingWebView: %@, self.sebWebView: %@)", sender, creatingWebView, self.sebWebView);
                    if (newBrowserWindowPolicy == openInNewWindow) {
                        // We have to close the temporary WebView, which we already opened
                        DDLogDebug(@"newBrowserWindowPolicy == openInNewWindow: closing the temporary WebView: %@", self.sebWebView);
                        [self.sebWebView close];
                    } else if (newBrowserWindowPolicy == openInSameWindow) {
                        if (self.sebWebView) {
                            DDLogDebug(@"newBrowserWindowPolicy == openInSameWindow: closing the sender WebView: %@", sender);
                            [sender close]; //close the temporary webview
                        }
                    }
                }
            }
            // Don't load the request
    #ifdef DEBUG
        DDLogDebug(@"%s: [listener ignore];", __FUNCTION__);
    #endif
            [listener ignore];
            return;
        } else {
            SEBWebView *creatingWebView = self.sebWebView.creatingWebView;
            DDLogVerbose(@"navigationDelegate decidePolicyForNavigationAction was Allow: sender WebView %@, creatingWebView property: %@, self.sebWebView: %@", sender, creatingWebView, self.sebWebView);
            
            // Check if the request's sender is different than the current webview (means the sender is the temporary webview)
            if (self.sebWebView && ![sender isEqual:self.sebWebView]) {
                // If the request's sender is the temporary webview
                
                if (sender.creatingWebView && newBrowserWindowPolicy == openInNewWindow) {
                    SEBAbstractWebView *newWindowAbstractWebView = [self.navigationDelegate openNewWebViewWindowWithURL:request.URL configuration:nil];
                    newWindowAbstractWebView.creatingWebView = self.navigationDelegate.abstractWebView;
                    DDLogDebug(@"Just opened new document browser window with SEBAbstractWebView %@", newWindowAbstractWebView);
                    [listener ignore];
                    [sender close]; //close the temporary webview
                    return;
                }
                
                if (sender.creatingWebView && newBrowserWindowPolicy == openInSameWindow) {
                    // If the request's sender is the temporary webview, then we have to load the request now in the current webview
                    [listener ignore]; // ignore listener
                    [[self.sebWebView mainFrame] loadRequest:request]; //load the new page in the same browser window
                    [sender close]; //close the temporary webview
                    return; //and return from here
                }
            }
        }
    }
#ifdef DEBUG
    DDLogDebug(@"%s: [listener use];", __FUNCTION__);
#endif
    [listener use];
}


// Open the link requesting to be opened in a new window according to settings
- (void)webView:(SEBWebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
   newFrameName:(NSString *)frameName
decisionListener:(id <WebPolicyDecisionListener>)listener
{
    DDLogDebug(@"%s", __FUNCTION__);

    SEBWKNavigationAction *navigationAction = [self navigationActionForActionInformation:actionInformation];
    navigationAction.writableRequest = request;

    [self.navigationDelegate decidePolicyForNavigationAction:navigationAction newTab:YES configuration:nil downloadFilename:self.downloadFilename];

    [listener ignore];
}


#pragma mark WebPolicyDelegates
#pragma mark Downloading

- (void)webView:(SEBWebView *)sender decidePolicyForMIMEType:(NSString*)type
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
decisionListener:(id < WebPolicyDecisionListener >)listener
{
    DDLogVerbose(@"[SEBWebViewController webView: %@ decidePolicyForMIMEType: %@ requestURL: %@ ...]", sender, type, request.URL.absoluteString);
    DDLogVerbose(@"SEBWebView.creatingWebView property: %@", sender.creatingWebView);
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // Check if this link had the "download" attribute, then we download the linked resource and don't try to display it
    if (self.downloadFilename) {
        BOOL isPDF = [self.downloadFilename.pathExtension caseInsensitiveCompare:filenameExtensionPDF] == NSOrderedSame;
        if ((isPDF && !_allowDownloads) == NO) {
            if (_allowDownloads) {
                DDLogInfo(@"Link to resource %@ had the 'download' attribute, force download it.", request.URL.absoluteString);
                [listener download];
                [self.navigationDelegate downloadFileFromURL:request.URL filename:self.downloadFilename cookies:@[]];
                self.downloadFilename = nil;
            } else {
                [listener ignore];
                [self.navigationDelegate showAlertNotAllowedDownUploading:NO];
            }
            return;
        }
    }

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
    
    SEBNavigationActionPolicy delegateNavigationActionPolicy = [self.navigationDelegate decidePolicyForMIMEType:type url:request.URL canShowMIMEType:[WebView canShowMIMEType:type] isForMainFrame:(frame == sender.mainFrame) suggestedFilename:self.downloadFilename cookies:NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies];
    if (delegateNavigationActionPolicy == SEBNavigationActionPolicyDownload) {
        DDLogInfo(@"Resource %@ will be downloaded.", request.URL.lastPathComponent);
        [listener download];
        [self.navigationDelegate downloadFileFromURL:request.URL filename:self.downloadFilename cookies:@[]];
    } else if (delegateNavigationActionPolicy == SEBNavigationResponsePolicyAllow) {
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
