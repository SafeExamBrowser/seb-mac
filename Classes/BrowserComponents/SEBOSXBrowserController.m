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
#import "NSWindow+SEBWindow.h"
#import "SEBWebViewController.h"
#import "SEBOSXConfigFileController.h"

#import "NSURL+SEBURL.h"
#import "NSScreen+SEBScreen.h"

@implementation SEBOSXBrowserController


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.delegate = self;

        self.openBrowserWindowsWebViews = [NSMutableArray new];

        // Initialize SEB dock item menu for open browser windows/WebViews
        SEBDockItemMenu *dockMenu = [[SEBDockItemMenu alloc] initWithTitle:@""];
        self.openBrowserWindowsWebViewsMenu = dockMenu;

        // Create a private pasteboard
        self.privatePasteboardItems = [NSArray array];
    }
    return self;
}


- (NSScreen *) mainScreen
{
    return _sebController.mainScreen;
}


- (void) closeWebView
{
    [self closeWebView:self.abstractWebView];
}


- (void) closeWebView:(SEBAbstractWebView *)webViewToClose
{
    if (webViewToClose) {
        // Remove the entry for the WebView in a browser window from the array and dock item menu of open browser windows/WebViews
        SEBBrowserWindow *windowToClose = (SEBBrowserWindow *)webViewToClose.window;
        [self removeBrowserWindowWithWebView:webViewToClose];
        
        // Get the document for the web view
        id myDocument = [[NSDocumentController sharedDocumentController] documentForWindow:windowToClose];
        
        // Close document and therefore also window
        DDLogInfo(@"Now closing new document browser window with WebView: %@", webViewToClose);
        
        [myDocument close];
        _activeBrowserWindow = nil;
        
        if (webViewToClose == self.temporaryWebView) {
            self.downloadingInTemporaryWebView = NO;
            self.temporaryWebView = nil;
        }
    }
}


// Called when SEB successfully downloaded the config file
- (void) openDownloadedSEBConfigData:(NSData *)sebFileData fromURL:(NSURL *)url originalURL:(NSURL *)originalURL
{
    DDLogDebug(@"%s URL: %@", __FUNCTION__, url);
    
    _sebController.openingSettings = true;
    SEBOSXConfigFileController *configFileController = [[SEBOSXConfigFileController alloc] init];
    configFileController.sebController = self.sebController;

    // Get current config path
    currentConfigPath = [[MyGlobals sharedMyGlobals] currentConfigURL];
    // Store the URL of the .seb file as current config file path
    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:[NSURL URLWithString:url.lastPathComponent]]; // absoluteString]];
        
    [configFileController storeNewSEBSettings:sebFileData
                                forEditing:NO
                                  callback:self
                                  selector:@selector(storeNewSEBSettingsSuccessful:)];
}


