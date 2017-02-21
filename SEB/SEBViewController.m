    //
//  SEBViewController.m
//
//  Created by Daniel R. Schneider on 10/09/15.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich,
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

#import <WebKit/WebKit.h>
#import "Constants.h"
#import "RNCryptor.h"
#import "SEBCryptor.h"
#import "SEBSliderItem.h"
#import "SEBIASKSecureSettingsStore.h"
#import "IASKSettingsReader.h"

#import "SEBViewController.h"

@interface SEBViewController () <WKNavigationDelegate, IASKSettingsDelegate>
{
    NSURL *currentConfigPath;
    UIBarButtonItem *leftButton;
    UIBarButtonItem *settingsShareButton;
    
    @private
    NSInteger attempts;
    BOOL adminPasswordPlaceholder;
    BOOL quitPasswordPlaceholder;
}

@property (weak) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerTopContraint;
@property (copy) NSURLRequest *request;

@end

static NSMutableSet *browserWindowControllers;

@implementation SEBViewController

@synthesize appSettingsViewController;


#pragma mark - Initializing

- (IASKAppSettingsViewController*)appSettingsViewController {
    if (!appSettingsViewController) {
        appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
        appSettingsViewController.delegate = self;
        SEBIASKSecureSettingsStore *sebSecureStore = [[SEBIASKSecureSettingsStore alloc] init];
        appSettingsViewController.settingsStore = sebSecureStore;
    }
    return appSettingsViewController;
}


- (SEBiOSConfigFileController*)configFileController
{
    if (!_configFileController) {
        _configFileController = [[SEBiOSConfigFileController alloc] init];
        _configFileController.sebViewController = self;
    }
    return _configFileController;
}


+ (WKWebViewConfiguration *)defaultWebViewConfiguration
{
    static WKWebViewConfiguration *configuration;
    
    if (!configuration) {
        configuration = [[WKWebViewConfiguration alloc] init];
    }
    
    return configuration;
}


#pragma mark - View management delegate methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.sebViewController = self;
    
    _browserTabViewController = self.childViewControllers[0];
    _browserTabViewController.sebViewController = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(guidedAccessChanged)
                                                 name:UIAccessibilityGuidedAccessStatusDidChangeNotification object:nil];
    
    // Add an observer for the request to conditionally quit SEB with asking quit password
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestedQuitWOPwd:)
                                                 name:@"requestQuitWPwdNotification" object:nil];
    
    // Add Notification Center observer to be alerted of any change to NSUserDefaults.
    // Managed app configuration changes pushed down from an MDM server appear in NSUSerDefaults.
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self readDefaultsValues];
                                                  }];
    // Initialize UI and default UI/browser settings
    [self initSEB];
    
    // Was SEB opened by loading a .seb file/using a seb:// link?
    if (appDelegate.sebFileURL) {
        // Yes: Load the .seb file now that the necessary SEB main view controller was loaded
        [self downloadAndOpenSEBConfigFromURL:appDelegate.sebFileURL];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Check if we received new settings from an MDM server
    //    [self readDefaultsValues];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"allowEditingConfig"]) {
        [self conditionallyShowSettingsModal];
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"initiateResetConfig"]) {
        [self conditionallyResetSettings];
    } else {
        [self startAutonomousSingleAppMode];
    }
}


#pragma mark - Handle request to reset settings

- (void)conditionallyResetSettings
{
    // If there is a hashed admin password the user has to enter it before editing settings
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedAdminPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
    
    if (hashedAdminPassword.length == 0) {
        // There is no admin password: Immediately reset settings
        [self resetSettings];
    } else {
        // Allow up to 5 attempts for entering password
        attempts = 5;
        NSString *enterPasswordString = NSLocalizedString(@"You can only reset settings after entering the SEB administrator password:", nil);
        
        // Ask the user to enter the settings password and proceed to the callback method after this happend
        [self.configFileController promptPasswordWithMessageText:enterPasswordString
                                                           title:NSLocalizedString(@"Reset Settings",nil)
                                                        callback:self
                                                        selector:@selector(resetSettingsEnteredAdminPassword:)];
        return;
    }
}

