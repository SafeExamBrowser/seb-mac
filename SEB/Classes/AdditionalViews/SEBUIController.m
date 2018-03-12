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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
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

    /// Get status bar style from settings
    _statusBarAppearance = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_mobileStatusBarAppearance"];
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
 
    BOOL showSettingsInApp = false;
    // If running with persisted (client) settings
    if (!NSUserDefaults.userDefaultsPrivate) {
        // Set the local flag for showing settings in-app, so this is also enabled
        // when opening temporary exam settings later
        showSettingsInApp = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showSettingsInApp"];
    }
    
    /// Add right items
    
    // Add Edit Settings command if enabled
    if (showSettingsInApp || [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showSettingsInApp"]) {
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
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"] &&
            [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showNavigationButtons"]) {
            dockIcon = [UIImage imageNamed:@"SEBNavigateBackIcon"];
            
            dockItem = [[UIBarButtonItem alloc] initWithImage:dockIcon
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(goBack)];
            //[dockItem setLandscapeImagePhone:[UIImage imageNamed:@"SEBSliderNavigateBackIcon"]];
            dockItem.enabled = false;
            [newDockItems addObject:dockItem];
            dockBackButton = dockItem;
            
            dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
            dockItem.width = 0;
            [newDockItems addObject:dockItem];
        }
        
        // Add Navigate Forward Button to dock if enabled
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"] &&
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
        }
    }
    
    // Add Reload dock button if enabled and dock visible
    if (([preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserWindowAllowReload"] ||
         [preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowAllowReload"]) &&
        [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"] &&
        [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showReloadButton"]) {
        dockIcon = [UIImage imageNamed:@"SEBReloadIcon"];
        dockItem = [[UIBarButtonItem alloc] initWithImage:dockIcon
                                                    style:UIBarButtonItemStylePlain
                                                   target:self
                                                   action:@selector(reload)];
        //[dockItem setLandscapeImagePhone:[UIImage imageNamed:@"SEBReloadIconLandscape"]];
        [newDockItems addObject:dockItem];
        dockReloadButton = dockItem;
        
        dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
        dockItem.width = 0;
        [newDockItems addObject:dockItem];
        
    } else if (([preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserWindowAllowReload"] ||
                [preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowAllowReload"]) &&
               ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"]) {
        // otherwise add reload page command to slider if the toolbar isn't enabled
        sliderIcon = [UIImage imageNamed:@"SEBSliderReloadIcon"];
        sliderCommandItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Reload Page",nil)
                                                            icon:sliderIcon
                                                          target:self
                                                          action:@selector(reload)];
        [sliderCommands addObject:sliderCommandItem];
    }
    
    // Add scan QR code command/Home screen quick action/dock button
    // if SEB isn't running in exam mode (= no quit pw)
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileAllowQRCodeConfig"] &&
        [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length == 0) {
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showScanQRCodeButton"]) {
            dockIcon = [UIImage imageNamed:@"SEBQRCodeIcon"];
            dockItem = [[UIBarButtonItem alloc] initWithImage:[dockIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(scanQRCode:)];
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
                                                          action:@selector(scanQRCode:)];
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
        dockReloadButton.enabled = true;
        sliderReloadButtonItem.enabled = true;
        
    } else {
        // Deactivate reload buttons in toolbar, dock and slider
        dockReloadButton.enabled = false;
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


- (void)scanQRCode:(id)sender
{
    [_sebViewController scanQRCode:sender];
}


- (void) quitExamConditionally
{
    [_sebViewController quitExamConditionally];
}


@end
