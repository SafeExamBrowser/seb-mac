//
//  BrowserWindow.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 06.12.10.
//  Copyright (c) 2010-2020 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2020 Daniel R. Schneider, ETH Zurich, Educational Development
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
#import "HUDPanel.h"
#import "NSScreen+SEBScreen.h"

#include <CoreServices/CoreServices.h>

@implementation SEBBrowserWindow

@synthesize webView;


-(BOOL)canBecomeKeyWindow {
    return YES;
}

-(BOOL)canBecomeMainWindow {
    return YES;
}


- (NSTimeInterval)animationResizeTime:(NSRect)newFrame
{
    return 0.1;
}


// Overriding setTitle method to adjust position of progress indicator
- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    if (!_isFullScreen) {
        [self adjustPositionOfViewInTitleBar:_progressIndicatorHolder atRightOffsetToTitle:10 verticalOffset:0];
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
    }

    [self.browserController checkForClosingTemporaryWebView:self.webView];
    [self.browserController closeWebView:self.webView];
    return YES;
}


- (BOOL) isTemporaryWindowWhileStartingUp
{
    return self.webView.creatingWebView == self.webView;
}


// Setup browser window and webView delegates
- (void) awakeFromNib
{
    // Display or don't display toolbar
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    // No toolbar on full screen window
    if (!_isFullScreen) {
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
    
    _allowDownloads = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDownUploads"];
    _allowDeveloperConsole = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDeveloperConsole"];

    quitURLTrimmed = [[preferences secureStringForKey:@"org_safeexambrowser_SEB_quitURL"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    
    // Display all MIME types the WebView can display as HTML
    NSArray* MIMETypes = [WebView MIMETypesShownAsHTML];
    NSUInteger i, count = [MIMETypes count];
    for (i=0; i<count; i++) {
        DDLogDebug(@"MIME type shown as HTML: %@", [MIMETypes objectAtIndex:i]);
    }
}


- (void) setCalculatedFrame
{
    [self setCalculatedFrameOnScreen:self.screen];

}


- (void) setCalculatedFrameOnScreen:(NSScreen *)screen
{
    if (screen) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        // Get frame of the usable screen (considering if menu bar or SEB dock is enabled)
        NSRect screenFrame = [_browserController visibleFrameForScreen:screen];

        NSRect windowFrame;
        NSString *windowWidth;
        NSString *windowHeight;
        NSInteger windowPositioning;
        if (self == self.browserController.mainBrowserWindow) {
            // This is the main browser window
            if (_isFullScreen) {
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
          [theEvent type] == NSRightMouseDown)) {
        [super sendEvent:theEvent];
    } else {
        // Allow right mouse button/context menu according to setting
        // This is the only way how to block the context menu in browser plugins
        // and video players etc. (not on regular website elements)
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enableRightMouse"]) {
            [super sendEvent:theEvent];
        }
    }
}


// Overriding this method without calling super in OS X 10.7 Lion
// prevents the windows' position and size to be restored on restarting the app
- (void)restoreStateWithCoder:(NSCoder *)coder
{
    DDLogVerbose(@"BrowserWindow %@: Prevented windows' position and size to be restored!", self);
    return;
}


- (void) startProgressIndicatorAnimation {
    
    if (!_progressIndicatorHolder) {
        _progressIndicatorHolder = [[NSView alloc] init];
        
        NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] init];
        
        [progressIndicator setBezeled: NO];
        [progressIndicator setStyle: NSProgressIndicatorSpinningStyle];
        [progressIndicator setControlSize: NSSmallControlSize];
        [progressIndicator sizeToFit];
        //[progressIndicator setUsesThreadedAnimation:YES];
        
        [_progressIndicatorHolder addSubview:progressIndicator];
        [_progressIndicatorHolder setFrame:progressIndicator.frame];
        [progressIndicator startAnimation:self];
        
        if (_isFullScreen) {
            [self addViewToTitleBar:_progressIndicatorHolder atRightOffset:20];
        } else {
            [self addViewToTitleBar:_progressIndicatorHolder atRightOffsetToTitle:10 verticalOffset:0];
        }
        
        [progressIndicator setFrame:NSMakeRect(
                                               
                                               0.5 * ([progressIndicator superview].frame.size.width - progressIndicator.frame.size.width),
                                               0.5 * ([progressIndicator superview].frame.size.height - progressIndicator.frame.size.height),
                                               
                                               progressIndicator.frame.size.width,
                                               progressIndicator.frame.size.height
                                               
                                               )];
        
        [progressIndicator setNextResponder:_progressIndicatorHolder];
        [_progressIndicatorHolder setNextResponder:self];
    } else {
        if (!_isFullScreen) {
            [self adjustPositionOfViewInTitleBar:_progressIndicatorHolder atRightOffsetToTitle:10 verticalOffset:0];
        }
    }
}

