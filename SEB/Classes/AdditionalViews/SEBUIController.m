//
//  SEBUIController.m
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

    // In iOS 9 we have to disable the status bar when SEB was started up by another
    // app, as the "back to" this app link in the status bar isn't blocked in AAC
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 10 && _appDelegate.openedURL) {
        _statusBarAppearance = mobileStatusBarAppearanceNone;
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
    
    // Add scan QR code command/Home screen quick action/dock button
    // if SEB isn't running in exam mode (= no quit pw)
    BOOL examSession = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length > 0;
    BOOL allowReconfiguring = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_examSessionReconfigureAllow"];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileAllowQRCodeConfig"] &&
        ((!NSUserDefaults.privateUserDefaults && !examSession) || (examSession && allowReconfiguring))) {
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showScanQRCodeButton"]) {
            dockIcon = [UIImage imageNamed:@"SEBQRCodeIcon"];
            dockItem = [[UIBarButtonItem alloc] initWithImage:[dockIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(scanQRCode)];
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
    sliderCommandItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"About SEB",nil)
                                                        icon:sliderIcon
                                                      target:self
                                                      action:@selector(showAboutSEB)];
    [sliderCommands addObject:sliderCommandItem];
    
    // Add Quit button
    dockIcon = [UIImage imageNamed:@"SEBShutDownIcon"];
    dockItem = [[UIBarButtonItem alloc] initWithImage:[dockIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(quitExamConditionally)];
    //[dockItem setLandscapeImagePhone:[UIImage imageNamed:@"SEBShutDownIconLandscape"]];
    [newDockItems addObject:dockItem];
    
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


#pragma mark - SEB Dock and left slider button handler

-(void)leftDrawerButtonPress:(id)sender{
    [_sebViewController leftDrawerButtonPress:sender];
}

- (void)conditionallyShowSettingsModal
{
    [_sebViewController conditionallyShowSettingsModal];
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


- (void)scanQRCode
{
    [_sebViewController scanQRCode];
}


- (void) quitExamConditionally
{
    [_sebViewController quitExamConditionally];
}


@end
