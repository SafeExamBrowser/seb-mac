//
//  NSString+MscExtensions.m
//  MscSCEP
//
//  Created by Microsec on 2014.01.20..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import "NSString+MscASCIIExtension.h"

@implementation NSString (MscASCIIExtension)

-(BOOL)isEmpty {
    if ([self length] == 0 || [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
        return YES;
    }
    return NO;
}

-(const char*)ASCIIString {
    return [self cStringUsingEncoding:NSASCIIStringEncoding];
}

@end
