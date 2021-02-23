//
//  SEBOSXBrowserController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06/10/14.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider,
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

#import "SEBOSXBrowserController.h"
#import "SEBBrowserOpenWindowWebView.h"
#import "NSWindow+SEBWindow.h"
#import "WebKit+WebKitExtensions.h"
#import "SEBOSXConfigFileController.h"

#include "WebStorageManagerPrivate.h"
#include "WebPreferencesPrivate.h"
#import "WebPluginDatabase.h"
#import "NSURL+SEBURL.h"
#import "NSScreen+SEBScreen.h"

@implementation SEBOSXBrowserController


- (instancetype)init
{
    self = [super init];
    if (self) {
        _browserController = [SEBBrowserController new];
        _browserController.delegate = self;

        // Activate the custom URL protocol if necessary (embedded certs or pinning available)
        [_browserController conditionallyInitCustomHTTPProtocol];

        self.openBrowserWindowsWebViews = [NSMutableArray new];

        // Initialize SEB dock item menu for open browser windows/WebViews
        SEBDockItemMenu *dockMenu = [[SEBDockItemMenu alloc] initWithTitle:@""];
        self.openBrowserWindowsWebViewsMenu = dockMenu;

        // Create a private pasteboard
        _privatePasteboardItems = [NSArray array];
        
        // Empties all cookies, caches and credential stores, removes disk files, flushes in-progress
        // downloads to disk, and ensures that future requests occur on a new socket.
        // OS X 10.9 and newer
        if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_9) {
            [[NSURLSession sharedSession] resetWithCompletionHandler:^{
                DDLogInfo(@"Cookies, caches and credential stores were reset");
            }];
        } else {
            DDLogError(@"Cannot reset cookies, caches and credential stores because of running on OS X 10.7 or 10.8.");
        }
    }
    return self;
}


- (NSData *)browserExamKey
{
    return _browserController.browserExamKey;
}

- (NSData *)configKey
{
    return _browserController.configKey;
}

- (NSScreen *) mainScreen
{
    return _sebController.mainScreen;
}

- (void) resetBrowser
{
    if (examSessionCookiesAlreadyCleared == NO) {
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_examSessionClearCookiesOnStart"]) {
            // Empties all cookies, caches and credential stores, removes disk files, flushes in-progress
            // downloads to disk, and ensures that future requests occur on a new socket.
            // OS X 10.9 and newer
            if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_9) {
                [[NSURLSession sharedSession] resetWithCompletionHandler:^{
                    DDLogInfo(@"Cookies, caches and credential stores were reset when starting new browser session (examSessionClearCookiesOnStart = false)");
                }];
            } else {
                DDLogError(@"Cannot reset cookies, caches and credential stores (when starting new browser session) because of running on OS X 10.7 or 10.8.");
            }
        }
    } else {
        // reset the flag when it was true before
        examSessionCookiesAlreadyCleared = NO;
    }

    _activeBrowserWindow = nil;
    
    [self.openBrowserWindowsWebViews removeAllObjects];
    // Initialize SEB dock item menu for open browser windows/WebViews
    SEBDockItemMenu *dockMenu = [[SEBDockItemMenu alloc] initWithTitle:@""];
    self.openBrowserWindowsWebViewsMenu = dockMenu;
    
    // Clear browser back/forward list (page cache)
    [self clearBackForwardList];
    
    self.currentMainHost = nil;
    _temporaryWebView = nil;
    
    _browserController.browserExamKey = nil;
    _browserController.configKey = nil;
    
    [_browserController conditionallyInitCustomHTTPProtocol];
}


// Save the default user agent of the installed WebKit version
- (void) createSEBUserAgentFromDefaultAgent:(NSString *)defaultUserAgent
{
    [_browserController createSEBUserAgentFromDefaultAgent:defaultUserAgent];
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


// Open a new web browser window document
- (SEBBrowserWindowDocument *) openBrowserWindowDocument
{
    NSError *error;
    SEBBrowserWindowDocument *browserWindowDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:NO error:&error];
    
    if (!error) {
        // Set the reference to the browser controller in the browser window document instance
        browserWindowDocument.browserController = self;
        
        // Show the browser window document = browser window
        [browserWindowDocument makeWindowControllers];
        
        SEBBrowserWindow *newWindow = (SEBBrowserWindow *)browserWindowDocument.mainWindowController.window;
        
        // Prevent that the browser window displays the button to make it fullscreen in OS X 10.11
        // and that it would allow to be used in split screen mode
        newWindow.collectionBehavior = NSWindowCollectionBehaviorStationary + NSWindowCollectionBehaviorFullScreenAuxiliary +NSWindowCollectionBehaviorFullScreenDisallowsTiling;
        
        // Enable or disable spell checking
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        _allowSpellCheck = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSpellCheck"];
        
        //    NSTextView *textView = (NSTextView *)[newWindow firstResponder];
        [newWindow.webView setContinuousSpellCheckingEnabled:_allowSpellCheck];
    }
    return browserWindowDocument;
}


