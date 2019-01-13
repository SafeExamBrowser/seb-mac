//
//  SEBViewController.m
//
//  Created by Daniel R. Schneider on 10/09/15.
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

#import <WebKit/WebKit.h>
#import "Constants.h"

#import "SEBViewController.h"

static NSMutableSet *browserWindowControllers;

@implementation SEBViewController

@synthesize appSettingsViewController;


#pragma mark - Initializing

- (IASKAppSettingsViewController*)appSettingsViewController {
    if (!appSettingsViewController) {
        appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
        _sebInAppSettingsViewController = [[SEBInAppSettingsViewController alloc] init];
        _sebInAppSettingsViewController.sebViewController = self;
        _sebInAppSettingsViewController.appSettingsViewController = appSettingsViewController;
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


- (SEBLockedViewController*)sebLockedViewController
{
    if (!_sebLockedViewController) {
        _sebLockedViewController = [[SEBLockedViewController alloc] init];
    }
    return _sebLockedViewController;
}


- (SEBBrowserController *) browserController
{
    if (!_browserController) {
        _browserController = [[SEBBrowserController alloc] init];
        _browserController.delegate = self;
    }
    return _browserController;
}


- (UIViewController *) topMostController
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
                                                                     self->_alertController = nil;
                                                                     NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                                     if ([[UIApplication sharedApplication] canOpenURL:url]) {
                                                                         [[UIApplication sharedApplication] openURL:url];
                                                                     }
                                                                 }]];
            [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                 style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                                     self->_alertController = nil;
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
                                                                     self->_alertController = nil;
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
    // Initialize file logger if logging enabled
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableLogging"] == NO) {
        [DDLog removeLogger:_myLogger];
    } else {
        //Set log directory
//        NSString *logPath = [[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_logDirectoryOSX"];
//        [DDLog removeLogger:_myLogger];
//        if (logPath.length == 0) {
//            // No log directory indicated: We use the standard one
//            logPath = nil;
//        } else {
//            logPath = [logPath stringByExpandingTildeInPath];
//            // Add subdirectory with the name of the computer
//        }
        DDLogFileManagerDefault* logFileManager = [[DDLogFileManagerDefault alloc] init];
        _myLogger = [[DDFileLogger alloc] initWithLogFileManager:logFileManager];
        _myLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
        _myLogger.logFileManager.maximumNumberOfLogFiles = 7; // keep logs for 7 days
        [DDLog addLogger:_myLogger];
    }
}


#pragma mark - View management delegate methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    _appDelegate.sebViewController = self;
    
    _browserTabViewController = self.childViewControllers[0];
    _browserTabViewController.sebViewController = self;
    
    self.sideMenuController.delegate = self;
    
    DDLogError(@"---------- INITIALIZING SEB - STARTING SESSION -------------");
    [self initializeLogger];
    
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
    
    // Add Notification Center observer to be alerted of any change to NSUserDefaults.
    // Managed app configuration changes pushed down from an MDM server appear in NSUSerDefaults.
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      NSDictionary *serverConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kConfigurationKey];
                                                      if (serverConfig) {
                                                          if (!self->_settingsOpen) {
                                                              DDLogWarn(@"NSUserDefaultsDidChangeNotification: Did receive MDM Managed Configuration dictionary.");
                                                              // Only reconfigure immediately with config received from MDM server
                                                              // when settings aren't open (otherwise it's postponed to next
                                                              // session restart or when leaving and returning to SEB
                                                              [self conditionallyOpenSEBConfigFromMDMServer];
                                                          } else {
                                                              DDLogWarn(@"NSUserDefaultsDidChangeNotification: Did receive MDM Managed Configuration dictionary, but InAppSettings are open. Delaying appying the MDM config.");
                                                          }
                                                      }
                                                  }];
    
    // Add Notification Center observer to be alerted when the UIScreen isCaptured property changes
//    if (@available(iOS 11.0, *)) {
//        [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenCapturedDidChangeNotification
//                                                          object:nil
//                                                           queue:[NSOperationQueue mainQueue]
//                                                      usingBlock:^(NSNotification *note) {
//                                                          [self readDefaultsValues];
//                                                      }];
//    }
    
    // Initialize UI and default UI/browser settings
    [self initSEB];
    
    // Was SEB opened by loading a .seb file/using a seb:// link?
    if (_appDelegate.sebFileURL) {
        DDLogInfo(@"SEB was started by loading a .seb file/using a seb:// link");
        // Yes: Load the .seb file now that the necessary SEB main view controller was loaded
        if (_settingsOpen) {
            DDLogInfo(@"SEB was started by loading a .seb file / seb:// link, but Settings were open, they need to be closed first");
            // Close settings
            [self.appSettingsViewController dismissViewControllerAnimated:YES completion:^{
                self.appSettingsViewController = nil;
                self->_settingsOpen = false;
                [self conditionallyDownloadAndOpenSEBConfigFromURL:self->_appDelegate.sebFileURL];
                
                // Set flag that SEB is initialized to prevent the client config
                // Start URL to be loaded
                [[MyGlobals sharedMyGlobals] setFinishedInitializing:YES];
            }];
        } else {
            [self conditionallyDownloadAndOpenSEBConfigFromURL:_appDelegate.sebFileURL];
            
            // Set flag that SEB is initialized to prevent the client config
            // Start URL to be loaded
            [[MyGlobals sharedMyGlobals] setFinishedInitializing:YES];
        }
    } else if (_appDelegate.shortcutItemAtLaunch) {
        // Was SEB opened by a Home screen quick action shortcut item?
        DDLogInfo(@"SEB was started by a Home screen quick action shortcut item");

        // Set flag that SEB is initialized to prevent the client config
        // Start URL to be loaded
        [[MyGlobals sharedMyGlobals] setFinishedInitializing:YES];

        [self handleShortcutItem:_appDelegate.shortcutItemAtLaunch];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([self allowediOSVersion]) {
        // Check if we received new settings from an MDM server
        //    [self readDefaultsValues];
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        // Check if settings aren't initialized and initial config assistant should be started
        if (!_initAssistantOpen && [preferences boolForKey:@"allowEditingConfig"]) {
            [preferences setBool:NO forKey:@"allowEditingConfig"];
            [self conditionallyShowSettingsModal];
        } else if ([preferences boolForKey:@"initiateResetConfig"]) {
            [self conditionallyResetSettings];
        } else if (![[MyGlobals sharedMyGlobals] finishedInitializing] &&
                   _appDelegate.openedUniversalLink == NO) {
            [self conditionallyStartKioskMode];
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
        BOOL iPadExtendedDisplay = homeIndicatorSpaceHeight && (calculatedNavigationBarHeight == 50 || calculatedNavigationBarHeight == 42);

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
            if (calculatedToolbarHeight == 46) {
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
    // Check if settings are currently open
    if (_settingsOpen) {
        // Close settings, but check if settings presented some alert or the share dialog first
        DDLogInfo(@"SEB settings should be reset, but the Settings view was open, it will be closed first");
        if (self.appSettingsViewController.presentedViewController) {
            [self.appSettingsViewController.presentedViewController dismissViewControllerAnimated:NO completion:^{
                [self conditionallyResetSettings];
            }];
            return;
        } else if (self.appSettingsViewController) {
            [self.appSettingsViewController dismissViewControllerAnimated:YES completion:^{
                self.appSettingsViewController = nil;
                self->_settingsOpen = false;
                [self conditionallyResetSettings];
            }];
            return;
        }
    } else {
        if (self.alertController) {
            [self.alertController dismissViewControllerAnimated:NO completion:^{
                self.alertController = nil;
                [self conditionallyResetSettings];
            }];
            return;
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
}


- (void) resetSettingsEnteredAdminPassword:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
        
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
    
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:YES];
    
    DDLogError(@"---------- SEB SETTINGS RESET PERFORMED -------------");
    [self initializeLogger];
    
    [self resetSEB];
    [self initSEB];
    [self openInitAssistant];
}


#pragma mark - Inititial Configuration Assistant

- (void)openInitAssistant
{
    if (!_initAssistantOpen) {
        if (!_assistantViewController) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            _assistantViewController = [storyboard instantiateViewControllerWithIdentifier:@"SEBInitAssistantView"];
            _assistantViewController.sebViewController = self;
            _assistantViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        //// Initialize SEB Dock, commands section in the slider view and
        //// 3D Touch Home screen quick actions
        
        // Add scan QR code Home screen quick action
        [UIApplication sharedApplication].shortcutItems = [NSArray arrayWithObject:[ self scanQRCodeShortcutItem]];

        if (_alertController) {
            [_alertController dismissViewControllerAnimated:NO completion:^{
                self->_alertController = nil;
            }];
        }

        [self.topMostController presentViewController:_assistantViewController animated:YES completion:^{
            self->_initAssistantOpen = true;
        }];
    }
}


- (UIApplicationShortcutItem *)scanQRCodeShortcutItem
{
    UIApplicationShortcutIcon *shortcutItemIcon = [UIApplicationShortcutIcon iconWithTemplateImageName:@"SEBQuickActionQRCodeIcon"];
    NSString *shortcutItemType = [NSString stringWithFormat:@"%@.ScanQRCodeConfig", [NSBundle mainBundle].bundleIdentifier];
    UIApplicationShortcutItem *scanQRCodeShortcutItem = [[UIApplicationShortcutItem alloc] initWithType:shortcutItemType
                                                                                         localizedTitle:@"Config QR Code"
                                                                                      localizedSubtitle:nil
                                                                                                   icon:shortcutItemIcon
                                                                                               userInfo:nil];
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
            self->_alertController = nil;
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
    if (!_scannedQRCode) {
        _scannedQRCode = true;
        [_visibleCodeReaderViewController dismissViewControllerAnimated:YES completion:^{
            self->_visibleCodeReaderViewController = nil;
            [self adjustBars];
            DDLogInfo(@"Scanned QR code: %@", result);
            NSURL *URLFromString = [NSURL URLWithString:result];
            if (URLFromString) {
                [self conditionallyDownloadAndOpenSEBConfigFromURL:URLFromString];
            } else {
                NSError *error = [self.configFileController errorCorruptedSettingsForUnderlyingError:nil];
                [self storeNewSEBSettingsSuccessful:error];
            }
        }];
    }
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self.sideMenuController hideLeftView];
    [self adjustBars];
    [_visibleCodeReaderViewController dismissViewControllerAnimated:YES completion:^{
        self->_visibleCodeReaderViewController = nil;
        if (!self->_finishedStartingUp || self->_pausedSAMAlertDisplayed) {
            self->_pausedSAMAlertDisplayed = false;
            // Continue starting up SEB without resetting settings
            // but user interface might need to be re-initialized
            [self initSEB];
            [self conditionallyStartKioskMode];
        }
    }];
}


#pragma mark - Handle requests to show in-app settings

- (void)conditionallyShowSettingsModal
{
    // Check if the initialize settings assistant is open
    if (_initAssistantOpen) {
        [self dismissViewControllerAnimated:YES completion:^{
            self->_initAssistantOpen = false;
            [self conditionallyShowSettingsModal];
        }];
        return;
    } else if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:^{
            self->_alertController = nil;
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
                [self showSettingsModal];
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
    }
}


- (void) enteredAdminPassword:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
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
            [self.sideMenuController hideLeftViewAnimated];
            if (!_finishedStartingUp) {
                [self conditionallyStartKioskMode];
            }
        }
        
    } else {
        // The correct admin password was entered: continue processing the parsed SEB settings it
        [self showSettingsModal];
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
            self->_alertController = nil;
        }];
    }
    [self.sideMenuController hideLeftViewAnimated];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    _aboutSEBViewController = [storyboard instantiateViewControllerWithIdentifier:@"AboutSEBView"];
    _aboutSEBViewController.sebViewController = self;
    _aboutSEBViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.topMostController presentViewController:_aboutSEBViewController animated:YES completion:^{
        self->_aboutSEBViewDisplayed = true;
    }];
}


