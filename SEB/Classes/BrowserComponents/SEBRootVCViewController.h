//
//  SEBRootVCViewController.h
//  TellTheWeb
//
//  Created by Daniel R. Schneider on 18/04/14.
//  Copyright (c) 2014 art technologies Schneider & Schneider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+MMDrawerController.h"
#import "SEBWebViewController.h"
#import "SEBSearchBarViewController.h"

@class SEBWebViewController;
@class SEBSearchBarViewController;

@interface SEBRootVCViewController : UIViewController {
    UIBarButtonItem *leftButton;
}

@property (nonatomic, strong) SEBWebViewController *webViewController;
@property (nonatomic, strong) SEBSearchBarViewController *searchBarController;

- (void)searchStarted;
- (void)searchStopped;
- (void)searchGoSearchString:(NSString *)searchString;

- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;
- (IBAction)reload:(id)sender;


@end
