//
//  BrowserWindow.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 06.12.10.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import "SEBBrowserWindow.h"
#import "SEBConfigFileManager.h"
#import "SEBBrowserWindowDocument.h"
#import "NSWindow+SEBWindow.h"
#import "SEBURLFilter.h"
#import "NSURL+KKDomain.h"
#import "HUDPanel.h"
#import "NSScreen+SEBScreen.h"

#include <CoreServices/CoreServices.h>

@implementation SEBBrowserWindow

@synthesize webView;


- (void)addConstraintsToWebView:(NSView*) nativeWebView
{
    nativeWebView.translatesAutoresizingMaskIntoConstraints = NO;
    [nativeWebView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor].active = YES;
    [nativeWebView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
    [nativeWebView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor].active = YES;
    [nativeWebView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
}


- (NSArray *)accessibilityChildren {
    NSArray *subViews = self.contentView.superview.subviews;
    DDLogVerbose(@"Browser window contentView superview subviews: %@", subViews);
    
    return @[self.contentView.superview, self.contentView, self.accessibilityDock];
}


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
        // Post a notification that SEB/Session should conditionally quit
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestQuitNotification" object:self];
        
        return NO; //but don't close the window (that will happen anyways in case quitting is confirmed)
    }
    return YES;
}


- (BOOL) isTemporaryWindowWhileStartingUp
{
    return self.webView.creatingWebView == self.webView;
}


- (SEBBrowserWindowController *)browserWindowController
{
    return (SEBBrowserWindowController *)self.windowController;
}


// Setup browser window and webView delegates
- (void) awakeFromNib
{
    // No toolbar on full screen window
    if (!_isFullScreen) {
        // Display or don't display toolbar
        [self conditionallyDisplayToolbar];
    }
    _javaScriptFunctions = self.browserController.pageJavaScript;
    self.contentView.superview.accessibilityLabel = NSLocalizedString(@"Browser Window", nil);
    self.contentView.accessibilityLabel = NSLocalizedString(@"Web Content", nil);
}

- (void)performFindPanelAction:(id)sender
{
    long tag = ((NSMenuItem *)sender).tag;
    switch (tag) {
        case NSFindPanelActionShowFindPanel:
            [self searchText];
            break;
            
        case NSFindPanelActionNext:
            [self searchTextNext];
            break;
            
        case NSFindPanelActionPrevious:
            [self searchTextPrevious];
            break;
            
        default:
            break;
    }
}

- (void) searchText
{
    if (!_isFullScreen) {
        [self displayToolbar];
        [self.browserWindowController searchTextMatchFound:NO];
        [self makeFirstResponder:self.browserWindowController.textSearchField];
    }
}

- (void) searchTextNext
{
    if (!_isFullScreen) {
        [self.browserWindowController searchTextNext];
    }
}

- (void) searchTextPrevious
{
    if (!_isFullScreen) {
        [self.browserWindowController searchTextPrevious];
    }
}



- (void) conditionallyDisplayToolbar
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"] || ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_hideBrowserWindowToolbar"] || _toolbarWasHidden))
    {
        _toolbarWasHidden = NO;
        [self.toolbar setVisible:NO];
    } else {
        [self.toolbar setVisible:YES];
    }
}

- (void) displayToolbar
{
    if (!_isFullScreen && !self.toolbar.isVisible) {
        _toolbarWasHidden = !self.toolbar.isVisible;
        [self.toolbar setVisible:YES];
    }
}


- (void) setCalculatedFrame
{
    [self setCalculatedFrameOnScreen:self.screen mainBrowserWindow:NO temporaryWindow:NO];
}

- (void) setCalculatedFrameOnScreen:(NSScreen *)screen
{
    [self setCalculatedFrameOnScreen:self.screen mainBrowserWindow:NO temporaryWindow:NO];
}