// Open a new WebView and show its window
- (SEBWebView *) openAndShowWebView
{
    SEBBrowserWindowDocument *browserWindowDocument = [self openBrowserWindowDocument];

    SEBBrowserWindow *newWindow = (SEBBrowserWindow *)browserWindowDocument.mainWindowController.window;
    SEBWebView *newWindowWebView = browserWindowDocument.mainWindowController.webView;
    newWindowWebView.creatingWebView = nil;
    newWindowWebView.browserController = self;

    // Create custom WebPreferences with bugfix for local storage not persisting application quit/start
    [self setCustomWebPreferencesForWebView:newWindowWebView];

    [self addBrowserWindow:(SEBBrowserWindow *)browserWindowDocument.mainWindowController.window
               withWebView:newWindowWebView
                 withTitle:NSLocalizedString(@"Untitled", @"Title of a new opened browser window; Untitled")];
    
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowWindowCapture"] == NO) {
        [browserWindowDocument.mainWindowController.window setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
    }
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL elevateWindowLevels = [preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    // Order new browser window to the front of our level
    [self setLevelForBrowserWindow:browserWindowDocument.mainWindowController.window elevateLevels:elevateWindowLevels];
    self.activeBrowserWindow = newWindow;
    self.activeBrowserWindowTitle = NSLocalizedString(@"Untitled", nil);
    [browserWindowDocument.mainWindowController showWindow:self];
    [newWindow makeKeyAndOrderFront:self];
    
    return newWindowWebView;
}


- (void) closeWebView:(SEBWebView *) webViewToClose
{
    if (webViewToClose) {
        // Remove the entry for the WebView in a browser window from the array and dock item menu of open browser windows/WebViews
        [self removeBrowserWindow:(SEBBrowserWindow *)webViewToClose.window withWebView:webViewToClose];
        
        // Get the document for the web view
        id myDocument = [[NSDocumentController sharedDocumentController] documentForWindow:webViewToClose.window];
        
        // Close document and therefore also window
        DDLogInfo(@"Now closing new document browser window with WebView: %@", webViewToClose);
        
        [myDocument close];
        _activeBrowserWindow = nil;
        
        if (webViewToClose == _temporaryWebView) {
            _temporaryWebView = nil;
        }
    }
}


- (void) checkForClosingTemporaryWebView:(SEBWebView *) webViewToClose
{
    DDLogDebug(@"%s", __FUNCTION__);
    if (webViewToClose == _temporaryWebView) {
        [self openingConfigURLRoleBack];
    }
}


// Show new window containing webView
- (void) webViewShow:(SEBWebView *)sender
{
    SEBBrowserWindowDocument *browserWindowDocument = [[NSDocumentController sharedDocumentController] documentForWindow:[sender window]];
//    [[sender window] setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
//    BOOL elevateWindowLevels = [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
//    [self setLevelForBrowserWindow:[sender window] elevateLevels:elevateWindowLevels];

    [browserWindowDocument showWindows];
    DDLogInfo(@"Now showing new document browser window for: %@",sender);
    // Order new browser window to the front
    //[[sender window] makeKeyAndOrderFront:self];
}


// Set up SEB Browser and open the main window
- (void) openMainBrowserWindow {
    
    [self.sebController conditionallyLockExam];
    
    // Log current WebKit Cookie Policy
     NSHTTPCookieAcceptPolicy cookiePolicy = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookieAcceptPolicy];
    if (cookiePolicy == NSHTTPCookieAcceptPolicyAlways) {
        DDLogInfo(@"NSHTTPCookieAcceptPolicyAlways");
    }
    if (cookiePolicy == NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain) {
        DDLogInfo(@"NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain");
    }
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Preconfigure Window for full screen
    BOOL mainBrowserWindowShouldBeFullScreen = ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserViewMode"] == browserViewModeFullscreen);
    
    DDLogInfo(@"Open MainBrowserWindow with browserViewMode: %hhd", mainBrowserWindowShouldBeFullScreen);
    
    // Open and maximize the browser window
    // (this is done here, after presentation options are set,
    // because otherwise menu bar and dock are deducted from screen size)
    SEBBrowserWindowDocument *browserWindowDocument = [self openBrowserWindowDocument];
    
    self.mainWebView = browserWindowDocument.mainWindowController.webView;
    self.mainWebView.creatingWebView = nil;
    self.mainWebView.browserController = self;

    // Load start URL from the system's user defaults
    NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    
    // Handle Start URL Query String Parameter
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_startURLAppendQueryParameter"]) {
        NSString *queryString = [preferences secureStringForKey:@"org_safeexambrowser_startURLQueryParameter"];
        if (queryString.length > 0) {
            urlText = [NSString stringWithFormat:@"%@?%@", urlText, queryString];
        }
    }

    // Create custom WebPreferences with bugfix for local storage not persisting application quit/start
    [self setCustomWebPreferencesForWebView:self.mainWebView];
    
    self.mainBrowserWindow = (SEBBrowserWindow *)browserWindowDocument.mainWindowController.window;
    DDLogDebug(@"Set main browser window: %@", self.mainBrowserWindow);

    // Check if the active screen (where the window is opened) changed in between opening dock
    if (self.mainBrowserWindow.screen != self.dockController.window.screen) {
        // Post a notification that the main screen changed
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"mainScreenChanged" object:self];
    }

    // Prevent that the browser window displays the button to make it fullscreen in OS X 10.11
    // and that it would allow to be used in split screen mode
    self.mainBrowserWindow.collectionBehavior = NSWindowCollectionBehaviorStationary + NSWindowCollectionBehaviorFullScreenAuxiliary +NSWindowCollectionBehaviorFullScreenDisallowsTiling;

    // Set the flag indicating if the main browser window should be displayed full screen
    self.mainBrowserWindow.isFullScreen = mainBrowserWindowShouldBeFullScreen;
    
    if (mainBrowserWindowShouldBeFullScreen) {
        [self.mainBrowserWindow setToolbar:nil];
        [self.mainBrowserWindow setStyleMask:NSBorderlessWindowMask];
        [self.mainBrowserWindow setReleasedWhenClosed:YES];
    }
    
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowWindowCapture"] == NO) {
        [self.mainBrowserWindow setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
    }
    [self.mainBrowserWindow setCalculatedFrameOnScreen:_sebController.mainScreen];
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"] && _sebController.isAACEnabled == NO) {
        [self.mainBrowserWindow newSetLevel:NSMainMenuWindowLevel+3];
    }
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    
    // Setup bindings to the preferences window close button
    NSButton *closeButton = [self.mainBrowserWindow standardWindowButton:NSWindowCloseButton];
    
    [closeButton bind:@"enabled"
             toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
          withKeyPath:@"values.org_safeexambrowser_SEB_allowQuit"
              options:nil];
    
    [self addBrowserWindow:self.mainBrowserWindow withWebView:self.mainWebView withTitle:NSLocalizedString(@"Main Browser Window", nil)];
    
    [self.mainBrowserWindow makeMainWindow];
    [self.mainBrowserWindow makeKeyAndOrderFront:self];
    self.activeBrowserWindow = self.mainBrowserWindow;
    
    DDLogInfo(@"Open MainBrowserWindow with start URL: %@", urlText);
    
    [self openURLString:urlText withSEBUserAgentInWebView:self.mainWebView];
}


