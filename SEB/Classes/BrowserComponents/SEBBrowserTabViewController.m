//
//  SEBBrowserTabViewController.m
//
//  Created by Daniel R. Schneider on 06/01/16.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
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


#pragma mark - View management delegate methods

- (void) didMoveToParentViewController:(UIViewController *)parent
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


- (void) viewDidLoad
{
    [super viewDidLoad];
    
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


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self becomeFirstResponder];
    
}


- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//    [self.searchBarController setLoading:NO];
}


#pragma mark - Controller interface

- (NSURL *) currentURL
{
    return _visibleWebViewController.currentURL;
}


- (NSString *) currentMainHost
{
    return _visibleWebViewController.currentMainHost;
}

- (void) setCurrentMainHost:(NSString *)currentMainHost
{
    self.currentMainHost = currentMainHost;
}

- (BOOL) isMainBrowserWebViewActive
{
    return self.navigationDelegate.isMainBrowserWebViewActive;
}

- (void) toggleScrollLock
{
    [_visibleWebViewController toggleScrollLock];
}

- (BOOL) isScrollLockActive
{
    return [_visibleWebViewController isScrollLockActive];
}

- (void) backToStart {
//    [_visibleWebViewController backToStart];
    
    // Conditionally load Back to Start URL into the main browser view
    if (_openWebpages.count > 0) {
        OpenWebpages *mainWebpage = _openWebpages[0];
        
        // Determine the right URL depending on settings
        NSURL* backToStartURL = [NSURL URLWithString:[_sebViewController.browserController backToStartURLString]];
        if (backToStartURL) {
            [mainWebpage.webViewController loadURL:backToStartURL];
            
            if ([MyGlobals sharedMyGlobals].currentWebpageIndexPathRow != 0) {
                [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow = 0;
                [self.sideMenuController showLeftViewAnimated:YES completionHandler:^(void) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self switchToTab:self];
                    });
                }];
            }
        }
    }
}

