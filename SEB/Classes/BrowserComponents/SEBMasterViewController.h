//
//  SEBMasterViewController.h
//  TellTheWeb
//
//  Created by Daniel R. Schneider on 17/04/14.
//  Copyright (c) 2014 art technologies Schneider & Schneider. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SEBDetailViewController;

#import <CoreData/CoreData.h>

@interface SEBMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) SEBDetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
