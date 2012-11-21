//
//  SEBKeychainManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07.11.12.
//
//

#import "SEBKeychainManager.h"

@implementation SEBKeychainManager

- (NSArray*)getCertificates {
    SecKeychainRef keychain;
    OSStatus error;
    error = SecKeychainCopyDefault(&keychain);
    if (error) {
        //certReqDbg("GetResult: SecKeychainCopyDefault failure");
        /* oh well, there's nothing we can do about this */
    }

    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           kSecClassCertificate, kSecClass,
                           [NSArray arrayWithObject:(__bridge id)keychain], kSecMatchSearchList,
                           kCFBooleanTrue, kSecReturnRef,
                           kSecMatchLimitAll, kSecMatchLimit,
                           nil];
    //NSArray *items = nil;
    CFTypeRef items = NULL;
    OSStatus status = SecItemCopyMatching((__bridge_retained CFDictionaryRef)query, (CFTypeRef *)&items);
    if (status) {
        if (status != errSecItemNotFound)
            //LKKCReportError(status, @"Can't search keychain");
        return nil;
    }
    return (__bridge  NSArray*)(items); // items contains all SecCertificateRefs in keychain

}

- (SecKeyRef*)copyPublicKeyFromCertificate:(SecCertificateRef)certificate {
    SecKeyRef key = NULL;
    OSStatus status = SecCertificateCopyPublicKey(certificate, &key);
    if (status) {
        if (status == errSecItemNotFound) {
            NSLog(@"No public key found in certificate.");
            if (key) CFRelease(key);
            return nil;
        }
    }
    return (SecKeyRef*)key; // public key contained in certificate
}

- (SecIdentityRef*)createIdentityWithCertificate:(SecCertificateRef)certificate {
    SecIdentityRef *identityRef;
    OSStatus status = SecIdentityCreateWithCertificate(NULL, certificate, identityRef);
    if (status) {
        if (status == errSecItemNotFound) {
            NSLog(@"No associated private key found for certificate.");
            return nil;
        }
    }
    return identityRef; // public key contained in certificate
}


- (NSData*)encryptData:(NSData*)inputData withPublicKey:(SecKeyRef*)publicKey {

    OSStatus status = noErr;
    
    // Convert input data into a buffer
    const void *bytes = [inputData bytes];
    int length = [inputData length];
    uint8_t *plainText = malloc(length);
    memcpy(plainText, bytes, length);

    // Allocate a buffer to hold the cipher text
    size_t cipherBufferSize;
    uint8_t *cipherBuffer;
    cipherBufferSize = SecKeyGetBlockSize(*publicKey);
    cipherBuffer = malloc(cipherBufferSize);

    // Encrypt using the public key
    status = SecKeyEncrypt(publicKey,
                           kSecPaddingPKCS1,
                           plainText,
                           length,
                           cipherBuffer,
                           &cipherBufferSize
                           );
    
    NSData *cipherData = [NSData dataWithBytes:cipherBuffer length:cipherBufferSize];
    
    /* Free the Security Framework Five! */
    CFRelease(publicKey);
    free(cipherBuffer);
    return cipherData;
    //[cipherData encodeBase64ForData];
}


@end