//
//  WKWebView+SEBEvaluateJavaScript.h
//  SafeExamBrowser
//
//  Workaround for a crash in the Swift WebKit bindings on older macOS versions
//  when the app is built with Xcode 16.3+. Routing all evaluateJavaScript calls
//  through Objective-C avoids the faulty Swift stub.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (SEBEvaluateJavaScript)

/// Evaluate JavaScript, calling the optional completion handler with the result.
/// Pass nil for fire-and-forget calls.
- (void)seb_evaluateJavaScript:(NSString *)script
             completionHandler:(void (^ _Nullable)(id _Nullable result, NSError * _Nullable error))completionHandler;

/// Evaluate JavaScript in a specific frame and content world (macOS 11 / iOS 14+).
- (void)seb_evaluateJavaScript:(NSString *)script
                       inFrame:(WKFrameInfo * _Nullable)frame
               inContentWorld:(WKContentWorld *)contentWorld
             completionHandler:(void (^ _Nullable)(id _Nullable result, NSError * _Nullable error))completionHandler
    API_AVAILABLE(macos(11.0), ios(14.0));

@end

NS_ASSUME_NONNULL_END
