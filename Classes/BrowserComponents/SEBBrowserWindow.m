//
//  BrowserWindow.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 06.12.10.
//  Copyright (c) 2010-2014 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2014 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import "SEBBrowserWindow.h"
#import "SEBConfigFileManager.h"
#import "SEBBrowserWindowDocument.h"
#import "NSWindow+SEBWindow.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "SEBURLFilter.h"


@implementation SEBBrowserWindow

@synthesize webView;


// This window has its usual -constrainFrameRect:toScreen: behavior temporarily suppressed.
// This enables our window's custom Full Screen Exit animations to avoid being constrained by the
// top edge of the screen and the menu bar.
//
- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen
{
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_showMenuBar"] == NO)
    {
        return frameRect;
    }
    else
    {
        return [super constrainFrameRect:frameRect toScreen:screen];
    }
}


-(BOOL)canBecomeKeyWindow {
    return YES;
}


-(BOOL)canBecomeMainWindow {
    return YES;
}


// Overriding setTitle method to adjust position of progress indicator
- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    if (!self.isFullScreen) {
        [self adjustPositionOfViewInTitleBar:progressIndicatorHolder atRightOffsetToTitle:10 verticalOffset:0];
    }
}


//- (NSWindowCollectionBehavior)collectionBehavior {

//    return NSWindowCollectionBehaviorFullScreenAuxiliary | NSWindowCollectionBehaviorCanJoinAllSpaces;
//}


// Closing of SEB Browser Window //
- (BOOL)windowShouldClose:(id)sender
{
    NSLog(@"SEBBrowserWindow %@ windowShouldClose: %@", self, sender);
    if (self == self.browserController.mainBrowserWindow) {
        // Post a notification that SEB should conditionally quit
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestExitNotification" object:self];
        
        return NO; //but don't close the window (that will happen anyways in case quitting is confirmed)
    } else {
        [self.browserController closeWebView:self.webView];
        return YES;
    }
}


// Setup browser window and webView delegates
- (void) awakeFromNib
{
    // Display or don't display toolbar
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    // No toolbar on full screen window
    if (!self.isFullScreen) {
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"] || [preferences secureBoolForKey:@"org_safeexambrowser_SEB_hideBrowserWindowToolbar"])
        {
            [self.toolbar setVisible:NO];
        } else {
            [self.toolbar setVisible:YES];
        }
    }

	// Suppress right-click with own delegate method for context menu
	[self.webView setUIDelegate:self];
	
	// The Policy Delegate is needed to catch opening links in new windows
	[self.webView setPolicyDelegate:self];
	
	// The Frame Load Delegate is needed to monitor frame loads
	[self.webView setFrameLoadDelegate:self];
    
	// The Frame Load Delegate is needed to monitor frame loads
	[self.webView setResourceLoadDelegate:self];
    
    // Set group name to group related frames (so not to open several new windows)
    [self.webView setGroupName:@"SEBBrowserDocument"];

    // Close webView when the last document window is closed
    [self.webView setShouldCloseWithWindow:YES];
    
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
    
    [self.webView setPreferences:webPrefs];
    
    [self.webView bind:@"maintainsBackForwardList"
          toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
       withKeyPath:@"values.org_safeexambrowser_SEB_allowBrowsingBackForward"
           options:nil];
    
/*#ifdef DEBUG
    // Display all MIME types the WebView can display as HTML
    NSArray* MIMETypes = [WebView MIMETypesShownAsHTML];
    int i, count = [MIMETypes count];
    for (i=0; i<count; i++) {
        NSLog(@"MIME type shown as HTML: %@", [MIMETypes objectAtIndex:i]);
    }
#endif*/

}


