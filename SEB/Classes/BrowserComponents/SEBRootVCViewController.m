//
//  SEBRootVCViewController.m
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

#import "SEBRootVCViewController.h"
#import "MMDrawerBarButtonItem.h"

@interface SEBRootVCViewController ()

@end

@implementation SEBRootVCViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    leftButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Browsers"] style:UIBarButtonItemStyleBordered target:self action:@selector(leftDrawerButtonPress:)];

    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPageButton:)];

    // Create search bar
    self.searchBarController = [[SEBSearchBarViewController alloc] init];
    //    self.searchBarController = [[SEBSearchBarControllerViewController alloc] initWithNibName:nil bundle:nil];


    self.navigationItem.leftBarButtonItem  = leftButton;
    self.navigationItem.rightBarButtonItem  = rightButton;
    self.navigationItem.titleView = self.searchBarController.view;
    
//    UIStoryboard *storyboard = [self storyboard];
    
    self.webViewController = self.childViewControllers[0];
    self.webViewController.searchBarController = self.searchBarController;
    self.searchBarController.webViewController = self.webViewController;
    self.searchBarController.rootViewController = self;
    

    //    self.webViewController = [SEBWebViewController new];
//    [self addChildViewController:self.webViewController];
//    [self.view addSubview:self.webViewController.view];
//    [self.webViewController didMoveToParentViewController:self];
    
//    [self.webViewController.SEBWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://heise.de"]]];

}


- (void)addPageButton:(id)sender
{

}


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
    [self.searchBarController cancelButtonPressed];
}


- (void)searchStopped
{
    [self.navigationItem setLeftBarButtonItem:leftButton animated:YES];
    
    [self.navigationItem setRightBarButtonItems:[NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPageButton:)]] animated:YES];
}


- (void)searchGoSearchString:(NSString *)searchString
{
    [self searchStopped];
    [self.webViewController loadWebPageOrSearchResultWithString:searchString];
}


//#pragma mark - UISearchBarDelegate
//
//
//- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
//    //[self searchBarCancelButtonClicked:nil];
//    
//}
//
//
//- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
//{
//    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:nil] animated:YES];
//}
//
//
//- (void)didReceiveMemoryWarning
//{
//    [super didReceiveMemoryWarning];
//    // Dispose of any resources that can be recreated.
//}
//
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - Button Handlers
-(void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)goBack:(id)sender {
    [self.webViewController goBack];
}

- (IBAction)goForward:(id)sender {
    [self.webViewController goForward];
}

- (IBAction)reload:(id)sender {
    [self.webViewController reload];
}


@end
