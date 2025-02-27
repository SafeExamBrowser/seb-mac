//
//  SEBTableViewController.m
//
//  Created by Daniel R. Schneider on 06/01/16.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBTableViewController.h"
#import "Webpages.h"
#import "SEBSliderItem.h"


@interface SEBTableViewController ()

@property (weak, nonatomic) IBOutlet UIView *StatusBarBackgroundView;
@property (weak, nonatomic) IBOutlet UIButton *SEBTitleButtonLabel;
@property (nonatomic, strong) NSArray *commandItems;

@end

@implementation SEBTableViewController

@synthesize managedObjectContext = __managedObjectContext;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];

    [self setManagedObjectContext:[_appDelegate managedObjectContext]];

//    NSString *appName = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleName"];
    NSString *versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
    [_SEBTitleButtonLabel setTitle:[NSString stringWithFormat:@"%@ %@", SEBFullAppName , versionString] forState:UIControlStateNormal];
    
    // Add an observer for refreshing the table view
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTableView:)
                                                 name:@"refreshSlider" object:nil];
    
    // Add an observer for the left slider will be displayed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initSliderViewAppearance)
                                                 name:@"LGSideMenuWillShowLeftViewNotification" object:nil];
    
    // Add an observer for the left slider was displayed
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sliderViewDidShow)
                                                 name:@"LGSideMenuDidShowLeftViewNotification" object:nil];
    
    // Add an observer for the left slider will be hidden by swipe gesture
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sliderWillCloseByGesture)
                                                 name:@"LGSideMenuWillHideLeftViewWithGestureNotification" object:nil];

    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0.0;
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self initSliderViewAppearance];
    
    // TO DO: Ok, later we will get the context from the creater of this VC

    /* Here we call the method to load the table data */
    [self loadTableData];
    
    //UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItem)];
    
    //self.navigationItem.rightBarButtonItem = item;
}


- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewCell *firstTableViewRow = [self.tableView cellForRowAtIndexPath:indexPath];
    if (firstTableViewRow) {
//        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, firstTableViewRow);
    }
}


// Get statusbar appearance depending on device type (traditional or iPhone X like)
- (NSUInteger)statusBarAppearance {
    return [_appDelegate.sebUIController statusBarAppearanceForDevice];
}


- (void)initSliderViewAppearance
{
    if (!self.sideMenuController.isLeftViewShowing) {
        _webpagesArray = [_appDelegate.persistentWebpages mutableCopy];
        _commandItems = _appDelegate.sebUIController.leftSliderCommands;
        
        _SEBTitleButtonLabel.tintColor = [UIColor whiteColor];
        _SEBTitleButtonLabel.hidden = NO;
        CGFloat statusBarHeight = [_appDelegate.sebUIController statusBarHeightForDevice];
        self.statusBarHeight.constant = statusBarHeight;
        self.backgroundViewbottomDistance.constant = -statusBarHeight;

        if (_appDelegate.sebUIController.backgroundTintStyle == SEBBackgroundTintStyleDark) {
            _StatusBarBackgroundView.backgroundColor = [UIColor blackColor];
            self.view.backgroundColor = [UIColor blackColor];
        } else {
            _StatusBarBackgroundView.backgroundColor = [UIColor darkGrayColor];
            self.view.backgroundColor = [UIColor darkGrayColor];
        }
        
        if (@available(iOS 13.0, *)) {
            contentConfiguration = nil;
            if (@available(iOS 13.0, *)) {
                if (UITraitCollection.currentTraitCollection.accessibilityContrast) {
                    backgroundColor = [UIColor colorWithWhite:0.80 alpha:1.0];
                    headerBackgroundColor = [UIColor colorWithWhite:0.70 alpha:1.0];
                } else {
                    backgroundColor = [UIColor colorWithWhite:0.67 alpha:1.0];
                    headerBackgroundColor = [UIColor colorWithWhite:0.60 alpha:1.0];
                }
            }
            self.tableView.backgroundColor = backgroundColor;

            if (UITraitCollection.currentTraitCollection.legibilityWeight == UILegibilityWeightBold) {
                cellFont = [[UIFontMetrics defaultMetrics] scaledFontForFont:[UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:20.0]];
                headerFont = [[UIFontMetrics defaultMetrics] scaledFontForFont:[UIFont fontWithName:@"AvenirNextCondensed-Bold" size:20.0]];
            } else {
                cellFont = [[UIFontMetrics defaultMetrics] scaledFontForFont:[UIFont fontWithName:@"AvenirNextCondensed-Regular" size:20.0]];
                headerFont = [[UIFontMetrics defaultMetrics] scaledFontForFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:20.0]];
            }
        }

        [self refreshTableView:self];
    }
}