- (SEBAbstractWebView *)openTempWebViewForDownloadingConfigFromURL:(NSURL *)url originalURL:originalURL
{
    SEBAbstractWebView *tempWebView = [self openTempWindowForDownloadingConfigFromURL:url originalURL:originalURL];
    
    return tempWebView;
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


- (void)closeOpeningConfigFileDialog {
    //TODO: not yet used on macOS
}


- (void)sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task {
    //TODO: not yet used on macOS
}


@synthesize startingUp;

- (BOOL)isStartingUp {
    return _sebController.startingUp;
}

- (void)setStartingUp:(BOOL)startingUp {
    _sebController.startingUp = startingUp;
}


- (void) resetBrowser
{
    _activeBrowserWindow = nil;
    
    [self.openBrowserWindowsWebViews removeAllObjects];
    // Initialize SEB dock item menu for open browser windows/WebViews
    SEBDockItemMenu *dockMenu = [[SEBDockItemMenu alloc] initWithTitle:@""];
    self.openBrowserWindowsWebViewsMenu = dockMenu;
    
    self.currentMainHost = nil;
    
    [super resetBrowser];
}


// Save the default user agent of the installed WebKit version
- (void) createSEBUserAgentFromDefaultAgent:(NSString *)defaultUserAgent
{
    [SEBBrowserController createSEBUserAgentFromDefaultAgent:defaultUserAgent];
}


// Open a new WebView and show its window
- (SEBAbstractWebView *) openAndShowWebViewWithURL:(NSURL *)url
{
    return [self openAndShowWebViewWithURL:url title:NSLocalizedString(@"Untitled", @"Title of a new opened browser window; Untitled") overrideSpellCheck:NO mainBrowserWindow:NO temporaryWindow:NO];
}

// Open a new WebView and show its window
- (SEBAbstractWebView *) openAndShowWebViewWithURL:(NSURL *)url title:(NSString *)title overrideSpellCheck:(BOOL)overrideSpellCheck mainBrowserWindow:(BOOL)mainBrowserWindow temporaryWindow:(BOOL)temporaryWindow
{
    SEBBrowserWindow *newBrowserWindow = [self openBrowserWindowWithURL:url title:title overrideSpellCheck:overrideSpellCheck];
    SEBAbstractWebView *newWindowWebView = newBrowserWindow.webView;
    newBrowserWindow.browserControllerDelegate = newWindowWebView;
    
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowWindowCapture"] == NO) {
        [newBrowserWindow setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
    }
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL elevateWindowLevels = [preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    // Order new browser window to the front of our level
    [self setLevelForBrowserWindow:newBrowserWindow elevateLevels:elevateWindowLevels];
    self.activeBrowserWindow = newBrowserWindow;
    self.activeBrowserWindowTitle = NSLocalizedString(@"Untitled", nil);
    [newBrowserWindow setCalculatedFrameOnScreen:newBrowserWindow.screen mainBrowserWindow:mainBrowserWindow temporaryWindow:temporaryWindow];
    [newBrowserWindow.windowController showWindow:self];
    [newBrowserWindow makeKeyAndOrderFront:self];
    [self transferCookiesToWKWebViewWithCompletionHandler:^{
        [newWindowWebView loadURL:url];
    }];

    return newWindowWebView;
}


- (SEBBrowserWindow *) openBrowserWindowWithURL:(NSURL *)url title:(NSString *)title overrideSpellCheck:(BOOL)overrideSpellCheck
{
    SEBBrowserWindow *browserWindow = [self openBrowserWindow];
    
    SEBOSXWebViewController *newViewController;
    newViewController = [self createNewWebViewControllerWithCommonHost:[self browserWindowHasCommonHostWithURL:url] overrideSpellCheck:overrideSpellCheck delegate:browserWindow];

    SEBAbstractWebView *newWindowWebView = newViewController.sebAbstractWebView;
    newWindowWebView.creatingWebView = nil;
    browserWindow.webView = newWindowWebView;

    NSView *webView = newViewController.view;
    [browserWindow.contentView addSubview:webView];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [webView.leadingAnchor constraintEqualToAnchor:browserWindow.contentView.leadingAnchor].active = YES;
    [webView.trailingAnchor constraintEqualToAnchor:browserWindow.contentView.trailingAnchor].active = YES;
    [webView.topAnchor constraintEqualToAnchor:browserWindow.contentView.topAnchor].active = YES;
    [webView.bottomAnchor constraintEqualToAnchor:browserWindow.contentView.bottomAnchor].active = YES;
    
    [self addBrowserWindow:(SEBBrowserWindow *)browserWindow
               withWebView:newWindowWebView
                 withTitle:title];
    return browserWindow;
}


// Open a new web browser window document and window
- (SEBBrowserWindow *) openBrowserWindow
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
        //    NSTextView *textView = (NSTextView *)[newWindow firstResponder];
        return newWindow;
    }
    return nil;
}