- (void) clearBackForwardList
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    [self.mainWebView setMaintainsBackForwardList:NO];
    [self.mainWebView setMaintainsBackForwardList:[preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowBrowsingBackForward"]];
}


- (void) openURLString:(NSString *)urlText withSEBUserAgentInWebView:(SEBWebView *)webView
{
    // Load start URL into browser window
    [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlText]]];
}


// Find the real visible frame of a screen SEB is running on
- (NSRect) visibleFrameForScreen:(NSScreen *)screen
{
    // Get frame of the usable screen (considering if menu bar is enabled)
    NSRect screenFrame = screen.usableFrame;
    // Check if SEB Dock is displayed and reduce visibleFrame accordingly
    // Also check if mainBrowserWindow exists, because when starting with a temporary
    // browser window for loading a seb(s):// link from a authenticated server, there
    // is no main browser window open yet
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ((!_mainBrowserWindow || screen == _mainBrowserWindow.screen) && [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"]) {
        double dockHeight = [preferences secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
        screenFrame.origin.y += dockHeight;
        screenFrame.size.height -= dockHeight;
    }
    return screenFrame;
}


// Adjust the size of the main browser window and bring it forward
- (void) adjustMainBrowserWindow
{
    if (self.mainBrowserWindow.isVisible) {
        [self.mainBrowserWindow setCalculatedFrame];
        [self.mainBrowserWindow makeKeyAndOrderFront:self];
    }
}


// Change window level of all open browser windows
- (void) moveAllBrowserWindowsToScreen:(NSScreen *)screen
{
    NSArray *openWindowDocuments = [[NSDocumentController sharedDocumentController] documents];
    SEBBrowserWindowDocument *openWindowDocument;
    for (openWindowDocument in openWindowDocuments) {
        SEBBrowserWindow *browserWindow = (SEBBrowserWindow *)openWindowDocument.mainWindowController.window;
        if (browserWindow.screen != screen) {
            [browserWindow setCalculatedFrameOnScreen:screen];
        }
    }
    
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [self.mainBrowserWindow makeKeyAndOrderFront:self];
}


// Change window level of all open browser windows
- (void) browserWindowsChangeLevelAllowApps:(BOOL)allowApps
{
    DDLogDebug(@"%s allowApps: %hd", __FUNCTION__, allowApps);
    NSArray *openWindowDocuments = [[NSDocumentController sharedDocumentController] documents];
    SEBBrowserWindowDocument *openWindowDocument;
    for (openWindowDocument in openWindowDocuments) {
        NSWindow *browserWindow = openWindowDocument.mainWindowController.window;
        [self setLevelForBrowserWindow:browserWindow elevateLevels:!allowApps];
        [browserWindow orderFront:self];
    }
    // If the main browser window is displayed fullscreen and switching to apps is allowed,
    // we make the window stationary, so that it isn't scaled down from Exposé
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"] && self.mainBrowserWindow.isFullScreen) {
        self.mainBrowserWindow.collectionBehavior = NSWindowCollectionBehaviorStationary + NSWindowCollectionBehaviorFullScreenAuxiliary +NSWindowCollectionBehaviorFullScreenDisallowsTiling;
    }
    
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [self.mainBrowserWindow makeKeyAndOrderFront:self];
}


- (void) setLevelForBrowserWindow:(NSWindow *)browserWindow elevateLevels:(BOOL)elevateLevels
{
    DDLogDebug(@"%s browserWindow: %@ elevateLevels: %hd", __FUNCTION__, browserWindow, elevateLevels);
    int levelOffset = (int)((SEBBrowserWindow *)browserWindow).isPanel;
    if (elevateLevels) {
        if (self.mainBrowserWindow.isFullScreen && browserWindow != self.mainBrowserWindow && _sebController.isAACEnabled == NO) {
            // If the main browser window is displayed fullscreen, then all auxillary windows
            // get a higher level, to float on top
            [browserWindow newSetLevel:NSMainMenuWindowLevel+4+levelOffset];
        } else {
            [browserWindow newSetLevel:NSMainMenuWindowLevel+3+levelOffset];
        }
    } else {
        
        // Order new browser window to the front of our level
        if (self.mainBrowserWindow.isFullScreen && browserWindow != self.mainBrowserWindow) {
            // If the main browser window is displayed fullscreen, then all auxillary windows
            // get a higher level, to float on top
            [browserWindow newSetLevel:NSNormalWindowLevel+1+levelOffset];
        } else {
            [browserWindow newSetLevel:NSNormalWindowLevel+levelOffset];
        }
        //[browserWindow orderFront:self];
    }
}


// Open an allowed additional resource in a new browser window
- (void)openResourceWithURL:(NSString *)URL andTitle:(NSString *)title
{
    NSError *error;
    
    /// ToDo: change opening and passing the reference to self
    SEBBrowserWindowDocument *browserWindowDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentAndDisplay:YES error:&error];
    if (!error) {
        NSWindow *additionalBrowserWindow = browserWindowDocument.mainWindowController.window;
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowWindowCapture"] == NO) {
            [additionalBrowserWindow setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
        }
        [(SEBBrowserWindow *)additionalBrowserWindow setCalculatedFrame];
        BOOL elevateWindowLevels = [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
        [self setLevelForBrowserWindow:additionalBrowserWindow elevateLevels:elevateWindowLevels];
        
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        
        //[additionalBrowserWindow makeKeyAndOrderFront:self];
        
        DDLogInfo(@"Open additional browser window with URL: %@", URL);
        
        // Load start URL into browser window
        [[browserWindowDocument.mainWindowController.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URL]]];
    }
}


// Set web page title for a window/WebView
- (void) setTitle:(NSString *)title forWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBWebView *)webView
{
    _activeBrowserWindowTitle = title;
    for (SEBBrowserOpenWindowWebView *openWindowWebView in self.openBrowserWindowsWebViews) {
        if ([openWindowWebView.webView isEqualTo:webView]) {
            [openWindowWebView setTitle: title];
            [self.openBrowserWindowsWebViewsMenu setPopoverMenuSize];
        }
    }
    [self setStateForWindow:browserWindow withWebView:webView];
}


