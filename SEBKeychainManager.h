//
//  SEBKeychainManager.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07.11.12.
//
//

#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <CoreServices/CoreServices.h>
#import <SSCrypto/SSCrypto.h>

@interface SEBKeychainManager : NSObject

- (NSArray*) getCertificates;
- (SecKeyRef*)copyPublicKeyFromCertificate:(SecCertificateRef)certificate;
- (SecIdentityRef*)createIdentityWithCertificate:(SecCertificateRef)certificate;
- (SecKeyRef)privateKeyFromIdentity:(SecIdentityRef*)identityRef;

//- (NSData*)encryptData:(NSData*)inputData withPublicKey:(SecKeyRef*)publicKey;
- (NSData*)encryptData:(NSData*)inputData withPublicKeyFromCertificate:(SecCertificateRef)certificate;
- (NSData*)decryptData:(NSData*)cipherData withPrivateKey:(SecKeyRef)privateKey;

@end
