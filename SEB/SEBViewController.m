//
//  SEBViewController.m
//
//  Created by Daniel R. Schneider on 10/09/15.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <WebKit/WebKit.h>
#import "Constants.h"
#import "UIViewController+LGSideMenuController.h"

#import "SEBViewController.h"

static NSMutableSet *browserWindowControllers;

@implementation SEBViewController

@synthesize appSettingsViewController;


#pragma mark - Initializing

- (IASKAppSettingsViewController*)appSettingsViewController {
    if (!appSettingsViewController) {
        appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
        _sebInAppSettingsViewController = [[SEBInAppSettingsViewController alloc] initWithIASKAppSettingsViewController:appSettingsViewController sebViewController:self];
        appSettingsViewController.delegate = _sebInAppSettingsViewController;
        SEBIASKSecureSettingsStore *sebSecureStore = [[SEBIASKSecureSettingsStore alloc] init];
        appSettingsViewController.settingsStore = sebSecureStore;
    }
    return appSettingsViewController;
}


- (SEBUIController *)sebUIController {
    SEBUIController *uiController = _appDelegate.sebUIController;
    uiController.sebViewController = self;
    return uiController;
}


- (SEBiOSConfigFileController*)configFileController
{
    if (!_configFileController) {
        _configFileController = [[SEBiOSConfigFileController alloc] init];
        _configFileController.sebViewController = self;
    }
    return _configFileController;
}


- (SEBiOSLockedViewController*)sebLockedViewController
{
    if (!_sebLockedViewController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _sebLockedViewController = [storyboard instantiateViewControllerWithIdentifier:@"SEBLockedView"];
    }

    return _sebLockedViewController;
}


- (JitsiViewController*)jitsiViewController
{
    if (!_jitsiViewController) {
        _jitsiViewController = [[JitsiViewController alloc] init];
    }
    _jitsiViewController.proctoringUIDelegate = self.sebUIController;
    return _jitsiViewController;
}


- (SEBiOSBrowserController *)browserController
{
    if (!_browserController) {
        _browserController = [[SEBiOSBrowserController alloc] init];
        _browserController.sebViewController = self;
    }
    return _browserController;
}


- (SEBBatteryController *) batteryController
{
    if (!_batteryController) {
        _batteryController = [[SEBBatteryController alloc] init];
    }
    return _batteryController;
}


- (ServerController*)serverController
{
    if (!_serverController) {
        _serverController = [[ServerController alloc] init];
        _serverController.delegate = self;
    }
    return _serverController;
}


- (UIViewController *)topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}


// Initialize and return QR code reader
- (QRCodeReaderViewController*)codeReaderViewController
{
    if ([QRCodeReader isAvailable]) {
        if (!_codeReaderViewController) {
            // Create the reader object
            QRCodeReader *codeReader = [QRCodeReader readerWithMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
            
            // Instantiate the view controller
            _codeReaderViewController = [QRCodeReaderViewController readerWithCancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                                                     codeReader:codeReader
                                                                            startScanningAtLoad:YES
                                                                         showSwitchCameraButton:NO
                                                                                showTorchButton:YES];
            
            // Set the presentation style
            _codeReaderViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            
            // Define the delegate receiver
            _codeReaderViewController.delegate = self;
        }
    } else {
        // Check if user denied access to camera
        NSString *mediaType = AVMediaTypeVideo;
        AVAuthorizationStatus camAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
        if (camAuthStatus == AVAuthorizationStatusDenied) {
            if (_alertController) {
                [_alertController dismissViewControllerAnimated:NO completion:nil];
            }
            _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Camera Access Denied", nil)
                                                                    message:NSLocalizedString(@"To scan a QR code, enable the camera in settings", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
            [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", nil)
                                                                 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                     self.alertController = nil;
                                                                     NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                                     if ([[UIApplication sharedApplication] canOpenURL:url]) {
                                                                         [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                                                                     }
                                                                 }]];
            [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                 style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                                     self.alertController = nil;
                                                                 }]];
            [self.topMostController presentViewController:_alertController animated:NO completion:nil];
        } else if (camAuthStatus == AVAuthorizationStatusNotDetermined) {
            if (_alertController) {
                [_alertController dismissViewControllerAnimated:NO completion:nil];
            }
            _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"No Camera Available", nil)
                                                                    message:NSLocalizedString(@"To scan a QR code, your device must have a camera", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
            [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                     self.alertController = nil;
                                                                 }]];
            [self.topMostController presentViewController:_alertController animated:NO completion:nil];
        }
    }
    return _codeReaderViewController;
}


+ (WKWebViewConfiguration *)defaultWebViewConfiguration
{
    static WKWebViewConfiguration *configuration;
    
    if (!configuration) {
        configuration = [[WKWebViewConfiguration alloc] init];
    }
    
    return configuration;
}


- (BOOL)isStartingUp
{
    return !_finishedStartingUp;
}


// Check if running on iOS 11.x earlier than 11.2.5
- (BOOL) allowediOSVersion {
    NSUInteger currentOSMajorVersion = NSProcessInfo.processInfo.operatingSystemVersion.majorVersion;
    NSUInteger currentOSMinorVersion = NSProcessInfo.processInfo.operatingSystemVersion.minorVersion;
    NSUInteger currentOSPatchVersion = NSProcessInfo.processInfo.operatingSystemVersion.patchVersion;
    if ((currentOSMajorVersion == 11 &&
         currentOSMinorVersion < 2) ||
        (currentOSMajorVersion == 11 &&
         currentOSMinorVersion == 2 &&
         currentOSPatchVersion < 5))
    {
        if (_alertController) {
            if (_alertController == _allowediOSAlertController) {
                return false;
            }
            [_alertController dismissViewControllerAnimated:NO completion:nil];
        }
        _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Running on Current iOS Version Not Allowed", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"For security reasons %@ cannot run on an iOS 11 version prior to iOS 11.2.5. Update to the current iOS version.", nil), SEBShortAppName]
                                                         preferredStyle:UIAlertControllerStyleAlert];
        _allowediOSAlertController = _alertController;
        [self.topMostController presentViewController:_alertController animated:NO completion:nil];
        return false;
    } else {
        return true;
    }
}


- (void) initializeLogger
{
    if (_appDelegate.myLogger) {
        [DDLog removeLogger:_appDelegate.myLogger];
    }
    // Initialize file logger if logging enabled
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableLogging"] == NO) {
        [DDLog removeLogger:_myLogger];
        _myLogger = nil;
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebMode"] == sebModeSebServer) {
            [DDLog removeLogger:ServerLogger.sharedInstance];
        }
    } else {
        if (!_myLogger) {
            _myLogger = [MyGlobals initializeFileLoggerWithDirectory:nil];
            [DDLog addLogger:_myLogger];
        }
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebMode"] == sebModeSebServer) {
            if (![DDLog.allLoggers containsObject:ServerLogger.sharedInstance]) {
                [DDLog addLogger:ServerLogger.sharedInstance];
                ServerLogger.sharedInstance.delegate = self;
            }
        }
    }
}


- (void) sendLogEventWithLogLevel:(NSUInteger)logLevel
                        timestamp:(NSString *)timestamp
                     numericValue:(double)numericValue
                          message:(NSString *)message
{
    [self.serverController sendLogEventWithLogLevel:logLevel timestamp:timestamp numericValue:numericValue message:message];
}


- (NSString *) appVersion
{
    NSString *displayName = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleDisplayName"];
    NSString *versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"];
    NSString *bundleID = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleIdentifier"];
    NSString *appVersion = [NSString stringWithFormat:@"%@_iOS_%@_%@_%@", displayName, versionString, buildNumber, bundleID];
    return appVersion;
}


#pragma mark - View management delegate methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    _appDelegate.sebViewController = self;
    [[MyGlobals sharedMyGlobals] setSebViewController:self];
    
    SEBRootViewController *rootViewController = (SEBRootViewController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    rootViewController.lgSideMenuController = self.sideMenuController;
    
    _browserTabViewController = self.childViewControllers[0];
    _browserTabViewController.sebViewController = self;
    
    self.sideMenuController.delegate = self;
    
    DDLogInfo(@"---------- INITIALIZING SEB - STARTING SESSION -------------");
    [self initializeLogger];
    
    NSString *displayName = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleDisplayName"];
    NSString *versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"];
    NSString *bundleID = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleIdentifier"];
    NSString *bundleExecutable = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleExecutable"];
    
    UIDevice *device = UIDevice.currentDevice;
    NSString *deviceName = device.name;
    NSString *systemName = device.systemName;
    NSString *systemVersion = device.systemVersion;
    NSString *deviceModel = device.model;
    
    device.batteryMonitoringEnabled = YES;
    float batteryLevel = device.batteryLevel;
    UIDeviceBatteryState batteryState = device.batteryState;

    DDLogInfo(@"%@ Version %@ (Build %@)", displayName, versionString, buildNumber);
    DDLogInfo(@"Bundle ID: %@, executable: %@", bundleID, bundleExecutable);
    DDLogInfo(@"%@, running %@ %@", deviceModel, systemName, systemVersion);
    DDLogInfo(@"Device name: %@", deviceName);
    DDLogInfo(@"Battery level: %.0f%% \(%ld)", batteryLevel*100, (long)batteryState);

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(singleAppModeStatusChanged)
                                                 name:UIAccessibilityGuidedAccessStatusDidChangeNotification object:nil];
    
    // Add an observer for the request to quit SEB without asking quit password
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(quitLinkDetected:)
                                                 name:@"quitLinkDetected" object:nil];
    
    // Add an observer for the request to quit SEB without confirming or asking for quit password
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(quitExam)
                                                 name:@"requestQuit" object:nil];
    
    // Add an observer for locking SEB
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(lockSEB:)
                                                 name:@"lockSEB" object:nil];
    
    // Add Notification Center observer to be alerted of any change to NSUserDefaults.
    // Managed app configuration changes pushed down from an MDM server appear in NSUSerDefaults.
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      NSDictionary *serverConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kConfigurationKey];
                                                      if (serverConfig.count > 0) {
                                                          if (self.didReceiveMDMConfig == NO &&
                                                              self.isReconfiguringToMDMConfig == NO &&
                                                              self.settingsOpen == NO &&
                                                              NSUserDefaults.userDefaultsPrivate == NO) {
                                                              self.didReceiveMDMConfig = YES;
                                                              DDLogVerbose(@"NSUserDefaultsDidChangeNotification: Did receive MDM Managed Configuration dictionary.");
                                                              // Only reconfigure immediately with config received from MDM server
                                                              // when settings aren't open (otherwise it's postponed to next
                                                              // session restart or when leaving and returning to SEB
                                                              [self conditionallyReadMDMServerConfig:serverConfig];
                                                          } else {
                                                              DDLogVerbose(@"NSUserDefaultsDidChangeNotification: Did receive MDM Managed Configuration dictionary, but%@%@%@%@. Not appying the MDM config for now.",
                                                                           self.didReceiveMDMConfig ? @" already processing received MDM config" : @"",
                                                                           self.isReconfiguringToMDMConfig ? @" already reconfiguring to MDM config" : @"",
                                                                           self.settingsOpen ? @" InAppSettings are open" : @"",
                                                                           NSUserDefaults.userDefaultsPrivate ? @" running with exam settings" : @"");
                                                          }
                                                      }
                                                  }];
    
    // Add Notification Center observer to be alerted when the UIScreen isCaptured property changes
    if (@available(iOS 11.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenCapturedDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          [self conditionallyOpenScreenCaptureLockdownWindows];
                                                      }];
    }
    // Was SEB opened by loading a .seb file/using a seb:// link?
    if (self.appDelegate.sebFileURL) {
        DDLogInfo(@"SEB was started by loading a .seb file/using a seb:// link");
        // Yes: Load the .seb file now that the necessary SEB main view controller was loaded
        if (self.settingsOpen) {
            DDLogInfo(@"SEB was started by loading a .seb file / seb:// link, but Settings were open, they need to be closed first");
            // Close settings
            [self.appSettingsViewController dismissViewControllerAnimated:YES completion:^{
                self.appSettingsViewController = nil;
                self.settingsOpen = false;
                [self conditionallyDownloadAndOpenSEBConfigFromURL:self.appDelegate.sebFileURL];
                
                // Set flag that SEB is initialized to prevent applying the client config
                // Start URL to be loaded
                [[MyGlobals sharedMyGlobals] setFinishedInitializing:YES];
            }];
        } else {
            [self conditionallyDownloadAndOpenSEBConfigFromURL:self.appDelegate.sebFileURL];
            
            // Set flag that SEB is initialized to prevent applying the client config
            // Start URL to be loaded
            [[MyGlobals sharedMyGlobals] setFinishedInitializing:YES];
        }
    } else if (self.appDelegate.shortcutItemAtLaunch) {
        // Was SEB opened by a Home screen quick action shortcut item?
        DDLogInfo(@"SEB was started by a Home screen quick action shortcut item");

        // Set flag that SEB is initialized to prevent applying the client config
        // Start URL to be loaded
        [[MyGlobals sharedMyGlobals] setFinishedInitializing:YES];

        [self handleShortcutItem:self.appDelegate.shortcutItemAtLaunch];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self becomeFirstResponder];

    [self adjustJitsiPiPDragBoundInsets];
    
    if ([self allowediOSVersion]) {
        // Check if we received new settings from an MDM server
        //    [self readDefaultsValues];
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        // Check if settings aren't initialized and initial config assistant should be started
        if (!_initAssistantOpen && [preferences boolForKey:@"allowEditingConfig"]) {
            [preferences setBool:NO forKey:@"allowEditingConfig"];
            if (!_ASAMActive) {
                [self conditionallyShowSettingsModal];
            }
        } else if ([preferences boolForKey:@"initiateResetConfig"]) {
            if (!_ASAMActive) {
                [self conditionallyResetSettings];
            }
        } else if ([preferences boolForKey:@"sendLogs"]) {
            [preferences setBool:NO forKey:@"sendLogs"];
            if (!_ASAMActive) {
                // If AAC isn't being started
                [self conditionallySendLogs];
            }
        } else if (![[MyGlobals sharedMyGlobals] finishedInitializing] &&
                   _appDelegate.openedURL == NO &&
                   _appDelegate.openedUniversalLink == NO) {
            // Initialize UI using client UI/browser settings
            [self initSEBUIWithCompletionBlock:^{
                [self conditionallyStartKioskMode];
            }];
        }
        
        // Set flag that SEB is initialized: Now showing alerts is allowed
        [[MyGlobals sharedMyGlobals] setFinishedInitializing:YES];
    }    
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (_openCloseSlider) {
        _openCloseSlider = NO;
        [self openCloseSliderForNewTab];
    }
    _viewDidLayoutSubviewsAlreadyCalled = YES;
}


- (void)newWebViewTabDidMoveToParentViewController
{
    if (_viewDidLayoutSubviewsAlreadyCalled) {
        _openCloseSlider = NO;
        [self openCloseSliderForNewTab];
    } else {
        _openCloseSlider = YES;
    }
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    if (@available(iOS 11.0, *)) {        
        // Hide the left slider menu before rotating the device
        // to prevent a black or white bar between side menu and main view
        [self.sideMenuController hideLeftView];
        [self adjustBars];

    } else {
        // If running on iOS < 11, displaying a status and navigation bar
        // and left slider view is showing
        // hide the left slider menu before rotating the device
        // to prevent a black or white bar underneath the navigation bar
        if (self.sideMenuController.leftViewShowing &&
            !self.prefersStatusBarHidden &&
            self.sebUIController.browserToolbarEnabled) {
            [self.sideMenuController hideLeftView];
        }
    }

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}


- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange: previousTraitCollection];
    
    [self adjustBars];
}


// Messy manual adjusting of navigation and toolbar to achieve the best
// possible look on iPhone and iPad Pro with new generation displays
- (void)adjustBars
{
    if (@available(iOS 11.0, *)) {
        BOOL sideSafeAreaInsets = false;
        CGFloat calculatedNavigationBarHeight = 0;
        CGFloat calculatedToolbarHeight = 0;
        navigationBarItemsOffset = 0;
        
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        CGFloat leftPadding = window.safeAreaInsets.left;
        sideSafeAreaInsets = leftPadding != 0;
        
        CGFloat statusbarHeight = window.safeAreaInsets.top;
        CGFloat navigationBarHeight = self.view.safeAreaInsets.top;
        calculatedNavigationBarHeight = navigationBarHeight - statusbarHeight;
        
        CGFloat homeIndicatorSpaceHeight = window.safeAreaInsets.bottom;
        CGFloat toolbarHeight = self.view.safeAreaInsets.bottom;
        calculatedToolbarHeight = toolbarHeight - homeIndicatorSpaceHeight;
        
        // iPad Pro 11 and 12.9 3rd generation have 50 or 42 pt calculated navigation bar height
        BOOL iPadExtendedDisplay = homeIndicatorSpaceHeight && (calculatedNavigationBarHeight == 50 ||
                                                                calculatedNavigationBarHeight == 42 ||
                                                                calculatedNavigationBarHeight == -24);
        
        _bottomBackgroundView.hidden = sideSafeAreaInsets;
        
        BOOL iPhoneXLandscape = (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact &&
                                 self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular);
        
        if (_navigationBarHeightConstraint) {
            CGFloat navigationBarHeight;
            CGFloat navigationBarOffset;
            // iPad Pro 11 and 12.9 3rd generation have 50/42 pt calculated navigation bar height
            if (iPadExtendedDisplay) {
                // But this is optically not ideal, so we change it manually
                navigationBarHeight = 42;
                navigationBarOffset = 24;
                navigationBarItemsOffset = -4;
                self.additionalSafeAreaInsets = UIEdgeInsetsMake(-8, 0, 0, 0);
                
            } else {
                navigationBarHeight = (sideSafeAreaInsets && iPhoneXLandscape) ? 32 : 46;
                navigationBarOffset = (sideSafeAreaInsets || !_finishedStartingUp) ? 0 : 12;
            }
            
            _navigationBarHeightConstraint.constant = navigationBarHeight;
            
            if (self.sideMenuController.leftViewShowing || (_finishedStartingUp && super.prefersStatusBarHidden)) {
                _navigationBarBottomConstraint.constant = navigationBarOffset;
            } else {
                _navigationBarBottomConstraint.constant = 0;
            }
        }
        
        if (_toolBarHeightConstraint) {
            CGFloat toolBarHeight;
            UIEdgeInsets newSafeArea;
            // iPad Pro 11 and 12.9 3rd generation have 46 pt calculated toolbar height
            if (calculatedToolbarHeight == 46 ||
                calculatedToolbarHeight == 26 ||
                calculatedToolbarHeight == -20) {
                // But this is optically not ideal, so we change it manually
                toolBarHeight = 42;
                newSafeArea = UIEdgeInsetsMake(-8, 0, -4, 0);
            } else {
                if (iPhoneXLandscape) {
                    toolBarHeight = 36;
                    newSafeArea = UIEdgeInsetsMake(0, 0, 2, 0);
                } else {
                    newSafeArea = UIEdgeInsetsMake(0, 0, -4, 0);
                    toolBarHeight = 46;
                }
                if (textSearchBar) {
                    [self setSearchBarWidthIcon:(textSearchBar.text.length == 0 && toolbarSearchButtonDone.hidden)];
                }
            }
            _toolBarHeightConstraint.constant = toolBarHeight;
            self.additionalSafeAreaInsets = newSafeArea;
            [self viewSafeAreaInsetsDidChange];
        }
    }
}


#pragma mark -
#pragma mark Animate safe area for left slider menu

- (void)willShowLeftView:(nonnull UIView *)leftView sideMenuController:(nonnull LGSideMenuController *)sideMenuController;
{
}


-(void)didShowLeftView:(UIView *)leftView sideMenuController:(LGSideMenuController *)sideMenuController
{
    
}


- (void)showAnimationsForLeftView:(nonnull UIView *)leftView sideMenuController:(nonnull LGSideMenuController *)sideMenuController duration:(NSTimeInterval)duration;
{
    [self changeLeftSafeAreaInset];
}


- (void)willHideLeftView:(nonnull UIView *)leftView sideMenuController:(nonnull LGSideMenuController *)sideMenuController;
{
    if (@available(iOS 11.0, *)) {
        if (self.sebUIController.extendedDisplay) {
            UIEdgeInsets newSafeArea = UIEdgeInsetsZero;
            self.parentViewController.additionalSafeAreaInsets = newSafeArea;
            [self viewSafeAreaInsetsDidChange];
        }
    }
}


-(void)willHideLeftViewWithGesture:(UIView *)leftView sideMenuController:(LGSideMenuController *)sideMenuController
{
    if (@available(iOS 11.0, *)) {
        if (self.sebUIController.extendedDisplay) {
            UIEdgeInsets newSafeArea = UIEdgeInsetsZero;
            self.parentViewController.additionalSafeAreaInsets = newSafeArea;
            [self viewSafeAreaInsetsDidChange];
        }
    }
}


- (void)didHideLeftView:(nonnull UIView *)leftView sideMenuController:(nonnull LGSideMenuController *)sideMenuController;
{
    [self becomeFirstResponder];
}


- (void)changeLeftSafeAreaInset
{
    if (@available(iOS 11.0, *)) {
        CGFloat leftSafeAreaInset = self.view.safeAreaInsets.left;
        if (self.sebUIController.extendedDisplay) {
            UIEdgeInsets newSafeArea = UIEdgeInsetsMake(0, -leftSafeAreaInset, 0, leftSafeAreaInset);
            self.parentViewController.additionalSafeAreaInsets = newSafeArea;
            [self viewSafeAreaInsetsDidChange];
        }
    }
}


#pragma mark - Handle request to reset settings

- (void)conditionallyResetSettings
{
    _resettingSettings = YES;
    if (_sebServerViewDisplayed) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.sebServerViewDisplayed = NO;
            self.establishingSEBServerConnection = NO;
            [self conditionallyResetSettings];
        }];
        return;
    } else if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:^{
            self.alertController = nil;
            [self conditionallyResetSettings];
        }];
        return;
    }
    // Check if settings are currently open
    if (_settingsOpen) {
        // Close settings, but check if settings presented the share dialog first
        DDLogInfo(@"SEB settings should be reset, but the Settings view was open, it will be closed first");
        if (self.appSettingsViewController.presentedViewController) {
            [self.appSettingsViewController.presentedViewController dismissViewControllerAnimated:NO completion:^{
                [self conditionallyResetSettings];
            }];
            return;
        } else if (self.appSettingsViewController) {
            [self.appSettingsViewController dismissViewControllerAnimated:YES completion:^{
                self.appSettingsViewController = nil;
                self.settingsOpen = false;
                [self conditionallyResetSettings];
            }];
            return;
        }
    } else {
        // If there is a hashed admin password the user has to enter it before editing settings
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        // Reset the setting for initiating the reset
        [preferences setBool:NO forKey:@"initiateResetConfig"];
        
        NSString *hashedAdminPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
        
        if (hashedAdminPassword.length == 0) {
            // There is no admin password: Immediately reset settings
            [self resetSettings];
        } else {
            // Allow up to 5 attempts for entering password
            attempts = 5;
            NSString *enterPasswordString = [NSString stringWithFormat:NSLocalizedString(@"You can only reset settings after entering the %@ administrator password:", nil), SEBShortAppName];
            
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.configFileController promptPasswordWithMessageText:enterPasswordString
                                                               title:NSLocalizedString(@"Reset Settings",nil)
                                                            callback:self
                                                            selector:@selector(resetSettingsEnteredAdminPassword:)];
            return;
        }
    }
}


- (void) resetSettingsEnteredAdminPassword:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
        _resettingSettings = NO;
        if (!_finishedStartingUp) {
            // Continue starting up SEB without resetting settings
            [self conditionallyStartKioskMode];
        }
        return;
    }
    
    attempts--;
    
    if (![self correctAdminPassword:password]) {
        // wrong password entered, are there still attempts left?
        if (attempts > 0) {
            // Let the user try it again
            NSString *enterPasswordString = [NSString stringWithFormat:NSLocalizedString(@"Wrong password! Try again to enter the current %@ administrator password:",nil), SEBShortAppName];
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.configFileController promptPasswordWithMessageText:enterPasswordString
                                                               title:NSLocalizedString(@"Reset Settings",nil)
                                                            callback:self
                                                            selector:@selector(resetSettingsEnteredAdminPassword:)];
            return;
            
        } else {
            // Wrong password entered in the last allowed attempts: Stop reading .seb file
            DDLogError(@"%s: Cannot Reset SEB Settings: You didn't enter the correct current SEB administrator password.", __FUNCTION__);
            
            NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Cannot Reset %@ Settings", nil), SEBExtraShortAppName];
            NSString *informativeText = [NSString stringWithFormat:NSLocalizedString(@"You didn't enter the correct %@ administrator password.", nil), SEBShortAppName];
            [self.configFileController showAlertWithTitle:title andText:informativeText];
            _resettingSettings = NO;
            
            if (!_finishedStartingUp) {
                // Continue starting up SEB without resetting settings
                [self conditionallyStartKioskMode];
            }
        }
        
    } else {
        // The correct admin password was entered: continue resetting SEB settings
        [self resetSettings];
        return;
    }
}


