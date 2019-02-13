//
//  SEBiOSKeychainManager.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15/12/15.
//
//

#import <Foundation/Foundation.h>

#import "SEBKeychainManager.h"
#include <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

@interface SEBiOSKeychainManager : NSObject <SEBKeychainManagerDelegate>

@property (nonatomic, retain) SEBKeychainManager *keychainManager;

- (NSArray*)getIdentitiesAndNames:(NSArray **)names;
- (NSArray*)getCertificatesAndNames:(NSArray **)names;
- (NSData*)getPublicKeyHashFromIdentity:(SecIdentityRef)identityRef;
- (NSData*)getPublicKeyHashFromCertificate:(SecCertificateRef)certificate;
- (SecKeyRef)getPrivateKeyFromPublicKeyHash:(NSData*)publicKeyHash;
- (SecIdentityRef)getIdentityRefFromPublicKeyHash:(NSData*)publicKeyHash;
- (SecKeyRef)copyPrivateKeyRefFromIdentityRef:(SecIdentityRef)identityRef;
- (SecKeyRef)copyPublicKeyFromCertificate:(SecCertificateRef)certificate;
- (SecIdentityRef)createIdentityWithCertificate:(SecCertificateRef)certificate;

- (SecCertificateRef)copyCertificateFromIdentity:(SecIdentityRef)identityRef;
- (NSData*)getDataForCertificate:(SecCertificateRef)certificate;
- (BOOL)importCertificateFromData:(NSData*)certificateData;
- (NSData*)getDataForIdentity:(SecIdentityRef)identity;
- (BOOL)importIdentityFromData:(NSData*)identityData;

- (NSData*)encryptData:(NSData*)plainData withPublicKeyFromCertificate:(SecCertificateRef)certificate;
- (NSData*)decryptData:(NSData*)cipherData withPrivateKey:(SecKeyRef)privateKey;

@end