- (void) stopProgressIndicatorAnimation {
    
    [_progressIndicatorHolder removeFromSuperview];
    _progressIndicatorHolder = nil;
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


// Enable back/forward buttons according to availablility for this webview
- (void)backForwardButtonsSetEnabled {
    NSSegmentedControl *backForwardButtons = [(SEBBrowserWindowController *)self.windowController backForwardButtons];
    [backForwardButtons setEnabled:self.webView.canGoBack forSegment:0];
    [backForwardButtons setEnabled:self.webView.canGoForward forSegment:1];
}


#pragma mark URL Filter Blocked Message

- (void) showURLFilterMessage {
    
    if (!_filterMessageHolder) {
        
        NSRect frameRect = NSMakeRect(0,0,155,21); // This will change based on the size you need
        NSTextField *message = [[NSTextField alloc] initWithFrame:frameRect];
        message.bezeled = NO;
        message.editable = NO;
        message.drawsBackground = NO;
        [message.cell setUsesSingleLineMode:YES];
        CGFloat messageLabelYOffset = 0;

        NSString *messageString;
        
        // Set message for URL blocked according to settings
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        switch ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_URLFilterMessage"]) {
                
            case URLFilterMessageText:
                message.stringValue = NSLocalizedString(@"URL Blocked!", nil);
                [message setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
                [message setTextColor:[NSColor redColor]];
                break;
                
            case URLFilterMessageX:
                message.stringValue = @"✕";
                [message setFont:[NSFont boldSystemFontOfSize:_isFullScreen ? 16 : 20]];
                [message setTextColor:[NSColor blackColor]];
                messageLabelYOffset = _isFullScreen ? 0 : 4;
                break;
        }

        NSButton *URLBlockedButton = [NSButton new];
        URLBlockedButton.title = messageString;
        [URLBlockedButton setButtonType:NSMomentaryLightButton];
        
        NSSize messageLabelSize = [message intrinsicContentSize];
        [message setAlignment:NSRightTextAlignment];
        CGFloat messageLabelWidth = messageLabelSize.width + 2;
        CGFloat messageLabelHeight = messageLabelSize.height;
        [message setFrameSize:NSMakeSize(messageLabelWidth, messageLabelHeight)];
        
        _filterMessageHolder = [[NSView alloc] initWithFrame:message.frame];
        [_filterMessageHolder addSubview:message];
        [_filterMessageHolder setContentHuggingPriority:NSLayoutPriorityFittingSizeCompression-1.0 forOrientation:NSLayoutConstraintOrientationVertical];
        
        [message setFrame:NSMakeRect(
                                     
                                     0.5 * ([message superview].frame.size.width - message.frame.size.width),
                                     (0.5 * ([message superview].frame.size.height - message.frame.size.height)) + messageLabelYOffset,
                                     
                                     message.frame.size.width,
                                     message.frame.size.height
                                     
                                     )];
        
        [message setNextResponder:_filterMessageHolder];
        
    }
    
    // Show the message
    if (_isFullScreen) {
        [self showURLBlockedHUD];
    } else {
        [self addViewToTitleBar:_filterMessageHolder atRightOffset:5];
        [_filterMessageHolder setNextResponder:self];
        
        // Remove the URL filter message after a delay
        [self performSelector:@selector(hideURLFilterMessage) withObject: nil afterDelay: 1];
    }
}

- (void) hideURLFilterMessage {
    
    [self.filterMessageHolder removeFromSuperview];
}


- (void) showURLBlockedHUD
{
    if (!_filterMessageHUD) {

        NSRect messageRect = _filterMessageHolder.frame;
        CGFloat horizontalPadding = 8.0;
        CGFloat verticalPadding = 5.0;
        
        NSRect backgroundRect = NSMakeRect(0, 0, messageRect.size.width+horizontalPadding*2, messageRect.size.height+verticalPadding*2);
        NSView *HUDBackground = [[NSView alloc] initWithFrame:backgroundRect];
        HUDBackground.wantsLayer = true;
        HUDBackground.layer.cornerRadius = MIN(horizontalPadding, verticalPadding);
        if (@available(macOS 10.8, *)) {
            HUDBackground.layer.backgroundColor = [NSColor lightGrayColor].CGColor;
        }
        
        [HUDBackground addSubview:_filterMessageHolder];
        [_filterMessageHolder setFrameOrigin:NSMakePoint(horizontalPadding, verticalPadding)];
        
        _filterMessageHUD = [[HUDPanel alloc] initWithContentRect:HUDBackground.bounds styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:false];
        _filterMessageHUD.backgroundColor = [NSColor clearColor];
        _filterMessageHUD.opaque = false;
        _filterMessageHUD.alphaValue = 0.75;

        _filterMessageHUD.contentView = HUDBackground;
    }
    NSRect visibleScreenRect = self.screen.usableFrame;
    NSPoint topLeftPoint;
    topLeftPoint.x = visibleScreenRect.origin.x + visibleScreenRect.size.width - _filterMessageHUD.frame.size.width - 42;
    topLeftPoint.y = visibleScreenRect.origin.y + visibleScreenRect.size.height - 3;
    [_filterMessageHUD setFrameTopLeftPoint:topLeftPoint];
    
    _filterMessageHUD.becomesKeyOnlyIfNeeded = YES;
    [_filterMessageHUD setLevel:NSModalPanelWindowLevel];
    DDLogDebug(@"Opening URL blocked HUD: %@", _filterMessageHUD);
    [_filterMessageHUD makeKeyAndOrderFront:nil];
    [_filterMessageHUD invalidateShadow];

    // Hide the HUD filter message after a delay
    [self performSelector:@selector(hideURLBlockedHUD) withObject: nil afterDelay: 1];
}


- (void) hideURLBlockedHUD
{
    [_filterMessageHUD orderOut:self];
}


#pragma mark URL Filter Teaching Mode Alert

- (BOOL) showURLFilterAlertSheetForWindow:(NSWindow *)window
                               forRequest:(NSURLRequest *)request
                         forContentFilter:(BOOL)contentFilter
                           filterResponse:(URLFilterRuleActions)filterResponse
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
                        
                        // Set full URL in the filter expression text field, trim a possible trailing "/"
                        self.filterExpressionField.string = [self.URLFilterAlertURL.absoluteString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
                        
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
    NSString *path = self.URLFilterAlertURL.path;
    if (!path || [path isEqualToString:@"/"]) {
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


#pragma mark Overriding NSWindow Methods

// This method is called by NSWindow’s zoom: method while determining the frame a window may be zoomed to
// We override the size calculation to take SEB Dock in account if it's displayed
- (NSRect)windowWillUseStandardFrame:(NSWindow *)window
                        defaultFrame:(NSRect)newFrame {
    // Check if SEB Dock is displayed and reduce visibleFrame accordingly
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // Get frame of the usable screen (considering if menu bar is enabled)
    NSRect screenFrame = self.screen.usableFrame;
    newFrame.size.height = screenFrame.size.height;
    
    if ((!_browserController.mainBrowserWindow || self.screen == _browserController.mainBrowserWindow.screen) && [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"]) {
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

- (void)webView:(SEBWebView *)sender runOpenPanelForFileButtonWithResultListener:(id < WebOpenPanelResultListener >)resultListener allowMultipleFiles:(BOOL)allowMultipleFiles;
// Choose file for upload
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (_allowDownloads == YES) {
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
                    
                    NSAlert *modalAlert = [self.browserController.sebController newAlert];
                    DDLogInfo(@"File to upload automatically chosen");
                    [modalAlert setMessageText:NSLocalizedString(@"File Automatically Chosen", nil)];
                    [modalAlert setInformativeText:NSLocalizedString(@"SEB will upload the same file which was downloaded before. If you edited it in a third party application, be sure you have saved it with the same name at the same path.", nil)];
                    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                    [modalAlert setAlertStyle:NSInformationalAlertStyle];
                    void (^alertOKHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                        [self.browserController.sebController removeAlertWindow:modalAlert.window];
                    };
                    [self.browserController.sebController runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))alertOKHandler];
                    return;
                }
            }
            
            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_chooseFileToUploadPolicy"] == onlyAllowUploadSameFileDownloadedBefore) {
                // if the policy is "Only allow to upload the same file downloaded before"
                [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
                [self makeKeyAndOrderFront:self];
                
                NSAlert *modalAlert = [self.browserController.sebController newAlert];
                DDLogError(@"File to upload (which was downloaded before) not found");
                [modalAlert setMessageText:NSLocalizedString(@"File to Upload Not Found!", nil)];
                [modalAlert setInformativeText:NSLocalizedString(@"SEB is configured to only allow uploading a file which was downloaded before. So download a file and if you edit it in a third party application, be sure to save it with the same name at the same path.", nil)];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
                [modalAlert setAlertStyle:NSCriticalAlertStyle];
                void (^alertOKHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                    [self.browserController.sebController removeAlertWindow:modalAlert.window];
                };
                [self.browserController.sebController runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))alertOKHandler];
                return;
            }
        }
        // Create the File Open Dialog class.
        NSOpenPanel* openFilePanel = [NSOpenPanel openPanel];
        
        // Enable the selection of files in the dialog.
        openFilePanel.canChooseFiles = YES;
        
        // Allow the user to open multiple files at a time.
        openFilePanel.allowsMultipleSelection = allowMultipleFiles;
        
        // Disable the selection of directories in the dialog.
        openFilePanel.canChooseDirectories = NO;
        
        // Change text of the open button in file dialog
        openFilePanel.prompt = NSLocalizedString(@"Choose",nil);
        
        // Change default directory in file dialog
        openFilePanel.directoryURL = [NSURL fileURLWithPath:[preferences secureStringForKey:@"org_safeexambrowser_SEB_downloadDirectoryOSX"] isDirectory:NO];
        
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
                                      NSMutableArray *filenames = [NSMutableArray new];
                                      for (NSURL *fileURL in files) {
                                          [filenames addObject:fileURL.path];
                                      }
                                      [resultListener chooseFilenames:filenames.copy];
                                  }
                              }];
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
initiatedByFrame:(WebFrame *)frame {
	NSString *pageTitle = [sender stringByEvaluatingJavaScriptFromString:@"document.title"];
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [self makeKeyAndOrderFront:self];
    
    NSAlert *modalAlert = [self.browserController.sebController newAlert];
    DDLogWarn(@"%s: %@", __FUNCTION__, message);
    [modalAlert setMessageText:pageTitle];
    [modalAlert setInformativeText:message];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [modalAlert setAlertStyle:NSInformationalAlertStyle];
    void (^alertOKHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
        [self.browserController.sebController removeAlertWindow:modalAlert.window];
    };
    [self.browserController.sebController runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))alertOKHandler];
}


