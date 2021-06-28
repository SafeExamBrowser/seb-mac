//
//  MscCertificate.h
//  MscSCEP
//
//  Created by Microsec on 2014.01.27..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MscCertificateSigningRequest.h"
#import "MscCertificateRevocationList.h"

#define SELFSIGNED_EXPIRE_DAYS  365

typedef NS_OPTIONS(NSUInteger, MscKeyUsage) {
    DigitalSignature    = 1 << 0,
    NonRepudiation      = 1 << 1,
    KeyEncipherment     = 1 << 2,
    DataEncipherment    = 1 << 3,
    KeyAgreement        = 1 << 4,
    KeyCertSign         = 1 << 5,
    CRLSign             = 1 << 6,
    EncipherOnly        = 1 << 7,
    DecipherOnly        = 1 << 8,
};

@interface MscCertificate : NSObject<NSCoding>

@property(readonly) MscX509Name* subject;
@property(readonly) MscX509Name* issuer;
@property(readonly) NSString* serial;
@property(readonly) NSDate* validFrom;
@property(readonly) NSDate* validTo;
@property(readonly) NSString* sha1Fingerprint;
@property(readonly) MscKeyUsage keyUsage;
@property(readonly) BOOL isRootCertificate;

-(MscCertificate*) init __attribute__((unavailable("please, use initWithRequest or initWithContentsOfFile for initialization")));

-(id)initWithRequest:(MscCertificateSigningRequest*)request error:(MscX509CommonError**)error;
-(id)initWithContentsOfFile:(NSString*)path error:(MscX509CommonError**)error;
-(id)initWithData:(NSData*)data error:(MscX509CommonError**)error;
-(void)saveToPath:(NSString*)path error:(MscX509CommonError**)error;
-(void)signWithRSAKey:(MscRSAKey*)rsaKey fingerPrintAlgorithm:(FingerPrintAlgorithm)fingerPrintAlgorithm error:(MscX509CommonError**)error;
-(BOOL)isEqualToMscCertificate:(MscCertificate*)otherMscCertificate;
-(NSString*)PEMFormat;


@end
