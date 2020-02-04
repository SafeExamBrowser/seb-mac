//
//  MscX509CommonError.h
//  MscX509Common
//
//  Created by Microsec on 2014.08.07..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>

#define FailedToAllocateMemory                      1000
#define IOError                                     1001
#define FailedToGenerateKey                         1002
#define FailedToReadKey                             1003
#define FailedToWriteKey                            1004
#define FailedToEncodeKey                           1005
#define FailedToDecodeKey                           1006
#define FailedToGenerateRequest                     1007
#define FailedToReadRequest                         1008
#define FailedToWriteRequest                        1009
#define FailedToSignRequest                         1010
#define FailedToEncodeRequest                       1011
#define FailedToDecodeRequest                       1012
#define FailedToGenerateCertificate                 1013
#define FailedToReadCertificate                     1014
#define FailedToWriteCertificate                    1015
#define FailedToSignCertificate                     1016
#define FailedToEncodeCertificate                   1017
#define FailedToDecodeCertificate                   1018
#define FailedToReadCertificateRevocationList       1019
#define FailedToWriteCertificateRevocationList      1020
#define FailedToEncodeCertificateRevocationList     1021
#define FailedToDecodeCertificateRevocationList     1022
#define FailedToGeneratePKCS12                      1023
#define FailedToReadPKCS12                          1024
#define FailedToWritePKCS12                         1025
#define FailedToParsePKCS12                         1026
#define FailedToEncodePKCS12                        1027
#define FailedToDecodePKCS12                        1028
#define FailedToConvertCertificateSubject           1029
#define FailedToConvertSerialNumber                 1030
#define FailedToConvertASN1_TIME                    1031
#define FailedToDigestCertificate                   1032
#define FailedToSignHash                            1033
#define FailedToCreatePKCS7Signature                1034
#define FailedToEncodePKCS7                         1035

@interface MscX509CommonError : NSError

+(id)errorWithCode:(NSInteger)code;

@end