// Select the current window in the SEB Dock popup menu with the titles of all open browser windows
- (void) setStateForWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBWebView *)webView
{
    DDLogVerbose(@"setStateForWindow: %@ withWebView: %@", browserWindow, webView);

    for (SEBBrowserOpenWindowWebView *openWindowWebView in self.openBrowserWindowsWebViews) {
        if (openWindowWebView && [openWindowWebView.webView isEqualTo:webView]) {
            [openWindowWebView setState:NSOnState];
            DDLogVerbose(@"setState: NSOnState: %@", webView);
        } else if (openWindowWebView) {
            [openWindowWebView setState:NSOffState];
        }
    }
    // Update enabled property of reload button in Dock
    [self.sebController reloadButtonEnabled:[[NSUserDefaults standardUserDefaults] secureBoolForKey:
                                             (_activeBrowserWindow == _mainBrowserWindow ?
                                             @"org_safeexambrowser_SEB_browserWindowAllowReload" : @"org_safeexambrowser_SEB_newBrowserWindowAllowReload")]];
}


- (void) activateNextOpenWindow
{
    NSUInteger openBrowserWindowsCount = self.openBrowserWindowsWebViews.count;
    SEBBrowserOpenWindowWebView *openWindowWebView;
    for (NSUInteger i = 0; i < openBrowserWindowsCount; i++) {
        openWindowWebView = self.openBrowserWindowsWebViews[i];
        if ([openWindowWebView.browserWindow isEqualTo:_activeBrowserWindow]) {
            if (i == openBrowserWindowsCount-1) {
                openWindowWebView = self.openBrowserWindowsWebViews[0];
            } else {
                openWindowWebView = self.openBrowserWindowsWebViews[i+1];
            }
            break;
        }
    }
    [self openWindowSelected:openWindowWebView];
}


- (void) activatePreviousOpenWindow
{
    NSUInteger openBrowserWindowsCount = self.openBrowserWindowsWebViews.count;
    SEBBrowserOpenWindowWebView *openWindowWebView;
    for (NSUInteger i = 0; i < openBrowserWindowsCount; i++) {
        openWindowWebView = self.openBrowserWindowsWebViews[i];
        if ([openWindowWebView.browserWindow isEqualTo:_activeBrowserWindow]) {
            if (i == 0) {
                openWindowWebView = self.openBrowserWindowsWebViews[openBrowserWindowsCount-1];
            } else {
                openWindowWebView = self.openBrowserWindowsWebViews[i-1];
            }
            break;
        }
    }
    [self openWindowSelected:openWindowWebView];
}


// Add an entry for a WebView in a browser window into the array and dock item menu of open browser windows/WebViews
- (void) addBrowserWindow:(SEBBrowserWindow *)newBrowserWindow withWebView:(SEBWebView *)newWebView withTitle:(NSString *)newTitle
{
    SEBBrowserOpenWindowWebView *newWindowWebView = [[SEBBrowserOpenWindowWebView alloc] initWithTitle:newTitle action:@selector(openWindowSelected:) keyEquivalent:@""];
    newWindowWebView.browserWindow = newBrowserWindow;
    newWindowWebView.webView = newWebView;
    newWindowWebView.title = newTitle;
    NSImage *browserWindowImage;
    [newWindowWebView setTarget:self];

    [self.openBrowserWindowsWebViews addObject:newWindowWebView];
    
    NSInteger numberOfItems = self.openBrowserWindowsWebViews.count;

    if (numberOfItems == 1) {
        browserWindowImage = [NSImage imageNamed:@"ExamIcon"];
    } else {
        browserWindowImage = [NSImage imageNamed:@"BrowserIcon"];
    }
    [browserWindowImage setSize:NSMakeSize(16, 16)];
    [newWindowWebView setImage:browserWindowImage];

    if (numberOfItems == 2) {
        [self.openBrowserWindowsWebViewsMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
    }
    
    [self.openBrowserWindowsWebViewsMenu insertItem:newWindowWebView atIndex:1];
}


// Remove an entry for a WebView in a browser window from the array and dock item menu of open browser windows/WebViews
- (void) removeBrowserWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBWebView *)webView
{
    SEBBrowserOpenWindowWebView *itemToRemove;
    for (SEBBrowserOpenWindowWebView *openWindowWebView in self.openBrowserWindowsWebViews) {
        if ([openWindowWebView.webView isEqualTo:webView]) {
            itemToRemove = openWindowWebView;
            break;
        }
    }
    [self.openBrowserWindowsWebViews removeObject:itemToRemove];
    [self.openBrowserWindowsWebViewsMenu removeItem:itemToRemove];
    if (self.openBrowserWindowsWebViews.count == 1) {
        [self.openBrowserWindowsWebViewsMenu removeItemAtIndex:1];
    }
}


- (void) openWindowSelected:(SEBBrowserOpenWindowWebView *)sender
{
    DDLogInfo(@"Selected menu item: %@", sender);

    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [sender.browserWindow makeKeyAndOrderFront:self];
}


// Close all browser windows (including the main browser window)
- (void) closeAllBrowserWindows
{
    // Close all browser windows (documents)
    self.mainBrowserWindow = nil;
    [[NSDocumentController sharedDocumentController] closeAllDocumentsWithDelegate:self
                                                               didCloseAllSelector:@selector(documentController:didCloseAll:contextInfo:)
                                                                       contextInfo: nil];
}


- (void)documentController:(NSDocumentController *)docController  didCloseAll: (BOOL)didCloseAll contextInfo:(void *)contextInfo
{
    DDLogDebug(@"documentController: %@ didCloseAll: %hhd contextInfo: %@", docController, didCloseAll, contextInfo);
}


// Close all additional browser windows (except the main browser window)
- (void) closeAllAdditionalBrowserWindows
{
    NSArray *openWindowDocuments = [[NSDocumentController sharedDocumentController] documents];
    SEBBrowserWindowDocument *openWindowDocument;
    for (openWindowDocument in openWindowDocuments) {
        SEBBrowserWindow *browserWindow = (SEBBrowserWindow *)openWindowDocument.mainWindowController.window;
        if (browserWindow != self.mainBrowserWindow) {
            [self closeWebView:browserWindow.webView];
        }
    }
}