// Create a NSViewController with a SEBAbstractWebView to hold new webpages
- (SEBOSXWebViewController *) createNewWebViewControllerWithCommonHost:(BOOL)commonHostTab overrideSpellCheck:(BOOL)overrideSpellCheck delegate:(nonnull id<SEBAbstractWebViewNavigationDelegate>)delegate {
    SEBOSXWebViewController *newSEBWebViewController = [[SEBOSXWebViewController alloc] initNewTabWithCommonHost:commonHostTab overrideSpellCheck:overrideSpellCheck delegate:delegate];
    return newSEBWebViewController;
}


- (void) checkForClosingTemporaryWebView:(SEBAbstractWebView *) webViewToClose
{
    DDLogDebug(@"%s", __FUNCTION__);
    if (webViewToClose == self.temporaryWebView) {
        self.downloadingInTemporaryWebView = NO;
        [self openingConfigURLRoleBack];
    }
}


// Show new window containing webView
- (void) webViewShow:(SEBAbstractWebView *)sender
{
    SEBBrowserWindowDocument *browserWindowDocument = [[NSDocumentController sharedDocumentController] documentForWindow:[sender window]];
    [browserWindowDocument showWindows];
    DDLogInfo(@"Now showing new document browser window for: %@",sender);
}


// Set up SEB Browser and open the main window
- (void) openMainBrowserWindow
{
    // Load start URL from the system's user defaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *urlString = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    
    // Handle Start URL Query String Parameter
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_startURLAppendQueryParameter"]) {
        NSString *queryString = [preferences secureStringForKey:@"org_safeexambrowser_startURLQueryParameter"];
        if (queryString.length > 0) {
            urlString = [NSString stringWithFormat:@"%@?%@", urlString, queryString];
        }
    }
    NSURL *startURL = [NSURL URLWithString:urlString];
    [self openMainBrowserWindowWithStartURL:startURL];
}


- (void) openMainBrowserWindowWithStartURL:(NSURL *)startURL
{
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
    DDLogInfo(@"Open MainBrowserWindow with start URL: %@", startURL.absoluteString);
    SEBAbstractWebView *newBrowserWindowWebView = [self openAndShowWebViewWithURL:startURL title:NSLocalizedString(@"Main Browser Window", nil) overrideSpellCheck:NO mainBrowserWindow:YES temporaryWindow:NO];
    SEBBrowserWindow *newBrowserWindow = newBrowserWindowWebView.window;

    self.mainBrowserWindow = newBrowserWindow;
    self.mainWebView = newBrowserWindowWebView;
    self.mainWebView.creatingWebView = nil;
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
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    
    // Setup bindings to the preferences window close button
    NSButton *closeButton = [self.mainBrowserWindow standardWindowButton:NSWindowCloseButton];
    
    [closeButton bind:@"enabled"
             toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
          withKeyPath:@"values.org_safeexambrowser_SEB_allowQuit"
              options:nil];
    
    
    [self.mainBrowserWindow makeMainWindow];
    [self.mainBrowserWindow makeKeyAndOrderFront:self];
//    self.activeBrowserWindow = self.mainBrowserWindow;
}


- (void) openURLString:(NSString *)urlText withSEBUserAgentInWebView:(SEBAbstractWebView *)webView
{
    // Load start URL into browser window
    [webView loadURL:[NSURL URLWithString:urlText]];
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
        [((SEBBrowserWindow *)browserWindowDocument.mainWindowController.window).webView loadURL:[NSURL URLWithString:URL]];
    }
}


// Set web page title for a window/WebView
- (void) setTitle:(NSString *)title forWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBAbstractWebView *)webView
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
- (void) setStateForWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBAbstractWebView *)webView
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
- (void) addBrowserWindow:(SEBBrowserWindow *)newBrowserWindow withWebView:(SEBAbstractWebView *)newWebView withTitle:(NSString *)newTitle
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
- (void) removeBrowserWindowWithWebView:(SEBAbstractWebView *)webView
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


