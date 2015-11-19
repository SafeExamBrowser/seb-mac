//
//  SEBWKWebView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 18/11/15.
//
//

#import "SEBWKWebView.h"
#import "Constants.h"
#import "RNCryptor.h"
#import "MethodSwizzling.h"
#import <objc/runtime.h>

@implementation SEBWKWebView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


+ (void)setupModifyRequest
{
    [self swizzleMethod:@selector(loadRequest:)
             withMethod:@selector(newLoadRequest:)];
}


+ (void) load
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(loadRequest:);
        SEL swizzledSelector = @selector(newLoadRequest:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}


- (void) newLoadRequest: (NSURLRequest *) request
{
    NSString *fragment = [[request URL] fragment];
    NSString *absoluteRequestURL = [[request URL] absoluteString];
    NSString *requestURLStrippedFragment;
    if (fragment.length) {
        // if there is a fragment
        requestURLStrippedFragment = [absoluteRequestURL substringToIndex:absoluteRequestURL.length - fragment.length - 1];
    } else requestURLStrippedFragment = absoluteRequestURL;
    //    DDLogVerbose(@"Full absolute request URL: %@", absoluteRequestURL);
    //    DDLogVerbose(@"Request URL used to calculate RequestHash: %@", requestURLStrippedFragment);
    
    NSDictionary *headerFields;
    headerFields = [request allHTTPHeaderFields];
    //    DDLogVerbose(@"All HTTP header fields: %@", headerFields);
    NSLog(@"All HTTP header fields: %@", headerFields);
    //    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (true) {
        //    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"]) {
        
        NSMutableURLRequest *modifiedRequest = [request mutableCopy];
        
        NSData *browserExamKey = [NSData data];
        //        NSData *browserExamKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
        
        unsigned char hashedChars[32];
        [browserExamKey getBytes:hashedChars length:32];
        
        //        DDLogVerbose(@"Current Browser Exam Key: %@", browserExamKey);
        
        NSMutableString* browserExamKeyString = [[NSMutableString alloc] init];
        [browserExamKeyString setString:requestURLStrippedFragment];
        for (int i = 0 ; i < 32 ; ++i) {
            [browserExamKeyString appendFormat: @"%02x", hashedChars[i]];
        }
        
        //        DDLogVerbose(@"Current request URL + Browser Exam Key: %@", browserExamKeyString);
        
        const char *urlString = [browserExamKeyString UTF8String];
        
        CC_SHA256(urlString,
                  (CC_LONG)strlen(urlString),
                  hashedChars);
        
        NSMutableString* hashedString = [[NSMutableString alloc] init];
        for (int i = 0 ; i < 32 ; ++i) {
            [hashedString appendFormat: @"%02x", hashedChars[i]];
        }
        [modifiedRequest setValue:hashedString forHTTPHeaderField:@"X-SafeExamBrowser-RequestHash"];
        
        headerFields = [modifiedRequest allHTTPHeaderFields];
        //        DDLogVerbose(@"All HTTP header fields in modified request: %@", headerFields);
        NSLog(@"All HTTP header fields in modified request: %@", headerFields);
        request = modifiedRequest;
        
    }
    
    [self newLoadRequest: request];
}

@end
