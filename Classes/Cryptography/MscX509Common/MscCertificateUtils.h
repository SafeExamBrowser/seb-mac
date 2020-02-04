//
//  MscCertificateUtils.h
//  MscSCEP
//
//  Created by Microsec on 2014.02.12..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MscCertificate.h"
#import "MscCertificateSigningRequest.h"
#import "MscX509Name.h"
#import <openssl/x509.h>

@interface MscCertificateUtils : NSObject

+(X509_NAME*)convertMscX509NameToX509_NAME:(MscX509Name*)subject;
+(MscX509Name*)convertX509_NAMEToMscX509Name:(X509_NAME*)name;
+(NSString*)getCertificateSigningRequestPublicKeyFingerPrint:(MscCertificateSigningRequest*)request error:(MscX509CommonError**)error;
+(NSString*)getCertificatePublicKeyFingerPrint:(MscCertificate*)certificate error:(MscX509CommonError**)error;
+(NSString*)convertASN1_INTEGERToNSString:(ASN1_INTEGER*)serialNumber;
+(ASN1_INTEGER*)convertNSStringToASN1_INTEGER:(NSString*)serialNumber;
+(NSDate*)convertASN1_TIMEToNSDate:(ASN1_TIME*)asn1_time;
+(NSString*)getFingerPrintAlgorithmNameByEnum: (FingerPrintAlgorithm)fingerPrintAlgorithm;
+(MscKeyUsage)getKeyUsageByIndex:(int)index;

@end
