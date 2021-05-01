//
//  SEBAbstractClassicWebView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03.03.21.
//

#import "SEBAbstractClassicWebView.h"
#if TARGET_OS_IPHONE
#import "SEBUIWebViewController.h"
#else
//#import "SEBWebViewController.h"
#endif

@implementation SEBAbstractClassicWebView

- (instancetype)init
{
    self = [super init];
    if (self) {
#if TARGET_OS_IPHONE
        SEBUIWebViewController *sebUIWebViewController = [SEBUIWebViewController new];
        sebUIWebViewController.navigationDelegate = self;
        self.browserControllerDelegate = sebUIWebViewController;
#else
//        self.delegate = [SEBWebViewController new];
#endif
    }
    return self;
}


/// SEBAbstractBrowserControllerDelegate Methods

- (void)loadView
{
    [self.browserControllerDelegate loadView];
}

- (void)didMoveToParentViewController
{
    [self.browserControllerDelegate didMoveToParentViewController];
}

- (void)viewDidLayoutSubviews
{
    [self.browserControllerDelegate viewDidLayoutSubviews];
}
- (void)viewWillTransitionToSize
{
    [self.browserControllerDelegate viewWillTransitionToSize];
}
- (void)viewWillAppear:(BOOL)animated
{
    [self.browserControllerDelegate viewWillAppear:(BOOL)animated];
}
- (void)viewDidAppear:(BOOL)animated
{
    [self.browserControllerDelegate viewDidAppear:(BOOL)animated];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [self.browserControllerDelegate viewWillDisappear:(BOOL)animated];
}


- (id)nativeWebView
{
    return self.browserControllerDelegate.nativeWebView;
}

- (NSURL*)url
{
    return [self.browserControllerDelegate url];
}

- (NSString*)pageTitle
{
    return [self.browserControllerDelegate pageTitle];
}

- (BOOL)canGoBack
{
    return [self.browserControllerDelegate canGoBack];
}

- (BOOL)canGoForward;
{
    return [self.browserControllerDelegate canGoForward];
}

- (void)goBack
{
    [self.browserControllerDelegate goBack];
}

- (void)goForward
{
    [self.browserControllerDelegate goForward];
}

- (void)reload
{
    [self.browserControllerDelegate reload];
}

- (void)loadURL:(NSURL *)url
{
    [self.browserControllerDelegate loadURL:url];
}

- (void)stopLoading
{
    [self.browserControllerDelegate stopLoading];
}

- (void) disableSpellCheck {
    [self.browserControllerDelegate disableSpellCheck];
}


- (void)toggleScrollLock
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(toggleScrollLock)]) {
        [self.browserControllerDelegate toggleScrollLock];
    }
}

- (BOOL) isScrollLockActive
{
    if ([self.browserControllerDelegate respondsToSelector:@selector(isScrollLockActive)]) {
        return [self.browserControllerDelegate isScrollLockActive];
    }
    return NO;
}


/// SEBAbstractWebViewNavigationDelegate Methods

@synthesize wkWebViewConfiguration;

- (WKWebViewConfiguration *)wkWebViewConfiguration
{
    return self.navigationDelegate.wkWebViewConfiguration;
}

- (void) setLoading:(BOOL)loading
{
    [self.navigationDelegate setLoading:loading];
}

- (void) setTitle:(NSString *)title
{
    [self.navigationDelegate setTitle:title];
}

- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
{
    [self.navigationDelegate setCanGoBack:canGoBack canGoForward:canGoForward];
}

- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
{
    return [self.navigationDelegate openNewTabWithURL:url];
}

- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies
{
    [self.navigationDelegate examineCookies:cookies];
}


- (void)sebWebViewDidStartLoad
{
    [self.navigationDelegate sebWebViewDidStartLoad];
}

- (void)sebWebViewDidFinishLoad
{
    [self.navigationDelegate sebWebViewDidFinishLoad];
}

- (void)sebWebViewDidFailLoadWithError:(NSError *)error
{
    [self.navigationDelegate sebWebViewDidFailLoadWithError:error];
}

- (BOOL)sebWebViewShouldStartLoadWithRequest:(NSURLRequest *)request
      navigationAction:(WKNavigationAction *)navigationAction
                                      newTab:(BOOL)newTab
{
    return [self.navigationDelegate sebWebViewShouldStartLoadWithRequest:request navigationAction:navigationAction newTab:newTab];
}

- (void)sebWebViewDidUpdateTitle:(nullable NSString *)title
{
    if ([self.navigationDelegate respondsToSelector:@selector(sebWebViewDidUpdateTitle:)]) {
        [self.navigationDelegate sebWebViewDidUpdateTitle:title];
    }
}

- (void)sebWebViewDidUpdateProgress:(double)progress
{
    if ([self.navigationDelegate respondsToSelector:@selector(sebWebViewDidUpdateProgress:)]) {
        [self.navigationDelegate sebWebViewDidUpdateProgress:progress];
    }
}

- (BOOL)sebWebViewDecidePolicyForMIMEType:(NSString*)mimeType
                                      url:(NSURL *)url
                          canShowMIMEType:(BOOL)canShowMIMEType
                           isForMainFrame:(BOOL)isForMainFrame
                        suggestedFilename:(NSString *)suggestedFilename
                                  cookies:(nonnull NSArray<NSHTTPCookie *> *)cookies
{
    return [self.navigationDelegate sebWebViewDecidePolicyForMIMEType:mimeType url:url canShowMIMEType:canShowMIMEType isForMainFrame:isForMainFrame suggestedFilename:suggestedFilename cookies:cookies];
}

- (SEBBackgroundTintStyle) backgroundTintStyle
{
    return [self.navigationDelegate backgroundTintStyle];
}

@end
