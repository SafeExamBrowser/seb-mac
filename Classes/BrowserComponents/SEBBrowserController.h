//
//  SEBBrowserController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06/10/14.
//
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "SEBBrowserWindow.h"

@class SEBBrowserWindow;

@interface SEBBrowserController : NSObject

@property (strong) WebView *webView;
@property (strong) SEBBrowserWindow *mainBrowserWindow;
@property (strong) NSString *currentMainHost;

- (WebView *) openWebView;
- (WebView *) openAndShowWebView;
- (void) closeWebView:(WebView *) webViewToClose;
- (void) webViewShow:(WebView *)sender;
- (void) openMainBrowserWindow;
- (void) adjustMainBrowserWindow;
- (void) allBrowserWindowsChangeLevel:(BOOL)allowApps;

- (void) openResourceWithURL:(NSString *)URL andTitle:(NSString *)title;
- (void) downloadAndOpenSebConfigFromURL:(NSURL *)url;

- (void) setTitle:(NSString *)title forWindow:(SEBBrowserWindow *)browserWindow andWebView:(WebView *)webView;

@end
