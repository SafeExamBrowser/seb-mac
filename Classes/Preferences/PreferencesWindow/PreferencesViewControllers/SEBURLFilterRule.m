//
//  SEBURLFilterRule.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 18.11.14.
//
//

#import "SEBURLFilterRule.h"

@implementation SEBURLFilterRule

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setObject:@YES forKey:@"active"];
        [self setObject:@NO forKey:@"regex"];
        [self setObject:[NSNumber numberWithLong:URLFilterActionAllow] forKey:@"action"];
    }
    return self;
}

@end
