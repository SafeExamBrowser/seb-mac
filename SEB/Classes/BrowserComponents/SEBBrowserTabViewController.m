//
//  SEBWebpageManager.m
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

#import "AppDelegate.h"

#import "SEBBrowserTabViewController.h"
#import "UIWebView+SEBWebView.h"
#import "Constants.h"
#import "Webpages.h"
#import "OpenWebpages.h"


@implementation SEBBrowserTabViewController

@synthesize managedObjectContext = __managedObjectContext;


- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if (parent) {
        // Add the view to the parent view and position it if you want
        [[parent view] addSubview:[self view]];
        CGRect viewFrame = parent.view.bounds;
        //viewFrame.origin.y += kNavbarHeight;
        //viewFrame.size.height -= kNavbarHeight;
        [[self view] setFrame:viewFrame];
    } else {
        [[self view] removeFromSuperview];
    }
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Adjust scroll position so top of webpage is below the navigation bar
//    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
//    CGFloat toolBarHeight = self.navigationController.toolbar.frame.size.height;
//    [self.visibleWebView.scrollView setContentInset:UIEdgeInsetsMake(navBarHeight, 0, toolBarHeight, 0)];
//    [self.visibleWebView.scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(navBarHeight, 0, toolBarHeight, 0)];
//    [self.visibleWebView.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    // TO DO: Ok, later we will get the context from the creator of this VC
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [self setManagedObjectContext:[appDelegate managedObjectContext]];
    
    self.openWebpages = [NSMutableArray new];
    
    // Add an observer for the request to reload webpage
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(switchToTab:)
                                                 name:@"requestWebpageReload" object:nil];
    
    // Add an observer for the request to close webpage
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeTab:)
                                                 name:@"requestWebpageClose" object:nil];
    
//    // Load all open web pages from the persistent store and re-create webview(s) for them
//    [self loadPersistedOpenWebPages];
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.searchBarController setLoading:NO];
}

#pragma mark -
#pragma mark Controller interface

- (void)goBack {
    [_visibleWebViewController goBack];
}

- (void)goForward {
    [_visibleWebViewController goForward];
}

- (void)reload {
    [_visibleWebViewController reload];
}

- (void)stopLoading {
    [_visibleWebViewController stopLoading];
}

- (void)setLoading:(BOOL)loading
{
//    if (self.searchBar.text.length > 0) {
//        if (loading) {
//            [self.searchBarRightButton setImage:stopLoadingButtonImage forState:UIControlStateNormal];//your button image.
//        } else {
//            [self.searchBarRightButton setImage:reloadButtonImage forState:UIControlStateNormal];//your button image.
//        }
//    } else {
//        [self.searchBarRightButton setImage:nil forState:UIControlStateNormal];
//    }
}


// Open new tab and load URL
- (void)openNewTabWithURL:(NSURL *)url
{
    _maxIndex++;
    NSUInteger index = _maxIndex;
    [self openNewTabWithURL:url index:index];
}


// Open new tab and load URL, use passed index
- (void)openNewTabWithURL:(NSURL *)url index:(NSUInteger)index
{
    // Save new tab data persistently
    NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObject *newWebpage = [NSEntityDescription
                                   insertNewObjectForEntityForName:@"Webpages"
                                   inManagedObjectContext:context];
    // Save webpage properties which are already known like URL
    [newWebpage setValue:[url absoluteString] forKey:@"url"];
    [newWebpage setValue:[NSNumber numberWithUnsignedInteger:index] forKey:@"index"];
    // Save current date for load and view date
    NSNumber *timeStamp = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    [newWebpage setValue:timeStamp forKey:@"loadDate"];
    [newWebpage setValue:timeStamp forKey:@"viewDate"];
    // This is an open webpage/tab and not a webpage on the reading list
    [newWebpage setValue:[NSNumber numberWithBool:NO] forKey:@"readingList"];
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Couldn't save: %@", [error localizedDescription]);
    }
    // Add this to the Array of all persistently saved webpages
    [self.persistentWebpages addObject:newWebpage];
    
    // Open URL in a new webview
    // Create a new UIWebView
    SEBWebViewController *newWebViewController = [self createNewWebViewController];
    
    // Create new OpenWebpage object with reference to the CoreData information
    OpenWebpages *newOpenWebpage = [OpenWebpages new];
    newOpenWebpage.webViewController = newWebViewController;
    newOpenWebpage.loadDate = timeStamp;
    // Add this to the Array of all open webpages
    [self.openWebpages addObject:newOpenWebpage];
    
    // Exchange the old against the new webview
    [_visibleWebViewController.view removeFromSuperview];
    [_visibleWebViewController removeFromParentViewController];

    [self.view addSubview:newWebViewController.sebWebView];
    [self addChildViewController:newWebViewController];
    _visibleWebViewController = newWebViewController;
    
    [_visibleWebViewController loadURL:url];
    
    [self.mm_drawerController openDrawerSide:MMDrawerSideLeft animated:YES completion:^(BOOL finished) {
        [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
    }];
    
    self.searchBarController.url = url.absoluteString;
}


