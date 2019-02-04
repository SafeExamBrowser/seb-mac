//
//  UIDragInteraction+Restrict.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 04.02.19.
//

#import "UIDragInteraction+Restrict.h"
#import "MethodSwizzling.h"

@implementation UIDragInteraction (Restrict)


+ (void)setupIsEnabled
{
    [self swizzleMethod:@selector(isEnabled)
             withMethod:@selector(restrictIsEnabled)];
}


- (BOOL)restrictIsEnabled
{
    return NO;
}

@end
