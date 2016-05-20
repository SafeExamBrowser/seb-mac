//
//  SEBBrowserController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06/10/14.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBOSXBrowserController.h"
#import "SEBBrowserOpenWindowWebView.h"
#import "NSWindow+SEBWindow.h"
#import "WebKit+WebKitExtensions.h"
#import "SEBConfigFileManager.h"

#include "WebStorageManagerPrivate.h"
#include "WebPreferencesPrivate.h"
#import "WebPluginDatabase.h"

@implementation SEBOSXBrowserController


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.openBrowserWindowsWebViews = [NSMutableArray new];

        // Initialize SEB dock item menu for open browser windows/WebViews
        SEBDockItemMenu *dockMenu = [[SEBDockItemMenu alloc] initWithTitle:@""];
        self.openBrowserWindowsWebViewsMenu = dockMenu;
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
    
    if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserUserAgentMac"] == browserUserAgentModeMacDefault) {
        overrideUserAgent = [[MyGlobals sharedMyGlobals] valueForKey:@"defaultUserAgent"];
    } else {
        overrideUserAgent = [preferences secureStringForKey:@"org_safeexambrowser_SEB_browserUserAgentMacCustom"];
    }
    // Add "SEB <version number>" to the browser's user agent, so the LMS SEB plugins recognize us
    overrideUserAgent = [overrideUserAgent stringByAppendingString:[NSString stringWithFormat:@" %@/%@", SEBUserAgentDefaultSuffix, versionString]];
    [webView setCustomUserAgent:overrideUserAgent];
    
    DDLogDebug(@"Testing if WebStorageManager respondsToSelector:@selector(_storageDirectoryPath)");
    if ([WebStorageManager respondsToSelector: @selector(_storageDirectoryPath)]) {
        NSString* dbPath = [WebStorageManager _storageDirectoryPath];
        WebPreferences* prefs = [webView preferences];
        if (![prefs respondsToSelector:@selector(_localStorageDatabasePath)]) {
            DDLogError(@"WebPreferences did not respond to selector _localStorageDatabasePath. Local Storage won't be available!");
            return;
        }
        NSString* localDBPath = [prefs _localStorageDatabasePath];
        [prefs setAutosaves:YES];  //SET PREFS AUTOSAVE FIRST otherwise settings aren't saved.
        [prefs setWebGLEnabled:YES];
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_removeLocalStorage"]) {
            [prefs setLocalStorageEnabled:NO];
            
            [webView setPreferences:prefs];
        } else {
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
                //        [prefs setDeveloperExtrasEnabled:[[NSUserDefaults standardUserDefaults] boolForKey: @"developer"]];
#ifdef DEBUG
                [prefs setDeveloperExtrasEnabled:YES];
#endif
                [prefs _setLocalStorageDatabasePath:dbPath];
                [prefs setLocalStorageEnabled:YES];
                
                [webView setPreferences:prefs];
            } else {
                [prefs setLocalStorageEnabled:YES];
            }
        }
    } else {
        DDLogError(@"WebStorageManager did not respond to selector _storageDirectoryPath. Local Storage won't be available!");
    }
}


// Open a new web browser window document
- (SEBBrowserWindowDocument *) openBrowserWindowDocument
{
    SEBBrowserWindowDocument *browserWindowDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"DocumentType" display:YES];
    
    // Set the reference to the browser controller in the browser window controller instance
    browserWindowDocument.mainWindowController.browserController = self;
    
    // Set the reference to the browser controller in the browser window instance
    SEBBrowserWindow *newWindow = (SEBBrowserWindow *)browserWindowDocument.mainWindowController.window;
    newWindow.browserController = self;
    
    // Prevent that the browser window displays the button to make it fullscreen in OS X 10.11
    // and that it would allow to be used in split screen mode
    newWindow.collectionBehavior = NSWindowCollectionBehaviorStationary + NSWindowCollectionBehaviorFullScreenAuxiliary +NSWindowCollectionBehaviorFullScreenDisallowsTiling;
    
    // Enable or disable spell checking
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL allowSpellCheck = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowSpellCheck"];
    
