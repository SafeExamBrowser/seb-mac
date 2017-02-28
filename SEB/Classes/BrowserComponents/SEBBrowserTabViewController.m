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
#import "SEBBrowserController.h"


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
    [super viewWillAppear:animated];
    
    // TO DO: Ok, later we will get the context from the creator of this VC
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [self setManagedObjectContext:[appDelegate managedObjectContext]];
    _persistentWebpages = appDelegate.persistentWebpages;
    
    _openWebpages = [NSMutableArray new];
    
    // Add an observer for the request to reload webpage
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(switchToTab:)
                                                 name:@"requestWebpageReload" object:nil];
    
    // Add an observer for the request to close webpage
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(closeTabRequested:)
                                                 name:@"requestWebpageClose" object:nil];
    
//    // Load all open web pages from the persistent store and re-create webview(s) for them
//    [self loadPersistedOpenWebPages];
    
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.searchBarController setLoading:NO];
}


#pragma mark - Controller interface

- (void)backToStart {
//    [_visibleWebViewController backToStart];
    
    // Conditionally load Back to Start URL into the main browser view
    OpenWebpages *mainWebpage = _openWebpages[0];

    // Determine the right URL depending on settings
    NSURL* backToStartURL = [NSURL URLWithString:[[SEBBrowserController new] backToStartURLString]];
    if (backToStartURL) {
        [mainWebpage.webViewController loadURL:backToStartURL];
        
        if ([MyGlobals sharedMyGlobals].currentWebpageIndexPathRow != 0) {
            [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow = 0;
            [self.mm_drawerController openDrawerSide:MMDrawerSideLeft animated:YES completion:^(BOOL finished) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self switchToTab:self];
                });
            }];
        }
    }
}

- (void)goBack {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([MyGlobals sharedMyGlobals].currentWebpageIndexPathRow == 0) {
        // Main browser tab with the exam
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowBrowsingBackForward"]) {
            // Cancel if navigation is disabled in exam
            return;
        }
    } else {
        // Additional browser tab
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowNavigation"]) {
            // Cancel if navigation is disabled in additional browser tabs
            return;
        }
    }
    [_visibleWebViewController goBack];
}

- (void)goForward {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([MyGlobals sharedMyGlobals].currentWebpageIndexPathRow == 0) {
        // Main browser tab with the exam
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowBrowsingBackForward"]) {
            // Cancel if navigation is disabled in exam
            return;
        }
    } else {
        // Additional browser tab
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowNavigation"]) {
            // Cancel if navigation is disabled in additional browser tabs
            return;
        }
    }
    [_visibleWebViewController goForward];
}

- (void)reload {
    [_visibleWebViewController reload];
}

- (void)stopLoading {
    [_visibleWebViewController stopLoading];
}


#pragma mark - Callbacks for UI state changes

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
    if (loading == false) {
        // Enable or disable back/forward buttons according to settings and
        // availability of browsing history for this webview
        
    }
}


- (void)setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([MyGlobals sharedMyGlobals].currentWebpageIndexPathRow == 0) {
        // Main browser tab with the exam
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowBrowsingBackForward"]) {
            // Cancel if navigation is disabled in exam
            canGoBack = false;
            canGoForward = false;
        }
    } else {
        // Additional browser tab
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowNavigation"]) {
            // Cancel if navigation is disabled in additional browser tabs
            canGoBack = false;
            canGoForward = false;
        }
    }

    [_sebViewController setCanGoBack:canGoBack canGoForward:canGoForward];
}


#pragma mark - Opening and closing tabs

// Open new tab and load URL
- (void)openNewTabWithURL:(NSURL *)url
{
    _maxIndex++;
    NSUInteger index = _maxIndex;
    [self openNewTabWithURL:url index:index];
}


// Open new tab and load URL or image (in the case of a freehand drawing)
- (void)openNewTabWithURL:(NSURL *)url image:(UIImage *)templateImage
{
    _maxIndex++;
    NSUInteger index = _maxIndex;
    [self openNewTabWithURL:url index:index image:templateImage];
}


// Open new tab and load URL, use passed index
- (void)openNewTabWithURL:(NSURL *)url index:(NSUInteger)index
{
    [self openNewTabWithURL:url index:index image:nil];
}


// Open new tab and load URL or template image (in the case of a freehand drawing)
- (void)openNewTabWithURL:(NSURL *)url index:(NSUInteger)index image:(UIImage *)templateImage
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
   
    // Create new OpenWebpage object with reference to the CoreData information
    OpenWebpages *newOpenWebpage = [OpenWebpages new];
    
    id newViewController;

    newViewController = [self createNewWebViewController];
    
    newOpenWebpage.webViewController = newViewController;
    newOpenWebpage.loadDate = timeStamp;
    // Add this to the Array of all open webpages
    [_openWebpages addObject:newOpenWebpage];
    
    // Set the index of the current web page
    [MyGlobals sharedMyGlobals].currentWebpageIndexPathRow = _openWebpages.count-1;
    
    // Exchange the old against the new webview
    [_visibleWebViewController removeFromParentViewController];

    [self addChildViewController:newViewController];
    [newViewController didMoveToParentViewController:self];
    
    _visibleWebViewController = newViewController;
    
    [_visibleWebViewController loadURL:url];
    
    [self.mm_drawerController openDrawerSide:MMDrawerSideLeft animated:YES completion:^(BOOL finished) {
        [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
    }];
    
    self.searchBarController.url = url.absoluteString;
}