- (BOOL) browserWindowHasCommonHostWithURL:(NSURL *)url
{
    BOOL commonHost = YES;
    if (self.openBrowserWindowsWebViews.count > 0) {
        commonHost = [self.openBrowserWindowsWebViews[0].webView.url.host isEqualToString:url.host];
    }
    return commonHost;
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
    [_sebController showEnterUsernamePasswordDialog:[[NSAttributedString alloc] initWithString:text] modalForWindow:window windowTitle:title username:username modalDelegate:modalDelegate didEndSelector:didEndSelector];
}


#pragma mark SEBBrowserControllerDelegate Methods

- (void) showEnterUsernamePasswordDialog:(NSString *)text
                                   title:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector
{
    [_sebController showEnterUsernamePasswordDialog:[[NSAttributedString alloc] initWithString:text] modalForWindow:self.activeBrowserWindow windowTitle:title username:username modalDelegate:modalDelegate didEndSelector:didEndSelector];
}


- (void) hideEnterUsernamePasswordDialog
{
    [_sebController hideEnterUsernamePasswordDialog];
    
    // If a temporary webview for loading config is open, close it
    [self openingConfigURLFailed];
}


- (void)showOpeningConfigFileDialog:(NSString *)text title:(NSString *)title cancelCallback:(id)callback selector:(SEL)selector {
}


- (BOOL) isMainBrowserWebViewActive
{
    return (_mainBrowserWindow == nil || _activeBrowserWindow == _mainBrowserWindow);
}



// Delegate method which returns URL or placeholder text (in case settings
// don't allow to display its URL) for active browser window
- (NSString *) placeholderTitleOrURLForActiveWebpage
{
    NSString *placeholderOrURLString = nil;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([self isMainBrowserWebViewActive]) {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowShowURL"] == browserWindowShowURLNever) {
            placeholderOrURLString = NSLocalizedString(@"the exam page", nil);
        } else {
            placeholderOrURLString = _activeBrowserWindow.webView.url.absoluteString;
        }
    } else {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowShowURL"] == browserWindowShowURLNever) {
            placeholderOrURLString = NSLocalizedString(@"the webpage", nil);
        } else {
            placeholderOrURLString = _activeBrowserWindow.webView.url.absoluteString;
        }
    }
    return placeholderOrURLString;
}


#pragma mark Downloading SEB Config Files

