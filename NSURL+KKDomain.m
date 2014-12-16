//
//  NSURL+KKDomain.m
//  KKDomain
//
//  Created by Luke on 4/6/14.
//  Copyright (c) 2014 geeklu. All rights reserved.
//

#import "NSURL+KKDomain.h"
#import "NSString+KKDomain.h"

@implementation NSURL (KKDomain)

- (NSString *)registeredDomain{
    return [self.host registeredDomain];
}

- (NSString *)publicSuffix{
    return [self.host publicSuffix];
}
@end