- (void) resetSettingsEnteredAdminPassword:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
        // Reset the setting for initiating the reset
        [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"initiateResetConfig"];
        
        if (!_finishedStartingUp) {
            // Continue starting up SEB without resetting settings
            [self startAutonomousSingleAppMode];
        }
        
        return;
    }
    
    attempts--;
    
    if (![self correctAdminPassword:password]) {
        // wrong password entered, are there still attempts left?
        if (attempts > 0) {
            // Let the user try it again
            NSString *enterPasswordString = NSLocalizedString(@"Wrong password! Try again to enter the current SEB administrator password:",nil);
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.configFileController promptPasswordWithMessageText:enterPasswordString
                                                               title:NSLocalizedString(@"Reset Settings",nil)
                                                            callback:self
                                                            selector:@selector(adminPasswordResetSettings:)];
            return;
            
        } else {
            // Wrong password entered in the last allowed attempts: Stop reading .seb file
            DDLogError(@"%s: Cannot Reset SEB Settings: You didn't enter the correct current SEB administrator password.", __FUNCTION__);
            
            NSString *title = NSLocalizedString(@"Cannot Reset SEB Settings", nil);
            NSString *informativeText = NSLocalizedString(@"You didn't enter the correct SEB administrator password.", nil);
            [self.configFileController showAlertWithTitle:title andText:informativeText];
            
            if (!_finishedStartingUp) {
                // Continue starting up SEB without resetting settings
                [self startAutonomousSingleAppMode];
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
    
    [[NSUserDefaults standardUserDefaults] setBool:false forKey:@"initiateResetConfig"];
    
    // Write just default SEB settings to UserDefaults
    NSDictionary *emptySettings = [NSDictionary dictionary];
    [self.configFileController storeIntoUserDefaults:emptySettings];
    
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:YES];
    
    [self resetSEB];
}


#pragma mark - Handle requests to show in-app settings

- (void)conditionallyShowSettingsModal
{
    // Check if settings are already displayed
    if (!_settingsOpen) {
        // If there is a hashed admin password the user has to enter it before editing settings
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSString *hashedAdminPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
        
        if (hashedAdminPassword.length == 0) {
            // There is no admin password: Just open settings
            [self showSettingsModal];
        } else {
            // Allow up to 5 attempts for entering password
            attempts = 5;
            NSString *enterPasswordString = NSLocalizedString(@"You can only edit settings after entering the SEB administrator password:", nil);
            
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.configFileController promptPasswordWithMessageText:enterPasswordString
                                                               title:NSLocalizedString(@"Edit Settings",nil)
                                                            callback:self
                                                            selector:@selector(enteredAdminPassword:)];
            return;
        }
    }
}


