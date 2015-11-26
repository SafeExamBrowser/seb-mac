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

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) IBOutlet SEBViewController *sebViewController;

@property (strong, nonatomic) UIView *blurringView;
@property (strong, nonatomic) UIView *coveringView;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@end

