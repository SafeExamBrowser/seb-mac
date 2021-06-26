//
//  MscCertificateSigningRequest.m
//  MscSCEP
//
//  Created by Microsec on 2014.01.27..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import "MscCertificateSigningRequest.h"
#import "MscCertificateSigningRequest_OpenSSL_X509_REQ.h"
#import "NSString+MscASCIIExtension.h"
#import "MscX509CommonLocalException.h"
#import "MscRSAKey_OpenSSL_RSA.h"
#import "MscCertificateUtils.h"

#import <openssl/x509.h>
#import <openssl/pem.h>

@implementation MscCertificateSigningRequest

@synthesize _request;

-(id)initWithSubject:(MscX509Name*)subject challengePassword:(NSString*)challengePassword error:(MscX509CommonError**)error {
    
    if (self = [super init]) {
    
        X509_REQ *request = NULL;
        X509_NAME *name = NULL;
        
        @try {
            
            int returnCode;
            
            if (!subject) {
                NSLog(@"Failed to generate certificate signing request, subject parameter missing");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateRequest];
            }
            
            request = X509_REQ_new();
            if (!request) {
                NSLog(@"Failed to allocate memory for variable: request");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToAllocateMemory];
            }
            
            //Set DN
            name = [MscCertificateUtils convertMscX509NameToX509_NAME:subject];
            returnCode = X509_REQ_set_subject_name(request, name);
            if (returnCode != 1) {
                NSLog(@"Failed to generate request, function X509_REQ_set_subject_name returned with %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateRequest];
            }
            
            if (challengePassword && ![challengePassword isEmpty]) {
                returnCode = X509_REQ_add1_attr_by_NID(request, NID_pkcs9_challengePassword, MBSTRING_UTF8, (const unsigned char*)[challengePassword UTF8String], -1);
                if (returnCode != 1) {
                    NSLog(@"Failed to generate request, function X509_REQ_add1_attr_by_NID returned with %d", returnCode);
                    @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateRequest];
                }
            }
            
            _request = request;
            
            return self;
        }
        @catch (MscX509CommonLocalException *e) {
            
            if (error) {
                *error = [MscX509CommonError errorWithCode:e.errorCode];
            }
            X509_REQ_free(request);
            return nil;
        }
    }
    return nil;
}

-(id)initWithContentsOfFile:(NSString *)path error:(MscX509CommonError**)error {
    
    if (self = [super init]) {
        FILE* file;
        X509_REQ *request = NULL;
        
        @try {
            
            file = fopen([path fileSystemRepresentation], "r");
            if (!file) {
                NSLog(@"Failed to open file for read: %@", path);
                @throw [MscX509CommonLocalException exceptionWithCode:IOError];
            }
            
            request = PEM_read_X509_REQ(file, NULL, NULL, NULL);
            if (!request) {
                NSLog(@"Failed to read request file");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadRequest];
            }
            _request = request;
            return self;
        }
        @catch (MscX509CommonLocalException *e) {
            
            if (error) {
                *error = [MscX509CommonError errorWithCode:e.errorCode];
            }
            X509_REQ_free(request);
            return nil;
        }
        @finally {
            
            fclose(file);
        }
    }
    return nil;
}

