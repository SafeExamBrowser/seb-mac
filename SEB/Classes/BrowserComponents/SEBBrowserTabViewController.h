//
//  SEBWebpageManager.h
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

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "SEBViewController.h"
#import "OpenWebpages.h"

#import "SEBAbstractWebView.h"
#import "SEBWebViewController.h"
#import "SEBSearchBarViewController.h"

@class SEBViewController;
@class OpenWebpages;
@class SEBAbstractWebView;
@class SEBWebViewController;
@class SEBSearchBarViewController;


@interface SEBBrowserTabViewController : UIViewController <SEBAbstractWebViewNavigationDelegate, NSFetchedResultsControllerDelegate>
{
    IBOutlet UIBarButtonItem *MainWebView;
}

@property (weak) SEBViewController *sebViewController;
@property (nonatomic, weak) SEBWebViewController<SEBAbstractBrowserControllerDelegate> *visibleWebViewController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSMutableArray<OpenWebpages*> *openWebpages;
@property (nonatomic, strong) NSMutableArray *persistentWebpages;
@property (readwrite) NSUInteger maxIndex;

@property (nonatomic, strong) SEBSearchBarViewController *searchBarController;

- (NSString *) currentURL;
@property (nonatomic, strong) NSString *currentMainHost;

- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward;

- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url;
- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url overrideSpellCheck:(BOOL)overrideSpellCheck;
- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url index:(NSUInteger)index overrideSpellCheck:(BOOL)overrideSpellCheck;
- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url image:(UIImage *)templateImage;
- (void) loadPersistedOpenWebPages;

- (void) closeAllTabs;

- (void) removePersistedOpenWebPages;

- (id) infoValueForKey:(NSString *)key;
- (NSString *) documentsDirectoryPath;

- (void) toggleScrollLock;
@property (readonly) BOOL isScrollLockActive;
- (void) backToStart;
- (void) goBack;
- (void) goForward;
- (void) reload;
- (void) stopLoading;

- (void) setLoading:(BOOL)loading;
- (void) setTitle:(NSString *)title forWebViewController:(SEBWebViewController *)webViewController;

- (void) loadWebPageOrSearchResultWithString:(NSString *)webSearchString;

- (void) openCloseSliderForNewTab;
- (void) switchToTab:(id)sender;
- (void) switchToNextTab;
- (void) switchToPreviousTab;
- (void) closeTab;

- (void) conditionallyDownloadAndOpenSEBConfigFromURL:(NSURL *)url;
- (void) conditionallyOpenSEBConfigFromData:(NSData *)sebConfigData;

- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies;
- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url;
- (void) sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task;

@end

