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
    // Create a webview to fit underneath the navigation view (=fill the whole screen).
    CGRect webFrame = self.parentViewController.view.frame;
    if (!_sebWebView) {
        _sebWebView = [[SEBWebView alloc] initWithFrame:webFrame];
        _sebWebView.navigationDelegate = self;
    }
}


- (void)viewDidAppear {
    
    [super viewDidAppear];

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


- (instancetype)init
{
    self = [super init];
    if (self) {
        
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

        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        _allowDownloads = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDownUploads"];
        _allowDeveloperConsole = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDeveloperConsole"];

        urlFilter = [SEBURLFilter sharedSEBURLFilter];
        quitURLTrimmed = self.navigationDelegate.quitURL;
        sendBrowserExamKey = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"];
        // Display all MIME types the WebView can display as HTML
        NSArray* MIMETypes = [WebView MIMETypesShownAsHTML];
        NSUInteger i, count = [MIMETypes count];
        for (i=0; i<count; i++) {
            DDLogDebug(@"MIME type shown as HTML: %@", [MIMETypes objectAtIndex:i]);
        }
    }
    return self;
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
    [self.sebWebView.mainFrame loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)stopLoading
{
    [_sebWebView.mainFrame stopLoading];
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


#pragma mark SEBAbstractWebViewNavigationDelegate Methods

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




#pragma mark WebView Delegates

#pragma mark WebUIDelegates

// Handling of requests to open a link in a new window (including Javascript commands)
- (SEBWebView *)webView:(SEBWebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    // Single browser window: [[self.webView mainFrame] loadRequest:request];
    // Multiple browser windows
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] != getGenerallyBlocked) {
        NSApplicationPresentationOptions presentationOptions = [NSApp currentSystemPresentationOptions];
        DDLogDebug(@"Current System Presentation Options: %lx",(long)presentationOptions);
        DDLogDebug(@"Saved System Presentation Options: %lx",(long)[[MyGlobals sharedMyGlobals] presentationOptions]);
        if ((presentationOptions != [[MyGlobals sharedMyGlobals] presentationOptions]) || ([[MyGlobals sharedMyGlobals] flashChangedPresentationOptions])) {
            // request to open link in new window came from the flash plugin context menu while playing video in full screen mode
            DDLogDebug(@"Cancel opening link from Flash plugin context menu");
            return nil; // cancel opening link
        }
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInNewWindow) {
            SEBAbstractWebView *newWindowAbstractWebView = [self.navigationDelegate openNewWebViewWindow];
            newWindowAbstractWebView.creatingWebView = self.navigationDelegate.abstractWebView;
            SEBWebView *newWindowWebView = newWindowAbstractWebView.nativeWebView;
            DDLogDebug(@"Now opening new document browser window. %@", newWindowWebView);
            DDLogDebug(@"Reqested from %@",sender);
            //[[sender preferences] setPlugInsEnabled:NO];
            [[newWindowWebView mainFrame] loadRequest:request];
            return newWindowWebView;
        }
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInSameWindow) {
            SEBAbstractWebView *tempAbstractWebView = [SEBAbstractWebView new];
            SEBWebView *tempWebView = tempAbstractWebView.nativeWebView;
            //create a new temporary, invisible WebView
            [tempWebView setPolicyDelegate:self];
            [tempWebView setUIDelegate:self];
            [tempWebView setFrameLoadDelegate:self];
            [tempWebView setGroupName:@"SEBBrowserDocument"];
            tempAbstractWebView.creatingWebView = self.navigationDelegate.abstractWebView;
            return tempWebView;
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
            [resultListener chooseFilenames:URLs];
        };
        [self.navigationDelegate webView:nil runOpenPanelWithParameters:nil initiatedByFrame:nil completionHandler:completionHandler];
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
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *absoluteRequestURL = [[request URL] absoluteString];
    
    // Trim a possible trailing slash "/"
    NSString *absoluteRequestURLTrimmed = [absoluteRequestURL stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];

    // Check if quit URL has been clicked (regardless of current URL Filter)
    if ([absoluteRequestURLTrimmed isEqualTo:quitURLTrimmed]) {
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_quitURLConfirm"]) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"requestQuitWPwdNotification" object:self];
        } else {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"requestQuitNotification" object:self];
        }
        return request;
    }
    
    //// If enabled, filter content
    if (urlFilter.enableURLFilter &&
        urlFilter.enableContentFilter &&
        !self.navigationDelegate.downloadingInTemporaryWebView) {
        URLFilterRuleActions filterActionResponse = [urlFilter testURLAllowed:request.URL];
        if (filterActionResponse != URLFilterActionAllow) {
            /// Content is not allowed: Show teach URL alert if activated or just indicate URL is blocked filterActionResponse == URLFilterActionBlock ||
            if (![self.navigationDelegate showURLFilterAlertForRequest:request forContentFilter:YES filterResponse:filterActionResponse]) {
                /// User didn't allow the content, don't load it
                DDLogWarn(@"This content was blocked by the content filter: %@", request.URL.absoluteString);
                // Return nil instead of request
                return nil;
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

    [self.navigationDelegate didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
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

// Opening Links in New Windows //
// Handling of requests from JavaScript and web plugins to open a link in a new window
- (void)webView:(SEBWebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
decisionListener:(id <WebPolicyDecisionListener>)listener {

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    DDLogInfo(@"decidePolicyForNavigationAction request URL: %@", [[request URL] absoluteString]);
    //NSString *requestedHost = [[request mainDocumentURL] host];
    
    if (request) {
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
        
        // Check if quit URL has been clicked (regardless of current URL Filter)
        NSString *absoluteRequestURLTrimmed = [request.URL.absoluteString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        
        if ([absoluteRequestURLTrimmed isEqualTo:quitURLTrimmed]) {
            if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_quitURLConfirm"]) {
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"requestQuitWPwdNotification" object:self];
            } else {
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"requestQuitNotification" object:self];
            }
            [listener ignore];
            return;
        }
        
        // If enabled, filter URL
        SEBURLFilter *URLFilter = [SEBURLFilter sharedSEBURLFilter];
        if (URLFilter.enableURLFilter && ![self.navigationDelegate downloadingInTemporaryWebView]) {
            URLFilterRuleActions filterActionResponse = [URLFilter testURLAllowed:request.URL];
            if (filterActionResponse != URLFilterActionAllow) {
                
                //// URL is not allowed
                
                // If the learning mode is active, display according sheet and ask user if he wants to allow this URL
                // but only if we're dealing with a request in the main frame of the web page
                if (frame != sender.mainFrame) {
                    // Don't load the request
                    [listener ignore];
                    return;
                }
                // Show alert for URL is not allowed as sheet on the WebView's window
                if (![self.navigationDelegate showURLFilterAlertForRequest:request
                                           forContentFilter:NO
                                             filterResponse:filterActionResponse]) {
                    /// User didn't allow the URL
                    
                    // Check if the link was opened by a script and
                    // if a temporary webview or a new browser window should be closed therefore
                    // If the new page is supposed to open in a new browser window
                    SEBAbstractWebView *creatingWebView = self.navigationDelegate.abstractWebView.creatingWebView;
                    if (creatingWebView) {
                        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInNewWindow) {
                            // Don't load the request
                            //                    [listener ignore];
                            // we have to close the new browser window which already has been opened by WebKit
                            // Get the document for my web view
                            DDLogDebug(@"Originating browser window %@", sender);
                            // Close document and therefore also window
                            //Workaround: Flash crashes after closing window and then clicking some other link
                            [[sender preferences] setPlugInsEnabled:NO];
                            DDLogDebug(@"Now closing new document browser window for: %@", self.sebWebView);
                            [self.navigationDelegate closeWebView];
                        } else if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInSameWindow) {
                            if (self.sebWebView) {
                                [sender close]; //close the temporary webview
                            }
                        }
                    }
                    
                    // Don't load the request
                    [listener ignore];
                    return;
                }
            }
        }
        
        // Check if this is a seb:// or sebs:// link
        NSString *scheme = request.URL.scheme;
        if ([scheme isEqualToString:@"seb"] || [scheme isEqualToString:@"sebs"]) {
            // If the scheme is seb(s):// we (conditionally) download and open the linked .seb file
            [self.navigationDelegate conditionallyDownloadAndOpenSEBConfigFromURL:request.URL];
            [listener ignore];
            return;
        }
    }

    if (self.currentMainHost && [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == getGenerallyBlocked) {
        [listener ignore];
        return;
    }

    // Check if the new page is supposed to be opened in the same browser window
    if (self.currentMainHost && [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInSameWindow) {
        // Check if the request's sender is different than the current webview (means the sender is the temporary webview)
        if (![sender isEqual:self.sebWebView]) {
            // If the request's sender is the temporary webview, then we have to load the request now in the current webview
            [listener ignore]; // ignore listener
            [self.navigationDelegate.abstractWebView loadURL:request.URL]; //load the new page in the same browser window
            [sender close]; //close the temporary webview
            return; //and return from here
        }
    }

    [listener use];
}


// Open the link requesting to be opened in a new window according to settings
- (void)webView:(SEBWebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
   newFrameName:(NSString *)frameName
decisionListener:(id <WebPolicyDecisionListener>)listener {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    // First check if links requesting to be opened in a new windows are generally blocked
    if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] != getGenerallyBlocked) {

        //// If enabled, filter URL
        SEBURLFilter *URLFilter = [SEBURLFilter sharedSEBURLFilter];
        if (URLFilter.enableURLFilter && ![self.navigationDelegate downloadingInTemporaryWebView]) {
            URLFilterRuleActions filterActionResponse = [URLFilter testURLAllowed:request.URL];
            if (filterActionResponse != URLFilterActionAllow) {
                /// URL is not allowed: Show teach URL alert if activated or just indicate URL is blocked
                if (![self.navigationDelegate showURLFilterAlertForRequest:request forContentFilter:NO filterResponse:filterActionResponse]) {
                    // User didn't allow the URL: Don't load the request
                    [listener ignore];
                    return;
                }
            }
        }
        
        // load link only if it's on the same host like the one of the current page
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkBlockForeign"] ||
            [self.currentMainHost isEqualToString:[[request mainDocumentURL] host]]) {
            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] == openInNewWindow) {
                // Open new browser window containing WebView and show it
                SEBAbstractWebView *newWebView = [self.navigationDelegate openNewWebViewWindow];
                // Load URL request in new WebView
                [newWebView loadURL:request.URL];
            }
            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] == openInSameWindow) {
                // Load URL request in existing WebView
                [[sender mainFrame] loadRequest:request];
            }
        }
    }
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
    /*NSDictionary *headerFields = [request allHTTPHeaderFields];
#ifdef DEBUG
    DDLogInfo(@"Request URL: %@", [[request URL] absoluteString]);
    DDLogInfo(@"All HTTP header fields: %@", headerFields);
#endif*/
    
    // Check if this link had the "download" attribute, then we download the linked resource and don't try to display it
    if (self.downloadFilename) {
        DDLogInfo(@"Link to resource %@ had the 'download' attribute, force download it.", request.URL.absoluteString);
        [listener download];
        [self startDownloadingURL:request.URL];
        return;
    }

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Check if it is a data: scheme to support the W3C saveAs() FileSaver interface
    if ([request.URL.scheme isEqualToString:@"data"]) {
        CFStringRef mimeType = (__bridge CFStringRef)type;
        CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, NULL);
        CFStringRef extension = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
        self.downloadFileExtension = (__bridge NSString *)(extension);
        if (uti) CFRelease(uti);
        if (extension) CFRelease(extension);
        DDLogInfo(@"data: content MIME type to download is %@, the file extension will be %@", type, extension);
        [listener download];
        [self startDownloadingURL:request.URL];
        
        // Close the temporary Window or WebView which has been opend by the data: download link
        SEBWebView *creatingWebView = [self.webView creatingWebView];
        if (creatingWebView) {
            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInNewWindow) {
                // we have to close the new browser window which already has been opened by WebKit
                // Get the document for my web view
                DDLogDebug(@"Originating browser window %@", sender);
                // Close document and therefore also window
                //Workaround: Flash crashes after closing window and then clicking some other link
                [[self.webView preferences] setPlugInsEnabled:NO];
                DDLogDebug(@"Now closing new document browser window for: %@", self.webView);
                [self.browserController closeWebView:self.webView];
            }
            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInSameWindow) {
                if (self.webView) {
                    [sender close]; //close the temporary webview
                }
            }
        }
        return;
    } else {
        self.downloadFileExtension = nil;
    }

    if (([type isEqualToString:@"application/seb"]) ||
        ([type isEqualToString:@"text/xml"]) ||
        ([request.URL.pathExtension isEqualToString:@"seb"])) {
        // If MIME-Type or extension of the file indicates a .seb file, we (conditionally) download and open it
        NSURL *originalURL = self.webView.originalURL;
        [self.browserController downloadSEBConfigFileFromURL:request.URL originalURL:originalURL];
        [listener ignore];
        return;
    }

    // Check for PDF file and according to settings either download or display it inline in the SEB browser
    if (![type isEqualToString:@"application/pdf"] || ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadPDFFiles"]) {
        // MIME type isn't PDF or downloading of PDFs isn't allowed
        if ([WebView canShowMIMEType:type]) {
            [listener use];
            return;
        }
    }
    
    // If MIME type cannot be displayed by the WebView, then we download it
    DDLogInfo(@"MIME type to download is %@", type);
    [listener download];
    [self startDownloadingURL:request.URL];
}