// Delegate method for JavaScript confirmation panel
- (BOOL)webView:(SEBWebView *)sender runJavaScriptConfirmPanelWithMessage:(NSString *)message 
initiatedByFrame:(WebFrame *)frame {
	NSString *pageTitle = [sender stringByEvaluatingJavaScriptFromString:@"document.title"];
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [self makeKeyAndOrderFront:self];

    NSAlert *modalAlert = [self.browserController.sebController newAlert];
    DDLogInfo(@"%s: %@", __FUNCTION__, message);
    [modalAlert setMessageText:pageTitle];
    [modalAlert setInformativeText:message];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [modalAlert setAlertStyle:NSInformationalAlertStyle];
    NSModalResponse alertResultButton = [modalAlert runModal];
    [self.browserController.sebController removeAlertWindow:modalAlert.window];
    return alertResultButton == NSAlertFirstButtonReturn;
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
       forFrame:(WebFrame *)frame
{
    // Enable back/forward buttons according to availablility for this webview
    NSSegmentedControl *backForwardButtons = [(SEBBrowserWindowController *)self.windowController backForwardButtons];
    [backForwardButtons setEnabled:self.webView.canGoBack forSegment:0];
    [backForwardButtons setEnabled:self.webView.canGoForward forSegment:1];
    
    [self stopProgressIndicatorAnimation];
    
    if ([error code] != -999) {
        
        if ([error code] !=  WebKitErrorFrameLoadInterruptedByPolicyChange && !_browserController.directConfigDownloadAttempted) //this error can be ignored
        {
            DDLogError(@"Error in %s: %@", __FUNCTION__, error.description);
            
            // Show alert only if load of the main frame failed
            if (frame == [sender mainFrame]) {
                
                //Close the About Window first, because it would hide the error alert
                [[NSNotificationCenter defaultCenter] postNotificationName:@"requestCloseAboutWindowNotification" object:self];
                
                NSString *titleString = NSLocalizedString(@"Error Loading Page",nil);
                NSString *messageString = [error localizedDescription];
                [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
                [self makeKeyAndOrderFront:self];
                
                NSAlert *modalAlert = [self.browserController.sebController newAlert];
                [modalAlert setMessageText:titleString];
                [modalAlert setInformativeText:messageString];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"Retry", nil)];
                [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
                [modalAlert setAlertStyle:NSCriticalAlertStyle];
                void (^alertOKHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                    [self.browserController.sebController removeAlertWindow:modalAlert.window];
                    switch(answer) {
                        case NSAlertFirstButtonReturn:
                            //Retry: try reloading
                            //self.browserController.currentMainHost = nil;
                            DDLogInfo(@"Trying to reload after %s: Request: %@ URL: %@", __FUNCTION__, [[frame provisionalDataSource] request], [[frame provisionalDataSource] request].URL);
                            
                            [[sender mainFrame] loadRequest:[[frame provisionalDataSource] request]];
                            return;
                        default:
                            // Close a temporary browser window which might have been opened for loading a config file from a SEB URL
                            [self.browserController openingConfigURLFailed];
                            return;
                    }
                };
                [self.browserController.sebController runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))alertOKHandler];

            }
        }
    }
}


