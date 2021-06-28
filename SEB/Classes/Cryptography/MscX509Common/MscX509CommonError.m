//
//  MscX509CommonError.m
//  MscX509Common
//
//  Created by Microsec on 2014.08.07..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import "MscX509CommonError.h"

@implementation MscX509CommonError

+(id)errorWithCode:(NSInteger)code {
    
    return [MscX509CommonError errorWithDomain:@"hu.microsec.x509common" code:code userInfo:nil];
}

@end
