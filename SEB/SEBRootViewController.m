//
//  SEBRootViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.06.19.
//

#import "SEBRootViewController.h"

@interface SEBRootViewController () {
}
@property (weak, nonatomic) LGSideMenuController *sideMenuController;

@end

@implementation SEBRootViewController

- (LGSideMenuController *)sideMenuController {
    if (!_sideMenuController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _sideMenuController = [storyboard instantiateViewControllerWithIdentifier:@"LGSideMenuController"];
    }
    return _sideMenuController;
}


#pragma mark - Status bar appearance

- (BOOL) prefersStatusBarHidden
{
    return self.sideMenuController.prefersStatusBarHidden;
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.sideMenuController.preferredStatusBarStyle;

}


- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return self.sideMenuController.preferredStatusBarUpdateAnimation;
}

@end
