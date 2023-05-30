//
//  NSObject+UIResponderSEBDefaults.h
//  SafeExamBrowser
//
//  Created by M Persson on 2023-03-31.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (UIResponderSEBDefaults)

/**
 Default implementation mostly intented for (the private) UIThreadSafeNode, which
 wraps an active DOMNode in a UIWebView. This method, which actually is from
 UIResponder, is called in particular when arrow keys on a physical keyboard is pressed.
 The default implementation enables these arrow keys, including selection, to work.
 */
- (BOOL)canPerformAction:(SEL)action withSender:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