- (void)webView:(SEBWebView *)sender unableToImplementPolicyWithError:(NSError *)error
          frame:(WebFrame *)frame
{
    DDLogError(@"webView: %@ unableToImplementPolicyWithError: %@ frame: %@", sender, error.description, frame);
}


- (void)startDownloadingURL:(NSURL *)url
{
    // Cache the download URL
    downloadURL = url;
    // OS X 10.9 and newer: Use modern NSURLSession for downloading files which also allows handling
    // basic/digest/NTLM authentication
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_9) {
        [self downloadFileFromURL:url];
    } else {
        // OS X 10.7 and 10.8
        // Create a NSURLDownload object with the request and start loading the data
        // Create the request
        NSURLRequest *theRequest = [NSURLRequest requestWithURL:url
                                                    cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                timeoutInterval:60.0];
        NSURLDownload  *theDownload = [[NSURLDownload alloc] initWithRequest:theRequest delegate:self];
        if (!theDownload) {
            DDLogError(@"Starting the download failed!"); //Inform the user that the download failed.
        }
    }
}


- (BOOL)download:(NSURLDownload *)download canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    // We accept any username/password authentication challenges.
    NSString *authenticationMethod = protectionSpace.authenticationMethod;
    
    return [authenticationMethod isEqual:NSURLAuthenticationMethodHTTPBasic] ||
    [authenticationMethod isEqual:NSURLAuthenticationMethodHTTPDigest] ||
    [authenticationMethod isEqual:NSURLAuthenticationMethodNTLM];
}