#pragma mark - Show in-app settings

- (void)showSettingsModal
{
    [self.sideMenuController hideLeftViewAnimated];

    // Get hashed passwords and put empty or placeholder strings into the password fields in InAppSettings
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
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
            self->_alertController = nil;
        }];
    }

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:self.appSettingsViewController];

    //[viewController setShowCreditsFooter:NO];   // Uncomment to not display InAppSettingsKit credits for creators.
    // But we encourage you not to uncomment. Thank you!

    self.appSettingsViewController.showDoneButton = YES;
    
    if (!settingsShareButton) {
        settingsShareButton = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                               target:self
                               action:@selector(shareSettingsAction:)];
    }
    self.appSettingsViewController.navigationItem.leftBarButtonItem = settingsShareButton;
    
    // Register notification for changed keys
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(inAppSettingsChanged:)
                                                 name:kIASKAppSettingChanged
                                               object:nil];
    
    _settingsOpen = true;
    
    [self.topMostController presentViewController:navigationController animated:YES completion:nil];
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
    
    // Get password
    NSString *encryptingPassword;
    // Is there one saved from the currently open config file?
    encryptingPassword = [preferences secureStringForKey:@"settingsPassword"];
    
    // Encrypt current settings with current credentials
    NSData *encryptedSEBData = [self.configFileController encryptSEBSettingsWithPassword:encryptingPassword passwordIsHash:NO withIdentity:nil forPurpose:configPurpose];
    if (encryptedSEBData) {

        if (_alertController) {
            [_alertController dismissViewControllerAnimated:NO completion:^{
                self->_alertController = nil;
            }];
            return;
        }

        // Get config file name
        NSString *configFileName = [preferences secureStringForKey:@"configFileName"];
        if (configFileName.length == 0) {
            configFileName = @"SEBConfigFile";
        }

        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:configFileName];
        NSString *configFilePath = [documentsPath stringByAppendingPathExtension:configPurpose == sebConfigPurposeManagedConfiguration ? @"plist" : SEBFileExtension];
        NSURL *configFileRUL = [NSURL fileURLWithPath:configFilePath];
        
        [encryptedSEBData writeToURL:configFileRUL atomically:YES];

        NSArray *activityItems;
        
        NSString *configFilePurpose = (configPurpose == sebConfigPurposeStartingExam ?
                                       NSLocalizedString(@"for starting an exam", nil) :
                                       (configPurpose == sebConfigPurposeConfiguringClient ?
                                       NSLocalizedString(@"for configuring clients", nil) :
                                        NSLocalizedString(@"for Managed Configuration (MDM)", nil)));
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"] &&
            [preferences secureBoolForKey:@"org_safeexambrowser_configFileShareKeys"]) {
            NSData *hashKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
            NSString *browserExamKey = hashKey ? [NSString stringWithFormat:@"\nBrowser Exam Key: %@", [self base16StringForHashKey:hashKey]] : nil;
            hashKey = [preferences secureObjectForKey:@"org_safeexambrowser_configKey"];
            NSString *configKey = hashKey ? [NSString stringWithFormat:@"\nConfig Key: %@", [self base16StringForHashKey:hashKey]] : nil;
            activityItems = @[ [NSString stringWithFormat:NSLocalizedString(@"%@ Config File %@", nil), SEBShortAppName, configFilePurpose], browserExamKey, configKey, configFileRUL ];
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


- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{    
    // Update entered passwords and save their hashes to SEB settings
    // as long as the passwords were really entered and don't contain the hash placeholders
    [self updateEnteredPasswords];
    
    // Check if settings changed
    if ([[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:NO updateSalt:NO]) {
        // Yes: Reset contained keys dictionary for Config Key, because it needs to be updated
        [[NSUserDefaults standardUserDefaults] setSecureObject:nil
                                                        forKey:@"org_safeexambrowser_configKeyContainedKeys"];
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    }
    _settingsOpen = false;
    
    NSString *pasteboardString;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"] &&
        [preferences secureBoolForKey:@"org_safeexambrowser_configFileShareKeys"]) {
        NSData *hashKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
        NSString *browserExamKey = hashKey ? [NSString stringWithFormat:@"Browser Exam Key: %@", [self base16StringForHashKey:hashKey]] : nil;
        hashKey = [preferences secureObjectForKey:@"org_safeexambrowser_configKey"];
        NSString *configKey = hashKey ? [NSString stringWithFormat:@"Config Key: %@", [self base16StringForHashKey:hashKey]] : nil;
        pasteboardString =  [NSString stringWithFormat:@"%@ \n%@", browserExamKey, configKey];
    }
    
    // Restart exam: Close all tabs, reset browser and reset kiosk mode
    // before re-initializing SEB with new settings
    _settingsDidClose = YES;
    [self restartExam:NO quittingClientConfig:NO pasteboardString:pasteboardString];
}


- (BOOL)readMDMServerConfig
{
    BOOL readMDMConfig = NO;

    if (!_isReconfiguringToMDMConfig) {
        DDLogWarn(@"%s", __FUNCTION__);
        // Check if we received a new configuration from an MDM server
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSDictionary *serverConfig = [preferences dictionaryForKey:kConfigurationKey];
        BOOL allowReconfiguring = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_examSessionReconfigureAllow"];
        BOOL examSession = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length > 0;
        DDLogWarn(@"%@ receive MDM Managed Configuration dictionary.", serverConfig.count > 0 ? @"Did" : @"Didn't");
        if (serverConfig &&
            ((!examSession && !NSUserDefaults.userDefaultsPrivate) ||
             (!examSession && NSUserDefaults.userDefaultsPrivate && allowReconfiguring) ||
             (examSession && allowReconfiguring))) {

                _isReconfiguringToMDMConfig = true;
                readMDMConfig = YES;
                // If we did receive a config and SEB isn't running in exam mode currently
                DDLogDebug(@"%s: Received new configuration from MDM server: %@", __FUNCTION__, serverConfig);
                // As we handle the config received from the MDM server, we need to remove it from settings
                [preferences removeObjectForKey:kConfigurationKey];
                [self.configFileController reconfigueClientWithMDMSettingsDict:serverConfig
                                                                      callback:self
                                                                      selector:@selector(storeNewSEBSettingsSuccessful:)];
            } else {
                DDLogWarn(@"%@ receive MDM Managed Configuration dictionary, reconfiguring isn't allowed currently.", serverConfig.count > 0 ? @"Did" : @"Didn't");
            }
    } else {
        DDLogWarn(@"%s: Already reconfiguring to MDM config!", __FUNCTION__);
    }
    return readMDMConfig;
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


#pragma mark - Init, reconfigure and reset SEB

void run_on_ui_thread(dispatch_block_t block)
{
    if ([NSThread isMainThread])
        block();
    else
        dispatch_sync(dispatch_get_main_queue(), block);
}


- (void) initSEB
{
    if (sebUIInitialized) {
        _appDelegate.sebUIController = nil;
    } else {
        sebUIInitialized = true;
    }
    run_on_ui_thread(^{
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        // Set up system
        
        // Set preventing Auto-Lock according to settings
        [UIApplication sharedApplication].idleTimerDisabled = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobilePreventAutoLock"];
        
        // Create browser user agent according to settings
        NSString* versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
        NSString *overrideUserAgent;
        NSString *browserUserAgentSuffix = [[preferences secureStringForKey:@"org_safeexambrowser_SEB_browserUserAgent"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (browserUserAgentSuffix.length != 0) {
            browserUserAgentSuffix = [NSString stringWithFormat:@" %@", browserUserAgentSuffix];
        }

        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserUserAgentiOS"] == browserUserAgentModeiOSDefault) {
            overrideUserAgent = [[MyGlobals sharedMyGlobals] valueForKey:@"defaultUserAgent"];
        } else if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserUserAgentiOS"] == browserUserAgentModeiOSMacDesktop) {
            overrideUserAgent = SEBiOSUserAgentDesktopMac;
        } else {
            overrideUserAgent = [preferences secureStringForKey:@"org_safeexambrowser_SEB_browserUserAgentiOSCustom"];
        }
        // Add "SEB <version number>" to the browser's user agent, so the LMS SEB plugins recognize us
        overrideUserAgent = [overrideUserAgent stringByAppendingString:[NSString stringWithFormat:@" %@/%@%@", SEBUserAgentDefaultSuffix, versionString, browserUserAgentSuffix]];

        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:overrideUserAgent, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
        
        // Update URL filter flags and rules
        [[SEBURLFilter sharedSEBURLFilter] updateFilterRules];
        // Update URL filter ignore rules
        [[SEBURLFilter sharedSEBURLFilter] updateIgnoreRuleList];
        
        // Activate the custom URL protocol if necessary (embedded certs or pinning available)
        [self.browserController conditionallyInitCustomHTTPProtocol];
        
        // UI
        
        [self addBrowserToolBarWithOffset:0];

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
            self->_appDelegate.showSettingsInApp = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showSettingsInApp"];
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
        
        /// If dock is enabled, register items to the toolbar
        
        if (self.sebUIController.dockEnabled) {
            [self.navigationController setToolbarHidden:NO];
            
            // Check if we need to customize the toolbar, because running on a device
            // like iPhone X
            if (@available(iOS 11.0, *)) {
                UIWindow *window = UIApplication.sharedApplication.keyWindow;
                CGFloat bottomPadding = window.safeAreaInsets.bottom;
                if (bottomPadding != 0) {
                    
                    [self.navigationController.toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionBottom barMetrics:UIBarMetricsDefault];
                    [self.navigationController.toolbar setShadowImage:[UIImage new] forToolbarPosition:UIBarPositionBottom];
                    self.navigationController.toolbar.translucent = YES;
                    
                    if (self->_bottomBackgroundView) {
                        [self->_bottomBackgroundView removeFromSuperview];
                    }
                    self->_bottomBackgroundView = [UIView new];
                    [self->_bottomBackgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];
                    [self.view addSubview:self->_bottomBackgroundView];

                    if (self->_toolBarView) {
                        [self->_toolBarView removeFromSuperview];
                    }
                    self->_toolBarView = [UIView new];
                    [self->_toolBarView setTranslatesAutoresizingMaskIntoConstraints:NO];
                    [self.view addSubview:self->_toolBarView];
                    

                    NSDictionary *viewsDictionary = @{@"toolBarView" : self->_toolBarView,
                                                      @"bottomBackgroundView" : self->_bottomBackgroundView,
                                                      @"containerView" : self->_containerView};
                    
                    NSMutableArray *constraints_H = [NSMutableArray new];
                    
                    // dock/toolbar leading constraint to safe area guide of superview
                    [constraints_H addObject:[NSLayoutConstraint constraintWithItem:self->_toolBarView
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self->_containerView.safeAreaLayoutGuide
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0
                                                                           constant:0]];
                    
                    // dock/toolbar trailling constraint to safe area guide of superview
                    [constraints_H addObject:[NSLayoutConstraint constraintWithItem:self->_toolBarView
                                                                          attribute:NSLayoutAttributeTrailing
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self->_containerView.safeAreaLayoutGuide
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

                    self->_toolBarHeightConstraint = [NSLayoutConstraint constraintWithItem:self->_toolBarView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:toolBarHeight];
                    [constraints_V addObject: self->_toolBarHeightConstraint];
                    
                    // dock/toolbar top constraint to safe area guide bottom of superview
                    [constraints_V addObject:[NSLayoutConstraint constraintWithItem:self->_toolBarView
                                                                          attribute:NSLayoutAttributeTop
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self->_containerView.safeAreaLayoutGuide
                                                                          attribute:NSLayoutAttributeBottom
                                                                         multiplier:1.0
                                                                           constant:0]];
                    
                    // dock/toolbar bottom constraint to background view top
                    [constraints_V addObject:[NSLayoutConstraint constraintWithItem:self->_toolBarView
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self->_bottomBackgroundView
                                                                          attribute:NSLayoutAttributeTop
                                                                         multiplier:1.0
                                                                           constant:0]];
                    
                    // background view bottom constraint to superview bottom
                    [constraints_V addObject:[NSLayoutConstraint constraintWithItem:self->_bottomBackgroundView
                                                                          attribute:NSLayoutAttributeBottom
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self->_containerView
                                                                          attribute:NSLayoutAttributeBottom
                                                                         multiplier:1.0
                                                                           constant:0]];
                    
                    [self.view addConstraints:constraints_H];
                    [self.view addConstraints:constraints_V];
                    
                    SEBBackgroundTintStyle backgroundTintStyle = (self->statusBarAppearance == mobileStatusBarAppearanceNone | self->statusBarAppearance == mobileStatusBarAppearanceLight |
                                                                  self->statusBarAppearance == mobileStatusBarAppearanceExtendedNoneDark) ? SEBBackgroundTintStyleDark : SEBBackgroundTintStyleLight;

                    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
                        [self addBlurEffectStyle:UIBlurEffectStyleRegular
                                       toBarView:self->_toolBarView
                             backgroundTintStyle:backgroundTintStyle];
                        
                    } else {
                        self->_toolBarView.backgroundColor = [UIColor lightGrayColor];
                    }
                    self->_toolBarView.hidden = false;
                    
                    NSArray *bottomBackgroundViewConstraints_H = [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-0-[bottomBackgroundView]-0-|"
                                                                                                         options: 0
                                                                                                         metrics: nil
                                                                                                           views: viewsDictionary];

                    [self.view addConstraints:bottomBackgroundViewConstraints_H];
                    
                    if (UIAccessibilityIsReduceTransparencyEnabled()) {
                        self->_bottomBackgroundView.backgroundColor = backgroundTintStyle == SEBBackgroundTintStyleDark ? [UIColor blackColor] : [UIColor whiteColor];
                    } else {
                        if (backgroundTintStyle == SEBBackgroundTintStyleDark) {
                            [self addBlurEffectStyle:UIBlurEffectStyleDark
                                           toBarView:self->_bottomBackgroundView
                                 backgroundTintStyle:SEBBackgroundTintStyleNone];
                        } else {
                            [self addBlurEffectStyle:UIBlurEffectStyleExtraLight
                                           toBarView:self->_bottomBackgroundView
                                 backgroundTintStyle:SEBBackgroundTintStyleNone];
                        }
                    }
                    BOOL sideSafeAreaInsets = false;
                    
                    UIWindow *window = UIApplication.sharedApplication.keyWindow;
                    CGFloat leftPadding = window.safeAreaInsets.left;
                    sideSafeAreaInsets = leftPadding != 0;

                    self->_bottomBackgroundView.hidden = sideSafeAreaInsets;
#ifdef DEBUG
                    CGFloat bottomPadding = window.safeAreaInsets.bottom;
                    CGFloat bottomMargin = window.layoutMargins.bottom;
                    CGFloat bottomInset = self.view.superview.safeAreaInsets.bottom;
                    DDLogDebug(@"%f, %f, %f, ", bottomPadding, bottomMargin, bottomInset);
#endif
                }
            }
            
            [self setToolbarItems:self.sebUIController.dockItems];
        } else {
            [self.navigationController setToolbarHidden:YES];
            
            if (self->_bottomBackgroundView) {
                [self->_bottomBackgroundView removeFromSuperview];
            }
            if (self->_toolBarView) {
                [self->_toolBarView removeFromSuperview];
            }
        }
        
        // Show navigation bar if browser toolbar is enabled in settings and populate it with enabled controls
        if (self.sebUIController.browserToolbarEnabled) {
            [self.navigationController setNavigationBarHidden:NO];
        } else {
            [self.navigationController setNavigationBarHidden:YES];
        }
        
        [self adjustBars];
    });
}


- (void) openCloseSliderForNewTab
{
    [self.sideMenuController showLeftViewAnimated:YES completionHandler:^(void) {
        [self.sideMenuController hideLeftViewAnimated];
    }];
}


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
    
    SEBBackgroundTintStyle backgroundTintStyle = (statusBarAppearance == mobileStatusBarAppearanceNone | statusBarAppearance == mobileStatusBarAppearanceLight |
                                                  statusBarAppearance == mobileStatusBarAppearanceExtendedNoneDark) ? SEBBackgroundTintStyleDark : SEBBackgroundTintStyleLight;
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
        
        _statusBarView.hidden = false;
        
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
        _statusBarView.backgroundColor = backgroundTintStyle == SEBBackgroundTintStyleDark ? [UIColor blackColor] : [UIColor whiteColor];
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


- (void) resetSEB
{
    [_browserTabViewController closeAllTabs];
    _examRunning = false;
    
    [NSURLCache.sharedURLCache removeAllCachedResponses];
    
    // Empties all cookies, caches and credential stores, removes disk files, flushes in-progress
    // downloads to disk, and ensures that future requests occur on a new socket
    // if the default value (enabled) for the setting examSessionClearSessionCookies is set
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_examSessionClearSessionCookies"]) {
        [[NSURLSession sharedSession] resetWithCompletionHandler:^{
            // Do something once it's done.
        }];
    }
    
    // Reset settings view controller (so new settings are displayed)
    self.appSettingsViewController = nil;
    
    self.browserController = nil;
    
    _viewDidLayoutSubviewsAlreadyCalled = NO;
}


- (void) conditionallyDownloadAndOpenSEBConfigFromURL:(NSURL *)url
{
    [self closeSettingsBeforeOpeningSEBConfig:url
                            callback:self
                            selector:@selector(downloadSEBConfigFromURL:)];
}


- (void) conditionallyOpenSEBConfigFromData:(NSData *)sebConfigData
{
    [self closeSettingsBeforeOpeningSEBConfig:sebConfigData
                            callback:self
                            selector:@selector(storeNewSEBSettings:)];
}


- (void) conditionallyOpenSEBConfigFromUniversalLink:(NSURL *)universalURL
{
    [self closeSettingsBeforeOpeningSEBConfig:universalURL
                            callback:self.browserController
                            selector:@selector(handleUniversalLink:)];
}


- (void) conditionallyOpenSEBConfigFromMDMServer
{
    [self closeSettingsBeforeOpeningSEBConfig:nil
                            callback:self
                            selector:@selector(handleMDMServerConfig:)];
}


- (void) handleMDMServerConfig:(id)reference
{
    [self readMDMServerConfig];
}


// Close settings if they are open
- (void) closeSettingsBeforeOpeningSEBConfig:(id)sebConfig
                                    callback:(id)callback
                                    selector:(SEL)selector
{
    if (_settingsOpen) {
        // Close settings, but check if settings presented some alert or the share dialog first
        if (self.appSettingsViewController.presentedViewController) {
            [self.appSettingsViewController.presentedViewController dismissViewControllerAnimated:NO completion:^{
                if (self.appSettingsViewController) {
                    [self.appSettingsViewController dismissViewControllerAnimated:NO completion:^{
                        self.appSettingsViewController = nil;
                        self->_settingsOpen = false;
                        [self conditionallyOpenSEBConfig:sebConfig callback:callback selector:selector];
                    }];
                    return;
                }
            }];
            return;
        } else if (self.appSettingsViewController) {
            [self.appSettingsViewController dismissViewControllerAnimated:NO completion:^{
                self.appSettingsViewController = nil;
                self->_settingsOpen = false;
                [self conditionallyOpenSEBConfig:sebConfig callback:callback selector:selector];
            }];
            return;
        }
    }
    [self conditionallyOpenSEBConfig:sebConfig callback:callback selector:selector];
}


// Prepare for downloading SEB config from URL
- (void) conditionallyOpenSEBConfig:(id)sebConfig
                           callback:(id)callback
                           selector:(SEL)selector
{
    if (_startSAMWAlertDisplayed) {
        // Dismiss the Activate SAM alert in case it still was visible
        [_alertController dismissViewControllerAnimated:NO completion:^{
            self->_alertController = nil;
            self->_startSAMWAlertDisplayed = false;
            self->_singleAppModeActivated = false;
            // Set the paused SAM alert displayed flag, because if loading settings
            // fails or is canceled, we need to restart the kiosk mode
            self->_pausedSAMAlertDisplayed = true;
            [self conditionallyOpenSEBConfig:sebConfig
                                    callback:callback
                                    selector:selector];
        }];
        return;
    } else if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:^{
            self->_alertController = nil;
            [self conditionallyOpenSEBConfig:sebConfig
                                    callback:callback
                                    selector:selector];
        }];
        return;
    } else if (_initAssistantOpen) {
        // Check if the initialize settings assistant is open
        [self dismissViewControllerAnimated:YES completion:^{
            self->_initAssistantOpen = false;
            // Reset the finished starting up flag, because if loading settings fails or is canceled,
            // we need to load the webpage
            self->_finishedStartingUp = false;
            [self conditionallyOpenSEBConfig:sebConfig
                                    callback:callback
                                    selector:selector];
        }];
        return;
    } else {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
            // Check if reconfiguring is allowed
            // If a quit password is set (= running in exam session),
            // then check if the reconfigure config file URL matches the setting
            // examSessionReconfigureConfigURL (where the wildcard character '*' can be used)
            BOOL examSession = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length > 0;
            BOOL examSessionReconfigureAllow = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_examSessionReconfigureAllow"];
            BOOL examSessionReconfigureURLMatch = NO;
            if (examSession && examSessionReconfigureAllow) {
                if ([sebConfig isKindOfClass:[NSURL class]]) {
                    NSString *sebConfigURLString = [(NSURL *)sebConfig absoluteString];
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self LIKE %@", [preferences secureStringForKey:@"org_safeexambrowser_SEB_examSessionReconfigureConfigURL"]];
                    examSessionReconfigureURLMatch = [predicate evaluateWithObject:sebConfigURLString];
                }
            }
            // Check if SEB is in exam mode (= quit password is set), but reconfiguring is allowed by setting
            // and the reconfigure config URL mathches the setting
            // or SEB isn't in exam mode, but is running with settings for starting an exam and the
            // reconfigure allow setting isn't set
            if ((examSession && !(examSessionReconfigureAllow && examSessionReconfigureURLMatch)) ||
                (!examSession && NSUserDefaults.userDefaultsPrivate && !examSessionReconfigureAllow)) {
                // If yes, we don't download the .seb file
                _scannedQRCode = false;
                if (_alertController) {
                    [_alertController dismissViewControllerAnimated:NO completion:nil];
                }
                _alertController = [UIAlertController  alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Loading New %@ Settings Not Allowed!", nil), SEBExtraShortAppName]
                                                                        message:[NSString stringWithFormat:NSLocalizedString(@"%@ is already running in exam mode and it is not allowed to interupt this by starting another exam. Finish the exam session and use a quit link or the quit button in SEB before starting another exam.", nil), SEBShortAppName]
                                                                 preferredStyle:UIAlertControllerStyleAlert];
                [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                     style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                         self->_alertController = nil;
                                                                     }]];
                [self.topMostController presentViewController:_alertController animated:NO completion:nil];
                
            } else {
                // Reconfiguring is allowed: Invoke the callback to proceed
                IMP imp = [callback methodForSelector:selector];
                void (*func)(id, SEL, id) = (void *)imp;
                func(callback, selector, sebConfig);
            }
        } else {
            _scannedQRCode = false;
        }
    }
}


