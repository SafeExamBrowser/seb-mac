//
//  SEBUIWebViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 05.03.21.
//

#import <UIKit/UIKit.h>

#import "SEBAbstractWebView.h"
#import "SEBURLFilter.h"

@class SEBAbstractClassicWebView;
@class SEBWKNavigationAction;
@class SEBURLFilter;

NS_ASSUME_NONNULL_BEGIN

@interface SEBUIWebViewController : UIViewController <UIWebViewDelegate, SEBAbstractBrowserControllerDelegate>
{
    IBOutlet UIBarButtonItem *MainWebView;
    
    NSString *jsCode;
    
@private
    BOOL allowSpellCheck;
    NSString *quitURLTrimmed;
    BOOL mobileEnableGuidedAccessLinkTransform;
    BOOL enableDrawingEditor;
    BOOL openCloseSlider;
}

@property (weak, nonatomic) id<SEBAbstractWebViewNavigationDelegate, SEBAbstractBrowserControllerDelegate> navigationDelegate;

//@property (weak) SEBBrowserTabViewController *browserTabViewController;
@property (nonatomic, strong) UIWebView *sebWebView;
@property (strong) SEBURLFilter *urlFilter;
@property (strong) UIView *filterMessageHolder;
@property (strong) NSString *currentURL;
@property (strong) NSString *currentMainHost;
@property (strong) NSURLRequest *currentRequest;
@property (readonly) BOOL isScrollLockActive;


- (NSInteger)highlightAllOccurencesOfString:(NSString*)searchString inWebView:(UIWebView *)webView;
- (void)removeAllHighlightsInWebView:(UIWebView *)webView;

- (id) infoValueForKey:(NSString *)key;
- (NSString *)tempDirectoryPath;

- (void)toggleScrollLock;
- (void)backToStart;
- (void)goBack;
- (void)goForward;
- (void)reload;
- (void)stopLoading;

- (void)loadURL:(NSURL *)url;

- (void)setBackForwardAvailabilty;

@end

NS_ASSUME_NONNULL_END
