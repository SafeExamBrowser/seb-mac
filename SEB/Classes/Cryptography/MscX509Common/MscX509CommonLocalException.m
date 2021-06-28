//
//  MscLocalException.m
//  MscSCEP
//
//  Created by Microsec on 2014.01.23..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import "MscX509CommonLocalException.h"

@implementation MscX509CommonLocalException

@synthesize errorCode = _errorCode;

-(id)initWithErrorCode:(NSUInteger)errorCode {
    
    self = [super initWithName:@"MscX509CommonLocalException" reason:nil userInfo:nil];
    if (self) {
        
        _errorCode = errorCode;
    }
    return self;
}

+(id)exceptionWithCode:(NSUInteger)code {
    
    return [[MscX509CommonLocalException alloc] initWithErrorCode:code];
}

@end