- (void) setCalculatedFrameOnScreen:(NSScreen *)screen mainBrowserWindow:(BOOL)mainBrowserWindow temporaryWindow:(BOOL)temporaryWindow
{
    if (mainBrowserWindow || temporaryWindow) {
        screen = _browserController.mainScreen;
    }
    if (screen) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        // Get frame of the usable screen (considering if menu bar or SEB dock is enabled)
        NSRect screenFrame = [_browserController visibleFrameForScreen:screen];

        NSRect windowFrame;
        NSString *windowWidth;
        NSString *windowHeight;
        NSInteger windowPositioning;
        if (mainBrowserWindow || self == self.browserController.mainBrowserWindow) {
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
        } else if (temporaryWindow || (self.webView && self.webView == self.browserController.temporaryWebView)) {
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
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enableRightMouseMac"]) {
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


- (void) activateInitialFirstResponder
{
    if (self.toolbar.isVisible) {
        [self.browserWindowController activateInitialFirstResponder];
    } else {
        [self focusFirstElement];
    }
}

- (void) makeContentFirstResponder
{
    [self makeFirstResponder:(NSResponder *)[self nativeWebView]];
}

- (void) goToDock
{
    [self.browserController goToDock];
}

- (void)goBack
{
    [self.browserControllerDelegate goBack];
}

- (void)goForward
{
    [self.browserControllerDelegate goForward];
}

- (void)reload
{
    if (self.webView.isReloadAllowed) {
        if (self.webView.showReloadWarning) {
            // Display warning and ask if to reload page
            NSAlert *newAlert = [self.browserController.sebController newAlert];
            [newAlert setMessageText:NSLocalizedString(@"Reload Current Page", nil)];
            [newAlert setInformativeText:NSLocalizedString(@"Do you really want to reload the current web page?", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Reload", nil)];
            [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [newAlert setAlertStyle:NSWarningAlertStyle];
            
            void (^conditionalReload)(NSModalResponse) = ^void (NSModalResponse answer) {
                [self.browserController.sebController removeAlertWindow:newAlert.window];
                switch(answer) {
                    case NSAlertFirstButtonReturn:
                        [self unconditionallyReload];
                        break;
                    
                        
                    default:
                        // Return without reloading page
                        return;
                }
            };
            
            [self.browserController.sebController runModalAlert:newAlert conditionallyForWindow:self completionHandler:conditionalReload];
            
        } else {
            // Reload page without displaying warning
            [self unconditionallyReload];
        }
    }
}

- (void)unconditionallyReload
{
    // Reset the list of dismissed URLs and the dismissAll flag
    // (for the Teach allowed/blocked URLs mode)
    SEBAbstractWebView *creatingWebView = [self.webView creatingWebView];
    if (!creatingWebView) {
        creatingWebView = self.webView;
    }
    [creatingWebView.notAllowedURLs removeAllObjects];
    creatingWebView.dismissAll = NO;
    
    // Reload page
    DDLogInfo(@"Reloading current webpage");
    [self.browserControllerDelegate reload];
}


- (void) focusFirstElement
{
    [self.browserControllerDelegate focusFirstElement];
}

- (void) focusLastElement
{
    [self.browserControllerDelegate focusLastElement];
}


- (void)zoomPageIn:(id)sender
{
    [self zoomPageIn];
}

- (void)zoomPageOut:(id)sender
{
    [self zoomPageOut];
}

- (void)resetPageZoom:(id)sender
{
    [self zoomPageReset];
}


- (void)zoomPageIn
{
    [self.browserControllerDelegate zoomPageIn];
}


- (void)zoomPageOut
{
    [self.browserControllerDelegate zoomPageOut];
}


- (void)zoomPageReset
{
    [self.browserControllerDelegate zoomPageReset];
}


- (void)makeTextLarger:(id)sender
{
    [self textSizeIncrease];
}

- (void)makeTextSmaller:(id)sender
{
    [self textSizeDecrease];
}

- (void)makeTextStandardSize:(id)sender
{
    [self textSizeReset];
}


- (void)textSizeIncrease
{
    [self.browserControllerDelegate textSizeIncrease];
}


- (void)textSizeDecrease
{
    [self.browserControllerDelegate textSizeDecrease];
}


- (void)textSizeReset
{
    [self.browserControllerDelegate textSizeReset];
}


- (void) privateCopy:(id)sender
{
    [self.browserControllerDelegate privateCopy:sender];
}

- (void) privateCut:(id)sender
{
    [self.browserControllerDelegate privateCut:sender];
}

- (void) privatePaste:(id)sender
{
    [self.browserControllerDelegate privatePaste:sender];
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
        SEBAbstractWebView *creatingWebView = [self.webView creatingWebView];
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
                        
                        if (@available(macOS 12.0, *)) {
                        } else {
                            if (@available(macOS 11.0, *)) {
                                if (!window && (self.browserController.sebController.isAACEnabled || self.browserController.sebController.wasAACEnabled)) {
                                    window = self.browserController.mainBrowserWindow;
                                }
                            }
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


#pragma mark - SEBAbstractBrowserControllerDelegate Methods

- (nonnull id)nativeWebView {
    return [self.browserControllerDelegate nativeWebView];

}


- (nullable NSURL *)url {
    return [self.browserControllerDelegate url];
}


- (nullable NSString *)pageTitle {
    return [self.browserControllerDelegate pageTitle];
}


- (BOOL)canGoBack {
    return [self.browserControllerDelegate canGoBack];
}


- (BOOL)canGoForward {
    return [self.browserControllerDelegate canGoForward];
}


- (void)loadURL:(nonnull NSURL *)url {
    [self.browserControllerDelegate loadURL:url];
}


- (void)stopLoading {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setLoading:NO];
    });
}


- (void) searchText:(NSString *)textToSearch backwards:(BOOL)backwards caseSensitive:(BOOL)caseSensitive
{
    [self.browserControllerDelegate searchText:textToSearch backwards:backwards caseSensitive:caseSensitive];
}


- (void) searchTextMatchFound:(BOOL)matchFound
{
    [self.browserWindowController searchTextMatchFound:matchFound];
}


- (void)setDownloadingSEBConfig:(BOOL)downloadingSEBConfig {
    self.browserControllerDelegate.downloadingSEBConfig = downloadingSEBConfig;
}


#pragma mark SEBAbstractWebViewNavigationDelegate Methods

- (WKWebViewConfiguration *) wkWebViewConfiguration
{
    return self.browserController.wkWebViewConfiguration;
}

- (id) accessibilityDock
{
    return self.browserController.accessibilityDock;
}


- (void) setPageTitle:(NSString *)title
{
    [self sebWebViewDidUpdateTitle:title];
}


- (void) setLoading:(BOOL)loading
{
    if (loading) {
        [self startProgressIndicatorAnimation];
    } else {
        [self stopProgressIndicatorAnimation];
    }
    [self.browserController setLoading:loading];
}

- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
{
    // Enable back/forward buttons according to availablility for this webview
    NSSegmentedControl *backForwardButtons = [self.browserWindowController backForwardButtons];
    [backForwardButtons setEnabled:canGoBack forSegment:0];
    [backForwardButtons setEnabled:canGoForward forSegment:1];
    
    [self.browserController setCanGoBack:canGoBack canGoForward:canGoForward];
}

- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies forURL:(NSURL *)url
{
    [self.browserController examineCookies:cookies forURL:url];
}

- (void) examineHeaders:(NSDictionary<NSString *,NSString *>*)headerFields forURL:(NSURL *)url
{
    [self.browserController examineHeaders:headerFields forURL:url];
}

- (void) firstDOMElementDeselected
{
    if (!self.toolbar.isVisible) {
        [self.browserController firstDOMElementDeselected];
    }
}

- (void) lastDOMElementDeselected
{
    if (!self.toolbar.isVisible) {
        [self.browserController lastDOMElementDeselected];
    }
}

- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
                             configuration:(WKWebViewConfiguration *)configuration
{
    return [self.browserController openNewTabWithURL:url configuration:configuration];
}

- (SEBAbstractWebView *) openNewWebViewWindowWithURL:(NSURL *)url
                                       configuration:(WKWebViewConfiguration *)configuration
{
    return [self.browserController openNewWebViewWindowWithURL:url configuration:configuration];
}

- (void) makeActiveAndOrderFront
{
    [self makeKeyAndOrderFront:self];
}

- (void) showWebView:(SEBAbstractWebView *)webView
{
    [self.browserController showWebView:webView];
}

- (void) closeWebView
{
    [self.browserController closeWebView:self.abstractWebView];
}

- (void) closeWebView:(SEBAbstractWebView *)webView
{
    [self.browserController closeWebView:webView];
}

- (void) addWebView:(id)nativeWebView
{
    [self.contentView addSubview:nativeWebView];
    [self addConstraintsToWebView:(NSView *)nativeWebView];
}


- (NSString *)currentMainHost
{
    return self.browserController.currentMainHost;
}

- (void)setCurrentMainHost:(NSString *)currentMainHost
{
    self.browserController.currentMainHost = currentMainHost;
}

- (BOOL) isMainBrowserWebViewActive
{
    return self.webView.isMainBrowserWebView;
}

- (BOOL) isNavigationAllowed
{
    if (self.webView) {
        return self.webView.isNavigationAllowed;
    } else {
        return [self isNavigationAllowedMainWebView:self.browserController.isMainBrowserWebViewActive];
    }
}

- (BOOL) isNavigationAllowedMainWebView:(BOOL)mainWebView
{
    return [self.browserController isNavigationAllowedMainWebView:mainWebView];
}

- (BOOL) isReloadAllowed
{
    if (self.webView) {
        return self.webView.isReloadAllowed;
    } else {
        return [self isReloadAllowedMainWebView:self.browserController.isMainBrowserWebViewActive];
    }
}

- (BOOL) isReloadAllowedMainWebView:(BOOL)mainWebView
{
    return [self.browserController isReloadAllowedMainWebView:mainWebView];
}

- (BOOL) showReloadWarning
{
    if (self.webView) {
        return self.webView.showReloadWarning;
    } else {
        return [self showReloadWarningMainWebView:self.browserController.isMainBrowserWebViewActive];
    }
}

- (BOOL) showReloadWarningMainWebView:(BOOL)mainWebView
{
    return [self.browserController showReloadWarningMainWebView:mainWebView];
}

- (NSString *) webPageTitle:(NSString *)title orURL:(NSURL *)url mainWebView:(BOOL)mainWebView
{
    return [self.browserController webPageTitle:title orURL:url mainWebView:mainWebView];
}

- (NSString *)quitURL
{
    return self.browserController.quitURL;
}

- (NSString *)pageJavaScript
{
    return self.browserController.pageJavaScript;
}

- (BOOL)allowDownUploads
{
    return self.browserController.allowDownUploads;
}

- (void)showAlertNotAllowedDownUploading:(BOOL)uploading
{
    [self.browserController showAlertNotAllowedDownUploading:uploading];
}

- (BOOL)overrideAllowSpellCheck
{
    return self.browserController.overrideAllowSpellCheck;
}

- (NSURLRequest *)modifyRequest:(NSURLRequest *)request
{
    return [self.browserController modifyRequest:request];
}

- (NSString *) browserExamKeyForURL:(NSURL *)url
{
    return [self.browserController browserExamKeyForURL:url];
}

- (NSString *) configKeyForURL:(NSURL *)url
{
    return [self.browserController configKeyForURL:url];
}

- (NSString *) appVersion
{
    return [self.browserController appVersion];
}


@synthesize customSEBUserAgent;

- (NSString *) customSEBUserAgent
{
    return self.browserController.customSEBUserAgent;
    
}


- (NSArray <NSData *> *) privatePasteboardItems
{
    return self.browserController.privatePasteboardItems;
}

- (void) setPrivatePasteboardItems:(NSArray<NSData *> *)privatePasteboardItems
{
    self.browserController.privatePasteboardItems = privatePasteboardItems;
}


- (void) presentAlertWithTitle:(NSString *)title
                       message:(NSString *)message
{
    [self.browserController presentAlertWithTitle:title message:message];
}


- (id) window
{
    return self;
}

- (BOOL) isAACEnabled
{
    return self.browserController.isAACEnabled;
}


- (void)sebWebViewDidStartLoad
{
    [self setLoading:YES];
}

- (void)sebWebViewDidFinishLoad
{
    [self setLoading:NO];
    [self.browserWindowController sebWebViewDidFinishLoad];

}

- (void)sebWebViewDidFailLoadWithError:(NSError *)error
{
    // Don't display the errors 102 "Frame load interrupted", this can be caused by
    // the URL filter canceling loading a blocked URL,
    // and 204 "Plug-in handled load"
    if (error.code != 102 && error.code != 204 && !(self.browserController.directConfigDownloadAttempted)) {
        NSString *failingURLString = [error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey];
        NSString *errorMessage = error.localizedDescription;
        DDLogError(@"%s: Load error with localized description: %@", __FUNCTION__, errorMessage);
        
        //Close the About Window first, because it would hide the error alert
        [[NSNotificationCenter defaultCenter] postNotificationName:@"requestCloseAboutWindowNotification" object:self];
        
        NSString *titleString = NSLocalizedString(@"Load Error",nil);
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        [self makeKeyAndOrderFront:self];
        
        NSAlert *modalAlert = [self.browserController.sebController newAlert];
        [modalAlert setMessageText:titleString];
        [modalAlert setInformativeText:errorMessage];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"Retry", nil)];
        [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [modalAlert setAlertStyle:NSCriticalAlertStyle];
        void (^alertOKHandler)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self.browserController.sebController removeAlertWindow:modalAlert.window];
            switch(answer) {
                case NSAlertFirstButtonReturn:
                {
                    //Retry: try reloading
                    //self.browserController.currentMainHost = nil;
                    DDLogInfo(@"Trying to reload after %s: %@, localized error: %@", __FUNCTION__, error.description, errorMessage);
                    NSURL *failingURL = [NSURL URLWithString:failingURLString];
                    if (failingURL) {
                        [self.browserControllerDelegate loadURL:failingURL];
                    }
                    return;
                }
                default:
                    // Close a temporary browser window which might have been opened for loading a config file from a SEB URL
                    [self.browserController openingConfigURLFailed];
                    return;
            }
        };
        [self.browserController.sebController runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))alertOKHandler];
    }
}

