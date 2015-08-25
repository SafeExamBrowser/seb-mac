//
//  SEBAlert.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 25/08/15.
//
//

#import "SEBAlert.h"

@implementation SEBAlert

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self.window setLevel:NSMainMenuWindowLevel+5];
    }
    return self;
}

@end
