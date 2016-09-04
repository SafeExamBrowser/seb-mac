//
//  BrowserWindow.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 06.12.10.
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

#import "SEBBrowserWindow.h"
#import "SEBWebView.h"
#import "SEBConfigFileManager.h"
#import "SEBBrowserWindowDocument.h"
#import "NSWindow+SEBWindow.h"
#import "WebKit+WebKitExtensions.h"
#include "WebPreferencesPrivate.h"
#import "SEBURLFilter.h"
#import "NSURL+KKDomain.h"

#include <CoreServices/CoreServices.h>

@implementation SEBBrowserWindow

@synthesize webView;


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


// Closing of SEB Browser Window //
- (BOOL)windowShouldClose:(id)sender
{
    DDLogDebug(@"SEBBrowserWindow %@ windowShouldClose: %@", self, sender);
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
    
	// The Resource Load Delegate is needed to monitor the progress of loading individual resources
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
    
    [webPrefs setWebAudioEnabled:YES];
    
    [self.webView setPreferences:webPrefs];
    
    [self.webView bind:@"maintainsBackForwardList"
          toObject:[SEBEncryptedUserDefaultsController sharedSEBEncryptedUserDefaultsController]
       withKeyPath:@"values.org_safeexambrowser_SEB_allowBrowsingBackForward"
           options:nil];
        
    // Display all MIME types the WebView can display as HTML
    NSArray* MIMETypes = [WebView MIMETypesShownAsHTML];
    int i, count = [MIMETypes count];
    for (i=0; i<count; i++) {
        DDLogDebug(@"MIME type shown as HTML: %@", [MIMETypes objectAtIndex:i]);
    }
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
    } else if (self.webView == self.browserController.temporaryWebView) {
        // This is a temporary browser window used for downloads with authentication
        windowWidth = @"1050";
        windowHeight = @"100%";
        windowPositioning = browserWindowPositioningCenter;
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


- (IBAction)resetPageZoom:(id)sender
{
    
}


- (IBAction)zoomPageIn:(id)sender
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.zoom = \"1.5\""];
}


- (IBAction)zoomPageOut:(id)sender;
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.zoom = \"0.5\""];
}


- (void) showURLFilterMessage {
    
    if (!self.filterMessageHolder) {
        
        NSRect frameRect = NSMakeRect(0,0,155,21); // This will change based on the size you need
        NSTextField *message = [[NSTextField alloc] initWithFrame:frameRect];
        message.bezeled = NO;
        message.editable = NO;
        message.drawsBackground = NO;
        [message.cell setUsesSingleLineMode:YES];
        CGFloat messageLabelYOffset = 0;

        // Set message for URL blocked according to settings
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        switch ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_URLFilterMessage"]) {
                
            case URLFilterMessageText:
                message.stringValue = NSLocalizedString(@"URL Blocked!", nil);
                [message setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
                [message setTextColor:[NSColor redColor]];
                break;
                
            case URLFilterMessageX:
                message.stringValue = @"✕";
                [message setFont:[NSFont systemFontOfSize:20]];
                [message setTextColor:[NSColor darkGrayColor]];
                messageLabelYOffset = 4;
                break;
        }

        NSSize messageLabelSize = [message intrinsicContentSize];
        [message setAlignment:NSRightTextAlignment];
        CGFloat messageLabelWidth = messageLabelSize.width + 2;
        CGFloat messageLabelHeight = messageLabelSize.height;
        [message setFrameSize:NSMakeSize(messageLabelWidth, messageLabelHeight)];
        
        self.filterMessageHolder = [[NSView alloc] initWithFrame:message.frame];
        [self.filterMessageHolder addSubview:message];
        [self.filterMessageHolder setContentHuggingPriority:NSLayoutPriorityFittingSizeCompression-1.0 forOrientation:NSLayoutConstraintOrientationVertical];
        
        [message setFrame:NSMakeRect(
                                     
                                     0.5 * ([message superview].frame.size.width - message.frame.size.width),
                                     (0.5 * ([message superview].frame.size.height - message.frame.size.height)) + messageLabelYOffset,
                                     
                                     message.frame.size.width,
                                     message.frame.size.height
                                     
                                     )];
        
        [message setNextResponder:self.filterMessageHolder];
        
//    } else {
//        if (self.isFullScreen) {
//            [self adjustPositionOfViewInTitleBar:self.filterMessageHolder atrighto:10 verticalOffset:0];
//        }
    }
    
    // Show the message
    if (self.isFullScreen) {
        [self addViewToTitleBar:self.filterMessageHolder atRightOffset:43];
    } else {
        [self addViewToTitleBar:self.filterMessageHolder atRightOffset:5];
    }
    [self.filterMessageHolder setNextResponder:self];

    // Remove the URL filter message after a delay
    [self performSelector:@selector(hideURLFilterMessage) withObject: nil afterDelay: 1];

}