- (void) showEnterUsernamePasswordDialog:(NSString *)text
                          modalForWindow:(NSWindow *)window
                             windowTitle:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector
{
    [_sebController showEnterUsernamePasswordDialog:[[NSAttributedString alloc] initWithString:text]
                                     modalForWindow:window
                                        windowTitle:title
                                           username:username
                                      modalDelegate:modalDelegate
                                     didEndSelector:didEndSelector];
}


#pragma mark SEBBrowserControllerDelegate Methods

- (void) showEnterUsernamePasswordDialog:(NSString *)text
                                   title:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector
{
    [_sebController showEnterUsernamePasswordDialog:[[NSAttributedString alloc] initWithString:text]
                                     modalForWindow:self.activeBrowserWindow
                                        windowTitle:title
                                           username:username
                                      modalDelegate:modalDelegate
                                     didEndSelector:didEndSelector];
}


- (void) hideEnterUsernamePasswordDialog
{
    [_sebController hideEnterUsernamePasswordDialog];
    
    // If a temporary webview for loading config is open, close it
    [self openingConfigURLFailed];
}


// Delegate method which returns URL or placeholder text (in case settings
// don't allow to display its URL) for active browser window
- (NSString *) placeholderTitleOrURLForActiveWebpage
{
    NSString *placeholderOrURLString = nil;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (_activeBrowserWindow == _mainBrowserWindow) {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowShowURL"] == browserWindowShowURLNever) {
            placeholderOrURLString = NSLocalizedString(@"the exam page", nil);
        } else {
            placeholderOrURLString = _activeBrowserWindow.webView.mainFrameURL;
        }
    } else {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowShowURL"] == browserWindowShowURLNever) {
            placeholderOrURLString = NSLocalizedString(@"the webpage", nil);
        } else {
            placeholderOrURLString = _activeBrowserWindow.webView.mainFrameURL;
        }
    }
    return placeholderOrURLString;
}


// Delegate method which returns a placeholder text in case settings
// don't allow to display its URL
- (NSString *) showURLplaceholderTitleForWebpage
{
    NSString *placeholderString = nil;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (_activeBrowserWindow == _mainBrowserWindow) {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowShowURL"] <= browserWindowShowURLOnlyLoadError) {
            placeholderString = NSLocalizedString(@"the exam page", nil);
        }
    } else {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowShowURL"] <= browserWindowShowURLOnlyLoadError) {
            placeholderString = NSLocalizedString(@"the webpage", nil);
        }
    }
    return placeholderString;
}


#pragma mark Downloading SEB Config Files

// Check if SEB is in exam mode = private UserDefauls are switched on:
// Then opening a new config file/reconfiguring SEB isn't allowed
- (BOOL) isReconfiguringAllowedFromURL:(NSURL *)url
{
    if (![self.browserController isReconfiguringAllowedFromURL:url]) {
        // If yes, we don't download the .seb file
        // Also reset the flag for SEB starting up
        _sebController.startingUp = false;
        NSAlert *modalAlert = [_sebController newAlert];
        [modalAlert setMessageText:NSLocalizedString(@"Loading New SEB Settings Not Allowed!", nil)];
        [modalAlert setInformativeText:NSLocalizedString(@"SEB is already running in exam mode and it is not allowed to interrupt this by starting another exam. Finish the exam and quit SEB before starting another exam.", nil)];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [modalAlert setAlertStyle:NSCriticalAlertStyle];
        void (^reconfiguringNotAllowedOK)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self.sebController removeAlertWindow:modalAlert.window];
        };
        [self.sebController runModalAlert:modalAlert conditionallyForWindow:self.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))reconfiguringNotAllowedOK];
        self.sebController.openingSettings = false;
        return NO;
    } else {
        return YES;
    }
}


/// Initiating Opening the Config File Link

// Conditionally open a config from an URL passed to SEB as parameter
// usually with a link using the seb(s):// protocols
- (void) openConfigFromSEBURL:(NSURL *)url
{
    DDLogDebug(@"%s URL: %@", __FUNCTION__, url);
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    // Check first if opening SEB config files is allowed in settings and if no other settings are currently being opened
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"] && !_temporaryWebView) {
        // Check if SEB is in exam mode = private UserDefauls are switched on
        if (_sebController.startingUp || [self isReconfiguringAllowedFromURL:url]) {
            // SEB isn't in exam mode: reconfiguring is allowed
            NSURL *sebURL = url;
            // Figure the download URL out, depending on if http or https should be used
            if ([url.scheme isEqualToString:@"seb"]) {
                // If it's a seb:// URL, we try to download it by http
                url = [url URLByReplacingScheme:@"http"];
            } else if ([url.scheme isEqualToString:@"sebs"]) {
                // If it's a sebs:// URL, we try to download it by https
                url = [url URLByReplacingScheme:@"https"];
            }
            
            // When the URL of the SEB config file to load is on another host than the current page
            // then we might need to clear session cookies before attempting to download the config file
            // when the setting examSessionClearCookiesOnEnd is true
            if (_currentMainHost && ![url.host isEqualToString:_currentMainHost]) {
                if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_examSessionClearCookiesOnEnd"]) {
                    // Empties all cookies, caches and credential stores, removes disk files, flushes in-progress
                    // downloads to disk, and ensures that future requests occur on a new socket.
                    // OS X 10.9 and newer
                    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_9) {
                        [[NSURLSession sharedSession] resetWithCompletionHandler:^{
                            DDLogInfo(@"Cookies, caches and credential stores were reset when ending browser session (examSessionClearCookiesOnEnd = false)");
                        }];
                    } else {
                        DDLogError(@"Cannot reset cookies, caches and credential stores (when ending browser session) because of running on OS X 10.7 or 10.8.");
                    }
                }
                // Set the flag for cookies cleared (either they actually were or they would have
                // been settings prevented it)
                examSessionCookiesAlreadyCleared = YES;

            } else if (!_currentMainHost) {
                // When currentMainHost isn't set yet, SEB was started with a config link, possibly
                // to an authenticated server. In this case, session cookies shouldn't be cleared after logging in
                // as they were anyways cleared when SEB was started
                examSessionCookiesAlreadyCleared = YES;
            }
            // Check if we should try to download the config file from the seb(s) URL directly
            // This is the case when the URL has a .seb filename extension
            // But we only try it when it didn't fail in a first attempt
            if (_directConfigDownloadAttempted == false && [url.pathExtension isEqualToString:@"seb"]) {
                _directConfigDownloadAttempted = true;
                [self downloadSEBConfigFileFromURL:url originalURL:sebURL];
            } else {
                _directConfigDownloadAttempted = false;
                [self openTempWindowForDownloadingConfigFromURL:url originalURL:sebURL];
            }
        }
    } else {
        DDLogDebug(@"%s aborted, downloading and opening settings not allowed or temporary webview already open: %@", __FUNCTION__, _temporaryWebView);
        _sebController.openingSettings = false;
    }
}


