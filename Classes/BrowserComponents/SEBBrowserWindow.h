//
//  BrowserWindow.h
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

// Browser window class, also containing all the web view delegates

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "SEBBrowserWindowController.h"
#import "SEBWebView.h"
#import "SEBEncryptedUserDefaultsController.h"
#import "SEBOSXBrowserController.h"
#import "SEBTextField.h"

@class SEBOSXBrowserController;

@interface SEBBrowserWindow : NSWindow <NSWindowDelegate, NSURLDownloadDelegate, NSTextViewDelegate, WebUIDelegate, WebPolicyDelegate, WebFrameLoadDelegate, WebResourceLoadDelegate>

{
    SEBWebView *requestingWebView;
    NSString *currentURL;
    NSString *downloadPath;
    NSView *progressIndicatorHolder;
    NSURL *downloadURL;
    
}

@property (weak) SEBOSXBrowserController *browserController;
@property (weak) IBOutlet SEBWebView *webView;
@property (strong) IBOutlet NSWindow *URLFilterAlert;
@property (weak) IBOutlet SEBTextField *URLFilterAlertText;
@property (strong) IBOutlet NSURL *URLFilterAlertURL;
@property (strong) NSString *filterExpression;
@property (weak) IBOutlet NSMatrix *filterPatternMatrix;
@property (strong) IBOutlet NSTextView *filterExpressionField;
@property BOOL isFullScreen;
@property BOOL isPanel;
@property (weak) IBOutlet NSButton *domainPatternButton;
@property (weak) IBOutlet NSButton *hostPatternButton;
@property (weak) IBOutlet NSButton *hostPathPatternButton;
@property (weak) IBOutlet NSButton *directoryPatternButton;
@property (strong) NSView *filterMessageHolder;

@property (copy) NSString *downloadFilename;
@property (copy) NSString *downloadFileExtension;

- (void) setCalculatedFrame;

- (void) startProgressIndicatorAnimation;
- (void) stopProgressIndicatorAnimation;

- (void) startDownloadingURL:(NSURL *)url;

- (NSView*) findFlashViewInView:(NSView*)view;


@end