- (void) hideURLFilterMessage {
    
    [self.filterMessageHolder removeFromSuperview];
//    self.filterMessageHolder = nil;
}


- (BOOL) showURLFilterAlertSheetForWindow:(NSWindow *)window forRequest:(NSURLRequest *)request forContentFilter:(BOOL)contentFilter filterResponse:(URLFilterRuleActions)filterResponse
{
    if (!window.attachedSheet) {
        SEBWebView *creatingWebView = [self.webView creatingWebView];
        if (!creatingWebView) {
            creatingWebView = self.webView;
        }
        
        // If the filter Response isn't block and the URL filter learning mode is switched on
        if (filterResponse != URLFilterActionBlock && [SEBURLFilter sharedSEBURLFilter].learningMode) {
            
            // Check if all non-allowed URLs should be dismissed in the current webview
            if (creatingWebView.dismissAll == NO) {
                NSURL *resourceURL = request.URL;
                self.URLFilterAlertURL = resourceURL;
                if (!creatingWebView.notAllowedURLs) {
                    creatingWebView.notAllowedURLs = [NSMutableArray new];
                }
                // Check if the non-allowed URL has been dismissed for the current webview
                BOOL containsURL = NO;
                for (NSURL *notAllowedURL in creatingWebView.notAllowedURLs) {
                    if ([resourceURL isEqualTo:notAllowedURL]) {
                        containsURL = YES;
                        break;
                    }
                }
                if (containsURL == NO) {
                    
                    // Check if the non-allowed URL is in the ignore list for current settings
                    if (![[SEBURLFilter sharedSEBURLFilter] testURLIgnored:resourceURL]) {
                        
                        // This non-allowed URL hasn't been dismissed yet, add it to the dismissed list
                        [creatingWebView.notAllowedURLs addObject:resourceURL];
                        
                        // Set filter alert text depending if a URL or content was blocked
                        if (contentFilter) {
                            self.URLFilterAlertText.stringValue = NSLocalizedString(@"This embedded resource isn't allowed! You can create a new filter rule based on the following patterns:", nil);
                        } else {
                            self.URLFilterAlertText.stringValue = NSLocalizedString(@"It's not allowed to open this URL! You can create a new filter rule based on the following patterns:", nil);
                        }
                        // Set filter expression according to selected pattern in the NSMatrix radio button group
                        [self changedFilterPattern:self.filterPatternMatrix];
                        
                        // Set full URL in the filter expression text field
                        self.filterExpressionField.string = self.URLFilterAlertURL.absoluteString;
                        
                        // Set the domain pattern label/button string
                        self.domainPatternButton.title = [self filterExpressionForPattern:SEBURLFilterAlertPatternDomain];
                        
                        // Set the host pattern label/button string
                        self.hostPatternButton.title = [self filterExpressionForPattern:SEBURLFilterAlertPatternHost];
                        
                        // Set the host/path pattern label/button string
                        self.hostPathPatternButton.title = [self filterExpressionForPattern:SEBURLFilterAlertPatternHostPath];
                        
                        // Set the directory pattern label/button string
                        self.directoryPatternButton.title = [self filterExpressionForPattern:SEBURLFilterAlertPatternDirectory];
                        
                        // If the (main) browser window is full screen, we don't show the dialog as sheet
                        if (window && self.browserController.mainBrowserWindow.isFullScreen && window == self.browserController.mainBrowserWindow) {
                            window = nil;
                        }
                        
                        [NSApp beginSheet: self.URLFilterAlert
                           modalForWindow: window
                            modalDelegate: nil
                           didEndSelector: nil
                              contextInfo: nil];
                        NSInteger returnCode = [NSApp runModalForWindow: self.URLFilterAlert];
                        // Dialog is up here.
                        [NSApp endSheet: self.URLFilterAlert];
                        [NSApp abortModal];
                        [self.URLFilterAlert orderOut: self];
                        switch (returnCode) {
                            case SEBURLFilterAlertDismiss:
                                return NO;
                                
                            case SEBURLFilterAlertAllow:
                                // Allow URL (in filter learning mode)
                                [[SEBURLFilter sharedSEBURLFilter] addRuleAction:URLFilterActionAllow withFilterExpression:[SEBURLFilterExpression filterExpressionWithString:self.filterExpression]];
                                return YES;
                                
                            case SEBURLFilterAlertIgnore:
                                // Ignore URL according to selected pattern (in filter learning mode)
                                [[SEBURLFilter sharedSEBURLFilter] addRuleAction:URLFilterActionIgnore withFilterExpression:[SEBURLFilterExpression filterExpressionWithString:self.filterExpression]];
                                return NO;
                                
                            case SEBURLFilterAlertBlock:
                                // Block URL (in filter learning mode)
                                [[SEBURLFilter sharedSEBURLFilter] addRuleAction:URLFilterActionBlock withFilterExpression:[SEBURLFilterExpression filterExpressionWithString:self.filterExpression]];
                                return NO;
                                
                            case SEBURLFilterAlertDismissAll:
                                return NO;
                                
                        }
                    }
                }
            }
        } else if (contentFilter == NO) {
            // The filter Response is block or the URL filter learning mode isn't switched on
            // Display "URL Blocked" (or red "X") top/right in window title bar
            [self showURLFilterMessage];
        }
    }
    return NO;
}


