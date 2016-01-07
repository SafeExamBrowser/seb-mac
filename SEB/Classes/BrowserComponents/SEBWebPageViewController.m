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

#import "SEBWebPageViewController.h"
#import "UIWebView+SEBWebView.h"
#import "Constants.h"
#import "Webpages.h"
#import "OpenWebpages.h"


@implementation SEBWebPageViewController

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
    
    // Load all open web pages from the persistant store and re-create webview(s) for them
//    [self loadPersistedOpenWebPages];
        
    // Create an instance of the SEBWebView defined in the Storyboard
    //    self.visibleWebView = [self createNewWebView];
    //    self.visibleWebView = self.SEBWebView;
    self.visibleWebView.delegate = self;	// setup the delegate as the web view is shown
    //    [self.visibleWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://safeexambrowser.org"]]];
    [self.view addSubview:self.visibleWebView];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.visibleWebView stopLoading];	// in case the web view is still loading its content
    self.visibleWebView.delegate = nil;	// disconnect the delegate as the webview is hidden
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.searchBarController setLoading:NO];
}

#pragma mark -
#pragma mark Controller interface

- (void)goBack {
    [self.visibleWebView goBack];
}

- (void)goForward {
    [self.visibleWebView goForward];
}

- (void)reload {
    [self.visibleWebView reload];
}

- (void)stopLoading {
    [self.visibleWebView stopLoading];
}


#pragma mark -
#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    // starting the load, show the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.searchBarController setLoading:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // Adjust scroll position so top of webpage is below the navigation bar
//    CGFloat navBarHeight = self.navigationController.navigationBar.frame.size.height;
//    CGFloat toolBarHeight = self.navigationController.toolbar.frame.size.height;
//    [webView.scrollView setContentInset:UIEdgeInsetsMake(navBarHeight, 0, toolBarHeight, 0)];
//    [webView.scrollView setScrollIndicatorInsets:UIEdgeInsetsMake(navBarHeight, 0, toolBarHeight, 0)];
//    [webView.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    
    // Get JavaScript code for modifying targets of hyperlinks in the webpage so can be open in new tabs
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ModifyLinkTargets" ofType:@"js"];
    jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    [webView stringByEvaluatingJavaScriptFromString:jsCode];
    
    [webView stringByEvaluatingJavaScriptFromString:@"SEB_ModifyLinkTargets()"];
    [webView stringByEvaluatingJavaScriptFromString:@"SEB_ModifyWindowOpen()"];
    //[webView stringByEvaluatingJavaScriptFromString:@"SEB_increaseMaxZoomFactor()"];
    
    //[self highlightAllOccurencesOfString:@"SEB" inWebView:webView];
    //[self speakWebView:webView];
    
    NSString *webPageTitle = [webView title];
    if ([webPageTitle isEqualToString:@""]) {
        
    } else {
        MainWebView.title = webPageTitle;
    }
    
    // finished loading, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.searchBarController setLoading:NO];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // load error, hide the activity indicator in the status bar
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.searchBarController setLoading:NO];
    
    // report the error inside the webview
    NSString* errorString = [NSString stringWithFormat:
                             @"<html><center><font size=+5 color='red'>An error occurred:<br>%@</font></center></html>",
                             error.localizedDescription];
    [webView loadHTMLString:errorString baseURL:nil];
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = [request URL];
    if ([[url scheme] isEqualToString:@"newtab"]) {
        NSString *urlString = [[url resourceSpecifier] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        url = [NSURL URLWithString:urlString relativeToURL:[webView url]];
        [self openNewTabWithURL:url];
        return NO;
    }
    if ([[url scheme] isEqualToString:@"about"]) {
        return NO;
    }
    if(navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSString *fileExtension = [url pathExtension];
        
        if ([fileExtension isEqualToString:@"png"] || [fileExtension isEqualToString:@"jpg"] || [fileExtension isEqualToString:@"tif"] || [fileExtension isEqualToString:@"xls"]) {
            // Get the filename of the loaded ressource form the UIWebView's request URL
            NSString *filename = [url lastPathComponent];
            NSLog(@"Filename: %@", filename);
            // Get the path to the App's Documents directory
            NSString *docPath = [self documentsDirectoryPath];
            // Combine the filename and the path to the documents dir into the full path
            NSString *pathToDownloadTo = [NSString stringWithFormat:@"%@/%@", docPath, filename];
            
            
            // Load the file from the remote server
            NSData *tmp = [NSData dataWithContentsOfURL:url];
            // Save the loaded data if loaded successfully
            if (tmp != nil) {
                NSError *error = nil;
                // Write the contents of our tmp object into a file
                [tmp writeToFile:pathToDownloadTo options:NSDataWritingAtomic error:&error];
                if (error != nil) {
                    NSLog(@"Failed to save the file: %@", [error description]);
                } else {
                    // Display an UIAlertView that shows the users we saved the file :)
                    UIAlertView *filenameAlert = [[UIAlertView alloc] initWithTitle:@"File saved" message:[NSString stringWithFormat:@"The file %@ has been saved.", filename] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [filenameAlert show];
                    return NO;
                }
            } else {
                // File could notbe loaded -> handle errors
            }
        } else {
            // File type not supported
        }
        
    }
    return YES;
}


- (NSInteger)highlightAllOccurencesOfString:(NSString*)searchString inWebView:(UIWebView *)webView
{
    //    NSString *path = [[NSBundle mainBundle] pathForResource:@"SearchWebView" ofType:@"js"];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SearchWebView" ofType:@"js"];
    NSString *jsCodeSearch = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [webView stringByEvaluatingJavaScriptFromString:jsCodeSearch];
    
    NSString *startSearch = [NSString stringWithFormat:@"MyApp_HighlightAllOccurencesOfString('%@')", searchString];
    [webView stringByEvaluatingJavaScriptFromString:startSearch];
    
    NSString *result = [webView stringByEvaluatingJavaScriptFromString:@"MyApp_SearchResultCount"];
    return [result integerValue];
}



- (void)removeAllHighlightsInWebView:(UIWebView *)webView
{
    [webView stringByEvaluatingJavaScriptFromString:@"MyApp_RemoveAllHighlights()"];
}


// Open new tab and load URL
- (void)openNewTabWithURL:(NSURL *)url
{
    [self.mm_drawerController openDrawerSide:MMDrawerSideLeft animated:YES completion:^(BOOL finished) {
        [self.mm_drawerController closeDrawerAnimated:YES completion:nil];
    }];
    // Save new tab data persistantly
    NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObject *newWebpage = [NSEntityDescription
                                   insertNewObjectForEntityForName:@"Webpages"
                                   inManagedObjectContext:context];
    // Save webpage properties which are already known like URL
    [newWebpage setValue:[url absoluteString] forKey:@"url"];
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
    [self.persistantWebpages addObject:newWebpage];
    
    // Open URL in a new webview
    // Create a new UIWebView
    UIWebView *newWebView = [self createNewWebView];
    
    // Create new OpenWebpage object with reference to the CoreData information
    OpenWebpages *newOpenWebpage = [OpenWebpages new];
    newOpenWebpage.webView = newWebView;
    newOpenWebpage.loadDate = timeStamp;
    // Add this to the Array of all open webpages
    [self.openWebpages addObject:newOpenWebpage];
    
    // Exchange the old against the new webview
    [self.visibleWebView removeFromSuperview];
    [self.view addSubview:newWebView];
    self.visibleWebView = newWebView;
    
    //self.visibleWebView.delegate = self;	// setup the delegate as the web view is shown
    [self.visibleWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
    self.searchBarController.url = url.absoluteString;
    //[self.mm_drawerController closeDrawerAnimated:YES completion:nil];
}


// Open new tab and load URL
- (void)switchToTab:(id)sender {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSUInteger tabIndex = appDelegate.selectedCourseIndexPathRow;
    OpenWebpages *webpageToSwitch = self.openWebpages[tabIndex];
    UIWebView *webviewToSwitch = webpageToSwitch.webView;
    
    // Create the webView in case it doesn't exist
    if (!webviewToSwitch) {
        webviewToSwitch = [self createNewWebView];
    }
    
    [self.visibleWebView removeFromSuperview];
    [self.view addSubview:webviewToSwitch];
    self.visibleWebView = webviewToSwitch;
    
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    
    //self.visibleWebView.delegate = self;	// setup the delegate as the web view is shown
    //[self.visibleWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
}

// Close tab
- (void)closeTab:(id)sender {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSUInteger tabIndex = appDelegate.selectedCourseIndexPathRow;
    
    // Delete the row from the data source
    NSManagedObjectContext *context = self.managedObjectContext;
    
    // Grab the label
    //    OpenWebpages *label = [self.labelArray objectAtIndex:indexPath.row];
    Webpages *webpageToClose = self.persistantWebpages[tabIndex];
    
    [context deleteObject:[context objectWithID:[webpageToClose objectID]]];
    
    // Save everything
    NSError *error = nil;
    if ([context save:&error]) {
        NSLog(@"The save was successful!");
    } else {
        NSLog(@"The save wasn't successful: %@", [error userInfo]);
    }
    
    [self.persistantWebpages removeObjectAtIndex:tabIndex];
    [self.openWebpages removeObjectAtIndex:tabIndex];
    
    //    [self.visibleWebView removeFromSuperview];
    //    [self.view addSubview:webviewToSwitch];
    //    self.visibleWebView = webviewToSwitch;
    
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
    
    //self.visibleWebView.delegate = self;	// setup the delegate as the web view is shown
    //[self.visibleWebView loadRequest:[NSURLRequest requestWithURL:url]];
    
}


- (void)loadWebPageOrSearchResultWithString:(NSString *)webSearchString
{
    [self.visibleWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:webSearchString]]];
    
}