- (void)resetSettings
{
    // Switch to system's (persisted) UserDefaults
    [NSUserDefaults setUserDefaultsPrivate:NO];
    
    // Write just default SEB settings to UserDefaults
    NSDictionary *emptySettings = [NSDictionary dictionary];
    [self.configFileController storeIntoUserDefaults:emptySettings];
    [[NSUserDefaults standardUserDefaults] setSecureString:@"" forKey:@"configFileName"];
    
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:YES];
    
    DDLogInfo(@"---------- SEB SETTINGS RESET PERFORMED -------------");
    [self initializeLogger];
    
    [self resetSEB];
    _resettingSettings = NO;
    [self initSEBUIWithCompletionBlock:^{
        [self openInitAssistant];
    }];
}


#pragma mark - Handle requests to send logs

- (void)conditionallySendLogs
{
    // Check if an alert is open and dismiss it
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:^{
            self.alertController = nil;
            [self conditionallySendLogs];
        }];
        return;
    } else {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _aboutSEBViewController = [storyboard instantiateViewControllerWithIdentifier:@"AboutSEBView"];
        _aboutSEBViewController.sebViewController = self;
        [_aboutSEBViewController sendLogsByEmail];
    }
}


#pragma mark - Initial Configuration Assistant

- (void)openInitAssistant
{
    if (!_initAssistantOpen) {
        if (_alertController) {
            [_alertController dismissViewControllerAnimated:NO completion:^{
                self.alertController = nil;
                [self openInitAssistant];
            }];
            return;
        }
        
        if (!_assistantViewController) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            _assistantViewController = [storyboard instantiateViewControllerWithIdentifier:@"SEBInitAssistantView"];
            _assistantViewController.sebViewController = self;
            _assistantViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            if (@available(iOS 13.0, *)) {
                _assistantViewController.modalInPopover = YES;
            }
        }
        //// Initialize SEB Dock, commands section in the slider view and
        //// 3D Touch Home screen quick actions
        
        // Add scan QR code Home screen quick action
        [UIApplication sharedApplication].shortcutItems = [NSArray arrayWithObject:[self scanQRCodeShortcutItem]];
        
        self.initAssistantOpen = true;
        [self.topMostController presentViewController:_assistantViewController animated:YES completion:^{
        }];
    }
}


- (UIApplicationShortcutItem *)scanQRCodeShortcutItem
{
    UIApplicationShortcutIcon *shortcutItemIcon = [UIApplicationShortcutIcon iconWithTemplateImageName:@"SEBQuickActionQRCodeIcon"];
    NSString *shortcutItemType = [NSString stringWithFormat:@"%@.ScanQRCodeConfig", [NSBundle mainBundle].bundleIdentifier];
    UIApplicationShortcutItem *scanQRCodeShortcutItem = [[UIApplicationShortcutItem alloc] initWithType:shortcutItemType
                                                                                         localizedTitle:NSLocalizedString(@"Config QR Code", nil)
                                                                                      localizedSubtitle:nil
                                                                                                   icon:shortcutItemIcon
                                                                                               userInfo:nil];
    scanQRCodeShortcutItem.accessibilityLabel = NSLocalizedString(@"Scan QR Code", nil);
    scanQRCodeShortcutItem.accessibilityHint = NSLocalizedString(@"Displays a camera view to scan for SEB configuration QR codes", nil);
    return scanQRCodeShortcutItem;
}


- (void)showConfigURLWarning:(NSError *)error
{
    [self alertWithTitle:[error.userInfo objectForKey:NSLocalizedDescriptionKey]
                 message:[error.userInfo objectForKey:NSLocalizedFailureReasonErrorKey]
            action1Title:NSLocalizedString(@"OK", nil)
          action1Handler:^{}
            action2Title:nil
          action2Handler:^{}];
}


#pragma mark - Handle Home screen quick actions

- (BOOL)handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem
{
    BOOL handled = false;
    
    NSString *scanQRCodeConfigItemType = [NSString stringWithFormat:@"%@.ScanQRCodeConfig", [NSBundle mainBundle].bundleIdentifier];
    
    if ([shortcutItem.type isEqualToString:scanQRCodeConfigItemType]) {
        handled = true;
        [self scanQRCode];
    }
    return handled;
}


#pragma mark - QRCodeReader

- (void)scanQRCode
{
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:^{
            self.alertController = nil;
            [self scanQRCode];
        }];
        return;
    }
    [self.sideMenuController hideLeftViewAnimated];
    
    _visibleCodeReaderViewController = self.codeReaderViewController;
    if (_visibleCodeReaderViewController) {
        if ([QRCodeReader isAvailable]) {
            [self.topMostController presentViewController:_visibleCodeReaderViewController animated:YES completion:NULL];
        }
    }
}


#pragma mark - QRCodeReader Delegate Methods

- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [self becomeFirstResponder];
    
    if (!_scannedQRCode) {
        _scannedQRCode = YES;
        [_visibleCodeReaderViewController dismissViewControllerAnimated:YES completion:^{
            self.visibleCodeReaderViewController = nil;
            [self adjustBars];
            DDLogInfo(@"Scanned QR code: %@", result);
            NSURL *URLFromString = [NSURL URLWithSEBString:result];
            if (URLFromString) {
                [self conditionallyDownloadAndOpenSEBConfigFromURL:URLFromString];
            } else {
                NSError *error = [self.configFileController errorCorruptedSettingsForUnderlyingError:[NSError new]];
                [self storeNewSEBSettingsSuccessful:error];
            }
        }];
    }
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self becomeFirstResponder];
    
    [self.sideMenuController hideLeftView];
    [self adjustBars];
    [_visibleCodeReaderViewController dismissViewControllerAnimated:YES completion:^{
        self.visibleCodeReaderViewController = nil;
        if (!self.finishedStartingUp || self.pausedSAMAlertDisplayed) {
            self.pausedSAMAlertDisplayed = false;
            // Continue starting up SEB without resetting settings
            // but user interface might need to be re-initialized
            [self initSEBUIWithCompletionBlock:^{
                [self conditionallyStartKioskMode];
            }];
        }
    }];
}


#pragma mark - Handle requests to show in-app settings

- (void)conditionallyShowSettingsModal
{
    _openingSettings = YES;
    // Check if the initialize settings assistant is open
    if (_initAssistantOpen) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.initAssistantOpen = NO;
            [self conditionallyShowSettingsModal];
        }];
        return;
    } else if (_sebServerViewDisplayed) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.sebServerViewDisplayed = NO;
            self.establishingSEBServerConnection = NO;
            [self conditionallyShowSettingsModal];
        }];
        return;
    } else if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:^{
            self.alertController = nil;
            [self conditionallyShowSettingsModal];
        }];
        return;
    } else {
        // Check if settings are already displayed
        if (!_settingsOpen) {
            // If there is a hashed admin password the user has to enter it before editing settings
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            NSString *hashedAdminPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
            
            if (hashedAdminPassword.length == 0) {
                // There is no admin password: Just open settings
                [self showSettingsModalCheckMDMSettingsReceived];
            } else {
                // Allow up to 5 attempts for entering password
                attempts = 5;
                NSString *enterPasswordString = [NSString stringWithFormat:NSLocalizedString(@"You can only edit settings after entering the %@ administrator password:", nil), SEBShortAppName];
                
                // Ask the user to enter the settings password and proceed to the callback method after this happend
                [self.configFileController promptPasswordWithMessageText:enterPasswordString
                                                                   title:NSLocalizedString(@"Edit Settings",nil)
                                                                callback:self
                                                                selector:@selector(enteredAdminPassword:)];
                return;
            }
        }
        _openingSettings = NO;
    }
}


- (void) enteredAdminPassword:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
        _openingSettings = NO;
        // Continue SEB without displaying settings
        [self.sideMenuController hideLeftViewAnimated];
        if (!_finishedStartingUp) {
            [self conditionallyStartKioskMode];
        }
        return;
    }
    
    attempts--;
    
    if (![self correctAdminPassword:password]) {
        // wrong password entered, are there still attempts left?
        if (attempts > 0) {
            // Let the user try it again
            NSString *enterPasswordString = [NSString stringWithFormat:NSLocalizedString(@"Wrong password! Try again to enter the current %@ administrator password:",nil), SEBShortAppName];
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.configFileController promptPasswordWithMessageText:enterPasswordString
                                                               title:NSLocalizedString(@"Edit Settings",nil)
                                                            callback:self
                                                            selector:@selector(enteredAdminPassword:)];
            return;
            
        } else {
            // Wrong password entered in the last allowed attempts: Stop reading .seb file
            DDLogError(@"%s: Cannot Edit SEB Settings: You didn't enter the correct current SEB administrator password.", __FUNCTION__);
            
            NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Cannot Edit %@ Settings", nil), SEBExtraShortAppName];
            NSString *informativeText = [NSString stringWithFormat:NSLocalizedString(@"You didn't enter the correct %@ administrator password.", nil), SEBShortAppName];
            [self.configFileController showAlertWithTitle:title andText:informativeText];
            
            // Continue SEB without displaying settings
            _openingSettings = NO;
            [self.sideMenuController hideLeftViewAnimated];
            if (!_finishedStartingUp) {
                [self conditionallyStartKioskMode];
            }
        }
        
    } else {
        // The correct admin password was entered: continue processing the parsed SEB settings it
        [self showSettingsModalCheckMDMSettingsReceived];
        return;
    }
}

- (BOOL)correctAdminPassword: (NSString *)password {
    // Get admin password hash from current client settings
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedAdminPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
    if (!hashedAdminPassword) {
        hashedAdminPassword = @"";
    } else {
        hashedAdminPassword = [hashedAdminPassword uppercaseString];
    }
    
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSString *hashedPassword;
    if (password.length == 0) {
        // An empty password has to be an empty hashed password string
        hashedPassword = @"";
    } else {
        hashedPassword = [keychainManager generateSHAHashString:password];
        hashedPassword = [hashedPassword uppercaseString];
    }
    return [hashedPassword caseInsensitiveCompare:hashedAdminPassword] == NSOrderedSame;
}


#pragma mark - Show About SEB

- (void)showAboutSEB
{
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:^{
            self.alertController = nil;
            [self showAboutSEB];
        }];
        return;
    }
    [self.sideMenuController hideLeftViewAnimated];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _aboutSEBViewController = [storyboard instantiateViewControllerWithIdentifier:@"AboutSEBView"];
    _aboutSEBViewController.sebViewController = self;
    _aboutSEBViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.topMostController presentViewController:_aboutSEBViewController animated:YES completion:^{
        self.aboutSEBViewDisplayed = true;
    }];
}


#pragma mark - Show in-app settings

- (void)showSettingsModalCheckMDMSettingsReceived
{
    [self.sideMenuController hideLeftViewAnimated];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *serverConfig = [preferences dictionaryForKey:kConfigurationKey];
    BOOL isClientConfigActive = !NSUserDefaults.userDefaultsPrivate;
    DDLogDebug(@"%s: %@ receive MDM Managed Configuration dictionary while client config is%@ active.", __FUNCTION__, serverConfig.count > 0 ? @"Did" : @"Didn't", isClientConfigActive ? @"" : @"n't");
    if (isClientConfigActive &&
        serverConfig.count &&
        [self isReceivedServerConfigNew:serverConfig])
    {
        _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Received Config from MDM Server", nil)
                                                                message:NSLocalizedString(@"Do you want to abort opening Settings and apply this managed configuration?", nil)
                                                         preferredStyle:UIAlertControllerStyleAlert];
        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.alertController = nil;
            self->receivedServerConfig = nil;
            self.didReceiveMDMConfig = YES;
            if (![self readMDMServerConfig:serverConfig]) {
                [self showSettingsModal];
            }
        }]];
        
        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                             style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            self.alertController = nil;
            [self showSettingsModal];
        }]];
        
        [self.topMostController presentViewController:_alertController animated:NO completion:nil];
        
        return;
    }
    [self showSettingsModal];
}


- (void)showSettingsModal
{
    _settingsOpen = true;
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Get hashed passwords and put empty or placeholder strings into the password fields in InAppSettings
    NSString *hashedPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
    NSString *placeholder = [self placeholderStringForHashedPassword:hashedPassword];
    [preferences setSecureString:placeholder forKey:@"adminPassword"];
    adminPasswordPlaceholder = true;
    
    hashedPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    placeholder = [self placeholderStringForHashedPassword:hashedPassword];
    [preferences setSecureString:placeholder forKey:@"quitPassword"];
    quitPasswordPlaceholder = true;
    
    // Dismiss an alert in case one is open
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:^{
            self.alertController = nil;
        }];
    }
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.appSettingsViewController];
    
    self.appSettingsViewController.showDoneButton = YES;
    if (@available(iOS 13.0, *)) {
        self.appSettingsViewController.modalInPopover = YES;
    }
    
    if (!settingsShareButton) {
        settingsShareButton = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                               target:self
                               action:@selector(shareSettingsAction:)];
        settingsShareButton.accessibilityLabel = NSLocalizedString(@"Share", nil);
        settingsShareButton.accessibilityHint = NSLocalizedString(@"Share settings", nil);
        
    }
    if (!settingsActionButton) {
        settingsActionButton = [[UIBarButtonItem alloc]
                                initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                target:self
                                action:@selector(moreSettingsActions:)];
        settingsActionButton.accessibilityLabel = NSLocalizedString(@"Settings Actions", nil);
        settingsActionButton.accessibilityHint = NSLocalizedString(@"Actions for creating or resetting settings", nil);
        
    }
    self.appSettingsViewController.navigationItem.leftBarButtonItems = @[settingsShareButton, settingsActionButton];
    
    // Register notification for changed keys
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inAppSettingsChanged:)
                                                 name:kIASKAppSettingChanged
                                               object:nil];
    
    if (NSUserDefaults.userDefaultsPrivate) {
        [self.appSettingsViewController setHiddenKeys:[NSSet setWithObjects:@"autoIdentity",
                                                       @"org_safeexambrowser_SEB_configFileCreateIdentity",
                                                       @"org_safeexambrowser_SEB_configFileEncryptUsingIdentity", nil]];
    }
    
    [self.topMostController presentViewController:navigationController animated:YES completion:^{
        self.openingSettings = NO;
    }];
}


- (void)inAppSettingsChanged:(NSNotification *)notification
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSArray *changedKeys = [notification.userInfo allKeys];
    
    if ([changedKeys containsObject:@"adminPassword"]) {
        adminPasswordPlaceholder = false;
    }
    
    if ([changedKeys containsObject:@"quitPassword"]) {
        quitPasswordPlaceholder = false;
    }
}


// Update entered passwords and save their hashes to SEB settings
// as long as the passwords were really entered and don't contain the hash placeholders
- (void)updateEnteredPasswords
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *password;
    NSString *hashedPassword;
    
    if (!adminPasswordPlaceholder) {
        password = [preferences secureStringForKey:@"adminPassword"];
        hashedPassword = [self sebHashedPassword:password];
        [preferences setSecureString:hashedPassword forKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
    }
    
    if (!quitPasswordPlaceholder) {
        password = [preferences secureStringForKey:@"quitPassword"];
        hashedPassword = [self sebHashedPassword:password];
        [preferences setSecureString:hashedPassword forKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    }
}


- (void)shareSettingsAction:(id)sender
{
    DDLogInfo(@"Share settings button pressed");
    
    // Update entered passwords and save their hashes to SEB settings
    // as long as the passwords were really entered and don't contain the hash placeholders
    [self updateEnteredPasswords];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Get selected config purpose
    sebConfigPurposes configPurpose = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebConfigPurpose"];
    
    // If this config is for starting an exam
    if (configPurpose == sebConfigPurposeStartingExam &&
        // Check if the option "Auto-Select Identity" was enabled in client config
        [preferences persistedSecureBoolForKey:@"org_safeexambrowser_SEB_configFileEncryptUsingIdentity"] &&
        // If yes and no identity was manually selected
        [preferences secureIntegerForKey:@"org_safeexambrowser_configFileIdentity"] == 0 &&
        self.sebInAppSettingsViewController.identitiesCounter.count > 0) {
        // Select the latest identity added to settings
        [self.sebInAppSettingsViewController selectLatestSettingsIdentity];
    }
    
    // Get SecIdentityRef for selected identity
    SecIdentityRef identityRef;
    identityRef = [_sebInAppSettingsViewController getSelectedIdentity];
    
    NSString *encryptedWithIdentity = (identityRef && configPurpose != sebConfigPurposeManagedConfiguration) ? [NSString stringWithFormat:@", %@ '%@'", NSLocalizedString(@"encrypted with identity certificate ", nil), [self.sebInAppSettingsViewController getSelectedIdentityName]] : @"";
    
    // Get password
    NSString *encryptingPassword;
    // Is there one saved from the currently open config file?
    encryptingPassword = [preferences secureStringForKey:@"org_safeexambrowser_settingsPassword"];
    
    // Encrypt current settings with current credentials
    NSData *encryptedSEBData = [self.configFileController encryptSEBSettingsWithPassword:encryptingPassword
                                                                          passwordIsHash:NO
                                                                            withIdentity:identityRef
                                                                              forPurpose:configPurpose];
    if (encryptedSEBData) {
        
        if (_alertController) {
            [_alertController dismissViewControllerAnimated:NO completion:^{
                self.alertController = nil;
            }];
        }
        
        // Get config file name
        NSString *configFileName = [preferences secureStringForKey:@"configFileName"];
        if (configFileName.length == 0) {
            configFileName = @"SEBConfigFile";
        }
        
        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:configFileName];
        NSString *configFilePath = [documentsPath stringByAppendingPathExtension:configPurpose == sebConfigPurposeManagedConfiguration ? @"plist" : SEBFileExtension];
        NSURL *configFileRUL = [NSURL fileURLWithPath:configFilePath];
        
        [encryptedSEBData writeToURL:configFileRUL atomically:YES];
        
        NSArray *activityItems;
        
        NSString *configFilePurpose = (configPurpose == sebConfigPurposeStartingExam ?
                                       [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"for starting an exam", nil), encryptedWithIdentity] :
                                       (configPurpose == sebConfigPurposeConfiguringClient ?
                                        NSLocalizedString(@"for configuring clients", nil) :
                                        NSLocalizedString(@"for Managed Configuration (MDM)", nil)));
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"] &&
            ([preferences secureBoolForKey:@"org_safeexambrowser_configFileShareBrowserExamKey"] ||
             [preferences secureBoolForKey:@"org_safeexambrowser_configFileShareConfigKey"]))
        {
            NSData *hashKey;
            NSMutableString *activityString = NSMutableString.new;
            if ([preferences secureBoolForKey:@"org_safeexambrowser_configFileShareBrowserExamKey"]) {
                hashKey = self.browserController.browserExamKey;
                [activityString appendFormat:@"%@",
                 hashKey ? [NSString stringWithFormat:@"\nBrowser Exam Key: %@", [self base16StringForHashKey:hashKey]] : nil];
            }
            if ([preferences secureBoolForKey:@"org_safeexambrowser_configFileShareConfigKey"]) {
                hashKey = self.browserController.configKey;
                [activityString appendFormat:@"%@",
                 hashKey ? [NSString stringWithFormat:@"\nConfig Key: %@", [self base16StringForHashKey:hashKey]] : nil];
            }
            if ([preferences secureIntegerForKey:@"org_safeexambrowser_configFileShareKeys"] == configFileShareKeysWithoutConfig) {
                activityItems = @[ [NSString stringWithFormat:NSLocalizedString(@"Browser Exam and/or Config Keys for %@ %@ Config File %@%@", nil), _sebInAppSettingsViewController.permanentSettingsChanged ? @"MODIFIED (!)" : @"unmodified", SEBShortAppName, configFilePurpose, activityString] ];
            } else {
                activityItems = @[ [NSString stringWithFormat:NSLocalizedString(@"%@ Config File %@%@", nil), SEBShortAppName, configFilePurpose, activityString], configFileRUL ];
            }
        } else {
            activityItems = @[ [NSString stringWithFormat:NSLocalizedString(@"%@ Config File %@", nil), SEBShortAppName, configFilePurpose], configFileRUL ];
        }
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];
        activityVC.popoverPresentationController.barButtonItem = settingsShareButton;
        [self.appSettingsViewController presentViewController:activityVC animated:TRUE completion:nil];
    }
}


- (NSString *)base16StringForHashKey:(NSData *)hashKey
{
    unsigned char hashedChars[32];
    [hashKey getBytes:hashedChars length:32];
    NSMutableString* hashedConfigKeyString = [[NSMutableString alloc] initWithCapacity:32];
    for (NSUInteger i = 0 ; i < 32 ; ++i) {
        [hashedConfigKeyString appendFormat: @"%02x", hashedChars[i]];
    }
    return hashedConfigKeyString.copy;
}


- (void)moreSettingsActions:(id)sender
{
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _alertController = [UIAlertController  alertControllerWithTitle:nil
                                                            message:nil
                                                     preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (!NSUserDefaults.userDefaultsPrivate) {
        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Create Exam Settings", nil)
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.alertController = nil;
            
            DDLogInfo(@"Create Exam Settings");
            
            // Update entered passwords and save their hashes to SEB settings
            // as long as the passwords were really entered and don't contain the hash placeholders
            [self updateEnteredPasswords];
            
            // Get key/values from local shared client UserDefaults
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            NSDictionary *localClientPreferences = [preferences dictionaryRepresentationSEB];
            
            // Cache the option "Auto-Select Identity"
            BOOL configFileEncryptUsingIdentity = ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_configFileEncryptUsingIdentity"]);
            
            // Reset config file hash, so the auto-select option can do its job
            self.configFileKeyHash = nil;
            
            // Switch to private UserDefaults (saved non-persistently in memory)
            NSMutableDictionary *privatePreferences = [NSUserDefaults privateUserDefaults]; //the mutable dictionary has to be created here, otherwise the preferences values will not be saved!
            [NSUserDefaults setUserDefaultsPrivate:YES];
            
            [self.configFileController storeIntoUserDefaults:localClientPreferences];
            
            DDLogVerbose(@"Private preferences set: %@", privatePreferences);
            
            // Switch config purpose to "starting exam"
            [preferences setSecureInteger:sebConfigPurposeStartingExam forKey:@"org_safeexambrowser_SEB_sebConfigPurpose"];
            
            // Check if the option "Auto-Select Identity" was enabled in client config
            if (configFileEncryptUsingIdentity &&
                [[NSUserDefaults standardUserDefaults] secureIntegerForKey:@"org_safeexambrowser_configFileIdentity"] == 0 &&
                self.sebInAppSettingsViewController.identitiesCounter.count > 0) {
                // Select the last identity certificate from the list
                [self.sebInAppSettingsViewController selectLatestSettingsIdentity];
            }
            //                                                                 [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:YES];
            
            // Close then reopen settings view controller (so new settings are displayed)
            [self closeThenReopenSettings];
        }]];
    } else {
        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Revert to Client Settings", nil)
                                                             style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            self.alertController = nil;
            
            // Switch to system's UserDefaults (persisted)
            [NSUserDefaults setUserDefaultsPrivate:NO];
            //                                                                 [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
            
            // Reset config file hash (client config isn't encrypted using an identity)
            self.configFileKeyHash = nil;
            
            // Close then reopen settings view controller (so new settings are displayed)
            [self closeThenReopenSettings];
        }]];
    }
    
    
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Reset to Default Settings", nil)
                                                         style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        self.alertController = nil;
        
        // Write just default SEB settings to UserDefaults
        NSDictionary *emptySettings = [NSDictionary dictionary];
        [self.configFileController storeIntoUserDefaults:emptySettings];
        
        //                                                             [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:YES];
        // Close then reopen settings view controller (so new settings are displayed)
        [self closeThenReopenSettings];
    }]];
    
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        self.alertController = nil;
        
    }]];
    
    _alertController.popoverPresentationController.barButtonItem = sender;
    _alertController.popoverPresentationController.sourceView = self.view;
    
    [self.topMostController presentViewController:_alertController animated:NO completion:nil];
}


- (void)closeThenReopenSettings
{
    [self.appSettingsViewController dismissViewControllerAnimated:NO completion:^{
        self.appSettingsViewController = nil;
        [self showSettingsModalCheckMDMSettingsReceived];
    }];
}


- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [self becomeFirstResponder];
    
    // Update entered passwords and save their hashes to SEB settings
    // as long as the passwords were really entered and don't contain the hash placeholders
    [self updateEnteredPasswords];
    
    _settingsOpen = false;
    
    NSMutableString *pasteboardString = NSMutableString.new;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"] &&
        ([preferences secureBoolForKey:@"org_safeexambrowser_configFileShareBrowserExamKey"] ||
         [preferences secureBoolForKey:@"org_safeexambrowser_configFileShareConfigKey"]))
    {
        NSData *hashKey;
        NSString *browserExamKey;
        if ([preferences secureBoolForKey:@"org_safeexambrowser_configFileShareBrowserExamKey"]) {
            hashKey = self.browserController.browserExamKey;
            browserExamKey = [self base16StringForHashKey:hashKey];
        }
        if ([preferences secureBoolForKey:@"org_safeexambrowser_configFileShareConfigKey"]) {
            hashKey = self.browserController.configKey;
            if (browserExamKey) {
                [pasteboardString appendFormat:@"%@: %@\n%@: ",
                 NSLocalizedString(@"Browser Exam Key", @"Browser Exam Key"),
                 browserExamKey,
                 NSLocalizedString(@"Config Key", @"Config Key")];
            }
            [pasteboardString appendFormat:@"%@", [self base16StringForHashKey:hashKey]];
        } else {
            browserExamKey ? [pasteboardString appendFormat:@"%@", browserExamKey] : nil;
        }
    }
    
    // Settings
    if (_startingExamFromSEBServer) {
        _startingExamFromSEBServer = NO;
        //        [self.serverController loginToExamAborted];
    }
    
    // Restart exam: Close all tabs, reset browser and reset kiosk mode
    // before re-initializing SEB with new settings
    _settingsDidClose = YES;
    [self restartExamQuitting:NO quittingClientConfig:NO pasteboardString:pasteboardString.copy];
}


