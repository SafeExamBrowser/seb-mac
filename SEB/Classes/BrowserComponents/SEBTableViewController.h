//
//  SEBTableViewController.h
//  TellTheWeb
//
//  Created by Daniel R. Schneider on 18/04/14.
//  Copyright (c) 2014 art technologies Schneider & Schneider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIViewController+MMDrawerController.h"

@interface SEBTableViewController : UIViewController  <UITableViewDelegate, UITableViewDataSource>


@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSArray *webpagesArray;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

-(IBAction)closeButtonPressed:(UIButton *)sender;

@end