// Open new tab and load URL
- (void)switchToTab:(id)sender {
    NSUInteger tabIndex = [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow;
    OpenWebpages *webpageToSwitch = self.openWebpages[tabIndex];
    SEBWebViewController *webViewControllerToSwitch = webpageToSwitch.webViewController;
    
    // Create the webView in case it doesn't exist
    if (!webViewControllerToSwitch) {
        webViewControllerToSwitch = [self createNewWebViewController];
    }
    
    // Exchange the old against the new webview
    [_visibleWebViewController.view removeFromSuperview];
    [_visibleWebViewController removeFromParentViewController];
    
    [self.view addSubview:webViewControllerToSwitch.sebWebView];
    [self addChildViewController:webViewControllerToSwitch];
    _visibleWebViewController = webViewControllerToSwitch;
   
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    
    
}

// Close tab
- (void)closeTab:(id)sender {
    NSUInteger tabIndex = [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow;
    
    // Delete the row from the data source
    NSManagedObjectContext *context = self.managedObjectContext;
    
    // Grab the label
    //    OpenWebpages *label = [self.labelArray objectAtIndex:indexPath.row];
    Webpages *webpageToClose = _persistentWebpages[tabIndex];
    
    // Check if the user is closing the main web view (with the exam)
    if ([webpageToClose.index unsignedIntegerValue] == 0) {
        [_sebViewController finishExamConditionally];
    }
    
    [context deleteObject:[context objectWithID:[webpageToClose objectID]]];
    
    // Save everything
    NSError *error = nil;
    if ([context save:&error]) {
        NSLog(@"The save was successful!");
    } else {
        NSLog(@"The save wasn't successful: %@", [error userInfo]);
    }
    
    [_persistentWebpages removeObjectAtIndex:tabIndex];
    [_openWebpages removeObjectAtIndex:tabIndex];
    
    //    [self.visibleWebView removeFromSuperview];
    //    [self.view addSubview:webviewToSwitch];
    //    self.visibleWebView = webviewToSwitch;
    
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    
    //self.visibleWebView.delegate = self;	// setup the delegate as the web view is shown
    //[self.visibleWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
}


- (void)loadWebPageOrSearchResultWithString:(NSString *)webSearchString
{
    [self.visibleWebViewController.sebWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:webSearchString]]];
    
}


// Load all open web pages from the persistent store and re-create webview(s) for them
- (void)loadPersistedOpenWebPages {
    NSManagedObjectContext *context = self.managedObjectContext;
    
    // Construct a fetch request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Webpages"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // Add an NSSortDescriptor to sort the labels alphabetically
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"loadDate" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSError *error = nil;
    NSArray *persistedOpenWebPages = [context executeFetchRequest:fetchRequest error:&error];
    _persistentWebpages = [NSMutableArray arrayWithArray:persistedOpenWebPages];
    _maxIndex = 0;
    
    // If no error occured and there have been some persisted pages
    if (persistedOpenWebPages && persistedOpenWebPages.count > 0) {
        // Open all persisted pages
        for (Webpages *webpage in persistedOpenWebPages) {
            // Open URL in a new webview
            // Create a new UIWebView
            SEBWebViewController *newWebViewController = [self createNewWebViewController];
            
            // Create new OpenWebpage object with reference to the CoreData information
            OpenWebpages *newOpenWebpage = [OpenWebpages new];
            newOpenWebpage.webViewController = newWebViewController;
            NSUInteger index = [webpage.index unsignedIntegerValue];
            if (index != 0) {
                _maxIndex++;
                index = _maxIndex;
            }
            newOpenWebpage.index = index;
            newOpenWebpage.loadDate = webpage.loadDate;
            // Add this to the Array of all open webpages
            [self.openWebpages addObject:newOpenWebpage];
            
            [newWebViewController loadURL:[NSURL URLWithString:webpage.url]];
            
        }
        OpenWebpages *newOpenWebpage = (self.openWebpages.lastObject);
        SEBWebViewController *visibleNewWebViewController = newOpenWebpage.webViewController;
        // Exchange the old against the new webview
        [_visibleWebViewController.view removeFromSuperview];
        [_visibleWebViewController removeFromParentViewController];
        
        [self.view addSubview:visibleNewWebViewController.sebWebView];
        [self addChildViewController:visibleNewWebViewController];
        _visibleWebViewController = visibleNewWebViewController;

        Webpages *visibleWebPage = persistedOpenWebPages.lastObject;
        [self.searchBarController setUrl:visibleWebPage.url];
    } else {
        // There were no persisted pages
        // Load start URL from the system's user defaults
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
        
        [self openNewTabWithURL:[NSURL URLWithString:urlText] index:0];
    }
}


// Create a UIViewController with a SEBWebView to hold new webpages
- (SEBWebViewController *)createNewWebViewController {
    SEBWebViewController *newSEBWebViewController = [SEBWebViewController new];
    newSEBWebViewController.browserTabViewController = self;
    newSEBWebViewController.sebWebView = [self createNewWebView];
    newSEBWebViewController.sebWebView.delegate = newSEBWebViewController;
    return newSEBWebViewController;
}


// Create a UIWebView to hold new webpages
- (UIWebView *)createNewWebView {
    // Create a webview to fit underneath the navigation view (=fill the whole screen).
    CGRect webFrame = [[UIScreen mainScreen] applicationFrame];
    UIWebView *newWebView = [[UIWebView alloc] initWithFrame:webFrame];
    
    newWebView.backgroundColor = [UIColor lightGrayColor];
    newWebView.scalesPageToFit = YES;
    newWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    newWebView.scrollView.scrollEnabled = YES;
    [newWebView setTranslatesAutoresizingMaskIntoConstraints:YES];
    //newWebView.delegate = self;
    return newWebView;
}


// Read Info.plist values from bundle
- (id) infoValueForKey:(NSString*)key
{
    if ([[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key])
        return [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key];
    
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
}


- (NSString *)documentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    return documentsDirectoryPath;
}


@end

