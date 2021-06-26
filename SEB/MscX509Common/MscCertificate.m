//
//  MscCertificate.m
//  MscSCEP
//
//  Created by Microsec on 2014.01.27..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import "MscCertificate.h"
#import "MscCertificate_OpenSSL_X509.h"
#import "NSString+MscASCIIExtension.h"
#import "MscX509CommonLocalException.h"
#import "MscCertificateSigningRequest_OpenSSL_X509_REQ.h"
#import "MscRSAKey_OpenSSL_RSA.h"
#import "MscCertificateUtils.h"
#import <openssl/pem.h>
#import <openssl/sha.h>
#import <openssl/x509v3.h>

#define SELFSIGNED_EXPIRE_DAYS 365

@implementation MscCertificate

@synthesize _x509;
@synthesize subject = _subject, issuer = _issuer, serial = _serial, validFrom = _validFrom, validTo = _validTo, sha1Fingerprint = _sha1Fingerprint, keyUsage = _keyUsage, isRootCertificate = _isRootCertificate;

-(id)initWithX509:(X509 *)x509 {
    
    if (self = [super init]) {
        _x509 = x509;
        return self;
    }
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    unsigned char *certificateData = NULL;
    
    @try {
        
        int certificateDataLength = i2d_X509(_x509, &certificateData);
        
        if (certificateDataLength < 1) {
            NSLog(@"Failed to encode certificate, function i2d_X509 returned with %d", certificateDataLength);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToEncodeCertificate];
        }
        
        [aCoder encodeBytes:certificateData length:certificateDataLength forKey:@"certificateData"];
    }
    @finally {
        
        OPENSSL_free(certificateData);
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super init]) {
        
        X509 *certificate = NULL;
        const unsigned char *certificateData = NULL;
        
        @try {
            
            NSUInteger certificateDataLength;
            
            certificateData = [aDecoder decodeBytesForKey:@"certificateData" returnedLength:&certificateDataLength];
            if (certificateDataLength < 1) {
                NSLog(@"Failed to decode certificate, function decodeBytesForKey returned with %lu", (unsigned long)certificateDataLength);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToDecodeCertificate];
            }
            
            certificate = d2i_X509(NULL, &certificateData, (unsigned long)certificateDataLength);
            if (certificate == NULL) {
                NSLog(@"Failed to decode certificate, function: d2i_X509");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToDecodeCertificate];
            }
            _x509 = certificate;
            return self;
            
        }
        @catch (MscX509CommonLocalException *e) {
            
            X509_free(certificate);
            return nil;
        }
    }
    return nil;
}

- (BOOL)isEqualToMscCertificate:(MscCertificate*)otherMscCertificate {
    return X509_cmp(_x509, otherMscCertificate._x509) == 0;
}

-(id)initWithRequest:(MscCertificateSigningRequest*)request error:(MscX509CommonError**)error {
    
    if (self = [super init]) {
        
        ASN1_INTEGER* serial = NULL;
        X509* x509 = NULL;
        
        @try {
            
            int returnCode;
            
            if (!request) {
                NSLog(@"Failed to generate certificate, request parameter missing");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateCertificate];
            }
            
            X509_NAME* subject = X509_REQ_get_subject_name(request._request);
            if(!subject) {
                NSLog(@"Failed to generate certificate, function: X509_REQ_get_subject_name");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateCertificate];
            }
            
            x509 = X509_new();
            if(!x509) {
                NSLog(@"Failed to allocate memory for variable: selfSignedCertificate");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToAllocateMemory];
            }
            
            returnCode = X509_set_version(x509, 2L);
            if (returnCode != 1) {
                NSLog(@"Failed to generate certificate, function X509_set_version returned with: %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateCertificate];
            }
            
            NSError* localError;
            NSString* serialNumber = [MscCertificateUtils getCertificateSigningRequestPublicKeyFingerPrint:request error:&localError];
            if (nil != localError) {
                @throw [MscX509CommonLocalException exceptionWithCode:localError.code];
            }
            
            serial = [MscCertificateUtils convertNSStringToASN1_INTEGER:serialNumber];
            returnCode = X509_set_serialNumber(x509, serial);
            if (returnCode != 1) {
                NSLog(@"Failed to generate certificate, function X509_set_serialNumber returned with: %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateCertificate];
            }
            
            returnCode = X509_set_subject_name(x509, subject);
            if (returnCode != 1) {
                NSLog(@"Failed to generate certificate, function X509_set_subject_name returned with: %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateCertificate];
            }
            
            returnCode = X509_set_issuer_name(x509, subject);
            if (returnCode != 1) {
                NSLog(@"Failed to generate certificate, function X509_set_issuer_name returned with: %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateCertificate];
            }
            
            if (!X509_gmtime_adj(X509_get_notBefore(x509), 0)) {
                NSLog(@"Failed to generate certificate, function: X509_gmtime_adj");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateCertificate];
            }
            if (!X509_gmtime_adj(X509_get_notAfter(x509), SELFSIGNED_EXPIRE_DAYS * 24 * 60)) {
                NSLog(@"Failed to generate certificate, function: X509_gmtime_adj");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateCertificate];
            }
            
            _x509 = x509;
            
            return self;
        }
        @catch (MscX509CommonLocalException *e) {
            
            if (error) {
                *error = [MscX509CommonError errorWithCode:e.errorCode];
            }
            ASN1_INTEGER_free(serial);
            X509_free(x509);
            return nil;
        }
    }
    return nil;
}