- (void) enteredAdminPassword:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
        // Continue SEB without displaying settings
        [self startAutonomousSingleAppMode];
        return;
    }
    
    attempts--;
    
    if (![self correctAdminPassword:password]) {
        // wrong password entered, are there still attempts left?
        if (attempts > 0) {
            // Let the user try it again
            NSString *enterPasswordString = NSLocalizedString(@"Wrong password! Try again to enter the current SEB administrator password:",nil);
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [self.configFileController promptPasswordWithMessageText:enterPasswordString
                                                               title:NSLocalizedString(@"Edit Settings",nil)
                                                            callback:self
                                                            selector:@selector(adminPasswordSettingsConfiguringClient:)];
            return;
            
        } else {
            // Wrong password entered in the last allowed attempts: Stop reading .seb file
            DDLogError(@"%s: Cannot Edit SEB Settings: You didn't enter the correct current SEB administrator password.", __FUNCTION__);
            
            NSString *title = NSLocalizedString(@"Cannot Edit SEB Settings", nil);
            NSString *informativeText = NSLocalizedString(@"You didn't enter the correct SEB administrator password.", nil);
            [self.configFileController showAlertWithTitle:title andText:informativeText];
            
            // Continue SEB without displaying settings
            [self startAutonomousSingleAppMode];
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
    NSString *hashedAdminPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
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


#pragma mark - Show in-app settings

- (void)showSettingsModal
{
    // Get hashed passwords and put empty or placeholder strings into the password fields in InAppSettings
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
    NSString *placeholder = [self placeholderStringForHashedPassword:hashedPassword];
    [preferences setSecureString:placeholder forKey:@"adminPassword"];
    adminPasswordPlaceholder = true;

    hashedPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    placeholder = [self placeholderStringForHashedPassword:hashedPassword];
    [preferences setSecureString:placeholder forKey:@"quitPassword"];
    quitPasswordPlaceholder = true;
    
    // Dismiss an alert in case one is open
    if (_alertController) {
        [_alertController dismissViewControllerAnimated:NO completion:nil];
    }

    UINavigationController *aNavController = [[UINavigationController alloc] initWithRootViewController:self.appSettingsViewController];
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
    
    [self presentViewController:aNavController animated:YES completion:nil];
}


- (void)inAppSettingsChanged:(NSNotification *)notification
{
    NSArray *changedKeys = [notification.userInfo allKeys];

    if ([changedKeys containsObject:@"adminPassword"]) {
        adminPasswordPlaceholder = false;
    }
    
    if ([changedKeys containsObject:@"quitPassword"]) {
        quitPasswordPlaceholder = false;
    }
}


- (void)shareSettingsAction:(id)sender
{
    NSLog(@"Share settings button pressed");

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Get selected config purpose
    sebConfigPurposes configPurpose = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebConfigPurpose"];
    
    // Get password
    NSString *encryptingPassword;
    // Is there one saved from the currently open config file?
    encryptingPassword = [preferences secureObjectForKey:@"settingsPassword"];
    
    // Encrypt current settings with current credentials
    NSData *encryptedSEBData = [self.configFileController encryptSEBSettingsWithPassword:encryptingPassword passwordIsHash:NO withIdentity:nil forPurpose:configPurpose];
    if (encryptedSEBData) {

        // Get config file name
        NSString *configFileName = [preferences secureObjectForKey:@"configFileName"];
        if (configFileName.length == 0) {
            configFileName = @"SEBConfigFile";
        }

        NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        documentsPath = [documentsPath stringByAppendingPathComponent:configFileName];
        NSString *configFilePath = [documentsPath stringByAppendingPathExtension:configPurpose == sebConfigPurposeManagedConfiguration ? @"plist" : @"seb"];
        NSURL *configFileRUL = [NSURL fileURLWithPath:configFilePath];
        
        [encryptedSEBData writeToURL:configFileRUL atomically:YES];

        NSString *configFilePurpose = (configPurpose == sebConfigPurposeStartingExam ?
                                       NSLocalizedString(@"for starting an exam", nil) :
                                       (configPurpose == sebConfigPurposeConfiguringClient ?
                                       NSLocalizedString(@"for configuring clients", nil) :
                                        NSLocalizedString(@"for Managed Configuration (MDM)", nil)));
        NSArray *activityItems = @[ [NSString stringWithFormat:@"SEB Config File %@", configFilePurpose], configFileRUL ];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];
        activityVC.popoverPresentationController.barButtonItem = settingsShareButton;
        [self.appSettingsViewController presentViewController:activityVC animated:TRUE completion:nil];
    }
}


- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [sender dismissViewControllerAnimated:YES completion:^{
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences setBool:NO forKey:@"allowEditingConfig"];
        
        // Get entered passwords and save their hashes to SEB settings
        // as long as the passwords were really entered and don't contain the hash placeholders
        NSString *password = [preferences secureObjectForKey:@"adminPassword"];
        NSString *hashedPassword = [self sebHashedPassword:password];
        if (!adminPasswordPlaceholder) {
            [preferences setSecureString:hashedPassword forKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
            [preferences setSecureString:@"" forKey:@"adminPassword"];
        }
        
        if (!quitPasswordPlaceholder) {
            password = [preferences secureObjectForKey:@"quitPassword"];
            hashedPassword = [self sebHashedPassword:password];
            [preferences setSecureString:hashedPassword forKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
            [preferences setSecureString:@"" forKey:@"quitPassword"];
        }
        _settingsOpen = false;
        
        // Close all tabs before re-initializing SEB with new settings
        [_browserTabViewController closeAllTabs];
        _examRunning = false;
        
        [self initSEB];
        [self startAutonomousSingleAppMode];
    }];

}


- (void)readDefaultsValues
{
    if (!_isReconfiguring) {
        // Check if we received a new configuration from an MDM server
        NSDictionary *serverConfig = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kConfigurationKey];
        if (serverConfig && !NSUserDefaults.userDefaultsPrivate) {
            _isReconfiguring = true;
            // If we did receive a config and SEB isn't running in exam mode currently
            NSLog(@"%s: Received new configuration from MDM server: %@", __FUNCTION__, serverConfig);
            
            [self.configFileController reconfigueClientWithMDMSettingsDict:serverConfig callback:self selector:@selector(storeNewSEBSettingsSuccessful:)];
        }
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


#pragma mark - Init and reset SEB

- (void) initSEB
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Set up system
    
    // Set preventing Auto-Lock according to settings
    [UIApplication sharedApplication].idleTimerDisabled = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobilePreventAutoLock"];
    
    // Create browser user agent according to settings
    NSString* versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
    NSString *overrideUserAgent;
    
    if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserUserAgentMac"] == browserUserAgentModeMacDefault) {
        overrideUserAgent = [[MyGlobals sharedMyGlobals] valueForKey:@"defaultUserAgent"];
    } else {
        overrideUserAgent = [preferences secureStringForKey:@"org_safeexambrowser_SEB_browserUserAgentMacCustom"];
    }
    // Add "SEB <version number>" to the browser's user agent, so the LMS SEB plugins recognize us
    overrideUserAgent = [overrideUserAgent stringByAppendingString:[NSString stringWithFormat:@" %@/%@", SEBUserAgentDefaultSuffix, versionString]];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:overrideUserAgent, @"UserAgent", nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    
    // UI
    
    // Draw background view for status bar if it is enabled
    if (!_statusBarView) {
        _statusBarView = [UIView new];
        [_statusBarView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:_statusBarView];
        
        NSDictionary *viewsDictionary = @{@"statusBarView" : _statusBarView,
                                          @"containerView" : _containerView};
        
        _containerTopContraint.active = false;
        NSArray *constraints_H = [NSLayoutConstraint constraintsWithVisualFormat: @"H:|-0-[statusBarView]-0-|"
                                                                         options: 0
                                                                         metrics: nil
                                                                           views: viewsDictionary];
        NSArray *constraints_V = [NSLayoutConstraint constraintsWithVisualFormat: @"V:|-0-[statusBarView(==20)]-0-[containerView]"
                                                                         options: 0
                                                                         metrics: nil
                                                                           views: viewsDictionary];
        [self.view addConstraints:constraints_H];
        [self.view addConstraints:constraints_V];
    }
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSUInteger statusBarAppearance = [[NSUserDefaults standardUserDefaults] secureIntegerForKey:@"org_safeexambrowser_SEB_mobileStatusBarAppearance"];
    appDelegate.statusBarAppearance = statusBarAppearance;
    
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"] == false &&
        statusBarAppearance != mobileStatusBarAppearanceNone) {
        // Only draw background for status bar when it is enabled and there is no navigation bar displayed
        
        _statusBarView.backgroundColor = (statusBarAppearance == mobileStatusBarAppearanceLight ? [UIColor blackColor] : [UIColor whiteColor]);
        _statusBarView.hidden = false;
        
    } else {
        _statusBarView.hidden = true;
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    //// Initialize SEB Dock and commands section in the slider view
    
    NSMutableArray *newDockItems = [NSMutableArray new];
    UIBarButtonItem *dockItem;
    UIImage *dockIcon;
    NSMutableArray *sliderCommands = [NSMutableArray new];
    SEBSliderItem *sliderCommandItem;
    UIImage *sliderIcon;
    
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
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showSettingsInApp"]) {
        sliderIcon = [UIImage imageNamed:@"SEBSliderSettingsIcon"];
        sliderCommandItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Edit Settings",nil)
                                                            icon:sliderIcon
                                                          target:self
                                                          action:@selector(conditionallyShowSettingsModal)];
        [sliderCommands addObject:sliderCommandItem];
    }
    
    // Add Restart Exam button if enabled
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamUseStartURL"] ||
        [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamURL"].length > 0) {
        dockIcon = [UIImage imageNamed:@"SEBRestartIcon"];
        
        NSString *restartButtonText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamText"];
        if (restartButtonText.length == 0) {
            restartButtonText = NSLocalizedString(@"Restart Exam",nil);
        }
        dockItem = [[UIBarButtonItem alloc] initWithImage:[dockIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(reload)];
        [newDockItems addObject:dockItem];
        
        dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
        dockItem.width = 0;
        [newDockItems addObject:dockItem];
        
        // Add Restart Exam command to slider items
        sliderIcon = [UIImage imageNamed:@"SEBSliderRestartIcon"];
        sliderCommandItem = [[SEBSliderItem alloc] initWithTitle:restartButtonText
                                                            icon:sliderIcon
                                                          target:self
                                                          action:@selector(reload)];
        [sliderCommands addObject:sliderCommandItem];
    }
    
    // Add Reload button if enabled
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showReloadButton"]) {
        dockIcon = [UIImage imageNamed:@"SEBReloadIcon"];
        dockItem = [[UIBarButtonItem alloc] initWithImage:[dockIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(reload)];
        [newDockItems addObject:dockItem];
        
        dockItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
        dockItem.width = 0;
        [newDockItems addObject:dockItem];
        
        // Add reload page command to slider items
        sliderIcon = [UIImage imageNamed:@"SEBSliderReloadIcon"];
        sliderCommandItem = [[SEBSliderItem alloc] initWithTitle:NSLocalizedString(@"Reload Page",nil)
                                                            icon:sliderIcon
                                                          target:self
                                                          action:@selector(reload)];
        [sliderCommands addObject:sliderCommandItem];
    }
    
    // Add Quit button
    dockIcon = [UIImage imageNamed:@"SEBShutDownIcon"];
    dockItem = [[UIBarButtonItem alloc] initWithImage:[dockIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(quitExamConditionally)];
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
    
    // Register slider commands
    appDelegate.leftSliderCommands = [sliderCommands copy];
    
    // If dock is enabled, register items to the tool bar
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_showTaskBar"]) {
        [self.navigationController setToolbarHidden:NO];
        _dockItems = newDockItems;
        [self setToolbarItems:_dockItems];
    } else {
        [self.navigationController setToolbarHidden:YES];
    }
    
    // Show navigation bar if browser toolbar is enabled in settings and populate it with enabled controls
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"]) {
        [self.navigationController setNavigationBarHidden:NO];
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowBrowsingBackForward"]) {
            // ToDo: Add back/forward buttons to navigation bar
        }
    } else {
        [self.navigationController setNavigationBarHidden:YES];
    }
    
    // Register slider view items
    appDelegate.leftSliderCommands = [sliderCommands copy];
}