- (void)sebWebViewDidUpdateTitle:(nullable NSString *)title
{
    title = [self.browserController webPageTitle:title orURL:self.webView.url mainWebView:self.webView.isMainBrowserWebView];
    [self.browserController setTitle: title forWindow:self withWebView:self.webView];
    NSString* versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
    NSString* appTitleString = [NSString stringWithFormat:@"%@ %@  —  %@",
                                SEBFullAppNameClassic,
                                versionString,
                                title];
    CGFloat windowWidth = [NSWindow minFrameWidthWithTitle:appTitleString styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask];
    if (windowWidth > self.frame.size.width) {
        appTitleString = [NSString stringWithFormat:@"SEB %@  —  %@",
                                    [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"],
                                    title];
    }
    DDLogInfo(@"BrowserWindow %@: Title of current Page: %@", self, appTitleString);
    [self setTitle:appTitleString];
}

- (void)webView:(WKWebView *)webView
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    if (_browserController == nil) {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    } else {
        [self.browserController webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
    }
}

- (void)webView:(WKWebView *)webView
runJavaScriptAlertPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(void))completionHandler
{
    NSString *pageTitle = webView.title;
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
        completionHandler();
    };
    [self.browserController.sebController runModalAlert:modalAlert conditionallyForWindow:self.browserController.mainBrowserWindow completionHandler:(void (^)(NSModalResponse answer))alertOKHandler];
}