#pragma mark - Handle MDM Managed App Configuration

- (BOOL)conditionallyReadMDMServerConfig:(NSDictionary *)serverConfig
{
    BOOL readMDMConfig = NO;
    
    // Check again if not running in exam mode, to catch timing related issues
    BOOL clientConfigActive = !NSUserDefaults.userDefaultsPrivate;
    if (clientConfigActive) {
        if (!_isReconfiguringToMDMConfig) {
            // Check if we received a new configuration from an MDM server
            _isReconfiguringToMDMConfig = YES;
            NSString *currentURL = [self.browserTabViewController.currentURL.absoluteString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
            NSString *currentStartURLTrimmed = [currentStartURL stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
            DDLogVerbose(@"%s: %@ receive MDM Managed Configuration dictionary. Check for openWebpages.count: %lu = 1 AND (currentMainHost == nil OR currentMainHost %@ is equal to currentStartURL %@ OR clientConfigSecureModePaused: %d)",
                         __FUNCTION__, serverConfig.count > 0 ? @"Did" : @"Didn't",
                         (unsigned long)self.browserTabViewController.openWebpages.count,
                         currentURL,
                         currentStartURLTrimmed,
                         _clientConfigSecureModePaused);
            if (serverConfig.count > 0 &&
                clientConfigActive &&
                (!currentURL || !currentStartURL ||
                 (self.browserTabViewController.openWebpages.count == 1 &&
                  [currentURL isEqualToString:currentStartURLTrimmed]) ||
                 _clientConfigSecureModePaused))
            {
                DDLogVerbose(@"%s: Received new configuration from MDM server (containing %lu setting key/values), while client config is active, only exam page is open and browser is still displaying the Start URL.", __FUNCTION__, (unsigned long)serverConfig.count);
                readMDMConfig = [self readMDMServerConfig:serverConfig];
                _didReceiveMDMConfig = NO;
                return readMDMConfig;
            } else {
                DDLogVerbose(@"%s: %@ receive non-empty MDM Managed Configuration dictionary, reconfiguring isn't allowed currently.", __FUNCTION__, serverConfig.count > 0 ? @"Did" : @"Didn't");
                _isReconfiguringToMDMConfig = NO;
            }
        } else {
            DDLogVerbose(@"%s: Already reconfiguring to MDM config!", __FUNCTION__);
        }
    } else {
        _isReconfiguringToMDMConfig = NO;
    }
    _didReceiveMDMConfig = NO;
    return readMDMConfig;
}


- (BOOL)readMDMServerConfig:(NSDictionary *)serverConfig
{
    BOOL readMDMConfig = NO;
    // Check again if not running in exam mode, to catch timing related issues
    if (!NSUserDefaults.userDefaultsPrivate) {
        if ([self didNotReceiveSameServerConfig:serverConfig]) {
            _isReconfiguringToMDMConfig = YES;
            readMDMConfig = YES;
            // If we did receive a config and SEB isn't running in exam mode currently
            DDLogDebug(@"%s: Received new configuration from MDM server with %lu keys", __FUNCTION__, (unsigned long)serverConfig.count);
            // Close all open alerts first before applying SEB settings
            [self conditionallyOpenSEBConfig:serverConfig
                                    callback:self
                                    selector:@selector(handleMDMServerConfig:)];
            
        } else {
            DDLogVerbose(@"%s: Received same configuration as before from MDM server, ignoring it.", __FUNCTION__);
            _isReconfiguringToMDMConfig = NO;
        }
    }
    return readMDMConfig;
}


- (void) handleMDMServerConfig:(NSDictionary *)serverConfig
{
    _establishingSEBServerConnection = NO;
    [self.configFileController reconfigueClientWithMDMSettingsDict:serverConfig
                                                          callback:self
                                                          selector:@selector(storeNewSEBSettingsSuccessful:)];
}


- (void)resetReceivedServerConfig
{
    receivedServerConfig = nil;
}

- (BOOL)didNotReceiveSameServerConfig:(NSDictionary *)newReceivedServerConfig
{
    if (!receivedServerConfig) {
        receivedServerConfig = newReceivedServerConfig;
        return [self isReceivedServerConfigNew:newReceivedServerConfig];
    } else if ([receivedServerConfig isEqualToDictionary:newReceivedServerConfig]) {
        return NO;
    } else {
        return [self isReceivedServerConfigNew:newReceivedServerConfig];
    }
}

- (BOOL)isReceivedServerConfigNew:(NSDictionary *)newReceivedServerConfig
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences isReceivedServerConfigNew:newReceivedServerConfig]) {
        DDLogDebug(@"%s: Configuration received from MDM server is different from current settings, it will be used to reconfigure SEB.", __FUNCTION__);
        receivedServerConfig = newReceivedServerConfig;
        return YES;
    } else {
        DDLogVerbose(@"%s: Configuration received from MDM server is same as current settings, ignore it.", __FUNCTION__);
        return NO;
    }
}


- (NSString *)sebHashedPassword:(NSString *)password
{
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSString *hashedPassword;
    if (password.length > 0) {
        hashedPassword = [keychainManager generateSHAHashString:password];
        hashedPassword = [hashedPassword uppercaseString];
    } else {
        hashedPassword = @"";
    }
    return hashedPassword;
}

- (NSString *)placeholderStringForHashedPassword:(NSString *)hashedPassword
{
    NSString *placeholder;
    if (hashedPassword.length > 0) {
        placeholder = @"0000000000000000";
    } else {
        placeholder = @"";
    }
    return placeholder;
}


#pragma mark - Init main SEB UI

void run_on_ui_thread(dispatch_block_t block)
{
    if ([NSThread isMainThread])
        block();
    else
        dispatch_sync(dispatch_get_main_queue(), block);
}


- (void) initSEBUIWithCompletionBlock:(dispatch_block_t)completionBlock
{
    run_on_ui_thread(^{
        [self initSEBUIWithCompletionBlock:completionBlock temporary:NO];
    });
}

- (void) initSEBUIWithCompletionBlock:(dispatch_block_t)completionBlock temporary:(BOOL)temporary
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (!_showNavigationBarTemporarily && !_updateTemporaryNavigationBarVisibilty) {
        if (sebUIInitialized) {
            _appDelegate.sebUIController = nil;
        } else {
            sebUIInitialized = YES;
        }
        
        // Set up system
        
        // Set preventing Auto-Lock according to settings
        [UIApplication sharedApplication].idleTimerDisabled = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobilePreventAutoLock"];
        
        // Create browser user agent according to settings
        NSString *overrideUserAgent = [self.browserController customSEBUserAgent];
        // Register browser user agent for UIWebView
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:overrideUserAgent, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        
        // Update URL filter flags and rules
        [[SEBURLFilter sharedSEBURLFilter] updateFilterRules];
        // Update URL filter ignore rules
        [[SEBURLFilter sharedSEBURLFilter] updateIgnoreRuleList];
        
        _allowFind = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowFind"];
    }
    
    [self addBrowserToolBarWithOffset:0];

    if (!_showNavigationBarTemporarily) {
        
        // UI
        
        //// Initialize SEB Dock, commands section in the slider view and
        //// 3D Touch Home screen quick actions
        
        // Reset dynamic Home screen quick actions
        [UIApplication sharedApplication].shortcutItems = nil;
        
        // Reset settings view controller (so new settings are displayed)
        self.appSettingsViewController = nil;
        
        // If running with persisted (client) settings
        if (!NSUserDefaults.userDefaultsPrivate) {
            // Set the local flag for showing settings in-app, so this is also enabled
            // when opening temporary exam settings later
            self.appDelegate.showSettingsInApp = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showSettingsInApp"];
        }
        
        // Add scan QR code command/Home screen quick action/dock button
        // if SEB isn't running in exam mode (= no quit pw)
        BOOL examSession = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length > 0;
        BOOL allowReconfiguring = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_examSessionReconfigureAllow"];
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileAllowQRCodeConfig"] &&
            ((!examSession && !NSUserDefaults.userDefaultsPrivate) ||
             (!examSession && NSUserDefaults.userDefaultsPrivate && allowReconfiguring) ||
             (examSession && allowReconfiguring))) {
            
            // Add scan QR code Home screen quick action
            NSMutableArray *shortcutItems = [UIApplication sharedApplication].shortcutItems.mutableCopy;
            [shortcutItems addObject:[self scanQRCodeShortcutItem]];
            [UIApplication sharedApplication].shortcutItems = shortcutItems.copy;
        } else {
            [UIApplication sharedApplication].shortcutItems = nil;
        }
        
        /// If dock is enabled, register items to UIToolbar
        
        if (self.sebUIController.dockEnabled) {
            [self.navigationController setToolbarHidden:NO];
            
            // Check if we need to customize UIToolbar, because running on a device like iPhone X
            if (@available(iOS 11.0, *)) {
                UIWindow *window = UIApplication.sharedApplication.keyWindow;
                CGFloat bottomPadding = window.safeAreaInsets.bottom;
                if (bottomPadding != 0) {
                    
                    [self.navigationController.toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionBottom barMetrics:UIBarMetricsDefault];
                    [self.navigationController.toolbar setShadowImage:[UIImage new] forToolbarPosition:UIBarPositionBottom];
                    self.navigationController.toolbar.translucent = YES;
                    
                    if (self.bottomBackgroundView) {
                        [self.bottomBackgroundView removeFromSuperview];
                    }
                    self.bottomBackgroundView = [UIView new];
                    [self.bottomBackgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];
                    [self.view addSubview:self.bottomBackgroundView];
                    
                    if (self.toolBarView) {
                        [self.toolBarView removeFromSuperview];
                    }
                    self.toolBarView = [UIView new];
                    [self.toolBarView setTranslatesAutoresizingMaskIntoConstraints:NO];
                    [self.view addSubview:self.toolBarView];
                    
                    
                    NSDictionary *viewsDictionary = @{@"toolBarView" : self.toolBarView,
                                                      @"bottomBackgroundView" : self.bottomBackgroundView,
                                                      @"containerView" : self.containerView};
                    
                    NSMutableArray *constraints_H = [NSMutableArray new];
                    
                    // dock/toolbar leading constraint to safe area guide of superview
                    [constraints_H addObject:[NSLayoutConstraint constraintWithItem:self.toolBarView
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.containerView.safeAreaLayoutGuide
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0
                                                                           constant:0]];
                    
                    // dock/toolbar trailling constraint to safe area guide of superview
                    [constraints_H addObject:[NSLayoutConstraint constraintWithItem:self.toolBarView
                                                                          attribute:NSLayoutAttributeTrailing
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.containerView.safeAreaLayoutGuide
                                                                          attribute:NSLayoutAttributeTrailing
                                                                         multiplier:1.0
                                                                           constant:0]];
                    
                    NSMutableArray *constraints_V = [NSMutableArray new];
                    
                    // dock/toolbar height constraint depends on vertical size class (less high on iPhones in landscape)
                    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
                        UIEdgeInsets newSafeArea = UIEdgeInsetsMake(0, 0, 2, 0);
                        self.additionalSafeAreaInsets = newSafeArea;
                    } else {
                        UIEdgeInsets newSafeArea = UIEdgeInsetsMake(0, 0, -4, 0);
                        self.additionalSafeAreaInsets = newSafeArea;
                    }
                    CGFloat toolBarHeight = (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact &&
                                             self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular) ? 36 : 46;
                    
                    self.toolBarHeightConstraint = [NSLayoutConstraint constraintWithItem:self.toolBarView
                                                                                  attribute:NSLayoutAttributeHeight
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:nil
                                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                                 multiplier:1.0
                                                                                   constant:toolBarHeight];
                    [constraints_V addObject: self.toolBarHeightConstraint];
                    
                    // dock/toolbar top constraint to safe area guide bottom of superview
                    [constraints_V addObject:[NSLayoutConstraint constraintWithItem:self.toolBarView
                                                                          attribute:NSLayoutAttributeTop
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.containerView.safeAreaLayoutGuide
                                                                          attribute:NSLayoutAttributeBottom
                                                                         multiplier:1.0
                                                                           constant:0]];
                    
                    // dock/toolbar bottom constraint to background view top
                    [constraints_V addObject:[NSLayoutConstraint constraintWithItem:self.toolBarView
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.bottomBackgroundView
                                                                          attribute:NSLayoutAttributeTop
                                                                         multiplier:1.0
                                                                           constant:0]];
                    
                    // background view bottom constraint to superview bottom
                    [constraints_V addObject:[NSLayoutConstraint constraintWithItem:self.bottomBackgroundView
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.containerView
                                                                          attribute:NSLayoutAttributeBottom
                                                                         multiplier:1.0
                                                                           constant:0]];
                    
                    [self.view addConstraints:constraints_H];
                    [self.view addConstraints:constraints_V];
                    
                    SEBBackgroundTintStyle backgroundTintStyle = self.sebUIController.backgroundTintStyle;
                    
                    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
                        [self addBlurEffectStyle:UIBlurEffectStyleRegular
                                       toBarView:self.toolBarView
                             backgroundTintStyle:backgroundTintStyle];
                        
                    } else {
                        self.toolBarView.backgroundColor = [UIColor lightGrayColor];
                    }
                    self.toolBarView.hidden = false;
                    
                    NSArray *bottomBackgroundViewConstraints_H = [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-0-[bottomBackgroundView]-0-|"
                                                                                                         options: 0
                                                                                                         metrics: nil
                                                                                                           views: viewsDictionary];
                    
                    [self.view addConstraints:bottomBackgroundViewConstraints_H];
                    
                    if (UIAccessibilityIsReduceTransparencyEnabled()) {
                        self.bottomBackgroundView.backgroundColor = backgroundTintStyle == SEBBackgroundTintStyleDark ? [UIColor blackColor] : [UIColor whiteColor];
                    } else {
                        if (backgroundTintStyle == SEBBackgroundTintStyleDark) {
                            [self addBlurEffectStyle:UIBlurEffectStyleDark
                                           toBarView:self.bottomBackgroundView
                                 backgroundTintStyle:SEBBackgroundTintStyleNone];
                        } else {
                            [self addBlurEffectStyle:UIBlurEffectStyleExtraLight
                                           toBarView:self.bottomBackgroundView
                                 backgroundTintStyle:SEBBackgroundTintStyleNone];
                        }
                    }
                    BOOL sideSafeAreaInsets = false;
                    
                    UIWindow *window = UIApplication.sharedApplication.keyWindow;
                    CGFloat leftPadding = window.safeAreaInsets.left;
                    sideSafeAreaInsets = leftPadding != 0;
                    
                    self.bottomBackgroundView.hidden = sideSafeAreaInsets;
    #ifdef DEBUG
                    CGFloat bottomPadding = window.safeAreaInsets.bottom;
                    CGFloat bottomMargin = window.layoutMargins.bottom;
                    CGFloat bottomInset = self.view.superview.safeAreaInsets.bottom;
                    DDLogDebug(@"%f, %f, %f, ", bottomPadding, bottomMargin, bottomInset);
    #endif
                } else {
                    // Fix Toolbar tint issue in iOS 15.0 or later - it's transparent without the code below
                    if (@available(iOS 15, *)) {
                        UIToolbarAppearance *toolbarAppearance = [UIToolbarAppearance new];
                        [toolbarAppearance configureWithDefaultBackground];
                        UIColor *toolbarColor = [UIColor lightGrayColor];
                        toolbarColor = [toolbarColor colorWithAlphaComponent:0.5];
                        toolbarAppearance.backgroundColor = toolbarColor;
                        self.navigationController.toolbar.standardAppearance = toolbarAppearance;
                        self.navigationController.toolbar.scrollEdgeAppearance = toolbarAppearance;
                    }
                }
            }
            
            [self setToolbarItems:self.sebUIController.dockItems];
        } else {
            [self.navigationController setToolbarHidden:YES];
            
            if (self.bottomBackgroundView) {
                [self.bottomBackgroundView removeFromSuperview];
            }
            if (self.toolBarView) {
                [self.toolBarView removeFromSuperview];
            }
        }
    }
    
    // Show navigation bar if browser toolbar is enabled in settings and populate it with enabled controls
    if (self.sebUIController.browserToolbarEnabled) {
        [self.navigationController setNavigationBarHidden:NO];
    } else {
        [self.navigationController setNavigationBarHidden:YES];
    }
    
    [self adjustBars];
    
    if (_showNavigationBarTemporarily) {
        run_on_ui_thread(completionBlock);
    } else {
        if (!temporary) {
            if (@available(iOS 11.0, *)) {
                BOOL browserMediaCaptureCamera = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserMediaCaptureCamera"];
                BOOL browserMediaCaptureMicrophone = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserMediaCaptureMicrophone"];
                BOOL jitsiMeetEnable = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetEnable"];
                BOOL zoomEnable = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomEnable"];
                BOOL proctoringSession = jitsiMeetEnable || zoomEnable;
                BOOL webApplications = browserMediaCaptureCamera || browserMediaCaptureMicrophone;

                if ((zoomEnable && !ZoomProctoringSupported) || (jitsiMeetEnable && !JitsiMeetProctoringSupported)) {
                    NSString *notAvailableRequiredRemoteProctoringService = [NSString stringWithFormat:@"%@%@", zoomEnable && !ZoomProctoringSupported ? @"Zoom " : @"",
                                                         jitsiMeetEnable && !JitsiMeetProctoringSupported ? @"Jitsi Meet " : @""];
                    DDLogError(@"%@Remote proctoring not available", notAvailableRequiredRemoteProctoringService);
                    run_on_ui_thread(^{
                         
                        [self alertWithTitle:NSLocalizedString(@"Remote Proctoring Not Available", nil)
                                     message:[NSString stringWithFormat:NSLocalizedString(@"Current settings require %@ remote proctoring, which this %@ version doesn't support. Use the correct %@ version required by your exam organizer.", nil), notAvailableRequiredRemoteProctoringService, SEBShortAppName, SEBShortAppName]
                                action1Title:NSLocalizedString(@"OK", nil)
                              action1Handler:^ {
                            self.alertController = nil;
                            [self sessionQuitRestart:NO];
                        }
                                action2Title:nil
                              action2Handler:^{}];
                    });
                    return;
                }
                
                void (^conditionallyStartProctoring)(void) =
                ^{
                    // OK action handler
                    void (^startRemoteProctoringOK)(void) =
                    ^{
                        if (jitsiMeetEnable) {
                            [self openJitsiView];
                            [self.jitsiViewController openJitsiMeetWithSender:self];
                        }
                        run_on_ui_thread(completionBlock);
                    };
                    if (jitsiMeetEnable) {
                        // Check if previous SEB session already had proctoring active
                        if (self.previousSessionJitsiMeetEnabled) {
                            run_on_ui_thread(startRemoteProctoringOK);
                        } else {
                            [self alertWithTitle:NSLocalizedString(@"Remote Proctoring Session", nil)
                                         message:[NSString stringWithFormat:NSLocalizedString(@"The current session will be remote proctored using a live video and audio stream, which is sent to an individually configured server. Ask your examinator about their privacy policy. %@ itself doesn't connect to any centralized %@ proctoring server, your exam provider decides which proctoring service/server to use.", nil), SEBShortAppName, SEBShortAppName]
                                    action1Title:NSLocalizedString(@"OK", nil)
                                  action1Handler:^ {
                                run_on_ui_thread(startRemoteProctoringOK);
                            }
                                    action2Title:NSLocalizedString(@"Cancel", nil)
                                  action2Handler:^ {
                                self.alertController = nil;
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:@"requestQuit" object:self];
                            }];
                            return;
                        }
                    } else {
                        run_on_ui_thread(completionBlock);
                    }
                };
                
                if (browserMediaCaptureMicrophone ||
                    browserMediaCaptureCamera ||
                    zoomEnable ||
                    jitsiMeetEnable) {
                    AVAuthorizationStatus audioAuthorization = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
                    AVAuthorizationStatus videoAuthorization = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
                    if (!(audioAuthorization == AVAuthorizationStatusAuthorized &&
                          videoAuthorization == AVAuthorizationStatusAuthorized)) {
                        if (self.alertController) {
                            [self.alertController dismissViewControllerAnimated:NO completion:nil];
                        }
                        NSString *microphone = (proctoringSession || browserMediaCaptureMicrophone) && audioAuthorization != AVAuthorizationStatusAuthorized ? NSLocalizedString(@"microphone", nil) : @"";
                        NSString *camera = @"";
                        if ((proctoringSession || browserMediaCaptureCamera) && videoAuthorization != AVAuthorizationStatusAuthorized) {
                            camera = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"camera", nil), microphone.length > 0 ? NSLocalizedString(@" and ", nil) : @""];
                        }
                        NSString *permissionsRequiredFor = [NSString stringWithFormat:@"%@%@%@",
                                                            proctoringSession ? NSLocalizedString(@"remote proctoring", nil) : @"",
                                                            proctoringSession && webApplications ? NSLocalizedString(@" and ", nil) : @"",
                                                            webApplications ? NSLocalizedString(@"web applications", nil) : @""];
                        NSString *resolveSuggestion;
                        NSString *resolveSuggestion2;
                        NSString *message;
                        if (videoAuthorization == AVAuthorizationStatusDenied ||
                            audioAuthorization == AVAuthorizationStatusDenied) {
                            resolveSuggestion = NSLocalizedString(@"in Settings ", nil);
                            resolveSuggestion2 = NSLocalizedString(@"return to SEB and re", nil);
                        } else {
                            resolveSuggestion = @"";
                            resolveSuggestion2 = @"";
                        }
                        if (videoAuthorization == AVAuthorizationStatusRestricted ||
                            audioAuthorization == AVAuthorizationStatusRestricted) {
                            message = [NSString stringWithFormat:NSLocalizedString(@"For this session, %@%@ access for %@ is required. On this device, %@%@ access is restricted. Ask your IT support to provide you a device without these restrictions.", nil), camera, microphone, permissionsRequiredFor, camera, microphone];
                        } else {
                            message = [NSString stringWithFormat:NSLocalizedString(@"For this session, %@%@ access for %@ is required. You need to authorize %@%@ access %@before you can %@start the session.", nil), camera, microphone, permissionsRequiredFor, camera, microphone, resolveSuggestion, resolveSuggestion2];
                        }
                        
                        self.alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Permissions Required for %@", nil), permissionsRequiredFor.localizedCapitalizedString]
                                                                                   message:message
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                        
                        NSString *firstButtonTitle = (videoAuthorization == AVAuthorizationStatusDenied ||
                                                      audioAuthorization == AVAuthorizationStatusDenied) ? NSLocalizedString(@"Settings", nil) : NSLocalizedString(@"OK", nil);
                        [self.alertController addAction:[UIAlertAction actionWithTitle:firstButtonTitle
                                                                                 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            self.alertController = nil;
                            if (videoAuthorization == AVAuthorizationStatusDenied ||
                                audioAuthorization == AVAuthorizationStatusDenied) {
                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:@"requestQuit" object:self];
                                return;
                            }
                            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                                if (granted){
                                    DDLogInfo(@"Granted access to %@", AVMediaTypeVideo);
                                    
                                    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                                        if (granted){
                                            DDLogInfo(@"Granted access to %@", AVMediaTypeAudio);
                                            
                                            run_on_ui_thread(conditionallyStartProctoring);
                                            
                                        } else {
                                            DDLogError(@"Not granted access to %@", AVMediaTypeAudio);
                                            [[NSNotificationCenter defaultCenter]
                                             postNotificationName:@"requestQuit" object:self];
                                        }
                                    }];
                                    return;
                                    
                                } else {
                                    DDLogError(@"Not granted access to %@", AVMediaTypeVideo);
                                    [[NSNotificationCenter defaultCenter]
                                     postNotificationName:@"requestQuit" object:self];
                                }
                            }];
                            return;
                        }]];
                        
                        if (NSUserDefaults.userDefaultsPrivate) {
                            [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                                     style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                self.alertController = nil;
                                [[NSNotificationCenter defaultCenter]
                                 postNotificationName:@"requestQuit" object:self];
                            }]];
                        }
                        
                        [self.topMostController presentViewController:self.alertController animated:NO completion:nil];
                        return;
                    } else {
                        run_on_ui_thread(conditionallyStartProctoring);
                        return;
                    }
                } else {
                    self.previousSessionJitsiMeetEnabled = NO;
                }
            }
            run_on_ui_thread(completionBlock);
        }
    }
}


- (void) openCloseSliderForNewTab
{
    [self conditionallyRemoveToolbarWithCompletion:^{
        [self.sideMenuController showLeftViewAnimated:YES completionHandler:^{
            [self.sideMenuController hideLeftViewAnimated:YES completionHandler:^{
                [self showToolbarConditionally:YES withCompletion:nil];
            }];
        }];
    }];
}


