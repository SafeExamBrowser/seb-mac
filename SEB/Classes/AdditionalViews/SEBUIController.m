//
//  SEBUIController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.02.18.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
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


- (SEBBackgroundTintStyle)backgroundTintStyle
{
    _statusBarAppearance = [self statusBarAppearanceForDevice];
    
    _backgroundTintStyle = (_statusBarAppearance == mobileStatusBarAppearanceNone ||
                            _statusBarAppearance == mobileStatusBarAppearanceLight ||
                            _statusBarAppearance == mobileStatusBarAppearanceExtendedNoneDark) ? SEBBackgroundTintStyleDark : SEBBackgroundTintStyleLight;
    return _backgroundTintStyle;
}


//// Initialize SEB Dock, commands section in the slider view and
//// 3D Touch Home screen quick actions
- (void)initUI
{
    if (_uiInitialized == NO) {
        _uiInitialized = YES;
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
        _statusBarAppearance = [self statusBarAppearanceForDevice];
        
        // Check if a quit password is set = run SEB in secure mode
        BOOL secureMode = preferences.secureSession;

        // In iOS 9 we have to disable the status bar when SEB was started up by another
        // app, as the "back to" this app link in the status bar isn't blocked in AAC
        if (secureMode && (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 10 || (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion == 14 && NSProcessInfo.processInfo.operatingSystemVersion.minorVersion < 5))) {
            _statusBarAppearance = mobileStatusBarAppearanceNone;
            if (_statusBarAppearanceExtended == mobileStatusBarAppearanceExtendedDarkOnLight || _statusBarAppearanceExtended == mobileStatusBarAppearanceExtendedNoneLight) {
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
        dockItem.accessibilityLabel = NSLocalizedString(@"Toggle Side Menu", @"");
        dockItem.accessibilityHint = NSLocalizedString(@"Shows or hides menu which lists browser tabs (starting with the exam tab) and SEB commands. You have to hide the side menu to access the browser view again", @"");

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
            sliderScrollLockItemTitle = NSLocalizedString(@"Enable Scroll Lock", @"");
            sliderScrollLockItemTitleLocked = NSLocalizedString(@"Disable Scroll Lock", @"");
            _sliderScrollLockItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Activate Scroll Lock", @"")
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
                _scrollLockButton.accessibilityLabel = NSLocalizedString(@"Scroll Lock", @"");
                _scrollLockButton.accessibilityHint = NSLocalizedString(@"Deactivates scrolling and text selection on the web page, facilitates using drag-and-drop web elements.", @"");
                [newDockItems addObject:_scrollLockButton];
                
                dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
                dockItem.width = 0;
                [newDockItems addObject:dockItem];
            }
        }
        
        // Add Page Zoom buttons to side menu if enabled
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableZoomPage"] &&
            [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowWebView"] != webViewSelectForceClassic) {
            
            sliderIcon = [UIImage imageNamed:@"SEBSliderZoomDefaultSizeIcon"];
            sliderZoomPageResetItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Default Size", @"")
                                                                icon:sliderIcon
                                                              target:self
                                                              action:@selector(zoomPageReset)];
            [sliderCommands addObject:sliderZoomPageResetItem];
            
            sliderIcon = [UIImage imageNamed:@"SEBSliderZoomOutSmallerSizeIcon"];
            sliderZoomPageOutItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Zoom Page Out", @"")
                                                                icon:sliderIcon
                                                              target:self
                                                              action:@selector(zoomPageOut)];
            [sliderCommands addObject:sliderZoomPageOutItem];
            
            sliderIcon = [UIImage imageNamed:@"SEBSliderZoomInLargerSizeIcon"];
            sliderZoomPageInItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Zoom Page In", @"")
                                                                icon:sliderIcon
                                                              target:self
                                                              action:@selector(zoomPageIn)];
            [sliderCommands addObject:sliderZoomPageInItem];
        }
        
        // Add Search Text button to side menu if enabled
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowFind"]) {
            
            // Add Search Text command to slider items
            sliderIcon = [UIImage imageNamed:@"SEBSliderSearchIcon"];
            sliderCommandItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Search Text", @"")
                                                                icon:sliderIcon
                                                              target:self
                                                              action:@selector(searchTextOnPage)];
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
                dockItem.accessibilityLabel = NSLocalizedString(@"Back to Start", @"");
                dockItem.accessibilityHint = NSLocalizedString(@"Navigates back to the start URL or to another preset URL. Doesn't log users out", @"");
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
            
            BOOL showNavigationButtons = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showNavigationButtons"];
            // Add Navigate Back Button to dock if enabled
            if (_dockEnabled && showNavigationButtons) {
                dockIcon = [UIImage imageNamed:@"SEBNavigateBackIcon"];
                
                dockItem = [[UIBarButtonItem alloc] initWithImage:dockIcon
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(goBack)];
                dockItem.enabled = false;
                dockItem.accessibilityLabel = NSLocalizedString(@"Navigate Back", @"");
                dockItem.accessibilityHint = NSLocalizedString(@"Show the previous page", @"");

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
            if (_dockEnabled && showNavigationButtons) {
                dockIcon = [UIImage imageNamed:@"SEBNavigateForwardIcon"];
                
                dockItem = [[UIBarButtonItem alloc] initWithImage:dockIcon
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(goForward)];
                dockItem.enabled = false;
                dockItem.accessibilityLabel = NSLocalizedString(@"Navigate Forward", @"");
                dockItem.accessibilityHint = NSLocalizedString(@"Show the next page", @"");
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
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserWindowAllowReload"] ||
             [preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowAllowReload"]) {
            
            if (_dockEnabled &&
                [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showReloadButton"]) {
                dockIcon = [UIImage imageNamed:@"SEBReloadIcon"];
                dockItem = [[UIBarButtonItem alloc] initWithImage:dockIcon
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(reload)];
                dockItem.accessibilityLabel = NSLocalizedString(@"Reload", @"");
                dockItem.accessibilityHint = NSLocalizedString(@"Reload this page", @"");
                //[dockItem setLandscapeImagePhone:[UIImage imageNamed:@"SEBReloadIconLandscape"]];
                [newDockItems addObject:dockItem];
                _dockReloadButton = dockItem;
                
                dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
                dockItem.width = 0;
                [newDockItems addObject:dockItem];
                
            } else if (!_browserToolbarEnabled) {
                // otherwise add reload page command to slider if the toolbar isn't enabled
                sliderIcon = [UIImage imageNamed:@"SEBSliderReloadIcon"];
                sliderReloadButtonItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Reload Page",nil)
                                                                    icon:sliderIcon
                                                                  target:self
                                                                  action:@selector(reload)];
                [sliderCommands addObject:sliderReloadButtonItem];
            }
        }
        
        // Add Raise Hand slider command and dock button if enabled and dock visible
        if (([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebMode"] == sebModeSebServer ||
            _sebViewController.establishingSEBServerConnection || _sebViewController.sebServerConnectionEstablished) &&
            [preferences secureBoolForKey:@"org_safeexambrowser_SEB_raiseHandButtonShow"]) {
            
            RaisedHandIconColorDefaultState = nil;
            RaisedHandIconColorRaisedState = [UIColor systemYellowColor];

            // Functionality enabled, add to slider menu
            RaisedHandSliderItemDefaultState = [UIImage imageNamed:@"SEBSliderRaiseHandIcon"];
            RaisedHandSliderItemRaisedState = [UIImage imageNamed:@"SEBSliderRaiseHandIcon_raised"];
            sliderRaiseHandItemTitle = NSLocalizedString(@"Raise Hand", @"");
            sliderRaiseHandItemTitleRaised = NSLocalizedString(@"Lower Hand", @"");
            raiseHandAccessibilityLabel = NSLocalizedString(@"Hand is not raised", @"");
            raiseHandAccessibilityLabelRaised = NSLocalizedString(@"Hand is raised", @"");
            sliderIcon = RaisedHandSliderItemDefaultState;;
            _sliderRaiseHandItem = [[SEBSliderItem alloc] initWithTitle:sliderRaiseHandItemTitle
                                                                icon:sliderIcon
                                                              target:self
                                                                 action:@selector(toggleRaiseHand)
                                                        secondaryAction:@selector(showEnterRaiseHandMessageWindow)];
            [sliderCommands addObject:_sliderRaiseHandItem];

            if (_dockEnabled) {
                RaisedHandIconDefaultState = [UIImage imageNamed:@"SEBRaiseHandIcon"];
                RaisedHandIconRaisedState = [[UIImage imageNamed:@"SEBRaiseHandIcon_raised"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                dockItem = [[UIBarButtonItem alloc] initWithImage:RaisedHandIconDefaultState
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(toggleRaiseHand)
                                                  secondaryAction:@selector(showEnterRaiseHandMessageWindow)];
                dockItem.accessibilityLabel = raiseHandAccessibilityLabel;
                _dockButtonRaiseHand = dockItem;
                [newDockItems addObject:dockItem];
                
                dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
                dockItem.width = 0;
                [newDockItems addObject:dockItem];
            }
        }

        // Add Screen Proctoring slider command and dock button if enabled and dock visible
        _dockScreenProctoringButton = nil;
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableScreenProctoring"]) {
            
            ScreenProctoringIconColorActiveState = [UIColor systemGreenColor];
            ScreenProctoringIconColorWarningState = [UIColor systemOrangeColor];
            ScreenProctoringIconColorErrorState = [UIColor systemRedColor];

            // Functionality enabled, add to slider menu
            ScreenProctoringSliderItemInactiveState = [UIImage imageNamed:@"SEBSliderScreenProctoringIcon_inactive"];
            ScreenProctoringSliderItemActiveState = [UIImage imageNamed:@"SEBSliderScreenProctoringIcon_active"];
            ScreenProctoringSliderItemActiveWarningState = [UIImage imageNamed:@"SEBSliderScreenProctoringIcon_active_warning"];
            ScreenProctoringSliderItemActiveErrorState = [UIImage imageNamed:@"SEBSliderScreenProctoringIcon_active_error"];
            ScreenProctoringSliderItemInactiveErrorState = [UIImage imageNamed:@"SEBSliderScreenProctoringIcon_inactive_error"];

            sliderIcon = ScreenProctoringSliderItemInactiveState;;
            _sliderScreenProctoringItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Screen Proctoring Inactive",nil)
                                                                icon:sliderIcon
                                                              target:self
                                                              action:@selector(screenProctoringButtonAction)];
            [sliderCommands addObject:_sliderScreenProctoringItem];

            if (_dockEnabled) {
                ScreenProctoringIconInactiveState = [UIImage imageNamed:@"SEBScreenProctoringIcon_inactive"];
                ScreenProctoringIconActiveState = [UIImage imageNamed:@"SEBScreenProctoringIcon_active"];
                ScreenProctoringIconActiveWarningState = [UIImage imageNamed:@"SEBScreenProctoringIcon_active_warning"];
                ScreenProctoringIconActiveErrorState = [UIImage imageNamed:@"SEBScreenProctoringIcon_active_error"];
                ScreenProctoringIconInactiveErrorState = [UIImage imageNamed:@"SEBScreenProctoringIcon_inactive_error"];
                dockItem = [[UIBarButtonItem alloc] initWithImage:ScreenProctoringIconInactiveState
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(screenProctoringButtonAction)];
                dockItem.accessibilityLabel = NSLocalizedString(@"Screen Proctoring Inactive",nil);
                _dockScreenProctoringButton = dockItem;
                [newDockItems addObject:dockItem];
                
                dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
                dockItem.width = 0;
                [newDockItems addObject:dockItem];
            }
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
                NSLocalizedString(@"Toggle Proctoring View", @"") :
                NSLocalizedString(@"Show Remote Proctoring Information", @"");
                dockItem.accessibilityHint = remoteProctoringViewShowPolicy != remoteProctoringViewShowNever ?
                NSLocalizedString(@"The overlay proctoring view is initially displayed in the lower right corner and can be swiped to other display corners.", @"") : @"";
                        
                _proctoringViewButton = dockItem;
                [newDockItems addObject:dockItem];
                
                dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
                dockItem.width = 0;
                [newDockItems addObject:dockItem];
            }
        }
        
        // Add scan QR code command/Home screen quick action/dock button
        // if SEB isn't running in exam mode (= no quit pw)
        BOOL examSession = preferences.secureSession;
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
                dockItem.accessibilityLabel = NSLocalizedString(@"Scan QR Code", @"");
                dockItem.accessibilityHint = [NSString stringWithFormat:NSLocalizedString(@"Displays a camera view to scan %@ configuration QR codes", @""), SEBShortAppName];
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
            dockItem.accessibilityLabel = NSLocalizedString(@"Quit Session", @"");
            dockItem.accessibilityHint = NSLocalizedString(@"Ends an exam session and returns to client settings", @"");
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
        CGFloat bottomSafeAreaInset = window.safeAreaInsets.bottom;
        if (bottomSafeAreaInset != 0)
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


- (void) activateZoomButtons:(BOOL)zoomEnabled
{
    sliderZoomPageResetItem.enabled = zoomEnabled;
    sliderZoomPageOutItem.enabled = zoomEnabled;
    sliderZoomPageInItem.enabled = zoomEnabled;
}


#pragma mark - Raise Hand Feature

- (void) raiseHandNotificationReceived:(NSInteger)notficationID
{
    if (_raiseHandRaised && raiseHandUID == notficationID) {
        [self toggleRaiseHandLoweredByServer:YES];
    }
}

- (void) toggleRaiseHand
{
    [self toggleRaiseHandLoweredByServer:NO];
}

- (void) toggleRaiseHandLoweredByServer:(BOOL)loweredByServer
{
    DDLogInfo(@"%s", __FUNCTION__);
    
    if (_raiseHandRaised) {
        _raiseHandRaised = NO;
        [self updateRaiseHandButtonStates];
        if (!loweredByServer) {
            [self.sebViewController.serverController sendLowerHandNotificationWithUID:raiseHandUID];
        }
        
    } else {
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_raiseHandButtonAlwaysPromptMessage"]) {
            [self showEnterRaiseHandMessageWindow];
        } else {
            [self raiseHand];
        }
    }
}

- (void) raiseHand
{
    if (!_raiseHandRaised) {
        _raiseHandRaised = YES;
        [self updateRaiseHandButtonStates];
        raiseHandUID = [self.sebViewController.serverController sendRaiseHandNotificationWithMessage:raiseHandNotification];
        raiseHandNotification = @"";
    }
}


- (void)updateRaiseHandButtonStates
{
    if (_raiseHandRaised) {
        _dockButtonRaiseHand.accessibilityLabel = raiseHandAccessibilityLabelRaised;
        [_dockButtonRaiseHand setImage:RaisedHandIconRaisedState tintColor: RaisedHandIconColorRaisedState];
        _sliderRaiseHandItem.icon = RaisedHandSliderItemRaisedState;
        _sliderRaiseHandItem.title = sliderRaiseHandItemTitleRaised;
    } else {
        _dockButtonRaiseHand.accessibilityLabel = raiseHandAccessibilityLabel;
        [_dockButtonRaiseHand setImage:RaisedHandIconDefaultState tintColor:RaisedHandIconColorDefaultState];
        _sliderRaiseHandItem.icon = RaisedHandSliderItemDefaultState;
        _sliderRaiseHandItem.title = sliderRaiseHandItemTitle;
    }
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"refreshSlider" object:self];
}