- (void) resetSEB
{
    [_browserTabViewController closeAllTabs];
    _examRunning = false;
    
    // Empties all cookies, caches and credential stores, removes disk files, flushes in-progress
    // downloads to disk, and ensures that future requests occur on a new socket.
    [[NSURLSession sharedSession] resetWithCompletionHandler:^{
        // Do something once it's done.
    }];
    
    // Switch to system's (persisted) UserDefaults
    [NSUserDefaults setUserDefaultsPrivate:NO];
    
    [self initSEB];
    [self startAutonomousSingleAppMode];
}


- (void) downloadAndOpenSEBConfigFromURL:(NSURL *)url
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
        // Check if SEB is in exam mode = private UserDefauls are switched on
        if (NSUserDefaults.userDefaultsPrivate) {
            // If yes, we don't download the .seb file
            if (_alertController) {
                [_alertController dismissViewControllerAnimated:NO completion:nil];
            }
            _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Loading New SEB Settings Not Allowed!", nil)
                                                                    message:NSLocalizedString(@"SEB is already running in exam mode and it is not allowed to interupt this by starting another exam. Finish the exam session and use a quit link or the quit button in SEB before starting another exam.", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
            [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                     [_alertController dismissViewControllerAnimated:NO completion:nil];
                                                                 }]];
            [self presentViewController:_alertController animated:YES completion:nil];
            
        } else {
            // SEB isn't in exam mode: reconfiguring is allowed
            NSError *error = nil;
            NSData *sebFileData;
            // Download the .seb file directly into memory (not onto disc like other files)
            if ([url.scheme isEqualToString:@"seb"]) {
                // If it's a seb:// URL, we try to download it by http
                NSURL *httpURL = [[NSURL alloc] initWithScheme:@"http" host:url.host path:url.path];
                sebFileData = [NSData dataWithContentsOfURL:httpURL options:NSDataReadingUncached error:&error];
                if (error) {
                    // If that didn't work, we try to download it by https
                    NSURL *httpsURL = [[NSURL alloc] initWithScheme:@"https" host:url.host path:url.path];
                    sebFileData = [NSData dataWithContentsOfURL:httpsURL options:NSDataReadingUncached error:&error];
                    // Still couldn't download the .seb file: present an error and abort
                    if (error) {
                        //                        [_mainBrowserWindow presentError:error modalForWindow:_mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
                        return;
                    }
                }
            } else if ([url.scheme isEqualToString:@"sebs"]) {
                // If it's a sebs:// URL, we try to download it by https
                NSURL *httpsURL = [[NSURL alloc] initWithScheme:@"https" host:url.host path:url.path];
                sebFileData = [NSData dataWithContentsOfURL:httpsURL options:NSDataReadingUncached error:&error];
                // Couldn't download the .seb file: present an error and abort
                if (error) {
                    //                    [_mainBrowserWindow presentError:error modalForWindow:_mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
                    return;
                }
            } else {
                sebFileData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
                if (error) {
                    //                    [_mainBrowserWindow presentError:error modalForWindow:_mainBrowserWindow delegate:nil didPresentSelector:NULL contextInfo:NULL];
                }
            }
            // Get current config path
            currentConfigPath = [[MyGlobals sharedMyGlobals] currentConfigURL];
            // Store the URL of the .seb file as current config file path
            [[MyGlobals sharedMyGlobals] setCurrentConfigURL:[NSURL URLWithString:url.lastPathComponent]]; // absoluteString]];
            
            [self.configFileController storeNewSEBSettings:sebFileData forEditing:false callback:self selector:@selector(storeNewSEBSettingsSuccessful:)];
        }
    }
}