#pragma mark - Toolbar (UINavigationBar)

- (void) addBrowserToolBarWithOffset:(CGFloat)navigationBarOffset
{
    // Draw background view for status bar if it is enabled
    if (_statusBarView) {
        [_statusBarView removeFromSuperview];
    }
    
    statusBarAppearance = [self.sebUIController statusBarAppearanceForDevice];
    
    _statusBarView = [UIView new];
    [_statusBarView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:_statusBarView];
    
    // Draw background view for navidation bar (SEB browser toolbar) if it is enabled
    // and if running on a device with extended display (like iPhone X)
    if (_navigationBarView) {
        [_navigationBarView removeFromSuperview];
    }
    _navigationBarView = [UIView new];
    [_navigationBarView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:_navigationBarView];
    
    NSDictionary *viewsDictionary = @{@"navigationBarView" : _navigationBarView,
                                      @"statusBarView" : _statusBarView,
                                      @"containerView" : _containerView};
    
    NSMutableArray *constraints_H = [NSMutableArray arrayWithArray:
                                     [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-0-[statusBarView]-0-|"
                                                                             options: 0
                                                                             metrics: nil
                                                                               views: viewsDictionary]];
    NSMutableArray *constraints_V = [NSMutableArray new];
    
    // browser tool bar top constraint to safe area guide bottom of superview
    [constraints_V addObject:[NSLayoutConstraint constraintWithItem:_statusBarView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:_containerView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0]];
    
    SEBBackgroundTintStyle backgroundTintStyle = self.sebUIController.backgroundTintStyle;
    
    CGFloat bottomPadding = 0;
    
    if (@available(iOS 11.0, *)) {
        
        // Check if we need to customize the navigation bar, when browser toolbar is enabled and
        // running on a device like iPhone X
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        bottomPadding = window.safeAreaInsets.bottom;
        
        if (bottomPadding != 0 && self.sebUIController.browserToolbarEnabled) {
            
            [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
            [self.navigationController.navigationBar setShadowImage:[UIImage new]];
            self.navigationController.navigationBar.translucent = YES;
            
            // browser toolbar (NavigationBar) leading constraint to safe area guide of superview
            _navigationBarLeftConstraintToSafeArea = [NSLayoutConstraint constraintWithItem:_navigationBarView
                                                                                  attribute:NSLayoutAttributeLeading
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:_containerView.safeAreaLayoutGuide
                                                                                  attribute:NSLayoutAttributeLeading
                                                                                 multiplier:1.0
                                                                                   constant:0];
            [constraints_H addObject: _navigationBarLeftConstraintToSafeArea];
            
            // browser toolbar (NavigationBar) trailling constraint to safe area guide of superview
            [constraints_H addObject:[NSLayoutConstraint constraintWithItem:_navigationBarView
                                                                  attribute:NSLayoutAttributeTrailing
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:_containerView.safeAreaLayoutGuide
                                                                  attribute:NSLayoutAttributeTrailing
                                                                 multiplier:1.0
                                                                   constant:0]];
            
            
            // browser toolbar (NavigationBar)  height constraint depends on vertical size class (less high on iPhones in landscape)
            CGFloat navigationBarHeight = (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact &&
                                           self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular) ? 32 : 46;
            _navigationBarHeightConstraint = [NSLayoutConstraint constraintWithItem:_navigationBarView
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:navigationBarHeight];
            [constraints_V addObject: _navigationBarHeightConstraint];
            
            // statusbar background view bottom constraint to navigation bar top
            _statusBarBottomConstraint = [NSLayoutConstraint constraintWithItem:_statusBarView
                                                                      attribute:NSLayoutAttributeBottom
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:_navigationBarView
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1.0
                                                                       constant:0];
            [constraints_V addObject:_statusBarBottomConstraint];
            
            // browser tool bar top constraint to safe area guide bottom of superview
            _navigationBarBottomConstraint = [NSLayoutConstraint constraintWithItem:_navigationBarView
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:_containerView.safeAreaLayoutGuide
                                                                          attribute:NSLayoutAttributeTop
                                                                         multiplier:1.0
                                                                           constant:navigationBarOffset];
            [constraints_V addObject: _navigationBarBottomConstraint];
            
            if (!UIAccessibilityIsReduceTransparencyEnabled()) {
                [self addBlurEffectStyle:UIBlurEffectStyleRegular
                               toBarView:_navigationBarView
                     backgroundTintStyle:backgroundTintStyle];
                
            } else {
                _navigationBarView.backgroundColor = [UIColor lightGrayColor];
            }
            _navigationBarView.hidden = false;
            
        } else {
            CGFloat statusBarBottomOffset = 0;
            if (self.sebUIController.browserToolbarEnabled) {
                _statusBarBottomConstraint = [NSLayoutConstraint constraintWithItem:_statusBarView
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:statusBarBottomOffset];
                [constraints_V addObject:_statusBarBottomConstraint];
                // Fix NavigationBar tint issue in iOS 15.0 or later - it's transparent without the code below
                if (@available(iOS 15, *)){
                    UINavigationBarAppearance *navigationBarAppearance = [UINavigationBarAppearance new];
                    [navigationBarAppearance configureWithDefaultBackground];
                    UIColor *toolbarColor = [UIColor lightGrayColor];
                    toolbarColor = [toolbarColor colorWithAlphaComponent:0.5];
                    navigationBarAppearance.backgroundColor = toolbarColor;
                    self.navigationController.navigationBar.standardAppearance = navigationBarAppearance;
                    self.navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance;
                }


            } else {
                _statusBarBottomConstraint = [NSLayoutConstraint constraintWithItem:_statusBarView
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:_containerView.safeAreaLayoutGuide
                                                                          attribute:NSLayoutAttributeTop
                                                                         multiplier:1.0
                                                                           constant:statusBarBottomOffset];
                [constraints_V addObject:_statusBarBottomConstraint];
            }
        }
        
        _statusBarView.hidden = NO;
        
#ifdef DEBUG
        CGFloat topPadding = window.safeAreaInsets.top;
        CGFloat topMargin = window.layoutMargins.top;
        CGFloat topInset = self.view.superview.safeAreaInsets.top;
        DDLogDebug(@"%f, %f, %f, ", topPadding, topMargin, topInset);
#endif
        
    } else {
        [constraints_V addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat: @"V:[statusBarView(==20)]"
                                                                                   options: 0
                                                                                   metrics: nil
                                                                                     views: viewsDictionary]];
        _statusBarView.hidden = (statusBarAppearance == mobileStatusBarAppearanceNone);
    }
    
    [self.view addConstraints:constraints_H];
    [self.view addConstraints:constraints_V];
    
    if (UIAccessibilityIsReduceTransparencyEnabled()) {
        _statusBarView.backgroundColor = (backgroundTintStyle == SEBBackgroundTintStyleDark ? [UIColor blackColor] : [UIColor whiteColor]);
    } else {
        if (backgroundTintStyle == SEBBackgroundTintStyleDark) {
            [self addBlurEffectStyle:UIBlurEffectStyleDark
                           toBarView:_statusBarView
                 backgroundTintStyle:SEBBackgroundTintStyleNone];
        } else {
            [self addBlurEffectStyle:UIBlurEffectStyleExtraLight
                           toBarView:_statusBarView
                 backgroundTintStyle:SEBBackgroundTintStyleNone];
        }
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
    
}

- (void) addBlurEffectStyle: (UIBlurEffectStyle)style
                  toBarView: (UIView *)barView
        backgroundTintStyle: (SEBBackgroundTintStyle)backgroundTintStyle
{
    barView.backgroundColor = [UIColor clearColor];
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:style];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = barView.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [barView addSubview:blurEffectView];
    
    if (backgroundTintStyle != SEBBackgroundTintStyleNone) {
        UIView *backgroundTintView = [UIView new];
        backgroundTintView.frame = barView.bounds;
        backgroundTintView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        backgroundTintView.backgroundColor = [UIColor lightGrayColor];
        backgroundTintView.alpha = (backgroundTintStyle == SEBBackgroundTintStyleLight ? 0.5 : 0.75);
        [barView addSubview:backgroundTintView];
    }
}


// Conditionally add back/forward buttons to navigation bar
- (void) showToolbarNavigation:(BOOL)navigationEnabled
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL show = (self.sebUIController.browserToolbarEnabled &&
                 navigationEnabled &&
                 !(self.sebUIController.dockEnabled &&
                   [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showNavigationButtons"]));
    
    if (show && !toolbarSearchBarActiveRemovedOtherItems) {
        // Add back/forward buttons to navigation bar
        toolbarBackButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SEBToolbarNavigateBackIcon"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(goBack)];
        toolbarBackButton.imageInsets = UIEdgeInsetsMake(navigationBarItemsOffset, 0, 0, 0);
        toolbarBackButton.accessibilityLabel = NSLocalizedString(@"Navigate Back", nil);
        toolbarBackButton.accessibilityHint = NSLocalizedString(@"Show the previous page", nil);
        
        toolbarForwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SEBToolbarNavigateForwardIcon"]
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goForward)];
        toolbarForwardButton.imageInsets = UIEdgeInsetsMake(navigationBarItemsOffset, 0, 0, 0);
        toolbarForwardButton.accessibilityLabel = NSLocalizedString(@"Navigate Forward", nil);
        toolbarForwardButton.accessibilityHint = NSLocalizedString(@"Show the next page", nil);
        
        self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:toolbarBackButton, toolbarForwardButton, nil];
        
    } else {
        self.navigationItem.leftBarButtonItems = nil;
    }
}


- (void) setToolbarTitle:(NSString *)title
{
    if (!toolbarSearchBarActiveRemovedOtherItems) { //&& self.sebUIController.browserToolbarEnabled ???
        self.navigationItem.title = title;
        toolbarSearchBarReplacedTitle = title;
        [self.navigationController.navigationBar setTitleVerticalPositionAdjustment:navigationBarItemsOffset
                                                                      forBarMetrics:UIBarMetricsDefault];
    } else {
        self.navigationItem.title = nil;
    }
}


- (void) restoreNavigationBarItemsConditionally:(BOOL)showConditionally
{
    BOOL isMainBrowserWebViewActive = [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow == 0;
    BOOL navigationAllowed = [self.browserController isNavigationAllowedMainWebView:isMainBrowserWebViewActive];
    [self showToolbarNavigation:navigationAllowed];
    [self setToolbarTitle:toolbarSearchBarReplacedTitle];
    BOOL showReload = [self.browserController isReloadAllowedMainWebView:isMainBrowserWebViewActive];
    [self updateRightNavigationItemsReloadEnabled:showReload];
}


- (void) updateRightNavigationItemsReloadEnabled:(BOOL)reloadEnabled
{
    NSMutableArray *rightToolbarItems = [NSMutableArray new];
    
    if (reloadEnabled && !toolbarSearchBarActiveRemovedOtherItems)  {
        if (self.sebUIController.browserToolbarEnabled &&
            !self.sebUIController.dockReloadButton) {
            // Add reload button to navigation bar
            toolbarReloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SEBToolbarReloadIcon"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(reload)];
            
            toolbarReloadButton.imageInsets = UIEdgeInsetsMake(navigationBarItemsOffset, 0, 0, 0);
            toolbarReloadButton.accessibilityLabel = NSLocalizedString(@"Reload", nil);
            toolbarReloadButton.accessibilityHint = NSLocalizedString(@"Reload this page", nil);
            
            [rightToolbarItems addObject:toolbarReloadButton];
        }
    }
    
    if (_allowFind)  {
        if (self.sebUIController.browserToolbarEnabled) {

            if (!toolbarSearchButton) {
                UIStackView *searchStackView = [[UIStackView alloc] init];
                searchStackView.translatesAutoresizingMaskIntoConstraints = NO;
                searchStackView.axis = UILayoutConstraintAxisHorizontal;
    //            searchStackView.alignment = UIStackViewAlignmentCenter;
                searchStackView.distribution = UIStackViewDistributionFill;
                searchStackView.spacing = 8;
                
                toolbarSearchButtonDone = [[UIButton alloc] init];
                toolbarSearchButtonDone.translatesAutoresizingMaskIntoConstraints = NO;
                [toolbarSearchButtonDone setTitle:NSLocalizedString(@"Done", nil) forState:UIControlStateNormal];
                [toolbarSearchButtonDone setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [toolbarSearchButtonDone.titleLabel setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightMedium]];
                [toolbarSearchButtonDone addTarget:self action:@selector(textSearchDone:) forControlEvents:UIControlEventTouchUpInside];
                
                UIView *searchBarView = [[UIView alloc] init];
                [self createSearchBarInView:searchBarView];
                
                toolbarSearchButtonPreviousResult = [[UIButton alloc] init];
                toolbarSearchButtonPreviousResult.translatesAutoresizingMaskIntoConstraints = NO;
                [toolbarSearchButtonPreviousResult setImage:[UIImage imageNamed:@"SEBToolbarSearchPreviousResultIcon"] forState:UIControlStateNormal];
                [toolbarSearchButtonPreviousResult setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [toolbarSearchButtonPreviousResult addTarget:self action:@selector(searchTextPrevious) forControlEvents:UIControlEventTouchUpInside];
                
                toolbarSearchButtonNextResult = [[UIButton alloc] init];
                toolbarSearchButtonNextResult.translatesAutoresizingMaskIntoConstraints = NO;
                [toolbarSearchButtonNextResult setImage:[UIImage imageNamed:@"SEBToolbarSearchNextResultIcon"] forState:UIControlStateNormal];
                [toolbarSearchButtonNextResult setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                [toolbarSearchButtonNextResult addTarget:self action:@selector(searchTextNext) forControlEvents:UIControlEventTouchUpInside];

                [searchStackView addArrangedSubview:toolbarSearchButtonDone];
                [searchStackView addArrangedSubview:searchBarView];
                [searchStackView addArrangedSubview:toolbarSearchButtonPreviousResult];
                [searchStackView addArrangedSubview:toolbarSearchButtonNextResult];
                NSDictionary *views = NSDictionaryOfVariableBindings(searchStackView);

                UIView *searchButtonView = [[UIView alloc] init];
                [searchButtonView addSubview:searchStackView];
                [searchButtonView addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[searchStackView]-|" options:0 metrics:nil views:views]];
                [searchButtonView addConstraints:
                 [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-(%f)-[searchStackView]-0-|", navigationBarItemsOffset*2] options:0 metrics:nil views:views]];
                
                toolbarSearchButton = [[UIBarButtonItem alloc] initWithCustomView:searchButtonView];
                toolbarSearchButton.imageInsets = UIEdgeInsetsMake(navigationBarItemsOffset, 0, 0, 0);
                toolbarSearchButton.accessibilityLabel = NSLocalizedString(@"Search Text", nil);
                toolbarSearchButton.accessibilityHint = NSLocalizedString(@"Search text on web pages", nil);
//            } else {
//                [self setSearchBarWidth:!_searchMatchFound];
            }
            [rightToolbarItems addObject:toolbarSearchButton];
        }
    }
    self.navigationItem.rightBarButtonItems = rightToolbarItems.copy;
}


- (void)createSearchBarInView:(UIView *)searchBarView
{
    textSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, SEBToolBarSearchBarIconWidth, 44)];
    textSearchBar.translatesAutoresizingMaskIntoConstraints = NO;
    textSearchBar.searchBarStyle = UISearchBarStyleMinimal;
    textSearchBar.returnKeyType = UIReturnKeyDone;
    textSearchBar.delegate = self;
    [searchBarView addSubview:textSearchBar];
    NSDictionary *views = NSDictionaryOfVariableBindings(searchBarView, textSearchBar);
    [searchBarView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[textSearchBar]-|" options:0 metrics:nil views:views]];
    searchBarTopConstraint = [NSLayoutConstraint constraintWithItem:textSearchBar
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:searchBarView
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0
                                                           constant:0];
    [searchBarView addConstraint:searchBarTopConstraint];
    [textSearchBar.superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[textSearchBar]-(0)-|" options:0 metrics:nil views:views]];
    searchBarWidthConstraint = nil;
    [self setSearchBarWidthIcon:!_searchMatchFound];
}

- (void)setSearchBarWidthIcon:(BOOL)iconWidth
{
    CGFloat width = iconWidth ? SEBToolBarSearchBarIconWidth : SEBToolBarSearchBarWidth;
    if (!searchBarWidthConstraint) {
        searchBarWidthConstraint = [NSLayoutConstraint constraintWithItem:textSearchBar
                                                                      attribute:NSLayoutAttributeWidth
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                                     multiplier:1.0
                                                                       constant:width];
        [textSearchBar.superview addConstraint:searchBarWidthConstraint];
    } else {
        searchBarWidthConstraint.constant = width;
    }
    BOOL iPhoneXLandscape = (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact &&
                             self.traitCollection.horizontalSizeClass != UIUserInterfaceSizeClassRegular);
    if (iconWidth) {
        if (@available(iOS 13.0, *)) {
            textSearchBar.searchTextField.backgroundColor = UIColor.clearColor;
        }
        searchBarTopConstraint.constant = navigationBarItemsOffset == -4 ? 6 : (iPhoneXLandscape ? -4 : 2);
        if (!_showNavigationBarTemporarily && toolbarSearchBarActiveRemovedOtherItems) {
            toolbarSearchBarActiveRemovedOtherItems = NO;
            [self restoreNavigationBarItemsConditionally:NO];
        }
    } else {
        if (@available(iOS 13.0, *)) {
            textSearchBar.searchTextField.backgroundColor = nil;
        }
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact && !toolbarSearchBarActiveRemovedOtherItems) {
            toolbarSearchBarActiveRemovedOtherItems = YES;
            self.navigationItem.leftBarButtonItems = nil;
            self.navigationItem.title = nil;
            self.navigationItem.rightBarButtonItem = nil;
            self.navigationItem.rightBarButtonItems = @[toolbarSearchButton];
        }
        searchBarTopConstraint.constant = navigationBarItemsOffset == -4 ? 0 : (iPhoneXLandscape ? 1 : -1); //(navigationBarItemsOffset+4) / (navigationBarItemsOffset+4); //(iPhoneXLandscape ? 1 : 2));
    }
}


// If no toolbar (UINavigationBar) is displayed, show it temporarilly
- (void) showToolbarConditionally:(BOOL)showConditionally withCompletion:(void (^)(void))completionHandler
{
    self.searchMatchFound = self.browserTabViewController.visibleWebViewController.searchMatchFound;
    NSString *currentSearchText = self.browserTabViewController.visibleWebViewController.searchText;

    if (!self.sebUIController.browserToolbarEnabled && (!showConditionally || currentSearchText.length > 0)) {
        self.sebUIController.browserToolbarEnabled = YES;
        self.showNavigationBarTemporarily = YES;
        toolbarSearchBarActiveRemovedOtherItems = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
        [self initSEBUIWithCompletionBlock:^{
            [self restoreNavigationBarItemsConditionally:showConditionally];
            [self updateSearchBarConditionally:showConditionally searchText:currentSearchText];
            if (completionHandler) {
                completionHandler();
            }
        } temporary:NO];
    } else {
        if (textSearchBar) {
            [self updateSearchBarConditionally:showConditionally searchText:currentSearchText];
        }
        if (completionHandler) {
            completionHandler();
        }
    }
}

- (void) updateSearchBarConditionally:(BOOL)showConditionally searchText:(NSString *)currentSearchText
{
    textSearchBar.text = currentSearchText;
    toolbarSearchButtonDone.hidden = !((showConditionally && toolbarSearchBarActiveRemovedOtherItems) || currentSearchText.length > 0);
    toolbarSearchButtonPreviousResult.hidden = !_searchMatchFound;
    toolbarSearchButtonNextResult.hidden = !_searchMatchFound;
    [self setSearchBarWidthIcon:currentSearchText.length == 0];
}


// If a temporary toolbar (UINavigationBar) was used, remove it
- (void) conditionallyRemoveToolbarWithCompletion:(void (^)(void))completionHandler
{
    if (_showNavigationBarTemporarily) {
        _showNavigationBarTemporarily = NO;
        [textSearchBar endEditing:YES];
        self.sebUIController.browserToolbarEnabled = NO;
        self.updateTemporaryNavigationBarVisibilty = YES;
        [self initSEBUIWithCompletionBlock:^{
            self.updateTemporaryNavigationBarVisibilty = NO;
            if (completionHandler) {
                completionHandler();
            }
        }];
    } else {
        [textSearchBar endEditing:YES];
        _searchMatchFound = NO;
        [self resetSearchBar];
        if (completionHandler) {
            completionHandler();
        }
    }
}


#pragma mark -  Reset and reconfigure SEB

- (void) resetSEB
{
    // Reset settings view controller (so new settings are displayed)
    self.appSettingsViewController = nil;
    
    [self.jitsiViewController closeJitsiMeetWithSender:self];
    if (@available(iOS 11, *)) {
        self.proctoringImageAnalyzer = nil;
    }
    
    if (textSearchBar.text.length > 0) {
        [self textSearchDone:self];
    }
    
    self.appDelegate.sebUIController = nil;
    
    self.viewDidLayoutSubviewsAlreadyCalled = NO;
    
    [self.browserTabViewController closeAllTabs];
    self.sessionRunning = false;
    [self.browserController resetBrowser];
}


- (void) conditionallyDownloadAndOpenSEBConfigFromURL:(NSURL *)url
{
    [self closeSettingsBeforeOpeningSEBConfig:url
                                     callback:self
                                     selector:@selector(saveOrDownloadSEBConfigFromURL:)];
}


- (void) openSEBConfigFromData:(NSData *)sebConfigData
{
    [self closeSettingsBeforeOpeningSEBConfig:sebConfigData
                                     callback:self
                                     selector:@selector(storeNewSEBSettingsFromData:)];
}


- (void) conditionallyOpenSEBConfigFromUniversalLink:(NSURL *)universalURL
{
    [self closeSettingsBeforeOpeningSEBConfig:universalURL
                                     callback:self.browserController
                                     selector:@selector(handleUniversalLink:)];
}


- (void) conditionallyOpenSEBConfigFromMDMServer:(NSDictionary *)serverConfig
{
    // Check if not running in exam mode
    if (!NSUserDefaults.userDefaultsPrivate && [self isReceivedServerConfigNew:serverConfig]) {
        _didReceiveMDMConfig = YES;
        [self resetReceivedServerConfig];
        
        if (_settingsOpen) {
            if (!_alertController && !self.appSettingsViewController.presentedViewController) {
                _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Received Config from MDM Server", nil)
                                                                        message:NSLocalizedString(@"Do you want to close Settings and apply this managed configuration?", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
                [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                     style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    self.alertController = nil;
                    DDLogDebug(@"%s: Received config while Settings are displayed: Closing Settings.", __FUNCTION__);
                    [self.appSettingsViewController dismissViewControllerAnimated:NO completion:^{
                        DDLogDebug(@"%s: Received config while Settings are displayed: Settings closed.", __FUNCTION__);
                        self.appSettingsViewController = nil;
                        self.settingsOpen = NO;
                        [self conditionallyReadMDMServerConfig:serverConfig];
                    }];
                }]];
                
                [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                     style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    self.alertController = nil;
                    self.didReceiveMDMConfig = NO;
                }]];
                
                [self.topMostController presentViewController:_alertController animated:NO completion:nil];
            } else {
                DDLogDebug(@"%s: Received config from MDM server while Settings and an alert or the Share Sheet were displayed: Ignoring MDM config.", __FUNCTION__);
            }
        } else {
            [self conditionallyReadMDMServerConfig:serverConfig];
        }
    }
}


// Close settings if they are open and then execute the callback selector
- (void) closeSettingsBeforeOpeningSEBConfig:(id)sebConfig
                                    callback:(id)callback
                                    selector:(SEL)selector
{
    DDLogDebug(@"closeSettingsBeforeOpeningSEBConfig: callback:%@ selector:%@", callback, NSStringFromSelector(selector));
    if (_settingsOpen) {
        if (_alertController) {
            DDLogDebug(@"%s: Received config while Settings and an alert are displayed: Closing alert first.", __FUNCTION__);
            [_alertController dismissViewControllerAnimated:NO completion:^{
                self.alertController = nil;
                [self closeSettingsBeforeOpeningSEBConfig:sebConfig callback:callback selector:selector];
            }];
            return;
        }
        // Close settings, but check if settings presented some alert or the share dialog first
        if (self.appSettingsViewController.presentedViewController) {
            DDLogDebug(@"%s: Received config while Settings and the Share Sheet are displayed: Closing Share Sheet first.", __FUNCTION__);
            [self.appSettingsViewController.presentedViewController dismissViewControllerAnimated:NO completion:^{
                DDLogDebug(@"%s: Received config while Settings and the Share Sheet are displayed: Share Sheet closed.", __FUNCTION__);
                if (self.appSettingsViewController) {
                    DDLogDebug(@"%s: Received config while Settings are displayed: Closing Settings.", __FUNCTION__);
                    [self.appSettingsViewController dismissViewControllerAnimated:NO completion:^{
                        DDLogDebug(@"%s: Received config while Settings are displayed: Settings closed.", __FUNCTION__);
                        self.appSettingsViewController = nil;
                        self.settingsOpen = false;
                        [self conditionallyOpenSEBConfig:sebConfig callback:callback selector:selector];
                    }];
                }
            }];
        } else if (self.appSettingsViewController) {
            DDLogDebug(@"%s: Received config while Settings are displayed: Closing Settings.", __FUNCTION__);
            [self.appSettingsViewController dismissViewControllerAnimated:NO completion:^{
                DDLogDebug(@"%s: Received config while Settings are displayed: Settings closed.", __FUNCTION__);
                self.appSettingsViewController = nil;
                self.settingsOpen = false;
                [self conditionallyOpenSEBConfig:sebConfig callback:callback selector:selector];
            }];
        } else {
            _settingsOpen = false;
            DDLogDebug(@"%s: Received config while Settings were apparently displayed, but in the meantime closed.", __FUNCTION__);
            [self conditionallyOpenSEBConfig:sebConfig callback:callback selector:selector];
        }
    } else {
        [self conditionallyOpenSEBConfig:sebConfig callback:callback selector:selector];
    }
}


// Prepare for downloading SEB config from URL
- (void) conditionallyOpenSEBConfig:(id)sebConfig
                           callback:(id)callback
                           selector:(SEL)selector
{
    if (_startSAMWAlertDisplayed) {
        // Dismiss the Activate SAM alert in case it still was visible
        [_alertController dismissViewControllerAnimated:NO completion:^{
            self.alertController = nil;
            self.startSAMWAlertDisplayed = false;
            self.singleAppModeActivated = false;
            // Set the paused SAM alert displayed flag, because if loading settings
            // fails or is canceled, we need to restart the kiosk mode
            self.pausedSAMAlertDisplayed = true;
            [self conditionallyOpenSEBConfig:sebConfig
                                    callback:callback
                                    selector:selector];
        }];
        return;
    } else if (_alertController) {
        [_alertController dismissViewControllerAnimated:YES completion:^{
            self.alertController = nil;
            [self conditionallyOpenSEBConfig:sebConfig
                                    callback:callback
                                    selector:selector];
        }];
        return;
    } else if (_initAssistantOpen) {
        // Check if the initialize settings assistant is open
        [self dismissViewControllerAnimated:YES completion:^{
            self.initAssistantOpen = false;
            // Reset the finished starting up flag, because if loading settings fails or is canceled,
            // we need to load the webpage
            self.finishedStartingUp = false;
            [self conditionallyOpenSEBConfig:sebConfig
                                    callback:callback
                                    selector:selector];
        }];
        return;
    } else if (_sebServerViewDisplayed) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.sebServerViewDisplayed = NO;
            self.establishingSEBServerConnection = NO;
            // Reset the finished starting up flag, because if loading settings fails or is canceled,
            // we need to load the webpage
            self.finishedStartingUp = NO;
            [self conditionallyOpenSEBConfig:sebConfig
                                    callback:callback
                                    selector:selector];
        }];
        return;
    } else if (!_didReceiveMDMConfig) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
            // Check if reconfiguring is allowed
            // If a quit password is set (= running in exam session),
            // then check if the reconfigure config file URL matches the setting
            // examSessionReconfigureConfigURL (where the wildcard character '*' can be used)
            NSURL *sebConfigURL = nil;
            if ([sebConfig isKindOfClass:[NSURL class]]) {
                sebConfigURL = (NSURL *)sebConfig;
            }
            // Check if SEB is in exam mode (= quit password is set) and exam is running,
            // but reconfiguring is allowed by setting and the reconfigure config URL matches the setting
            // or SEB isn't in exam mode, but is running with settings for starting an exam and the
            // reconfigure allow setting isn't set
            if (_sessionRunning && ![self.browserController isReconfiguringAllowedFromURL:sebConfigURL]) {
                // If yes, we don't download the .seb file
                _scannedQRCode = NO;
                return;
            }
        } else {
            _scannedQRCode = NO;
            return;
        }
    }
    // Reconfiguring is allowed: Invoke the callback to proceed
    IMP imp = [callback methodForSelector:selector];
    void (*func)(id, SEL, id) = (void *)imp;
    func(callback, selector, sebConfig);
}


