//
//  SEBUIController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.02.18.
//  Copyright (c) 2010-2020 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2020 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBUIController.h"

@implementation SEBUIController

- (instancetype)init
{
    self = [super init];
    _appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (self) {
        [self initUI];
    }
    return self;
}

//// Initialize SEB Dock, commands section in the slider view and
//// 3D Touch Home screen quick actions
- (void)initUI
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *newDockItems = [NSMutableArray new];
    UIBarButtonItem *dockItem;
    UIImage *dockIcon;
    NSMutableArray *sliderCommands = [NSMutableArray new];
    SEBSliderItem *sliderCommandItem;
    UIImage *sliderIcon;

    _browserToolbarEnabled = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"];
    _dockEnabled = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"];
    
    /// Get status bar style from settings
    // Check if we need to customize the status bar, because running on a device
    // like iPhone X
    _statusBarAppearance = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_mobileStatusBarAppearance"];
    _statusBarAppearanceExtended = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_mobileStatusBarAppearanceExtended"];
    // Check if a quit password is set = run SEB in secure mode
    BOOL secureMode = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length > 0;

    // In iOS 9 we have to disable the status bar when SEB was started up by another
    // app, as the "back to" this app link in the status bar isn't blocked in AAC
    if (secureMode && (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 10 || NSProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 14)) {
        _statusBarAppearance = mobileStatusBarAppearanceNone;
        if (_statusBarAppearanceExtended == mobileStatusBarAppearanceExtendedLight || _statusBarAppearanceExtended == mobileStatusBarAppearanceExtendedNoneLight) {
            _statusBarAppearanceExtended = mobileStatusBarAppearanceExtendedNoneLight;
        } else {
            _statusBarAppearanceExtended = mobileStatusBarAppearanceExtendedNoneDark;
        }
    }
    
    /// Add left items
    
    // Add SEB app icon to the left side of the dock
    dockIcon = [UIImage imageNamed:@"SEBDockIcon"]
    ; //[appIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
    //        UIImage *appIcon = [UIImage imageNamed:@"SEBicon"]; //[appIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
    
    dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    dockItem.width = -12;
    [newDockItems addObject:dockItem];
    
    dockItem = [[UIBarButtonItem alloc] initWithImage:[dockIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                style:UIBarButtonItemStylePlain
                                               target:self
                                               action:@selector(leftDrawerButtonPress:)];
    dockItem.accessibilityLabel = NSLocalizedString(@"Toggle Side Menu", nil);
    dockItem.accessibilityHint = NSLocalizedString(@"Shows or hides menu which lists browser tabs (starting with the exam tab) and SEB commands. You have to hide the side menu to access the browser view again", nil);

    [newDockItems addObject:dockItem];
    
    // Add flexible space between left and right items
    dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    [newDockItems addObject:dockItem];
 
    /// Add right items
    
    // Add Edit Settings command if enabled
    if (_appDelegate.showSettingsInApp || [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showSettingsInApp"]) {
        sliderIcon = [UIImage imageNamed:@"SEBSliderSettingsIcon"];
        sliderCommandItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Edit Settings",nil)
                                                            icon:sliderIcon
                                                          target:self
                                                          action:@selector(conditionallyShowSettingsModal)];
        [sliderCommands addObject:sliderCommandItem];
    }
    
    // Add Scroll Lock button if enabled
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableScrollLock"]) {
        
        // Add Scroll Lock command to slider items
        sliderScrollLockIcon = [UIImage imageNamed:@"SEBSliderScrollLockIcon"];
        sliderScrollLockIconLocked = [UIImage imageNamed:@"SEBSliderScrollLockIcon_locked"];
        sliderScrollLockItemTitle = NSLocalizedString(@"Enable Scroll Lock", nil);
        sliderScrollLockItemTitleLocked = NSLocalizedString(@"Disable Scroll Lock", nil);
        _sliderScrollLockItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Activate Scroll Lock", nil)
                                                            icon:sliderScrollLockIcon
                                                          target:self
                                                          action:@selector(toggleScrollLock)];
        [sliderCommands addObject:_sliderScrollLockItem];
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showScrollLockButton"]) {
            scrollLockIcon = [UIImage imageNamed:@"SEBScrollLockIcon"];
            scrollLockIconLocked = [UIImage imageNamed:@"SEBScrollLockIcon_locked"];

            _scrollLockButton = [[UIBarButtonItem alloc] initWithImage:scrollLockIcon
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(toggleScrollLock)];
            _scrollLockButton.accessibilityLabel = NSLocalizedString(@"Scroll Lock", nil);
            _scrollLockButton.accessibilityHint = NSLocalizedString(@"Deactivates scrolling and text selection on the web page, facilitates using drag-and-drop web elements.", nil);
            [newDockItems addObject:_scrollLockButton];
            
            dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
            dockItem.width = 0;
            [newDockItems addObject:dockItem];
        }
    }
    
    // Add Back to Start button if enabled
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamUseStartURL"] ||
        [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamURL"].length > 0) {
        
        // Add Back to Start command to slider items
        NSString *restartButtonText = [self backToStartText];
        sliderIcon = [UIImage imageNamed:@"SEBSliderSkipBackIcon"];
        sliderCommandItem = [[SEBSliderItem alloc] initWithTitle:restartButtonText
                                                            icon:sliderIcon
                                                          target:self
                                                          action:@selector(backToStart)];
        [sliderCommands addObject:sliderCommandItem];
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showBackToStartButton"]) {
            dockIcon = [UIImage imageNamed:@"SEBSkipBackIcon"];
            
            dockItem = [[UIBarButtonItem alloc] initWithImage:[dockIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(backToStart)];
            dockItem.accessibilityLabel = NSLocalizedString(@"Back to Start", nil);
            dockItem.accessibilityHint = NSLocalizedString(@"Navigates back to the start URL or to another preset URL. Doesn't log users out", nil);
            //[dockItem setLandscapeImagePhone:[UIImage imageNamed:@"SEBSliderSkipBackIcon"]];
            [newDockItems addObject:dockItem];
            
            dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
            dockItem.width = 0;
            [newDockItems addObject:dockItem];
        }
    }
    
    // Add Navigate Back and Forward buttons if enabled,
    // either to toolbar, dock or slider (to only one of them)
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowBrowsingBackForward"] ||
        [preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowNavigation"]) {
        
        // Add Navigate Back Button to dock if enabled
        if (_dockEnabled &&
            [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showNavigationButtons"]) {
            dockIcon = [UIImage imageNamed:@"SEBNavigateBackIcon"];
            
            dockItem = [[UIBarButtonItem alloc] initWithImage:dockIcon
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(goBack)];
            dockItem.enabled = false;
            dockItem.accessibilityLabel = NSLocalizedString(@"Navigate Back", nil);
            dockItem.accessibilityHint = NSLocalizedString(@"Show the previous page", nil);

            [newDockItems addObject:dockItem];
            dockBackButton = dockItem;
            
            dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
            dockItem.width = 0;
            [newDockItems addObject:dockItem];
        } else if (!_browserToolbarEnabled) {
            // otherwise add navigate back command to slider if the toolbar isn't enabled
            sliderIcon = [UIImage imageNamed:@"SEBSliderNavigateBackIcon"];
            sliderBackButtonItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Go Back",nil)
                                                                icon:sliderIcon
                                                              target:self
                                                              action:@selector(goBack)];
            [sliderCommands addObject:sliderBackButtonItem];
        }
        
        // Add Navigate Forward Button to dock if enabled
        if (_dockEnabled &&
            [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showNavigationButtons"]) {
            dockIcon = [UIImage imageNamed:@"SEBNavigateForwardIcon"];
            
            dockItem = [[UIBarButtonItem alloc] initWithImage:dockIcon
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(goForward)];
            dockItem.enabled = false;
            dockItem.accessibilityLabel = NSLocalizedString(@"Navigate Forward", nil);
            dockItem.accessibilityHint = NSLocalizedString(@"Show the next page", nil);
            [newDockItems addObject:dockItem];
            dockForwardButton = dockItem;
            
            dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
            dockItem.width = 0;
            [newDockItems addObject:dockItem];
        } else if (!_browserToolbarEnabled) {
            // otherwise add navigate back command to slider if the toolbar isn't enabled
            sliderIcon = [UIImage imageNamed:@"SEBSliderNavigateForwardIcon"];
            sliderForwardButtonItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Go Forward",nil)
                                                                icon:sliderIcon
                                                              target:self
                                                              action:@selector(goForward)];
            [sliderCommands addObject:sliderForwardButtonItem];
        }
    }
    
    // Add Reload dock button if enabled and dock visible
    _dockReloadButton = nil;
    if (([preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserWindowAllowReload"] ||
         [preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowAllowReload"]) &&
        _dockEnabled &&
        [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showReloadButton"]) {
        dockIcon = [UIImage imageNamed:@"SEBReloadIcon"];
        dockItem = [[UIBarButtonItem alloc] initWithImage:dockIcon
                                                    style:UIBarButtonItemStylePlain
                                                   target:self
                                                   action:@selector(reload)];
        dockItem.accessibilityLabel = NSLocalizedString(@"Reload", nil);
        dockItem.accessibilityHint = NSLocalizedString(@"Reload this page", nil);
        //[dockItem setLandscapeImagePhone:[UIImage imageNamed:@"SEBReloadIconLandscape"]];
        [newDockItems addObject:dockItem];
        _dockReloadButton = dockItem;
        
        dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
        dockItem.width = 0;
        [newDockItems addObject:dockItem];
        
    } else if (([preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserWindowAllowReload"] ||
                [preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowAllowReload"]) &&
               !_browserToolbarEnabled) {
        // otherwise add reload page command to slider if the toolbar isn't enabled
        sliderIcon = [UIImage imageNamed:@"SEBSliderReloadIcon"];
        sliderReloadButtonItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Reload Page",nil)
                                                            icon:sliderIcon
                                                          target:self
                                                          action:@selector(reload)];
        [sliderCommands addObject:sliderReloadButtonItem];
    }
    
    // Add Proctoring slider command and dock button if enabled and dock visible
    _proctoringViewButton = nil;
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetEnable"]) {
        
        NSUInteger remoteProctoringViewShowPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_remoteProctoringViewShow"];
        BOOL allowToggleProctoringView = (remoteProctoringViewShowPolicy == remoteProctoringViewShowAllowToHide ||
                                          remoteProctoringViewShowPolicy == remoteProctoringViewShowAllowToShow);

        // Functionality enabled, add to slider menu
        sliderIcon = [UIImage imageNamed:@"SEBSliderProctoringViewIcon"];
        sliderProctoringViewButtonItem = [[SEBSliderItem alloc] initWithTitle:allowToggleProctoringView ?
                                  NSLocalizedString(@"Toggle Proctoring View",nil) :
                                  NSLocalizedString(@"Remote Proctoring",nil)
                                                            icon:sliderIcon
                                                          target:self
                                                          action:@selector(toggleProctoringViewVisibility)];
        [sliderCommands addObject:sliderProctoringViewButtonItem];

        if (_dockEnabled &&
        [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showProctoringViewButton"]) {
            ProctoringIconDefaultState = [UIImage imageNamed:@"SEBProctoringViewIcon"];
            ProctoringIconNormalState = [UIImage imageNamed:@"SEBProctoringViewIcon_checkmark"];
            ProctoringIconColorNormalState = [UIColor systemGreenColor];
            ProctoringBadgeNormalState = [[CIImage alloc] initWithCGImage:[UIImage imageNamed:@"SEBBadgeCheckmark"].CGImage];
            ProctoringIconWarningState = [UIImage imageNamed:@"SEBProctoringViewIcon_warning"];
            ProctoringIconColorWarningState = [UIColor systemOrangeColor];
            ProctoringBadgeWarningState = [[CIImage alloc] initWithCGImage:[UIImage imageNamed:@"SEBBadgeWarning"].CGImage];
            ProctoringIconErrorState = [UIImage imageNamed:@"SEBProctoringViewIcon_error"];
            ProctoringIconColorErrorState = [UIColor systemRedColor];
            ProctoringBadgeErrorState = [[CIImage alloc] initWithCGImage:[UIImage imageNamed:@"SEBBadgeError"].CGImage];
            dockItem = [[UIBarButtonItem alloc] initWithImage:ProctoringIconDefaultState
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(toggleProctoringViewVisibility)];
            dockItem.accessibilityLabel = allowToggleProctoringView ?
            NSLocalizedString(@"Toggle Proctoring View", nil) :
            NSLocalizedString(@"Show Remote Proctoring Information", nil);
            dockItem.accessibilityHint = remoteProctoringViewShowPolicy != remoteProctoringViewShowNever ?
            NSLocalizedString(@"The overlay proctoring view is initially displayed in the lower right corner and can be swiped to other display corners.", nil) : @"";
                    
            _proctoringViewButton = dockItem;
            [newDockItems addObject:dockItem];
            
            dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
            dockItem.width = 0;
            [newDockItems addObject:dockItem];
        }
    }
    
    // Add scan QR code command/Home screen quick action/dock button
    // if SEB isn't running in exam mode (= no quit pw)
    BOOL examSession = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length > 0;
    BOOL allowReconfiguring = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_examSessionReconfigureAllow"];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileAllowQRCodeConfig"] &&
        ((!examSession && !NSUserDefaults.userDefaultsPrivate) ||
         (!examSession && NSUserDefaults.userDefaultsPrivate && allowReconfiguring) ||
         (examSession && allowReconfiguring))) {
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showScanQRCodeButton"]) {
            dockIcon = [UIImage imageNamed:@"SEBQRCodeIcon"];
            dockItem = [[UIBarButtonItem alloc] initWithImage:[dockIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(scanQRCode)];
            dockItem.accessibilityLabel = NSLocalizedString(@"Scan QR Code", nil);
            dockItem.accessibilityHint = NSLocalizedString(@"Displays a camera view to scan for SEB configuration QR codes", nil);
            [newDockItems addObject:dockItem];
            
            dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
            dockItem.width = 0;
            [newDockItems addObject:dockItem];
            
        }
        // Add scan QR code command to slider items
        sliderIcon = [UIImage imageNamed:@"SEBSliderQRCodeIcon"];
        sliderCommandItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Scan Config QR Code",nil)
                                                            icon:sliderIcon
                                                          target:self
                                                          action:@selector(scanQRCode)];
        [sliderCommands addObject:sliderCommandItem];
        
    }
    
    // Add About SEB command to slider items
    sliderIcon = [UIImage imageNamed:@"SEBSliderInfoIcon"];
    sliderCommandItem = [[SEBSliderItem alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"About %@",nil), SEBExtraShortAppName]
                                                        icon:sliderIcon
                                                      target:self
                                                      action:@selector(showAboutSEB)];
    [sliderCommands addObject:sliderCommandItem];
    
    // Add Quit button if enabled in Dock settings
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showQuitButton"]) {
        dockIcon = [UIImage imageNamed:@"SEBShutDownIcon"];
        dockItem = [[UIBarButtonItem alloc] initWithImage:[dockIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(quitExamConditionally)];
        dockItem.accessibilityLabel = NSLocalizedString(@"Quit Session", nil);
        dockItem.accessibilityHint = NSLocalizedString(@"Ends an exam session and returns to client settings", nil);
        [newDockItems addObject:dockItem];
    }
    
    dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    dockItem.width = -12;
    [newDockItems addObject:dockItem];
    
    // Add quit command to slider items
    sliderIcon = [UIImage imageNamed:@"SEBSliderShutDownIcon"];
    sliderCommandItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Quit Session",nil)
                                                        icon:sliderIcon
                                                      target:self
                                                      action:@selector(quitExamConditionally)];
    [sliderCommands addObject:sliderCommandItem];
    
    // Register dock commands
    _dockItems = [newDockItems copy];
    
    // Register slider commands
    _leftSliderCommands = [sliderCommands copy];
}