- (void)sliderViewDidShow
{
    [self accessibilityMessageForSliderShow:YES];
    
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//    UITableViewCell *firstTableViewRow = [self.tableView cellForRowAtIndexPath:indexPath];
//    if (firstTableViewRow) {
//        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, firstTableViewRow);
//    }
}


- (void)sliderWillCloseByGesture
{
    if (![_appDelegate.sebUIController extendedDisplay] || _appDelegate.sebUIController.iPadExtendedDisplay) {
        _SEBTitleButtonLabel.hidden = YES;
    }
}


- (IBAction)closeLeftSideMenu
{
    [self accessibilityMessageForSliderShow:NO];
    [self.sideMenuController hideLeftViewAnimated];
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)refreshTableView:(id)sender
{
    [self.tableView reloadData];
}


- (void)accessibilityMessageForSliderShow:(BOOL)show
{
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [NSString stringWithFormat:@"%@ %@", show ? NSLocalizedString(@"Showing", @"") : NSLocalizedString(@"Hiding", @""), NSLocalizedString(@"side menu", @"")]);
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1 + (_commandItems.count > 0);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return [_webpagesArray count];
            break;
            
        case 1:
            return [_commandItems count];
            break;
            
        default:
            return 0;
            break;
    }
}


- (NSString *)tableView:(UITableView *)tableView
titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return nil;
            break;

        case 1:
            return NSLocalizedString(@"Commands", "Separator in slider menu");
            break;

        default:
            return nil;
            break;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 0;
            break;
            
        case 1:
            return 32;
            break;
            
        default:
            return 0;
            break;
    }
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
    headerView.contentView.backgroundColor = headerBackgroundColor;

    if (@available(iOS 14.0, *)) {
        if (!contentConfiguration) {
            contentConfiguration = headerView.defaultContentConfiguration;
            contentConfiguration.text = NSLocalizedString(@"Commands", "Separator in slider menu");
            contentConfiguration.image = [UIImage new];
            contentConfiguration.textProperties.font = headerFont;
            contentConfiguration.textProperties.color = [UIColor blackColor];
            contentConfiguration.textProperties.adjustsFontForContentSizeCategory = YES;
        }
        headerView.contentConfiguration = contentConfiguration;
    } else {
        UILabel *cellLabel = headerView.textLabel;
        cellLabel.font = headerFont;
        cellLabel.textColor = [UIColor blackColor];
        cellLabel.adjustsFontForContentSizeCategory = YES;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger index = indexPath.row;

    switch (section) {
        case 0:
        {
            static NSString *CellIdentifier = @"WebpageCell";
            SEBActionUITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            if (cell == nil)
            {
                cell = [[SEBActionUITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            cell.delegate = self;
            
            // Get webpage
            Webpages *webpage = [_webpagesArray objectAtIndex:index];
            
            // Set the title or URL if title not (yet) available
            UILabel *cellLabel;
            cellLabel = (UILabel *)[cell viewWithTag:2];
            
            NSString *webpageCellLabelText;
            if (!webpage.title || [webpage.title isEqualToString:@""]) {
                webpageCellLabelText = index == 0 ? NSLocalizedString(@"Exam Page", @"") : NSLocalizedString(@"Untitled Page", @"");
                cellLabel.accessibilityLabel = webpageCellLabelText;
            } else {
                webpageCellLabelText = webpage.title;
                cellLabel.accessibilityLabel = [NSString stringWithFormat:@"%@: %@", webpage.title, NSLocalizedString(@"Webpage.", @"")];
            }
            cellLabel.text = webpageCellLabelText;
            if (index == 0) {
                cellLabel.textColor = [UIColor blackColor];
            } else {
                cellLabel.textColor = [UIColor whiteColor];
            }
            // Underline selected webpage title
            NSMutableAttributedString *attributedLabelText = [[NSMutableAttributedString alloc]
                                                              initWithAttributedString:cellLabel.attributedText];
            
            if (index == [MyGlobals sharedMyGlobals].currentWebpageIndexPathRow) {
                [attributedLabelText setAttributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)}
                                             range:NSMakeRange(0, attributedLabelText.length)];
            } else {
                [attributedLabelText setAttributes:@{NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)}
                                             range:NSMakeRange(0, attributedLabelText.length)];
            }
            cellLabel.attributedText = attributedLabelText.copy;
            cellLabel.font = cellFont;
            cellLabel.adjustsFontForContentSizeCategory = YES;

            UIButton *closeButton = (UIButton *)[cell viewWithTag:1];
            [closeButton addTarget:cell action:@selector(fireAction:) forControlEvents:UIControlEventTouchUpInside];
            
            return cell;
        }
            break;
            
        case 1:
        {
            static NSString *CellIdentifier = @"CommandCell";
            SEBActionUITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            
            if (cell == nil)
            {
                cell = [[SEBActionUITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            cell.delegate = self;
            
            // Get command
            SEBSliderItem *commandItem = [_commandItems objectAtIndex:index];
            
            // Set icon and title for cell
            UILabel *cellLabel;
            cellLabel = (UILabel *)[cell viewWithTag:2];
            cellLabel.text = commandItem.title;
            if (@available(iOS 13.0, *)) {
                if (UITraitCollection.currentTraitCollection.accessibilityContrast) {
                    cellLabel.textColor = [UIColor blackColor];
                } else {
                    cellLabel.textColor = [UIColor whiteColor];
                }
            }
            cellLabel.font = cellFont;
            cellLabel.adjustsFontForContentSizeCategory = YES;
            UIButton *closeButton = (UIButton *)[cell viewWithTag:1];
            [closeButton setImage:commandItem.icon forState:UIControlStateNormal];
            [closeButton addTarget:cell action:@selector(fireAction:) forControlEvents:UIControlEventTouchUpInside];
            closeButton.enabled = commandItem.enabled;
            
            return cell;

        }
            
        default:
            return [[UITableViewCell alloc] init];
            break;
    }
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger index = indexPath.row;
    
    [tableView reloadData];

    switch (section) {
        case 0:
        {
            [MyGlobals sharedMyGlobals].currentWebpageIndexPathRow = index;
            [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow = index;
            
            // Post a notification that the web page should be reloaded
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"requestWebpageReload" object:self];
        }
            break;
            
        case 1:
            [self didFireActionForIndexPath:indexPath];
            break;
            
        default:
            break;
    }
}


// Add this method for slide to delete
-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewCellEditingStyleDelete;
    
}


-(void)tableViewCell:(UITableViewCell *)cell didFireActionForSender:(id)sender
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) return;
    
    [self didFireActionForIndexPath:indexPath];
}


