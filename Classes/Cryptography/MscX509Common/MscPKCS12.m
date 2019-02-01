//
//  MscPKCS12.m
//  MscSCEP
//
//  Created by Microsec on 2014.02.18..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import "MscPKCS12.h"
#import <openssl/pkcs12.h>
#import "MscX509CommonLocalException.h"
#import "MscPKCS12_OpenSSL_PKCS12.h"
#import "MscCertificate_OpenSSL_X509.h"
#import "MscRSAKey_OpenSSL_RSA.h"
#import "NSString+MscASCIIExtension.h"

@implementation MscPKCS12

@synthesize _pkcs12;

-(id)initWithPKCS12:(PKCS12*)pkcs12 {
    
    if (self = [super init]) {
        _pkcs12 = pkcs12;
        return self;
    }
    return nil;
}

-(id)initWithContentsOfFile:(NSString *)path error:(MscX509CommonError **)error {
    
    if (self = [super init]) {
        FILE* file = NULL;
        PKCS12 *pkcs12 = NULL;
        
        @try {
            
            file = fopen([path fileSystemRepresentation], "r");
            if (!file) {
                NSLog(@"Failed to open file for read: %@", path);
                @throw [MscX509CommonLocalException exceptionWithCode:IOError];
            }
            
            pkcs12 =  d2i_PKCS12_fp(file, NULL);
            if (!pkcs12) {
                NSLog(@"Failed to read PKCS12 file");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadPKCS12];
            }
            _pkcs12 = pkcs12;
            
            return self;
        }
        @catch (MscX509CommonLocalException *e) {
            
            if (error) {
                *error = [MscX509CommonError errorWithCode:e.errorCode];
            }
            PKCS12_free(pkcs12);
            return nil;
        }
        @finally {
            fclose(file);
        }
    }
    return nil;
}

-(id)initWithRSAKey:(MscRSAKey*)rsaKey certificate:(MscCertificate*)certificate password:(NSString*)password error:(MscX509CommonError **)error {
    
    if (self = [super init]) {
        
        PKCS12 *pkcs12 = NULL;
        
        @try {
            
            int returnCode;
            
            if (!rsaKey) {
                NSLog(@"Failed to generate PKCS12, rsaKey parameter is missing");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGeneratePKCS12];
            }
            
            if (!certificate) {
                NSLog(@"Failed to generate PKCS12, certificate parameter is missing");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGeneratePKCS12];
            }
            
            returnCode = X509_check_private_key(certificate._x509, rsaKey._evp_pkey);
            if (returnCode != 1) {
                NSLog(@"Failed to generate PKCS12, function X509_check_private_key returned with %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGeneratePKCS12];
            }
            
            OpenSSL_add_all_algorithms();
            OpenSSL_add_all_ciphers();
            OpenSSL_add_all_digests();
            
            pkcs12 = PKCS12_create((char *)[password UTF8String], (char*)[SEBFullAppName UTF8String], rsaKey._evp_pkey, certificate._x509, NULL, NID_pbe_WithSHA1And3_Key_TripleDES_CBC, NID_pbe_WithSHA1And3_Key_TripleDES_CBC, PKCS12_DEFAULT_ITER, PKCS12_DEFAULT_ITER, 0);
            if (!pkcs12) {
                NSLog(@"Failed to generate PKCS12, function: PKCS12_create");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToGeneratePKCS12];
            }
            
            _pkcs12 = pkcs12;
            
            return self;
        }
        @catch (MscX509CommonLocalException *e) {
            
            if (error) {
                *error = [MscX509CommonError errorWithCode:e.errorCode];
            }
            PKCS12_free(pkcs12);
            return nil;
        }
    }
    return nil;
}

