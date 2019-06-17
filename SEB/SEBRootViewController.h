//
//  SEBRootViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.06.19.
//

#import <UIKit/UIKit.h>

#import "LGSideMenuController.h"
#import "UIViewController+LGSideMenuController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SEBRootViewController : UIViewController

@property (weak, nonatomic) LGSideMenuController *lgSideMenuController;

@end

NS_ASSUME_NONNULL_END
