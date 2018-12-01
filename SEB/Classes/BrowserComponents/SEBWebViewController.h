//
//  SEBWebViewController.h
//
//  Created by Daniel R. Schneider on 06/01/16.
//  Copyright (c) 2010-2018 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2018 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "SEBBrowserTabViewController.h"

#import "LGSideMenuController.h"
#import "UIViewController+LGSideMenuController.h"
#import "SEBURLFilter.h"

@class SEBBrowserTabViewController;
@class SEBURLFilter;

@interface SEBWebViewController : UIViewController <UIWebViewDelegate>
{
    IBOutlet UIBarButtonItem *MainWebView;
    
    NSString *jsCode;
    
@private
    BOOL allowSpellCheck;
    NSString *quitURLTrimmed;
    BOOL mobileEnableGuidedAccessLinkTransform;
    BOOL enableDrawingEditor;
}


@property (nonatomic, strong) SEBBrowserTabViewController *browserTabViewController;
@property (nonatomic, strong) UIWebView *sebWebView;
@property (strong) SEBURLFilter *urlFilter;
@property (strong) UIView *filterMessageHolder;
@property (strong) NSString *currentMainHost;


- (NSInteger)highlightAllOccurencesOfString:(NSString*)searchString inWebView:(UIWebView *)webView;
- (void)removeAllHighlightsInWebView:(UIWebView *)webView;

- (id) infoValueForKey:(NSString *)key;
- (NSString *)documentsDirectoryPath;

- (void)backToStart;
- (void)goBack;
- (void)goForward;
- (void)reload;
- (void)stopLoading;

- (void)loadURL:(NSURL *)url;

- (void)setBackForwardAvailabilty;

@end