-(void)saveToPath:(NSString *)path error:(MscX509CommonError **)error {
    
    FILE* file = NULL;
    
    @try {
        
        int returnCode;
        
        file = fopen([path fileSystemRepresentation], "w");
        if (!file) {
            NSLog(@"Failed to open file for write: %@", path);
            @throw [MscX509CommonLocalException exceptionWithCode:IOError];
        }
        
        returnCode = i2d_PKCS12_fp(file, _pkcs12);
        if (returnCode != 1) {
            NSLog(@"Failed to write PKCS12 file, function i2d_PKCS12_fp returned with %d", returnCode);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToWritePKCS12];
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

-(MscCertificate*)getCertificateWithPassword:(NSString*)password error:(MscX509CommonError**)error {
    
    X509* certificate = NULL;
    EVP_PKEY* key = NULL;
    
    @try {
        
        int returnCode;
        returnCode = PKCS12_parse(_pkcs12, [password UTF8String], &key, &certificate, NULL);
        if (returnCode != 1) {
            NSLog(@"Failed to parse PKCS12 file, function PKCS12_parse returned with %d", returnCode);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToParsePKCS12];
        }
        return [[MscCertificate alloc] initWithX509:certificate];
    }
    @catch (MscX509CommonLocalException *e) {
        
        if (error) {
            *error = [MscX509CommonError errorWithCode:e.errorCode];
        }
        X509_free(certificate);
        return nil;
    }
    @finally {
        
        EVP_PKEY_free(key);
    }
}

-(MscRSAKey*)getRSAKeyWithPassword:(NSString*)password error:(MscX509CommonError**)error {
    
    X509* certificate = NULL;
    EVP_PKEY* key = NULL;
    
    @try {
        
        int returnCode;
        returnCode = PKCS12_parse(_pkcs12, [password UTF8String], &key, &certificate, NULL);
        if (returnCode != 1) {
            NSLog(@"Failed to parse PKCS12 file, function PKCS12_parse returned with %d", returnCode);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToParsePKCS12];
        }
        return [[MscRSAKey alloc] initWithEVP_PKEY:key];
    }
    @catch (MscX509CommonLocalException *e) {
        
        if (error) {
            *error = [MscX509CommonError errorWithCode:e.errorCode];
        }
        
        EVP_PKEY_free(key);
        return nil;
    }
    @finally {
        
        X509_free(certificate);
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    unsigned char *pkcs12Data = NULL;
    
    @try {
        
        int pkcs12DataLength = i2d_PKCS12(_pkcs12, &pkcs12Data);
        
        if (pkcs12DataLength < 1) {
            NSLog(@"Failed to encode PKCS12, function i2d_PKCS12 returned with %d", pkcs12DataLength);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToEncodePKCS12];
        }
        
        [aCoder encodeBytes:pkcs12Data length:pkcs12DataLength forKey:@"pkcs12Data"];
    }
    @finally {
        
        OPENSSL_free(pkcs12Data);
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super init]) {
        
        PKCS12 *pkcs12 = NULL;
        const unsigned char *pkcs12Data = NULL;
        
        @try {
            
            NSUInteger pkcs12DataLength;
            
            pkcs12Data = [aDecoder decodeBytesForKey:@"pkcs12Data" returnedLength:&pkcs12DataLength];
            if (pkcs12DataLength < 1) {
                NSLog(@"Failed to decode PKCS12, function decodeBytesForKey returned with %lu", (unsigned long)pkcs12DataLength);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToDecodePKCS12];
            }
            
            pkcs12 = d2i_PKCS12(NULL, &pkcs12Data, (unsigned long)pkcs12DataLength);
            if (pkcs12 == NULL) {
                NSLog(@"Failed to decode PKCS12, function: d2i_PKCS12");
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToDecodePKCS12];
            }
            _pkcs12 = pkcs12;
            return self;
            
        }
        @catch (MscX509CommonLocalException *e) {
            
            PKCS12_free(pkcs12);
            return nil;
        }
    }
    return nil;
}

-(BOOL)isEqualToMscPKCS12:(MscPKCS12*)otherMscPKCS12 {
    
    
    unsigned char *myPkcs12 = NULL;
    unsigned char *otherPkcs12 = NULL;
    
    @try {
        
        int myPkcs12Length = i2d_PKCS12(_pkcs12, &myPkcs12);
        int otherPkcs12Length = i2d_PKCS12(otherMscPKCS12._pkcs12, &otherPkcs12);
        
        if (myPkcs12Length < 1) {
            NSLog(@"Failed to read PKCS12, function i2d_PKCS12 returned with %d", myPkcs12Length);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadPKCS12];
        }
        
        if (otherPkcs12Length < 1) {
            NSLog(@"Failed to read PKCS12, function i2d_PKCS12 returned with %d", otherPkcs12Length);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadPKCS12];
        }
        
        if (myPkcs12Length != otherPkcs12Length) {
            return NO;
        }
        
        return memcmp(myPkcs12, otherPkcs12, otherPkcs12Length) == 0;
    }
    @finally {
        
        OPENSSL_free(myPkcs12);
        OPENSSL_free(otherPkcs12);
        
    }
}

-(BOOL)openWithPassword:(NSString*)password {
    
    EVP_PKEY* key = NULL;
    
    @try {
        
        int returnCode;
        returnCode = PKCS12_parse(_pkcs12, [password UTF8String], &key, NULL, NULL);
        if (returnCode != 1) {
            NSLog(@"Failed to open PKCS12 file, function PKCS12_parse returned with %d", returnCode);
            return NO;
        }
        return YES;
    }
    @finally {
        
        EVP_PKEY_free(key);
    }
}

-(NSData*)data {
    
    unsigned char *pkcs12 = NULL;
    
    @try {
        
        int pkcs12Length = i2d_PKCS12(_pkcs12, &pkcs12);
        if (pkcs12Length < 1) {
            NSLog(@"Failed to read PKCS12, function i2d_PKCS12 returned with %d", pkcs12Length);
            return nil;
        }
        return [[NSData alloc] initWithBytes:pkcs12 length:pkcs12Length];
    }
    @finally {
        
        OPENSSL_free(pkcs12);
    }
}

-(NSData*)signHash:(NSData*)hash password:(NSString*)password error:(MscX509CommonError**)error {
    
    EVP_PKEY* pKey = NULL;
    
    @try {
        
        int returnCode;
        returnCode = PKCS12_parse(_pkcs12, [password UTF8String], &pKey, NULL, NULL);
        if (returnCode != 1) {
            NSLog(@"Failed to open PKCS12 file, function PKCS12_parse returned with %d", returnCode);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToParsePKCS12];
        }
        
        RSA* rsa = EVP_PKEY_get1_RSA(pKey);
        if (!rsa) {
            NSLog(@"Failed to read private key, function: EVP_PKEY_get1_RSA");
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadKey];
        }
        
        MscRSAKey* rsaKey = [[MscRSAKey alloc] initWithRSA:rsa];
        return [rsaKey signHash:hash error:error];
    }
    @catch(MscX509CommonLocalException* e) {
        
        if (error) {
            *error = [MscX509CommonError errorWithCode:e.errorCode];
        }
        return nil;
    }
    @finally {
        
        if (pKey) EVP_PKEY_free(pKey);
    }
}

-(void)dealloc {
    PKCS12_free(_pkcs12);
}

@end