- (void) showEnterRaiseHandMessageWindow
{
    if (!_raiseHandRaised && !_raiseHandMessageAlertDisplayed) {
        _raiseHandMessageAlertDisplayed = YES;
        [self promptTextWithMessageText:NSLocalizedString(@"Enter Raise Hand message:", @"Prompting user to enter message for SEB Server Raise Hand feature")
                                  title:sliderRaiseHandItemTitle
                               callback:self
                               selector:@selector(enteredRaiseHandText:)];
    }
}

- (void) enteredRaiseHandText:(NSString *)text
{
    raiseHandNotification = text;
    if (raiseHandNotification) {
        [self raiseHand];
    }
    _raiseHandMessageAlertDisplayed = NO;
}


- (void) promptTextWithMessageText:(NSString *)messageText title:(NSString *)titleString callback:(id)callback selector:(SEL)selector
{
    if (_sebViewController.alertController) {
        [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _sebViewController.alertController = [UIAlertController alertControllerWithTitle:titleString
                                                                message:messageText
                                                         preferredStyle:UIAlertControllerStyleAlert];
    
    [_sebViewController.alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
//         textField.placeholder = NSLocalizedString(@"", @"");
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        textField.spellCheckingType = UITextSpellCheckingTypeNo;
        if (@available(iOS 17.0, *)) {
            textField.inlinePredictionType = UITextInlinePredictionTypeNo;
        }
     }];
    
    UIAlertAction *actionSend = [UIAlertAction actionWithTitle:NSLocalizedString(@"Send", @"")
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                 NSString *text = self->_sebViewController.alertController.textFields.firstObject.text;
                                                                 if (!text) {
                                                                     text = @"";
                                                                 }
                                                                 self->_sebViewController.alertController = nil;
                                                                 IMP imp = [callback methodForSelector:selector];
                                                                 void (*func)(id, SEL, NSString*) = (void *)imp;
                                                                 func(callback, selector, text);
                                                             }];
    [_sebViewController.alertController addAction:actionSend];
    
    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                                             style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                                 self->_sebViewController.alertController = nil;
                                                                 // Return nil to callback method to indicate that cancel was pressed
                                                                 IMP imp = [callback methodForSelector:selector];
                                                                 void (*func)(id, SEL, NSString*) = (void *)imp;
                                                                 func(callback, selector, nil);
                                                             }]];