- (void) storeNewSEBSettingsSuccessful:(BOOL)success
{
    NSLog(@"%s: Storing new SEB settings was %@successful", __FUNCTION__, success ? @"" : @"not ");
    if (success) {
        [_browserTabViewController closeAllTabs];
        _examRunning = false;
        [self initSEB];
        
        _isReconfiguring = false;
        
        [self startAutonomousSingleAppMode];
        
        
        //        // Post a notification that it was requested to restart SEB with changed settings
        //        [[NSNotificationCenter defaultCenter]
        //         postNotificationName:@"requestRestartNotification" object:self];
        
    } else {
        _isReconfiguring = false;
        
        // if decrypting new settings wasn't successfull, we have to restore the path to the old settings
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:currentConfigPath];
    }
}


#pragma mark - Start and quit exam session

- (void) startExam {
    _examRunning = true;
    
    // Load all open web pages from the persistent store and re-create webview(s) for them
    // or if no persisted web pages are available, load the start URL
    [_browserTabViewController loadPersistedOpenWebPages];
}


- (void) quitExamConditionally
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
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
            [self quitExamIgnoringQuitPW];
        }
    }
}


- (void)requestedQuitWOPwd:(NSNotification *)notification
{
    [self quitExamIgnoringQuitPW];
}


// If no quit password is required, then confirm quitting
- (void) quitExamIgnoringQuitPW
{
    _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Quit Session", nil)
                                                            message:NSLocalizedString(@"Are you sure you want to quit this session?", nil)
                                                     preferredStyle:UIAlertControllerStyleAlert];
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Quit", nil)
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                             [_alertController dismissViewControllerAnimated:NO completion:nil];
                                                             [self quitExam];
                                                         }]];
    
    [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                         style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                             [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
                                                             //                                                                     [_alertController dismissViewControllerAnimated:NO completion:nil];
                                                         }]];
    
    [self presentViewController:_alertController animated:YES completion:nil];
}


