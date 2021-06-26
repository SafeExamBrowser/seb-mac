//
//  MscLocalException.h
//  MscSCEP
//
//  Created by Microsec on 2014.01.23..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MscX509CommonLocalException : NSException

@property(readonly) NSUInteger errorCode;

+(id)exceptionWithCode:(NSUInteger)code;

@end