// Open a new, temporary browser window for downloading the linked config file
// This allows the user to authenticate if the link target is stored on a secured server
- (void) openTempWindowForDownloadingConfigFromURL:(NSURL *)url originalURL:(NSURL *)originalURL
{
    DDLogDebug(@"%s URL: %@", __FUNCTION__, url);
    
    // Create a new WebView
    NSString *tempWindowTitle = NSLocalizedString(@"Opening SEB Config", @"Title of a temporary browser window for opening a SEB link");
    _temporaryBrowserWindowDocument = [self openBrowserWindowDocument];
    SEBBrowserWindow *newWindow = (SEBBrowserWindow *)_temporaryBrowserWindowDocument.mainWindowController.window;
    _temporaryWebView = _temporaryBrowserWindowDocument.mainWindowController.webView;
    if (_sebController.startingUp) {
        _temporaryWebView.creatingWebView = _temporaryWebView;
    } else {
        _temporaryWebView.creatingWebView = nil;
    }
    _temporaryWebView.browserController = self;
    _temporaryWebView.originalURL = originalURL;
    
    newWindow.isPanel = true;
    [newWindow setCalculatedFrameOnScreen:_sebController.mainScreen];
    [newWindow setTitle:tempWindowTitle];
    
    // Create custom WebPreferences with bugfix for local storage not persisting application quit/start
    [self setCustomWebPreferencesForWebView:_temporaryWebView];
    
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowWindowCapture"] == NO) {
        [newWindow setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
    }
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL elevateWindowLevels = ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"];
    // Order new browser window to the front of our level
    [self setLevelForBrowserWindow:newWindow elevateLevels:elevateWindowLevels];
    
    [self addBrowserWindow:(SEBBrowserWindow *)newWindow
               withWebView:_temporaryWebView
                 withTitle:tempWindowTitle];
    
    self.activeBrowserWindow = newWindow;
    [_temporaryBrowserWindowDocument.mainWindowController showWindow:self];
    [newWindow makeKeyAndOrderFront:self];
    
    // Try to download the SEB config file by opening it in the invisible WebView
    [self tryToDownloadConfigByOpeningURL:url];
}


// Try to download the config by opening the URL in the temporary browser window
- (void) tryToDownloadConfigByOpeningURL:(NSURL *)url
{
    DDLogInfo(@"Loading SEB config from URL %@ in temporary browser window.", [url absoluteString]);
    [[_temporaryWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
    
}


// Called by the browser webview delegate if loading the config URL failed
- (void) openingConfigURLFailed {
    DDLogDebug(@"%s", __FUNCTION__);
    
    // Close the temporary browser window if it was opened
    if (_temporaryWebView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            DDLogDebug(@"Closing temporary browser window in: %s", __FUNCTION__);
            [self closeWebView:self.temporaryWebView];
        });
    }
    
    [self openingConfigURLRoleBack];
    
    // Also reset the flag for SEB starting up
    _sebController.startingUp = false;
}


/// Performing the Download

// This method is called by the browser webview delegate if the file to download has a .seb extension
- (void) downloadSEBConfigFileFromURL:(NSURL *)url originalURL:(NSURL *)originalURL
{
    DDLogDebug(@"%s URL: %@", __FUNCTION__, url);
    
    startURLQueryParameter = [self.browserController startURLQueryParameter:&url];
    
    // OS X 10.9 and newer: Use modern NSURLSession for downloading .seb files which also allows handling
    // basic/digest/NTLM authentication without having to open a temporary webview
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_9) {
        if (!_URLSession) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            _URLSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        }
        NSURLSessionDataTask *downloadTask = [_URLSession dataTaskWithURL:url
                                                        completionHandler:^(NSData *sebFileData, NSURLResponse *response, NSError *error)
                                              {
                                                  [self didDownloadConfigData:sebFileData response:response error:error URL:url originalURL:originalURL];
                                              }];
        
        [downloadTask resume];
        
    } else {
        // OS X 10.7 and 10.8: Use NSURLConnection
        NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:url];
        [NSURLConnection sendAsynchronousRequest:downloadRequest
                                           queue:NSOperationQueue.mainQueue
                               completionHandler:^(NSURLResponse *response, NSData *sebFileData, NSError *error)
         {
             [self didDownloadConfigData:sebFileData response:response error:error URL:url originalURL:originalURL];
         }];
    }
}


- (void) didDownloadConfigData:(NSData *)sebFileData
                      response:(NSURLResponse *)response
                         error:(NSError *)error
                           URL:(NSURL *)url
                   originalURL:(NSURL *)originalURL
{
    DDLogDebug(@"%s URL: %@, error: %@", __FUNCTION__, url, error);
    
    if (error) {
        if (error.code == NSURLErrorCancelled) {
            // Only close temp browser window if this wasn't a direct download attempt
            if (!_directConfigDownloadAttempted) {
                // Close the temporary browser window
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self closeWebView:self.temporaryWebView];
                });
                [self openingConfigURLRoleBack];
                
            } else {
                _directConfigDownloadAttempted = false;
            }
            return;
        }
        if ([url.scheme isEqualToString:@"http"] && !_browserController.usingCustomURLProtocol) {
            // If it was a seb:// URL, and http failed, we try to download it by https
            NSURL *downloadURL = [url URLByReplacingScheme:@"https"];
            if (_directConfigDownloadAttempted) {
                [self downloadSEBConfigFileFromURL:downloadURL originalURL:originalURL];
            } else {
                [self tryToDownloadConfigByOpeningURL:downloadURL];
            }
        } else {
            if (_directConfigDownloadAttempted) {
                // If we tried a direct download first, now try to download it
                // by opening the URL in a temporary webview
                dispatch_async(dispatch_get_main_queue(), ^{
                    // which needs to be done on the main thread!
                    [self openTempWindowForDownloadingConfigFromURL:url originalURL:originalURL];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self downloadingSEBConfigFailed:error];
                });
            }
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self openDownloadedSEBConfigData:sebFileData fromURL:url originalURL:originalURL];
        });
    }
}