- (void) setCalculatedFrame
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Get frame of the visible screen (considering if menu bar is enabled)
    NSRect screenFrame = self.screen.visibleFrame;
    // Check if SEB Dock is displayed and reduce visibleFrame accordingly
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"]) {
        double dockHeight = [preferences secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
        screenFrame.origin.y += dockHeight;
        screenFrame.size.height -= dockHeight;
    }
    NSRect windowFrame;
    NSString *windowWidth;
    NSString *windowHeight;
    NSInteger windowPositioning;
    if (self == self.browserController.mainBrowserWindow) {
        // This is the main browser window
        if (self.isFullScreen) {
            // Full screen windows cover the whole screen
            windowWidth = @"100%";
            windowHeight = @"100%";
            windowPositioning = browserWindowPositioningCenter;
        } else {
            windowWidth = [preferences secureStringForKey:@"org_safeexambrowser_SEB_mainBrowserWindowWidth"];
            windowHeight = [preferences secureStringForKey:@"org_safeexambrowser_SEB_mainBrowserWindowHeight"];
            windowPositioning = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_mainBrowserWindowPositioning"];
        }
    } else {
        // This is another browser window
        windowWidth = [preferences secureStringForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkWidth"];
        windowHeight = [preferences secureStringForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkHeight"];
        windowPositioning = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPositioning"];
    }
    if ([windowWidth rangeOfString:@"%"].location == NSNotFound) {
        // Width is in pixels
        windowFrame.size.width = [windowWidth integerValue];
    } else {
        // Width is in percent
        windowFrame.size.width = ([windowWidth integerValue] * screenFrame.size.width) / 100;
    }
    if ([windowHeight rangeOfString:@"%"].location == NSNotFound) {
        // Height is in pixels
        windowFrame.size.height = [windowHeight integerValue];
    } else {
        // Height is in percent
        windowFrame.size.height = ([windowHeight integerValue] * screenFrame.size.height) / 100;
    }
    // Enforce minimum window size
    if (windowFrame.size.width < 394) windowFrame.size.width = 394;
    if (windowFrame.size.height < 247) windowFrame.size.height = 247;
    // Calculate x position according to positioning flag
    switch (windowPositioning) {
        case browserWindowPositioningLeft:
            windowFrame.origin.x = screenFrame.origin.x;
            break;
        case browserWindowPositioningCenter:
            windowFrame.origin.x = screenFrame.origin.x+(screenFrame.size.width-windowFrame.size.width) / 2;
            break;
        case browserWindowPositioningRight:
            windowFrame.origin.x = screenFrame.origin.x+screenFrame.size.width-windowFrame.size.width;
            break;
            
        default:
            //just in case set screen origin
            windowFrame.origin.x = screenFrame.origin.x;
            break;
    }
    // Calculate y position: On top
    windowFrame.origin.y = screenFrame.origin.y + screenFrame.size.height - windowFrame.size.height;
    // Change Window size
    [self setFrame:windowFrame display:YES];
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


// Overriding the sendEvent method allows blocking the context menu
// in the whole WebView, even in plugins
- (void)sendEvent:(NSEvent *)theEvent
{
	int controlKeyDown = [theEvent modifierFlags] & NSControlKeyMask;
	// filter out right clicks
	if (!(([theEvent type] == NSLeftMouseDown && controlKeyDown) ||
		[theEvent type] == NSRightMouseDown))
		[super sendEvent:theEvent];
}


// Overriding this method without calling super in OS X 10.7 Lion
// prevents the windows' position and size to be restored on restarting the app
- (void)restoreStateWithCoder:(NSCoder *)coder
{
    DDLogVerbose(@"BrowserWindow %@: Prevented windows' position and size to be restored!", self);
    return;
}


- (void) startProgressIndicatorAnimation {
    
    if (!progressIndicatorHolder) {
        progressIndicatorHolder = [[NSView alloc] init];
        
        NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] init];
        
        [progressIndicator setBezeled: NO];
        [progressIndicator setStyle: NSProgressIndicatorSpinningStyle];
        [progressIndicator setControlSize: NSSmallControlSize];
        [progressIndicator sizeToFit];
        //[progressIndicator setUsesThreadedAnimation:YES];
        
        [progressIndicatorHolder addSubview:progressIndicator];
        [progressIndicatorHolder setFrame:progressIndicator.frame];
        [progressIndicator startAnimation:self];
        
        if (self.isFullScreen) {
            [self addViewToTitleBar:progressIndicatorHolder atRightOffset:20];
        } else {
            [self addViewToTitleBar:progressIndicatorHolder atRightOffsetToTitle:10 verticalOffset:0];
        }
        
        [progressIndicator setFrame:NSMakeRect(
                                               
                                               0.5 * ([progressIndicator superview].frame.size.width - progressIndicator.frame.size.width),
                                               0.5 * ([progressIndicator superview].frame.size.height - progressIndicator.frame.size.height),
                                               
                                               progressIndicator.frame.size.width,
                                               progressIndicator.frame.size.height
                                               
                                               )];
        
        [progressIndicator setNextResponder:progressIndicatorHolder];
        [progressIndicatorHolder setNextResponder:self];
    } else {
        if (!self.isFullScreen) {
            [self adjustPositionOfViewInTitleBar:progressIndicatorHolder atRightOffsetToTitle:10 verticalOffset:0];
        }
    }
}