- (void) downloadSEBConfigFromURL:(NSURL *)url
{
    // Check URL for additional query string
    startURLQueryParameter = nil;
    NSString *queryString = url.query;
    if (queryString.length > 0) {
        NSArray *additionalQueryStrings = [queryString componentsSeparatedByString:@"?"];
        // There is an additional query string if the full query URL component itself containts
        // a query separator character "?"
        if (additionalQueryStrings.count == 2) {
            // Cache the additional query string for later use
            startURLQueryParameter = additionalQueryStrings.lastObject;
            // Replace the full query string in the download URL with the first query component
            // (which is the actual query of the SEB config download URL)
            queryString = additionalQueryStrings.firstObject;
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
            if (queryString.length == 0) {
                queryString = nil;
            }
            urlComponents.query = queryString;
            url = urlComponents.URL;
        }
    }
    
    NSError *error = nil;
    NSData *sebFileData;
    // Download the .seb file directly into memory (not onto disc like other files)
    if ([url.scheme isEqualToString:SEBProtocolScheme]) {
        // If it's a seb:// URL, we try to download it by http
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        urlComponents.scheme = @"http";
        NSURL *httpURL = urlComponents.URL;
        
        if (!_URLSession) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            _URLSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        }
        _downloadTask = [_URLSession dataTaskWithURL:httpURL
                                   completionHandler:^(NSData *sebFileData, NSURLResponse *response, NSError *error)
                         {
                             if (error) {
                                 // If that didn't work, we try to download it by https
                                 NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
                                 urlComponents.scheme = @"https";
                                 NSURL *httpsURL = urlComponents.URL;
                                 self.downloadTask = [self.URLSession dataTaskWithURL:httpsURL
                                                            completionHandler:^(NSData *sebFileData, NSURLResponse *response, NSError *error)
                                                  {
                                                      // Still couldn't download the .seb file: present an error and abort
                                                      if (error) {
                                                          error = [self.configFileController errorCorruptedSettingsForUnderlyingError:error];
                                                          [self storeNewSEBSettingsSuccessful:error];
                                                      } else {
                                                          [self storeDownloadedData:sebFileData fromURL:url];
                                                      }
                                                  }];
                                 [self.downloadTask resume];
                             } else {
                                 [self storeDownloadedData:sebFileData fromURL:url];
                             }
                         }];
        [_downloadTask resume];
        return;

    } else if ([url.scheme isEqualToString:SEBSSecureProtocolScheme]) {
        // If it's a sebs:// URL, we try to download it by https
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        urlComponents.scheme = @"https";
        NSURL *httpsURL = urlComponents.URL;
        self.downloadTask = [self.URLSession dataTaskWithURL:httpsURL
                                           completionHandler:^(NSData *sebFileData, NSURLResponse *response, NSError *error)
                             {
                                 // Still couldn't download the .seb file: present an error and abort
                                 if (error || !sebFileData) {
                                     // Couldn't download the .seb file: for the case it is a deep link, treat the link
                                     // same as a Universal Link
                                     [self.browserController handleUniversalLink:httpsURL];
                                 } else {
                                     [self storeDownloadedData:sebFileData fromURL:url];
                                 }
                             }];
    } else {
        // We got passed a http(s) URL: Try to download the seb data directly
        self.downloadTask = [self.URLSession dataTaskWithURL:url
                                           completionHandler:^(NSData *sebFileData, NSURLResponse *response, NSError *error)
                             {
                                 if (error || !sebFileData) {
                                     // Check if the URL is in an associated domain
                                     [self storeSEBSettingsDownloadedDirectlySuccessful:error];
                                 } else {
                                     // Directly downloading config file worked:
                                     
                                     // Cache current config URL, as it has to be restored if current URL fails in the end
                                     self->currentConfigPath = [[MyGlobals sharedMyGlobals] currentConfigURL];
                                     
                                     // Store the filename from the URL as current config file name
                                     [[MyGlobals sharedMyGlobals] setCurrentConfigURL:[NSURL URLWithString:url.lastPathComponent]];
                                     [self storeDownloadedData:sebFileData fromURL:url];
                                 }
                             }];
    }
}