-(id)initWithContentsOfFile:(NSString*)path error:(MscX509CommonError**)error {
    
    if (self = [super init]) {
        FILE* file;
        X509 *x509 = NULL;
    
        @try {
        
            file = fopen([path fileSystemRepresentation], "r");
            if (!file) {
                NSLog(@"Failed to open file for read: %@", path);
                @throw [MscX509CommonLocalException exceptionWithCode:IOError];
            }
        
            x509 = PEM_read_X509(file, NULL, NULL, NULL);
            if (!x509) {
                NSLog(@"Failed to read certificate file");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadCertificate];
            }
            _x509 = x509;
            return self;
        }
        @catch (MscX509CommonLocalException *e) {
        
            if (error) {
                *error = [MscX509CommonError errorWithCode:e.errorCode];
            }
            X509_free(x509);
            return nil;
        }
        @finally {
        
            fclose(file);
        }
    }
    return nil;
}

-(void)saveToPath:(NSString*)path error:(MscX509CommonError**)error {
    
    FILE* file;
    
    @try {
        
        int returnCode;
        
        file = fopen([path fileSystemRepresentation], "w");
        if (!file) {
            NSLog(@"Failed to open file for write: %@", path);
            @throw [MscX509CommonLocalException exceptionWithCode:IOError];
        }
        
        returnCode = PEM_write_X509(file, _x509);
        if (returnCode != 1) {
            NSLog(@"Failed to write certificate file, function PEM_write_X509 returned with %d", returnCode);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToWriteCertificate];
        }
    }
    @catch (MscX509CommonLocalException *e) {
        
        if (error) {
            *error = [MscX509CommonError errorWithCode:e.errorCode];
        }
        return;
    }
    @finally {
        
        fclose(file);
    }
}

-(MscX509Name*)subject {
    X509_NAME* subjectName = NULL;
    
    subjectName = X509_get_subject_name(_x509);
    if (!subjectName) {
        NSLog(@"Failed to read certificate, function: X509_get_subject_name");
        return nil;
    }
    
    MscX509Name* subject = [MscCertificateUtils convertX509_NAMEToMscX509Name:subjectName];
    
    return subject;
}

-(MscX509Name*)issuer {
    
    X509_NAME* issuerName = NULL;

    issuerName = X509_get_issuer_name(_x509);
    if (!issuerName) {
        NSLog(@"Failed to read certificate, function: X509_get_issuer_name");
        return nil;
    }
    
    MscX509Name* issuer = [MscCertificateUtils convertX509_NAMEToMscX509Name:issuerName];
    return issuer;
}

-(NSString*)serial {
    
        ASN1_INTEGER* serialNumber = X509_get_serialNumber(_x509);
        if (!serialNumber) {
            NSLog(@"Failed to read certificate, function: X509_get_serialNumber");
            return nil;
        }
    
        NSString* serial = [MscCertificateUtils convertASN1_INTEGERToNSString:serialNumber];

        return serial;
}

-(NSDate*)validFrom {
    
    ASN1_TIME* notBeforeASN1_TIME = X509_get_notBefore(_x509);
    if (!notBeforeASN1_TIME) {
        NSLog(@"Failed to read certificate, function: X509_get_notBefore");
        return nil;
    }
    
    NSDate* notBefore = [MscCertificateUtils convertASN1_TIMEToNSDate:notBeforeASN1_TIME];
    
    return notBefore;
}

-(NSDate*)validTo {
    
    ASN1_TIME* notAfterASN1_TIME = X509_get_notAfter(_x509);
    if (!notAfterASN1_TIME) {
        NSLog(@"Failed to read certificate, function: X509_get_notAfter");
        return nil;
    }

    NSDate* notAfter = [MscCertificateUtils convertASN1_TIMEToNSDate:notAfterASN1_TIME];
    return notAfter;
}