- (void) stopProgressIndicatorAnimation {
    
    [progressIndicatorHolder removeFromSuperview];
    progressIndicatorHolder = nil;
    
}


- (void) showURLFilterAlertForRequest:(NSURLRequest *)request
{
    NSString *resourceURL = @"!";
#ifdef DEBUG
    resourceURL = [NSString stringWithFormat:@": %@", [[request URL] absoluteString]];
#endif
    NSAlert *newAlert = [NSAlert alertWithMessageText:NSLocalizedString(@"Resource Not Permitted", nil) defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString(@"It isn't allowed to open this link%@", nil), resourceURL];
    [newAlert setAlertStyle:NSCriticalAlertStyle];
    [newAlert beginSheetModalForWindow:self completionHandler:nil];
}


#pragma mark Overriding NSWindow Methods

// This method is called by NSWindow’s zoom: method while determining the frame a window may be zoomed to
// We override the size calculation to take SEB Dock in account if it's displayed
- (NSRect)windowWillUseStandardFrame:(NSWindow *)window
                        defaultFrame:(NSRect)newFrame {
    // Check if SEB Dock is displayed and reduce visibleFrame accordingly
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"]) {
        CGFloat dockHeight = [preferences secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
        newFrame.origin.y += dockHeight;
        newFrame.size.height -= dockHeight;
    }
    return newFrame;
}


#pragma mark WebView Delegates

#pragma mark WebUIDelegates

// Handling of requests to open a link in a new window (including Javascript commands)
- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
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
            WebView *newWindowWebView = [self.browserController openWebView];
            DDLogDebug(@"Now opening new document browser window. %@", newWindowWebView);
            DDLogDebug(@"Reqested from %@",sender);
            //[[sender preferences] setPlugInsEnabled:NO];
            [[newWindowWebView mainFrame] loadRequest:request];
            return newWindowWebView;
        }
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInSameWindow) {
            WebView *tempWebView = [[WebView alloc] init];
            //create a new temporary, invisible WebView
            [tempWebView setPolicyDelegate:self];
            [tempWebView setUIDelegate:self];
            [tempWebView setGroupName:@"SEBBrowserDocument"];
            [tempWebView setFrameLoadDelegate:self];
            return tempWebView;
        }
        return nil;
    } else {
        return nil;
    }
}


// Show new window containing webView
- (void)webViewShow:(WebView *)sender
{
    [self.browserController webViewShow:sender];
}


/*
 - (void)orderOut:(id)sender {
 //we prevent the browser window to be hidden
 }
 */


// Downloading and Uploading of Files //