- (void) storeDownloadedData:(NSData *)sebFileData fromURL:(NSURL *)url
{
    directlyDownloadedURL = url;
    [self.configFileController storeNewSEBSettings:sebFileData
                                        forEditing:NO
                                          callback:self
                                          selector:@selector(storeSEBSettingsDownloadedDirectlySuccessful:)];
}


- (void) storeSEBSettingsDownloadedDirectlySuccessful:(NSError *)error
{
    if (error) {
        // Check if the URL is in an associated domain
        if ([self.browserController isAssociatedDomain:directlyDownloadedURL]) {
            [self.browserController handleUniversalLink:directlyDownloadedURL];
            return;
        } else {
            if ([directlyDownloadedURL.scheme isEqualToString:SEBSSecureProtocolScheme]) {
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
- (void) storeNewSEBSettings:(NSData *)sebData
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
    DDLogWarn(@"%s: Storing new SEB settings was %@successful", __FUNCTION__, error ? @"not " : @"");
    if (!error) {
        _isReconfiguringToMDMConfig = false;
        _scannedQRCode = false;
        [[NSUserDefaults standardUserDefaults] setSecureString:startURLQueryParameter forKey:@"org_safeexambrowser_startURLQueryParameter"];
        // If we got a valid filename from the opened config file
        // we save this for displaing in InAppSettings
        NSString *newSettingsFilename = [[MyGlobals sharedMyGlobals] currentConfigURL].lastPathComponent.stringByDeletingPathExtension;
        if (newSettingsFilename.length > 0) {
            [[NSUserDefaults standardUserDefaults] setSecureString:newSettingsFilename forKey:@"configFileName"];
        }
        
        [self restartExam:false];
        
    } else {
        
        // if decrypting new settings wasn't successfull, we have to restore the path to the old settings
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:currentConfigPath];
        
        // When reconfiguring from MDM config fails, the SEB session needs to be restarted
        if (_isReconfiguringToMDMConfig) {
            DDLogError(@"%s: Reconfiguring from MDM config failed, restarting SEB session.", __FUNCTION__);
            _isReconfiguringToMDMConfig = false;
            [self restartExam:false];
            
        } else if (_scannedQRCode) {
            DDLogError(@"%s: Reconfiguring from QR code config failed!", __FUNCTION__);
            _scannedQRCode = false;
            if (error.code == SEBErrorNoValidConfigData) {
                error = [NSError errorWithDomain:sebErrorDomain
                                            code:SEBErrorNoValidConfigData
                                        userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Scanning Config QR Code Failed", nil),
                                                   NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:NSLocalizedString(@"No valid %@ config found.", nil), SEBShortAppName],
                                                   NSUnderlyingErrorKey : error}];
            }
            if (_alertController) {
                [_alertController dismissViewControllerAnimated:NO completion:nil];
            }
            NSString *alertMessage = error.localizedRecoverySuggestion;
            alertMessage = [NSString stringWithFormat:@"%@%@%@", alertMessage ? alertMessage : @"", alertMessage ? @"\n" : @"", error.localizedFailureReason];
            _alertController = [UIAlertController alertControllerWithTitle:error.localizedDescription
                                                                       message:alertMessage
                                                                preferredStyle:UIAlertControllerStyleAlert];
            [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                     style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                         self->_alertController = nil;
                                                                         if (!self->_finishedStartingUp) {
                                                                             [self conditionallyStartKioskMode];
                                                                         }
                                                                     }]];
            
            [self.topMostController presentViewController:_alertController animated:NO completion:nil];

        } else if (!_finishedStartingUp || _pausedSAMAlertDisplayed) {
            _pausedSAMAlertDisplayed = false;
            // Continue starting up SEB without resetting settings
            // but user interface might need to be re-initialized
            [self initSEB];
            [self conditionallyStartKioskMode];
        } else {
            [_configFileController showAlertWithError:error];
        }
    }
}


