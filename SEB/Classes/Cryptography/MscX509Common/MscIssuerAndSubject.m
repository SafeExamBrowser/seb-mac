//
//  MscIssuerAndSubject.m
//  MscSCEP
//
//  Created by Microsec on 2014.02.07..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import "MscIssuerAndSubject.h"

@implementation MscIssuerAndSubject

@synthesize issuer, subject;

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:issuer forKey:@"issuer"];
    [aCoder encodeObject:subject forKey:@"subject"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super init]) {
        
        issuer = [aDecoder decodeObjectForKey:@"issuer"];
        subject = [aDecoder decodeObjectForKey:@"subject"];
        
        return self;
    }
    return nil;
}

- (BOOL)isEqualToMscIssuerAndSubject:(MscIssuerAndSubject*)otherMscIssuerAndSubject {
    return [issuer isEqualToMscX509Name:otherMscIssuerAndSubject.issuer] &&
    [subject isEqualToMscX509Name:otherMscIssuerAndSubject.subject];
}

@end
