//
//  SEBBrowserController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06/10/14.
//
//

#import "SEBBrowserController.h"
#import "SEBBrowserWindowDocument.h"
#import "SEBBrowserOpenWindowWebView.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "NSWindow+SEBWindow.h"
#import "SEBConfigFileManager.h"
#import "MyGlobals.h"
#import "Constants.h"

@implementation SEBBrowserController


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


// Open a new web browser window document
- (SEBBrowserWindowDocument *) openBrowserWindowDocument
{
    SEBBrowserWindowDocument *browserWindowDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"DocumentType" display:YES];
    
    // Set the reference to the browser controller in the browser window controller instance
    browserWindowDocument.mainWindowController.browserController = self;
    
    // Set the reference to the browser controller in the browser window instance
    SEBBrowserWindow *newWindow = (SEBBrowserWindow *)browserWindowDocument.mainWindowController.window;
    newWindow.browserController = self;
    
    return browserWindowDocument;
}


// Open a new WebView
- (WebView *) openWebView
{
    SEBBrowserWindowDocument *browserWindowDocument = [self openBrowserWindowDocument];

    SEBBrowserWindow *newWindow = (SEBBrowserWindow *)browserWindowDocument.mainWindowController.window;
    WebView *newWindowWebView = browserWindowDocument.mainWindowController.webView;

    // Add the title to the SEB dock item menu with open webpages
    [self addBrowserWindow:(SEBBrowserWindow *)browserWindowDocument.mainWindowController.window
               withWebView:newWindowWebView
                 withTitle:NSLocalizedString(@"Untitled", @"Title of a new opened browser window; Untitled")];
    
    [newWindow makeKeyAndOrderFront:self];
    
    return newWindowWebView;
}

// Open a new WebView and show its window
- (WebView *) openAndShowWebView
{
    SEBBrowserWindowDocument *browserWindowDocument = [self openBrowserWindowDocument];

    SEBBrowserWindow *newWindow = (SEBBrowserWindow *)browserWindowDocument.mainWindowController.window;
    WebView *newWindowWebView = browserWindowDocument.mainWindowController.webView;
    
    [self addBrowserWindow:(SEBBrowserWindow *)browserWindowDocument.mainWindowController.window
               withWebView:browserWindowDocument.mainWindowController.webView
                 withTitle:NSLocalizedString(@"Untitled", @"Title of a new opened browser window; Untitled")];
    
    [browserWindowDocument.mainWindowController.window setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"]) {
        // Order new browser window to the front of our level
        [browserWindowDocument.mainWindowController.window newSetLevel:NSModalPanelWindowLevel];
        [browserWindowDocument.mainWindowController showWindow:self];
    }
    [newWindow makeKeyAndOrderFront:self];
    
    return newWindowWebView;
}


- (void) closeWebView:(WebView *) webViewToClose
{
    // Remove the entry for the WebView in a browser window from the array and dock item menu of open browser windows/WebViews
    [self removeBrowserWindow:(SEBBrowserWindow *)webViewToClose.window withWebView:webViewToClose];
    
    // Get the document for the web view
    id myDocument = [[NSDocumentController sharedDocumentController] documentForWindow:webViewToClose.window];
    // Close document and therefore also window
#ifdef DEBUG
    NSLog(@"Now closing new document browser window. %@", webViewToClose);
#endif
    [myDocument close];
}


// Show new window containing webView
- (void) webViewShow:(WebView *)sender
{
    SEBBrowserWindowDocument *browserWindowDocument = [[NSDocumentController sharedDocumentController] documentForWindow:[sender window]];
    [[sender window] setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"]) {
        [[sender window] newSetLevel:NSModalPanelWindowLevel];
    }
    [browserWindowDocument showWindows];
#ifdef DEBUG
    NSLog(@"Now showing new document browser window for: %@",sender);
#endif
    // Order new browser window to the front
    //[[sender window] makeKeyAndOrderFront:self];
}