#pragma mark - Start and quit exam session

- (void) startExam {
    NSString *startURLString = [[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    NSURL *startURL = [NSURL URLWithString:startURLString];
    if (startURLString.length == 0 ||
        (([startURL.host hasSuffix:@"safeexambrowser.org"] ||
          [startURL.host hasSuffix:SEBWebsiteShort]) &&
         [startURL.path hasSuffix:@"start"])) {
        // Start URL was set to the default value, show init assistant later
        [self openInitAssistant];
    } else {
        _examRunning = true;
        
        // Load all open web pages from the persistent store and re-create webview(s) for them
        // or if no persisted web pages are available, load the start URL
        [_browserTabViewController loadPersistedOpenWebPages];
        
        currentStartURL = startURLString;
        if (_secureMode) {
            [self.sebLockedViewController addLockedExam:startURLString];
        }
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
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL restart = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_quitURLRestart"];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_quitURLConfirm"]) {
        [self sessionQuitRestartIgnoringQuitPW:restart];
    } else {
        [self sessionQuitRestart:restart];
    }
}


// Quit or restart session without asking for confirmation
- (void) sessionQuitRestart:(BOOL)restart
{
    BOOL quittingClientConfig = ![NSUserDefaults userDefaultsPrivate];
    
    // Are exam settings active and we aren't restarting the exam?
    if (!quittingClientConfig && !restart) {
        // Switch to system's (persisted) UserDefaults
        [NSUserDefaults setUserDefaultsPrivate:NO];
    }
    [self restartExam:true quittingClientConfig:quittingClientConfig
     pasteboardString:nil];
}


// Quit or restart session, but ask user for confirmation first
- (void) sessionQuitRestartIgnoringQuitPW:(BOOL)restart
{
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Quit Session", nil)
                                                            message:NSLocalizedString(@"Are you sure you want to quit this session?", nil)
                                                     preferredStyle:UIAlertControllerStyleAlert];
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Quit", nil)
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                             self->_alertController = nil;
                                                             [self sessionQuitRestart:restart];
                                                         }]];
    
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                             self->_alertController = nil;
                                                             [self.sideMenuController hideLeftViewAnimated];
                                                         }]];
    
    [self.topMostController presentViewController:_alertController animated:NO completion:nil];
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
    [self sessionQuitRestart:NO];
}