- (IBAction)clickedDomainPattern:(id)sender
{
    self.filterExpression = [self filterExpressionForPattern:SEBURLFilterAlertPatternDomain];
    self.filterExpressionField.string = self.filterExpression;
}

- (IBAction)clickedHostPattern:(id)sender
{
    self.filterExpression = [self filterExpressionForPattern:SEBURLFilterAlertPatternHost];
    self.filterExpressionField.string = self.filterExpression;
}

- (IBAction)clickedHostPathPattern:(id)sender
{
    self.filterExpression = [self filterExpressionForPattern:SEBURLFilterAlertPatternHostPath];
    self.filterExpressionField.string = self.filterExpression;
}

- (IBAction)clickedDirectoryPattern:(id)sender
{
    self.filterExpression = [self filterExpressionForPattern:SEBURLFilterAlertPatternDirectory];
    self.filterExpressionField.string = self.filterExpression;
}

- (IBAction)clickedFullURLPattern:(id)sender {
    self.filterExpression = self.URLFilterAlertURL.absoluteString;
    self.filterExpressionField.string = self.filterExpression;
}


- (IBAction) URLFilterAlertDismiss: (id)sender {
    [NSApp stopModalWithCode:SEBURLFilterAlertDismiss];
}

- (IBAction) URLFilterAlertAllow: (id)sender {
    [NSApp stopModalWithCode:SEBURLFilterAlertAllow];
}

- (IBAction) URLFilterAlertIgnore: (id)sender {
    [NSApp stopModalWithCode:SEBURLFilterAlertIgnore];
}

- (IBAction) URLFilterAlertBlock: (id)sender {
    [NSApp stopModalWithCode:SEBURLFilterAlertBlock];
}

- (IBAction) URLFilterAlertIgnoreAll: (id)sender {
    if (self.webView.creatingWebView) {
        self.webView.creatingWebView.dismissAll = YES;
    } else {
        self.webView.dismissAll = YES;
    }
    [NSApp stopModalWithCode:SEBURLFilterAlertDismissAll];
}


- (IBAction)editingFilterExpression:(NSTextField *)sender {
    self.filterExpression = self.filterExpressionField.string;
}


- (void)textDidChange:(NSNotification *)aNotification
{
    [self.filterPatternMatrix selectCellAtRow:SEBURLFilterAlertPatternCustom column:0];
    self.filterExpression = self.filterExpressionField.string;
}

- (IBAction)changedFilterPattern:(NSMatrix *)sender
{
    NSUInteger selectedFilterPattern = [sender selectedRow];
    
    self.filterExpression = [self filterExpressionForPattern:selectedFilterPattern];
}


- (NSString *)filterExpressionForPattern:(SEBURLFilterAlertPattern)filterPattern
{
    NSString *domain = [self.URLFilterAlertURL registeredDomain];
    if (!domain) {
        domain = @"";
    }
    
    NSString *host = self.URLFilterAlertURL.host;
    if (host.length == 0) {
        host = [self.URLFilterAlertURL.scheme stringByAppendingString:@":"];
    }
    NSString *path = [self.URLFilterAlertURL.path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    if (!path) {
        path = @"";
    }
    NSString *directory = @"";
    if (self.URLFilterAlertURL.pathExtension.length > 0) {
        NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:self.URLFilterAlertURL.pathComponents];
        if (pathComponents.count > 2) {
            [pathComponents removeObjectAtIndex:0];
            [pathComponents removeLastObject];
            directory = [pathComponents componentsJoinedByString:@"/"];
            directory = [NSString stringWithFormat:@"/%@/*", directory];
        } else if (pathComponents.count == 2) {
            directory = @"/*";
        }
    } else {
        if (path.length > 1) {
            directory = [NSString stringWithFormat:@"%@/*", path];
        }
    }
    
    
    switch (filterPattern) {
            
        case SEBURLFilterAlertPatternDomain:
            return domain;
            
        case SEBURLFilterAlertPatternHost:
            return host;
            
        case SEBURLFilterAlertPatternHostPath: {
            return [NSString stringWithFormat:@"%@%@", host, path];
        }
            
        case SEBURLFilterAlertPatternDirectory: {
            return [NSString stringWithFormat:@"%@%@", host, directory];
        }
            
        case SEBURLFilterAlertPatternCustom:
            return self.filterExpressionField.string;
    }
    
    return @"";
}