// NSURLSession download basic/digest/NTLM authentication challenge delegate
// Only called when downloading .seb files and only when running on OS X 10.9 or higher
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    DDLogInfo(@"URLSession: %@ task: %@ didReceiveChallenge: %@", session, task, challenge);
    
    // We accept any username/password authentication challenges.
    NSString *authenticationMethod = challenge.protectionSpace.authenticationMethod;
    
    if ([authenticationMethod isEqual:NSURLAuthenticationMethodHTTPBasic] ||
        [authenticationMethod isEqual:NSURLAuthenticationMethodHTTPDigest] ||
        [authenticationMethod isEqual:NSURLAuthenticationMethodNTLM]) {
        DDLogInfo(@"URLSession didReceive HTTPBasic/HTTPDigest/NTLM challenge");
        // If we have credentials from a previous login to the server we're on, try these first
        // but not when the credentials are from a failed username/password attempt
        if (_enteredCredential &&!_pendingChallengeCompletionHandler) {
            completionHandler(NSURLSessionAuthChallengeUseCredential, _enteredCredential);
            // We reset the cached previously entered credentials, because subsequent
            // downloads in this session won't need authentication anymore
            _enteredCredential = nil;
        } else {
            // Allow to enter password 3 times
            if ([challenge previousFailureCount] < 3) {
                // Display authentication dialog
                _pendingChallengeCompletionHandler = completionHandler;
                
                NSString *text = [NSString stringWithFormat:@"%@://%@", challenge.protectionSpace.protocol, challenge.protectionSpace.host];
                if ([challenge previousFailureCount] == 0) {
                    text = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"To proceed, you must log in to", nil), text];
                    lastUsername = @"";
                } else {
                    text = [NSString stringWithFormat:NSLocalizedString(@"The user name or password you entered for %@ was incorrect. Make sure you’re entering them correctly, and then try again.", nil), text];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showEnterUsernamePasswordDialog:text
                                           modalForWindow:self.activeBrowserWindow
                                              windowTitle:NSLocalizedString(@"Authentication Required", nil)
                                                 username:self->lastUsername
                                            modalDelegate:self
                                           didEndSelector:@selector(enteredUsername:password:returnCode:)];
                });
                
            } else {
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
                // inform the user that the user name and password
                // in the preferences are incorrect
                
                [self openingConfigURLRoleBack];
            }
        }
    } else {
        DDLogInfo(@"URLSession didReceive other challenge (default handling)");
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, NULL);
    }
}


// Managing entered credentials for .seb file download
- (void)enteredUsername:(NSString *)username password:(NSString *)password returnCode:(NSInteger)returnCode
{
    DDLogDebug(@"Enter username password sheetDidEnd with return code: %ld", (long)returnCode);
    
    if (_pendingChallengeCompletionHandler) {
        if (returnCode == SEBEnterPasswordOK) {
            lastUsername = username;
            NSURLCredential *newCredential = [NSURLCredential credentialWithUser:username
                                                                        password:password
                                                                     persistence:NSURLCredentialPersistenceForSession];
            _pendingChallengeCompletionHandler(NSURLSessionAuthChallengeUseCredential, newCredential);
            
            _enteredCredential = newCredential;
            return;
            
            // Authentication wasn't successful
        } else if (returnCode == SEBEnterPasswordCancel) {
            _pendingChallengeCompletionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            _enteredCredential = nil;
            _pendingChallengeCompletionHandler = nil;
        } else {
            // Any other case as when the server aborted the authentication challenge
            _enteredCredential = nil;
            _pendingChallengeCompletionHandler = nil;
        }
        [self openingConfigURLRoleBack];
    }
}


// Called when downloading the config file failed
- (void) downloadingSEBConfigFailed:(NSError *)error
{
    DDLogError(@"%s error: %@", __FUNCTION__, error);
    _sebController.openingSettings = false;
    
    // Only show the download error and close temp browser window if this wasn't a direct download attempt
    if (!_directConfigDownloadAttempted) {
        
        // Close the temporary browser window
        [self closeWebView:_temporaryWebView];
        // Show the load error
        [self.mainBrowserWindow presentError:error modalForWindow:self.mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
        [self openingConfigURLRoleBack];
    }
}


// Called when SEB successfully downloaded the config file
- (void) openDownloadedSEBConfigData:(NSData *)sebFileData fromURL:(NSURL *)url originalURL:(NSURL *)originalURL
{
    DDLogDebug(@"%s URL: %@", __FUNCTION__, url);
    
    // Close the temporary browser window
    [self closeWebView:_temporaryWebView];
    
    if (_sebController.startingUp || [self isReconfiguringAllowedFromURL:originalURL ? originalURL : url]) {
        _sebController.openingSettings = true;
        SEBOSXConfigFileController *configFileController = [[SEBOSXConfigFileController alloc] init];
        configFileController.sebController = self.sebController;
        
        if (examSessionCookiesAlreadyCleared == NO) {
            if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_examSessionClearCookiesOnEnd"] == YES) {
                // Empties all cookies, caches and credential stores, removes disk files, flushes in-progress
                // downloads to disk, and ensures that future requests occur on a new socket.
                // OS X 10.9 and newer
                if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_9) {
                    [[NSURLSession sharedSession] resetWithCompletionHandler:^{
                        DDLogInfo(@"Cookies, caches and credential stores were reset when ending browser session (examSessionClearCookiesOnEnd = false)");
                    }];
                } else {
                    DDLogError(@"Cannot reset cookies, caches and credential stores (when ending browser session) because of running on OS X 10.7 or 10.8.");
                }
            }
            // Set the flag for cookies cleared (either they actually were or they would have
            // been settings prevented it)
            examSessionCookiesAlreadyCleared = YES;
        }
        // Get current config path
        currentConfigPath = [[MyGlobals sharedMyGlobals] currentConfigURL];
        // Store the URL of the .seb file as current config file path
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:[NSURL URLWithString:url.lastPathComponent]]; // absoluteString]];
        
        downloadedSEBConfigDataURL = url;
        
        // Reset the pending challenge in case it was an authenticated load
        _pendingChallengeCompletionHandler = nil;
        
        [configFileController storeNewSEBSettings:sebFileData
                                    forEditing:NO
                                      callback:self
                                      selector:@selector(storeNewSEBSettingsSuccessful:)];
        
    } else {
        // Opening downloaded SEB config data definitely failed:
        // we might need to quit (if SEB was just started)
        // or reset the opening settings flag which prevents opening URLs concurrently
        [self openingConfigURLRoleBack];
    }
}