// Check if running on a device like iPhone X
- (BOOL)extendedDisplay {
    BOOL extendedDisplay = NO;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        extendedDisplay = window.safeAreaInsets.bottom != 0;
    }
    return extendedDisplay;
}


// Get statusbar appearance depending on device type (traditional or iPhone X like)
- (NSUInteger)statusBarAppearanceForDevice {
    NSUInteger deviceStatusBarAppearance = _statusBarAppearance;
    if (@available(iOS 11.0, *)) {
        // Check if running on a device like iPhone X
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        if (window.safeAreaInsets.bottom != 0)
        {
            if (_statusBarAppearanceExtended != mobileStatusBarAppearanceExtendedInferred) {
                deviceStatusBarAppearance = _statusBarAppearanceExtended;
            }
        }
    }
    return deviceStatusBarAppearance;
}


// Get statusbar height depending on device type (traditional =20 or iPhone X, new iPad Pro like)
- (NSUInteger)statusBarHeightForDevice {
    NSUInteger deviceStatusBarHeight = 20;
    if (@available(iOS 11.0, *)) {
        // Check if running on a device like iPad Pro with extended display
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        NSUInteger homeIndicatorSafeAreaHeight = window.safeAreaInsets.bottom;
        if (homeIndicatorSafeAreaHeight == 20) {
            deviceStatusBarHeight = 24;
        }
    }
    return deviceStatusBarHeight;
}