- (void) alertDidEnd:(NSAlert *)alert
          returnCode:(NSInteger)returnCode
         contextInfo:(void *)contextInfo
{
    // If the URL filter learning mode is switched on, handle the first button differently
    if (returnCode == NSAlertFirstButtonReturn && [SEBURLFilter sharedSEBURLFilter].learningMode) {
        // Allow URL (in filter learning mode)
        [alert.window orderOut:self];
        return;
    }
    [alert.window orderOut:self];
}


// Enable back/forward buttons according to availablility for this webview
- (void)backForwardButtonsSetEnabled {
    NSSegmentedControl *backForwardButtons = [(SEBBrowserWindowController *)self.windowController backForwardButtons];
    [backForwardButtons setEnabled:self.webView.canGoBack forSegment:0];
    [backForwardButtons setEnabled:self.webView.canGoForward forSegment:1];
}


#pragma mark Overriding NSWindow Methods

// This method is called by NSWindow’s zoom: method while determining the frame a window may be zoomed to
// We override the size calculation to take SEB Dock in account if it's displayed
- (NSRect)windowWillUseStandardFrame:(NSWindow *)window
                        defaultFrame:(NSRect)newFrame {
    // Check if SEB Dock is displayed and reduce visibleFrame accordingly
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // Get frame of the visible screen (considering if menu bar is enabled)
    NSRect screenFrame = self.screen.visibleFrame;
    newFrame.size.height = screenFrame.size.height;
//    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showMenuBar"])
//    {
//    }
    
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
            SEBWebView *newWindowWebView = [self.browserController openAndShowWebView];
            newWindowWebView.creatingWebView = self.webView;
            DDLogDebug(@"Now opening new document browser window. %@", newWindowWebView);
            DDLogDebug(@"Reqested from %@",sender);
            //[[sender preferences] setPlugInsEnabled:NO];
            [[newWindowWebView mainFrame] loadRequest:request];
            return newWindowWebView;
        }
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInSameWindow) {
            SEBWebView *tempWebView = [[SEBWebView alloc] init];
            //create a new temporary, invisible WebView
            [tempWebView setPolicyDelegate:self];
            [tempWebView setUIDelegate:self];
            [tempWebView setFrameLoadDelegate:self];
            [tempWebView setGroupName:@"SEBBrowserDocument"];
            tempWebView.creatingWebView = self.webView;
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
    [self.browserController webViewShow:sender];
}


/*
 - (void)orderOut:(id)sender {
 //we prevent the browser window to be hidden
 }
 */


// Downloading and Uploading of Files //

