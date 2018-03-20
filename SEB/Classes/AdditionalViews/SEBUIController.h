//
//  SEBUIController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.02.18.
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
#import "AppDelegate.h"
#import "SEBViewController.h"
#import "SEBSliderItem.h"

@class AppDelegate;
@class SEBViewController;

@interface SEBUIController : NSObject {
    
    UIBarButtonItem *dockBackButton;
    UIBarButtonItem *dockForwardButton;
    UIBarButtonItem *dockReloadButton;
    SEBSliderItem *sliderBackButtonItem;
    SEBSliderItem *sliderForwardButtonItem;
    SEBSliderItem *sliderReloadButtonItem;

}

@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) SEBViewController *sebViewController;

@property (nonatomic, strong) NSArray *leftSliderCommands;
@property (nonatomic, strong) NSArray *dockItems;

@property (readwrite) NSUInteger statusBarAppearance;
@property (readwrite) BOOL showSettingsInApp;


- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward;
//- (void) activateReloadButtonsExamTab:(BOOL)examTab;
- (void) activateReloadButtons:(BOOL)reloadEnabled; 

@end
