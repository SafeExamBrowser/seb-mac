//
//  AppDelegate.m
//  SEB
//
//  Created by Daniel R. Schneider on 10/09/15.
//
//

#import "AppDelegate.h"
//#import "NSUserDefaults+SEBEncryptedUserDefaults.h"

@interface AppDelegate ()
{
}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // Preloads keyboard so there's no lag on initial keyboard appearance.
    UITextField *lagFreeField = [[UITextField alloc] init];
    [self.window addSubview:lagFreeField];
    [lagFreeField becomeFirstResponder];
    [lagFreeField resignFirstResponder];
    [lagFreeField removeFromSuperview];

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    [preferences setSEBDefaults];
    
//    // Initialize file logger if it's enabled in settings
//    [self initializeLogger];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(guidedAccessChanged) name:UIAccessibilityGuidedAccessStatusDidChangeNotification object:nil];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


// Called when the Guided Access status changes
- (void) guidedAccessChanged
{
    // Is the exam already running?
    if (self.examRunning) {
        
        // Exam running: Check if Guided Access was switched off
        if (UIAccessibilityIsGuidedAccessEnabled() == false) {
            
            // Dismiss the Guided Access warning alert if it still was visible
            self.sebViewController = (SEBViewController*)self.window.rootViewController;
            if (self.sebViewController.alertController) {
                [self.sebViewController dissmissGuidedAccessAlert];
            }

            // If there wasn't a lockdown covering view openend yet, initialize it
            if (!self.coveringView) {
                
                UIView *parentView = self.window.subviews[0];
                
                if (!self.lockedViewController) {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                    self.lockedViewController = [storyboard instantiateViewControllerWithIdentifier:@"SEBLockedView"];
                    self.lockedViewController.controllerDelegate = self;
                }
                
                if (!self.lockedViewController.resignActiveLogString) {
                    self.lockedViewController.resignActiveLogString = [[NSAttributedString alloc] initWithString:@""];
                }
                // Save current time for information about when Guided Access was switched off
                self.didResignActiveTime = [NSDate date];
                DDLogError(@"Guided Accesss switched off!");

                // Open the lockdown view
                [self.lockedViewController willMoveToParentViewController:self.sebViewController];
                [parentView addSubview:self.lockedViewController.view];
                [self.sebViewController addChildViewController:self.lockedViewController];
                [self.lockedViewController didMoveToParentViewController:self.sebViewController];
                
                // Add log string for resign active
                [self.lockedViewController appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Guided Access was switched off!", nil)] withTime:self.didResignActiveTime];
            }
        }
    } else {
        // Exam is not yet running, was Guided Access switched on?
        if (UIAccessibilityIsGuidedAccessEnabled() == true) {
            
            // Yes, close the notification alert about how to switch Guided Access on
            self.sebViewController = (SEBViewController*)self.window.rootViewController;

            [self.sebViewController dissmissGuidedAccessAlert];
            
            self.examRunning = true;
        }
    }
}


#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "org.safeexambrowser.SEB" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
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
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
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
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
