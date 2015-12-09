//
//  AppDelegate.h
//  SEB
//
//  Created by Daniel R. Schneider on 10/09/15.
//
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "SEBViewController.h"
#import "SEBLockedViewController.h"
#import "SEBiOSLockedViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, SEBLockedViewControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) IBOutlet SEBViewController *sebViewController;
@property (strong, nonatomic) SEBiOSLockedViewController< SEBLockedViewUIDelegate > *lockedViewController;

@property (strong, nonatomic) UIView *blurringView;
@property (strong, nonatomic) UIView *coveringView;

@property(readwrite) BOOL examRunning;

@property(strong, readwrite) NSDate *didResignActiveTime;
@property(strong, readwrite) NSDate *didBecomeActiveTime;
@property(strong, readwrite) NSDate *didResumeExamTime;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end