// Close all tabs, reset browser and reset kiosk mode
// before re-initializing SEB with new settings and restarting exam
- (void) restartExam:(BOOL)quitting
{
    [self restartExam:quitting quittingClientConfig:NO
     pasteboardString:nil];
}

- (void) restartExam:(BOOL)quitting quittingClientConfig:(BOOL)quittingClientConfig
    pasteboardString:(NSString *)pasteboardString
{
    // Close the left slider view first if it was open
    if (!self.sideMenuController.isLeftViewHidden) {
        [self.sideMenuController hideLeftViewAnimated:YES completionHandler:^{
            [self restartExam:quitting quittingClientConfig:quittingClientConfig pasteboardString:pasteboardString];
        }];
        return;
    }
    
    DDLogError(@"---------- RESTARTING SEB SESSION -------------");
    [self initializeLogger];
    
    // Close browser tabs and reset browser session
    [self resetSEB];
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];

    // We only might need to switch off kiosk mode if it was active in previous settings
    if (_secureMode) {

        // Remove this exam from the list of running exams,
        // otherwise it would be locked next time it is started again
        [self.sebLockedViewController removeLockedExam:currentStartURL];

        // Clear Pasteboard if we don't have to copy the hash keys into it
        if (pasteboardString) {
            pasteboard.string = pasteboardString;
        } else {
            pasteboard.items = @[];
        }

        // Get new setting for running SEB in secure mode
        BOOL oldSecureMode = _secureMode;
        
        // Get new setting for ASAM/AAC enabled
        BOOL oldEnableASAM = _enableASAM;
        
        // Check if we received new settings from an MDM server
        if ([self readMDMServerConfig]) {
            DDLogWarn(@"%s: Received new settings from an MDM server, canceling restarting SEB session for now.", __FUNCTION__);
            return;
        }
        
        // Update kiosk flags according to current settings
        [self updateKioskSettingFlags];

        // If there are one or more difference(s) in active kiosk mode
        // compared to the new kiosk mode settings, also considering:
        // when we're running in SAM mode, it's not relevant if settings for ASAM differ
        // when we're running in ASAM mode, it's not relevant if settings for SAM differ
        // we deactivate the current kiosk mode
        if ((quittingClientConfig && oldSecureMode) ||
            oldSecureMode != _secureMode ||
            (!_singleAppModeActivated && (_ASAMActive != _enableASAM)) ||
            (!_ASAMActive && (_singleAppModeActivated != _allowSAM))) {
            
            // If SAM is active, we display the alert for waiting for it to be switched off
            if (_singleAppModeActivated) {
                if (_lockedViewController) {
                    _lockedViewController.resignActiveLogString = [[NSAttributedString alloc] initWithString:@""];
                }
                if (_alertController) {
                    [_alertController dismissViewControllerAnimated:NO completion:nil];
                }

                _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Waiting For Single App Mode to End", nil)
                                                                        message:NSLocalizedString(@"You will be able to work with other apps after Single App Mode is switched off by your administrator.", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
                _endSAMWAlertDisplayed = true;
                [self.topMostController presentViewController:_alertController animated:NO completion:nil];
                return;
            }
            
            // If ASAM is active, we stop it now and display the alert for restarting session
            if (oldEnableASAM) {
                if (_ASAMActive) {
                    DDLogInfo(@"Requesting to exit Autonomous Single App Mode");
                    UIAccessibilityRequestGuidedAccessSession(false, ^(BOOL didSucceed) {
                        if (didSucceed) {
                            DDLogInfo(@"%s: Exited Autonomous Single App Mode", __FUNCTION__);
                            self->_ASAMActive = false;
                        }
                        else {
                            DDLogError(@"%s: Failed to exit Autonomous Single App Mode", __FUNCTION__);
                        }
                        [self restartExamASAM:quitting && self->_secureMode];
                    });
                } else {
                    [self restartExamASAM:quitting && _secureMode];
                }
            } else {
                // When no kiosk mode was active, then we can just restart SEB with the start URL in local client settings
                [self initSEB];
                [self conditionallyStartKioskMode];
            }
        } else {
            // If kiosk mode settings stay same, we just initialize SEB with new settings and start the exam
            [self initSEB];
            [self startExam];
        }
        
    } else {
        // When no kiosk mode was active, then we can just restart SEB
        // and switch kiosk mode on conditionally according to new settings
        if (pasteboardString) {
            pasteboard.string = pasteboardString;
        }
        [self initSEB];
        [self conditionallyStartKioskMode];
    }
}