- (SEBAbstractWebView *)openTempWebViewForDownloadingConfigFromURL:(NSURL *)url originalURL:originalURL
{
    if (!sebUIInitialized) {
        [self initSEBUIWithCompletionBlock:nil temporary:YES];
    }
    SEBAbstractWebView *tempWebView = [self.browserTabViewController openNewTabWithURL:url configuration:nil overrideSpellCheck:YES];
    tempWebView.originalURL = originalURL;
    
    return tempWebView;
}


- (void) saveOrDownloadSEBConfigFromURL:(NSURL *)url
{
    if (url.isFileURL) {
        run_on_ui_thread(^{
            NSError *error = nil;
            NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            [fileCoordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingWithoutChanges error:&error byAccessor:^(NSURL * _Nonnull newURL) {
                if (!error) {
                    NSError *fileReadingError = nil;
                    NSData *sebFileData;
                    if ([url startAccessingSecurityScopedResource]) {
                        DDLogDebug(@"%s: Reading a security scoped resource from URL %@", __FUNCTION__, url);
                        sebFileData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&fileReadingError];
                        [url stopAccessingSecurityScopedResource];
                    } else {
                        sebFileData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&fileReadingError];
                    }
                    if (fileReadingError || !sebFileData) {
                        DDLogError(@"Reading the file URL %@ contents failed with error %@", url, fileReadingError);
                        [self storeNewSEBSettingsSuccessful:error];
                    } else {
                        [self storeDownloadedData:sebFileData fromURL:url];
                    }
                }
                else {
                    DDLogError(@"Coordinating reading the file URL %@ contents failed with error %@", url, error);
                    [self storeNewSEBSettingsSuccessful:error];
                }
            }];
            
        });
        return;
    }
    [self.browserController openConfigFromSEBURL:url];
    return;
}


- (void) storeDownloadedData:(NSData *)sebFileData fromURL:(NSURL *)url
{
    DDLogDebug(@"%s fromURL: %@", __FUNCTION__, url);
    run_on_ui_thread(^{
        self->directlyDownloadedURL = url;
        [self.configFileController storeNewSEBSettings:sebFileData
                                            forEditing:NO
                                              callback:self
                                              selector:@selector(storeSEBSettingsDownloadedDirectlySuccessful:)];
    });
}


- (void) storeSEBSettingsDownloadedDirectlySuccessful:(NSError *)error
{
    if (error) {
        // Check if config couldn't be decrypted because of an unavailable identity certificate
        if (!(error.code == SEBErrorNoValidConfigData ||
              error.code == SEBErrorNoValidPrefixNoValidUnencryptedHeader)) {
            [self storeNewSEBSettingsSuccessful:error];
            return;
        }
        // Check if the URL is in an associated domain
        if ([self.browserController isAssociatedDomain:directlyDownloadedURL]) {
            [self.browserController handleUniversalLink:directlyDownloadedURL];
            return;
        } else {
            if (directlyDownloadedURL.scheme && [directlyDownloadedURL.scheme caseInsensitiveCompare:SEBSSecureProtocolScheme] == NSOrderedSame) {
                // If it's a sebs:// URL, we try to download it by https
                NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:directlyDownloadedURL resolvingAgainstBaseURL:NO];
                urlComponents.scheme = @"https";
                NSURL *httpsURL = urlComponents.URL;
                [self.browserController handleUniversalLink:httpsURL];
                return;
            } else {
                error = [self.configFileController errorCorruptedSettingsForUnderlyingError:error];
            }
        }
    } else {
        // Directly downloading SEB config was successfull
        
        // Store the URL of the .seb file as current config file name
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:directlyDownloadedURL];
    }
    [self storeNewSEBSettingsSuccessful:error];
}


// Decrypt, parse and store new SEB settings and report if it was successful
- (void) storeNewSEBSettingsFromData:(NSData *)sebData
{
    [self.configFileController storeNewSEBSettings:sebData
                                        forEditing:false
                                          callback:self
                                          selector:@selector(storeNewSEBSettingsSuccessful:)];
}


-(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
                   callback:(id)callback
                   selector:(SEL)selector
{
    [self.configFileController storeNewSEBSettings:sebData
                                        forEditing:forEditing
                            forceConfiguringClient:forceConfiguringClient
                                          callback:callback
                                          selector:selector];
}


// Decrypt, parse and store new SEB settings
// When forceConfiguringClient, Exam Settings have the same effect as Client Settings
// When showReconfigureAlert=false then don't show the reconfigured notification to the user
// Method with selector in the callback object is called after storing settings
// was successful or aborted
-(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
      showReconfiguredAlert:(BOOL)showReconfiguredAlert
                   callback:(id)callback
                   selector:(SEL)selector
{
    [self.configFileController storeNewSEBSettings:sebData
                                        forEditing:forEditing
                            forceConfiguringClient:forceConfiguringClient
                             showReconfiguredAlert:(BOOL)showReconfiguredAlert
                                          callback:callback
                                          selector:selector];
}


- (void) storeNewSEBSettingsSuccessful:(NSError *)error
{
    DDLogDebug(@"%s: Storing new SEB settings was %@successful", __FUNCTION__, error ? @"not " : @"");
    if (!error) {
        // If decrypting new settings was successfull
        receivedServerConfig = nil;
        self.scannedQRCode = NO;
        [[NSUserDefaults standardUserDefaults] setSecureString:self->startURLQueryParameter forKey:@"org_safeexambrowser_startURLQueryParameter"];
        // If we got a valid filename from the opened config file
        // we save this for displaing in InAppSettings
        NSString *newSettingsFilename = [[MyGlobals sharedMyGlobals] currentConfigURL].lastPathComponent.stringByDeletingPathExtension;
        if (newSettingsFilename.length > 0) {
            [[NSUserDefaults standardUserDefaults] setSecureString:newSettingsFilename forKey:@"configFileName"];
        }
        run_on_ui_thread(^{
            [self restartExamQuitting:NO];
            self.isReconfiguringToMDMConfig = NO;
            self.didReceiveMDMConfig = NO;
        });
        
    } else {

        self.establishingSEBServerConnection = NO;
        // If decrypting new settings wasn't successfull, we have to restore the path to the old settings
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:self->currentConfigPath];
        
        if (self.scannedQRCode) {
            DDLogError(@"%s: Reconfiguring from QR code config failed!", __FUNCTION__);
            self.scannedQRCode = NO;
            if (error.code == SEBErrorNoValidConfigData) {
                error = [NSError errorWithDomain:sebErrorDomain
                                            code:SEBErrorNoValidConfigData
                                        userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Scanning Config QR Code Failed", nil),
                                                   NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"No valid %@ config found.", nil), SEBShortAppName],
                                                   NSUnderlyingErrorKey : error}];
            }
            run_on_ui_thread(^{
                if (self.alertController) {
                    [self.alertController dismissViewControllerAnimated:NO completion:nil];
                }
                NSString *alertMessage = error.localizedRecoverySuggestion;
                alertMessage = [NSString stringWithFormat:@"%@%@%@", alertMessage ? alertMessage : @"", alertMessage ? @"\n" : @"", error.localizedFailureReason];
                self.alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                           message:alertMessage
                                                                    preferredStyle:UIAlertControllerStyleAlert];
                [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    self.alertController = nil;
                    if (!self.finishedStartingUp) {
                        // Continue starting up SEB without resetting settings
                        [self conditionallyStartKioskMode];
                    }
                }]];
                
                [self.topMostController presentViewController:self.alertController animated:NO completion:nil];
            });
            
        } else if (self.isReconfiguringToMDMConfig) {
            // When reconfiguring from MDM config fails, the SEB session needs to be restarted
            DDLogError(@"%s: Reconfiguring from MDM config failed, restarting SEB session.", __FUNCTION__);
            self.isReconfiguringToMDMConfig = NO;
            self.didReceiveMDMConfig = NO;
            run_on_ui_thread(^{
                [self restartExamQuitting:NO];
            });
            
        } else if (!self.finishedStartingUp || self.pausedSAMAlertDisplayed) {
            self.pausedSAMAlertDisplayed = NO;
            // Continue starting up SEB without resetting settings
            // but user interface might need to be re-initialized
            run_on_ui_thread(^{
                [self initSEBUIWithCompletionBlock:^{
                    [self conditionallyStartKioskMode];
                }];
            });
            
        } else {
            run_on_ui_thread(^{
                [self showReconfiguringAlertWithError:error];
            });
        }
    }
}


- (void) showAlertWithTitle:(NSString *)title
                    andText:(NSString *)informativeText
{
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _alertController = [UIAlertController  alertControllerWithTitle:title
                                                            message:informativeText
                                                     preferredStyle:UIAlertControllerStyleAlert];
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.alertController = nil;
    }]];
    
    [self.topMostController presentViewController:_alertController animated:NO completion:nil];
}


- (void) showReconfiguringAlertWithError:(NSError *)error
{
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:nil];
    }
    NSString *alertTitle = error.localizedDescription;
    NSString *alertMessage = error.localizedFailureReason;
    NSString *recoverySuggestion = error.localizedRecoverySuggestion;
    NSError *underlyingError = error.userInfo[NSUnderlyingErrorKey];
    NSString *underlyingErrorMessage = underlyingError.localizedFailureReason;
    if (recoverySuggestion) {
        alertMessage = recoverySuggestion;
    }
    if (underlyingErrorMessage) {
        alertMessage = [NSString stringWithFormat:@"%@ (%@)", alertMessage, underlyingErrorMessage];
    }
    
    _alertController = [UIAlertController alertControllerWithTitle:alertTitle
                                                           message:alertMessage
                                                    preferredStyle:UIAlertControllerStyleAlert];
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.alertController = nil;
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestQuit" object:self];
    }]];
    
    [self.topMostController presentViewController:_alertController animated:NO completion:nil];
}


- (void) showAlertWithError:(NSError *)error
{
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:nil];
    }
    NSString *alertMessage = error.localizedRecoverySuggestion;
    alertMessage = [NSString stringWithFormat:@"%@%@%@", alertMessage ? alertMessage : @"", alertMessage ? @"\n" : @"", error.localizedFailureReason ? error.localizedFailureReason : @""];
    _alertController = [UIAlertController  alertControllerWithTitle:error.localizedDescription
                                                            message:alertMessage
                                                     preferredStyle:UIAlertControllerStyleAlert];
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.alertController = nil;
    }]];
    
    [_topMostController presentViewController:_alertController animated:NO completion:nil];
}


#pragma mark - Start, restart and quit exam session

- (void) startExamWithFallback:(BOOL)fallback
{
    DDLogInfo(@"%s", __FUNCTION__);
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    if (@available(iOS 11.0, *)) {
        if (_secureMode &&
            UIScreen.mainScreen.isCaptured &&
            ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_enablePrintScreen"] ) {
            NSString *alertMessageiOSVersion = NSLocalizedString(@"The screen is being captured/shared. The exam cannot be started.", nil);
            if (_alertController) {
                [_alertController dismissViewControllerAnimated:NO completion:nil];
            }
            _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Capturing Screen Not Allowed", nil)
                                                                    message:alertMessageiOSVersion
                                                             preferredStyle:UIAlertControllerStyleAlert];
            
            [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", nil)
                                                                 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                self.alertController = nil;
                [self startExamWithFallback:fallback];
            }]];
            if (NSUserDefaults.userDefaultsPrivate) {
                [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                     style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    self.alertController = nil;
                    DDLogInfo(@"%s: Quitting session", __FUNCTION__);
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"requestQuit" object:self];
                }]];
            }
            [self.topMostController presentViewController:_alertController animated:NO completion:nil];
            return;
        }
    }
    
    if (_establishingSEBServerConnection == YES && !fallback) {
        _startingExamFromSEBServer = YES;
        [self.serverController startExamFromServer];
        return;
    }
    if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebMode"] == sebModeSebServer &&
        !fallback) {
        NSString *sebServerURLString = [preferences secureStringForKey:@"org_safeexambrowser_SEB_sebServerURL"];
        NSDictionary *sebServerConfiguration = [preferences secureDictionaryForKey:@"org_safeexambrowser_SEB_sebServerConfiguration"];
        _establishingSEBServerConnection = YES;
        NSError *error = [self.serverController connectToServer:[NSURL URLWithString:sebServerURLString] withConfiguration:sebServerConfiguration];
        if (!error) {
            // All necessary information for connecting to SEB Server was available in settings:
            // try to connect to SEB Server and wait for delegate method to be called with success/failure
            [self showSEBServerView];
            return;
        } else {
            // Cannot connect as some SEB Server settings/API endpoints are missing
            [self didFailWithError:error fatal:YES];
            return;
        }
    }
    NSString *startURLString = [[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    NSURL *startURL = [NSURL URLWithString:startURLString];
    if (startURLString.length == 0 ||
        (([startURL.host hasSuffix:@"safeexambrowser.org"] ||
          [startURL.host hasSuffix:SEBWebsiteShort]) &&
         [startURL.path hasSuffix:@"start"]))
    {
        // Start URL was set to the default value, show init assistant
        [self openInitAssistant];
    } else {
        _sessionRunning = YES;
        
        // Load all open web pages from the persistent store and re-create webview(s) for them
        // or if no persisted web pages are available, load the start URL
        [_browserTabViewController loadPersistedOpenWebPages];
        
        [self persistSecureExamStartURL:startURLString];
    }

}

// Persist start URL of a secure exam
- (void) persistSecureExamStartURL:(NSString *)startURLString
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length != 0) {
        currentStartURL = startURLString;
        [self.sebLockedViewController addLockedExam:currentStartURL];
    } else {
        currentStartURL = nil;
    }
}


- (void) quitExamConditionally
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowQuit"] == YES) {
        // if quitting SEB is allowed
        if (hashedQuitPassword.length > 0) {
            // if quit password is set, then restrict quitting
            // Allow up to 5 attempts for entering decoding password
            attempts = 5;
            NSString *enterPasswordString = NSLocalizedString(@"Enter quit password:", nil);
            
            // Ask the user to enter the quit password and proceed to the callback method after this happend
            [self.configFileController promptPasswordWithMessageText:enterPasswordString
                                                               title:NSLocalizedString(@"Quit Session",nil)
                                                            callback:self
                                                            selector:@selector(enteredQuitPassword:)];
        } else {
            // if no quit password is required, then just confirm quitting
            [self sessionQuitRestartIgnoringQuitPW:NO];
        }
    }
}


- (void)quitLinkDetected:(NSNotification *)notification
{
    DDLogInfo(@"Quit Link invoked");
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL restart = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_quitURLRestart"];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_quitURLConfirm"]) {
        [self sessionQuitRestartIgnoringQuitPW:restart];
    } else {
        [self sessionQuitRestart:restart];
    }
}


// Quit or restart session, but ask user for confirmation first
- (void) sessionQuitRestartIgnoringQuitPW:(BOOL)restart
{
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:nil];
    }
    DDLogDebug(@"%s Displaying confirm quit alert", __FUNCTION__);
    _alertController = [UIAlertController  alertControllerWithTitle:restart ? NSLocalizedString(@"Restart Session", nil) : NSLocalizedString(@"Quit Session", nil)
                                                            message:restart ? NSLocalizedString(@"Are you sure you want to restart this session?", nil) : NSLocalizedString(@"Are you sure you want to quit this session?", nil)
                                                     preferredStyle:UIAlertControllerStyleAlert];
    [_alertController addAction:[UIAlertAction actionWithTitle:restart ? NSLocalizedString(@"Restart", nil) : NSLocalizedString(@"Quit", nil)
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.alertController = nil;
        DDLogInfo(@"Confirmed to %@ %@", restart ? @"restart" : @"quit", !self.quittingSession ? SEBShortAppName : @"exam session");
        [self sessionQuitRestart:restart];
    }]];
    
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        self.alertController = nil;
        DDLogDebug(@"%s canceled quit alert", __FUNCTION__);
        [self.sideMenuController hideLeftViewAnimated];
    }]];
    
    [self.topMostController presentViewController:_alertController animated:NO completion:nil];
}


// Quit or restart session without asking for confirmation
- (void) sessionQuitRestart:(BOOL)restart
{
    //    BOOL quittingClientConfig = ![NSUserDefaults userDefaultsPrivate];
    _openingSettings = NO;
    _scannedQRCode = NO;    
    _resettingSettings = NO;
    
    [self conditionallyCloseSEBServerConnectionWithRestart:restart completion:^(BOOL restart) {
        [self didCloseSEBServerConnectionRestart:restart];
    }];
}


- (void) conditionallyCloseSEBServerConnectionWithRestart:(BOOL)restart completion:(void (^)(BOOL))completion
{
    if (self.startingExamFromSEBServer || self.establishingSEBServerConnection) {
        self.establishingSEBServerConnection = NO;
        self.startingExamFromSEBServer = NO;
        [self.serverController loginToExamAbortedWithCompletion:completion];
    } else if (self.sebServerConnectionEstablished) {
        self.sebServerConnectionEstablished = NO;
        [self.serverController quitSessionWithRestart:restart completion:^(BOOL restart) {
            completion(restart);
        }];
    } else {
        completion(restart);
    }
}


- (BOOL) quittingSession
{
    BOOL examSession = NSUserDefaults.userDefaultsPrivate;
    return examSession;
}


- (void) quitSEBOrSession
{
    DDLogDebug(@"[SEBViewController quitSEBOrSession]");
    BOOL quittingExamSession = self.quittingSession;
    if (quittingExamSession) {
        // Switch to system's (persisted) UserDefaults
        [NSUserDefaults setUserDefaultsPrivate:NO];
        // Reset settings password and config key hash for settings,
        // as we're returning from exam to client settings
        [[NSUserDefaults standardUserDefaults] setSecureString:@"" forKey:@"org_safeexambrowser_settingsPassword"];
        _configFileKeyHash = nil;
    }
    [self restartExamQuitting:YES
         quittingClientConfig:!quittingExamSession
             pasteboardString:nil];
}


- (void) enteredQuitPassword:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
        [self.sideMenuController hideLeftViewAnimated];
        return;
    }
    
    // Get quit password hash from current client settings
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    hashedQuitPassword = [hashedQuitPassword uppercaseString];
    
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSString *hashedPassword = [keychainManager generateSHAHashString:password];
    hashedPassword = [hashedPassword uppercaseString];
    
    attempts--;
    
    if ([hashedPassword caseInsensitiveCompare:hashedQuitPassword] != NSOrderedSame) {
        // wrong password entered, are there still attempts left?
        if (attempts > 0) {
            // Let the user try it again
            NSString *enterPasswordString = NSLocalizedString(@"Wrong password! Try again to enter the quit password:",nil);
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.configFileController promptPasswordWithMessageText:enterPasswordString
                                                               title:NSLocalizedString(@"Quit Session",nil)
                                                            callback:self
                                                            selector:@selector(enteredQuitPassword:)];
            return;
            
        } else {
            // Wrong password entered in the last allowed attempts: Stop quitting the exam
            DDLogError(@"%s: Couldn't quit the session: The correct quit password wasn't entered.", __FUNCTION__);
            
            NSString *title = NSLocalizedString(@"Cannot Quit Session", nil);
            NSString *informativeText = NSLocalizedString(@"If you don't enter the correct quit password, then you cannot quit the session.", nil);
            [self.configFileController showAlertWithTitle:title andText:informativeText];
            [self.sideMenuController hideLeftViewAnimated];
            return;
        }
        
    } else {
        // The correct quit password was entered
        [self quitExam];
    }
}


- (void) quitExam
{
    run_on_ui_thread(^{
        self->receivedServerConfig = nil;
        [self.browserController quitSession];
        [self sessionQuitRestart:NO];
    });
}


// Close all tabs, reset browser and reset kiosk mode
// before re-initializing SEB with new settings and restarting exam
- (void) restartExamQuitting:(BOOL)quitting
{
    BOOL quittingClientConfig = ![NSUserDefaults userDefaultsPrivate];
    [self restartExamQuitting:quitting
         quittingClientConfig:quittingClientConfig
             pasteboardString:nil];
}