//    NSTextView *textView = (NSTextView *)[newWindow firstResponder];
    [newWindow.webView setContinuousSpellCheckingEnabled:allowSpellCheck];
    
    return browserWindowDocument;
}


// Open a new WebView and show its window
- (SEBWebView *) openAndShowWebView
{
    SEBBrowserWindowDocument *browserWindowDocument = [self openBrowserWindowDocument];

    SEBBrowserWindow *newWindow = (SEBBrowserWindow *)browserWindowDocument.mainWindowController.window;
    SEBWebView *newWindowWebView = browserWindowDocument.mainWindowController.webView;
    newWindowWebView.creatingWebView = nil;

    // Create custom WebPreferences with bugfix for local storage not persisting application quit/start
    [self setCustomWebPreferencesForWebView:newWindowWebView];

    [self addBrowserWindow:(SEBBrowserWindow *)browserWindowDocument.mainWindowController.window
               withWebView:newWindowWebView
                 withTitle:NSLocalizedString(@"Untitled", @"Title of a new opened browser window; Untitled")];
    
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrintScreen"] == NO) {
        [browserWindowDocument.mainWindowController.window setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
    }
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL elevateWindowLevels = [preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"];
    // Order new browser window to the front of our level
    [self setLevelForBrowserWindow:browserWindowDocument.mainWindowController.window elevateLevels:elevateWindowLevels];
    self.activeBrowserWindow = newWindow;
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
        
        if (webViewToClose == _temporaryWebView) {
            _temporaryWebView = nil;
        }
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
    
    // Save current WebKit Cookie Policy
     NSHTTPCookieAcceptPolicy cookiePolicy = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookieAcceptPolicy];
     if (cookiePolicy == NSHTTPCookieAcceptPolicyAlways) DDLogInfo(@"NSHTTPCookieAcceptPolicyAlways");
     if (cookiePolicy == NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain) DDLogInfo(@"NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain");
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Preconfigure Window for full screen
    BOOL mainBrowserWindowShouldBeFullScreen = ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserViewMode"] == browserViewModeFullscreen);
    
    DDLogInfo(@"Open MainBrowserWindow with browserViewMode: %hhd", mainBrowserWindowShouldBeFullScreen);
    
    // Open and maximize the browser window
    // (this is done here, after presentation options are set,
    // because otherwise menu bar and dock are deducted from screen size)
    SEBBrowserWindowDocument *browserWindowDocument = [self openBrowserWindowDocument];
    
    self.webView = browserWindowDocument.mainWindowController.webView;
    self.webView.creatingWebView = nil;
    
    // Load start URL from the system's user defaults
    NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    
    // Create custom WebPreferences with bugfix for local storage not persisting application quit/start
    [self setCustomWebPreferencesForWebView:self.webView];
    
    self.mainBrowserWindow = (SEBBrowserWindow *)browserWindowDocument.mainWindowController.window;

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
    
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrintScreen"] == NO) {
        [self.mainBrowserWindow setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
    }
    [self.mainBrowserWindow setCalculatedFrame];
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"]) {
        [self.mainBrowserWindow newSetLevel:NSMainMenuWindowLevel+3];
    }
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    
    // Setup bindings to the preferences window close button
    NSButton *closeButton = [self.mainBrowserWindow standardWindowButton:NSWindowCloseButton];
    
    [closeButton bind:@"enabled"
             toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
          withKeyPath:@"values.org_safeexambrowser_SEB_allowQuit"
              options:nil];
    
    [self addBrowserWindow:self.mainBrowserWindow withWebView:self.webView withTitle:NSLocalizedString(@"Main Browser Window", nil)];
    
    [self.mainBrowserWindow makeMainWindow];
    [self.mainBrowserWindow makeKeyAndOrderFront:self];
    self.activeBrowserWindow = self.mainBrowserWindow;
    
    DDLogInfo(@"Open MainBrowserWindow with start URL: %@", urlText);
    
    [self openURLString:urlText withSEBUserAgentInWebView:self.webView];
}


