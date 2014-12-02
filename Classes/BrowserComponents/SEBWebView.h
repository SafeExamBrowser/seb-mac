//
//  SEBWebView.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 02.12.14.
//
//

#import <WebKit/WebKit.h>

@interface SEBWebView : WebView

@property (weak, nonatomic) SEBWebView *creatingWebView;

@end
