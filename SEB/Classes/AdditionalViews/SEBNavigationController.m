//
//  SEBNavigationController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 11/06/16.
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

#import "SEBNavigationController.h"

@interface SEBNavigationController ()

@end

@implementation SEBNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];

    _appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (SEBUIController *)sebUIController {
    SEBUIController *uiController = _appDelegate.sebUIController;
    return uiController;
}


// Get statusbar appearance depending on device type (traditional or iPhone X like)
- (NSUInteger)statusBarAppearance {
    return [self.sebUIController statusBarAppearanceForDevice];
}


#pragma mark - Status bar appearance

- (BOOL) prefersStatusBarHidden
{
    NSUInteger statusBarAppearance = [self statusBarAppearance];
    // On a modern device with extended display, always display statusbar when browser toolbar is enabled
    BOOL hidden = (!(self.sebUIController.extendedDisplay & self.sebUIController.browserToolbarEnabled) &&
                   (statusBarAppearance == mobileStatusBarAppearanceNone ||
                    statusBarAppearance == mobileStatusBarAppearanceExtendedNoneDark ||
                    statusBarAppearance == mobileStatusBarAppearanceExtendedNoneLight));
    return hidden;
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    NSUInteger statusBarAppearance = [self statusBarAppearance];
    // Also consider if browser toolbar is enabled:
    // then use always dark text statusbar on a classic device
    if ((self.sebUIController.extendedDisplay || !self.sebUIController.browserToolbarEnabled) &&
        ((self.sebUIController.extendedDisplay && (statusBarAppearance == mobileStatusBarAppearanceNone || statusBarAppearance == mobileStatusBarAppearanceExtendedNoneDark)) ||
        statusBarAppearance == mobileStatusBarAppearanceLight ||
        statusBarAppearance == mobileStatusBarAppearanceExtendedLight)) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}


- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    if (self.sideMenuController.isLeftViewVisible) {
        return UIStatusBarAnimationFade;
    }
    else if (self.sideMenuController.isRightViewVisible) {
        return UIStatusBarAnimationSlide;
    }
    else {
        return UIStatusBarAnimationNone;
    }
}


@end
