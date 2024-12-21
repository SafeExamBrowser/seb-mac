//
//  SEBUIController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.02.18.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "SEBViewController.h"
#import "SEBSliderItem.h"
#import "SafeExamBrowser-Swift.h"

@class AppDelegate;
@class SEBViewController;

@interface SEBUIController : NSObject <ProctoringUIDelegate> {
    
    UIBarButtonItem *dockBackButton;
    UIBarButtonItem *dockForwardButton;
    SEBSliderItem *sliderZoomPageResetItem;
    SEBSliderItem *sliderZoomPageOutItem;
    SEBSliderItem *sliderZoomPageInItem;
    SEBSliderItem *sliderBackButtonItem;
    SEBSliderItem *sliderForwardButtonItem;
    SEBSliderItem *sliderReloadButtonItem;
    SEBSliderItem *sliderProctoringViewButtonItem;

    UIImage *scrollLockIcon;
    UIImage *scrollLockIconLocked;
    UIImage *sliderScrollLockIcon;
    UIImage *sliderScrollLockIconLocked;
    NSString *sliderScrollLockItemTitle;
    NSString *sliderScrollLockItemTitleLocked;

    NSInteger raiseHandUID;
    NSString *raiseHandNotification;
    UIColor *RaisedHandIconColorDefaultState;
    UIColor *RaisedHandIconColorRaisedState;
    UIImage *RaisedHandIconDefaultState;
    UIImage *RaisedHandIconRaisedState;
    UIImage *RaisedHandSliderItemDefaultState;
    UIImage *RaisedHandSliderItemRaisedState;

    UIImage *ScreenProctoringIconInactiveState;
    UIImage *ScreenProctoringIconActiveState;
    UIImage *ScreenProctoringIconActiveWarningState;
    UIImage *ScreenProctoringIconActiveErrorState;
    UIImage *ScreenProctoringIconInactiveErrorState;
    UIImage *ScreenProctoringSliderItemInactiveState;
    UIImage *ScreenProctoringSliderItemActiveState;
    UIImage *ScreenProctoringSliderItemActiveWarningState;
    UIImage *ScreenProctoringSliderItemActiveErrorState;
    UIImage *ScreenProctoringSliderItemInactiveErrorState;
    UIColor *ScreenProctoringIconColorActiveState;
    UIColor *ScreenProctoringIconColorWarningState;
    UIColor *ScreenProctoringIconColorErrorState;
    
    UIImage *ProctoringIconDefaultState;
    UIImage *ProctoringIconNormalState;
    UIImage *ProctoringIconWarningState;
    UIImage *ProctoringIconErrorState;
    UIColor *ProctoringIconColorNormalState;
    UIColor *ProctoringIconColorWarningState;
    UIColor *ProctoringIconColorErrorState;
    
    CIImage *ProctoringBadgeNormalState;
    CIImage *ProctoringBadgeWarningState;
    CIImage *ProctoringBadgeErrorState;
}

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) SEBViewController *sebViewController;

@property (nonatomic, strong) NSArray *leftSliderCommands;
@property (nonatomic, strong) NSArray *dockItems;
@property (nonatomic, strong) SEBSliderItem *sliderScrollLockItem;
@property (nonatomic, strong) UIBarButtonItem *scrollLockButton;
@property (nonatomic, strong) UIBarButtonItem *dockReloadButton;
@property (nonatomic, strong) UIBarButtonItem *dockButtonRaiseHand;
@property (nonatomic, strong) UIBarButtonItem *dockScreenProctoringButton;
@property (nonatomic, strong) SEBSliderItem *sliderScreenProctoringItem;
@property(strong, nonatomic) NSString *screenProctoringStateString;

@property(readwrite) BOOL raiseHandRaised;

@property (nonatomic, strong) UIBarButtonItem *proctoringViewButton;


@property (readwrite) NSUInteger statusBarAppearance;
@property (readwrite) NSUInteger statusBarAppearanceExtended;
@property (nonatomic, readwrite) SEBBackgroundTintStyle backgroundTintStyle;
@property (readwrite) BOOL browserToolbarEnabled;
@property (readwrite) BOOL dockEnabled;


// Check if running on a device like iPhone X
- (BOOL)extendedDisplay;

// Check if running on iPad Pro with FaceID and new generation displays
- (BOOL)iPadExtendedDisplay;

// Get statusbar appearance depending on device type (traditional or iPhone X like)
- (NSUInteger)statusBarAppearanceForDevice;

- (NSUInteger)statusBarHeightForDevice;

- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward;

- (void) activateReloadButtons:(BOOL)reloadEnabled; 
- (void) activateZoomButtons:(BOOL)zoomEnabled;

- (void) updateScrollLockButtonStates;

#pragma mark - Raise Hand Feature

- (void) raiseHandNotificationReceived:(NSInteger)notficationID;


#pragma mark - Screen Proctoring SPSControllerUIDelegate methods

- (void) updateStatusWithString:(NSString *)string append:(BOOL)append;

- (void) setScreenProctoringButtonState:(ScreenProctoringButtonStates)screenProctoringButtonState;
- (void) setScreenProctoringButtonState:(ScreenProctoringButtonStates)screenProctoringButtonState
                           userFeedback:(BOOL)userFeedback;

- (void) setScreenProctoringButtonInfoString:(NSString *)infoString;

- (void) setProctoringViewButtonState:(remoteProctoringButtonStates)remoteProctoringButtonState
                         userFeedback:(BOOL)userFeedback;

@end