- (void) restartExamASAM:(BOOL)quittingASAMtoSAM
{
    if (quittingASAMtoSAM) {
        if (_alertController) {
            [_alertController dismissViewControllerAnimated:NO completion:nil];
        }
        _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Exam Session Finished", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Your device is now unlocked, you can exit SEB using the Home button/indicator.\n\nUse the button below to start another exam session and lock the device again.", nil), SEBShortAppName]
                                                         preferredStyle:UIAlertControllerStyleAlert];
        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Start Another Exam", nil)
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                 self->_alertController = nil;
                                                                 [self initSEB];
                                                                 [self conditionallyStartKioskMode];
                                                             }]];
        [self.topMostController presentViewController:_alertController animated:NO completion:nil];
    } else {
        [self initSEB];
        [self conditionallyStartKioskMode];
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


#pragma mark - Kiosk mode

// Called when the Single App Mode (SAM) status changes
- (void) singleAppModeStatusChanged
{
    if (_finishedStartingUp && _singleAppModeActivated && _ASAMActive == false) {

        // Is the exam already running?
        if (_examRunning) {
            
            // Dismiss the Activate SAM alert in case it still was visible
            [_alertController dismissViewControllerAnimated:NO completion:^{
                self->_alertController = nil;
            }];
            _alertController = nil;
            _startSAMWAlertDisplayed = false;
            
            // Exam running: Check if SAM is switched off
            if (UIAccessibilityIsGuidedAccessEnabled() == false) {
                
                /// SAM is off
                
                // Lock the exam down
                
                // If there wasn't a lockdown covering view openend yet, initialize it
                if (!_sebLocked) {
                    [self openLockdownWindows];
                }
                [_lockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Single App Mode switched off!", nil)] withTime:_didResignActiveTime];

            } else {
                
                /// SAM is on again
                
                // Add log string
                _didBecomeActiveTime = [NSDate date];
                
                [_lockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Single App Mode was switched on again.", nil)] withTime:_didBecomeActiveTime];
                
                // Close unlock windows only if the correct quit/restart password was entered already
                if (_unlockPasswordEntered) {
                    _unlockPasswordEntered = false;
                    [_lockedViewController shouldCloseLockdownWindows];
                }
            }
        } else {
            
            /// Exam is not yet running
            
            // If Single App Mode is switched on
            if (UIAccessibilityIsGuidedAccessEnabled() == true) {
                
                // Dismiss the Activate SAM alert in case it still was visible
                [_alertController dismissViewControllerAnimated:NO completion:nil];
                _alertController = nil;
                _startSAMWAlertDisplayed = false;
                
                // Proceed to exam
                [self startExam];
                
            } else {

                // Dismiss the Waiting for SAM to end alert
                if (_endSAMWAlertDisplayed) {
                    [_alertController dismissViewControllerAnimated:NO completion:^{
                        self->_alertController = nil;
                        self->_endSAMWAlertDisplayed = false;
                        self->_singleAppModeActivated = false;
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
    // Check if running on iOS 11.x earlier than 11.2.5
    if (![self allowediOSVersion]) {
        return;
    }
    
    // Check if running on beta iOS
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSUInteger allowBetaiOSVersion = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowiOSBetaVersionNumber"];
    NSUInteger currentOSMajorVersion = NSProcessInfo.processInfo.operatingSystemVersion.majorVersion;
    if (currentOSMajorVersion > currentStableMajoriOSVersion && //first check if we're running on a beta at all
        (allowBetaiOSVersion == iOSBetaVersionNone || //if no beta allowed, abort
         allowBetaiOSVersion != currentOSMajorVersion))
    { //if allowed, version has to match current iOS
        
        if (_alertController) {
            [_alertController dismissViewControllerAnimated:NO completion:nil];
        }

        _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Running on New iOS Version Not Allowed", nil)
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"Currently it isn't allowed to run %@ on the iOS version installed on this device.", nil), SEBShortAppName]
                                                         preferredStyle:UIAlertControllerStyleAlert];
        if (NSUserDefaults.userDefaultsPrivate) {
            [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                     self->_alertController = nil;
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
        if (_alertController) {
            [_alertController dismissViewControllerAnimated:NO completion:nil];
        }
        _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Running on Current iOS Version Not Allowed", nil)
                                                                message:alertMessageiOSVersion
                                                         preferredStyle:UIAlertControllerStyleAlert];
        if (NSUserDefaults.userDefaultsPrivate) {
            [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                     self->_alertController = nil;
                                                                     [[NSNotificationCenter defaultCenter]
                                                                      postNotificationName:@"requestQuit" object:self];
                                                                 }]];
        }
        [self.topMostController presentViewController:_alertController animated:NO completion:nil];
        return;
    }

    _finishedStartingUp = true;
    
    // Update kiosk flags according to current settings
    [self updateKioskSettingFlags];
    
    if (_secureMode) {
        // Clear Pasteboard
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.items = @[];
    }
    
    // If ASAM is enabled and SAM not allowed, we have to check if SAM or Guided Access is
    // already active and deny starting a secured exam until Guided Access is switched off
    if (_enableASAM && !_allowSAM) {
        // Get time of app launch
        dispatch_time_t dispatchTimeAppLaunched = _appDelegate.dispatchTimeAppLaunched;
        if (dispatchTimeAppLaunched != 0) {
            // Wait at least 2 seconds after app launch
            dispatch_after(dispatch_time(dispatchTimeAppLaunched, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self->_appDelegate.dispatchTimeAppLaunched = 0;
                // Is SAM/Guided Access (or ASAM because of previous crash) active?
                [self assureSAMNotActive];
            });
        } else {
            [self assureSAMNotActive];
        }
    } else {
        _appDelegate.dispatchTimeAppLaunched = 0;
        [self conditionallyStartASAM];
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

}

// Is SAM/Guided Access (or ASAM because of previous crash) active?
- (void) assureSAMNotActive
{
    _SAMActive = UIAccessibilityIsGuidedAccessEnabled();
    DDLogWarn(@"%s: Single App Mode is %@active at least 2 seconds after app launch.", __FUNCTION__, _SAMActive ? @"" : @"not ");
    if (_SAMActive) {
        // SAM or Guided Access (or ASAM because of previous crash) is already active:
        // refuse starting a secured exam until SAM/Guided Access is switched off
        ASAMActiveChecked = false;
        [self requestDisablingSAM];
    } else {
        [self conditionallyStartASAM];
    }
}


// SAM or Guided Access (or ASAM because of previous crash) is already active:
// refuse starting a secured exam until SAM/Guided Access is switched off
- (void) requestDisablingSAM
{
    // Is SAM/Guided Access (or ASAM because of previous crash) still active?
    _SAMActive = UIAccessibilityIsGuidedAccessEnabled();
    if (_SAMActive) {
        if (!ASAMActiveChecked) {
            // First try to switch off ASAM in case it was active because of a previously happend crash
            UIAccessibilityRequestGuidedAccessSession(false, ^(BOOL didSucceed) {
                self->ASAMActiveChecked = true;
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
            // If ASAM is enabled and SAM not allowed, we have to deny starting a secured exam
            // until Guided Access/SAM is switched off
            if (_enableASAM && !_allowSAM) {
                // Warn user that SAM/Guided Access must first be switched off
                if (_alertController) {
                    [_alertController dismissViewControllerAnimated:NO completion:nil];
                }
                _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Single App Mode/Guided Access Not Allowed", nil)
                                                                        message:NSLocalizedString(@"Current settings require that Guided Access or an MDM/Apple Configurator invoked Single App Mode is first switched off before the exam can be started.", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
                [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", nil)
                                                                     style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                         self->_alertController = nil;
                                                                         // Check again if a single app mode is still active
                                                                         [self requestDisablingSAM];
                                                                     }]];
                
                [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                     style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                                         self->_alertController = nil;
                                                                         [[NSNotificationCenter defaultCenter]
                                                                          postNotificationName:@"requestQuit" object:self];
                                                                     }]];
                
                [self.topMostController presentViewController:_alertController animated:NO completion:nil];
            }
        }
    } else {
        // SAM/Guided Access (or ASAM because of previous crash) is no longer active: start ASAM
        [self conditionallyStartASAM];
    }
}


- (void) conditionallyStartASAM
{
    // First check if a quit password is set = run SEB in secure mode
    if (!_secureMode) {
        // If secure mode isn't required, we can proceed to opening start URL
        [self startExam];
    } else if (!_ASAMActive) {
        // Secure mode required, find out which kiosk mode to use
        // Is ASAM enabled in settings?
        if (_enableASAM) {
            DDLogInfo(@"Requesting Autonomous Single App Mode");
            _ASAMActive = true;
            UIAccessibilityRequestGuidedAccessSession(true, ^(BOOL didSucceed) {
                if (didSucceed) {
                    DDLogInfo(@"%s: Entered Autonomous Single App Mode", __FUNCTION__);
                    [self startExam];
                }
                else {
                    DDLogError(@"%s: Failed to enter Autonomous Single App Mode", __FUNCTION__);
                    self->_ASAMActive = false;
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
    DDLogInfo(@"Requesting to exit Autonomous Single App Mode");
    UIAccessibilityRequestGuidedAccessSession(false, ^(BOOL didSucceed) {
        if (didSucceed) {
            DDLogInfo(@"%s: Exited Autonomous Single App Mode", __FUNCTION__);
            self->_ASAMActive = false;
        }
        else {
            DDLogError(@"%s: Failed to exit Autonomous Single App Mode", __FUNCTION__);
        }
    });
}


- (void) showStartSingleAppMode
{
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
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:nil];
    }
    if ([[self.topMostController.presentedViewController superclass] isKindOfClass:[UIAlertController superclass]]) {
        [self.topMostController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    _noSAMAlertDisplayed = true;
    _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"No Kiosk Mode Available", nil)
                                                            message:NSLocalizedString(@"Neither Automatic Assessment Configuration nor (Autonomous) Single App Mode are available on this device or activated in settings. Ask your exam support for an eligible exam environment. Sometimes also restarting the device might help.", nil)
                                                     preferredStyle:UIAlertControllerStyleAlert];
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", nil)
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                             self->_alertController = nil;
                                                             self->_noSAMAlertDisplayed = false;
                                                             [self conditionallyStartKioskMode];
                                                         }]];
    
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                             self->_alertController = nil;
                                                             self->_noSAMAlertDisplayed = false;
                                                             // We didn't actually succeed to switch a kiosk mode on
                                                             self->_secureMode = false;
                                                             [[NSNotificationCenter defaultCenter]
                                                              postNotificationName:@"requestQuit" object:self];
                                                         }]];
    [self.topMostController presentViewController:_alertController animated:NO completion:nil];
}


- (void) showRestartSingleAppMode {
    // First check if a quit password is set
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    if (hashedQuitPassword.length > 0) {
        // A quit password is set in current settings: Ask user to restart Guided Access
        // If Guided Access isn't already on, show alert to switch it on again
        if (UIAccessibilityIsGuidedAccessEnabled() == false) {
            if (_alertController) {
                [_alertController dismissViewControllerAnimated:NO completion:nil];
            }
            _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Waiting for Single App Mode", nil)
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Single App Mode needs to be reactivated before %@ can continue.", nil), SEBShortAppName]
                                                             preferredStyle:UIAlertControllerStyleAlert];
            _singleAppModeActivated = true;
            _startSAMWAlertDisplayed = true;
            [self.topMostController presentViewController:_alertController animated:NO completion:nil];
        }
    } else {
        // If no quit password is defined, then we can initialize SEB with new settings
        // quit and restart the exam / reload the start page directly
        [self initSEB];
        [self startExam];
    }
}


#pragma mark - Lockdown windows

- (void) conditionallyOpenLockdownWindows
{
    if ([self.sebLockedViewController shouldOpenLockdownWindows]) {
        if (_secureMode) {
            [self openLockdownWindows];
            
            // Add log string for entering a locked exam
            [_lockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Re-opening an exam which was locked before", nil)] withTime:[NSDate date]];
        } else {
            // Add log string for entering a previously locked exam
            [_lockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Re-opening an exam which was locked before, but now doesn't have a quit password set, therefore doesn't run in secure mode.", nil)] withTime:[NSDate date]];
        }
    }
}


- (void) openLockdownWindows
{
    if (!_lockedViewController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        _lockedViewController = [storyboard instantiateViewControllerWithIdentifier:@"SEBLockedView"];
        _lockedViewController.controllerDelegate = self;
    }
    
    if (!_lockedViewController.resignActiveLogString) {
        _lockedViewController.resignActiveLogString = [[NSAttributedString alloc] initWithString:@""];
    }
    // Save current time for information about when Guided Access was switched off
    _didResignActiveTime = [NSDate date];
    DDLogError(@"Single App Mode switched off!");
    
    // Open the lockdown view
    //    [_lockedViewController willMoveToParentViewController:self];
    
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    //    [rootViewController.view addSubview:_lockedViewController.view];
    [rootViewController addChildViewController:_lockedViewController];
    [_lockedViewController didMoveToParentViewController:rootViewController];
    
    _sebLocked = true;
    
    [_lockedViewController didOpenLockdownWindows];
}


- (void) correctPasswordEntered
{
    // If (new) setting don't require a kiosk mode or
    // kiosk mode is already switched on, close lockdown window
    if (!_secureMode || (_secureMode && UIAccessibilityIsGuidedAccessEnabled() == true)) {
        [_lockedViewController shouldCloseLockdownWindows];
    } else {
        // If necessary show the dialog to start SAM again
        [self showRestartSingleAppMode];
    }
}


#pragma mark - Status bar appearance

- (BOOL) prefersStatusBarHidden
{
    return (statusBarAppearance == mobileStatusBarAppearanceNone ||
            statusBarAppearance == mobileStatusBarAppearanceExtendedNoneDark ||
            statusBarAppearance == mobileStatusBarAppearanceExtendedNoneLight);
}


#pragma mark - Toolbar

// Conditionally add back/forward buttons to navigation bar
- (void) showToolbarNavigation:(BOOL)navigationEnabled
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL show = (navigationEnabled &&
                 !(self.sebUIController.dockEnabled &&
                   [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showNavigationButtons"]));

    if (show) {
        // Add back/forward buttons to navigation bar
        toolbarBackButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SEBToolbarNavigateBackIcon"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(goBack)];
        toolbarBackButton.imageInsets = UIEdgeInsetsMake(navigationBarItemsOffset, 0, 0, 0);

        toolbarForwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SEBToolbarNavigateForwardIcon"]
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(goForward)];
        toolbarForwardButton.imageInsets = UIEdgeInsetsMake(navigationBarItemsOffset, 0, 0, 0);
        
        self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:toolbarBackButton, toolbarForwardButton, nil];
        
    } else {
        self.navigationItem.leftBarButtonItems = nil;
    }
}


- (void)setToolbarTitle:(NSString *)title
{
    self.navigationItem.title = title;
    [self.navigationController.navigationBar setTitleVerticalPositionAdjustment:navigationBarItemsOffset
                                                                  forBarMetrics:UIBarMetricsDefault];
}


#pragma mark - SEB Dock and left slider button handler

-(void)leftDrawerButtonPress:(id)sender
{
    [self.sideMenuController showLeftViewAnimated];
}


- (IBAction)backToStart
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
              [self->_browserTabViewController backToStart];
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
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _alertController = [UIAlertController  alertControllerWithTitle:title
                                                            message:message
                                                     preferredStyle:UIAlertControllerStyleAlert];
    [_alertController addAction:[UIAlertAction actionWithTitle:action1Title
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                             self->_alertController = nil;
                                                             action1Handler();
                                                         }]];
    if (action2Title) {
        [_alertController addAction:[UIAlertAction actionWithTitle:action2Title
                                                             style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                                 self->_alertController = nil;
                                                                 action2Handler();
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


- (NSString *)backToStartText
{
    NSString *backToStartText = [[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_restartExamText"];
    if (backToStartText.length == 0) {
        backToStartText = NSLocalizedString(@"Back to Start",nil);
    }
    return backToStartText;
}


- (IBAction)goBack {
    [_browserTabViewController goBack];
    [self.sideMenuController hideLeftViewAnimated];
}


- (IBAction)goForward {
    [_browserTabViewController goForward];
    [self.sideMenuController hideLeftViewAnimated];
}


- (IBAction)reload {
    void (^action1Handler)(void) =
    ^{
        [self->_browserTabViewController reload];
        [self.sideMenuController hideLeftViewAnimated];
    };

    BOOL showReloadWarning = false;
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([MyGlobals sharedMyGlobals].currentWebpageIndexPathRow == 0) {
        // Main browser tab with the exam
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserWindowAllowReload"]) {
            // Cancel if navigation is disabled in exam
            [self.sideMenuController hideLeftViewAnimated];
            return;
        }
        showReloadWarning = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_showReloadWarning"];
    } else {
        // Additional browser tab
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowNavigation"]) {
            // Cancel if navigation is disabled in additional browser tabs
            [self.sideMenuController hideLeftViewAnimated];
            return;
        }
        showReloadWarning = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowShowReloadWarning"];
    }

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


- (void)setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
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
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL showReload = false;
    if (examTab) {
        // Main browser tab with the exam
        showReload = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserWindowAllowReload"];
    } else {
        // Additional browser tab
        showReload = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowAllowReload"];
    }
    [self activateReloadButtons:showReload];
}


// Conditionally add reload button to navigation bar or
// enable/disable reload buttons in dock and left slider
- (void) activateReloadButtons:(BOOL)reloadEnabled
{
    if (reloadEnabled)  {
        if (self.sebUIController.browserToolbarEnabled &&
            !self.sebUIController.dockReloadButton) {
            // Add reload button to navigation bar
            toolbarReloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SEBToolbarReloadIcon"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(reload)];
            
            toolbarReloadButton.imageInsets = UIEdgeInsetsMake(navigationBarItemsOffset, 0, 0, 0);
            self.navigationItem.rightBarButtonItem = toolbarReloadButton;
        }
    } else {
        // Deactivate reload button in toolbar
        self.navigationItem.rightBarButtonItem = nil;
    }
    // Activate/Deactivate reload buttons in dock and slider
    [self.sebUIController activateReloadButtons:reloadEnabled];
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
         textField.text = username;
     }];
    
    [_alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = NSLocalizedString(@"Password", nil);
         textField.secureTextEntry = YES;
         if (@available(iOS 11.0, *)) {
             textField.textContentType = UITextContentTypePassword;
         }
     }];
    
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Log In", nil)
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                             NSString *username = self->_alertController.textFields[0].text;
                                                             NSString *password = self->_alertController.textFields[1].text;
                                                             self->_alertController = nil;
                                                             IMP imp = [modalDelegate methodForSelector:didEndSelector];
                                                             void (*func)(id, SEL, NSString*, NSString*, NSInteger) = (void *)imp;
                                                             func(modalDelegate, didEndSelector, username, password, SEBEnterPasswordOK);
                                                         }]];
    
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                                             NSString *username = self->_alertController.textFields[0].text;
                                                             NSString *password = self->_alertController.textFields[1].text;
                                                             self->_alertController = nil;
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


