//
//  MscCertificateRevocationList.m
//  MscSCEP
//
//  Created by Microsec on 2014.02.07..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import "MscCertificateRevocationList.h"
#import "MscCertificateRevocationList_OpenSSL_X509_CRL.h"
#import "MscX509CommonLocalException.h"
#import "MscX509CommonError.h"

#import "NSString+MscASCIIExtension.h"
#import <openssl/pem.h>

@implementation MscCertificateRevocationList

@synthesize _crl;

-(id)initWithX509_CRL:(X509_CRL *)crl {
    
    if (self = [super init]) {
        _crl = crl;
        return self;
    }
    return nil;
}

-(id)initWithContentsOfFile:(NSString*)path error:(NSError**)error {
    
    if (self = [super init]) {
        FILE* file;
        X509_CRL *crl = NULL;
        
        @try {
            
            file = fopen([path fileSystemRepresentation], "r");
            if (!file) {
                NSLog(@"Failed to open file for read: %@", path);
                @throw [MscX509CommonLocalException exceptionWithCode:IOError];
            }
            
            crl = PEM_read_X509_CRL(file, NULL, NULL, NULL);
            if (!crl) {
                NSLog(@"Failed to read certificate revocation list file");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadCertificateRevocationList];
            }
            _crl = crl;
            return self;
        }
        @catch (MscX509CommonLocalException *e) {
            
            if (error) {
                *error = [MscX509CommonError errorWithCode:e.errorCode];
            }
            X509_CRL_free(crl);
            return nil;
        }
        @finally {
            
            fclose(file);
        }
    }
    return nil;
}

-(void)saveToPath:(NSString*)path error:(NSError**)error {
    
    FILE* file;
    
    @try {
        
        int returnCode;
        
        file = fopen([path fileSystemRepresentation], "w");
        if (!file) {
            NSLog(@"Failed to open file for write: %@", path);
            @throw [MscX509CommonLocalException exceptionWithCode:IOError];
            
        }
        
        returnCode = PEM_write_X509_CRL(file, _crl);
        if (returnCode != 1) {
            NSLog(@"Failed to write certificate revocation list file, function PEM_write_X509_CRL returned with %d", returnCode);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToWriteCertificateRevocationList];
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

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    unsigned char *crlData = NULL;
    
    @try {
        
        int crlDataLength = i2d_X509_CRL(_crl, &crlData);
        
        if (crlDataLength < 1) {
            NSLog(@"Failed to encode certificate revocation list, function i2d_X509_CRL returned with %d", crlDataLength);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToEncodeCertificateRevocationList];
        }
        
        [aCoder encodeBytes:crlData length:crlDataLength forKey:@"crlData"];
    }
    @finally {
        
        OPENSSL_free(crlData);
    }
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super init]) {
        
        X509_CRL *crl = NULL;
        const unsigned char *crlData = NULL;
        
        @try {
            
            NSUInteger crlDataLength;
            
            crlData = [aDecoder decodeBytesForKey:@"crlData" returnedLength:&crlDataLength];
            if (crlDataLength < 1) {
                NSLog(@"Failed to decode certificate revocation list, function decodeBytesForKey returned with %lu", (unsigned long)crlDataLength);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToDecodeCertificateRevocationList];
            }
            
            crl = d2i_X509_CRL(NULL, &crlData, (unsigned long)crlDataLength);
            if (crl == NULL) {
                NSLog(@"Failed to decode certificate revocation list, function: d2i_X509_CRL");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToDecodeCertificateRevocationList];
            }
            _crl = crl;
            return self;
            
        }
        @catch (MscX509CommonLocalException *e) {
            
            X509_CRL_free(crl);
            return nil;
        }
    }
    return nil;
}

- (BOOL)isEqualToMscCertificateRevocationList:(MscCertificateRevocationList*)otherMscCertificateRevocationList {
    return X509_CRL_cmp(_crl, otherMscCertificateRevocationList._crl) == 0;
}

-(void)dealloc {
    
    X509_CRL_free(_crl);
}

@end