-(void)didFireActionForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;
    NSInteger index = indexPath.row;
    
    switch (section) {
        case 0:
        {
            // Section: Open webpages
            DDLogVerbose(@"Close button indexPath.row: %ld", (long)index);
            [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow = index;
            
            // If not closing the main web view: remove the webpage from the list
            if (index != 0) {
                [self.webpagesArray removeObjectAtIndex:index];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView reloadData];
            }
            // Post a notification that the web page should be closed
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"requestWebpageClose" object:self];
        }
            break;
            
        case 1:
        {
            // Section: Commands
            if (index < _commandItems.count) {
                SEBSliderItem *item = _commandItems[index];
                id callback = item.target;
                SEL selector = item.action;
                IMP imp = [callback methodForSelector:selector];
                void (*func)(id, SEL) = (void *)imp;
                // Execute action on target
                func(callback, selector);
            }
        }
            break;
            
        default:
            break;
    }
}


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
    
//    NSManagedObjectContext *context = self.managedObjectContext;
//    
//    // Construct a fetch request
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Webpages"
//                                              inManagedObjectContext:context];
//    
//    [fetchRequest setEntity:entity];
//    
//    // Add an NSSortDescriptor to sort the webpages according to their loadDate timestamp
//    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"loadDate" ascending:YES];
//    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
//    [fetchRequest setSortDescriptors:sortDescriptors];
//    
//    
//    NSError *error = nil;
//    self.webpagesArray = [NSMutableArray arrayWithArray:[context executeFetchRequest:fetchRequest error:&error]];
    [self.tableView reloadData];
}


// Bugfix for iPhone X: Otherwise after the first rotation the table view section header is invisible...
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self.tableView reloadData];
}

@end