- (void)pageTitle:(NSString *)pageTitle
runJavaScriptAlertPanelWithMessage:(NSString *)message
{
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


- (void)webView:(WKWebView *)webView
runJavaScriptConfirmPanelWithMessage:(NSString *)message
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(BOOL result))completionHandler
{
    NSString *pageTitle = webView.title;
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [self makeKeyAndOrderFront:self];
    
    NSModalResponse alertResultButton;
    if (@available(macOS 12.0, *)) {
    } else {
        if (@available(macOS 11.0, *)) {
            if (self.browserController.sebController.isAACEnabled || self.browserController.sebController.wasAACEnabled) {
                alertResultButton = [self showCustomModalAlert:[NSString stringWithFormat:@"%@\n\n%@", pageTitle, message]];
                completionHandler(YES);
            }
        }
    }
    NSAlert *modalAlert = [self.browserController.sebController newAlert];
    DDLogInfo(@"%s: %@", __FUNCTION__, message);
    [modalAlert setMessageText:pageTitle];
    [modalAlert setInformativeText:message];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [modalAlert setAlertStyle:NSInformationalAlertStyle];
    alertResultButton = [modalAlert runModal];
    
    [self.browserController.sebController removeAlertWindow:modalAlert.window];
    completionHandler(alertResultButton == NSAlertFirstButtonReturn);
}


