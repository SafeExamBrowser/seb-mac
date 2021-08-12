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
//        sebAbstractWebView.navigationDelegate = self;
        _sebAbstractWebView = sebAbstractWebView;
    }
    return self;
}


#pragma mark - SEBAbstractBrowserControllerDelegate Methods

- (void)loadView
{
    [_sebAbstractWebView loadView];
    self.view = _sebAbstractWebView.nativeWebView;
}

- (void) viewDidLoad
{
    [_sebAbstractWebView viewDidLoad];
    
    [super viewDidLoad];
}

- (void)viewWillAppear
{
    [_sebAbstractWebView viewWillAppear];
    
    [super viewWillAppear];
}

- (void)viewDidAppear
{
    [_sebAbstractWebView viewDidAppear];
    
    [super viewDidAppear];
}

- (void)viewWillDisappear
{
    [_sebAbstractWebView viewWillDisappear];
    
    [super viewWillDisappear];
}

- (void)viewWDidDisappear
{
    [_sebAbstractWebView viewDidDisappear];
    
    [super viewDidDisappear];
}

- (id)nativeWebView
{
    return _sebAbstractWebView.nativeWebView;
}

- (NSURL*)url
{
    return [_sebAbstractWebView url];
}

- (NSString*)pageTitle
{
    return [_sebAbstractWebView pageTitle];
}

- (BOOL)canGoBack
{
    return [_sebAbstractWebView canGoBack];
}

- (BOOL)canGoForward;
{
    return [_sebAbstractWebView canGoForward];
}

- (void)goBack {
    [_sebAbstractWebView goBack];
}

- (void)goForward {
    [_sebAbstractWebView goForward];
}

- (void)reload {
    [_sebAbstractWebView reload];
}

- (void)loadURL:(NSURL *)url
{
    [_sebAbstractWebView loadURL:url];
}

- (void)stopLoading {
    [_sebAbstractWebView stopLoading];
}

- (void)disableFlashFullscreen
{
    [_sebAbstractWebView disableFlashFullscreen];
}


#pragma mark - SEBAbstractWebViewNavigationDelegate Methods

