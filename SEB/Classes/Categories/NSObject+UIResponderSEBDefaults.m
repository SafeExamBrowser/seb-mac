//
//  NSObject+UIResponderSEBDefaults.m
//  SafeExamBrowser
//
//  Created by M Persson on 2023-03-31.
//

#import "NSObject+UIResponderSEBDefaults.h"

@implementation NSObject (UIResponderSEBDefaults)

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    BOOL result = [self respondsToSelector:action];
    DDLogVerbose(@"NSObject default canPerformAction: %s withSender: %@ => %s", sel_getName(action), sender, result ? "YES" : "NO");
    return result;
}

@end