- (void)download:(NSURLDownload *)download didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (_browserController.enteredCredential) {
        [challenge.sender useCredential:_browserController.enteredCredential forAuthenticationChallenge:challenge];
        // We reset the cached previously entered credentials, because subsequent
        // downloads in this session won't need authentication anymore
        _browserController.enteredCredential = nil;
    } else {
        [self webView:self.webView resource:nil didReceiveAuthenticationChallenge:challenge fromDataSource:nil];
    }
}


- (void)download:(NSURLDownload *)download didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [self webView:self.webView resource:nil didCancelAuthenticationChallenge:challenge fromDataSource:nil];
}


- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
    if ([filename.pathExtension isEqualToString:@"seb"]) {
        // If MIME-Type or extension of the file indicates a .seb file, we (conditionally) download and open it
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        // Check again if opening SEB config files is allowed in settings and if no other settings are currently being opened
        // Because this method is also called when a .seb file is downloaded (besides opening a seb(s):// URL)
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
            // Download the .seb config file directly to memory
            [self.browserController downloadSEBConfigFileFromURL:downloadURL originalURL:nil];
            // and cancel the download to disc below
        }
        // We cancel the download in any case, because .seb config files should be opened directly and not downloaded to disc
        [download cancel];
        return;
    }

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (_allowDownloads == YES) {
        // If downloading is allowed
        downloadPath = [preferences secureStringForKey:@"org_safeexambrowser_SEB_downloadDirectoryOSX"];
        if (!downloadPath) {
            //if there's no path saved in preferences, set standard path
            downloadPath = @"~/Downloads";
        }
        downloadPath = [downloadPath stringByExpandingTildeInPath];
        if (self.downloadFilename) {
            // If we got the filename from a <a download="... tag, we use that
            // as WebKit doesn't recognize the filename and suggests "Unknown"
            filename = self.downloadFilename;
        } else if (self.downloadFileExtension) {
            // If we didn't get the file name, at least set the file extension properly
            filename = [NSString stringWithFormat:@"%@.%@", filename, self.downloadFileExtension];
        }
        NSString *destinationFilename = [downloadPath stringByAppendingPathComponent:filename];
        [download setDestination:destinationFilename allowOverwrite:NO];
    } else {
        // If downloading isn't allowed, then we cancel the initiated download here
        [download cancel];
    }
}