- (void) goBack {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (self.navigationDelegate.isMainBrowserWebViewActive) {
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

- (void) goForward {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (self.navigationDelegate.isMainBrowserWebViewActive) {
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

- (void) reload {
    [_visibleWebViewController reload];
}

- (void) stopLoading {
    [_visibleWebViewController stopLoading];
}


/// SEBAbstractWebViewNavigationDelegate Methods

- (WKWebViewConfiguration *)wkWebViewConfiguration
{
    return [_sebViewController.browserController wkWebViewConfiguration];
}


@synthesize customSEBUserAgent;

- (NSString *) customSEBUserAgent
{
    return [_sebViewController.browserController customSEBUserAgent];
    
}

- (NSString *) quitURL
{
    return _sebViewController.browserController.quitURL;
}


- (void) setLoading:(BOOL)loading
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


- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL showToolbarNavigation = true;
    if (self.navigationDelegate.isMainBrowserWebViewActive) {
        // Main browser tab with the exam
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowBrowsingBackForward"]) {
            // Cancel if navigation is disabled in exam
            showToolbarNavigation = false;
            canGoBack = false;
            canGoForward = false;
        }
    } else {
        // Additional browser tab
        if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_newBrowserWindowNavigation"]) {
            // Cancel if navigation is disabled in additional browser tabs
            showToolbarNavigation = false;
            canGoBack = false;
            canGoForward = false;
        }
    }

    [_sebViewController showToolbarNavigation:showToolbarNavigation];
    [_sebViewController setCanGoBack:canGoBack canGoForward:canGoForward];
}


- (BOOL) directConfigDownloadAttempted
{
    return _sebViewController.browserController.directConfigDownloadAttempted;
}


- (void)webView:(WKWebView *)webView
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    [_sebViewController.browserController webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
}


#pragma mark - Opening and closing tabs

// Open new tab and load URL
- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
{
    return [self openNewTabWithURL:url overrideSpellCheck:NO];
}


- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url overrideSpellCheck:(BOOL)overrideSpellCheck
{
    _maxIndex++;
    NSUInteger index = _maxIndex;
    return [self openNewTabWithURL:url index:index overrideSpellCheck:overrideSpellCheck];
}


// Open new tab and load URL or image (in the case of a freehand drawing)
- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url image:(UIImage *)templateImage
{
    _maxIndex++;
    NSUInteger index = _maxIndex;
    return [self openNewTabWithURL:url index:index image:templateImage overrideSpellCheck:NO];
}


// Open new tab and load URL, use passed index
- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url index:(NSUInteger)index overrideSpellCheck:(BOOL)overrideSpellCheck
{
    return [self openNewTabWithURL:url index:index image:nil overrideSpellCheck:overrideSpellCheck];
}


- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
                                     index:(NSUInteger)index
                                     image:(UIImage *)templateImage
                        overrideSpellCheck:(BOOL)overrideSpellCheck
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
        DDLogError(@"%s: Couldn't save context: %@", __FUNCTION__, [error localizedDescription]);
    }
    // Add this to the Array of all persistently saved webpages
    [self.persistentWebpages addObject:newWebpage];
   
    // Create new OpenWebpage object with reference to the CoreData information
    OpenWebpages *newOpenWebpage = [OpenWebpages new];
    
    id newViewController;

    newViewController = [self createNewWebViewControllerWithCommonHost:[self examTabHasCommonHostWithURL:url] overrideSpellCheck:overrideSpellCheck];
    
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

    NSString *browserTabTitle;
    if (index == 0) {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowShowURL"] >= browserWindowShowURLBeforeTitle) {
            browserTabTitle = url.absoluteString;
        } else {
            browserTabTitle = NSLocalizedString(@"Exam Page", nil);
        }
    } else {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowShowURL"] >= browserWindowShowURLBeforeTitle) {
            browserTabTitle = url.absoluteString;
        } else {
            browserTabTitle = NSLocalizedString(@"Untitled Page", nil);
        }
    }
    [_sebViewController setToolbarTitle:browserTabTitle];
    
    [_sebViewController activateReloadButtonsExamTab:index == 0];

    [_sebViewController updateScrollLockButtonStates];
    
    [_visibleWebViewController loadURL:url];
    
//    self.searchBarController.url = url.absoluteString;
    return newOpenWebpage.webViewController.sebWebView;;
}

- (BOOL) examTabHasCommonHostWithURL:(NSURL *)url
{
    BOOL commonHost = YES;
    if (_openWebpages.count > 0) {
        commonHost = [_openWebpages[0].webViewController.sebWebView.url.host isEqualToString:url.host];
    }
    return commonHost;
}


- (void) openCloseSliderForNewTab
{
    [self.sebViewController newWebViewTabDidMoveToParentViewController];
}


