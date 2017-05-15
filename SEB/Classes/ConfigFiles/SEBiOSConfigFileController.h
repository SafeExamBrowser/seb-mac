//
//  SEBiOSConfigFileController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15/12/15.
//
//

#import <Foundation/Foundation.h>
#import "SEBConfigFileManager.h"
#import "SEBViewController.h"
#import <UIKit/UIKit.h>

@class SEBViewController;

@interface SEBiOSConfigFileController : SEBConfigFileManager <SEBConfigUIDelegate, UIAlertViewDelegate> {
    NSInteger alertButtonIndex;
}

@property (strong, nonatomic) SEBViewController *sebViewController;


@end
