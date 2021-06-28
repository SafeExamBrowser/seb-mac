//
//  MscIssuerAndSerial.m
//  MscSCEP
//
//  Created by Microsec on 2014.02.07..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import "MscIssuerAndSerial.h"

@implementation MscIssuerAndSerial

@synthesize issuer, serial;

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:issuer forKey:@"issuer"];
    [aCoder encodeObject:serial forKey:@"serial"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super init]) {
        
        issuer = [aDecoder decodeObjectForKey:@"issuer"];
        serial = [aDecoder decodeObjectForKey:@"serial"];
        
        return self;
    }
    return nil;
}

- (BOOL)isEqualToMscIssuerAndSerial:(MscIssuerAndSerial*)otherMscIssuerAndSerial {
    return [issuer isEqualToMscX509Name:otherMscIssuerAndSerial.issuer] &&
    [serial isEqualToString:otherMscIssuerAndSerial.serial];
}

@end
