//
//  MscRSAKey.h
//  MscSCEP
//
//  Created by Microsec on 2014.01.27..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MscX509CommonError.h"

typedef NS_ENUM(NSUInteger, KeySize) {
    KeySize_2048 = 2048,
    KeySize_4096 = 4096
};

@interface MscRSAKey : NSObject<NSCoding>

-(id)init __attribute__((unavailable("please, use initWithKeySize or initWithContentsOfFile for initialization")));
-(id)initWithKeySize:(KeySize)keySize error:(MscX509CommonError**)error;
-(id)initWithContentsOfFile:(NSString*)path error:(MscX509CommonError**)error;
-(void)saveToPath:(NSString *)path error:(MscX509CommonError**)error;
-(BOOL)isEqualToMscRSA:(MscRSAKey*)otherMscRSAKey;
-(NSData*)signHash:(NSData*)hash error:(MscX509CommonError**)error;

@end