- (BOOL)pageTitle:(NSString *)pageTitle
runJavaScriptConfirmPanelWithMessage:(NSString *)message
{
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    [self makeKeyAndOrderFront:self];
    
    NSModalResponse alertResultButton;
    if (@available(macOS 12.0, *)) {
    } else {
        if (@available(macOS 11.0, *)) {
            if (self.browserController.sebController.isAACEnabled || self.browserController.sebController.wasAACEnabled) {
                alertResultButton = [self showCustomModalAlert:[NSString stringWithFormat:@"%@\n\n%@", pageTitle, message]];
                return alertResultButton == NSAlertFirstButtonReturn;
            }
        }
    }
    NSAlert *modalAlert = [self.browserController.sebController newAlert];
    DDLogInfo(@"%s: %@", __FUNCTION__, message);
    [modalAlert setMessageText:pageTitle];
    [modalAlert setInformativeText:message];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [modalAlert setAlertStyle:NSInformationalAlertStyle];
    alertResultButton = [modalAlert runModal];
    
    [self.browserController.sebController removeAlertWindow:modalAlert.window];
    return alertResultButton == NSAlertFirstButtonReturn;
}


- (IBAction) customAlertOKButton: (id)sender {
    [NSApp stopModalWithCode:NSAlertFirstButtonReturn];
}