- (void) restartExamQuitting:(BOOL)quitting
        quittingClientConfig:(BOOL)quittingClientConfig
            pasteboardString:(NSString *)pasteboardString
{
    _isReconfiguringToMDMConfig = NO;
    // Close the left slider view first if it was open
    if (self.sideMenuController.isLeftViewHidden == NO) {
        [self.sideMenuController hideLeftViewAnimated:YES completionHandler:^{
            [self restartExamQuitting:quitting
                 quittingClientConfig:quittingClientConfig
                     pasteboardString:pasteboardString];
        }];
        return;
    }
    DDLogInfo(@"---------- RESTARTING SEB SESSION -------------");
    
    run_on_ui_thread(^{
        
        [self initializeLogger];
        
        // Close browser tabs and reset browser session
        [self resetSEB];
        
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        
        if (self.batteryController && !self.establishingSEBServerConnection) {
            [self.batteryController stopMonitoringBattery];
            self.batteryController = nil;
        }
        
        // We only might need to switch off kiosk mode if it was active in previous settings
        if (self.secureMode) {
            
            // Remove this exam from the list of running exams,
            // otherwise it would be locked next time it is started again
            [self.sebLockedViewController removeLockedExam:self->currentStartURL];
            
            // Clear Pasteboard if we don't have to copy the hash keys into it
            if (pasteboardString) {
                pasteboard.string = pasteboardString;
            } else {
                pasteboard.items = @[];
            }
            
            // Get new setting for running SEB in secure mode
            BOOL oldSecureMode = self.secureMode;
            
            // Get new setting for ASAM/AAC enabled
            BOOL oldEnableASAM = self.enableASAM;
            
            if (quittingClientConfig) {
                self.previousSessionJitsiMeetEnabled = NO;
            }
            // Update kiosk flags according to current settings
            [self updateKioskSettingFlags];
            
            // If there are one or more difference(s) in active kiosk mode
            // compared to the new kiosk mode settings, also considering:
            // when we're running in SAM mode, it's not relevant if settings for ASAM differ
            // when we're running in ASAM mode, it's not relevant if settings for SAM differ
            // we deactivate the current kiosk mode
            if ((quittingClientConfig && oldSecureMode) ||
                oldSecureMode != self.secureMode ||
                (!self.singleAppModeActivated && (self.ASAMActive != self.enableASAM)) ||
                (!self.ASAMActive && (self.singleAppModeActivated != self.allowSAM))) {
                
                // If SAM is active, we display the alert for waiting for it to be switched off
                if (self.singleAppModeActivated) {
                    if (self.sebLockedViewController) {
                        self.sebLockedViewController.resignActiveLogString = [[NSAttributedString alloc] initWithString:@""];
                    }
                    if (self.alertController) {
                        [self.alertController dismissViewControllerAnimated:NO completion:nil];
                    }
                    
                    self.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Waiting For Single App Mode to End", nil)
                                                                                message:NSLocalizedString(@"You will be able to work with other apps after Single App Mode is switched off by your administrator.", nil)
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                    self.endSAMWAlertDisplayed = true;
                    [self.topMostController presentViewController:self.alertController animated:NO completion:nil];
                    return;
                }
                
                // If ASAM is active, we stop it now and display the alert for restarting session
                if (oldEnableASAM) {
                    if (self.ASAMActive) {
                        DDLogInfo(@"Requesting to exit Autonomous Single App Mode");
                        UIAccessibilityRequestGuidedAccessSession(false, ^(BOOL didSucceed) {
                            if (didSucceed) {
                                DDLogInfo(@"%s: Exited Autonomous Single App Mode", __FUNCTION__);
                                self.ASAMActive = false;
                            }
                            else {
                                DDLogError(@"%s: Failed to exit Autonomous Single App Mode", __FUNCTION__);
                            }
                            [self restartExamASAM:quitting && self.secureMode];
                        });
                    } else {
                        [self restartExamASAM:quitting && self.secureMode];
                    }
                } else {
                    // When no kiosk mode was active, then we can just restart SEB with the start URL in local client settings
                    [self initSEBUIWithCompletionBlock:^{
                        [self conditionallyStartKioskMode];
                    }];
                }
            } else {
                // If kiosk mode settings stay same, we just initialize SEB with new settings and start the exam
                [self initSEBUIWithCompletionBlock:^{
                    [self startExamWithFallback:NO];
                }];
            }
            
        } else {
            // When no kiosk mode was active, then we can just restart SEB
            // and switch kiosk mode on conditionally according to new settings
            if (pasteboardString) {
                pasteboard.string = pasteboardString;
            }
            [self initSEBUIWithCompletionBlock:^{
                [self conditionallyStartKioskMode];
            }];
        }
    });
}


- (void) restartExamASAM:(BOOL)quittingASAMtoSAM
{
    if (quittingASAMtoSAM) {
        if (_alertController) {
            [_alertController dismissViewControllerAnimated:NO completion:nil];
        }
        _clientConfigSecureModePaused = YES;
        _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Exam Session Finished", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Your device is now unlocked, you can exit %@ using the Home button/indicator.%@Use the button below to start another exam session and lock the device again.", nil), SEBShortAppName, @"\n\n"]
                                                         preferredStyle:UIAlertControllerStyleAlert];
        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Start Another Exam", nil)
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.alertController = nil;
            [self initSEBUIWithCompletionBlock:^{
                [self conditionallyStartKioskMode];
                self.clientConfigSecureModePaused = NO;
            }];
        }]];
        [self.topMostController presentViewController:_alertController animated:NO completion:nil];
    } else {
        [self initSEBUIWithCompletionBlock:^{
            [self conditionallyStartKioskMode];
        }];
    }
}

// Inform the callback method if decrypting, parsing and storing new settings was successful or not
- (void) quitExamWithCallback:(id)callback selector:(SEL)selector
{
    BOOL success = true;
    IMP imp = [callback methodForSelector:selector];
    void (*func)(id, SEL, BOOL) = (void *)imp;
    func(callback, selector, success);
}


#pragma mark - Connecting to SEB Server

- (void) showSEBServerView
{
    if (_sebServerViewDisplayed == NO) {
        if (_alertController) {
            [_alertController dismissViewControllerAnimated:NO completion:^{
                self.alertController = nil;
                [self showSEBServerView];
            }];
            return;
        }
        [self.sideMenuController hideLeftViewAnimated];
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _sebServerViewController = [storyboard instantiateViewControllerWithIdentifier:@"SEBServerView"];
    _sebServerViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    _sebServerViewController.sebViewController = self;
    if (@available(iOS 13.0, *)) {
        _sebServerViewController.modalInPopover = YES;
    }
    
    _sebServerViewController.sebServerController = self.serverController.sebServerController;
    self.serverController.sebServerController.serverControllerUIDelegate = self.sebServerViewController;

    [self.topMostController presentViewController:_sebServerViewController animated:YES completion:^{
        self.sebServerViewDisplayed = YES;
        [self.sebServerViewController updateExamList];
    }];
}


- (void) startBatteryMonitoringWithDelegate:(id)delegate
{
    [self.batteryController addDelegate:delegate];
    [self.batteryController startMonitoringBattery];
}


- (void) didSelectExamWithExamId:(NSString *)examId url:(NSString *)url
{
    [self.serverController examSelected:examId url:url];
}


- (void) loginToExam:(NSString *)url
{
    NSURL *examURL = [NSURL URLWithString:url];
    [_browserTabViewController openNewTabWithURL:examURL configuration:nil];
    [self persistSecureExamStartURL:url];
    self.browserController.sebServerExamStartURL = examURL;
    _sessionRunning = YES;
}


- (void) didEstablishSEBServerConnection
{
    _establishingSEBServerConnection = NO;
    _startingExamFromSEBServer = NO;
    _sebServerConnectionEstablished = YES;
}


- (void) didFailWithError:(NSError *)error fatal:(BOOL)fatal
{
    BOOL optionallyAttemptFallback = fatal && !_startingExamFromSEBServer && !_sebServerConnectionEstablished;
    DDLogError(@"SEB Server connection did fail with error: %@%@", [error.userInfo objectForKey:NSDebugDescriptionErrorKey], optionallyAttemptFallback ? @", optionally attempt failback" : @" This is a non-fatal error, no fallback necessary.");
    if (optionallyAttemptFallback) {
        if (!self.serverController.fallbackEnabled) {
            DDLogError(@"Aborting SEB Server connection as fallback isn't enabled");
            [self closeServerViewWithCompletion:^{
                NSString *informativeText = [NSString stringWithFormat:@"%@\n%@", [error.userInfo objectForKey:NSLocalizedDescriptionKey], [error.userInfo objectForKey:NSLocalizedRecoverySuggestionErrorKey]];
                [self alertWithTitle:NSLocalizedString(@"Connection to SEB Server Failed", nil)
                             message:informativeText
                        action1Title:NSLocalizedString(@"Retry", nil)
                      action1Handler:^(void){
                    self.establishingSEBServerConnection = NO;
                    [self startExamWithFallback:NO];
                }
                        action2Title:NSLocalizedString(@"Quit Session", nil)
                      action2Handler:^(void){
                    [self closeServerViewAndRestart:self];
                }];
                return;
            }];
            return;
        } else {
            [self closeServerViewWithCompletion:^{
                DDLogInfo(@"Server connection failed: Querying user if fallback should be used");
                NSString *informativeText = [NSString stringWithFormat:@"%@\n%@", [error.userInfo objectForKey:NSLocalizedDescriptionKey], [error.userInfo objectForKey:NSLocalizedRecoverySuggestionErrorKey]];
                [self alertWithTitle:NSLocalizedString(@"Connection to SEB Server Failed: Fallback Option", nil)
                             message:informativeText
                      preferredStyle:UIAlertControllerStyleAlert
                        action1Title:NSLocalizedString(@"Retry", nil)
                        action1Style:UIAlertActionStyleDefault
                      action1Handler:^(void){
                    DDLogInfo(@"User selected Retry option");
                    self.establishingSEBServerConnection = NO;
                    [self startExamWithFallback:NO];
                }
                 
                        action2Title:NSLocalizedString(@"Fallback", nil)
                        action2Style:UIAlertActionStyleDefault
                      action2Handler:^(void){
                    DDLogInfo(@"User selected Fallback option");
                    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
                    NSString *sebServerFallbackPasswordHash = [preferences secureStringForKey:@"org_safeexambrowser_SEB_sebServerFallbackPasswordHash"];
                    // If SEB Server fallback password is set, then restrict fallback
                    if (sebServerFallbackPasswordHash.length != 0) {
                        DDLogInfo(@"%s Displaying SEB Server fallback password alert", __FUNCTION__);
                        [self promptPasswordWithMessageText:NSLocalizedString(@"Enter SEB Server fallback password:", nil) title:NSLocalizedString(@"SEB Server Fallback Password Required", nil) completion:^(NSString* password) {
                            
                            SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
                            if (password.length > 0 && [sebServerFallbackPasswordHash caseInsensitiveCompare:[keychainManager generateSHAHashString:password]] == NSOrderedSame) {
                                DDLogInfo(@"Correct SEB Server fallback password entered");
                                DDLogInfo(@"Open startURL as SEB Server fallback");
                                self.establishingSEBServerConnection = NO;
                                [self startExamWithFallback:YES];
                                
                            } else {
                                DDLogInfo(@"%@ SEB Server fallback password entered", password.length > 0 ? @"Wrong" : @"No");
                                
                                self.alertController = [UIAlertController  alertControllerWithTitle:password.length > 0 ? NSLocalizedString(@"Wrong SEB Server Fallback Password entered", nil) : NSLocalizedString(@"No SEB Server Fallback Password entered", nil)
                                                                                            message:NSLocalizedString(@"If you don't enter the correct SEB Server fallback password, then you cannot invoke fallback.", nil)
                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                                [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                    self.alertController = nil;
                                    [self didFailWithError:error fatal:fatal];
                                    
                                }]];
                                [self.topMostController presentViewController:self.alertController animated:NO completion:nil];
                            }
                        }];
                    } else {
                        DDLogInfo(@"Open startURL as SEB Server fallback");
                        self.establishingSEBServerConnection = NO;
                        [self startExamWithFallback:YES];
                    }
                }
                 
                        action3Title:NSLocalizedString(@"Quit Session", nil)
                        action3Style:UIAlertActionStyleDestructive
                      action3Handler:^(void){
                    DDLogInfo(@"User selected Quit option");
                    [self closeServerViewAndRestart:self];
                }];
                return;
            }];
        }
    }
}


// Ask the user to enter a password using the message text and then call the callback selector with the password as parameter
- (void) promptPasswordWithMessageText:(NSString *)messageText title:(NSString *)titleString completion:(void (^)(NSString * _Nullable ))completion;
{
    if (self.alertController) {
        [self.alertController dismissViewControllerAnimated:NO completion:nil];
    }
    self.alertController = [UIAlertController alertControllerWithTitle:titleString
                                                               message:messageText
                                                        preferredStyle:UIAlertControllerStyleAlert];
    
    [self.alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
        textField.placeholder = NSLocalizedString(@"Password", nil);
        textField.secureTextEntry = YES;
    }];
    
    [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *password = self.alertController.textFields.firstObject.text;
        self.alertController = nil;
        completion(password);
    }]];
    
    [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                             style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        self.alertController = nil;
        completion(nil);
    }]];
    
    [self.topMostController presentViewController:self.alertController animated:NO completion:nil];
}


- (void) closeServerViewAndRestart:(id)sender
{
    [self closeServerViewWithCompletion:^{
        [self sessionQuitRestart:NO];
    }];
}


- (void) closeServerViewWithCompletion:(void (^)(void))completion
{
    if (_sebServerViewController) {
        [_sebServerViewController dismissViewControllerAnimated:YES completion:^{
            self.sebServerViewDisplayed = NO;
            self.sebServerViewController = nil;
            completion();
        }];
    } else {
        completion();
    }
}


- (void) serverSessionQuitRestart:(BOOL)restart
{
    self.establishingSEBServerConnection = NO;
    if (_sebServerViewDisplayed) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.sebServerViewDisplayed = NO;
            [self serverSessionQuitRestart:restart];
        }];
        return;
    } else if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:^{
            self.alertController = nil;
            [self serverSessionQuitRestart:restart];
        }];
        return;
    }
    // Check if settings are currently open
    if (_settingsOpen) {
        // Close settings, but check if settings presented the share dialog first
        DDLogInfo(@"SEB settings should be reset, but the Settings view was open, it will be closed first");
        if (self.appSettingsViewController.presentedViewController) {
            [self.appSettingsViewController.presentedViewController dismissViewControllerAnimated:NO completion:^{
                [self serverSessionQuitRestart:restart];
            }];
            return;
        } else if (self.appSettingsViewController) {
            [self.appSettingsViewController dismissViewControllerAnimated:YES completion:^{
                self.appSettingsViewController = nil;
                self.settingsOpen = NO;
                [self serverSessionQuitRestart:restart];
            }];
            return;
        }
    }
    [self sessionQuitRestart:restart];
}


- (void) didCloseSEBServerConnectionRestart:(BOOL)restart
{
    _establishingSEBServerConnection = NO;
    if (restart) {
        [self restartExamQuitting:YES];
    } else {
        [self quitSEBOrSession];
    }
}


- (void) confirmNotificationWithAttributes:(NSDictionary *)attributes
{
    DDLogDebug(@"%s: attributes: %@", __FUNCTION__, attributes);
    NSString *notificationType = attributes[@"type"];
    NSNumber *notificationIDNumber = [attributes objectForKey:@"id"];
    
    //    if ([notificationType isEqualToString:@"raisehand"]) {
    //        if (_raiseHandRaised && raiseHandUID == notificationIDNumber.integerValue) {
    //            [self toggleRaiseHandLoweredByServer:YES];
    //        }
    //    }
    
    if ([notificationType isEqualToString:@"lockscreen"]) {
        if (self.sebServerPendingLockscreenEvents.count > 0) {
#ifdef DEBUG
            DDLogDebug(@"sebServerPendingLockscreenEvents: %@", self.sebServerPendingLockscreenEvents);
#endif
            NSInteger notificationID = notificationIDNumber.integerValue;
            for (NSUInteger index = 0 ; index < self.sebServerPendingLockscreenEvents.count ; ++index) {
                if (self.sebServerPendingLockscreenEvents[index].integerValue == notificationID) {
                    [self.sebServerPendingLockscreenEvents removeObjectAtIndex:index];
                }
            }
#ifdef DEBUG
            DDLogDebug(@"sebServerPendingLockscreenEvents after removing notificationID %@: %@", notificationIDNumber, self.sebServerPendingLockscreenEvents);
#endif
            if (self.sebServerPendingLockscreenEvents.count == 0) {
                DDLogInfo(@"No pending lock screen events, closing lockdown windows invoked by SEB Server");
                [self correctPasswordEntered];
            }
        }
    }
}


- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url
{
    if (_establishingSEBServerConnection) {
        [self.serverController shouldStartLoadFormSubmittedURL:url];
    }
}


- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies forURL:(NSURL *)url
{
    if (_establishingSEBServerConnection) {
        [self.serverController examineCookies:cookies forURL:url];
    }
}


- (void) examineHeaders:(NSDictionary<NSString *,NSString *>*)headerFields forURL:(NSURL *)url
{
    if (_establishingSEBServerConnection) {
        [self.serverController examineHeaders:headerFields forURL:url];
    }
}


#pragma mark - Kiosk mode

// Called when the Single App Mode (SAM) status changes
- (void) singleAppModeStatusChanged
{
    if (_finishedStartingUp && _singleAppModeActivated && _ASAMActive == false) {
        
        // Is the exam already running?
        if (_sessionRunning) {
            
            // Dismiss the Activate SAM alert in case it still was visible
            if (_alertController) {
                [_alertController dismissViewControllerAnimated:NO completion:^{
                    self.alertController = nil;
                    self.startSAMWAlertDisplayed = false;
                    [self singleAppModeStatusChanged];
                }];
                return;
            }
            
            // Exam running: Check if SAM is switched off
            if (UIAccessibilityIsGuidedAccessEnabled() == false) {
                
                /// SAM is off
                
                // Lock the exam down
                
                // Save current time for information about when Guided Access was switched off
                _didResignActiveTime = [NSDate date];
                
                DDLogError(@"Single App Mode switched off!");
                
                // If there wasn't a lockdown covering view openend yet, initialize it
                if (!_sebLocked) {
                    [self openLockdownWindows];
                }
                [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Single App Mode switched off!", nil)] withTime:_didResignActiveTime repeated:NO];
                
            } else {
                
                /// SAM is on again
                
                // Add log string
                _didBecomeActiveTime = [NSDate date];
                
                DDLogDebug(@"Single App Mode was switched on again.");
                
                [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Single App Mode was switched on again.", nil)] withTime:_didBecomeActiveTime repeated:NO];
                
                // Close lock windows only if the correct quit/restart password was entered already
                if (_unlockPasswordEntered) {
                    _unlockPasswordEntered = false;
                    [self.sebLockedViewController shouldCloseLockdownWindows];
                }
            }
        } else {
            
            /// Exam is not yet running
            
            // If Single App Mode is switched on
            if (UIAccessibilityIsGuidedAccessEnabled() == true) {
                
                // Dismiss the Activate SAM alert in case it still was visible
                [_alertController dismissViewControllerAnimated:NO completion:^{
                    self.alertController = nil;
                    self.startSAMWAlertDisplayed = false;
                }];
                
                // Proceed to exam
                [self startExamWithFallback:NO];
                
            } else {
                
                // Dismiss the Waiting for SAM to end alert
                if (_endSAMWAlertDisplayed) {
                    [_alertController dismissViewControllerAnimated:NO completion:^{
                        self.alertController = nil;
                        self.endSAMWAlertDisplayed = false;
                        self.singleAppModeActivated = false;
                        [self showRestartSingleAppMode];
                    }];
                    return;
                }
                
                // if Single App Mode is off
                if (!_startSAMWAlertDisplayed && !_pausedSAMAlertDisplayed) {
                    [self showRestartSingleAppMode];
                }
            }
        }
    }
}


- (void) conditionallyStartKioskMode
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL allowEditingConfig = [preferences boolForKey:@"allowEditingConfig"];
    BOOL initiateResetConfig = [preferences boolForKey:@"initiateResetConfig"];
    DDLogDebug(@"%s: allowEditingConfig: %d, initiateResetConfig: %d", __FUNCTION__, allowEditingConfig, initiateResetConfig);
    if (!_openingSettings && !_resettingSettings && !_settingsOpen) {
        // Check if running on iOS 11.x earlier than 11.2.5
        if (![self allowediOSVersion]) {
            DDLogError(@"%s Running on not allowed iOS 11.x version earlier than 11.2.5, don't start kiosk mode", __FUNCTION__);
            return;
        }
        
        // Check if running on beta iOS
        NSUInteger allowBetaiOSVersion = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowiOSBetaVersionNumber"];
        NSUInteger currentOSMajorVersion = NSProcessInfo.processInfo.operatingSystemVersion.majorVersion;
        if (currentOSMajorVersion > currentStableMajoriOSVersion && //first check if we're running on a beta at all
            (allowBetaiOSVersion == iOSBetaVersionNone || //if no beta allowed, abort
             allowBetaiOSVersion != currentOSMajorVersion))
        { //if allowed, version has to match current iOS
            DDLogError(@"%s Show alert 'Running on New iOS Version Not Allowed'", __FUNCTION__);
            
            if (_alertController) {
                [_alertController dismissViewControllerAnimated:NO completion:nil];
            }
            
            _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Running on New iOS Version Not Allowed", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Currently it isn't allowed to run %@ on the iOS version installed on this device.", nil), SEBShortAppName]
                                                             preferredStyle:UIAlertControllerStyleAlert];
            if (NSUserDefaults.userDefaultsPrivate) {
                [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                     style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    self.alertController = nil;
                    DDLogInfo(@"%s: Quitting session", __FUNCTION__);
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"requestQuit" object:self];
                }]];
            }
            [self.topMostController presentViewController:_alertController animated:NO completion:nil];
            return;
        }
        
        // Check if running on older iOS version than the one allowed in settings
        NSUInteger allowiOSVersionMajor = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowiOSVersionNumberMajor"];
        NSUInteger allowiOSVersionMinor = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowiOSVersionNumberMinor"];
        NSUInteger allowiOSVersionPatch = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowiOSVersionNumberPatch"];
        NSUInteger currentOSMinorVersion = NSProcessInfo.processInfo.operatingSystemVersion.minorVersion;
        NSUInteger currentOSPatchVersion = NSProcessInfo.processInfo.operatingSystemVersion.patchVersion;
        if (currentOSMajorVersion < allowiOSVersionMajor ||
            (currentOSMajorVersion == allowiOSVersionMajor &&
             currentOSMinorVersion < allowiOSVersionMinor) ||
            (currentOSMajorVersion == allowiOSVersionMajor &&
             currentOSMinorVersion == allowiOSVersionMinor &&
             currentOSPatchVersion < allowiOSVersionPatch) ||
            (currentOSMajorVersion == 11 &&
             currentOSMinorVersion < 2) ||
            (currentOSMajorVersion == 11 &&
             currentOSMinorVersion == 2 &&
             currentOSPatchVersion < 5)
            )
        {
            NSString *allowediOSVersionMinorString = @"";
            NSString *allowediOSVersionPatchString = @"";
            // Test special case: iOS 11 - 11.2.2 is never allowed
            if (allowiOSVersionMajor == 11 && allowiOSVersionMinor <= 2 && allowiOSVersionPatch < 5) {
                allowediOSVersionMinorString = @".2";
                allowediOSVersionPatchString = @".5";
            } else {
                if (allowiOSVersionPatch > 0 || allowiOSVersionMinor > 0) {
                    allowediOSVersionMinorString = [NSString stringWithFormat:@".%lu", (unsigned long)allowiOSVersionMinor];
                }
                if (allowiOSVersionPatch > 0) {
                    allowediOSVersionPatchString = [NSString stringWithFormat:@".%lu", (unsigned long)allowiOSVersionPatch];
                }
            }
            NSString *alertMessageiOSVersion = [NSString stringWithFormat:@"%@%@%lu%@%@",
                                                SEBShortAppName,
                                                NSLocalizedString(@" settings don't allow to run on the iOS version installed on this device. Update to latest iOS version or use another device with at least iOS ", nil),
                                                (unsigned long)allowiOSVersionMajor,
                                                allowediOSVersionMinorString,
                                                allowediOSVersionPatchString];
            DDLogError(@"%s %@", __FUNCTION__, alertMessageiOSVersion);
            
            if (_alertController) {
                [_alertController dismissViewControllerAnimated:NO completion:nil];
            }
            _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Running on Current iOS Version Not Allowed", nil)
                                                                    message:alertMessageiOSVersion
                                                             preferredStyle:UIAlertControllerStyleAlert];
            if (NSUserDefaults.userDefaultsPrivate) {
                [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                     style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    self.alertController = nil;
                    DDLogInfo(@"%s: Quitting session", __FUNCTION__);
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"requestQuit" object:self];
                }]];
            }
            [self.topMostController presentViewController:_alertController animated:NO completion:nil];
            return;
        }
        
        // Update kiosk flags according to current settings
        [self updateKioskSettingFlags];
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetEnable"]) {
            AVAuthorizationStatus audioAuthorization = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
            AVAuthorizationStatus videoAuthorization = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            if (!(audioAuthorization == AVAuthorizationStatusAuthorized &&
                  videoAuthorization == AVAuthorizationStatusAuthorized)) {
                NSString *microphone = audioAuthorization != AVAuthorizationStatusAuthorized ? NSLocalizedString(@"microphone", nil) : @"";
                NSString *camera = @"";
                if (videoAuthorization != AVAuthorizationStatusAuthorized) {
                    camera = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"camera", nil), microphone.length > 0 ? NSLocalizedString(@" and ", nil) : @""];
                }
                DDLogError(@"Enabled remote proctoring require %@%@ permissions, which are not granted currently. Aborting starting this session.", camera, microphone);
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"requestQuit" object:self];
            }
        }
        _finishedStartingUp = true;
        
        if (_secureMode) {
            // Clear Pasteboard
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.items = @[];
        }
        
        // If AAC/ASAM is enabled and SAM not allowed, we have to check if SAM or Guided Access is
        // already active and deny starting a secured exam until Guided Access is switched off
        if (_enableASAM && !_allowSAM) {
            DDLogInfo(@"%s _enableASAM && !_allowSAM: If AAC/ASAM is enabled and SAM not allowed, we have to check if SAM or Guided Access is already active and deny starting a secured exam until Guided Access is switched off.", __FUNCTION__);
            // Get time of app launch
            dispatch_time_t dispatchTimeAppLaunched = _appDelegate.dispatchTimeAppLaunched;
            if (dispatchTimeAppLaunched != 0) {
                // If not yet waiting for at least 2 seconds after app launch
                if (!assureSAMNotActiveWaiting) {
                    assureSAMNotActiveWaiting = YES;
                    // Wait at least 2 seconds after app launch
                    DDLogInfo(@"%s Wait at least 2 seconds after app launch", __FUNCTION__);
                    dispatch_after(dispatch_time(dispatchTimeAppLaunched, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        self.appDelegate.dispatchTimeAppLaunched = 0;
                        // Is SAM/Guided Access (or ASAM because of previous crash) active?
                        [self assureSAMNotActive];
                        self->assureSAMNotActiveWaiting = NO;
                    });
                } else {
                    DDLogInfo(@"%s Already waiting 2 seconds since app start before checking if SAM or Guided Access is already active.", __FUNCTION__);
                }
            } else {
                DDLogInfo(@"%s App is already running at least 2 seconds", __FUNCTION__);
                [self assureSAMNotActive];
            }
        } else {
            _appDelegate.dispatchTimeAppLaunched = 0;
            [self conditionallyStartASAM];
        }
    }
}