- (void) download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    // Inform the user
    [self presentError:error modalForWindow:self delegate:nil didPresentSelector:NULL contextInfo:NULL];

    DDLogError(@"Download failed! Error - %@ %@",
               error.description,
               [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}


- (void) downloadDidFinish:(NSURLDownload *)download
{
    DDLogDebug(@"%s: Downloaded file with path: %@", __FUNCTION__, downloadPath);
    [self fileDownloadedSuccessfully:downloadPath];
}


- (void) download:(NSURLDownload *)download didCreateDestination:(NSString *)path
{
    // path now contains the destination path
    // of the download, taking into account any
    // unique naming caused by -setDestination:allowOverwrite:
    [self storeDownloadPath:path];
}


- (void) storeDownloadPath:(NSString *)path
{
    downloadPath = path;
    NSMutableArray *downloadPaths = [NSMutableArray arrayWithArray:[[MyGlobals sharedMyGlobals] downloadPath]];
    if (!downloadPaths) {
        downloadPaths = [NSMutableArray arrayWithCapacity:1];
    }
    [downloadPaths addObject:downloadPath];
    [[MyGlobals sharedMyGlobals] setDownloadPath:downloadPaths];
    [[MyGlobals sharedMyGlobals] setLastDownloadPath:[downloadPaths count]-1];
}


- (void) fileDownloadedSuccessfully:(NSString *)path
{
    DDLogInfo(@"Download of File %@ did finish.", downloadPath);
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_openDownloads"] == YES) {
        // Open downloaded file
        [[NSWorkspace sharedWorkspace] openFile:path];
    } else {
        NSAlert *modalAlert = [self.browserController.sebController newAlert];
        // Inform user that download succeeded
        [modalAlert setMessageText:NSLocalizedString(@"Download Finished", nil)];
        [modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"%@ was downloaded.", nil), downloadPath]];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [modalAlert setAlertStyle:NSInformationalAlertStyle];
        void (^alertOKHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self.browserController.sebController removeAlertWindow:modalAlert.window];
        };
        [self.browserController.sebController runModalAlert:modalAlert conditionallyForWindow:self completionHandler:(void (^)(NSModalResponse answer))alertOKHandler];
    }
}


