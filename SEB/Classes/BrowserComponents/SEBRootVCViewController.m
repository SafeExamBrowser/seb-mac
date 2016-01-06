//
//  SEBRootVCViewController.m
//  TellTheWeb
//
//  Created by Daniel R. Schneider on 18/04/14.
//  Copyright (c) 2014 art technologies Schneider & Schneider. All rights reserved.
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
