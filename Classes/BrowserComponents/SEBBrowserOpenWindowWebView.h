//
//  SEBBrowserOpenWindowWebView.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 12/10/14.
//
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "SEBBrowserWindow.h"

@interface SEBBrowserOpenWindowWebView : NSObject

@property (nonatomic, retain) SEBBrowserWindow *browserWindow;
@property (nonatomic, retain) WebView *webView;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSMenuItem *menuItem;

@end