- (void) storeNewSEBSettingsSuccessful:(NSError *)error
{
    if (!error) {
        DDLogInfo(@"Storing downloaded SEB config data was successful");
        
        // Reset the direct download flag for the case this was a successful direct download
        _directConfigDownloadAttempted = false;
        
        [[NSUserDefaults standardUserDefaults] setSecureString:startURLQueryParameter forKey:@"org_safeexambrowser_startURLQueryParameter"];

        // Reset BrowserController to force re-reading parameters like Browser Exam and Config Key
        // from changed settings even if SEB was started opening a new config
        _browserController = [SEBBrowserController new];
        _browserController.delegate = self;

        [_sebController didOpenSettings];
        
        return;
        
    } else {
        /// Decrypting new settings wasn't successfull:
        DDLogInfo(@"Decrypting downloaded SEB config data failed or data needs to be downloaded in a temporary WebView after the user performs web-based authentication.");
        
        // We have to restore the path to the old settings
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:currentConfigPath];
        
        // Was this an attempt to download the config directly and the downloaded data was corrupted?
        if (_directConfigDownloadAttempted && error.code == SEBErrorNoValidConfigData) {
            // We try to download the config in a temporary WebView
            DDLogInfo(@"Trying to download the config in a temporary WebView");
            [self openConfigFromSEBURL:downloadedSEBConfigDataURL];
            
            return;
        } else {
            // The download failed definitely or was canceled by the user:
            DDLogError(@"Decrypting downloaded SEB config data failed definitely, present error and role back opening URL!");
            
            // Reset the direct download flag for the case this was a successful direct download
            _directConfigDownloadAttempted = false;
            
            // Opening downloaded SEB config data definitely failed:
            if (self.mainBrowserWindow) {
                [self.mainBrowserWindow presentError:error modalForWindow:self.mainBrowserWindow delegate:self didPresentSelector:@selector(didPresentErrorWithRecovery:contextInfo:) contextInfo:NULL];
                return;
            } else if (!(_sebController.isAACEnabled && _sebController.wasAACEnabled)) {
                [NSApp presentError:error];
            }
            // we might need to quit (if SEB was just started)
            // or reset the opening settings flag which prevents opening URLs concurrently
            [self openingConfigURLRoleBack];
        }
    }
}

- (void)didPresentErrorWithRecovery:(BOOL)didRecover
   contextInfo:(void *)contextInfo
{
    // we might need to quit (if SEB was just started)
    // or reset the opening settings flag which prevents opening URLs concurrently
    [self openingConfigURLRoleBack];
}


- (void)closeOpeningConfigFileDialog {
    //TODO: not yet used on macOS
}


- (void)sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task {
    //TODO: not yet used on macOS
}


- (void)showOpeningConfigFileDialog:(NSString *)text title:(NSString *)title cancelCallback:(id)callback selector:(SEL)selector {
    //TODO: not yet used on macOS
}


- (void)storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
      showReconfiguredAlert:(BOOL)showReconfiguredAlert
                   callback:(id)callback
                   selector:(SEL)selector
{
    [self.sebController storeNewSEBSettings:sebData
                                 forEditing:forEditing
                     forceConfiguringClient:forceConfiguringClient
                      showReconfiguredAlert:showReconfiguredAlert
                                   callback:callback
                                   selector:selector];
}


- (void) openingConfigURLRoleBack
{
    // If SEB was just started (by opening a seb(s) link)
    if (_sebController.startingUp) {
        // we quit, as decrypting the config wasn't successful
        DDLogError(@"%s: SEB is starting up and opening a config link wasn't successfull, SEB will be terminated!", __FUNCTION__);
        _sebController.quittingMyself = true; // quit SEB without asking for confirmation or password
        [NSApp terminate: nil]; // Quit SEB
    }
    // Reset the opening settings flag which prevents opening URLs concurrently
    _sebController.openingSettings = false;
}


#pragma mark SEB Dock Buttons Action Methods

- (void) backToStartCommand
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    [self clearBackForwardList];
    
    // Close all browser windows (documents)
    [self closeAllAdditionalBrowserWindows];
    
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamUseStartURL"]) {
        // Load start URL from the system's user defaults
        NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
        DDLogInfo(@"Reloading Start URL in main browser window: %@", urlText);
        [self openURLString:urlText withSEBUserAgentInWebView:self.mainWebView];
    } else {
        NSString* restartExamURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamURL"];
        if (restartExamURL.length > 0) {
            // Load restart exam URL into the main browser window
            DDLogInfo(@"Reloading Restart Exam URL in main browser window: %@", restartExamURL);
            [self openURLString:restartExamURL withSEBUserAgentInWebView:self.mainWebView];
        }
    }
}


- (void) reloadCommand
{
    DDLogInfo(@"Reloading current browser window: %@", self.activeBrowserWindow);
    [self.activeBrowserWindow.webView reload:self.activeBrowserWindow];
}


@end