// Open new tab and load URL
- (void)switchToTab:(id)sender {
    NSUInteger tabIndex = [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow;
    if (tabIndex < _openWebpages.count) {
        OpenWebpages *webpageToSwitch = _openWebpages[tabIndex];
        SEBWebViewController *webViewControllerToSwitch = webpageToSwitch.webViewController;
        
        // Create the webView in case it doesn't exist
        if (!webViewControllerToSwitch) {
            webViewControllerToSwitch = [self createNewWebViewController];
        }
        
        // Exchange the old against the new webview
        [_visibleWebViewController removeFromParentViewController];
        
        [self addChildViewController:webViewControllerToSwitch];
        [webViewControllerToSwitch didMoveToParentViewController:self];
        
        _visibleWebViewController = webViewControllerToSwitch;
        
        [MyGlobals sharedMyGlobals].currentWebpageIndexPathRow = [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow;;
        [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    }
}


// Close tab requested
- (void)closeTabRequested:(id)sender
{
    NSUInteger tabIndex = [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow;
    
    // Check if the user is closing the main web view (with the exam)
    if (tabIndex == 0) {
        [_sebViewController quitExamConditionally];
    } else {
        [self closeTab];
    }
}


// Close tab
- (void)closeTab
{
    NSUInteger tabIndex = [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow;
    
    // Delete the row from the data source
    NSManagedObjectContext *context = self.managedObjectContext;
    
    if (tabIndex < _persistentWebpages.count) {
        Webpages *webpageToClose = _persistentWebpages[tabIndex];
        
        NSString *pageToCloseURL = webpageToClose.url;
        if ([pageToCloseURL hasPrefix:@"drawing"]) {
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
        
        // Check if the user is closing the main web view (with the exam)
        if (tabIndex == 0) {
            [_visibleWebViewController removeFromParentViewController];
            _visibleWebViewController = nil;
        } else {
            NSInteger selectedWebpageIndexPathRow = [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow;
            NSInteger currentWebpageIndexPathRow = [MyGlobals sharedMyGlobals].currentWebpageIndexPathRow;
            // Was a tab closed which was before the currently displayed in the webpage side panel list
            if (selectedWebpageIndexPathRow < currentWebpageIndexPathRow) {
                // Yes: the index of the current webpage must be decreased by one
                [MyGlobals sharedMyGlobals].currentWebpageIndexPathRow--;
                // Or was the currently displayed webpage closed?
            } else if (selectedWebpageIndexPathRow == currentWebpageIndexPathRow) {
                // Yes: the index of the current webpage must be decreased by one
                [MyGlobals sharedMyGlobals].currentWebpageIndexPathRow--;
                [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow--;
                // and we switch to the webpage one position before the closed one in the webpage side panel list
                [self switchToTab:nil];
            }
        }
    }
}


- (void)setTitle:(NSString *)title forWebViewController:(SEBWebViewController *)webViewController
{
    NSUInteger index = [_openWebpages indexOfObjectPassingTest:
     ^(OpenWebpages *openPage, NSUInteger idx, BOOL *stop) {
         return [openPage.webViewController isEqual:webViewController];
     }];
    if (index != NSNotFound && index < _persistentWebpages.count) {
        [(Webpages *)_persistentWebpages[index] setValue:title forKey:@"title"];
    }
}


- (void)loadWebPageOrSearchResultWithString:(NSString *)webSearchString
{
    [self.visibleWebViewController.sebWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:webSearchString]]];
    
}


// Load all open web pages from the persistent store and re-create webview(s) for them
- (void)loadPersistedOpenWebPages {
    
    // Currently we don't use eventually persisted webpages
    [self removePersistedOpenWebPages];
    
    [_sebViewController conditionallyOpenLockdownWindows];
    
    NSArray *persistedOpenWebPages;
    
    NSManagedObjectContext *context = self.managedObjectContext;
    
    if (context) {
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
        persistedOpenWebPages = [context executeFetchRequest:fetchRequest error:&error];
    }
    
    // If no error occured and there have been some persisted pages
    if (persistedOpenWebPages && persistedOpenWebPages.count > 0) {
        _maxIndex = 0;
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
            [_openWebpages addObject:newOpenWebpage];
            
            [newWebViewController loadURL:[NSURL URLWithString:webpage.url]];
            
        }
        OpenWebpages *newOpenWebpage = (_openWebpages.lastObject);
        SEBWebViewController *newVisibleWebViewController = newOpenWebpage.webViewController;

        // Exchange the old against the new webview
        [_visibleWebViewController removeFromParentViewController];
        
        [self addChildViewController:newVisibleWebViewController];
        [newVisibleWebViewController didMoveToParentViewController:self];

        _visibleWebViewController = newVisibleWebViewController;

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


// Close all tabs with open web pages and remove persisted open webpages
- (void)closeAllTabs
{
    [self.mm_drawerController closeDrawerAnimated:YES completion:nil];

    [_visibleWebViewController removeFromParentViewController];

    for (OpenWebpages *webpage in _openWebpages) {
        SEBWebViewController *webViewController = webpage.webViewController;
        // Close the webview
        webViewController.view = nil;
    }
    [_openWebpages removeAllObjects];
    
    [self removePersistedOpenWebPages];
}


// Remove all open web pages from the persistent store
- (void)removePersistedOpenWebPages
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Webpages"];
    [fetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects)
    {
        [context deleteObject:object];
    }
    
    error = nil;
    [context save:&error];
    
    [_persistentWebpages removeAllObjects];
}


// Create a UIViewController with a SEBWebView to hold new webpages
- (SEBWebViewController *)createNewWebViewController {
    SEBWebViewController *newSEBWebViewController = [SEBWebViewController new];
    newSEBWebViewController.browserTabViewController = self;
    return newSEBWebViewController;
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


- (void) downloadAndOpenSEBConfigFromURL:(NSURL *)url
{
    [_sebViewController downloadAndOpenSEBConfigFromURL:url];
}


@end