- (void)webView:(WebView *)sender runOpenPanelForFileButtonWithResultListener:(id < WebOpenPanelResultListener >)resultListener
// Choose file for upload
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDownUploads"] == YES) {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_chooseFileToUploadPolicy"] != manuallyWithFileRequester) {
            // If the policy isn't "manually with file requester"
            // We try to choose the filename and path ourselves, it's the last dowloaded file
            NSInteger lastDownloadPathIndex = [[MyGlobals sharedMyGlobals] lastDownloadPath];
            NSMutableArray *downloadPaths = [[MyGlobals sharedMyGlobals] downloadPath];
            if (downloadPaths && downloadPaths.count) {
                if (lastDownloadPathIndex == -1) {
                    //if the index counter of the last downloaded file is -1, we have reached the beginning of the list of downloaded files
                    lastDownloadPathIndex = [downloadPaths count]-1; //so we jump to the last path in the list
                }
                NSString *lastDownloadPath = [downloadPaths objectAtIndex:lastDownloadPathIndex];
                lastDownloadPathIndex--;
                [[MyGlobals sharedMyGlobals] setLastDownloadPath:lastDownloadPathIndex];
                if (lastDownloadPath && [[NSFileManager defaultManager] fileExistsAtPath:lastDownloadPath]) {
                    [resultListener chooseFilename:lastDownloadPath];
                    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
                    [self makeKeyAndOrderFront:self];
                    NSRunAlertPanel(NSLocalizedString(@"File Automatically Chosen", nil),
                                    NSLocalizedString(@"SEB will upload the same file which was downloaded before. If you edited it in a third party application, be sure you have saved it with the same name at the same path.", nil),
                                    NSLocalizedString(@"OK", nil), nil, nil);
                    return;
                }
            }
            
            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_chooseFileToUploadPolicy"] == onlyAllowUploadSameFileDownloadedBefore) {
                // if the policy is "Only allow to upload the same file downloaded before"
                [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
                [self makeKeyAndOrderFront:self];
                NSRunAlertPanel(NSLocalizedString(@"File to Upload Not Found!", nil),
                                NSLocalizedString(@"SEB is configured to only allow uploading a file which was downloaded before. So download a file and if you edit it in a third party application, be sure to save it with the same name at the same path.", nil),
                                NSLocalizedString(@"OK", nil), nil, nil);
                return;
            }
        }
        // Create the File Open Dialog class.
        NSOpenPanel* openFilePanel = [NSOpenPanel openPanel];
        
        // Enable the selection of files in the dialog.
        [openFilePanel setCanChooseFiles:YES];
        
        // Disable the selection of directories in the dialog.
        [openFilePanel setCanChooseDirectories:NO];
        
        // Change text of the open button in file dialog
        [openFilePanel setPrompt:NSLocalizedString(@"Choose",nil)];
        
        // Change default directory in file dialog
        [openFilePanel setDirectoryURL:[NSURL fileURLWithPath:[preferences secureStringForKey:@"org_safeexambrowser_SEB_downloadDirectoryOSX"]]];
        
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        [self makeKeyAndOrderFront:self];

        // Display the dialog.  If the OK button was pressed,
        // process the files.
        [openFilePanel beginSheetModalForWindow:self
                              completionHandler:^(NSInteger result) {
                                  if (result == NSFileHandlingPanelOKButton) {
                                      // Get an array containing the full filenames of all
                                      // files and directories selected.
                                      NSArray* files = [openFilePanel URLs];
                                      NSString* fileName = [[files objectAtIndex:0] path];
                                      [resultListener chooseFilename:fileName];
                                  }
                              }];
    }
}


// Delegate method for disabling right-click context menu
- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element 
    defaultMenuItems:(NSArray *)defaultMenuItems {
    // disable right-click context menu
    return NO;
}


// Delegate method for JavaScript alert panel
- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message 
initiatedByFrame:(WebFrame *)frame {
	NSString *pageTitle = [sender stringByEvaluatingJavaScriptFromString:@"document.title"];
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [self makeKeyAndOrderFront:self];
    
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:pageTitle];
    [newAlert setInformativeText:message];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [newAlert setAlertStyle:NSInformationalAlertStyle];
    [newAlert runModal];
}


// Delegate method for JavaScript confirmation panel
- (BOOL)webView:(WebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message 
initiatedByFrame:(WebFrame *)frame {
	NSString *pageTitle = [sender stringByEvaluatingJavaScriptFromString:@"document.title"];
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [self makeKeyAndOrderFront:self];

    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:pageTitle];
    [newAlert setInformativeText:message];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [newAlert setAlertStyle:NSInformationalAlertStyle];
    return [newAlert runModal];
}


#pragma mark WebFrameLoadDelegates

// Get the URL of the page being loaded
// Invoked when a page load is in progress in a given frame
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
    DDLogInfo(@"didStartProvisionalLoadForFrame request URL: %@", [[[[frame provisionalDataSource] request] URL] absoluteString]);
    [self startProgressIndicatorAnimation];
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]){
        self.browserController.currentMainHost = [[[[frame provisionalDataSource] request] URL] host];
        //reset the flag for presentation option changes by flash
        [[MyGlobals sharedMyGlobals] setFlashChangedPresentationOptions:NO];
    }
}


