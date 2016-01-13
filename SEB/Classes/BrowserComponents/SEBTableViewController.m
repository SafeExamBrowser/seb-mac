//
//  SEBTableViewController.m
//
//  Created by Daniel R. Schneider on 06/01/16.
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

#import "SEBTableViewController.h"
#import "Webpages.h"
#import "AppDelegate.h"

@interface SEBTableViewController ()

@end

@implementation SEBTableViewController

@synthesize managedObjectContext = __managedObjectContext;
@synthesize webpagesArray;

//- (id)initWithStyle:(UITableViewStyle)style
//{
//    self = [super initWithStyle:style];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //showsStatusBarBackgroundView = YES;
    
//    [self.tableView setContentInset:UIEdgeInsetsMake(20, self.tableView.contentInset.left, self.tableView.contentInset.bottom, self.tableView.contentInset.right)];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //[self.mm_drawerController setShowsStatusBarBackgroundView:YES];
    
    // TO DO: Ok, later we will get the context from the creater of this VC
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [self setManagedObjectContext:[appDelegate managedObjectContext]];

    /* Here we call the method to load the table data */
    [self loadTableData];
    
    //UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItem)];
    
    //self.navigationItem.rightBarButtonItem = item;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

//- (UIStatusBarStyle)preferredStatusBarStyle {
//    return UIStatusBarStyleBlackOpaque;
//}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [webpagesArray count];
}


- (NSArray *) testModel{
    return @[@"Home",@"Page 1"];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"WebpageCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    
    // Get webpage
    Webpages *webpage = [self.webpagesArray objectAtIndex:indexPath.row];
    
    // Set the title or URL if title not (yet) available
    UILabel *cellLabel;
    cellLabel = (UILabel *)[cell viewWithTag:1];
    
    NSString *webpageCellLabelText = (!webpage.title || [webpage.title isEqualToString:@""]) ? webpage.url : webpage.title;
    cellLabel.text = webpageCellLabelText;
    UIButton *closeButton = (UIButton *)[cell viewWithTag:0];
    closeButton.tag = indexPath.row;

//    cellLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:20];
//    cellLabel.textColor = [UIColor whiteColor];

//    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    closeButton.frame = CGRectMake(2, 10, 14, 14);
//    [closeButton setImage:[UIImage imageNamed:@"Cancel"] forState:UIControlStateNormal];
//    [closeButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//    closeButton.tintColor = [UIColor blackColor];
//    closeButton.backgroundColor= [UIColor clearColor];
//    [cell.contentView addSubview:closeButton];
    return cell;
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger index = indexPath.row;
    [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow = index;

    // Post a notification that the web page should be reloaded
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestWebpageReload" object:self];

//    UIViewController *vc =  [self.storyboard instantiateViewControllerWithIdentifier:@"page1"];
//    UIViewController *vcmain = [self.storyboard instantiateViewControllerWithIdentifier:@"vcmain"];
//    
//    switch (index) {
//        case 0:{
//            [self.mm_drawerController closeDrawerAnimated:YES completion:^(BOOL finished) {
//                self.mm_drawerController.centerViewController = vcmain;
//                [self.mm_drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeNone];
//                
//            }];
//            break;
//        }
//        case 1:{
//            [self.mm_drawerController closeDrawerAnimated:YES completion:^(BOOL finished) {
//                self.mm_drawerController.centerViewController = vc;
//                [self.mm_drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeAll];
//                
//            }];
//            break;
//        }
//            
//            
//        default:
//            break;
//    }
    
    
}


// Add this method for slide to delete
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
    
}


-(IBAction)closeButtonPressed:(UIButton *)sender {
    NSInteger index = sender.tag;
    NSLog(@"Close button indexPath.row: %ld", (long)index);
    [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow = index;
    
//    // Remove the row in the table view
//    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
//
    // Post a notification that the web page should be closed
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestWebpageClose" object:self];

}



/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - Private methods

// This method executes a fetch request and reloads the table view.
- (void) loadTableData {
    
    NSManagedObjectContext *context = self.managedObjectContext;
    
    // Construct a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Webpages"
                                              inManagedObjectContext:context];
    
    [fetchRequest setEntity:entity];
    
    // Add an NSSortDescriptor to sort the webpages according to their loadDate timestamp
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"loadDate" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    
    NSError *error = nil;
    self.webpagesArray = [context executeFetchRequest:fetchRequest error:&error];
    [self.tableView reloadData];
}


@end