- (IBAction) customAlertCancelButton: (id)sender {
    [NSApp stopModalWithCode:NSAlertSecondButtonReturn];
}


- (NSModalResponse) showCustomModalAlert:(NSString *)text
{
    self.customAlertText.stringValue = text;
    [NSApp beginSheet: self.customAlert
       modalForWindow: self
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    NSModalResponse answer = [NSApp runModalForWindow: self];
    [NSApp endSheet: self.customAlert];
    [NSApp abortModal];
    [self.customAlert orderOut: self];
    return answer;
}


- (void)webView:(WKWebView *)webView
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
    defaultText:(nullable NSString *)defaultText
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSString *result))completionHandler
{
    [self.browserController webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
}


- (NSString *)pageTitle:(NSString *)pageTitle
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
            defaultText:(NSString *)defaultText
{
    return [self.browserController pageTitle:pageTitle runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText];
}


- (void)webView:(WKWebView *)webView
runOpenPanelWithParameters:(id)parameters
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSArray<NSURL *> *URLs))completionHandler
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (self.allowDownUploads) {
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
                    completionHandler(@[[NSURL fileURLWithPath:lastDownloadPath]]);
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
        
        if (@available(macOS 10.12, *)) {
            if ([[parameters class] isEqual:WKOpenPanelParameters.class]) {
                // Is selection of multiple files at a time allowed?
                openFilePanel.allowsMultipleSelection = ((WKOpenPanelParameters *)parameters).allowsMultipleSelection;
                // Is selection of directories allowed?
                if (@available(macOS 10.13.4, *)) {
                    openFilePanel.canChooseDirectories = ((WKOpenPanelParameters *)parameters).allowsDirectories;
                } else {
                    openFilePanel.canChooseDirectories = NO;
                }
            }
        }
        if ([parameters respondsToSelector: @selector(boolValue)]) {
            openFilePanel.allowsMultipleSelection = ((NSNumber *)parameters).boolValue;
            openFilePanel.canChooseDirectories = NO;
        }
        
        // Change text of the open button in file dialog
        openFilePanel.prompt = NSLocalizedString(@"Choose",nil);
        
        // Change default directory in file dialog
        NSString *downloadPath = [preferences secureStringForKey:@"org_safeexambrowser_SEB_downloadDirectoryOSX"];
        if (downloadPath.length == 0) {
            //if there's no path saved in preferences, set standard path
            downloadPath = @"~/Downloads";
        }
        downloadPath = [downloadPath stringByExpandingTildeInPath];
        openFilePanel.directoryURL = [NSURL fileURLWithPathString:downloadPath];
        
        [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
        [self makeKeyAndOrderFront:self];
        
        // Display the dialog.  If the OK button was pressed,
        // process the files.
        [openFilePanel beginSheetModalForWindow:self
                              completionHandler:^(NSInteger result) {
            if (result == NSFileHandlingPanelOKButton) {
                // Get an array containing the full filenames of all
                // files and directories selected.
                NSArray* fileURLs = [openFilePanel URLs];
                completionHandler(fileURLs);
            } else {
                completionHandler(nil);
            }
        }];
    } else {
        completionHandler(nil);
        [self.browserController showAlertNotAllowedDownUploading:YES];
    }
}


- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url
{
    [self.browserController shouldStartLoadFormSubmittedURL:url];
}


- (void) transferCookiesToWKWebViewWithCompletionHandler:(void (^)(void))completionHandler
{
    [self.browserController transferCookiesToWKWebViewWithCompletionHandler:completionHandler];
}


- (BOOL) showURLFilterAlertForRequest:(NSURLRequest *)request
                     forContentFilter:(BOOL)contentFilter
                       filterResponse:(URLFilterRuleActions)filterResponse
{
    return [self showURLFilterAlertSheetForWindow:self forRequest:request forContentFilter:contentFilter filterResponse:filterResponse];
}


- (NSURL *) downloadPathURL
{
    return self.browserController.downloadPathURL;
}


- (void) downloadFileFromURL:(NSURL *)url filename:(NSString *)filename cookies:(NSArray <NSHTTPCookie *>*)cookies
{
    [self.browserController downloadFileFromURL:url filename:filename cookies:cookies sender:self];
}


- (void) conditionallyDownloadAndOpenSEBConfigFromURL:(NSURL *)url
{
    [self.browserController openConfigFromSEBURL:url];
}


- (void) openSEBConfigFromData:(NSData *)sebConfigData;
{
    [self.browserController.sebController storeNewSEBSettingsFromData:sebConfigData];
}


- (void) downloadSEBConfigFileFromURL:(NSURL *)url originalURL:(NSURL *)originalURL cookies:(NSArray <NSHTTPCookie *>*)cookies
{
    [self.browserController downloadSEBConfigFileFromURL:url originalURL:originalURL cookies:cookies sender:self];
}


- (BOOL) downloadingInTemporaryWebView
{
    return [self.browserController downloadingInTemporaryWebView];
}


@end