// Load all open web pages from the persistant store and re-create webview(s) for them
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
    self.persistantWebpages = [NSMutableArray arrayWithArray:persistedOpenWebPages];
    
    // If no error occured and there have been some persisted pages
    if (persistedOpenWebPages && persistedOpenWebPages.count > 0) {
        // Open all persisted pages
        for (Webpages *webpage in persistedOpenWebPages) {
            // Open URL in a new webview
            // Create a new UIWebView
            UIWebView *newWebView = [self createNewWebView];
            
            // Create new OpenWebpage object with reference to the CoreData information
            OpenWebpages *newOpenWebpage = [OpenWebpages new];
            newOpenWebpage.webView = newWebView;
            newOpenWebpage.loadDate = webpage.loadDate;
            // Add this to the Array of all open webpages
            [self.openWebpages addObject:newOpenWebpage];
            
            //self.visibleWebView.delegate = self;	// setup the delegate as the web view is shown
            [newWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:webpage.url]]];
            
        }
        OpenWebpages *newOpenWebpage = (self.openWebpages.lastObject);
        // Exchange the old against the new webview
        [self.visibleWebView removeFromSuperview];
        [self.view addSubview:newOpenWebpage.webView];
        self.visibleWebView = newOpenWebpage.webView;
        Webpages *visibleWebPage = persistedOpenWebPages.lastObject;
        [self.searchBarController setUrl:visibleWebPage.url];
    } else {
        // There were no persisted pages
        //[self openNewTabWithURL:[NSURL URLWithString:@"http://www.safeexambrowser.org"]];
    }
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
    newWebView.delegate = self;
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