// Open new tab and load URL
- (void) switchToTab:(id)sender
{
    NSUInteger tabIndex = [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow;
    [self switchToTabWithIndex:tabIndex];
    [self.sideMenuController toggleLeftViewAnimated];
}


- (void) switchToTabWithIndex:(NSUInteger)tabIndex
{
    if (tabIndex < _openWebpages.count) {
        OpenWebpages *webpageToSwitch = _openWebpages[tabIndex];
        SEBiOSWebViewController<SEBAbstractBrowserControllerDelegate> *webViewControllerToSwitch = webpageToSwitch.webViewController;
        
        // Create the webView in case it doesn't exist
        if (!webViewControllerToSwitch) {
            webViewControllerToSwitch = [self createNewWebViewControllerWithCommonHost:[self examTabHasCommonHostWithURL:webpageToSwitch.webViewController.url] overrideSpellCheck:NO];
        }
        
        // Exchange the old against the new webview
        [_visibleWebViewController removeFromParentViewController];
        
        [self addChildViewController:webViewControllerToSwitch];
        [webViewControllerToSwitch didMoveToParentViewController:self];
        
        _visibleWebViewController = webViewControllerToSwitch;
        
        // Update back/forward buttons according to new visible webview
        [_visibleWebViewController setBackForwardAvailabilty];
        
        // Update reload button depending if switching to exam or new tab
        [_sebViewController activateReloadButtonsExamTab:tabIndex == 0];
        
        // Update state of scroll lock buttons for the new webview
        [_sebViewController updateScrollLockButtonStates];
        
        // Update title in toolbar according to new visible webview
        NSString *title = [(Webpages *)_persistentWebpages[tabIndex] valueForKey:@"title"];
        [_sebViewController setToolbarTitle:title];
        
        [MyGlobals sharedMyGlobals].currentWebpageIndexPathRow = tabIndex;
    }
}


- (void) switchToNextTab
{
    NSUInteger tabIndex = [MyGlobals sharedMyGlobals].currentWebpageIndexPathRow;
    NSUInteger tabCount = _openWebpages.count;
    if (tabCount > 1) {
        if (tabIndex == tabCount - 1) {
            [self switchToTabWithIndex:0];
        } else {
            [self switchToTabWithIndex:tabIndex + 1];
        }
        [self.sideMenuController toggleLeftViewAnimated:YES completionHandler:^{
            [self.sideMenuController hideLeftViewAnimated];
        }];
    }
}


- (void) switchToPreviousTab
{
    NSUInteger tabIndex = [MyGlobals sharedMyGlobals].currentWebpageIndexPathRow;
    NSUInteger tabCount = _openWebpages.count;
    if (tabCount > 1) {
        if (tabIndex == 0) {
            [self switchToTabWithIndex:tabCount - 1];
        } else {
            [self switchToTabWithIndex:tabIndex - 1];
        }
        [self.sideMenuController toggleLeftViewAnimated:YES completionHandler:^{
            [self.sideMenuController hideLeftViewAnimated];
        }];
    }
}


- (void) closeTabWithWebView:(SEBAbstractWebView *)webView
{
    NSUInteger tabIndex = [self tabIndexForWebView:webView];
    [self closeTabWithIndex:tabIndex];
}


- (NSUInteger) tabIndexForWebView:(SEBAbstractWebView *)webView
{
    NSUInteger tabIndex = 0;
    for (OpenWebpages *openWebpage in _openWebpages) {
        SEBiOSWebViewController *webViewController = openWebpage.webViewController;
        if ([webViewController isEqual:webView]) {
            return tabIndex;
        }
    }
    return _openWebpages.count-1;
}


// Close tab requested
- (void) closeTabRequested:(id)sender
{
    NSUInteger tabIndex = [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow;
    
    // Check if the user is closing the main web view (with the exam)
    if (tabIndex == 0) {
        [_sebViewController quitExamConditionally];
    } else {
        [self closeTab];
    }
}


- (void) closeTab
{
    NSUInteger tabIndex = [MyGlobals sharedMyGlobals].selectedWebpageIndexPathRow;
    [self closeTabWithIndex:tabIndex];
}


- (void) closeTabWithIndex:(NSUInteger)tabIndex
{
    // Delete the row from the data source
    NSManagedObjectContext *context = self.managedObjectContext;
    
    if (tabIndex < _persistentWebpages.count) {
        Webpages *webpageToClose = _persistentWebpages[tabIndex];
        
        NSString *pageToCloseURL = webpageToClose.url;
        if ([pageToCloseURL hasPrefix:@"drawing"]) {
        } else {
            OpenWebpages *webpage = _openWebpages[tabIndex];
            SEBiOSWebViewController *webViewController = webpage.webViewController;
            // Prevent media player from playing audio after its webview was closed
            // by properly releasing it
            webViewController.sebWebView = nil;
            webViewController.view = nil;
            webViewController = nil;
        }
        
        [context deleteObject:[context objectWithID:[webpageToClose objectID]]];
        
        // Save everything
        NSError *error = nil;
        if ([context save:&error]) {
            DDLogDebug(@"%s: Saving context was successful!", __FUNCTION__);
        } else {
            DDLogError(@"%s: Saving context wasn't successful: %@", __FUNCTION__, [error userInfo]);
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


- (void) setTitle:(NSString *)title forWebViewController:(SEBiOSWebViewController *)webViewController
{
    NSUInteger index = [_openWebpages indexOfObjectPassingTest:
     ^(OpenWebpages *openPage, NSUInteger idx, BOOL *stop) {
         return [openPage.webViewController isEqual:webViewController];
     }];
    if (index != NSNotFound && index < _persistentWebpages.count) {
        [(Webpages *)_persistentWebpages[index] setValue:title forKey:@"title"];
    }
    
    [_sebViewController setToolbarTitle:title];
    
    // Post a notification that the slider should be refreshed
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"refreshSlider" object:self];
}


- (void) loadWebPageOrSearchResultWithString:(NSString *)webSearchString
{
    [self.visibleWebViewController.sebWebView loadURL:[NSURL URLWithString:webSearchString]];
    
}


// Load all open web pages from the persistent store and re-create webview(s) for them
- (void) loadPersistedOpenWebPages {
    
    // Currently we don't use eventually persisted webpages
    [self removePersistedOpenWebPages];
    
    [_sebViewController conditionallyOpenStartExamLockdownWindows];
    
    NSArray<Webpages*> *persistedOpenWebPages;
    
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
        NSString *examPageHost = [NSURL URLWithString:persistedOpenWebPages[0].url].host;
        // Open all persisted pages
        for (Webpages *webpage in persistedOpenWebPages) {
            // Open URL in a new webview
            // Create a new WebView
            NSURL *webpageURL = [NSURL URLWithString:webpage.url];
            SEBiOSWebViewController<SEBAbstractBrowserControllerDelegate> *newWebViewController = [self createNewWebViewControllerWithCommonHost:[examPageHost isEqualToString:webpageURL.host] overrideSpellCheck:NO];
            
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
            
            [newWebViewController loadURL:webpageURL];
            
        }
        OpenWebpages *newOpenWebpage = (_openWebpages.lastObject);
        SEBiOSWebViewController<SEBAbstractBrowserControllerDelegate> *newVisibleWebViewController = newOpenWebpage.webViewController;

        // Exchange the old against the new webview
        [_visibleWebViewController removeFromParentViewController];
        
        [self addChildViewController:newVisibleWebViewController];
        [newVisibleWebViewController didMoveToParentViewController:self];

        _visibleWebViewController = newVisibleWebViewController;

//        Webpages *visibleWebPage = persistedOpenWebPages.lastObject;
//        [self.searchBarController setUrl:visibleWebPage.url];
    } else {
        // There were no persisted pages
        // Load start URL from the system's user defaults
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSString *urlText = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
        
        // Handle Deep Links
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_startURLAllowDeepLink"]) {
            NSString *deepLink = [preferences secureStringForKey:@"org_safeexambrowser_startURLDeepLink"];
            [preferences setSecureString:@""
                                  forKey:@"org_safeexambrowser_startURLDeepLink"];
            if (deepLink.length > 0 && [deepLink hasPrefix:urlText]) {
                urlText = deepLink;
            }
        }
        
        // Handle Start URL Query String Parameter
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_startURLAppendQueryParameter"]) {
            NSString *queryString = [preferences secureStringForKey:@"org_safeexambrowser_startURLQueryParameter"];
            if (queryString.length > 0) {
                urlText = [NSString stringWithFormat:@"%@?%@", urlText, queryString];
            }
        }
        // This should prevent that a race condition with
        // receiving MDM server config already added an empty webpage
        [_openWebpages removeAllObjects];
        [self openNewTabWithURL:[NSURL URLWithString:urlText] index:0 overrideSpellCheck:NO];
    }
}


// Close all tabs with open web pages and remove persisted open webpages
- (void) closeAllTabs
{
    [self.sideMenuController hideLeftViewAnimated];

    [_visibleWebViewController removeFromParentViewController];

    for (OpenWebpages *webpage in _openWebpages) {
        SEBiOSWebViewController *webViewController = webpage.webViewController;
        // Prevent media player from playing audio after its webview was closed
        // by properly releasing it
        webViewController.sebWebView = nil;
        webViewController.view = nil;
        webViewController = nil;
    }
    [_openWebpages removeAllObjects];
    
    [self removePersistedOpenWebPages];
}


// Remove all open web pages from the persistent store
- (void) removePersistedOpenWebPages
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
- (SEBiOSWebViewController<SEBAbstractBrowserControllerDelegate> *) createNewWebViewControllerWithCommonHost:(BOOL)commonHostTab overrideSpellCheck:(BOOL)overrideSpellCheck {
    SEBiOSWebViewController<SEBAbstractBrowserControllerDelegate> *newSEBWebViewController = [[SEBiOSWebViewController<SEBAbstractBrowserControllerDelegate> alloc] initNewTabWithCommonHost:commonHostTab overrideSpellCheck:overrideSpellCheck delegate: self];
    return newSEBWebViewController;
}


// Read Info.plist values from bundle
- (id) infoValueForKey:(NSString*)key
{
    if ([[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key])
        return [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key];
    
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
}


- (NSString *) documentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    return documentsDirectoryPath;
}


// Download, decrypt, parse, store new SEB settings and if successfull, reconfigure SEB
- (void) conditionallyDownloadAndOpenSEBConfigFromURL:(NSURL *)url
{
    [_sebViewController conditionallyDownloadAndOpenSEBConfigFromURL:url];
}


// Decrypt, parse, store new SEB settings and if successfull, reconfigure SEB
- (void) conditionallyOpenSEBConfigFromData:(NSData *)sebConfigData;
{
    [_sebViewController conditionallyOpenSEBConfigFromData:sebConfigData];
}


- (void) downloadSEBConfigFileFromURL:(NSURL *)url originalURL:(NSURL *)originalURL cookies:(NSArray <NSHTTPCookie *>*)cookies
{
    [_sebViewController.browserController downloadSEBConfigFileFromURL:url originalURL:originalURL cookies:cookies sender:nil];
}


- (BOOL) downloadingInTemporaryWebView
{
    return _sebViewController.browserController.downloadingInTemporaryWebView;
}


- (void) transferCookiesToWKWebViewWithCompletionHandler:(void (^)(void))completionHandler
{
    [_sebViewController.browserController transferCookiesToWKWebViewWithCompletionHandler:completionHandler];
}


- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies
{
    [_sebViewController examineCookies:cookies];
}

- (NSURLRequest *)modifyRequest:(NSURLRequest *)request
{
    return [_sebViewController.browserController modifyRequest:request];
}


- (NSString *) browserExamKeyForURL:(NSURL *)url
{
    return [_sebViewController.browserController browserExamKeyForURL:url];
}

- (NSString *) configKeyForURL:(NSURL *)url
{
    return [_sebViewController.browserController configKeyForURL:url];
}

- (NSString *) appVersion
{
    return [_sebViewController appVersion];
}


- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url
{
    [_sebViewController shouldStartLoadFormSubmittedURL:url];
}


- (id) uiAlertController
{
    return _sebViewController.alertController;
}

- (void) setUiAlertController:(id)uiAlertController
{
    _sebViewController.alertController = uiAlertController;
}


- (void) presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion
{
    [_sebViewController presentViewController:viewControllerToPresent animated:flag completion:completion];
}


// Called by the CustomHTTPProtocol class to let the delegate know that a regular HTTP request
// or a XMLHttpRequest (XHR) successfully completed loading. The delegate can use this callback
// for example to scan the newly received HTML data
- (void)sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task
{
    NSURL *requestURL = task.originalRequest.URL;
    for (OpenWebpages *webpage in _openWebpages) {
        SEBiOSWebViewController *webViewController = webpage.webViewController;
        NSURL *webpageCurrentRequestURL = webViewController.currentURL;
        if ([webpageCurrentRequestURL isEqual:requestURL]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [webViewController sebWebViewDidFinishLoad];
            });
        }
    }
}


@end

