//
//  MscCertificateSigningRequest.h
//  MscSCEP
//
//  Created by Microsec on 2014.01.27..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MscX509Name.h"
#import "MscRSAKey.h"

typedef NS_ENUM(NSUInteger, FingerPrintAlgorithm) {
    FingerPrintAlgorithm_MD5,
    FingerPrintAlgorithm_SHA1,
    FingerPrintAlgorithm_SHA256,
    FingerPrintAlgorithm_SHA512
};

@interface MscCertificateSigningRequest : NSObject<NSCoding>

-(MscCertificateSigningRequest*) init __attribute__((unavailable("please, use initWithSubject or initWithContentsOfFile for initialization")));
-(id)initWithSubject:(MscX509Name*)subject challengePassword:(NSString*)challengePassword error:(MscX509CommonError**)error;
-(id)initWithContentsOfFile:(NSString*)path error:(MscX509CommonError**)error;
-(void)saveToPath:(NSString *)path error:(MscX509CommonError **)error;
-(void)signWithRSAKey:(MscRSAKey*)rsaKey fingerPrintAlgorithm:(FingerPrintAlgorithm)fingerPrintAlgorithm error:(MscX509CommonError**)error;
-(BOOL)isEqualToMscCertificateSigningRequest:(MscCertificateSigningRequest*)otherMscCertificateSigningRequest;

@end