- (void) clearBackForwardList
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    [self.mainBrowserWindow.webView setMaintainsBackForwardList:NO];
    [self.mainBrowserWindow.webView setMaintainsBackForwardList:[preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowBrowsingBackForward"]];
}


- (void) openURLString:(NSString *)urlText withSEBUserAgentInWebView:(SEBWebView *)webView
{
    // Load start URL into browser window
    [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlText]]];
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
- (void) allBrowserWindowsChangeLevel:(BOOL)allowApps
{
    NSArray *openWindowDocuments = [[NSDocumentController sharedDocumentController] documents];
    SEBBrowserWindowDocument *openWindowDocument;
    for (openWindowDocument in openWindowDocuments) {
        NSWindow *browserWindow = openWindowDocument.mainWindowController.window;
        [self setLevelForBrowserWindow:browserWindow elevateLevels:!allowApps];
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
    int levelOffset = (int)((SEBBrowserWindow *)browserWindow).isPanel;
    if (elevateLevels) {
        if (self.mainBrowserWindow.isFullScreen && browserWindow != self.mainBrowserWindow) {
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
    SEBBrowserWindowDocument *browserWindowDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"DocumentType" display:YES];
    NSWindow *additionalBrowserWindow = browserWindowDocument.mainWindowController.window;
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrintScreen"] == NO) {
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



//// Downloading of SEB Config Files

/// Initiating Opening the Config File Link

// Conditionally open a config from an URL passed to SEB as parameter
// usually with a link using the seb(s):// protocols
- (void) openConfigFromSEBURL:(NSURL *)url
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    // Check first if opening SEB config files is allowed in settings and if no other settings are currently being opened
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"] && !_temporaryWebView) {
        // Check if SEB is in exam mode = private UserDefauls are switched on
        if (NSUserDefaults.userDefaultsPrivate) {
            // If yes, we don't download the .seb file
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:NSLocalizedString(@"Loading New SEB Settings Not Allowed!", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"SEB is already running in exam mode and it is not allowed to interupt this by starting another exam. Finish the exam and quit SEB before starting another exam.", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            [newAlert runModal];
        } else {
            // SEB isn't in exam mode: reconfiguring it is allowed
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];

            // Download the .seb file directly into memory (not onto disc like other files)
            if ([url.scheme isEqualToString:@"seb"]) {
                // If it's a seb:// URL, we try to download it by http
                urlComponents.scheme = @"http";
                url = urlComponents.URL;
            } else if ([url.scheme isEqualToString:@"sebs"]) {
                // If it's a sebs:// URL, we try to download it by https
                urlComponents.scheme = @"https";
                url = urlComponents.URL;
            }
            [self openTempWindowForDownloadingConfigFromURL:url];
        }
    }
}


// Open a new, temporary browser window for downloading the linked config file
// This allows the user to authenticate if the link target is stored on a secured server
- (void) openTempWindowForDownloadingConfigFromURL:(NSURL *)url
{
    // Create a new WebView
    NSString *tempWindowTitle = NSLocalizedString(@"Opening SEB Link", @"Title of a temporary browser window for opening a SEB link");
    _temporaryBrowserWindowDocument = [self openBrowserWindowDocument];
    SEBBrowserWindow *newWindow = (SEBBrowserWindow *)_temporaryBrowserWindowDocument.mainWindowController.window;
    _temporaryWebView = _temporaryBrowserWindowDocument.mainWindowController.webView;
    _temporaryWebView.creatingWebView = nil;
    newWindow.isPanel = true;
    [newWindow setCalculatedFrame];
    [newWindow setTitle:tempWindowTitle];
    
    // Create custom WebPreferences with bugfix for local storage not persisting application quit/start
    [self setCustomWebPreferencesForWebView:_temporaryWebView];
    
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrintScreen"] == NO) {
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
    // Close the temporary browser window if it was opened
    if (_temporaryWebView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            DDLogDebug(@"Closing temporary browser window in: %s", __FUNCTION__);
            [self closeWebView:_temporaryWebView];
        });
    }
}


/// Performing the Download

