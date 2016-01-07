//
//  SEBKeychainManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07.11.12.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, 
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre, 
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "SEBKeychainManager.h"
#import "RNCryptor.h"

#if TARGET_OS_IPHONE
#import "SEBiOSKeychainManager.h"
#else
#import "SEBOSXKeychainManager.h"
#endif

@implementation SEBKeychainManager


-(id) init
{
    self = [super init];
    if (self) {
#if TARGET_OS_IPHONE
        self.delegate = [[SEBiOSKeychainManager alloc] init];

#else
        self.delegate = [[SEBOSXKeychainManager alloc] init];
        
#endif
    }
    return self;
}




// We ignore "deprecated" warnings for CSSM methods, since Apple doesn't provide any replacement
// for asymetric public key cryptography as for OS X 10.10
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (NSArray*)getIdentitiesAndNames:(NSArray **)names
{
    return [self.delegate getIdentitiesAndNames:names];
}


- (NSArray*)getCertificatesAndNames:(NSArray **)names
{
    return [self.delegate getCertificatesAndNames:names];
}


- (NSData*)getPublicKeyHashFromCertificate:(SecCertificateRef)certificate
{
    return [self.delegate getPublicKeyHashFromCertificate:certificate];
}


- (SecKeyRef)getPrivateKeyFromPublicKeyHash:(NSData*)publicKeyHash
{
    return [self.delegate getPrivateKeyFromPublicKeyHash:publicKeyHash];
}


- (SecIdentityRef)getIdentityRefFromPublicKeyHash:(NSData*)publicKeyHash
{
    return [self.delegate getIdentityRefFromPublicKeyHash:publicKeyHash];
}


- (SecKeyRef)copyPrivateKeyRefFromIdentityRef:(SecIdentityRef)identityRef
{
    return [self.delegate copyPrivateKeyRefFromIdentityRef:identityRef];
}


- (SecKeyRef*)copyPublicKeyFromCertificate:(SecCertificateRef)certificate
{
    return [self.delegate copyPublicKeyFromCertificate:certificate];
}


- (SecIdentityRef)createIdentityWithCertificate:(SecCertificateRef)certificate
{
    return [self.delegate createIdentityWithCertificate:certificate];
}


- (SecCertificateRef)copyCertificateFromIdentity:(SecIdentityRef)identityRef
{
    return [self.delegate copyCertificateFromIdentity:identityRef];
}


- (NSData*)getDataForCertificate:(SecCertificateRef)certificate
{
    return [self.delegate getDataForCertificate:certificate];
}


- (BOOL)importCertificateFromData:(NSData*)certificateData
{
    return [self.delegate importCertificateFromData:certificateData];
}


- (NSData*)getDataForIdentity:(SecIdentityRef)identity
{
    return [self.delegate getDataForIdentity:identity];
}


- (BOOL) importIdentityFromData:(NSData*)identityData {
    return [self.delegate importIdentityFromData:identityData];
}


- (NSData*)encryptData:(NSData*)plainData withPublicKeyFromCertificate:(SecCertificateRef)certificate
{
    return [self.delegate encryptData:plainData withPublicKeyFromCertificate:certificate];
}


- (NSData*)decryptData:(NSData*)cipherData withPrivateKey:(SecKeyRef)privateKeyRef
{
    return [self.delegate decryptData:cipherData withPrivateKey:privateKeyRef];
}


// Switch diagnostics for "deprecated" on again
#pragma clang diagnostic pop

- (NSString *) generateSHAHashString:(NSString*)inputString {
    unsigned char hashedChars[32];
    CC_SHA256([inputString UTF8String],
              (CC_LONG)[inputString lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
              hashedChars);
    NSMutableString* hashedString = [[NSMutableString alloc] init];
    for (int i = 0 ; i < 32 ; ++i) {
        [hashedString appendFormat: @"%02x", hashedChars[i]];
    }
    return hashedString;
}


// Add a generic key to the keychain
- (BOOL) storeKey:(NSData *)keyData
{
    NSString *keyID = @"4815162342";
    return [self storeKeyWithID:keyID keyData:keyData];
}

// Add key with ID to the keychain
- (BOOL) storeKeyWithID:(NSString *)keyID keyData:(NSData *)keyData
{
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
                           service, (__bridge id)kSecAttrService,
                           keyID, (__bridge id)kSecAttrGeneric,
                           keyID, (__bridge id)kSecAttrAccount,
                           //(__bridge id)kSecAttrAccessibleAfterFirstUnlock, (__bridge id)kSecAttrAccessible,
                           (__bridge id)kCFBooleanTrue, (__bridge id)kSecAttrIsInvisible,
                           keyData, (__bridge id)kSecValueData,
                           nil];
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    if (status != errSecSuccess) {
        NSError *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        DDLogError(@"SecItemAdd failed with error: %@. Will now try SecItemUpdate.", outError);
//        [NSApp presentError:outError];
        return [self updateKeyWithID:keyID keyData:keyData];
    }
	return (status == errSecSuccess);
}


// Update a generic key in the keychain
- (BOOL) updateKey:(NSData *)keyData
{
    NSString *keyID = @"4815162342";
    return [self updateKeyWithID:keyID keyData:keyData];
}

// Update a key with ID in the keychain
- (BOOL) updateKeyWithID:(NSString *)keyID keyData:(NSData *)keyData
{
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
                           service, (__bridge id)kSecAttrService,
                           keyID, (__bridge id)kSecAttrGeneric,
                           keyID, (__bridge id)kSecAttrAccount,
                           (__bridge id)kCFBooleanTrue, (__bridge id)kSecAttrIsInvisible,
//                           (__bridge id)kSecMatchLimitOne, (__bridge id)kSecMatchLimit,
                           nil];
    NSDictionary *attributesToUpdate = [NSDictionary dictionaryWithObjectsAndKeys:
                                        keyData, (__bridge id)kSecValueData,
                                        nil];
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
    if (status != errSecSuccess) {
        NSError *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL];
        DDLogError(@"SecItemUpdate failed with error: %@", outError);
    }
	return (status == errSecSuccess);
//    return true;
}


// Get a generic key from the keychain
- (NSData *) retrieveKey
{
    NSString *keyID = @"4815162342";
    return [self retrieveKeyWithID:keyID];
}

// Get a key with ID from the keychain
- (NSData *) retrieveKeyWithID:(NSString *)keyID
{
    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
                           service, (__bridge id)kSecAttrService,
                           keyID, (__bridge id)kSecAttrGeneric,
                           keyID, (__bridge id)kSecAttrAccount,
                           (__bridge id)kCFBooleanTrue, (__bridge id)kSecAttrIsInvisible,
                           (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnData,
                           (__bridge id)kSecMatchLimitOne, (__bridge id)kSecMatchLimit,
                           nil];
    CFTypeRef keyData = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &keyData);
    if (status != errSecSuccess) {
        NSError *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL];
        DDLogError(@"SecItemCopyMatching failed with error: %@", outError);
        return nil;
    }
    return (__bridge_transfer NSData *)keyData;
}

@end