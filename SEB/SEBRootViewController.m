//
//  SEBRootViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.06.19.
//

#import "SEBRootViewController.h"

@implementation SEBRootViewController

#pragma mark - Status bar appearance

- (BOOL) prefersStatusBarHidden
{
    if (_lgSideMenuController) {
        return _lgSideMenuController.prefersStatusBarHidden;
    } else {
        return NO;
    }
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (_lgSideMenuController) {
        return _lgSideMenuController.preferredStatusBarStyle;
    } else {
        return UIStatusBarStyleDefault;
    }
}


- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    if (_lgSideMenuController) {
        return _lgSideMenuController.preferredStatusBarUpdateAnimation;
    } else {
        return UIStatusBarAnimationNone;
    }
}

@end