- (void) enteredQuitPassword:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
        [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
        return;
    }
    
    // Get quit password hash from current client settings
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
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
            [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
            return;
        }
        
    } else {
        // The correct quit password was entered
        [self quitExam];
    }
}


- (void) quitExam
{
    // Close the left slider view if it was open
    [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
    
    // Close browser tabs and reset SEB settings to the local client settings if necessary
    [self resetSEB];
    // Update (because settings might have changed to local client settings)
    // if a quit password is set = run SEB in secure mode
    _secureMode = [[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length > 0;
    
    
    // If ASAM is active, we stop it now and display the alert for restarting session
    if (_ASAMActive) {
        [self stopAutonomousSingleAppMode];
        //        _ASAMActive = false;
        _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Restart Session", nil)
                                                                message:_secureMode ? NSLocalizedString(@"Return to start page and lock device into SEB.", nil) : NSLocalizedString(@"Return to start page.", nil)
                                                         preferredStyle:UIAlertControllerStyleAlert];
        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                             style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                 [_alertController dismissViewControllerAnimated:NO completion:nil];
                                                                 [self startAutonomousSingleAppMode];
                                                             }]];
        [self presentViewController:_alertController animated:YES completion:nil];
    } else if (_guidedAccessActive) {
        if (_lockedViewController) {
            _lockedViewController.resignActiveLogString = [[NSAttributedString alloc] initWithString:@""];
        }
        _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Stop Guided Access", nil)
                                                                message:NSLocalizedString(@"You can now switch off Guided Access by home button triple click or Touch ID.", nil)
                                                         preferredStyle:UIAlertControllerStyleAlert];
        _guidedAccessWarningDisplayed = true;
        [self presentViewController:_alertController animated:YES completion:nil];
    } else {
        // When Guided Access is off, then we can restart SEB with the start URL in local client settings
        [self startExam];
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

// Called when the Guided Access status changes
- (void) guidedAccessChanged
{
    if (_finishedStartingUp && _guidedAccessActive && _ASAMActive == false) {
        // Is the exam already running?
        if (_examRunning) {
            
            // Exam running: Check if Guided Access is switched off
            if (UIAccessibilityIsGuidedAccessEnabled() == false) {
                
                /// Guided Access is off
                
                // Dismiss the Guided Access warning alert if it still was visible
                if (_guidedAccessWarningDisplayed) {
                    [_alertController dismissViewControllerAnimated:NO completion:nil];
                    _alertController = nil;
                    _guidedAccessWarningDisplayed = false;
                }
                
                /// Lock the exam down
                
                // If there wasn't a lockdown covering view openend yet, initialize it
                if (!_sebLocked) {
                    [self openLockdownWindows];
                }
                [_lockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Guided Access switched off!", nil)] withTime:_didResignActiveTime];

            } else {
                
                /// Guided Access is on again
                
                // Add log string
                _didBecomeActiveTime = [NSDate date];
                
                [_alertController dismissViewControllerAnimated:NO completion:nil];
                _alertController = nil;

                [_lockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Guided Access is switched on again.", nil)] withTime:_didBecomeActiveTime];
                
                // Close unlock windows only if the correct quit/restart password was entered already
                if (_unlockPasswordEntered) {
                    _unlockPasswordEntered = false;
//                    [_alertController dismissViewControllerAnimated:NO completion:nil];
//                    _alertController = nil;
                    [_lockedViewController shouldCloseLockdownWindows];
                }
            }
        } else {
            
            /// Exam is not yet running
            
            // If Guided Access switched on
            if (UIAccessibilityIsGuidedAccessEnabled() == true) {
                
                // Proceed to exam
                [self showGuidedAccessWarning];
                
            }
            // Guided Access off
            else if (_guidedAccessWarningDisplayed) {
                // Guided Access warning was already displayed: dismiss it
                [_alertController dismissViewControllerAnimated:NO completion:nil];
                _alertController = nil;
                _guidedAccessWarningDisplayed = false;
                _guidedAccessActive = false;
                [self showRestartGuidedAccess];
            }
        }
    }
}


- (void) startAutonomousSingleAppMode
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    _finishedStartingUp = true;
    
    // First check if a quit password is set = run SEB in secure mode
    _secureMode = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length > 0;
    
    // Is ASAM enabled in current settings?
    _enableASAM = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileEnableASAM"];
    
    // Is ASAM active or any other of the Single App Modes not yet active?
    if (_ASAMActive || UIAccessibilityIsGuidedAccessEnabled() == false) {

        // Is ASAM already active?
        if (_ASAMActive) {
            NSLog(@"Autonomous Single App Mode already active");
            if (!_secureMode || !_enableASAM) {
                [self stopAutonomousSingleAppMode];
            }
            [self startExam];

        } else {
            // ASAM not active
            // Is ASAM enabled in settings?
            if (_secureMode && _enableASAM) {
                NSLog(@"Requesting Autonomous Single App Mode");
                _ASAMActive = true;
                UIAccessibilityRequestGuidedAccessSession(true, ^(BOOL didSucceed) {
                    if (didSucceed) {
                        NSLog(@"Entered Autonomous Single App Mode");
                        [self startExam];
                    }
                    else {
                        NSLog(@"Failed to enter Autonomous Single App Mode");
                        _ASAMActive = false;
                        // Conditionally ask user to start Guided Access
                        [self showStartGuidedAccess];
                    }
                });
            } else {
                [self showStartGuidedAccess];
            }
        }
    } else {
        // Guided Access, SAM or ASAM is already active (maybe because of a crash)
        NSLog(@"Guided Access or ASAM is already active, maybe because of a crash.");
        // Try to switch ASAM off to find out if it was active
        _ASAMActive = true;
        UIAccessibilityRequestGuidedAccessSession(false, ^(BOOL didSucceed) {
            if (didSucceed) {
                NSLog(@"Exited Autonomous Single App Mode");
                _ASAMActive = false;
//                // Restart ASAM properly again
//                [self startAutonomousSingleAppMode];
            }
            else {
                NSLog(@"Failed to exit Autonomous Single App Mode, Guided Access must be active");
                _ASAMActive = false;
            }
        });
    }
}


- (void) stopAutonomousSingleAppMode
{
    NSLog(@"Requesting to exit Autonomous Single App Mode");
    UIAccessibilityRequestGuidedAccessSession(false, ^(BOOL didSucceed) {
        if (didSucceed) {
            NSLog(@"Exited Autonomous Single App Mode");
            _ASAMActive = false;
        }
        else {
            NSLog(@"Failed to exit Autonomous Single App Mode");
        }
    });
}


- (void) showStartGuidedAccess
{
    // Set flag that SEB is initialized: Now showing alerts is allowed
    [[MyGlobals sharedMyGlobals] setFinishedInitializing:YES];

    // First check if a quit password is set
    if (!_secureMode) {
        // No quit password set in current settings: Don't ask user to switch on Guided Access
        // and open an exam portal page or a mock exam (which don't need to be secured)
        _guidedAccessActive = false;
        [self startExam];
    } else {
        // A quit password is set: Ask user to switch on Guided Access (as far as it is allowed in settings)
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_mobileAllowGuidedAccess"]) {
            // Guided Access is allowed
            _guidedAccessActive = true;
            if (UIAccessibilityIsGuidedAccessEnabled() == false) {
                [_alertController dismissViewControllerAnimated:NO completion:nil];
                _startGuidedAccessDisplayed = true;
                _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Start Guided Access", nil)
                                                                        message:NSLocalizedString(@"Enable Guided Access in Settings -> General -> Accessibility and after returning to SEB, triple click home button to proceed to exam.", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
                [self presentViewController:_alertController animated:YES completion:nil];
            }
        } else {
            // Guided Access isn't allowed: SEB refuses to start the exam
            [_alertController dismissViewControllerAnimated:NO completion:nil];
            _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"No Kiosk Mode Available", nil)
                                                                    message:NSLocalizedString(@"Neither (Autonomous) Single App Mode nor manual Guided Access are available on this device or activated in  settings. Ask your exam support for an eligible exam environment.", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
            [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", nil)
                                                                 style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                     [_alertController dismissViewControllerAnimated:NO completion:nil];
                                                                     [self startAutonomousSingleAppMode];
                                                                 }]];

            [self presentViewController:_alertController animated:YES completion:nil];
        }
    }
}