// Invoked when a page load completes
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    [self stopProgressIndicatorAnimation];
}


// Invoked when a client redirect is cancelled
- (void)webView:(WebView *)sender didCancelClientRedirectForFrame:(WebFrame *)frame
{
    DDLogInfo(@"webView: %@ didCancelClientRedirectForFrame: %@", sender, frame);
}


// Invoked when a frame receives a client redirect and before it is fired
- (void)webView:(WebView *)sender
willPerformClientRedirectToURL:(NSURL *)URL
          delay:(NSTimeInterval)seconds
       fireDate:(NSDate *)date
       forFrame:(WebFrame *)frame
{
    DDLogInfo(@"willPerformClientRedirectToURL: %@", URL);
}


// Update the URL of the current page in case of a server redirect
- (void)webView:(WebView *)sender didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame {
    //[self stopProgressIndicatorAnimation];
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]){
        self.browserController.currentMainHost = [[[[frame provisionalDataSource] request] URL] host];
        //reset the flag for presentation option changes by flash
        [[MyGlobals sharedMyGlobals] setFlashChangedPresentationOptions:NO];
    }
}


- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
    // Report feedback only for the main frame.
    if (frame == [sender mainFrame]){
        [self.browserController setTitle: title forWindow:self withWebView:sender];
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
        [sender.window setTitle:appTitleString];
    }
}


/// Handle WebView load errors

// Invoked if an error occurs when starting to load data for a page
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error
       forFrame:(WebFrame *)frame {
    
    [self stopProgressIndicatorAnimation];
    
    if ([error code] != -999) {
        
        if ([error code] !=  WebKitErrorFrameLoadInterruptedByPolicyChange) //this error can be ignored
        {
            //Close the About Window first, because it would hide the error alert
            [[NSNotificationCenter defaultCenter] postNotificationName:@"requestCloseAboutWindowNotification" object:self];
            
            NSString *titleString = NSLocalizedString(@"Error Loading Page",nil);
            NSString *messageString = [error localizedDescription];
            NSPanel *alertPanel = NSGetAlertPanel(titleString, messageString, NSLocalizedString(@"Retry", nil), NSLocalizedString(@"Cancel", nil), nil, nil);
            [alertPanel setLevel:NSScreenSaverWindowLevel];
            
            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
            [self makeKeyAndOrderFront:self];
            int answer = NSRunAlertPanel(titleString, messageString, NSLocalizedString(@"Retry", nil), NSLocalizedString(@"Cancel", nil), nil, nil);
            switch(answer) {
                case NSAlertDefaultReturn:
                    //Retry: try reloading
                    //self.browserController.currentMainHost = nil;
                    [[sender mainFrame] loadRequest:[[frame provisionalDataSource] request]];
                    return;
                default:
                    return;
            }
        }
    }
}


// Invoked when an error occurs loading a committed data source
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    
    [self stopProgressIndicatorAnimation];
    
    if ([error code] != -999) {
        
        if ([error code] !=  WebKitErrorFrameLoadInterruptedByPolicyChange) //this error can be ignored
        {
            //Close the About Window first, because it would hide the error alert
            [[NSNotificationCenter defaultCenter] postNotificationName:@"requestCloseAboutWindowNotification" object:self];
            
            NSString *titleString = NSLocalizedString(@"Error Loading Page",nil);
            NSString *messageString = [error localizedDescription];
            
            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
            [self makeKeyAndOrderFront:self];
            int answer = NSRunAlertPanel(titleString, messageString, NSLocalizedString(@"Retry", nil), NSLocalizedString(@"Cancel", nil), nil, nil);
            switch(answer) {
                case NSAlertDefaultReturn:
                    //Retry: try reloading
                    //self.browserController.currentMainHost = setCurrentMainHost:nil;
                    [[sender mainFrame] loadRequest:[[frame dataSource] request]];
                    return;
                default:
                    return;
            }
        }
    }
}


// Invoked when the JavaScript window object in a frame is ready for loading
- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowObject
       forFrame:(WebFrame *)frame
{
    DDLogDebug(@"webView: %@ didClearWindowObject: %@ forFrame: %@", sender, windowObject, frame);
}