//    _sebViewController.alertController.view.subviews[0].subviews[0].subviews[0].backgroundColor = [UIColor whiteColor];

    _sebViewController.alertController.preferredAction = actionSend;
    [_sebViewController.topMostController presentViewController:_sebViewController.alertController animated:NO completion:nil];
}


#pragma mark - Screen Proctoring SPSControllerUIDelegate methods

- (void) updateStatusWithString:(NSString *)string append:(BOOL)append
{
    run_on_ui_thread(^{
        self.dockScreenProctoringButton.accessibilityLabel = string;
        self.sliderScreenProctoringItem.title = string;
    });
}


- (void) screenProctoringButtonAction
{
    DDLogDebug(@"%s", __FUNCTION__);
}


- (void) setScreenProctoringButtonState:(ScreenProctoringButtonStates)screenProctoringButtonState
{
    [self setScreenProctoringButtonState:screenProctoringButtonState userFeedback:YES];
}

- (void) setScreenProctoringButtonState:(ScreenProctoringButtonStates)screenProctoringButtonState
                           userFeedback:(BOOL)userFeedback
{
    run_on_ui_thread(^{
        UIImage *dockScreenProctoringButtonImage;
        UIImage *sliderScreenProctoringItemImage;
        UIColor *screenProctoringButtonTintColor;
        DDLogDebug(@"[SEBController setScreenProctoringButtonState: %ld userFeedback: %@]", (long)screenProctoringButtonState, userFeedback ? @"YES" : @"NO");
        switch (screenProctoringButtonState) {
            case ScreenProctoringButtonStateActive:
                self.screenProctoringStateString = NSLocalizedString(@"Screen Proctoring Active",nil);
                self.dockScreenProctoringButton.accessibilityLabel = self.screenProctoringStateString;
                self.sliderScreenProctoringItem.title = self.screenProctoringStateString;
                dockScreenProctoringButtonImage = self->ScreenProctoringIconActiveState;
                sliderScreenProctoringItemImage = self->ScreenProctoringSliderItemActiveState;
                screenProctoringButtonTintColor = self->ScreenProctoringIconColorActiveState;
                break;
                
            case ScreenProctoringButtonStateActiveWarning:
                dockScreenProctoringButtonImage = self->ScreenProctoringIconActiveWarningState;
                sliderScreenProctoringItemImage = self->ScreenProctoringSliderItemActiveWarningState;
                screenProctoringButtonTintColor = self->ScreenProctoringIconColorWarningState;
                break;
                
            case ScreenProctoringButtonStateActiveError:
                dockScreenProctoringButtonImage = self->ScreenProctoringIconActiveErrorState;
                sliderScreenProctoringItemImage = self->ScreenProctoringSliderItemActiveErrorState;
                screenProctoringButtonTintColor = self->ScreenProctoringIconColorErrorState;
                break;
                
            case ScreenProctoringButtonStateInactive:
            default:
                self.screenProctoringStateString = NSLocalizedString(@"Screen Proctoring Inactive",nil);
                self.dockScreenProctoringButton.accessibilityLabel = self.screenProctoringStateString;
                self.sliderScreenProctoringItem.title = self.screenProctoringStateString;
                dockScreenProctoringButtonImage = self->ScreenProctoringIconInactiveState;
                sliderScreenProctoringItemImage = self->ScreenProctoringSliderItemInactiveState;
                break;
        }
        if (userFeedback) {
            self.dockScreenProctoringButton.image = dockScreenProctoringButtonImage;
            self.sliderScreenProctoringItem.icon = sliderScreenProctoringItemImage;
            self.dockScreenProctoringButton.tintColor = screenProctoringButtonTintColor;
        }
    });
}