- (void) showRestartGuidedAccess {
    // First check if a quit password is set
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    if (hashedQuitPassword.length > 0) {
        // A quit password is set in current settings: Ask user to restart Guided Access
        // If Guided Access isn't already on, show alert to switch it on again
        if (UIAccessibilityIsGuidedAccessEnabled() == false) {
            _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Restart Guided Access", nil)
                                                                    message:NSLocalizedString(@"Activate Guided Access with triple click home button to return to exam.", nil)
                                                             preferredStyle:UIAlertControllerStyleAlert];
            _guidedAccessActive = true;
            [self presentViewController:_alertController animated:YES completion:nil];
        }
    } else {
        // If no quit password is defined, then we can restart the exam / reload the start page directly
        [self startExam];
    }
}


- (void) showGuidedAccessWarning
{
    // If Guided Access switched on
    if (UIAccessibilityIsGuidedAccessEnabled() == true) {
        // Proceed to exam
        [_alertController dismissViewControllerAnimated:NO completion:nil];
        
        _alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Guided Access Warning", nil)
                                                                          message:NSLocalizedString(@"Don't switch Guided Access off (home button triple click or Touch ID) before submitting your exam, otherwise SEB will lock access to the exam! SEB will notify you when you're allowed to switch Guided Access off.", nil)
                                                                   preferredStyle:UIAlertControllerStyleAlert];
        [_alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"I Understand", nil)
                                                                       style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                           [_alertController dismissViewControllerAnimated:NO completion:nil];
                                                                           _alertController = nil;
                                                                           _guidedAccessWarningDisplayed = false;
                                                                           
                                                                           [self startExam];
        }]];
        _guidedAccessWarningDisplayed = true;
        [self presentViewController:_alertController animated:YES completion:nil];
    }
}


