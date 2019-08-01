//
//  AppDelegate.m
//  SEB
//
//  Created by Daniel R. Schneider on 10/09/15.
//  Copyright (c) 2010-2019 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2019 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "AppDelegate.h"

#import "SEBMasterViewController.h"

#import "LGSideMenuController.h"
#import "UIViewController+LGSideMenuController.h"

#import "SEBBrowserController.h"
#import "SEBFilteredURLCache.h"

#import <AVFoundation/AVFoundation.h>


@implementation AppDelegate

@synthesize persistentWebpages;

void run_block_on_ui_thread(dispatch_block_t block)
{
    if ([NSThread isMainThread])
        block();
    else
        dispatch_sync(dispatch_get_main_queue(), block);
}

- (SEBUIController *)sebUIController {
    if (!_sebUIController) {
        _sebUIController = [[SEBUIController alloc] init];
    }
    return _sebUIController;
}


#pragma mark - UIApplicationDelegate methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    DDLogWarn(@"%s", __FUNCTION__);
    BOOL shouldPerformAdditionalDelegateHandling = true;

    // Initialize console loggers
#ifdef DEBUG
    // We show log messages only in Console.app and the Xcode console in debug mode
    [DDLog addLogger:[DDOSLogger sharedInstance]];
#endif

    [self initializeTemporaryLogger];

    // Check if Single App Mode is active
    // or Autonomous Single App Mode stayed active because
    // SEB crashed before and was automatically restarted
    // Apple recommends to wait 2 seconds before using UIAccessibilityIsGuidedAccessEnabled(),
    // so we save current time and to another check later
    _dispatchTimeAppLaunched = dispatch_time(DISPATCH_TIME_NOW, 0);
    _SAMActive = UIAccessibilityIsGuidedAccessEnabled();
    DDLogWarn(@"%s: Single App Mode was %@active at app launch.", __FUNCTION__, _SAMActive ? @"" : @"not ");
    
    // Preloads keyboard so there's no lag on initial keyboard appearance.
    UITextField *lagFreeField = [[UITextField alloc] init];
    [self.window addSubview:lagFreeField];
    [lagFreeField becomeFirstResponder];
    [lagFreeField resignFirstResponder];
    [lagFreeField removeFromSuperview];
    
    // Sets audio session category to "playback" for enabling proper sound output
    // when playing a video in the webview
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *setCategoryError = nil;
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    if (!success) {
        DDLogError(@"Couldn't set AVAudioSession category to playback %@!", setCategoryError);
    }

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences setSEBDefaults]) {
        DDLogInfo(@"SEB was started the first time, UserDefaults were empty.");
    }

    // Get default WebKit browser User Agent and create
    // default SEB User Agent
    NSString *defaultUserAgent = [[UIWebView new] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
    [[SEBBrowserController new] createSEBUserAgentFromDefaultAgent:defaultUserAgent];
    
    [_window makeKeyAndVisible];
    
    // The registration domain is volatile.  It does not persist across launches.
    // You must register your defaults at each launch; otherwise you will get
    // (system) default values when accessing the values of preferences the
    // user (via the Settings app) or your app (via set*:forKey:) has not
    // modified.  Registering a set of default values ensures that your app always
    // has a known good set of values to operate on.
    [self populateRegistrationDomain];
    
    // Load our preferences.  Preloading the relevant preferences here will
    // prevent possible diskIO latency from stalling our code in more time
    // critical areas, such as tableView:cellForRowAtIndexPath:, where the
    // values associated with these preferences are actually needed.
    [self onDefaultsChanged:nil];
    
    // If SEB was launched by invoking a shortcut, display its information and take the appropriate action
    UIApplicationShortcutItem *shortcutItem = [launchOptions objectForKeyedSubscript:UIApplicationLaunchOptionsShortcutItemKey];
    
    // If SEB was launched by invoking a shortcut, display its information and take the appropriate action
    if (shortcutItem)
    {
        DDLogInfo(@"Launched with shortcut item: %@", shortcutItem);
        
        _shortcutItemAtLaunch = shortcutItem;
        
        // This will block "performActionForShortcutItem:completionHandler" from being called.
        shouldPerformAdditionalDelegateHandling = false;
    }
    
    NSString *path = @"CustomURLCache";

    NSUInteger diskCapacity = 20*1024*1024;
    NSUInteger memoryCapacity = 512*1024;
    
    SEBFilteredURLCache *cache = [[SEBFilteredURLCache alloc] initWithMemoryCapacity:memoryCapacity
                                                                        diskCapacity:diskCapacity
                                                                            diskPath:path];
    [NSURLCache setSharedURLCache:cache];

    // If SEB was launched by invoking a shortcut, display its information and take the appropriate action
    NSDictionary *userActivity = [launchOptions objectForKey:UIApplicationLaunchOptionsUserActivityDictionaryKey];
    if (userActivity) {
        if ([[userActivity objectForKey:UIApplicationLaunchOptionsUserActivityTypeKey] isEqualToString:NSUserActivityTypeBrowsingWeb]) {
            _openedUniversalLink = YES;
        }
    }

    return shouldPerformAdditionalDelegateHandling;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    DDLogWarn(@"%s", __FUNCTION__);
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    DDLogWarn(@"%s", __FUNCTION__);
    if (_sebViewController.noSAMAlertDisplayed || _sebViewController.startSAMWAlertDisplayed) {
        [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
        _sebViewController.alertController = nil;
        _sebViewController.noSAMAlertDisplayed = false;
        _sebViewController.startSAMWAlertDisplayed = false;
        // We didn't actually succeed to switch a kiosk mode on
        _sebViewController.secureMode = false;
        _sebViewController.singleAppModeActivated = false;
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestQuit" object:self];

    }
    if (_sebViewController.aboutSEBViewDisplayed && !_sebViewController.mailViewController && !_sebViewController.alertController) {
        [_sebViewController.aboutSEBViewController dismissViewControllerAnimated:NO completion:^{
            self->_sebViewController.aboutSEBViewDisplayed = false;
            self->_sebViewController.aboutSEBViewController = nil;
        }];
    }
    if (_sebViewController.visibleCodeReaderViewController) {
        [_sebViewController.visibleCodeReaderViewController dismissViewControllerAnimated:NO completion:^{
            self->_sebViewController.visibleCodeReaderViewController = nil;
        }];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    DDLogWarn(@"%s", __FUNCTION__);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    DDLogWarn(@"%s", __FUNCTION__);

    // Update UserDefaults as settings might have been changed in the settings app
    [self populateRegistrationDomain];
    if (_sebViewController && !_sebViewController.mailViewController) {
        // If the main SEB view controller was already instantiated

        // Check if we received a new configuration from an MDM server (by MDM managed configuration)
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        if ([preferences boolForKey:@"allowEditingConfig"]) {
            [preferences setBool:NO forKey:@"allowEditingConfig"];
            [_sebViewController conditionallyShowSettingsModal];
        } else if ([preferences boolForKey:@"initiateResetConfig"]) {
            [_sebViewController conditionallyResetSettings];
        } else {
            NSDictionary *serverConfig = [preferences dictionaryForKey:kConfigurationKey];
            if (serverConfig) {
                DDLogWarn(@"%s: Received MDM Managed Configuration, dictionary was present when app did become active.", __FUNCTION__);
                [_sebViewController conditionallyOpenSEBConfigFromMDMServer];
            }
        }
    }
}


- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    DDLogError(@"%s", __FUNCTION__);
    [NSURLCache.sharedURLCache removeAllCachedResponses];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground
    DDLogError(@"%s", __FUNCTION__);

    [NSURLCache.sharedURLCache removeAllCachedResponses];

    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(nonnull NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    DDLogWarn(@"%s", __FUNCTION__);
    DDLogInfo(@"URL scheme:%@", [url scheme]);
    DDLogInfo(@"URL query: %@", [url query]);
    
    if (url) {
        DDLogInfo(@"Get URL event: Loading .seb settings file with URL %@", url);
        _openedURL = true;
        
        // Is the main SEB view controller already instantiated?
        if (_sebViewController && !_sebViewController.mailViewController) {
            [_sebViewController conditionallyDownloadAndOpenSEBConfigFromURL:url];
        } else {
            // Postpone loading .seb file until app did finish launching
            _sebFileURL = url;
        }
    }

    return YES;
}


- (void)application:(UIApplication *)application
performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
  completionHandler:(void (^)(BOOL succeeded))completionHandler;
{
    DDLogWarn(@"%s", __FUNCTION__);
    DDLogInfo(@"%s: shortcut item %@", __FUNCTION__, shortcutItem.type);
    
    // Is the main SEB view controller already instantiated?
    if (_sebViewController && !_sebViewController.mailViewController) {
        // Only handle shortcut if Settings aren't open
        if (!_sebViewController.settingsOpen) {
            BOOL handled = [_sebViewController handleShortcutItem:shortcutItem];
            completionHandler(handled);
        }
    }
}


- (BOOL) application:(UIApplication *)application
continueUserActivity:(nonnull NSUserActivity *)userActivity
// Xcode 9:  restorationHandler:(nonnull void (^)(NSArray * _Nullable))restorationHandler
  restorationHandler:(nonnull void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    DDLogWarn(@"%s", __FUNCTION__);
    NSURL *openedURL = [self getURLForUserActivity:userActivity];
    _openedURL = true;

    // Is the main SEB view controller already instantiated?
    if (_sebViewController && !_sebViewController.mailViewController) {
        [_sebViewController conditionallyOpenSEBConfigFromUniversalLink:openedURL];
    } else {
        // Postpone loading Universal Link until app did finish launching
        _universalURL = openedURL;
    }
    
    return YES;
}


// Initializes a temporary logger unconditionally with the Debug log level
// and the standard log file path, so SEB can log startup events before
// settings are initialized
- (void) initializeTemporaryLogger
{
    DDLogFileManagerDefault* logFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory:nil];
    _myLogger = [[DDFileLogger alloc] initWithLogFileManager:logFileManager];
    _myLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    _myLogger.logFileManager.maximumNumberOfLogFiles = 7; // keep logs for 7 days
    [DDLog addLogger:_myLogger];
    
    DDLogError(@"---------- STARTING UP SEB - INITIALIZE SETTINGS -------------");
    DDLogError(@"(log after start up is finished may continue in another file, according to current settings)");
//    NSString *localHostname = (NSString *)CFBridgingRelease(SCDynamicStoreCopyLocalHostName(NULL));
//    NSString *computerName = (NSString *)CFBridgingRelease(SCDynamicStoreCopyComputerName(NULL, NULL));
    NSString *userName = NSUserName();
    NSString *fullUserName = NSFullUserName();
    NSString *displayName = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleDisplayName"];
    NSString *versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"];
    NSString *bundleID = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleIdentifier"];
    NSString *bundleExecutable = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleExecutable"];
    DDLogError(@"%@ Version %@ (Build %@)", displayName, versionString, buildNumber);
    DDLogError(@"Bundle ID: %@, executable: %@", bundleID, bundleExecutable);
    
//    DDLogInfo(@"Local hostname: %@", localHostname);
//    DDLogInfo(@"Computer name: %@", computerName);
    DDLogInfo(@"User name: %@", userName);
    DDLogInfo(@"Full user name: %@", fullUserName);
}


- (NSURL *)getURLForUserActivity:(NSUserActivity *)userActivity
{
    NSURL *url = nil;
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        url = userActivity.webpageURL;
    }
    return url;
}


