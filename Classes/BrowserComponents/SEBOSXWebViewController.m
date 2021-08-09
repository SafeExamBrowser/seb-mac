//
//  SEBOSXWebViewController.m
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 09.08.21.
//

#import "SEBOSXWebViewController.h"


@implementation SEBOSXWebViewController


- (instancetype)initNewTabWithCommonHost:(BOOL)commonHostTab overrideSpellCheck:(BOOL)overrideSpellCheck
{
    self = [super init];
    if (self) {
        SEBAbstractWebView *sebAbstractWebView = [[SEBAbstractWebView alloc] initNewTabWithCommonHost:commonHostTab overrideSpellCheck:(BOOL)overrideSpellCheck];
        sebAbstractWebView.navigationDelegate = self;
        _sebWebView = sebAbstractWebView;
    }
    return self;
}


#pragma mark - SEBAbstractBrowserControllerDelegate Methods

- (void)loadView
{
    [_sebWebView loadView];
    self.view = _sebWebView.nativeWebView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [_sebWebView.nativeWebView viewDidLoad];
}

- (id)nativeWebView
{
    return _sebWebView.nativeWebView;
}

- (NSURL*)url
{
    return [_sebWebView url];
}

- (NSString*)pageTitle
{
    return [_sebWebView pageTitle];
}

- (BOOL)canGoBack
{
    return [_sebWebView canGoBack];
}

- (BOOL)canGoForward;
{
    return [_sebWebView canGoForward];
}

- (void)goBack {
    [_sebWebView goBack];
}

- (void)goForward {
    [_sebWebView goForward];
}

- (void)reload {
    [_sebWebView reload];
}

- (void)loadURL:(NSURL *)url
{
    [_sebWebView loadURL:url];
}

- (void)stopLoading {
    [_sebWebView stopLoading];
}


#pragma mark - SEBAbstractWebViewNavigationDelegate Methods

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

- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies
{
    [self.navigationDelegate examineCookies:cookies];
}

- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
{
    return [self.navigationDelegate openNewTabWithURL:url];
}

- (SEBAbstractWebView *) openNewWebViewWindowWithURL:(NSURL *)url
{
    return [self.navigationDelegate openNewWebViewWindowWithURL:url];
}

- (void) makeActiveAndOrderFront
{
    [self.navigationDelegate makeActiveAndOrderFront];
}

- (void) showWebView:(SEBAbstractWebView *)webView
{
    [self.navigationDelegate showWebView:webView];
}

- (void) closeWebView
{
    [self.navigationDelegate closeWebView:_sebWebView];
}

- (void) closeWebView:(SEBAbstractWebView *)webView
{
    [self.navigationDelegate closeWebView:webView];
}


@end
