//
//  WKWebView+SEBEvaluateJavaScript.m
//  SafeExamBrowser
//

#import "WKWebView+SEBEvaluateJavaScript.h"

@implementation WKWebView (SEBEvaluateJavaScript)

- (void)seb_evaluateJavaScript:(NSString *)script
             completionHandler:(void (^ _Nullable)(id _Nullable result, NSError * _Nullable error))completionHandler {
    [self evaluateJavaScript:script completionHandler:completionHandler];
}

- (void)seb_evaluateJavaScript:(NSString *)script
                       inFrame:(WKFrameInfo * _Nullable)frame
               inContentWorld:(WKContentWorld *)contentWorld
             completionHandler:(void (^ _Nullable)(id _Nullable result, NSError * _Nullable error))completionHandler
    API_AVAILABLE(macos(11.0), ios(14.0)) {
    if (@available(macOS 11.0, iOS 14.0, *)) {
        [self evaluateJavaScript:script inFrame:frame inContentWorld:contentWorld completionHandler:completionHandler];
    }
}

@end