// Invoked when an error occurs loading a committed data source
- (void)webView:(SEBWebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
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
            NSAlert *modalAlert = [self.browserController.sebController newAlert];
            [modalAlert setMessageText:titleString];
            [modalAlert setInformativeText:messageString];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Retry", nil)];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [modalAlert setAlertStyle:NSCriticalAlertStyle];
            void (^alertAnswerHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
                [self.browserController.sebController removeAlertWindow:modalAlert.window];
                switch(answer) {
                    case NSAlertFirstButtonReturn:
                        //Retry: try reloading
                        //self.browserController.currentMainHost = setCurrentMainHost:nil;
                        DDLogInfo(@"Trying to reload after %s: Request: %@ URL: %@", __FUNCTION__, [[frame dataSource] request], [[frame dataSource] request].URL);
                        
                        [[sender mainFrame] loadRequest:[[frame dataSource] request]];
                        return;
                    default:
                        // Close a temporary browser window which might have been opened for loading a config file from a SEB URL
                        [self.browserController openingConfigURLFailed];
                        return;
                }
            };
            [self.browserController.sebController runModalAlert:modalAlert conditionallyForWindow:self completionHandler:(void (^)(NSModalResponse answer))alertAnswerHandler];
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
    SEBURLFilter *URLFilter = [SEBURLFilter sharedSEBURLFilter];
    if (URLFilter.enableURLFilter &&
        URLFilter.enableContentFilter &&
        ![self isTemporaryWindowWhileStartingUp]) {
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
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"]) {
        
        NSMutableURLRequest *modifiedRequest = [request mutableCopy];
        
        // Browser Exam Key
        
        NSData *browserExamKey = _browserController.browserExamKey;
#ifdef DEBUG
        DDLogVerbose(@"Current Browser Exam Key: %@", browserExamKey);
#endif
        unsigned char hashedChars[32];
        [browserExamKey getBytes:hashedChars length:32];
        
        NSMutableString* browserExamKeyString = [[NSMutableString alloc] initWithString:requestURLStrippedFragment];
        for (NSUInteger i = 0 ; i < 32 ; ++i) {
            [browserExamKeyString appendFormat: @"%02x", hashedChars[i]];
        }
#ifdef DEBUG
        DDLogVerbose(@"Current request URL + Browser Exam Key: %@", browserExamKeyString);
#endif
        const char *urlString = [browserExamKeyString UTF8String];
        CC_SHA256(urlString,
                  (uint)strlen(urlString),
                  hashedChars);

        NSMutableString* hashedString = [[NSMutableString alloc] initWithCapacity:32];
        for (NSUInteger i = 0 ; i < 32 ; ++i) {
            [hashedString appendFormat: @"%02x", hashedChars[i]];
        }
        [modifiedRequest setValue:hashedString forHTTPHeaderField:@"X-SafeExamBrowser-RequestHash"];

        // Config Key
        
        NSData *configKey = _browserController.configKey;
        [configKey getBytes:hashedChars length:32];
        
#ifdef DEBUG
        DDLogVerbose(@"Current Config Key: %@", configKey);
#endif
        
        NSMutableString* configKeyString = [[NSMutableString alloc] initWithString:requestURLStrippedFragment];
        for (NSUInteger i = 0 ; i < 32 ; ++i) {
            [configKeyString appendFormat: @"%02x", hashedChars[i]];
        }
#ifdef DEBUG
        DDLogVerbose(@"Current request URL + Config Key: %@", configKeyString);
#endif
        urlString = [configKeyString UTF8String];
        CC_SHA256(urlString,
                  (uint)strlen(urlString),
                  hashedChars);
        
        NSMutableString* hashedConfigKeyString = [[NSMutableString alloc] initWithCapacity:32];
        for (NSUInteger i = 0 ; i < 32 ; ++i) {
            [hashedConfigKeyString appendFormat: @"%02x", hashedChars[i]];
        }
        [modifiedRequest setValue:hashedConfigKeyString forHTTPHeaderField:@"X-SafeExamBrowser-ConfigKeyHash"];

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
            // If a temporary webview for loading config is open, close it
            [_browserController openingConfigURLFailed];
        } else {
            // Any other case as when the server aborted the authentication challenge
            _browserController.enteredCredential = nil;
            _pendingChallenge = nil;
            // If a temporary webview for loading config is open, close it
            [_browserController openingConfigURLFailed];
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
    NSString *currentMainHost = self.browserController.currentMainHost;
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
        if (URLFilter.enableURLFilter && ![self isTemporaryWindowWhileStartingUp]) {
            URLFilterRuleActions filterActionResponse = [URLFilter testURLAllowed:request.URL];
            if (filterActionResponse != URLFilterActionAllow) {
                
                //// URL is not allowed
                
                // If the learning mode is active, display according sheet and ask user if he wants to allow this URL
                // but only if we're dealing with a request in the main frame of the web page
                if (frame != self.webView.mainFrame) {
                    // Don't load the request
                    [listener ignore];
                    return;
                }
                // Show alert for URL is not allowed as sheet on the WebView's window
                if (![self showURLFilterAlertSheetForWindow:self
                                                 forRequest:request
                                           forContentFilter:NO
                                             filterResponse:filterActionResponse]) {
                    /// User didn't allow the URL
                    
                    // Check if the link was opened by a script and
                    // if a temporary webview or a new browser window should be closed therefore
                    // If the new page is supposed to open in a new browser window
                    SEBWebView *creatingWebView = [self.webView creatingWebView];
                    if (creatingWebView) {
                        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInNewWindow) {
                            // Don't load the request
                            //                    [listener ignore];
                            // we have to close the new browser window which already has been opened by WebKit
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
        if (URLFilter.enableURLFilter && ![self isTemporaryWindowWhileStartingUp]) {
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