// Block custom keyboards
- (BOOL)application:(UIApplication *)application shouldAllowExtensionPointIdentifier:(NSString *)extensionPointIdentifier {
    if ([extensionPointIdentifier isEqualToString: UIApplicationKeyboardExtensionPointIdentifier]) {
        return NO;
    }
    // Currently, the keyboard extension is the only one that can
    // be disallowed, but we will disallow all other types too
    return NO;
}


- (void)onDefaultsChanged:(NSNotification*)aNotification
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}


// -------------------------------------------------------------------------------
//	populateRegistrationDomain
//  Locates the file representing the root page of the settings for this app,
//  invokes loadDefaults:fromSettingsPage:inSettingsBundleAtURL: on it,
//  and registers the loaded values as the app's defaults.
// -------------------------------------------------------------------------------
- (void)populateRegistrationDomain
{
    NSURL *settingsBundleURL = [[NSBundle mainBundle] URLForResource:@"Settings" withExtension:@"bundle"];
    
    // loadDefaults:fromSettingsPage:inSettingsBundleAtURL: expects its caller
    // to pass it an initialized NSMutableDictionary.
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    
    // Invoke loadDefaults:fromSettingsPage:inSettingsBundleAtURL: on the property
    // list file for the root settings page (always named Root.plist).
    [self loadDefaults:appDefaults fromSettingsPage:@"Root.plist" inSettingsBundleAtURL:settingsBundleURL];
    
    // Set defaults which cannot be changed in the settings
//    [appDefaults setObject:[NSNumber numberWithInt:locatingModeHeading] forKey:tmapLocatingMode];
    
    // appDefaults is now populated with the preferences and their default values.
    // Add these to the registration domain.
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    
    [standardDefaults registerDefaults:appDefaults];
    [standardDefaults synchronize];
    
}