// Set up SEB Browser and open the main window
- (void) openMainBrowserWindow {
    
    /*/ Save current WebKit Cookie Policy
     NSHTTPCookieAcceptPolicy cookiePolicy = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookieAcceptPolicy];
     if (cookiePolicy == NSHTTPCookieAcceptPolicyAlways) NSLog(@"NSHTTPCookieAcceptPolicyAlways");
     if (cookiePolicy == NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain) NSLog(@"NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain"); */
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Preconfigure Window for full screen
    BOOL mainBrowserWindowShouldBeFullScreen = ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserViewMode"] == browserViewModeFullscreen);
    
#ifdef DEBUG
    NSLog(@"openMainBrowserWindow with browserViewMode: %hhd", mainBrowserWindowShouldBeFullScreen);
#endif
    
    // Open and maximize the browser window
    // (this is done here, after presentation options are set,
    // because otherwise menu bar and dock are deducted from screen size)
    SEBBrowserWindowDocument *browserWindowDocument = [self openBrowserWindowDocument];
    
    self.webView = browserWindowDocument.mainWindowController.webView;

    self.mainBrowserWindow = (SEBBrowserWindow *)browserWindowDocument.mainWindowController.window;

    // Check if the active screen (where the window is opened) changed in between opening dock
    if (self.mainBrowserWindow.screen != self.dockController.window.screen) {
        // Post a notification that the main screen changed
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"mainScreenChanged" object:self];
    }

    // Set the flag indicating if the main browser window should be displayed full screen
    self.mainBrowserWindow.isFullScreen = mainBrowserWindowShouldBeFullScreen;
    
    if (mainBrowserWindowShouldBeFullScreen) {
        [self.mainBrowserWindow setToolbar:nil];
        [self.mainBrowserWindow setStyleMask:NSBorderlessWindowMask];
    }
    
    [self.mainBrowserWindow setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
    [self.mainBrowserWindow setCalculatedFrame];
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"]) {
        [self.mainBrowserWindow newSetLevel:NSModalPanelWindowLevel];
        
    }
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    
    // Setup bindings to the preferences window close button
    NSButton *closeButton = [self.mainBrowserWindow standardWindowButton:NSWindowCloseButton];
    
    [closeButton bind:@"enabled"
             toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
          withKeyPath:@"values.org_safeexambrowser_SEB_allowQuit"
              options:nil];
    
    [self addBrowserWindow:self.mainBrowserWindow withWebView:self.webView withTitle:NSLocalizedString(@"Main Browser Window", nil)];
    
    //[self.browserWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    [self.mainBrowserWindow makeKeyAndOrderFront:self];
    
    // Load start URL from the system's user defaults database
    NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
#ifdef DEBUG
    NSLog(@"Open MainBrowserWindow with start URL: %@", urlText);
#endif
    
    // Add "SEB" to the browser's user agent, so the LMS SEB plugins recognize us
    NSString *customUserAgent = [self.webView userAgentForURL:[NSURL URLWithString:urlText]];
    [self.webView setCustomUserAgent:[customUserAgent stringByAppendingString:@" Safari/533.16 SEB"]];
//    [self.webView setCustomUserAgent:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/600.1.17 (KHTML, like Gecko) Safari/533.16 SEB"];
    
    // Load start URL into browser window
    [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlText]]];
}


// Adjust the size of the main browser window and bring it forward
- (void) adjustMainBrowserWindow
{
    [self.mainBrowserWindow setCalculatedFrame];
    [self.mainBrowserWindow makeKeyAndOrderFront:self];
}


// Change window level of all open browser windows
- (void) allBrowserWindowsChangeLevel:(BOOL)allowApps
{
    NSArray *openWindowDocuments = [[NSDocumentController sharedDocumentController] documents];
    SEBBrowserWindowDocument *openWindowDocument;
    for (openWindowDocument in openWindowDocuments) {
        NSWindow *browserWindow = openWindowDocument.mainWindowController.window;
        if (allowApps) {
            // Order new browser window to the front of our level
            [browserWindow newSetLevel:NSNormalWindowLevel];
            [browserWindow orderFront:self];
        } else {
            [browserWindow newSetLevel:NSModalPanelWindowLevel];
        }
    }
    // If the main browser window is displayed fullscreen and switching to apps is allowed,
    // we make the window stationary, so that it isn't scaled down from Exposé
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"] && self.mainBrowserWindow.isFullScreen) {
        self.mainBrowserWindow.collectionBehavior = NSWindowCollectionBehaviorStationary;
    }

    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [self.mainBrowserWindow
     makeKeyAndOrderFront:self];
}


