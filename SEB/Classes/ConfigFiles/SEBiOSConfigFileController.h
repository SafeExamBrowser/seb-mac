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

@class SEBViewController;

@interface SEBiOSConfigFileController : SEBConfigFileManager <SEBConfigUIDelegate> {
    NSInteger alertButtonIndex;
}

@property (strong, nonatomic) SEBViewController *sebViewController;

@property (strong, nonatomic) UIAlertController *alertController;

@end
