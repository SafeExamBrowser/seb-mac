//
//  MscIssuerAndSerial.h
//  MscSCEP
//
//  Created by Microsec on 2014.02.07..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MscX509Name.h"

@interface MscIssuerAndSerial : NSObject<NSCoding>

@property MscX509Name* issuer;
@property NSString* serial;

- (BOOL)isEqualToMscIssuerAndSerial:(MscIssuerAndSerial*)otherMscIssuerAndSerial;

@end