- (void) correctPasswordEntered {
    // If necessary show the dialog to start Guided Access again
    [self showRestartGuidedAccess];

    // If Guided Access is already switched on, close lockdown window
    if (UIAccessibilityIsGuidedAccessEnabled() == true) {
        [_lockedViewController shouldCloseLockdownWindows];
    }
}


#pragma mark - Lockdown windows

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
    DDLogError(@"Guided Accesss switched off!");
    
    // Open the lockdown view
//    [_lockedViewController willMoveToParentViewController:self];
    
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
//    [rootViewController.view addSubview:_lockedViewController.view];
    [rootViewController addChildViewController:_lockedViewController];
    [_lockedViewController didMoveToParentViewController:rootViewController];
    
    _sebLocked = true;
    
    [_lockedViewController didOpenLockdownWindows];
}


- (void) conditionallyOpenLockdownWindows
{
    if ([[SEBLockedViewController new] shouldOpenLockdownWindows]) {
        [self openLockdownWindows];
        
        // Add log string for entering a locked exam
        [_lockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Re-opening an exam which was locked before", nil)] withTime:[NSDate date]];
    }
}


#pragma mark - Status bar appearance

- (BOOL) prefersStatusBarHidden
{
    return ([[NSUserDefaults standardUserDefaults] secureIntegerForKey:@"org_safeexambrowser_SEB_mobileStatusBarAppearance"] == mobileStatusBarAppearanceNone);
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableBrowserWindowToolbar"] == false) {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_mobileStatusBarAppearance"] == mobileStatusBarAppearanceLight) {
            return UIStatusBarStyleLightContent;
        }
    }
    return UIStatusBarStyleDefault;
}


#pragma mark - SEB Dock and left slider button handler

-(void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)goBack:(id)sender {
    [_browserTabViewController goBack];
}

- (IBAction)goForward:(id)sender {
    [_browserTabViewController goForward];
}

- (IBAction)reload {
    [_browserTabViewController reload];
    [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
}


#pragma mark - Search

- (void)searchStarted
{
    [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
    
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
