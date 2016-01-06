//
//  SEBSearchBarControllerViewController.h
//  TellTheWeb
//
//  Created by Daniel R. Schneider on 24/05/14.
//  Copyright (c) 2014 art technologies Schneider & Schneider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "SEBRootVCViewController.h"
#import "SEBWebViewController.h"
#import "SEBTextField.h"

@class SEBWebViewController;
@class SEBRootVCViewController;

@interface SEBSearchBarViewController : UIViewController <UITextFieldDelegate>
{
    BOOL shouldBeginEditing;
    
    UIImage *reloadButtonImage;
    UIImage *stopLoadingButtonImage;

}

@property (nonatomic, strong) SEBRootVCViewController *rootViewController;
@property (nonatomic, strong) SEBWebViewController *webViewController;

@property (nonatomic, strong) SEBTextField *searchBar;
@property (nonatomic, strong) UIButton *searchBarRightButton;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, assign) BOOL loading;

-(void)cancelButtonPressed;

@end