- (void) updateKioskSettingFlags
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // First check if a quit password is set = run SEB in secure mode
    _secureMode = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length > 0;
    
    // Is ASAM/AAC enabled in current settings?
    _enableASAM = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileEnableASAM"];
    
    // Is using classic Single App Mode (SAM) allowed in current settings?
    _allowSAM = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileAllowSingleAppMode"];
    
    DDLogInfo(@"%s: secureMode = %d, enableASAM = %d, allowSAM: %d", __FUNCTION__, _secureMode, _enableASAM, _allowSAM);
}

// Is SAM/Guided Access (or ASAM because of previous crash) active?
- (void) assureSAMNotActive
{
    _SAMActive = UIAccessibilityIsGuidedAccessEnabled();
    DDLogWarn(@"%s: Single App Mode is %@active at least 2 seconds after app launch.", __FUNCTION__, _SAMActive ? @"" : @"not ");
    if (_SAMActive) {
        DDLogInfo(@"SAM or Guided Access (or AAC/ASAM because of previous crash) is already active: refuse starting a secured exam until SAM/Guided Access is switched off");
        // SAM or Guided Access (or AAC/ASAM because of previous crash) is already active:
        // refuse starting a secured exam until SAM/Guided Access is switched off
        ASAMActiveChecked = NO;
        [self requestDisablingSAM];
    } else {
        [self conditionallyStartASAM];
    }
}


// SAM or Guided Access (or ASAM because of previous crash) is already active:
// refuse starting a secured exam until SAM/Guided Access is switched off
- (void) requestDisablingSAM
{
    DDLogInfo(@"%s SAM/Guided Access (or AAC/ASAM because of previous crash) is still active, in needs to be (manually) disabled", __FUNCTION__);
    
    // Is SAM/Guided Access (or ASAM because of previous crash) still active?
    _SAMActive = UIAccessibilityIsGuidedAccessEnabled();
    if (_SAMActive) {
        DDLogDebug(@"%s _SAMActive", __FUNCTION__);
        
        if (!ASAMActiveChecked) {
            DDLogDebug(@"%s !ASAMActiveChecked", __FUNCTION__);
            
            // First try to switch off ASAM in case it was active because of a previously happend crash
            UIAccessibilityRequestGuidedAccessSession(NO, ^(BOOL didSucceed) {
                DDLogDebug(@"%s UIAccessibilityRequestGuidedAccessSession(NO, ^(BOOL didSucceed = %d)", __FUNCTION__, didSucceed);
                
                self->ASAMActiveChecked = YES;
                if (didSucceed) {
                    DDLogInfo(@"%s: Exited Autonomous Single App Mode", __FUNCTION__);
                    [self requestDisablingSAM];
                }
                else {
                    DDLogError(@"%s: Failed to exit Autonomous Single App Mode, SAM/Guided Access must be active", __FUNCTION__);
                    //                _ASAMActive = false;
                    [self requestDisablingSAM];
                }
            });
        } else {
            DDLogInfo(@"%s If ASAM is enabled and SAM not allowed, we have to deny starting a secured exam until Guided Access/SAM is switched off", __FUNCTION__);
            // If ASAM is enabled and SAM not allowed, we have to deny starting a secured exam
            // until Guided Access/SAM is switched off
            if (_enableASAM && !_allowSAM) {
                DDLogDebug(@"%s _enableASAM && !_allowSAM", __FUNCTION__);
                
                // Warn user that SAM/Guided Access must first be switched off
                if (_alertController) {
                    [_alertController dismissViewControllerAnimated:NO completion:nil];
                }
                _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Single App Mode/Guided Access Not Allowed", nil)
                                                                        message:NSLocalizedString(@"Current settings require that Guided Access or an MDM/Apple Configurator invoked Single App Mode is first switched off before the exam can be started.", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
                [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", nil)
                                                                     style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    self.alertController = nil;
                    // Check again if a single app mode is still active
                    [self requestDisablingSAM];
                }]];
                
                [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                     style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    self.alertController = nil;
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:@"requestQuit" object:self];
                }]];
                
                [self.topMostController presentViewController:_alertController animated:NO completion:nil];
            }
        }
    } else {
        DDLogInfo(@"%s SAM/Guided Access (or ASAM because of previous crash) is no longer active: start ASAM", __FUNCTION__);
        // SAM/Guided Access (or ASAM because of previous crash) is no longer active: start ASAM
        [self conditionallyStartASAM];
    }
}


- (void) conditionallyStartASAM
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    // First check if a quit password is set = run SEB in secure mode
    if (!_secureMode) {
        DDLogInfo(@"%s Secure mode isn't required in settings (no quit pw), proceed to open start URL", __FUNCTION__);
        // If secure mode isn't required, we can proceed to opening start URL
        [self startExamWithFallback:NO];
    } else if (!_ASAMActive) {
        // Secure mode required, find out which kiosk mode to use
        // Is ASAM enabled in settings?
        if (_enableASAM) {
            DDLogInfo(@"%s Requesting AAC/Autonomous Single App Mode", __FUNCTION__);
            _ASAMActive = true;
            UIAccessibilityRequestGuidedAccessSession(YES, ^(BOOL didSucceed) {
                DDLogDebug(@"%s UIAccessibilityRequestGuidedAccessSession(YES, ^(BOOL didSucceed = %d)", __FUNCTION__, didSucceed);
                if (didSucceed) {
                    if (UIAccessibilityIsGuidedAccessEnabled() == NO) {
                        DDLogError(@"%s: Switching AAC/Autonomous Single App Mode on returned didSucceed, even though AAC isn't actually active! Inform user that the device needs to be restarted", __FUNCTION__);
                        // This is an issue happening on older iOS versions:
                        // the device needs to be restarted
                        if (self.alertController) {
                            [self.alertController dismissViewControllerAnimated:NO completion:nil];
                        }
                        self.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Failed to Start Single App Mode", nil)
                                                                                    message:NSLocalizedString(@"Single App Mode could not be started. You need to restart your device (iPad with Face ID: Press and hold either volume button and the top button until the power off slider appears. iPad with Home button: Press and hold the top button until the power off slider appears). Update iOS/iPadOS to the latest version to prevent this issue.", nil)
                                                                             preferredStyle:UIAlertControllerStyleAlert];
                        
                        [self.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                                 style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                            self.alertController = nil;
                            DDLogInfo(@"%s User confirmed OK, quit current session.", __FUNCTION__);
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:@"requestQuit" object:self];
                        }]];
                        
                        [self.topMostController presentViewController:self.alertController animated:NO completion:nil];
                        return;
                    }
                    DDLogInfo(@"%s: Entered AAC/Autonomous Single App Mode, proceed to open start URL", __FUNCTION__);
                    [self startExamWithFallback:NO];
                } else {
                    DDLogError(@"%s: Failed to enter AAC/Autonomous Single App Mode", __FUNCTION__);
                    self.ASAMActive = NO;
                    [self showNoKioskModeAvailable];
                }
            });
        } else {
            [self showStartSingleAppMode];
        }
    }
}


- (void) stopAutonomousSingleAppMode
{
    DDLogInfo(@"%s: Requesting to exit AAC/Autonomous Single App Mode", __FUNCTION__);
    UIAccessibilityRequestGuidedAccessSession(NO, ^(BOOL didSucceed) {
        if (didSucceed) {
            DDLogInfo(@"%s: Exited AAC/Autonomous Single App Mode", __FUNCTION__);
            self.ASAMActive = false;
        }
        else {
            DDLogError(@"%s: Failed to exit AAC/Autonomous Single App Mode", __FUNCTION__);
        }
    });
}


- (void) showStartSingleAppMode
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (_allowSAM) {
        // SAM is allowed
        _singleAppModeActivated = true;
        if (UIAccessibilityIsGuidedAccessEnabled() == false) {
            if (_alertController) {
                [_alertController dismissViewControllerAnimated:NO completion:nil];
            }
            _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Waiting for Single App Mode", nil)
                                                                    message:NSLocalizedString(@"Current Settings require Single App Mode to be active to proceed.", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
            _startSAMWAlertDisplayed = true;
            [self.topMostController presentViewController:_alertController animated:NO completion:nil];
        }
    } else {
        // SAM isn't allowed: SEB refuses to start the exam
        [self showNoKioskModeAvailable];
    }
}


// No kiosk mode available: SEB refuses to start the exam
- (void) showNoKioskModeAvailable
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:^{
            self.alertController = nil;
            [self showNoKioskModeAvailable];
        }];
        return;
    }
    if ([[self.topMostController.presentedViewController superclass] isKindOfClass:[UIAlertController superclass]]) {
        [self.topMostController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    _noSAMAlertDisplayed = YES;
    DDLogError(@"%s Showing alert 'No Kiosk Mode Available – Neither Automatic Assessment Configuration nor (Autonomous) Single App Mode are available on this device or activated in settings. Ask your exam support for an eligible exam environment. Sometimes also restarting the device might help.'", __FUNCTION__);
    _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"No Kiosk Mode Available", nil)
                                                            message:NSLocalizedString(@"Neither Automatic Assessment Configuration nor (Autonomous) Single App Mode are available on this device or activated in settings. Ask your exam support for an eligible exam environment. Sometimes also restarting the device might help.", nil)
                                                     preferredStyle:UIAlertControllerStyleAlert];
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", nil)
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        DDLogDebug(@"%s: User selected Retry", __FUNCTION__);
        self.alertController = nil;
        self.noSAMAlertDisplayed = false;
        [self conditionallyStartKioskMode];
    }]];
    
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        DDLogDebug(@"%s: User selected Cancel", __FUNCTION__);
        self.alertController = nil;
        self.noSAMAlertDisplayed = NO;
        self.establishingSEBServerConnection = NO;
        // We didn't actually succeed to switch a kiosk mode on
        // self.secureMode = false;
        // removed because in this case the alert "Exam Session Finished" should be displayed if these are client settings
        DDLogInfo(@"%s: Quitting session", __FUNCTION__);
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestQuit" object:self];
    }]];
    [self.topMostController presentViewController:_alertController animated:NO completion:nil];
}


- (void) showRestartSingleAppMode {
    DDLogDebug(@"%s", __FUNCTION__);
    
    // First check if a quit password is set
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    if (hashedQuitPassword.length > 0) {
        // A quit password is set in current settings: Ask user to restart Guided Access
        // If Guided Access isn't already on, show alert to switch it on again
        DDLogInfo(@"%s: A quit password is set in current settings: Ask user to restart Guided Access. If Guided Access isn't already on, show alert to switch it on again", __FUNCTION__);
        if (UIAccessibilityIsGuidedAccessEnabled() == NO) {
            if (_alertController) {
                [_alertController dismissViewControllerAnimated:NO completion:nil];
            }
            DDLogInfo(@"%s: SAM/Guided Access is not on, showing alert 'Waiting for Single App Mode – Single App Mode needs to be reactivated before %@ can continue.'", __FUNCTION__, SEBShortAppName);
            
            _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Waiting for Single App Mode", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Single App Mode needs to be reactivated before %@ can continue.", nil), SEBShortAppName]
                                                             preferredStyle:UIAlertControllerStyleAlert];
            _singleAppModeActivated = YES;
            _startSAMWAlertDisplayed = YES;
            [self.topMostController presentViewController:_alertController animated:NO completion:nil];
        }
    } else {
        // If no quit password is defined, then we can initialize SEB with new settings
        // quit and restart the exam / reload the start page directly
        DDLogInfo(@"%s: No quit password is defined, then we can initialize SEB with new settings, quit and restart the exam / reload the start page directly", __FUNCTION__);
        DDLogDebug(@"%s: [self initSEBWithCompletionBlock:^{[self startExam]; }];", __FUNCTION__);
        [self initSEBUIWithCompletionBlock:^{
            [self startExamWithFallback:NO];
        }];
    }
}


#pragma mark - Lockdown windows

- (void) conditionallyOpenStartExamLockdownWindows:(NSString *)examURLString
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if ([self.sebLockedViewController isStartingLockedExam:examURLString]) {
        if (_secureMode) {
            DDLogError(@"Re-opening an exam which was locked before");
            [self openLockdownWindows];
            [self.sebLockedViewController setLockdownAlertTitle: nil
                                                        Message:NSLocalizedString(@"SEB is locked because Single App Mode was switched off during the exam or the device was restarted. Unlock SEB with the quit password, which usually exam supervision/support knows.", nil)];
            // Add log string for entering a locked exam
            [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Re-opening an exam which was locked before", nil)] withTime:[NSDate date] repeated: NO];
        } else {
            DDLogWarn(@"Re-opening an exam which was locked before, but now doesn't have a quit password set, therefore doesn't run in secure mode.");
            // Add log string for entering a previously locked exam
            [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Re-opening an exam which was locked before, but now doesn't have a quit password set, therefore doesn't run in secure mode.", nil)] withTime:[NSDate date] repeated:NO];
            [self.sebLockedViewController removeLockedExam:[[NSUserDefaults standardUserDefaults] secureStringForKey:examURLString]];
        }
    }
}


- (void) conditionallyOpenScreenCaptureLockdownWindows
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (@available(iOS 11.0, *)) {
        if (UIScreen.mainScreen.isCaptured &&
            _secureMode &&
            _sessionRunning &&
            !_clientConfigSecureModePaused &&
            ![[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrintScreen"]) {
            DDLogError(@"Screen is being captured while in secure mode!");
            [self openLockdownWindows];
            [self.sebLockedViewController setLockdownAlertTitle: NSLocalizedString(@"Screen is Being Captured/Shared!", @"Lockdown alert title text for screen is being captured/shared")
                                                        Message:NSLocalizedString(@"SEB is locked because the screen is being captured/shared during an exam. Stop screen capturing (or ignore it) and unlock SEB with the quit password, which usually exam supervision/support knows.", nil)];
            // Add log string for entering a locked exam
            [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Screen capturing/sharing was started while running in secure mode", nil)] withTime:[NSDate date] repeated:NO];
        } else {
            NSString *logString = [NSString stringWithFormat:@"Screen capturing/sharing %@, while %@running in secure mode%@.",
                                   UIScreen.mainScreen.isCaptured ? @"started" : @"stopped",
                                   _secureMode ? @"" : @"not ",
                                   [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_enablePrintScreen"] ? @" and it is allowed in current settings" : @""];
            DDLogInfo(@"%@", logString);
        }
    }
}


- (BOOL) conditionallyOpenSleepModeLockdownWindows
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (_secureMode &&
        _sessionRunning &&
        !_clientConfigSecureModePaused &&
        [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_mobileSleepModeLockScreen"]) {
        [self openLockdownWindows];
        [self.sebLockedViewController setLockdownAlertTitle: NSLocalizedString(@"Device Was in Sleep Mode!", @"Lockdown alert title text for device was in sleep mode")
                                                    Message:NSLocalizedString(@"Sleep mode was activated, for example by closing an iPad case. Before unlocking, check if the lock screen wallpaper of the device is displaying a cheat sheet. Then unlock SEB by entering the quit/unlock password, which usually exam supervision/support knows.", nil)];
        // Add log string for trying to re-open a locked exam
        // Calculate time difference between session resigning active and becoming active again
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [calendar components:NSCalendarUnitMinute | NSCalendarUnitSecond
                                                   fromDate:_appDidEnterBackgroundTime
                                                     toDate:_appDidBecomeActiveTime
                                                    options:NSCalendarWrapComponents];
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", [NSString stringWithFormat:NSLocalizedString(@"The device was in sleep mode for %ld:%.2ld (minutes:seconds)", nil), components.minute, components.second]] withTime:_appDidBecomeActiveTime repeated:NO];
        return YES;
    } else {
        return NO;
    }
}


- (void) lockSEB:(NSNotification *)notification
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    NSString *lockReason;
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo) {
        lockReason = [userInfo valueForKey:@"lockReason"];
    }
    DDLogError(@"%@", lockReason);
    [self openLockdownWindows];
    [self.sebLockedViewController setLockdownAlertTitle:nil Message:lockReason];
    [self appendErrorString:[NSString stringWithFormat:@"%@\n", lockReason] withTime:[NSDate date] repeated:NO];
}


- (void) openLockdownWindows
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (!self.sebLockedViewController.resignActiveLogString) {
        self.sebLockedViewController.resignActiveLogString = [[NSAttributedString alloc] initWithString:@""];
    }
    // Save current time for information about when lock windows were opened
    self.didLockSEBTime = [NSDate date];
    
    if (!_sebLocked) {
        // This sets us as the SEBLockedViewControllerDelegate
        _sebLockedViewController.sebViewController = self;
        
        _rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        
        [_rootViewController addChildViewController:self.sebLockedViewController];
        [self.sebLockedViewController didMoveToParentViewController:_rootViewController];
        
        NSArray *constraints = @[[NSLayoutConstraint constraintWithItem:self.sebLockedViewController.view
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:_rootViewController.view
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1.0
                                                               constant:0],
                                 [NSLayoutConstraint constraintWithItem:self.sebLockedViewController.view
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:_rootViewController.view
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1.0
                                                               constant:0],
                                 [NSLayoutConstraint constraintWithItem:self.sebLockedViewController.view
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:_rootViewController.view
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0],
                                 [NSLayoutConstraint constraintWithItem:self.sebLockedViewController.view
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:_rootViewController.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0]];
        [_rootViewController.view addConstraints:constraints];
        
        _sebLocked = true;
    }
}


- (void) correctPasswordEntered
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    // If (new) setting don't require a kiosk mode or
    // kiosk mode is already switched on, close lockdown window
    if (!_secureMode || (_secureMode && UIAccessibilityIsGuidedAccessEnabled() == true)) {
        [self.sebLockedViewController shouldCloseLockdownWindows];
    } else {
        // If necessary show the dialog to start SAM again
        [self showRestartSingleAppMode];
    }
}

- (void)retryButtonPressed {
}


- (void) appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime repeated:(BOOL)repeated
{
    if (!repeated &&
        (_establishingSEBServerConnection || _sebServerConnectionEstablished)) {
        NSInteger notificationID = [self.serverController sendLockscreenWithMessage:[NSString stringWithFormat:@"%@", errorString]];
        NSNumber *notificationIDNumber = [NSNumber numberWithInteger:notificationID];
        [self.sebServerPendingLockscreenEvents addObject:notificationIDNumber];
    }
    [self.sebLockedViewController appendErrorString:errorString withTime:errorTime];
}

- (NSMutableArray *) sebServerPendingLockscreenEvents
{
    if (!_sebServerPendingLockscreenEvents) {
        _sebServerPendingLockscreenEvents = [NSMutableArray new];
    }
    return _sebServerPendingLockscreenEvents;
}


#pragma mark - Remote Proctoring

- (void) openJitsiView
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (@available(iOS 11.0, *)) {
        self.previousSessionJitsiMeetEnabled = YES;
        
        // Initialize Jitsi Meet WebRTC settings
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        _jitsiMeetReceiveAudio = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetReceiveAudio"];
        _jitsiMeetReceiveVideo = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetReceiveVideo"];
        _jitsiMeetSendAudio = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetSendAudio"];
        _jitsiMeetSendVideo = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetSendVideo"];
        _remoteProctoringViewShowPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_remoteProctoringViewShow"];
        _allRTCTracks = [NSMutableArray new];
        _localRTCTracks = [NSMutableArray new];
        
        // For the case that the device orientation is unknown (accelerometer can't get accurate read of orientation)
        // we use the current UI orientation for the camera video stream
        if (@available(iOS 13.0, *)) {
            _userInterfaceOrientation = UIApplication.sharedApplication.windows.firstObject.windowScene.interfaceOrientation;
        } else {
            _userInterfaceOrientation = UIApplication.sharedApplication.statusBarOrientation;
        }
        
        EAGLContext *eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        [EAGLContext setCurrentContext:eaglContext];
        _ciContext = [CIContext contextWithEAGLContext:eaglContext options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
        
        _rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
        
        [_rootViewController addChildViewController:self.jitsiViewController];
        self.jitsiViewController.safeAreaLayoutGuideInsets = self.view.safeAreaInsets;
        [self.jitsiViewController didMoveToParentViewController:_rootViewController];
        
        NSArray *constraints = @[[NSLayoutConstraint constraintWithItem:self.jitsiViewController.view
                                                              attribute:NSLayoutAttributeLeading
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:_rootViewController.view
                                                              attribute:NSLayoutAttributeLeading
                                                             multiplier:1.0
                                                               constant:0],
                                 [NSLayoutConstraint constraintWithItem:self.jitsiViewController.view
                                                              attribute:NSLayoutAttributeTrailing
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:_rootViewController.view
                                                              attribute:NSLayoutAttributeTrailing
                                                             multiplier:1.0
                                                               constant:0],
                                 [NSLayoutConstraint constraintWithItem:self.jitsiViewController.view
                                                              attribute:NSLayoutAttributeTop
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:_rootViewController.view
                                                              attribute:NSLayoutAttributeTop
                                                             multiplier:1.0
                                                               constant:0],
                                 [NSLayoutConstraint constraintWithItem:self.jitsiViewController.view
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:_rootViewController.view
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1.0
                                                               constant:0]];
        [_rootViewController.view addConstraints:constraints];
    }
}

- (void) startProctoringWithAttributes:(NSDictionary *)attributes
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    NSString *serviceType = attributes[@"service-type"];
    DDLogDebug(@"%s: Service type: %@", __FUNCTION__, serviceType);
    if ([serviceType isEqualToString:@"JITSI_MEET"]) {
        NSString *jitsiMeetServerURLString = attributes[@"jitsiMeetServerURL"];
        NSURL *jitsiMeetServerURL = [NSURL URLWithString:jitsiMeetServerURLString];
        NSString *jitsiMeetRoom = attributes[@"jitsiMeetRoom"];
        // ToDo: Remove workaround for SEB Server bug where the room is included in the Jitsi server URL
        if ([jitsiMeetServerURL.path containsString:jitsiMeetRoom]) {
            NSRange rangeOfRoomString = [jitsiMeetServerURLString rangeOfString:jitsiMeetRoom options:NSLiteralSearch];
            jitsiMeetServerURLString = [jitsiMeetServerURLString substringToIndex:rangeOfRoomString.location-1];
            jitsiMeetServerURL = [NSURL URLWithString:jitsiMeetServerURLString];
        }
        NSString *jitsiMeetSubject = attributes[@"jitsiMeetSubject"];
        NSString *jitsiMeetToken = attributes[@"jitsiMeetToken"];
        NSString *instructionConfirm = attributes[@"instruction-confirm"];
        if (jitsiMeetServerURL && jitsiMeetRoom && jitsiMeetToken && instructionConfirm) {
            //            DDLogInfo(@"%s: Starting Jitsi Meet proctoring.", __FUNCTION__);
            [self.jitsiViewController openJitsiMeetWithServerURL:jitsiMeetServerURL
                                                            room:jitsiMeetRoom
                                                         subject:jitsiMeetSubject
                                                           token:jitsiMeetToken];
            self.serverController.sebServerController.pingInstruction = instructionConfirm;
            [self.jitsiViewController updateProctoringViewButtonState];
        } else {
            DDLogError(@"%s: Cannot start proctoring, missing parameters in attributes %@!", __FUNCTION__, attributes);
        }
    }
}