// Check if SEB is in exam mode = private UserDefauls are switched on:
// Then opening a new config file/reconfiguring SEB isn't allowed
- (BOOL) isReconfiguringAllowedFromURL:(NSURL *)url
{
    if (![super isReconfiguringAllowedFromURL:url]) {
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

// Open a new, temporary browser window for downloading the linked config file
// This allows the user to authenticate if the link target is stored on a secured server
- (SEBAbstractWebView *) openTempWindowForDownloadingConfigFromURL:(NSURL *)url originalURL:(NSURL *)originalURL
{
    DDLogDebug(@"[SEBOSXBrowserController openTempWindowForDownloadingConfigFromURL: %@ originalURL: %@]", url, originalURL);
    
    // Create a new WebView
    NSString *tempWindowTitle = NSLocalizedString(@"Opening SEB Config", @"Title of a temporary browser window for opening a SEB link");
    SEBAbstractWebView *temporaryWebView = [self openAndShowWebViewWithURL:url title:tempWindowTitle overrideSpellCheck:YES mainBrowserWindow:NO temporaryWindow:YES];
    SEBBrowserWindow *temporaryBrowserWindow = temporaryWebView.window;

    if (_sebController.startingUp) {
        temporaryWebView.creatingWebView = temporaryWebView;
    } else {
        temporaryWebView.creatingWebView = nil;
    }
    temporaryWebView.originalURL = originalURL;
    
    temporaryBrowserWindow.isPanel = true;
    [temporaryBrowserWindow setTitle:tempWindowTitle];
    
    return temporaryWebView;
}


// Try to download the config by opening the URL in the temporary browser window
- (void) tryToDownloadConfigByOpeningURL:(NSURL *)url
{
    DDLogInfo(@"Loading SEB config from URL %@ in temporary browser window.", [url absoluteString]);
    [self.temporaryWebView loadURL:url];
    
}


// Called when downloading the config file failed
- (void) downloadingSEBConfigFailed:(NSError *)error
{
    DDLogError(@"%s error: %@", __FUNCTION__, error);
    _sebController.openingSettings = false;
    // Also reset the flag for SEB starting up
    _sebController.startingUp = false;

    // Only show the download error and close temp browser window if this wasn't a direct download attempt
    if (!self.directConfigDownloadAttempted) {
        
        // Close the temporary browser window
        [self closeWebView:self.temporaryWebView];
        // Show the load error
        [self.mainBrowserWindow presentError:error modalForWindow:self.mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
        [self openingConfigURLRoleBack];
    }
}


- (void) storeNewSEBSettingsSuccessfulProceed:(NSError *)error
{
    if (!error) {
        [_sebController didOpenSettings];
        
        return;
        
    } else {
        // Decrypting new settings wasn't successfull:
        // We have to restore the path to the old settings
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:currentConfigPath];
        
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

- (void)didPresentErrorWithRecovery:(BOOL)didRecover
   contextInfo:(void *)contextInfo
{
    // we might need to quit (if SEB was just started)
    // or reset the opening settings flag which prevents opening URLs concurrently
    [self openingConfigURLRoleBack];
}


- (void)storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
      showReconfiguredAlert:(BOOL)showReconfiguredAlert
                   callback:(id)callback
                   selector:(SEL)selector
{
    [self.sebController storeNewSEBSettings:sebData forEditing:forEditing forceConfiguringClient:forceConfiguringClient showReconfiguredAlert:showReconfiguredAlert callback:callback selector:selector];
}


- (void) presentAlertWithTitle:(NSString *)title
                       message:(NSString *)message
{
    NSAlert *modalAlert = [self.sebController newAlert];
    // Inform user that download succeeded
    [modalAlert setMessageText:title];
    [modalAlert setInformativeText:message];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [modalAlert setAlertStyle:NSInformationalAlertStyle];
    void (^alertOKHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
        [self.sebController removeAlertWindow:modalAlert.window];
    };
    [self.sebController runModalAlert:modalAlert conditionallyForWindow:self.activeBrowserWindow completionHandler:(void (^)(NSModalResponse answer))alertOKHandler];

}


- (void) presentDownloadError:(NSError *)error
{
    [self.mainBrowserWindow presentError:error modalForWindow:self.mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
}


#pragma mark SEB Dock Buttons Action Methods

- (void) backToStartCommand
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
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
    [self.activeBrowserWindow.browserControllerDelegate reload];
}


#pragma mark - SEBAbstractBrowserControllerDelegate Methods

- (void) privateCopy:(id)sender
{
    [self.activeBrowserWindow privateCopy:sender];
}

- (void) privateCut:(id)sender
{
    [self.activeBrowserWindow privateCut:sender];
}

- (void) privatePaste:(id)sender
{
    [self.activeBrowserWindow privatePaste:sender];
}

- (void) clearPrivatePasteboard
{
    self.privatePasteboardItems = [NSArray array];
}


#pragma mark SEBAbstractWebViewNavigationDelegate Methods

- (void)examineCookies:(nonnull NSArray<NSHTTPCookie *> *)cookies
{
    [self.sebController examineCookies:cookies];
}

- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url
{
    [self.sebController shouldStartLoadFormSubmittedURL:url];
}


- (void)setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward {
    // Would be used if SEB for macOS would support back/forward buttons in the Dock
}


- (void)setLoading:(BOOL)loading {
    // Would be used if SEB for macOS would support a global "loading" indicator
}


- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
{
    return [self openNewWebViewWindowWithURL:url];
}

- (SEBAbstractWebView *) openNewWebViewWindowWithURL:(NSURL *)url
{
    return [self openAndShowWebViewWithURL:url];
}


- (void) showWebView:(SEBAbstractWebView *)webView
{
    [self webViewShow:webView];
}


@end