- (void)webView:(SEBWebView *)sender runOpenPanelForFileButtonWithResultListener:(id < WebOpenPanelResultListener >)resultListener
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
                    
                    NSAlert *newAlert = [[NSAlert alloc] init];
                    [newAlert setMessageText:NSLocalizedString(@"File Automatically Chosen", nil)];
                    [newAlert setInformativeText:NSLocalizedString(@"SEB will upload the same file which was downloaded before. If you edited it in a third party application, be sure you have saved it with the same name at the same path.", nil)];
                    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                    [newAlert setAlertStyle:NSInformationalAlertStyle];
                    [newAlert runModal];
                    return;
                }
            }
            
            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_chooseFileToUploadPolicy"] == onlyAllowUploadSameFileDownloadedBefore) {
                // if the policy is "Only allow to upload the same file downloaded before"
                [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
                [self makeKeyAndOrderFront:self];
                NSAlert *newAlert = [[NSAlert alloc] init];
                [newAlert setMessageText:NSLocalizedString(@"File to Upload Not Found!", nil)];
                [newAlert setInformativeText:NSLocalizedString(@"SEB is configured to only allow uploading a file which was downloaded before. So download a file and if you edit it in a third party application, be sure to save it with the same name at the same path.", nil)];
                [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [newAlert setAlertStyle:NSCriticalAlertStyle];
                [newAlert runModal];
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
- (NSArray *)webView:(SEBWebView *)sender contextMenuItemsForElement:(NSDictionary *)element 
    defaultMenuItems:(NSArray *)defaultMenuItems {
    // disable right-click context menu
    return NO;
}


// Delegate method for JavaScript alert panel
- (void)webView:(SEBWebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message 
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
- (BOOL)webView:(SEBWebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message 
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


- (void)webView:(WebView *)sender frame:(WebFrame *)frame exceededDatabaseQuotaForSecurityOrigin:(id)origin database:(NSString *)databaseIdentifier
{
    static const unsigned long long defaultQuota = 5 * 1024 * 1024;
    if ([origin respondsToSelector: @selector(setQuota:)]) {
        [origin performSelector:@selector(setQuota:) withObject:[NSNumber numberWithLongLong: defaultQuota]];
    } else {
        DDLogError(@"Could not increase quota to %llu bytes for database %@", defaultQuota, databaseIdentifier);
    }
}


#pragma mark WebFrameLoadDelegates

// Get the URL of the page being loaded
// Invoked when a page load is in progress in a given frame
- (void)webView:(SEBWebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
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
- (void)webView:(SEBWebView *)sender didFinishLoadForFrame:(WebFrame *)frame {

    [self backForwardButtonsSetEnabled];
    
    [self stopProgressIndicatorAnimation];
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
- (void)webView:(SEBWebView *)sender didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame {
    //[self stopProgressIndicatorAnimation];
    // Only report feedback for the main frame.
    if (frame == [sender mainFrame]){
        self.browserController.currentMainHost = [[[[frame provisionalDataSource] request] URL] host];
        //reset the flag for presentation option changes by flash
        [[MyGlobals sharedMyGlobals] setFlashChangedPresentationOptions:NO];
    }
}


- (void)webView:(SEBWebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
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
- (void)webView:(SEBWebView *)sender didFailProvisionalLoadWithError:(NSError *)error
       forFrame:(WebFrame *)frame {
    
    // Enable back/forward buttons according to availablility for this webview
    NSSegmentedControl *backForwardButtons = [(SEBBrowserWindowController *)self.windowController backForwardButtons];
    [backForwardButtons setEnabled:self.webView.canGoBack forSegment:0];
    [backForwardButtons setEnabled:self.webView.canGoForward forSegment:1];
    
    [self stopProgressIndicatorAnimation];
    
    if ([error code] != -999) {
        
        if ([error code] !=  WebKitErrorFrameLoadInterruptedByPolicyChange && !_browserController.directConfigDownloadAttempted) //this error can be ignored
        {
            DDLogError(@"Error in %s: %@", __FUNCTION__, error.description);

            //Is it a "plug-in handled load error"?
            
            
            //Close the About Window first, because it would hide the error alert
            [[NSNotificationCenter defaultCenter] postNotificationName:@"requestCloseAboutWindowNotification" object:self];
            
            NSString *titleString = NSLocalizedString(@"Error Loading Page",nil);
            NSString *messageString = [error localizedDescription];
            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
            [self makeKeyAndOrderFront:self];
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:titleString];
            [newAlert setInformativeText:messageString];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Retry", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            int answer = [newAlert runModal];

            switch(answer) {
                case NSAlertFirstButtonReturn:
                    //Retry: try reloading
                    //self.browserController.currentMainHost = nil;
                    DDLogInfo(@"Trying to reload after %s: Request: %@ URL: %@", __FUNCTION__, [[frame provisionalDataSource] request], [[frame provisionalDataSource] request].URL);

                    [[sender mainFrame] loadRequest:[[frame provisionalDataSource] request]];
                    return;
                default:
                    // Close a temporary browser window which might have been opened for loading a config file from a SEB URL
                    [_browserController openingConfigURLFailed];
                    return;
            }
        }
    }
}


// Invoked when an error occurs loading a committed data source
- (void)webView:(SEBWebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    
    // Enable back/forward buttons according to availablility for this webview
    NSSegmentedControl *backForwardButtons = [(SEBBrowserWindowController *)self.windowController backForwardButtons];
    [backForwardButtons setEnabled:self.webView.canGoBack forSegment:0];
    [backForwardButtons setEnabled:self.webView.canGoForward forSegment:1];
    
    [self stopProgressIndicatorAnimation];
    
    DDLogError(@"Error in %s: %lx %@", __FUNCTION__, (long)error.code, error.description);
    
    if (error.code != -999) {
        
        if (error.code !=  WebKitErrorFrameLoadInterruptedByPolicyChange && error.code != 204 && !_browserController.directConfigDownloadAttempted) //these errors can be ignored (204 = Plug-in handled load)
        {
            //Close the About Window first, because it would hide the error alert
            [[NSNotificationCenter defaultCenter] postNotificationName:@"requestCloseAboutWindowNotification" object:self];
            
            NSString *titleString = NSLocalizedString(@"Error Loading Page",nil);
            NSString *messageString = [error localizedDescription];
            
            [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
            [self makeKeyAndOrderFront:self];
            NSAlert *newAlert = [[NSAlert alloc] init];
            [newAlert setMessageText:titleString];
            [newAlert setInformativeText:messageString];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Retry", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [newAlert setAlertStyle:NSCriticalAlertStyle];
            int answer = [newAlert runModal];
            switch(answer) {
                case NSAlertFirstButtonReturn:
                    //Retry: try reloading
                    //self.browserController.currentMainHost = setCurrentMainHost:nil;
                    DDLogInfo(@"Trying to reload after %s: Request: %@ URL: %@", __FUNCTION__, [[frame dataSource] request], [[frame dataSource] request].URL);

                    [[sender mainFrame] loadRequest:[[frame dataSource] request]];
                    return;
                default:
                    // Close a temporary browser window which might have been opened for loading a config file from a SEB URL
                    [_browserController openingConfigURLFailed];
                    return;
            }
        }
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
    //// If enabled, filter content
    SEBURLFilter *URLFilter = [SEBURLFilter sharedSEBURLFilter];
    if (URLFilter.enableURLFilter && URLFilter.enableContentFilter) {
        URLFilterRuleActions filterActionResponse = [URLFilter testURLAllowed:request.URL];
        if (filterActionResponse != URLFilterActionAllow) {
            /// Content is not allowed: Show teach URL alert if activated or just indicate URL is blocked filterActionResponse == URLFilterActionBlock ||
            if (![self showURLFilterAlertSheetForWindow:self forRequest:request forContentFilter:YES filterResponse:filterActionResponse]) {
                /// User didn't allow the content, don't load it
                DDLogWarn(@"This content was blocked by the content filter: %@", request.URL.absoluteString);
                // Return nil instead of request
                return nil;
            }
        }
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
        
        const char *urlString = [browserExamKeyString UTF8String];
        
        CC_SHA256(urlString,
                  strlen(urlString),
                  hashedChars);

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
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:error.localizedDescription];
    [newAlert setInformativeText:error.localizedFailureReason];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [newAlert setAlertStyle:NSCriticalAlertStyle];
    [newAlert runModal];
}


// Invoked when an authentication challenge has been received for a resource
- (void)webView:(SEBWebView *)sender
       resource:(id)identifier
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
 fromDataSource:(WebDataSource *)dataSource
{
    DDLogInfo(@"webView: %@ resource: %@ didReceiveAuthenticationChallenge: %@ fromDataSource: %@", sender, identifier, challenge, dataSource);

    // Allow to enter password 3 times
    if ([challenge previousFailureCount] < 3) {
        // Display authentication dialog
        _pendingChallenge = challenge;
        
        NSString *text = [NSString stringWithFormat:@"%@://%@", challenge.protectionSpace.protocol, challenge.protectionSpace.host];
        if ([challenge previousFailureCount] == 0) {
            text = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"To proceed, you must log in to", nil), text];
            lastUsername = @"";
        } else {
            text = [NSString stringWithFormat:NSLocalizedString(@"The user name or password you entered for %@ was incorrect. Make sure you’re entering them correctly, and then try again.", nil), text];
        }
        
        [_browserController showEnterUsernamePasswordDialog:text
                                             modalForWindow:self
                                                windowTitle:NSLocalizedString(@"Authentication Required", nil)
                                                   username:lastUsername
                                              modalDelegate:self
                                             didEndSelector:@selector(enteredUsername:password:returnCode:)];
        
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        // inform the user that the user name and password
        // in the preferences are incorrect
    }
    
}


- (void)enteredUsername:(NSString *)username password:(NSString *)password returnCode:(NSInteger)returnCode
{
    DDLogDebug(@"Enter username password sheetDidEnd with return code: %ld", (long)returnCode);
    
    if (_pendingChallenge) {
        if (returnCode == SEBEnterPasswordOK) {
            lastUsername = username;
            NSURLCredential *newCredential = [NSURLCredential credentialWithUser:username
                                                                        password:password
                                                                     persistence:NSURLCredentialPersistenceForSession];
            [[_pendingChallenge sender] useCredential:newCredential
                           forAuthenticationChallenge:_pendingChallenge];
            _browserController.enteredCredential = newCredential;
            _pendingChallenge = nil;
        } else if (returnCode == SEBEnterPasswordCancel) {
            [[_pendingChallenge sender] cancelAuthenticationChallenge:_pendingChallenge];
            _browserController.enteredCredential = nil;
            _pendingChallenge = nil;
        } else {
            // Any other case as when the server aborted the authentication challenge
            _browserController.enteredCredential = nil;
            _pendingChallenge = nil;
        }
    }
}


// Invoked when an authentication challenge for a resource was canceled
- (void)webView:(SEBWebView *)sender
       resource:(id)identifier
didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
 fromDataSource:(WebDataSource *)dataSource
{
    DDLogInfo(@"webView: %@ resource: %@ didCancelAuthenticationChallenge: %@ fromDataSource: %@", sender, identifier, challenge, dataSource);
    [_browserController hideEnterUsernamePasswordDialog];
}


// Helper method to extract a filename from an anchor element with a "download" attribute
- (NSString *) getFilenameFromHTMLAnchorElement:(DOMHTMLAnchorElement *)parentNode
{
    NSString *filename;
    if ([parentNode respondsToSelector:@selector(outerHTML)]) {
        NSString *parentOuterHTML = parentNode.outerHTML;
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
    NSString *currentMainHost = self.browserController.currentMainHost;
    //NSString *requestedHost = [[request mainDocumentURL] host];
    
    if (request) {
        // Get the DOMNode from the information about the action that triggered the navigation request
        self.downloadFilename = nil;
        NSDictionary *webElementDict = [actionInformation valueForKey:@"WebActionElementKey"];
        if (webElementDict) {
            DOMNode *webElementDOMNode = [webElementDict valueForKey:@"WebElementDOMNode"];

            // Do we have a parentNode?
            if ([webElementDOMNode respondsToSelector:@selector(parentNode)]) {
            
                // Is the parent an anchor?
                DOMHTMLAnchorElement *parentNode = (DOMHTMLAnchorElement *)webElementDOMNode.parentNode;
                if ([parentNode respondsToSelector:@selector(nodeName)]) {
                    if ([parentNode.nodeName isEqualToString:@"A"]) {
                        self.downloadFilename = [self getFilenameFromHTMLAnchorElement:parentNode];
                    }
                }
                
                // Check if one of the children of the parent node is an anchor
                if ([parentNode respondsToSelector:@selector(children)]) {
                    // We had to check if we get children, bad formatted HTML and
                    // older WebKit versions would throw an exception here
                    DOMHTMLCollection *childrenNodes = parentNode.children;
                    int i;
                    for (i = 0; i < childrenNodes.length; i++) {
                        DOMHTMLAnchorElement *childNode = (DOMHTMLAnchorElement *)[childrenNodes item:i];
                        if ([childNode respondsToSelector:@selector(nodeName)]) {
                            if ([childNode.nodeName isEqualToString:@"A"]) {
                                self.downloadFilename = [self getFilenameFromHTMLAnchorElement:childNode];
                                break;
                            }
                        }
                    }
                }
            }
        }
        
        // Check if quit URL has been clicked (regardless of current URL Filter)
        if ([[[request URL] absoluteString] isEqualTo:[preferences secureStringForKey:@"org_safeexambrowser_SEB_quitURL"]]) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"requestQuitWPwdNotification" object:self];
            [listener ignore];
            return;
        }
        
        // If enabled, filter URL
        SEBURLFilter *URLFilter = [SEBURLFilter sharedSEBURLFilter];
        if (URLFilter.enableURLFilter) {
            URLFilterRuleActions filterActionResponse = [URLFilter testURLAllowed:request.URL];
            if (filterActionResponse != URLFilterActionAllow) {
                
                //// URL is not allowed
                
                // If the learning mode is active, display according sheet and ask user if he wants to allow this URL
                // Show alert for URL is not allowed as sheet on the WebView's window
                if (![self showURLFilterAlertSheetForWindow:self
                                                forRequest:request forContentFilter:NO filterResponse:filterActionResponse]) {
                    /// User didn't allow the URL
                    
                    // Check if the link was opened by a script and
                    // if a temporary webview or a new browser window should be closed therefore
                    // If the new page is supposed to open in a new browser window
                    SEBWebView *creatingWebView = [self.webView creatingWebView];
                    if (creatingWebView) {
                        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInNewWindow) {
                            // Don't load the request
                            //                    [listener ignore];
                            // we have to close the new browser window which already has been openend by WebKit
                            // Get the document for my web view
                            DDLogDebug(@"Originating browser window %@", sender);
                            // Close document and therefore also window
                            //Workaround: Flash crashes after closing window and then clicking some other link
                            [[self.webView preferences] setPlugInsEnabled:NO];
                            DDLogDebug(@"Now closing new document browser window for: %@", self.webView);
                            [self.browserController closeWebView:self.webView];
                        } else if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInSameWindow) {
                            if (self.webView) {
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
            [self.browserController openConfigFromSEBURL:request.URL];
            [listener ignore];
            return;
        }
    }

    if (currentMainHost && [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == getGenerallyBlocked) {
        [listener ignore];
        return;
    }
//    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptBlockForeign"]) {
//        //            NSString *requestedHost = [[request mainDocumentURL] host];
//        DDLogDebug(@"Current Host: %@", currentMainHost);
//        DDLogDebug(@"Requested Host: %@", requestedHost);
//        // If current host is not the same as the requested host
//        if (currentMainHost && (!requestedHost || ![currentMainHost isEqualToString:requestedHost])) {
//            [listener ignore];
//            // If the new page is supposed to open in a new browser window
//            if (requestedHost && self.webView && [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInNewWindow) {
//                // we have to close the new browser window which already has been openend by WebKit
//                // Get the document for my web view
//                DDLogDebug(@"Originating browser window %@", sender);
//                // Close document and therefore also window
//                //Workaround: Flash crashes after closing window and then clicking some other link
//                [[self.webView preferences] setPlugInsEnabled:NO];
//                DDLogDebug(@"Now closing new document browser window for: %@", self.webView);
//                [self.browserController closeWebView:self.webView];
//            }
//            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInSameWindow) {
//                if (self.webView) {
//                    [sender close]; //close the temporary webview
//                }
//            }
//            return;
//        }
//    }
    // Check if the new page is supposed to be opened in the same browser window
    if (currentMainHost && [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInSameWindow) {
        // Check if the request's sender is different than the current webview (means the sender is the temporary webview)
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
- (void)webView:(SEBWebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation
		request:(NSURLRequest *)request 
   newFrameName:(NSString *)frameName 
decisionListener:(id <WebPolicyDecisionListener>)listener {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    // First check if links requesting to be opened in a new windows are generally blocked
    if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] != getGenerallyBlocked) {

        //// If enabled, filter URL
        SEBURLFilter *URLFilter = [SEBURLFilter sharedSEBURLFilter];
        if (URLFilter.enableURLFilter) {
            URLFilterRuleActions filterActionResponse = [URLFilter testURLAllowed:request.URL];
            if (filterActionResponse != URLFilterActionAllow) {
                /// URL is not allowed: Show teach URL alert if activated or just indicate URL is blocked
                if (![self showURLFilterAlertSheetForWindow:self forRequest:request forContentFilter:NO filterResponse:filterActionResponse]) {
                    // User didn't allow the URL: Don't load the request
                    [listener ignore];
                    return;
                }
            }
        }
        
        // load link only if it's on the same host like the one of the current page
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkBlockForeign"] ||
            [self.browserController.currentMainHost isEqualToString:[[request mainDocumentURL] host]]) {
            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByLinkPolicy"] == openInNewWindow) {
                // Open new browser window containing WebView and show it
                SEBWebView *newWebView = [self.browserController openAndShowWebView];
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
//    if (([type isEqualToString:@"application/seb"]) || ([request.URL.pathExtension isEqualToString:@"seb"])) {
//        // If MIME-Type or extension of the file indicates a .seb file, we (conditionally) download and open it
//        [self.browserController downloadAndOpenSebConfigFromURL:request.URL];
//        [listener ignore];
//        return;
//    }
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
        }
    } else {
        self.downloadFileExtension = nil;
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
    // Create the request
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:60.0];
    // Create the download with the request and start loading the data.
    NSURLDownload  *theDownload = [[NSURLDownload alloc] initWithRequest:theRequest delegate:self];
    if (!theDownload) {
        DDLogError(@"Starting the download failed!"); //Inform the user that the download failed.
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
            [self.browserController downloadSEBConfigFileFromURL:downloadURL];
            // and cancel the download to disc below
        }
        // We cancel the download in any case, because .seb config files should be opened directly and not downloaded to disc
        [download cancel];
        return;
    }

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDownUploads"] == YES) {
        // If downloading is allowed
        downloadPath = [preferences secureStringForKey:@"org_safeexambrowser_SEB_downloadDirectoryOSX"];
        if (!downloadPath) {
            //if there's no path saved in preferences, set standard path
            downloadPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"];
            [preferences setSecureObject:downloadPath forKey:@"org_safeexambrowser_SEB_downloadDirectoryOSX"];
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
    // Release the download.
    
    // Inform the user
    [self presentError:error modalForWindow:self delegate:nil didPresentSelector:NULL contextInfo:NULL];

    DDLogError(@"Download failed! Error - %@ %@",
               error.description,
               [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}


- (void) downloadDidFinish:(NSURLDownload *)download
{
    // Release the download.
    
    DDLogInfo(@"Download of File %@ did finish.", downloadPath);
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_openDownloads"] == YES) {
    // Open downloaded file
    [[NSWorkspace sharedWorkspace] openFile:downloadPath];
    } else {
        // Inform user that download succeeded
        NSAlert *newAlert = [[NSAlert alloc] init];
        [newAlert setMessageText:NSLocalizedString(@"Download Finished", nil)];
        [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"%@ was downloaded.", nil), downloadPath]];
        [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [newAlert setAlertStyle:NSInformationalAlertStyle];
        [newAlert runModal];
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