#pragma mark WebResourceLoadDelegate Protocol

// Generate and send the Browser Exam Key in modified header
// Invoked before a request is initiated for a resource and returns a possibly modified request
- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
    // If enabled, filter content
    SEBURLFilter *URLFilter = [SEBURLFilter sharedSEBURLFilter];
    if (URLFilter.enableURLFilter && URLFilter.enableContentFilter && ![URLFilter allowURL:request.URL]) {
        // Content is not allowed
        DDLogWarn(@"This content was blocked by the content filter: %@", request.URL.absoluteString);
        // Return nil instead of request
        return nil;
    }

    NSString *fragment = [[request URL] fragment];
    NSString *absoluteRequestURL = [[request URL] absoluteString];
    NSString *requestURLStrippedFragment;
    if (fragment.length) {
        // if there is a fragment
        requestURLStrippedFragment = [absoluteRequestURL substringToIndex:absoluteRequestURL.length - fragment.length - 1];
    } else requestURLStrippedFragment = absoluteRequestURL;
    DDLogVerbose(@"Full absolute request URL: %@", absoluteRequestURL);
    DDLogVerbose(@"Request URL used to calculate RequestHash: %@", requestURLStrippedFragment);

    NSDictionary *headerFields;
    headerFields = [request allHTTPHeaderFields];
    DDLogVerbose(@"All HTTP header fields: %@", headerFields);
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"]) {
        
        NSMutableURLRequest *modifiedRequest = [request mutableCopy];
        
        /*/ Generate and store salt for exam key
         NSData *HMACKey = [RNCryptor randomDataOfLength:kCCKeySizeAES256];
         [preferences setSecureObject:HMACKey forKey:@"org_safeexambrowser_SEB_examKeySalt"];
         
         NSMutableData *HMACData = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
         
         CCHmac(kCCHmacAlgSHA256, HMACKey.bytes, HMACKey.length, archivedPrefs.mutableBytes, archivedPrefs.length, [HMACData mutableBytes]);
         */
        //NSMutableData *browserExamKey = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
        NSData *browserExamKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
        unsigned char hashedChars[32];
        [browserExamKey getBytes:hashedChars length:32];

        DDLogVerbose(@"Current Browser Exam Key: %@", browserExamKey);
        
        NSMutableString* browserExamKeyString = [[NSMutableString alloc] init];
        [browserExamKeyString setString:requestURLStrippedFragment];
        for (int i = 0 ; i < 32 ; ++i) {
            [browserExamKeyString appendFormat: @"%02x", hashedChars[i]];
        }
        
        DDLogVerbose(@"Current request URL + Browser Exam Key: %@", browserExamKeyString);
        
        //unsigned char hashedChars[32];
        
        const char *urlString = [browserExamKeyString UTF8String];
        
        //CC_SHA256_CTX sha256;
        //CC_SHA256_Init(&sha256);
        //CC_SHA256_Update(&sha256, urlString, strlen(urlString));
        //CC_SHA256_Update(&sha256, urlString, strlen(urlString));
        //CC_SHA256_Update(&sha256, browserExamKey.bytes, browserExamKey.length);

        //CC_SHA256_Final(hashedChars, &sha256);

        CC_SHA256(urlString,
                  strlen(urlString),
                  hashedChars);
        //[browserExamKey getBytes:hashedChars length:32];
        //browserExamKey = nil;

        NSMutableString* hashedString = [[NSMutableString alloc] init];
        for (int i = 0 ; i < 32 ; ++i) {
            [hashedString appendFormat: @"%02x", hashedChars[i]];
        }
        [modifiedRequest setValue:hashedString forHTTPHeaderField:@"X-SafeExamBrowser-RequestHash"];

        headerFields = [modifiedRequest allHTTPHeaderFields];
        DDLogVerbose(@"All HTTP header fields in modified request: %@", headerFields);
        return modifiedRequest;
        
    } else {
        
        return request;
    }
}


// Invoked when a resource failed to load
- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error
 fromDataSource:(WebDataSource *)dataSource
{
    DDLogError(@"webView: %@ resource: %@ didFailLoadingWithError: %@ fromDataSource: %@", sender, identifier, error.description, dataSource);
}