- (void) reconfigureWithAttributes:(NSDictionary *)attributes
{
    DDLogDebug(@"%s: attributes: %@", __FUNCTION__, attributes);
    NSNumber *receiveAudio = [attributes objectForKey:@"jitsiMeetReceiveAudio"];
    NSNumber *receiveVideo = [attributes objectForKey:@"jitsiMeetReceiveVideo"];
    NSNumber *featureFlagChat = [attributes objectForKey:@"jitsiMeetFeatureFlagChat"];
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (receiveAudio != nil || receiveVideo != nil || featureFlagChat != nil) {
        BOOL receiveAudioFlag = receiveAudio.boolValue;
        if (receiveAudio != nil) {
            _jitsiMeetReceiveAudio = receiveAudioFlag;
        } else {
            _jitsiMeetReceiveAudio = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetReceiveAudio"];
        }
        BOOL receiveVideoFlag = receiveVideo.boolValue;
        if (receiveVideo != nil) {
            _jitsiMeetReceiveVideo = receiveVideoFlag;
        } else {
            _jitsiMeetReceiveVideo = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetReceiveVideo"];
        }
        BOOL useChatFlag = featureFlagChat.boolValue;
        if (receiveVideoFlag || useChatFlag) {
            _remoteProctoringViewShowPolicy = remoteProctoringViewShowAlways;
        } else {
            _remoteProctoringViewShowPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_remoteProctoringViewShow"];
        }
        [self.jitsiViewController openJitsiMeetWithReceiveAudioOverride:receiveAudioFlag
                                                   receiveVideoOverride:receiveVideoFlag
                                                        useChatOverride:useChatFlag];
    } else {
        _jitsiMeetReceiveAudio = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetReceiveAudio"];
        _jitsiMeetReceiveVideo = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetReceiveVideo"];
        _jitsiMeetSendAudio = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetSendAudio"];
        _jitsiMeetSendVideo = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_jitsiMeetSendVideo"];
        _remoteProctoringViewShowPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_remoteProctoringViewShow"];
    }
    [self.jitsiViewController updateProctoringViewButtonState];
    NSString *instructionConfirm = attributes[@"instruction-confirm"];
    self.serverController.sebServerController.pingInstruction = instructionConfirm;
}


- (void) toggleProctoringViewVisibility
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    BOOL allowToggleProctoringView = (_remoteProctoringViewShowPolicy == remoteProctoringViewShowAllowToHide ||
                                      _remoteProctoringViewShowPolicy == remoteProctoringViewShowAllowToShow);
    if (allowToggleProctoringView) {
        [self.jitsiViewController toggleJitsiViewVisibilityWithSender:self];
    } else {
        if (_alertController) {
            [_alertController dismissViewControllerAnimated:NO completion:nil];
        }
        _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Remote Proctoring Active", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"The current session is being remote proctored using a live video and audio stream, which is sent to an individually configured server. Ask your examinator about their privacy policy. %@ itself doesn't connect to any centralized %@ server, your exam provider decides which proctoring server to use.", nil), SEBShortAppName, SEBShortAppName]
                                                         preferredStyle:UIAlertControllerStyleAlert];
        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.alertController = nil;
        }]];
        [self.topMostController presentViewController:_alertController animated:NO completion:nil];
    }
    [self.sideMenuController hideLeftViewAnimated];
}

- (void) adjustJitsiPiPDragBoundInsets
{
    if (@available(iOS 11.0, *)) {
        CGFloat navigationBarHeight = self.view.safeAreaInsets.top;
        CGFloat toolbarHeight = self.view.safeAreaInsets.bottom;
        UIEdgeInsets safeAreaFrameInsets = UIEdgeInsetsMake(navigationBarHeight,
                                                            self.view.safeAreaInsets.left,
                                                            toolbarHeight,
                                                            self.view.safeAreaInsets.right);
        self.jitsiViewController.safeAreaLayoutGuideInsets = safeAreaFrameInsets;
    }
}


/// WebRTC Callback Methods

- (BOOL) rtcAudioInputEnabled
{
    return _jitsiMeetSendAudio;
}

- (BOOL) rtcAudioReceivingEnabled
{
    return _jitsiMeetReceiveAudio;
}

- (BOOL) rtcVideoSendingEnabled
{
    return _jitsiMeetSendVideo;
}

- (BOOL) rtcVideoReceivingEnabled
{
    return _jitsiMeetReceiveVideo;
}

- (BOOL) rtcVideoTrackIsLocal:(RTCVideoTrack *)videoTrack
{
    BOOL videoTrackIsLocal = [_localRTCTracks containsObject:videoTrack];
    return videoTrackIsLocal;
}

- (void) detectFace:(CMSampleBufferRef)sampleBuffer
{
    if (@available(iOS 11.0, *)) {
        if (!_proctoringImageAnalyzer) {
            _proctoringImageAnalyzer = [[ProctoringImageAnalyzer alloc] init];
            _proctoringImageAnalyzer.delegate = self;
        }
        if (_proctoringImageAnalyzer.enabled) {
            [_proctoringImageAnalyzer detectFaceIn:sampleBuffer];
        }
    }
}


- (RTCVideoFrame *) overlayFrame:(RTCVideoFrame *)frame
{
    @synchronized(self) {
        
        if (_proctoringImageAnalyzer.enabled) {
            RTCCVPixelBuffer *rtcPixelBuffer = frame.buffer;
            CVPixelBufferRef pixelBuffer = rtcPixelBuffer.pixelBuffer;
            
            CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
            
            CIImage *cameraImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer];
            CGRect cameraExtend = cameraImage.extent;
            CGFloat badgeX = (cameraExtend.size.width - cameraExtend.size.height)/2 + cameraExtend.size.height - 100;
            
            CGColorSpaceRef cSpace = CGColorSpaceCreateDeviceRGB();
            RTCVideoRotation rotation = frame.rotation;
            // When the device orientation is unknown (accelerometer can't get accurate read of orientation),
            // use the initially determined UIInterfaceOrientation
            if (UIDevice.currentDevice.orientation == UIDeviceOrientationUnknown) {
                switch (_userInterfaceOrientation) {
                    case UIInterfaceOrientationPortrait:
                        rotation = RTCVideoRotation_90;
                        break;
                    case UIInterfaceOrientationPortraitUpsideDown:
                        rotation = RTCVideoRotation_270;
                        break;
                    case UIInterfaceOrientationLandscapeLeft:
                        rotation = RTCVideoRotation_0;
                        break;
                    case UIInterfaceOrientationLandscapeRight:
                        rotation = RTCVideoRotation_180;
                        break;
                    case UIInterfaceOrientationUnknown:
                        rotation = RTCVideoRotation_180;
                        break;
                }
                RTCVideoFrame *rotatedFrame = [[RTCVideoFrame alloc] initWithBuffer:rtcPixelBuffer
                                                                           rotation:rotation
                                                                        timeStampNs:frame.timeStampNs];
                frame = rotatedFrame;
            }
            int orientation;
            switch (rotation) {
                case RTCVideoRotation_0:
                    orientation = kCGImagePropertyOrientationUp;
                    break;
                case RTCVideoRotation_90:
                    orientation = kCGImagePropertyOrientationLeft;
                    break;
                case RTCVideoRotation_180:
                    orientation = kCGImagePropertyOrientationDown;
                    break;
                case RTCVideoRotation_270:
                    orientation = kCGImagePropertyOrientationRight;
                    break;
            }
            CIImage *rotatedBadge = [self.proctoringStateIcon imageByApplyingOrientation:orientation];
            CGAffineTransform transform = CGAffineTransformMakeTranslation(badgeX,30);
            CIImage *transformedOverlayImage = [rotatedBadge imageByApplyingTransform:transform];
            
            cameraImage = [transformedOverlayImage imageByCompositingOverImage:cameraImage];
            [self.ciContext render:cameraImage toCVPixelBuffer:pixelBuffer bounds:cameraExtend colorSpace:cSpace];
            
            CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
            CGColorSpaceRelease(cSpace);
        }
        
        return frame;
    }
}


- (void) proctoringEvent:(RemoteProctoringEventType)proctoringEvent
                 message:(NSString *)message
            userFeedback: (BOOL)userFeedback
{
    remoteProctoringButtonStates proctoringButtonState;
    switch (proctoringEvent) {
        case RemoteProctoringEventTypeNormal:
            proctoringButtonState = remoteProctoringButtonStateNormal;
            DDLogInfo(@"%@", message);
            break;
            
        case RemoteProctoringEventTypeWarning:
            proctoringButtonState = remoteProctoringButtonStateWarning;
            DDLogWarn(@"%@", message);
            break;
            
        case RemoteProctoringEventTypeError:
            proctoringButtonState = remoteProctoringButtonStateError;
            DDLogError(@"%@", message);
            break;
            
        default:
            proctoringButtonState = remoteProctoringButtonStateDefault;
            DDLogDebug(@"%@", message);
            break;
    }
    [self.sebUIController setProctoringViewButtonState:proctoringButtonState userFeedback:userFeedback];
}


#pragma mark - Status bar appearance

- (BOOL) prefersStatusBarHidden
{
    return (statusBarAppearance == mobileStatusBarAppearanceNone ||
            statusBarAppearance == mobileStatusBarAppearanceExtendedNoneDark ||
            statusBarAppearance == mobileStatusBarAppearanceExtendedNoneLight);
}


#pragma mark - SEB Dock and left slider button handler

- (void) leftDrawerButtonPress:(id)sender
{
    [self.sideMenuController showLeftViewAnimated];
}


- (void) leftDrawerKeyShortcutPress:(id)sender
{
    [self.sideMenuController toggleLeftViewAnimated];
}


- (IBAction) toggleScrollLock
{
    [_browserTabViewController toggleScrollLock];
}

- (void) updateScrollLockButtonStates
{
    [self.sebUIController updateScrollLockButtonStates];
}

- (BOOL) isScrollLockActive
{
    return [_browserTabViewController isScrollLockActive];
}


- (void)zoomPageIn
{
    [_browserTabViewController zoomPageIn];
}


- (void)zoomPageOut
{
    [_browserTabViewController zoomPageOut];
}


- (void)zoomPageReset
{
    [_browserTabViewController zoomPageReset];
}


- (void)textSizeIncrease
{
    [_browserTabViewController textSizeIncrease];
}


- (void)textSizeDecrease
{
    [_browserTabViewController textSizeDecrease];
}


- (void)textSizeReset
{
    [_browserTabViewController textSizeReset];
}


- (IBAction) searchTextOnPage
{
    [self.sideMenuController hideLeftViewAnimated:YES completionHandler:^{
        [self activateSearchField];
    }];
}


- (IBAction) backToStart
{
    NSString *backToStartText = [self backToStartText];
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamPasswordProtected"] == YES) {
        NSString *hashedQuitPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
        // if quitting SEB is allowed
        if (hashedQuitPassword.length > 0) {
            // if quit password is set, then restrict quitting
            // Allow up to 5 attempts for entering decoding password
            attempts = 5;
            NSString *enterPasswordString = NSLocalizedString(@"Enter quit password:", nil);
            
            // Ask the user to enter the quit password and proceed to the callback method after this happend
            [self.configFileController promptPasswordWithMessageText:enterPasswordString
                                                               title:backToStartText
                                                            callback:self
                                                            selector:@selector(enteredBackToStartPassword:)];
            return;
        }
    }
    // if no quit password is required, then just confirm Back to Start
    [self alertWithTitle:backToStartText
                 message:NSLocalizedString(@"Are you sure?", nil)
            action1Title:NSLocalizedString(@"OK", nil)
          action1Handler:^{
        [self.browserTabViewController backToStart];
        [self.sideMenuController hideLeftViewAnimated];
    }
            action2Title:NSLocalizedString(@"Cancel", nil)
          action2Handler:^{
        [self.sideMenuController hideLeftViewAnimated];
    }];
}


- (void) alertWithTitle:(NSString *)title
                message:(NSString *)message
           action1Title:(NSString *)action1Title
         action1Handler:(void (^)(void))action1Handler
           action2Title:(NSString *)action2Title
         action2Handler:(void (^)(void))action2Handler
{
    [self alertWithTitle:title
                 message:message
          preferredStyle:UIAlertControllerStyleAlert
            action1Title:action1Title
            action1Style:UIAlertActionStyleDefault
          action1Handler:action1Handler
            action2Title:action2Title
            action2Style:UIAlertActionStyleCancel
          action2Handler:action2Handler];
}


- (void) alertWithTitle:(NSString *)title
                message:(NSString *)message
         preferredStyle:(UIAlertControllerStyle)controllerStyle
           action1Title:(NSString *)action1Title
           action1Style:(UIAlertActionStyle)action1Style
         action1Handler:(void (^)(void))action1Handler
           action2Title:(NSString *)action2Title
           action2Style:(UIAlertActionStyle)action2Style
         action2Handler:(void (^)(void))action2Handler
{
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _alertController = [UIAlertController alertControllerWithTitle:title
                                                           message:message
                                                    preferredStyle:controllerStyle];
    [_alertController addAction:[UIAlertAction actionWithTitle:action1Title
                                                         style:action1Style
                                                       handler:^(UIAlertAction *action) {
        self.alertController = nil;
        action1Handler();
    }]];
    if (action2Title) {
        [_alertController addAction:[UIAlertAction actionWithTitle:action2Title
                                                             style:action2Style
                                                           handler:^(UIAlertAction *action) {
            self.alertController = nil;
            action2Handler();
        }]];
    }
    
    [self.topMostController presentViewController:_alertController animated:NO completion:nil];
}


- (void) alertWithTitle:(NSString *)title
                message:(NSString *)message
         preferredStyle:(UIAlertControllerStyle)controllerStyle
           action1Title:(NSString *)action1Title
           action1Style:(UIAlertActionStyle)action1Style
         action1Handler:(void (^)(void))action1Handler
           action2Title:(NSString *)action2Title
           action2Style:(UIAlertActionStyle)action2Style
         action2Handler:(void (^)(void))action2Handler
           action3Title:(NSString *)action3Title
           action3Style:(UIAlertActionStyle)action3Style
         action3Handler:(void (^)(void))action3Handler
{
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _alertController = [UIAlertController alertControllerWithTitle:title
                                                           message:message
                                                    preferredStyle:controllerStyle];
    [_alertController addAction:[UIAlertAction actionWithTitle:action1Title
                                                         style:action1Style
                                                       handler:^(UIAlertAction *action) {
        self.alertController = nil;
        action1Handler();
    }]];
    if (action2Title) {
        [_alertController addAction:[UIAlertAction actionWithTitle:action2Title
                                                             style:action2Style
                                                           handler:^(UIAlertAction *action) {
            self.alertController = nil;
            action2Handler();
        }]];
    }
    if (action3Title) {
        [_alertController addAction:[UIAlertAction actionWithTitle:action3Title
                                                             style:action3Style
                                                           handler:^(UIAlertAction *action) {
            self.alertController = nil;
            action3Handler();
        }]];
    }

    [self.topMostController presentViewController:_alertController animated:NO completion:nil];
}


- (void) enteredBackToStartPassword:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
        [self.sideMenuController hideLeftViewAnimated];
        return;
    }
    
    // Get quit password hash from current client settings
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    hashedQuitPassword = [hashedQuitPassword uppercaseString];
    
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSString *hashedPassword = [keychainManager generateSHAHashString:password];
    hashedPassword = [hashedPassword uppercaseString];
    
    attempts--;
    
    NSString *backToStartText = [self backToStartText];
    if ([hashedPassword caseInsensitiveCompare:hashedQuitPassword] != NSOrderedSame) {
        // wrong password entered, are there still attempts left?
        if (attempts > 0) {
            // Let the user try it again
            NSString *enterPasswordString = NSLocalizedString(@"Wrong password! Try again to enter the quit password:",nil);
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.configFileController promptPasswordWithMessageText:enterPasswordString
                                                               title:backToStartText
                                                            callback:self
                                                            selector:@selector(enteredBackToStartPassword:)];
            return;
            
        } else {
            // Wrong password entered in the last allowed attempts: Stop quitting the exam
            DDLogError(@"%s: Couldn't go back to start: The correct quit password wasn't entered.", __FUNCTION__);
            
            NSString *title = backToStartText;
            NSString *informativeText = NSLocalizedString(@"You need to enter the correct quit password for this command.", nil);
            [self.configFileController showAlertWithTitle:title andText:informativeText];
            return;
        }
        
    } else {
        // The correct quit password was entered
        [_browserTabViewController backToStart];
        [self.sideMenuController hideLeftViewAnimated];
    }
}


- (NSString *) backToStartText
{
    NSString *backToStartText = [[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_restartExamText"];
    if (backToStartText.length == 0) {
        backToStartText = NSLocalizedString(@"Back to Start",nil);
    }
    return backToStartText;
}


- (IBAction) goBack {
    [_browserTabViewController goBack];
    [self.sideMenuController hideLeftViewAnimated];
}


- (IBAction) goForward {
    [_browserTabViewController goForward];
    [self.sideMenuController hideLeftViewAnimated];
}


- (IBAction) reload {
    void (^action1Handler)(void) =
    ^{
        [self.browserTabViewController reload];
        [self.sideMenuController hideLeftViewAnimated];
    };
    
    BOOL isMainBrowserWebViewActive = self.browserController.isMainBrowserWebViewActive;
    if (![self.browserController isReloadAllowedMainWebView:isMainBrowserWebViewActive]) {
        // Cancel if reload is disabled in exam or additional browser tabs
        [self.sideMenuController hideLeftViewAnimated];
        return;
    }
    BOOL showReloadWarning = [self.browserController showReloadWarningMainWebView:isMainBrowserWebViewActive];
    if (showReloadWarning) {
        [self alertWithTitle:NSLocalizedString(@"Reload Page", nil)
                     message:NSLocalizedString(@"Do you really want to reload the web page?", nil)
                action1Title:NSLocalizedString(@"Reload", nil)
              action1Handler:action1Handler
                action2Title:NSLocalizedString(@"Cancel", nil)
              action2Handler:^{
            [self.sideMenuController hideLeftViewAnimated];
        }];
    } else {
        action1Handler();
    }
}


- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
{
    toolbarBackButton.enabled = canGoBack;
    toolbarForwardButton.enabled = canGoForward;
    
    [self.sebUIController setCanGoBack:canGoBack canGoForward:canGoForward];
}


// Add reload button to navigation bar or enable/disable
// reload buttons in dock and left slider, depending if
// active tab is the exam tab or a new (additional) tab
- (void) activateReloadButtonsExamTab:(BOOL)examTab
{
    BOOL showReload = [self.browserController isReloadAllowedMainWebView:examTab];
    [self activateReloadButtons:showReload];
}


// Conditionally add reload button to navigation bar or
// enable/disable reload buttons in dock and left slider
- (void) activateReloadButtons:(BOOL)reloadEnabled
{
    // Activate/Deactivate reload buttons in dock and slider
    [self.sebUIController activateReloadButtons:reloadEnabled];
    
    // Activate/Deactivate reload button and other buttons (search text) in navigation bar
    [self updateRightNavigationItemsReloadEnabled:reloadEnabled];
}


- (void) activateZoomButtons:(BOOL)zoomEnabled
{
    [self.sebUIController activateZoomButtons:zoomEnabled];
}


- (void)setPowerConnected:(BOOL)powerConnected warningLevel:(SEBLowBatteryWarningLevel)batteryWarningLevel {
    // ToDo: To be used for battery dock item
}

- (void)updateBatteryLevel:(double)batteryLevel infoString:(nonnull NSString *)infoString {
    // ToDo: To be used for battery dock item
}


#pragma mark - SEBBrowserControllerDelegate methods

// Delegate method to display an enter password dialog with the
// passed message text asynchronously, calling the callback
// method with the entered password when one was entered
- (void) showEnterUsernamePasswordDialog:(NSString *)text
                                   title:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector
{
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _alertController = [UIAlertController alertControllerWithTitle:title
                                                           message:text
                                                    preferredStyle:UIAlertControllerStyleAlert];
    
    [_alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
        textField.placeholder = NSLocalizedString(@"User Name", nil);
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
        if (@available(iOS 11.0, *)) {
            textField.textContentType = UITextContentTypeUsername;
        }
        if (username.length > 0) {
            textField.text = username;
        } else {
            [textField becomeFirstResponder];
        }
    }];
    
    [_alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
        textField.placeholder = NSLocalizedString(@"Password", nil);
        textField.secureTextEntry = YES;
        if (@available(iOS 11.0, *)) {
            textField.textContentType = UITextContentTypePassword;
        }
        // If there was a username provided, we select the password field
        if (username.length > 0) {
            [textField becomeFirstResponder];
        }
    }];
    
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Log In", nil)
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *username = self.alertController.textFields[0].text;
        NSString *password = self.alertController.textFields[1].text;
        self.alertController = nil;
        IMP imp = [modalDelegate methodForSelector:didEndSelector];
        void (*func)(id, SEL, NSString*, NSString*, NSInteger) = (void *)imp;
        func(modalDelegate, didEndSelector, username, password, SEBEnterPasswordOK);
    }]];
    
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        NSString *username = self.alertController.textFields[0].text;
        NSString *password = self.alertController.textFields[1].text;
        self.alertController = nil;
        IMP imp = [modalDelegate methodForSelector:didEndSelector];
        void (*func)(id, SEL, NSString*, NSString*, NSInteger) = (void *)imp;
        func(modalDelegate, didEndSelector, username, password, SEBEnterPasswordCancel);
    }]];
    
    [self.topMostController presentViewController:_alertController animated:NO completion:nil];
}


// Delegate method to hide the previously displayed enter password dialog
- (void) hideEnterUsernamePasswordDialog
{
    [self.alertController dismissViewControllerAnimated:NO completion:^{
        self.alertController = nil;
    }];
}


// Delegate method which displays a dialog when a config file
// is being downloaded, providing a cancel button. When tapped, then
// the callback method is invoked
- (void) showOpeningConfigFileDialog:(NSString *)text
                               title:(NSString *)title
                      cancelCallback:(id)callback
                            selector:(SEL)selector
{
    //    [self alertWithTitle:title
    //                 message:text
    //            action1Title:NSLocalizedString(@"Cancel", nil)
    //          action1Handler:^{
    //              IMP imp = [callback methodForSelector:selector];
    //              void (*func)(id, SEL) = (void *)imp;
    //              func(callback, selector);
    //          }
    //            action2Title:nil
    //          action2Handler:nil];
}


// Delegate method to close the dialog displayed while a config file
// is being downloaded,
- (void) closeOpeningConfigFileDialog;
{
    //    if (_alertController) {
    //        [_alertController dismissViewControllerAnimated:NO completion:nil];
    //        _alertController = nil;
    //    }
}


// Called by the CustomHTTPProtocol class to let the delegate know that a regular HTTP request
// or a XMLHttpRequest (XHR) successfully completed loading. The delegate can use this callback
// for example to scan the newly received HTML data
- (void)sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task
{
    [self.browserTabViewController sessionTaskDidCompleteSuccessfully:task];
}

#pragma mark - Search text


- (void) activateSearchField
{
    self.browserTabViewController.visibleWebViewController.openCloseSlider = NO; // This is unfortunately necessary because of reasons...
    [self showToolbarConditionally:NO withCompletion:^{
        [self->textSearchBar becomeFirstResponder];
    }];
}


- (void) searchTextNext
{
    [self.browserTabViewController.visibleWebViewController searchText:nil backwards:NO caseSensitive:NO];
}


- (void) searchTextPrevious
{
    [self.browserTabViewController.visibleWebViewController searchText:nil backwards:YES caseSensitive:NO];
}


- (void) searchTextMatchFound:(BOOL)matchFound
{
    self.searchMatchFound = matchFound;
    toolbarSearchButtonPreviousResult.hidden = !matchFound;
    toolbarSearchButtonNextResult.hidden = !matchFound;
}


- (void) textSearchDone:(id)sender
{
    [textSearchBar endEditing:YES];
    if (textSearchBar.text.length > 0) {
        textSearchBar.text = @"";
        self.browserTabViewController.visibleWebViewController.searchText = @"";
        [self.browserTabViewController.visibleWebViewController searchText:nil backwards:NO caseSensitive:NO];
    }
    [self resetSearchBar];

    // If a temporary toolbar (UINavigationBar) was used, remove it
    [self conditionallyRemoveToolbarWithCompletion:nil];
}

- (void) resetSearchBar
{
    if (textSearchBar) {
        toolbarSearchButtonDone.hidden = YES;
        toolbarSearchButtonPreviousResult.hidden = YES;
        toolbarSearchButtonNextResult.hidden = YES;
        // Because minimizing the width of UISearchBar doesn't work properly, we need to remove and add it again
        UIView *searchBarView = textSearchBar.superview;
        [textSearchBar removeFromSuperview];
        textSearchBar = nil;
        [self createSearchBarInView:searchBarView];
    }
}


- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if (self.navigationItem.title) {
        toolbarSearchBarReplacedTitle = self.navigationItem.title;
    }
    [self setSearchBarWidthIcon:NO];
    toolbarSearchButtonDone.hidden = NO;
}


//- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
//{
//    return YES;
//}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
}

- (void)searchBar:(UISearchBar *)searchBar
    textDidChange:(NSString *)newSearchText
{
    if (![self.browserTabViewController.visibleWebViewController.searchText isEqualToString:newSearchText]) {
        self.browserTabViewController.visibleWebViewController.searchText = newSearchText;
        [self.browserTabViewController.visibleWebViewController searchText:nil backwards:NO caseSensitive:NO];
    }
}

// called when keyboard search button pressed
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar endEditing:YES];
}


- (void)sebWebViewDidFinishLoad
{
    if (self.browserTabViewController.visibleWebViewController.searchText.length > 0) {
        [self.browserTabViewController.visibleWebViewController searchText:@"" backwards:NO caseSensitive:NO];
        [self.browserTabViewController.visibleWebViewController searchText:nil backwards:NO caseSensitive:NO];
    }
}


#pragma mark - Memory warning delegate methods

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