// -------------------------------------------------------------------------------
//	loadDefaults:fromSettingsPage:inSettingsBundleAtURL:
//  Helper function that parses a Settings page file, extracts each preference
//  defined within along with its default value, and adds it to a mutable
//  dictionary.  If the page contains a 'Child Pane Element', this method will
//  recurs on the referenced page file.
// -------------------------------------------------------------------------------
- (void)loadDefaults:(NSMutableDictionary*)appDefaults fromSettingsPage:(NSString*)plistName inSettingsBundleAtURL:(NSURL*)settingsBundleURL
{
    // Each page of settings is represented by a property-list file that follows
    // the Settings Application Schema:
    // <https://developer.apple.com/library/ios/#documentation/PreferenceSettings/Conceptual/SettingsApplicationSchemaReference/Introduction/Introduction.html>.
    
    // Create an NSDictionary from the plist file.
    NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfURL:[settingsBundleURL URLByAppendingPathComponent:plistName]];
    
    // The elements defined in a settings page are contained within an array
    // that is associated with the root-level PreferenceSpecifiers key.
    NSArray *prefSpecifierArray = [settingsDict objectForKey:@"PreferenceSpecifiers"];
    
    for (NSDictionary *prefItem in prefSpecifierArray)
        // Each element is itself a dictionary.
    {
        // What kind of control is used to represent the preference element in the
        // Settings app.
        NSString *prefItemType = prefItem[@"Type"];
        // How this preference element maps to the defaults database for the app.
        NSString *prefItemKey = prefItem[@"Key"];
        // The default value for the preference key.
        NSString *prefItemDefaultValue = prefItem[@"DefaultValue"];
        
        if ([prefItemType isEqualToString:@"PSChildPaneSpecifier"])
            // If this is a 'Child Pane Element'.  That is, a reference to another
            // page.
        {
            // There must be a value associated with the 'File' key in this preference
            // element's dictionary.  Its value is the name of the plist file in the
            // Settings bundle for the referenced page.
            NSString *prefItemFile = prefItem[@"File"];
            
            // Recurs on the referenced page.
            [self loadDefaults:appDefaults fromSettingsPage:prefItemFile inSettingsBundleAtURL:settingsBundleURL];
        }
        else if (prefItemKey != nil && prefItemDefaultValue != nil)
            // Some elements, such as 'Group' or 'Text Field' elements do not contain
            // a key and default value.  Skip those.
        {
            [appDefaults setObject:prefItemDefaultValue forKey:prefItemKey];
        }
    }
}


// This mutable array holds a copy of the persistent webpages in the CoreData context for caching
- (NSMutableArray *) persistentWebpages
{
    if (_persistentWebpages == nil) {
        _persistentWebpages = [NSMutableArray new];
    }
    return _persistentWebpages;
}


- (void) setPersistentWebpages:(NSMutableArray *)newPersistentWebpages
{
    _persistentWebpages = newPersistentWebpages;
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "org.safeexambrowser.SEB" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"SEB" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SEB.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            DDLogError(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