// This method is called by the browser webview delegate if the file to download has a .seb extension
- (void) downloadSEBConfigFileFromURL:(NSURL *)url
{
    NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                          dataTaskWithURL:url completionHandler:^(NSData *sebFileData, NSURLResponse *response, NSError *error)
                                          {
                                              if (error) {
                                                  if ([url.scheme isEqualToString:@"http"]) {
                                                      NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
                                                          // If it was a seb:// URL, and http failed, we try to download it by https
                                                          urlComponents.scheme = @"https";
                                                          NSURL *downloadURL = urlComponents.URL;
                                                      [self tryToDownloadConfigByOpeningURL:downloadURL];
                                                  } else {
                                                      dispatch_async(dispatch_get_main_queue(), ^{
                                                          [self downloadingSEBConfigFailed:error];
                                                      });
                                                  }
                                              } else {
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [self openDownloadedSEBConfigData:sebFileData fromURL:url];
                                                  });
                                              }
                                          }];
    
    [downloadTask resume];
}


// Called when downloading the config file failed
- (void) downloadingSEBConfigFailed:(NSError *)error
{
    // Close the temporary browser window
    [self closeWebView:_temporaryWebView];
    
    [self.mainBrowserWindow presentError:error modalForWindow:self.mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
}


// Called when SEB successfully downloaded the config file
- (void) openDownloadedSEBConfigData:(NSData *)sebFileData fromURL:(NSURL *)url
{
    // Close the temporary browser window
    [self closeWebView:_temporaryWebView];
    
    SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
    
    // Get current config path
    NSURL *currentConfigPath = [[MyGlobals sharedMyGlobals] currentConfigURL];
    // Store the URL of the .seb file as current config file path
    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:[NSURL URLWithString:url.lastPathComponent]]; // absoluteString]];
    
    if ([configFileManager storeDecryptedSEBSettings:sebFileData forEditing:NO]) {
        
        // Post a notification that it was requested to restart SEB with changed settings
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestRestartNotification" object:self];
        
    } else {
        // if decrypting new settings wasn't successfull, we have to restore the path to the old settings
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:currentConfigPath];
    }
}


// Set web page title for a window/WebView
- (void) setTitle:(NSString *)title forWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBWebView *)webView
{
    for (SEBBrowserOpenWindowWebView *openWindowWebView in self.openBrowserWindowsWebViews) {
        if ([openWindowWebView.webView isEqualTo:webView]) {
            [openWindowWebView setTitle: title];
            [self.openBrowserWindowsWebViewsMenu setPopoverMenuSize];
        }
    }
    [self setStateForWindow:browserWindow withWebView:webView];
}


- (void) setStateForWindow:(SEBBrowserWindow *)browserWindow withWebView:(SEBWebView *)webView
{
    DDLogDebug(@"setStateForWindow: %@ withWebView: %@", browserWindow, webView);

    for (SEBBrowserOpenWindowWebView *openWindowWebView in self.openBrowserWindowsWebViews) {
        if ([openWindowWebView.webView isEqualTo:webView]) {
            [openWindowWebView setState:NSOnState];
            DDLogDebug(@"setState: NSOnState: %@", webView);
        } else {
            [openWindowWebView setState:NSOffState];
        }
    }
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
    
    int numberOfItems = self.openBrowserWindowsWebViews.count;

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


#pragma mark SEB Dock Buttons Action Methods

- (void) restartDockButtonPressed
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    [self clearBackForwardList];
    
    // Close all browser windows (documents)
    [self closeAllAdditionalBrowserWindows];
    
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamUseStartURL"]) {
        // Load start URL from the system's user defaults
        NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
        DDLogInfo(@"Reloading Start URL in main browser window: %@", urlText);
        [self openURLString:urlText withSEBUserAgentInWebView:self.webView];
    } else {
        NSString* restartExamURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamURL"];
        if (restartExamURL.length > 0) {
            // Load restart exam URL into the main browser window
            DDLogInfo(@"Reloading Restart Exam URL in main browser window: %@", restartExamURL);
            [self openURLString:restartExamURL withSEBUserAgentInWebView:self.webView];
        }
    }
}


- (void) reloadDockButtonPressed
{
    DDLogInfo(@"Reloading current browser window: %@", self.activeBrowserWindow);
    [self.activeBrowserWindow.webView reload:self.activeBrowserWindow];
}


@end
