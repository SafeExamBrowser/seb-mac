//
//  SEBUIWebViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 05.03.21.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
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

#import <UIKit/UIKit.h>

#import "SEBAbstractWebView.h"
#import "SEBURLFilter.h"

@class SEBAbstractClassicWebView;
@class SEBWKNavigationAction;
@class SEBURLFilter;

NS_ASSUME_NONNULL_BEGIN

@interface SEBUIWebViewController : UIViewController <UIWebViewDelegate, SEBAbstractBrowserControllerDelegate>
{
    IBOutlet UIBarButtonItem *MainWebView;
    
    NSString *jsCode;
    
@private
    BOOL allowSpellCheck;
    BOOL mobileEnableGuidedAccessLinkTransform;
    BOOL enableDrawingEditor;
    BOOL openCloseSlider;
    BOOL waitingForConfigDownload;
}

@property (weak, nonatomic) id<SEBAbstractWebViewNavigationDelegate> navigationDelegate;

//@property (weak) SEBBrowserTabViewController *browserTabViewController;
@property (nonatomic, strong) UIWebView *sebWebView;
@property (strong) SEBURLFilter *urlFilter;
@property (strong) UIView *filterMessageHolder;
@property (strong) NSString *currentURL;
@property (strong) NSString *currentMainHost;
@property (readonly) BOOL isScrollLockActive;

- (NSInteger)highlightAllOccurencesOfString:(NSString*)searchString inWebView:(UIWebView *)webView;
- (void)removeAllHighlightsInWebView:(UIWebView *)webView;

- (id) infoValueForKey:(NSString *)key;
- (NSString *)tempDirectoryPath;

- (void)toggleScrollLock;
- (void)backToStart;
- (void)goBack;
- (void)goForward;
- (void)reload;
- (void)stopLoading;

- (void)loadURL:(NSURL *)url;

- (void)setBackForwardAvailabilty;

@end

NS_ASSUME_NONNULL_END