//@synthesize wkWebViewConfiguration;
//
//- (WKWebViewConfiguration *)wkWebViewConfiguration
//{
//    return self.navigationDelegate.wkWebViewConfiguration;
//}
//
//- (void) setLoading:(BOOL)loading
//{
//    [self.navigationDelegate setLoading:loading];
//}
//
//- (void) setTitle:(NSString *)title
//{
//    [self.navigationDelegate setTitle:title];
//}
//
//- (void) setCanGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward
//{
//    [self.navigationDelegate setCanGoBack:canGoBack canGoForward:canGoForward];
//}
//
//- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies
//{
//    [self.navigationDelegate examineCookies:cookies];
//}
//
//- (SEBAbstractWebView *) openNewTabWithURL:(NSURL *)url
//{
//    return [self.navigationDelegate openNewTabWithURL:url];
//}
//
//- (SEBAbstractWebView *) openNewWebViewWindowWithURL:(NSURL *)url
//{
//    return [self.navigationDelegate openNewWebViewWindowWithURL:url];
//}
//
//- (void) makeActiveAndOrderFront
//{
//    [self.navigationDelegate makeActiveAndOrderFront];
//}
//
//- (void) showWebView:(SEBAbstractWebView *)webView
//{
//    [self.navigationDelegate showWebView:webView];
//}
//
//- (void) closeWebView
//{
//    [self.navigationDelegate closeWebView:_sebAbstractWebView];
//}
//
//- (void) closeWebView:(SEBAbstractWebView *)webView
//{
//    [self.navigationDelegate closeWebView:webView];
//}
//
//
//- (SEBAbstractWebView *) abstractWebView
//{
//    return _sebAbstractWebView;
//}
//
//- (NSURL *)currentURL
//{
//    return self.navigationDelegate.currentURL;
//}
//
//- (NSString *)currentMainHost
//{
//    return self.navigationDelegate.currentMainHost;
//}
//
//- (void)setCurrentMainHost:(NSString *)currentMainHost
//{
//    self.navigationDelegate.currentMainHost = currentMainHost;
//}
//
//- (BOOL) isMainBrowserWebViewActive
//{
//    return self.navigationDelegate.isMainBrowserWebViewActive;
//}
//
//- (NSString *)quitURL
//{
//    return self.navigationDelegate.quitURL;
//}
//
//- (NSString *) pageJavaScript
//{
//    return self.navigationDelegate.pageJavaScript;
//}
//
//- (BOOL) overrideAllowSpellCheck
//{
//    return self.navigationDelegate.overrideAllowSpellCheck;
//}
//
//- (NSURLRequest *)modifyRequest:(NSURLRequest *)request
//{
//    return [self.navigationDelegate modifyRequest:request];
//}
//
//- (NSString *) browserExamKeyForURL:(NSURL *)url
//{
//    return [self.navigationDelegate browserExamKeyForURL:url];
//}
//
//- (NSString *) configKeyForURL:(NSURL *)url
//{
//    return [self.navigationDelegate configKeyForURL:url];
//}
//
//- (NSString *) appVersion
//{
//    return [self.navigationDelegate appVersion];
//}
//
//
//@synthesize customSEBUserAgent;
//
//- (NSString *) customSEBUserAgent
//{
//    return self.navigationDelegate.customSEBUserAgent;
//    
//}
//
//
//- (id) window
//{
//    return self.navigationDelegate.window;
//}
//
//
//- (NSArray <NSData *> *) privatePasteboardItems
//{
//    return self.navigationDelegate.privatePasteboardItems;
//}
//
//- (void) setPrivatePasteboardItems:(NSArray<NSData *> *)privatePasteboardItems
//{
//    self.navigationDelegate.privatePasteboardItems = privatePasteboardItems;
//}
//
//
//- (void)sebWebViewDidStartLoad
//{
//    [self.navigationDelegate sebWebViewDidStartLoad];
//}
//
//- (void)sebWebViewDidFinishLoad
//{
//    [self.navigationDelegate sebWebViewDidFinishLoad];
//}
//
//- (void)sebWebViewDidFailLoadWithError:(NSError *)error
//{
//    [self.navigationDelegate sebWebViewDidFailLoadWithError:error];
//}
//
//- (SEBNavigationActionPolicy)decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
//                                                      newTab:(BOOL)newTab
//{
//    return [self.navigationDelegate decidePolicyForNavigationAction:navigationAction newTab:newTab];
//}
//
//- (void)sebWebViewDidUpdateTitle:(nullable NSString *)title
//{
//    if ([self.navigationDelegate respondsToSelector:@selector(sebWebViewDidUpdateTitle:)]) {
//        [self.navigationDelegate sebWebViewDidUpdateTitle:title];
//    }
//}
//
//- (void)sebWebViewDidUpdateProgress:(double)progress
//{
//    if ([self.navigationDelegate respondsToSelector:@selector(sebWebViewDidUpdateProgress:)]) {
//        [self.navigationDelegate sebWebViewDidUpdateProgress:progress];
//    }
//}
//
//- (SEBNavigationResponsePolicy)decidePolicyForMIMEType:(NSString*)mimeType
//                                                   url:(NSURL *)url
//                                       canShowMIMEType:(BOOL)canShowMIMEType
//                                        isForMainFrame:(BOOL)isForMainFrame
//                                     suggestedFilename:(NSString *)suggestedFilename
//                                               cookies:(NSArray<NSHTTPCookie *> *)cookies
//{
//    return [self.navigationDelegate decidePolicyForMIMEType:mimeType url:url canShowMIMEType:canShowMIMEType isForMainFrame:isForMainFrame suggestedFilename:suggestedFilename cookies:cookies];
//}
//
//- (void)webView:(WKWebView *)webView
//runJavaScriptAlertPanelWithMessage:(NSString *)message
//initiatedByFrame:(WKFrameInfo *)frame
//completionHandler:(void (^)(void))completionHandler
//{
//    [self.navigationDelegate webView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
//}
//
//- (void)pageTitle:(NSString *)pageTitle
//runJavaScriptAlertPanelWithMessage:(NSString *)message
//initiatedByFrame:(WebFrame *)frame
//{
//    [self.navigationDelegate pageTitle:pageTitle runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame];
//}
//
//- (void)webView:(WKWebView *)webView
//runJavaScriptConfirmPanelWithMessage:(NSString *)message
//initiatedByFrame:(WKFrameInfo *)frame
//completionHandler:(void (^)(BOOL result))completionHandler
//{
//    [self.navigationDelegate webView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
//}
//
//- (BOOL)pageTitle:(NSString *)pageTitle
//runJavaScriptConfirmPanelWithMessage:(NSString *)message
//initiatedByFrame:(WebFrame *)frame
//{
//    return [self.navigationDelegate pageTitle:pageTitle runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame];
//}
//
//- (void)webView:(WKWebView *)webView
//runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
//    defaultText:(nullable NSString *)defaultText
//initiatedByFrame:(WKFrameInfo *)frame
//completionHandler:(void (^)(NSString *result))completionHandler
//{
//    [self.navigationDelegate webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
//}
//
//- (NSString *)pageTitle:(NSString *)pageTitle
//runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
//          defaultText:(NSString *)defaultText
//     initiatedByFrame:(WebFrame *)frame
//{
//    return [self.navigationDelegate pageTitle:pageTitle runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame];
//}
//
//- (void)webView:(WKWebView *)webView
//runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters
//initiatedByFrame:(WKFrameInfo *)frame
//completionHandler:(void (^)(NSArray<NSURL *> *URLs))completionHandler
//{
//    [self.navigationDelegate webView:webView runOpenPanelWithParameters:parameters initiatedByFrame:frame completionHandler:completionHandler];
//}
//
//- (void) downloadFileFromURL:(NSURL *)url filename:(NSString *)filename
//{
//    [self.navigationDelegate downloadFileFromURL:url filename:filename];
//}
//
//- (BOOL) downloadingInTemporaryWebView
//{
//    return self.navigationDelegate.downloadingInTemporaryWebView;
//}
//
//- (BOOL) originalURLIsEqualToURL:(NSURL *)url
//{
//    return [self.navigationDelegate originalURLIsEqualToURL:url];
//}


@end