-(NSString*)sha1Fingerprint {
    
    unsigned int digestLength;
    unsigned char digest[SHA_DIGEST_LENGTH];
    
    if (!X509_digest(_x509, EVP_sha1(), digest, &digestLength)) {
        NSLog(@"Failed to digest certificate, function: X509_digest");
        return nil;
    }
    
    NSMutableString* digestString = [[NSMutableString alloc] init];
    for (int i = 0; i < digestLength; i++) {
        [digestString appendFormat:@"%02X", digest[i]];
    }
    
    return digestString;
}

-(void)signWithRSAKey:(MscRSAKey*)rsaKey fingerPrintAlgorithm:(FingerPrintAlgorithm)fingerPrintAlgorithm error:(MscX509CommonError**)error {
    
    @try {
        
        int returnCode;
        
        if (!rsaKey) {
            NSLog(@"Failed to sign certificate, rsaKey parameter missing");
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToSignCertificate];
        }
        
        if (!fingerPrintAlgorithm) {
            NSLog(@"Failed to sign certificate, fingerPrintAlgorithm parameter missing");
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToSignCertificate];
        }
        
        returnCode = X509_set_pubkey(_x509, rsaKey._evp_pkey);
        if (returnCode != 1) {
            NSLog(@"Failed to sign certificate, function X509_set_pubkey returned with: %d", returnCode);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateCertificate];
        }
        
        returnCode = X509_sign(_x509, rsaKey._evp_pkey, EVP_get_digestbyname([[MscCertificateUtils getFingerPrintAlgorithmNameByEnum:fingerPrintAlgorithm] ASCIIString]));
        if (!returnCode) {
            NSLog(@"Failed to sign certificate, function X509_sign returned with: %d", returnCode);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToSignCertificate];
        }
        
    }
    @catch (MscX509CommonLocalException *e) {
        
        if (error) {
            *error = [MscX509CommonError errorWithCode:e.errorCode];
        }
    }
}

-(id)initWithData:(NSData*)data error:(MscX509CommonError**)error
{
    self = [super init];
    if (self) {
        
        X509* x509 = NULL;
        
        @try {
            
            const unsigned char* certificateData = [data bytes];
            long certificateDataLength = [data length];
            
            x509 = d2i_X509(NULL, &certificateData, certificateDataLength);
            if (!x509) {
                NSLog(@"Failed to read certificate, function: d2i_X509");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadCertificate];
            }
            _x509 = x509;
            return self;
        }
        @catch (MscX509CommonLocalException *e) {
            
            if (error) {
                *error = [MscX509CommonError errorWithCode:e.errorCode];
            }
            X509_free(x509);
            return nil;
        }
    }
}

-(MscKeyUsage)keyUsage {
    
    MscKeyUsage keyUsages = 0x00;
    ASN1_BIT_STRING* keyUsage = NULL;
    
    @try {
        
        X509_check_ca(_x509);

        keyUsage = X509_get_ext_d2i(_x509, NID_key_usage, NULL, NULL);
        if(!keyUsage) {
            NSLog(@"Failed to read certificate, function: X509_get_ext_d2i");
            return keyUsages;
        }
        else
        {
            for (int i = 0; i < 8; i++) {
                if (ASN1_BIT_STRING_get_bit(keyUsage, i)) {
                    keyUsages = keyUsages | [MscCertificateUtils getKeyUsageByIndex:i];
                }
            }
        }
        return keyUsages;
    }
    @finally {
        ASN1_BIT_STRING_free(keyUsage);
    }
}

-(BOOL)isRootCertificate {
    
    X509_check_ca(_x509);
    if (X509_check_issued(_x509, _x509) == X509_V_OK){
        return YES;
    }
    return NO;
}

-(NSString*)PEMFormat {
    
    BIO* memBIO = NULL;
    
    @try {
        
        int returnCode;
        
        memBIO = BIO_new(BIO_s_mem());
        if (!memBIO) {
            NSLog(@"Failed to allocate memory for variable: memBIO");
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToAllocateMemory];
        }
        
        returnCode = PEM_write_bio_X509(memBIO, self._x509);
        if (returnCode != 1) {
            NSLog(@"Failed to read certificate, function PEM_write_bio_X509 returned with: %d", returnCode);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadCertificate];
        }
        
        char* pemFormat = NULL;
        long pemFormatLength = BIO_get_mem_data(memBIO, &pemFormat);
        if (pemFormatLength < 1) {
            NSLog(@"Failed to read certificate, function BIO_get_mem_data returned with: %ld", pemFormatLength);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadCertificate];
        }
        
        return [[NSString alloc] initWithBytes:pemFormat length:pemFormatLength encoding:NSASCIIStringEncoding];
        
    }
    @catch (MscX509CommonLocalException *e) {
        
        return nil;
    }
    @finally {
        
        BIO_free(memBIO);
    }
}

-(void)dealloc {
    X509_free(_x509);
}

@end