#pragma mark Downloading for macOS 10.9 and higher

- (void) downloadFileFromURL:(NSURL *)url
{
    DDLogDebug(@"%s URL: %@", __FUNCTION__, url);
    
    if (!_URLSession) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        _URLSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self.browserController delegateQueue:nil];
    }
    NSURLSessionDownloadTask *downloadTask = [_URLSession downloadTaskWithURL:url
                                                            completionHandler:^(NSURL *fileLocation, NSURLResponse *response, NSError *error)
                                              {
                                                  [self didDownloadFile:fileLocation response:response error:error];
                                              }];
    
    [downloadTask resume];
}


- (void) didDownloadFile:(NSURL *)url
                response:(NSURLResponse *)response
                   error:(NSError *)error
{
    NSString *suggestedFilename = response.suggestedFilename;
    NSURL *responseURL = response.URL;
    NSString *pathExtension = responseURL.pathExtension;
    DDLogDebug(@"%s from URL: %@ (NSURLResponse URL: %@, suggestedFilename: %@, error: %@", __FUNCTION__, url, responseURL, suggestedFilename, error);
    
    if (!error) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        NSString *filename = suggestedFilename;
        if (self.downloadFilename) {
            // If we got the filename from a <a download="... tag, we use that
            // as WebKit doesn't recognize the filename and suggests "Unknown"
            filename = self.downloadFilename;
            pathExtension = filename.pathExtension;
        } else if (self.downloadFileExtension) {
            // If we didn't get the file name, at least set the file extension properly
            filename = [NSString stringWithFormat:@"%@.%@", filename, self.downloadFileExtension];
        }

        if ([pathExtension isEqualToString:@"seb"] || [filename.pathExtension isEqualToString:@"seb"]) {
            // If file extension indicates a .seb file, we try to open it
            // First check if opening SEB config files is allowed in settings and if no other settings are currently being opened
            if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
                // Read the contents of the .seb config file and delete it from disk
                NSData *sebFileData = [NSData dataWithContentsOfURL:url];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                [fileManager removeItemAtURL:url error:&error];
                if (error) {
                    DDLogError(@"Failed to remove downloaded SEB config file %@! Error: %@", url, [error userInfo]);
                }
                if (sebFileData) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSURL *originalURL = self.webView.originalURL;
                        [self.browserController openDownloadedSEBConfigData:sebFileData
                                                                    fromURL:url
                                                                originalURL:originalURL];
                    });
                    return;
                }
            }
        } else if (_allowDownloads == YES) {
            // If downloading is allowed
            NSString *downloadPath = [preferences secureStringForKey:@"org_safeexambrowser_SEB_downloadDirectoryOSX"];
            if (downloadPath.length == 0) {
                //if there's no path saved in preferences, set standard path
                downloadPath = @"~/Downloads";
            }
            downloadPath = [downloadPath stringByExpandingTildeInPath];
            NSURL *destinationURL = [NSURL fileURLWithPath:[downloadPath stringByAppendingPathComponent:filename] isDirectory:NO];
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            int fileIndex = 1;
            NSURL *directory = destinationURL.URLByDeletingLastPathComponent;
            NSString* filenameWithoutExtension = [filename stringByDeletingPathExtension];
            NSString* extension = [filename pathExtension];

            while ([fileManager moveItemAtURL:url toURL:[directory URLByAppendingPathComponent:filename] error:&error] == NO) {
                if (error.code == NSFileWriteFileExistsError) {
                    error = nil;
                    filename = [NSString stringWithFormat:@"%@-%d.%@", filenameWithoutExtension, fileIndex, extension];
                    fileIndex++;
                } else {
                    break;
                }
            }
            if (!error) {
                [self storeDownloadPath:destinationURL.absoluteString];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self fileDownloadedSuccessfully:destinationURL.absoluteString];
                });
                return;
            } else {
                DDLogError(@"Failed to move downloaded file! %@", [error userInfo]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentError:error modalForWindow:self delegate:nil didPresentSelector:NULL contextInfo:NULL];
                });
                return;
            }
        } else {
            // Downloading not allowed
            return;
        }
    }
    
    // Download failed: Show error message
    DDLogError(@"Download failed! Error - %@ %@",
               error.description,
               [error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey]);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentError:error modalForWindow:self delegate:nil didPresentSelector:NULL contextInfo:NULL];
    });
}


@end
