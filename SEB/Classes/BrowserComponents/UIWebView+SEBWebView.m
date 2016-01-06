//
//  UIWebView+SEBWebView.m
//  SEB
//
//  Created by Daniel Schneider on 13.05.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIWebView+SEBWebView.h"

@implementation UIWebView (SEBWebView)


- (NSString*)title
{
    return [self stringByEvaluatingJavaScriptFromString:@"document.title"];
}


- (NSURL*)url
{
    NSString *urlString = [self stringByEvaluatingJavaScriptFromString:@"location.href"];
    if (urlString) {
        return [NSURL URLWithString:urlString];
    } else {
        return nil;
    }
}


@end