- (void) setScreenProctoringButtonInfoString:(NSString *)infoString
{
    
    run_on_ui_thread(^{
        NSString *screenProctoringButtonStringShort;
        NSString *screenProctoringButtonString;
        if (infoString.length == 0) {
            screenProctoringButtonString = self.screenProctoringStateString;
            screenProctoringButtonStringShort = self.screenProctoringStateString;
        } else {
            screenProctoringButtonString = [NSString stringWithFormat:@"%@ (%@)", self.screenProctoringStateString, infoString];
            screenProctoringButtonStringShort = infoString;
        }
        self.dockScreenProctoringButton.accessibilityLabel = screenProctoringButtonString;
        self.sliderScreenProctoringItem.title = screenProctoringButtonStringShort;
    });
}


#pragma mark - Remote Proctoring

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
        _scrollLockButton.accessibilityLabel = NSLocalizedString(@"Scroll Lock Active", @"");
        _scrollLockButton.image = scrollLockIconLocked;
        _scrollLockButton.tintColor = [UIColor systemYellowColor];
        _sliderScrollLockItem.icon = sliderScrollLockIconLocked;
        _sliderScrollLockItem.title = sliderScrollLockItemTitleLocked;
    } else {
        _scrollLockButton.accessibilityLabel = NSLocalizedString(@"Scroll Lock Inactive", @"");
        _scrollLockButton.image = scrollLockIcon;
        _scrollLockButton.tintColor = nil;
        _sliderScrollLockItem.icon = sliderScrollLockIcon;
        _sliderScrollLockItem.title = sliderScrollLockItemTitle;
    }
}


- (void)zoomPageIn
{
    [_sebViewController zoomPageIn];
}

- (void)zoomPageOut
{
    [_sebViewController zoomPageOut];
}

- (void)zoomPageReset
{
    [_sebViewController zoomPageReset];
}


- (void)textSizeIncrease
{
    [_sebViewController textSizeIncrease];
}

- (void)textSizeDecrease
{
    [_sebViewController textSizeDecrease];
}

- (void)textSizeReset
{
    [_sebViewController textSizeReset];
}


- (IBAction)searchTextOnPage
{
    [_sebViewController searchTextOnPage];
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
    [_sebViewController quitExamConditionally:self];
}


@end