// Running on iPad Pro with FaceID and new generation displays
- (BOOL)iPadExtendedDisplay
{
    BOOL iPadExtendedDisplay = NO;
    
    if (@available(iOS 11.0, *)) {
        CGFloat calculatedNavigationBarHeight = 0;
        CGFloat calculatedToolbarHeight = 0;
        
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        
        CGFloat statusbarHeight = window.safeAreaInsets.top;
        CGFloat navigationBarHeight = _sebViewController.view.safeAreaInsets.top;
        calculatedNavigationBarHeight = navigationBarHeight - statusbarHeight;
        
        CGFloat homeIndicatorSpaceHeight = window.safeAreaInsets.bottom;
        CGFloat toolbarHeight = _sebViewController.view.safeAreaInsets.bottom;
        calculatedToolbarHeight = toolbarHeight - homeIndicatorSpaceHeight;
        
        // iPad Pro 11 and 12.9 3rd generation have 50 or 42 pt calculated navigation bar height
        iPadExtendedDisplay = homeIndicatorSpaceHeight && (calculatedNavigationBarHeight == 50 || calculatedNavigationBarHeight == 42 || calculatedToolbarHeight == 46);
    }
    return iPadExtendedDisplay;
}


- (NSString *)backToStartText
{
    NSString *backToStartText = [[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_restartExamText"];
    if (backToStartText.length == 0) {
        backToStartText = NSLocalizedString(@"Back to Start",nil);
    }
    return backToStartText;
}


- (void)setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
{
    dockBackButton.enabled = canGoBack;
    dockForwardButton.enabled = canGoForward;
    
    sliderBackButtonItem.enabled = canGoBack;
    sliderForwardButtonItem.enabled = canGoForward;
    
    // Post a notification that the slider should be refreshed
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"refreshSlider" object:self];
}


//// Add reload button to navigation bar or enable/disable
//// reload buttons in dock and left slider, depending if
//// active tab is the exam tab or a new (additional) tab
//- (void) activateReloadButtonsExamTab:(BOOL)examTab
//{
//    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    BOOL showReload = false;
//    if (examTab) {
//        // Main browser tab with the exam
//        showReload = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserWindowAllowReload"];
//    } else {
//        // Additional browser tab
//        showReload = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowAllowReload"];
//    }
//    [self activateReloadButtons:showReload];
//}


// Conditionally add reload button to navigation bar or
// enable/disable reload buttons in dock and left slider
- (void) activateReloadButtons:(BOOL)reloadEnabled
{
    if (reloadEnabled)  {
        // Activate reload buttons in dock and slider
        _dockReloadButton.enabled = true;
        sliderReloadButtonItem.enabled = true;
        
    } else {
        // Deactivate reload buttons in toolbar, dock and slider
        _dockReloadButton.enabled = false;
        sliderReloadButtonItem.enabled = false;
    }
}

- (void) setProctoringViewButtonState:(remoteProctoringButtonStates)remoteProctoringButtonState
{
    [self setProctoringViewButtonState:remoteProctoringButtonState userFeedback:YES];
}


- (void) setProctoringViewButtonState:(remoteProctoringButtonStates)remoteProctoringButtonState
                         userFeedback:(BOOL)userFeedback
{
    UIImage *remoteProctoringButtonImage;
    UIColor *remoteProctoringButtonTintColor;
    switch (remoteProctoringButtonState) {
        case remoteProctoringButtonStateNormal:
            remoteProctoringButtonImage = ProctoringIconNormalState;
            remoteProctoringButtonTintColor = ProctoringIconColorNormalState;
            _sebViewController.proctoringStateIcon = ProctoringBadgeNormalState;
            break;
            
        case remoteProctoringButtonStateWarning:
            remoteProctoringButtonImage = ProctoringIconWarningState;
            remoteProctoringButtonTintColor = ProctoringIconColorWarningState;
            _sebViewController.proctoringStateIcon = ProctoringBadgeWarningState;
            break;
            
        case remoteProctoringButtonStateError:
            remoteProctoringButtonImage = ProctoringIconErrorState;
            remoteProctoringButtonTintColor = ProctoringIconColorErrorState;
            _sebViewController.proctoringStateIcon = ProctoringBadgeErrorState;
            break;
            
        case remoteProctoringButtonStateAIInactive:
            remoteProctoringButtonImage = ProctoringIconDefaultState;
            remoteProctoringButtonTintColor = ProctoringIconColorNormalState;
            _sebViewController.proctoringStateIcon = nil;
            break;
            
        default:
            remoteProctoringButtonImage = ProctoringIconDefaultState;
            remoteProctoringButtonTintColor = nil;
            _sebViewController.proctoringStateIcon = nil;
            break;
    }
    if (userFeedback) {
        _proctoringViewButton.image = remoteProctoringButtonImage;
        _proctoringViewButton.tintColor = remoteProctoringButtonTintColor;
    }
}


#pragma mark - SEB Dock and left slider button handler

-(void)leftDrawerButtonPress:(id)sender{
    [_sebViewController leftDrawerButtonPress:sender];
}

- (void)conditionallyShowSettingsModal
{
    [_sebViewController conditionallyShowSettingsModal];
}

- (IBAction)toggleScrollLock
{
    [_sebViewController toggleScrollLock];
    [self updateScrollLockButtonStates];
}

- (void)updateScrollLockButtonStates
{
    if (_sebViewController.isScrollLockActive) {
        _scrollLockButton.image = scrollLockIconLocked;
        _scrollLockButton.tintColor = [UIColor systemYellowColor];
        _sliderScrollLockItem.icon = sliderScrollLockIconLocked;
        _sliderScrollLockItem.title = sliderScrollLockItemTitleLocked;
    } else {
        _scrollLockButton.image = scrollLockIcon;
        _scrollLockButton.tintColor = nil;
        _sliderScrollLockItem.icon = sliderScrollLockIcon;
        _sliderScrollLockItem.title = sliderScrollLockItemTitle;
    }
}

- (IBAction)backToStart
{
    [_sebViewController backToStart];
}

- (IBAction)goBack {
    [_sebViewController goBack];
}


- (IBAction)goForward {
    [_sebViewController goForward];
}


- (IBAction)reload {
    [_sebViewController reload];
}


- (void)showAboutSEB
{
    [_sebViewController showAboutSEB];
}


- (void) toggleProctoringViewVisibility
{
    [_sebViewController toggleProctoringViewVisibility];
}


- (void)scanQRCode
{
    [_sebViewController scanQRCode];
}


- (void) quitExamConditionally
{
    [_sebViewController quitExamConditionally];
}


@end