- (NSString *) showURLplaceholderTitleForWebpage
{
    NSString *placeholderString = nil;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([MyGlobals sharedMyGlobals].currentWebpageIndexPathRow == 0) {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowShowURL"] <= browserWindowShowURLOnlyLoadError) {
            placeholderString = NSLocalizedString(@"the exam page", nil);
        }
    } else {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowShowURL"] <= browserWindowShowURLOnlyLoadError) {
            placeholderString = NSLocalizedString(@"the webpage", nil);
        }
    }
    return placeholderString;
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


#pragma mark - Search

- (void)searchStarted
{
    [self.sideMenuController hideLeftViewAnimated];
    
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    
    UIBarButtonItem *cancelSearchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(searchButtonCancel:)];
    
    UIBarButtonItem *padding = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    [padding setWidth:13];
    
    [self.navigationItem setRightBarButtonItems:
     [NSArray arrayWithObjects:cancelSearchButton, padding, nil] animated:YES];
}


- (void)searchButtonCancel:(id)sender
{
    [_searchBarViewController cancelButtonPressed];
}


- (void)searchStopped
{
    [self.navigationItem setLeftBarButtonItem:leftButton animated:YES];
    
    //    [_navigationItem setRightBarButtonItems:[NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPageButton:)]] animated:YES];
}


- (void)searchGoSearchString:(NSString *)searchString
{
    [self searchStopped];
    [_browserTabViewController loadWebPageOrSearchResultWithString:searchString];
}


#pragma mark - Memory warning delegate methods

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
