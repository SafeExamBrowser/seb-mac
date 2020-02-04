//
//  MscCertificateSubject.m
//  MscSCEP
//
//  Created by Microsec on 2014.01.14..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import "MscX509Name.h"


@implementation MscX509Name

@synthesize commonName, localityName, stateOrProvinceName, organizationName, organizationalUnitName, countryName, streetAddress, domainComponent, userid, serialNumber;

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:commonName forKey:@"commonName"];
    [aCoder encodeObject:localityName forKey:@"localityName"];
    [aCoder encodeObject:stateOrProvinceName forKey:@"stateOrProvinceName"];
    [aCoder encodeObject:organizationName forKey:@"organizationName"];
    [aCoder encodeObject:organizationalUnitName forKey:@"organizationalUnitName"];
    [aCoder encodeObject:countryName forKey:@"countryName"];
    [aCoder encodeObject:streetAddress forKey:@"streetAddress"];
    [aCoder encodeObject:domainComponent forKey:@"domainComponent"];
    [aCoder encodeObject:userid forKey:@"userid"];
    [aCoder encodeObject:serialNumber forKey:@"serialNumber"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super init]) {
        
        commonName = [aDecoder decodeObjectForKey:@"commonName"];
        localityName = [aDecoder decodeObjectForKey:@"localityName"];
        stateOrProvinceName = [aDecoder decodeObjectForKey:@"stateOrProvinceName"];
        organizationName = [aDecoder decodeObjectForKey:@"organizationName"];
        organizationalUnitName = [aDecoder decodeObjectForKey:@"organizationalUnitName"];
        countryName = [aDecoder decodeObjectForKey:@"countryName"];
        streetAddress = [aDecoder decodeObjectForKey:@"streetAddress"];
        domainComponent = [aDecoder decodeObjectForKey:@"domainComponent"];
        userid = [aDecoder decodeObjectForKey:@"userid"];
        serialNumber = [aDecoder decodeObjectForKey:@"serialNumber"];
        
        return self;
    }
    return nil;
}

- (BOOL)isEqualToMscX509Name:(MscX509Name*)otherMscX509Name {
    return [commonName isEqualToString:otherMscX509Name.commonName] &&
    [localityName isEqualToString:otherMscX509Name.localityName] &&
    [stateOrProvinceName isEqualToString:otherMscX509Name.stateOrProvinceName] &&
    [organizationName isEqualToString:otherMscX509Name.organizationName] &&
    [organizationalUnitName isEqualToString:otherMscX509Name.organizationalUnitName] &&
    [countryName isEqualToString:otherMscX509Name.countryName] &&
    [streetAddress isEqualToString:otherMscX509Name.streetAddress] &&
    [domainComponent isEqualToString:otherMscX509Name.domainComponent] &&
    [userid isEqualToString:otherMscX509Name.userid] &&
    [serialNumber isEqualToString:otherMscX509Name.serialNumber];
}

@end