// Invoked when a plug-in fails to load
- (void)webView:(WebView *)sender plugInFailedWithError:(NSError *)error
     dataSource:(WebDataSource *)dataSource
{
    DDLogError(@"webView: %@ plugInFailedWithError: %@ dataSource: %@", sender, error, dataSource);
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:error.localizedDescription];
    [newAlert setInformativeText:error.localizedFailureReason];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [newAlert setAlertStyle:NSCriticalAlertStyle];
    [newAlert runModal];
}


// Invoked when an authentication challenge has been received for a resource
- (void)webView:(WebView *)sender resource:(id)identifier didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
 fromDataSource:(WebDataSource *)dataSource
{
    DDLogInfo(@"webView: %@ resource: %@ didReceiveAuthenticationChallenge: %@ fromDataSource: %@", sender, identifier, challenge, dataSource);
}


// Invoked when an authentication challenge for a resource was canceled
- (void)webView:(WebView *)sender
       resource:(id)identifier
didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
 fromDataSource:(WebDataSource *)dataSource
{
    DDLogInfo(@"webView: %@ resource: %@ didCancelAuthenticationChallenge: %@ fromDataSource: %@", sender, identifier, challenge, dataSource);
}


// Opening Links in New Windows //

// Handling of requests from web plugins to open a link in a new window
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation 
        request:(NSURLRequest *)request 
          frame:(WebFrame *)frame 
