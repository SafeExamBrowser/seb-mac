//
//  SEBWebpageManager.h
//  TellTheWeb
//
//  Created by Daniel R. Schneider on 13/07/14.
//  Copyright (c) 2014 art technologies Schneider & Schneider. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "UIViewController+MMDrawerController.h"

#import "SEBSearchBarViewController.h"

@class SEBSearchBarViewController;


@interface SEBWebPageViewController : UIViewController <UIWebViewDelegate, NSFetchedResultsControllerDelegate>
{
    //IBOutlet UIWebView *SEBWebView;
    IBOutlet UIBarButtonItem *MainWebView;
    
    //UIWebView *SEBWebView;
    
    NSString *jsCode;
}

@property (nonatomic, strong) IBOutlet UIWebView *SEBWebView;
@property (nonatomic, strong) UIWebView *visibleWebView;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSMutableArray *openWebpages;
@property (nonatomic, strong) NSMutableArray *persistantWebpages;

@property (nonatomic, strong) SEBSearchBarViewController *searchBarController;


- (NSInteger)highlightAllOccurencesOfString:(NSString*)searchString inWebView:(UIWebView *)webView;
- (void)removeAllHighlightsInWebView:(UIWebView *)webView;

- (void)openNewTabWithURL:(NSURL *)url;
- (id) infoValueForKey:(NSString *)key;
- (NSString *)documentsDirectoryPath;

- (void)goBack;
- (void)goForward;
- (void)reload;
- (void)stopLoading;

- (void)loadWebPageOrSearchResultWithString:(NSString *)webSearchString;

- (void)switchToTab:(id)sender;

@end

