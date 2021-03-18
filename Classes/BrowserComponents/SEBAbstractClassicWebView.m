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

- (NSString*)title
{
    return [self.browserControllerDelegate title];
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

- (void)SEBWebViewDidStartLoad:(SEBAbstractWebView *)sebWebView
{
    [self.navigationDelegate SEBWebViewDidStartLoad:sebWebView];
}

- (void)SEBWebViewDidFinishLoad:(SEBAbstractWebView *)sebWebView
{
    [self.navigationDelegate SEBWebViewDidFinishLoad:sebWebView];
}

- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didFailLoadWithError:(NSError *)error
{
    [self.navigationDelegate SEBWebView:sebWebView didFailLoadWithError:error];
}

- (BOOL)SEBWebView:(SEBAbstractWebView *)sebWebView shouldStartLoadWithRequest:(NSURLRequest *)request
      navigationAction:(WKNavigationAction *)navigationAction
{
    return [self.navigationDelegate SEBWebView:sebWebView shouldStartLoadWithRequest:request navigationAction:navigationAction];
}

- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didUpdateTitle:(nullable NSString *)title
{
    if ([self.navigationDelegate respondsToSelector:@selector(SEBWebView:didUpdateTitle:)]) {
        [self.navigationDelegate SEBWebView:sebWebView didUpdateTitle:title];
    }
}

- (void)SEBWebView:(SEBAbstractWebView *)sebWebView didUpdateProgress:(double)progress
{
    if ([self.navigationDelegate respondsToSelector:@selector(SEBWebView:didUpdateProgress:)]) {
        [self.navigationDelegate SEBWebView:sebWebView didUpdateProgress:progress];
    }
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

- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies
{
    [self.navigationDelegate examineCookies:cookies];
}

@end