decisionListener:(id <WebPolicyDecisionListener>)listener {

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    DDLogInfo(@"decidePolicyForNavigationAction request URL: %@", [[request URL] absoluteString]);

    // Check if quit URL has been clicked (regardless of current URL Filter)
    if ([[[request URL] absoluteString] isEqualTo:[preferences secureStringForKey:@"org_safeexambrowser_SEB_quitURL"]]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestQuitWPwdNotification" object:self];
        [listener ignore];
        return;
    }
    
    // If enabled, filter URL
    SEBURLFilter *URLFilter = [SEBURLFilter sharedSEBURLFilter];
    if (URLFilter.enableURLFilter && ![URLFilter allowURL:request.URL]) {
        // URL is not allowed: Show alert
        [self showURLFilterAlertForRequest:request];
        //Don't load the request
        [listener ignore];
        return;
    }
    
    // Check if this is a seb:// link
    if ([request.URL.scheme isEqualToString:@"seb"]) {
        // If the scheme is seb:// we (conditionally) download and open the linked .seb file
        [self.browserController downloadAndOpenSebConfigFromURL:request.URL];
        [listener ignore];
        return;
    }
    
    NSString *currentMainHost = self.browserController.currentMainHost;
    if (currentMainHost && [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == getGenerallyBlocked) {
        [listener ignore];
        return;
    }
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptBlockForeign"]) {
        NSString *requestedHost = [[request mainDocumentURL] host];
        DDLogDebug(@"Current Host: %@", currentMainHost);
        DDLogDebug(@"Requested Host: %@", requestedHost);
        // If current host is not the same as the requested host
        if (currentMainHost && (!requestedHost || ![currentMainHost isEqualToString:requestedHost])) {
            [listener ignore];
            // If the new page is supposed to open in a new browser window
            if (requestedHost && self.webView && [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInNewWindow) {
                // we have to close the new browser window which already has been openend by WebKit
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
            return;
        } 
    }
    // Check if the new page is supposed to be opened in the same browser window
    if (currentMainHost && [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInSameWindow) {
        if (self.webView && ![sender isEqual:self.webView]) {
            // If the request's sender is the temporary webview, then we have to load the request now in the current webview
            [listener ignore]; // ignore listener
            [[self.webView mainFrame] loadRequest:request]; //load the new page in the same browser window
            [sender close]; //close the temporary webview
            return; //and return from here
        }
    }

    [listener use];
}


// Open the link requesting to be opened in a new window according to settings
- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation 
		request:(NSURLRequest *)request 
   newFrameName:(NSString *)frameName 
decisionListener:(id <WebPolicyDecisionListener>)listener {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    // First check if links requesting to be opened in a new windows are generally blocked
    if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] != getGenerallyBlocked) {
        // load link only if it's on the same host like the one of the current page
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkBlockForeign"] ||
            [self.browserController.currentMainHost isEqualToString:[[request mainDocumentURL] host]]) {
            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] == openInNewWindow) {
                // Open new browser window containing WebView and show it
                WebView *newWebView = [self.browserController openAndShowWebView];
                // Load URL request in new WebView
                [[newWebView mainFrame] loadRequest:request];
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

- (void)webView:(WebView *)sender decidePolicyForMIMEType:(NSString*)type
        request:(NSURLRequest *)request 
          frame:(WebFrame *)frame
decisionListener:(id < WebPolicyDecisionListener >)listener
{
    DDLogDebug(@"decidePolicyForMIMEType: %@ requestURL: %@", type, request.URL.absoluteString);
    /*NSDictionary *headerFields = [request allHTTPHeaderFields];
#ifdef DEBUG
    NSLog(@"Request URL: %@", [[request URL] absoluteString]);
    NSLog(@"All HTTP header fields: %@", headerFields);
#endif*/

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (([type isEqualToString:@"application/seb"]) || ([request.URL.pathExtension isEqualToString:@"seb"])) {
        // If MIME-Type or extension of the file indicates a .seb file, we (conditionally) download and open it
        [self.browserController downloadAndOpenSebConfigFromURL:request.URL];
        [listener ignore];
        return;
    }
    // Check for PDF file and according to settings either download or display it inline in the SEB browser
    if (![type isEqualToString:@"application/pdf"] || ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadPDFFiles"]) {
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


- (void)webView:(WebView *)sender unableToImplementPolicyWithError:(NSError *)error
          frame:(WebFrame *)frame
{
    DDLogError(@"webView: %@ unableToImplementPolicyWithError: %@ frame: %@", sender, error, frame);
}


- (void)startDownloadingURL:(NSURL *)url
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDownUploads"] == YES) {
        // If downloading is allowed
        // Create the request.
        NSURLRequest *theRequest = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:60.0];
        // Create the download with the request and start loading the data.
        NSURLDownload  *theDownload = [[NSURLDownload alloc] initWithRequest:theRequest delegate:self];
        if (!theDownload) {
            DDLogError(@"Starting the download failed!"); //Inform the user that the download failed.
        }
    }
}


- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    downloadPath = [preferences secureStringForKey:@"org_safeexambrowser_SEB_downloadDirectoryOSX"];
    if (!downloadPath) {
        //if there's no path saved in preferences, set standard path
        downloadPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"];
        [preferences setSecureObject:downloadPath forKey:@"org_safeexambrowser_SEB_downloadDirectoryOSX"];
    }
    downloadPath = [downloadPath stringByExpandingTildeInPath];
    NSString *destinationFilename = [downloadPath stringByAppendingPathComponent:filename];
    [download setDestination:destinationFilename allowOverwrite:NO];
}


- (void) download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    // Release the download.
    
    // Inform the user
    //[self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:NULL contextInfo:NULL];

    DDLogError(@"Download failed! Error - %@ %@",
               [error localizedDescription],
               [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}


- (void) downloadDidFinish:(NSURLDownload *)download
{
    // Release the download.
    
    DDLogInfo(@"Download of File %@ did finish.",downloadPath);
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_openDownloads"] == YES) {
    // Open downloaded file
    [[NSWorkspace sharedWorkspace] openFile:downloadPath];
    }
}


- (void) download:(NSURLDownload *)download didCreateDestination:(NSString *)path
{
    // path now contains the destination path
    // of the download, taking into account any
    // unique naming caused by -setDestination:allowOverwrite:
    DDLogInfo(@"Final file destination: %@",path);
    downloadPath = path;
    NSMutableArray *downloadPaths = [NSMutableArray arrayWithArray:[[MyGlobals sharedMyGlobals] downloadPath]];
    if (!downloadPaths) {
        downloadPaths = [NSMutableArray arrayWithCapacity:1];
    }
    [downloadPaths addObject:downloadPath];
    [[MyGlobals sharedMyGlobals] setDownloadPath:downloadPaths];
    [[MyGlobals sharedMyGlobals] setLastDownloadPath:[downloadPaths count]-1];
}





@end