-(void)saveToPath:(NSString *)path error:(MscX509CommonError **)error {
    
    FILE* file;
    
    @try {
        
        int returnCode;
        
        file = fopen([path fileSystemRepresentation], "w");
        if (!file) {
            NSLog(@"Failed to open file for write: %@", path);
            @throw [MscX509CommonLocalException exceptionWithCode:IOError];
        }
        
        returnCode = PEM_write_X509_REQ(file, _request);
        if (returnCode != 1) {
            NSLog(@"Failed to write request file, function PEM_write_X509_REQ returned with %d", returnCode);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToWriteRequest];
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

-(void)signWithRSAKey:(MscRSAKey*)rsaKey fingerPrintAlgorithm:(FingerPrintAlgorithm)fingerPrintAlgorithm error:(MscX509CommonError**)error {
    
    @try {
        
        int returnCode;
        
        if (!rsaKey) {
            NSLog(@"Failed to generate certificate signing request, rsaKey parameter missing");
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateRequest];
        }
        
        if (!fingerPrintAlgorithm) {
            NSLog(@"Failed to generate certificate signing request, fingerPrintAlgorithm parameter missing");
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToGenerateRequest];
        }
        
        returnCode = X509_REQ_set_pubkey(_request, rsaKey._evp_pkey);
        if (returnCode != 1) {
            NSLog(@"Failed to sign request, function X509_REQ_set_pubkey returned with %d", returnCode);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToSignRequest];
        }
        
        returnCode = X509_REQ_sign(_request, rsaKey._evp_pkey, EVP_get_digestbyname([[MscCertificateUtils getFingerPrintAlgorithmNameByEnum:fingerPrintAlgorithm] ASCIIString]));
        if (returnCode == 0) {
            NSLog(@"Failed to sign request, function X509_REQ_sign returned with %d", returnCode);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToSignRequest];
        }
    }
    @catch (MscX509CommonLocalException *e) {
        
        if (error) {
            *error = [MscX509CommonError errorWithCode:e.errorCode];
        }
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    unsigned char *requestData = NULL;
    
    @try {
        
        int requestDataLength = i2d_X509_REQ(_request, &requestData);
        
        if (requestDataLength < 1) {
            NSLog(@"Failed to encode certificate signing request, function i2d_X509_REQ returned with %d", requestDataLength);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToEncodeRequest];
        }
        
        [aCoder encodeBytes:requestData length:requestDataLength forKey:@"requestData"];
    }
    @finally {
        
        OPENSSL_free(requestData);
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super init]) {
        
        X509_REQ *request = NULL;
        const unsigned char *requestData = NULL;
        
        @try {
            
            NSUInteger requestDataLength;
            
            requestData = [aDecoder decodeBytesForKey:@"requestData" returnedLength:&requestDataLength];
            if (requestDataLength < 1) {
                NSLog(@"Failed to decode certificate signing request, function decodeBytesForKey returned with %lu", (unsigned long)requestDataLength);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToDecodeRequest];
            }
            
            request = d2i_X509_REQ(NULL, &requestData, (unsigned long)requestDataLength);
            if (request == NULL) {
                NSLog(@"Failed to decode certificate signing request, function: d2i_X509_REQ");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToDecodeRequest];
            }
            _request = request;
            return self;
            
        }
        @catch (MscX509CommonLocalException *e) {
            
            X509_REQ_free(request);
            return nil;
        }
    }
    return nil;
}

-(BOOL)isEqualToMscCertificateSigningRequest:(MscCertificateSigningRequest*)otherMscCertificateSigningRequest {
    
    
    unsigned char *myRequest = NULL;
    unsigned char *otherRequest = NULL;
    
    @try {
        
        int myRequestLength = i2d_X509_REQ(_request, &myRequest);
        int otherRequestLength = i2d_X509_REQ(otherMscCertificateSigningRequest._request, &otherRequest);
        
        if (myRequestLength < 1) {
            NSLog(@"Failed to read certificate signing request, function i2d_X509_REQ returned with %d", myRequestLength);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadRequest];
        }
        
        if (otherRequestLength < 1) {
            NSLog(@"Failed to read certificate signing request, function i2d_X509_REQ returned with %d", otherRequestLength);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadRequest];
        }
        
        if (myRequestLength != otherRequestLength) {
            return NO;
        }
        
        return memcmp(myRequest, otherRequest, otherRequestLength) == 0;
    }
    @finally {
        
        OPENSSL_free(myRequest);
        OPENSSL_free(otherRequest);
        
    }
}

-(void)dealloc {
    X509_REQ_free(_request);
}

@end
