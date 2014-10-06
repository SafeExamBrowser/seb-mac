//
//  SEBBrowserController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06/10/14.
//
//

#import "SEBBrowserController.h"
#import "SEBBrowserWindowDocument.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "NSWindow+SEBWindow.h"
#import "SEBConfigFileManager.h"
#import "MyGlobals.h"
#import "Constants.h"

@implementation SEBBrowserController


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
    SEBBrowserWindowDocument *browserWindowDocument = [[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"DocumentType" display:YES];
    self.webView = browserWindowDocument.mainWindowController.webView;

    self.browserWindow = (SEBBrowserWindow *)browserWindowDocument.mainWindowController.window;
    // Set the reference to the browser controller in the browser window instance
    self.browserWindow.browserController = self;
    // Set the flag indicating if the main browser window should be displayed full screen
    self.browserWindow.isFullScreen = mainBrowserWindowShouldBeFullScreen;
    
    if (mainBrowserWindowShouldBeFullScreen) {
        [self.browserWindow setToolbar:nil];
        [self.browserWindow setStyleMask:NSBorderlessWindowMask];
    }
    
    [self.browserWindow setSharingType: NSWindowSharingNone];  //don't allow other processes to read window contents
    [self.browserWindow setCalculatedFrame];
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"]) {
        [self.browserWindow newSetLevel:NSModalPanelWindowLevel];
        
    }
    //	[NSApp activateIgnoringOtherApps: YES];
    //    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    
    // Setup bindings to the preferences window close button
    NSButton *closeButton = [self.browserWindow standardWindowButton:NSWindowCloseButton];
    
    [closeButton bind:@"enabled"
             toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
          withKeyPath:@"values.org_safeexambrowser_SEB_allowQuit"
              options:nil];
    
    //[self.browserWindow setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    [self.browserWindow makeKeyAndOrderFront:self];
    
    // Load start URL from the system's user defaults database
    NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
#ifdef DEBUG
    NSLog(@"Open MainBrowserWindow with start URL: %@", urlText);
#endif
    
    // Add "SEB" to the browser's user agent, so the LMS SEB plugins recognize us
    NSString *customUserAgent = [self.webView userAgentForURL:[NSURL URLWithString:urlText]];
    [self.webView setCustomUserAgent:[customUserAgent stringByAppendingString:@" SEB"]];
    
    // Load start URL into browser window
    [[self.webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlText]]];
}


// Adjust the size of the main browser window and bring it forward
- (void) adjustMainBrowserWindow
{
    [self.browserWindow setCalculatedFrame];
    [self.browserWindow makeKeyAndOrderFront:self];
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
                        [self.browserWindow presentError:error modalForWindow:self.browserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
                        return;
                    }
                }
            } else {
                sebFileData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
                if (error) {
                    [self.browserWindow presentError:error modalForWindow:self.browserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
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


@end