// Open an allowed additional resource in a new browser window
- (void)openResourceWithURL:(NSString *)URL andTitle:(NSString *)title
{
    SEBBrowserWindowDocument *browserWindowDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"DocumentType" display:YES];
    NSWindow *additionalBrowserWindow = browserWindowDocument.mainWindowController.window;
    [additionalBrowserWindow setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
    [(SEBBrowserWindow *)additionalBrowserWindow setCalculatedFrame];
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"]) {
        [additionalBrowserWindow newSetLevel:NSModalPanelWindowLevel];
    }
    //	[NSApp activateIgnoringOtherApps: YES];
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    
    //[additionalBrowserWindow makeKeyAndOrderFront:self];
    
#ifdef DEBUG
    NSLog(@"Open additional browser window with URL: %@", URL);
#endif
    
    // Load start URL into browser window
    [[browserWindowDocument.mainWindowController.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URL]]];
}


- (void) downloadAndOpenSebConfigFromURL:(NSURL *)url
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
        // Check if SEB is in exam mode = private UserDefauls are switched on
        if (NSUserDefaults.userDefaultsPrivate) {
            // If yes, we don't download the .seb file
            NSRunAlertPanel(NSLocalizedString(@"Loading new SEB settings not allowed!", nil),
                            NSLocalizedString(@"SEB is already running in exam mode and it is not allowed to interupt this by starting another exam. Finish the exam and quit SEB before starting another exam.", nil),
                            NSLocalizedString(@"OK", nil), nil, nil);
        } else {
            // SEB isn't in exam mode: reconfiguring it is allowed
            NSError *error = nil;
            NSData *sebFileData;
            // Download the .seb file directly into memory (not onto disc like other files)
            if ([url.scheme isEqualToString:@"seb"]) {
                // If it's a seb:// URL, we try to download it by http
                NSURL *httpURL = [[NSURL alloc] initWithScheme:@"http" host:url.host path:url.path];
                sebFileData = [NSData dataWithContentsOfURL:httpURL options:NSDataReadingUncached error:&error];
                if (error) {
                    // If that didn't work, we try to download it by https
                    NSURL *httpsURL = [[NSURL alloc] initWithScheme:@"https" host:url.host path:url.path];
                    sebFileData = [NSData dataWithContentsOfURL:httpsURL options:NSDataReadingUncached error:&error];
                    // Still couldn't download the .seb file: present an error and abort
                    if (error) {
                        [self.mainBrowserWindow presentError:error modalForWindow:self.mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
                        return;
                    }
                }
            } else {
                sebFileData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
                if (error) {
                    [self.mainBrowserWindow presentError:error modalForWindow:self.mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
                }
            }
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
    }
}


// Set web page title for a window/WebView
- (void) setTitle:(NSString *)title forWindow:(SEBBrowserWindow *)browserWindow withWebView:(WebView *)webView
{
    for (SEBBrowserOpenWindowWebView *openWindowWebView in self.openBrowserWindowsWebViews) {
        if ([openWindowWebView.webView isEqualTo:webView]) {
            [openWindowWebView setTitle: title];
            [self.openBrowserWindowsWebViewsMenu setPopoverMenuSize];
        }
    }
    [self setStateForWindow:browserWindow withWebView:webView];
}


- (void) setStateForWindow:(SEBBrowserWindow *)browserWindow withWebView:(WebView *)webView
{
#ifdef DEBUG
    NSLog(@"setStateForWindow: %@ withWebView: %@", browserWindow, webView);
#endif
    for (SEBBrowserOpenWindowWebView *openWindowWebView in self.openBrowserWindowsWebViews) {
        if ([openWindowWebView.webView isEqualTo:webView]) {
            [openWindowWebView setState:NSOnState];
#ifdef DEBUG
            NSLog(@"setState: NSOnState: %@", webView);
#endif
        } else {
            [openWindowWebView setState:NSOffState];
        }
    }
}


// Add an entry for a WebView in a browser window into the array and dock item menu of open browser windows/WebViews
- (void) addBrowserWindow:(SEBBrowserWindow *)newBrowserWindow withWebView:(WebView *)newWebView withTitle:(NSString *)newTitle
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
- (void) removeBrowserWindow:(SEBBrowserWindow *)browserWindow withWebView:(WebView *)webView
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
#ifdef DEBUG
    NSLog(@"Selected menu item: %@", sender);
#endif
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [sender.browserWindow makeKeyAndOrderFront:self];
}

@end
