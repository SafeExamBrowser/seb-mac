//
//  SEBWebViewController.h
//  SEB
//
//  Created by Daniel Schneider on 09.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "UIViewController+MMDrawerController.h"

#import "SEBSearchBarViewController.h"

@class SEBSearchBarViewController;


@interface SEBWebViewController : UIViewController <UIWebViewDelegate, NSFetchedResultsControllerDelegate>
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

- (void)speakWebView;
- (void)stopSpeakingWebView;

- (void)switchToTab:(id)sender;

@end
