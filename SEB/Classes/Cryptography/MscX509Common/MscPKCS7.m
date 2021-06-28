//
//  MscPKCS7.m
//  MscX509Common
//
//  Created by Lendvai Richárd on 2015. 02. 23..
//  Copyright (c) 2015. Microsec. All rights reserved.
//

#import "MscPKCS7.h"
#import "MscX509CommonLocalException.h"
#import "MscCertificate_OpenSSL_X509.h"
#import "MscRSAKey_OpenSSL_RSA.h"

#import <openssl/pkcs7.h>

@implementation MscPKCS7

-(NSData*)signData:(NSData*)data key:(MscPKCS12*)pkcs12 password:(NSString*)password error:(MscX509CommonError**)error {
    
    PKCS7* p7 = NULL;
    BIO *memBIO = NULL;
    unsigned char* signedData = NULL;
    
    @try {
        
        int flags = PKCS7_DETACHED | PKCS7_NOCERTS | PKCS7_NOATTR | PKCS7_BINARY | PKCS7_PARTIAL;
        
        memBIO = BIO_new(BIO_s_mem());
        if (!memBIO) {
            NSLog(@"Failed to allocate memory for variable: memoryBIO");
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToAllocateMemory];
        }
        
        MscX509CommonError* localError;
        MscCertificate* signerCertificate = [pkcs12 getCertificateWithPassword:password error:&localError];
        if (localError) {
            @throw [MscX509CommonLocalException exceptionWithCode:localError.code];
        }
        
        MscRSAKey* signerKey = [pkcs12 getRSAKeyWithPassword:password error:&localError];
        if (localError) {
            @throw [MscX509CommonLocalException exceptionWithCode:localError.code];
        }
        
        p7 = PKCS7_sign(NULL, NULL, NULL, memBIO, flags);
        if (!p7) {
            NSLog(@"Failed to create PKCS7 signature, function: PKCS7_sign");
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToCreatePKCS7Signature];
        }
        
        if (!PKCS7_sign_add_signer(p7, signerCertificate._x509, signerKey._evp_pkey, EVP_sha256(), flags)) {
            NSLog(@"Failed to create PKCS7 signature, function: PKCS7_sign_add_signer");
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToCreatePKCS7Signature];
        }
        
        if (!PKCS7_final(p7, memBIO, flags)) {
            NSLog(@"Failed to create PKCS7 signature, function: PKCS7_final");
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToCreatePKCS7Signature];
        }
        
        int signedDataLength = i2d_PKCS7(p7, &signedData);
        if (signedDataLength < 1) {
            NSLog(@"Failed to encode PKCS7, function i2d_PKCS7 returned with: %d", signedDataLength);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToEncodePKCS7];
        }
        
        return [NSData dataWithBytes:signedData length:signedDataLength];
    }
    @catch (MscX509CommonLocalException *e) {
        
        if (error) {
            *error = [MscX509CommonError errorWithCode:e.errorCode];
        }
        return nil;
    }
    @finally {
        
        PKCS7_free(p7);
        BIO_free(memBIO);
        OPENSSL_free(signedData);
    }
}

@end
