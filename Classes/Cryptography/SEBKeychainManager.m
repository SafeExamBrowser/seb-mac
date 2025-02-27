//
//  SEBKeychainManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07.11.12.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel, 
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
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
        self.delegate.keychainManager = self;

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


- (NSArray*)getCertificatesOfType:(certificateTypes)certificateType
{
    return [self.delegate getCertificatesOfType:certificateType];
}


- (NSData*)getPublicKeyHashFromIdentity:(SecIdentityRef)identityRef
{
    return [self.delegate getPublicKeyHashFromIdentity:identityRef];
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


- (BOOL)importIdentityFromData:(NSData*)identityData {
    return [self.delegate importIdentityFromData:identityData];
}


// Generate PKCS12 identity data
- (NSData *)generatePKCS12IdentityWithName:(NSString *)commonName
{
    return [self.delegate generatePKCS12IdentityWithName:commonName];
}


// Generate identity and store in Keychain
- (BOOL)generateIdentityWithName:(NSString *)commonName
{
    return [self importIdentityFromData:[self generatePKCS12IdentityWithName:commonName]];
}


- (BOOL)removeIdentityFromKeychain:(SecIdentityRef)identityRef
{
    NSData *publicKeyHash = [self getPublicKeyHashFromIdentity:identityRef];
    NSString *publicKeyHashBase64 = [publicKeyHash base64EncodedStringWithOptions:(0)];

    NSDictionary *query = @{
                            (id)kSecValueRef: (__bridge id)identityRef
                            };
    OSStatus status = SecItemDelete((CFDictionaryRef)query);
    if (status == errSecSuccess) {
        DDLogInfo(@"%s: Removing identity from Keychain succeeded.", __FUNCTION__);
        [self removeKeyWithID:publicKeyHashBase64];
        return YES;
    } else {
        DDLogError(@"%s: Removing identity from Keychain failed with OSStatus error code %d!", __FUNCTION__, (int)status);
        return NO;
    }
}


- (NSData *)retrieveKeyForIdentity:(SecIdentityRef)identityRef
{
    NSData *publicKeyHash = [self getPublicKeyHashFromIdentity:identityRef];
    NSString *publicKeyHashBase64 = [publicKeyHash base64EncodedStringWithOptions:(0)];
    return [self retrieveKeyWithID:publicKeyHashBase64];
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


- (NSString *) generateChallenge
{
    int randomNumber = arc4random_uniform(999999);
    return [NSString stringWithFormat:@"%d", randomNumber];
}


- (NSString *) generateResponseForChallenge:(NSString *)challenge secret:(NSString *)secret
{
    unsigned char hashedChars[32];
    NSString *inputString = [challenge stringByAppendingString:secret];
    const char *inputStringChars = [inputString UTF8String];
    CC_SHA256(inputStringChars,
              (uint)strlen(inputStringChars),
              hashedChars);
    
    NSMutableString* hashedString = [[NSMutableString alloc] initWithCapacity:32];
    for (NSUInteger i = 0 ; i < 32 ; ++i) {
        [hashedString appendFormat: @"%02x", hashedChars[i]];
    }
    return hashedString.copy;
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
        DDLogError(@"%s: SecItemAdd failed with error: %@. Will now try SecItemUpdate.", __FUNCTION__, outError);
        return [self updateKeyWithID:keyID keyData:keyData];
    }
    return (status == errSecSuccess);
}


- (BOOL) storeInternetPassword:(NSString *)password
                       account:(NSString *)account
                        server:(NSString *)server
                synchronizable:(BOOL)synchronizable
{
    NSData *passwordData = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)kSecClassInternetPassword, (__bridge id)kSecClass,
                           server, (__bridge id)kSecAttrServer,
                           account, (__bridge id)kSecAttrAccount,
                           (synchronizable ? kCFBooleanTrue : kCFBooleanFalse), (__bridge id)kSecAttrSynchronizable,
                           //(__bridge id)kSecAttrAccessibleAfterFirstUnlock, (__bridge id)kSecAttrAccessible,
                           passwordData, (__bridge id)kSecValueData,
                           nil];
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    if (status != errSecSuccess) {
        NSError *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        DDLogError(@"%s: SecItemAdd failed with error: %@. Will now try SecItemUpdate.", __FUNCTION__, outError);
        return [self updateInternetPassword:password account:account server:server synchronizable:synchronizable];
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
        DDLogError(@"%s: SecItemUpdate failed with error: %@", __FUNCTION__, outError);
    }
    return (status == errSecSuccess);
}


- (BOOL) updateInternetPassword:(NSString *)password
                        account:(NSString *)account
                         server:(NSString *)server
                 synchronizable:(BOOL)synchronizable
{
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)kSecClassInternetPassword, (__bridge id)kSecClass,
                           server, (__bridge id)kSecAttrServer,
                           account, (__bridge id)kSecAttrAccount,
                           (synchronizable ? kCFBooleanTrue : kCFBooleanFalse), (__bridge id)kSecAttrSynchronizable,
                           nil];
    NSDictionary *attributesToUpdate = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [password dataUsingEncoding:NSUTF8StringEncoding], (__bridge id)kSecValueData,
                                        nil];
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributesToUpdate);
    if (status != errSecSuccess) {
        NSError *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL];
        DDLogError(@"%s: SecItemUpdate failed with error: %@", __FUNCTION__, outError);
    }
    return (status == errSecSuccess);
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
        DDLogError(@"%s: SecItemCopyMatching failed with error: %@", __FUNCTION__, outError);
        return nil;
    }
    return (__bridge_transfer NSData *)keyData;
}


- (NSArray *) retrieveInternetPasswordsForServer:(NSString *)server
{
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)kSecClassInternetPassword, (__bridge id)kSecClass,
                           server, (__bridge id)kSecAttrServer,
                           @YES, (__bridge id)kSecReturnAttributes,
                           (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnData,
                           (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                           nil];
    CFTypeRef resultsArray = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &resultsArray);
    if (status != errSecSuccess) {
        NSError *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL];
        DDLogError(@"%s: SecItemCopyMatching failed with error: %@", __FUNCTION__, outError);
        return nil;
    }
    return (__bridge_transfer NSArray *)resultsArray;
}


- (NSString *) retrieveInternetPasswordForAccount:(NSString *)account
                                           server:(NSString *)server
                                   synchronizable:(BOOL)synchronizable
{
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)kSecClassInternetPassword, (__bridge id)kSecClass,
                           server, (__bridge id)kSecAttrServer,
                           account, (__bridge id)kSecAttrAccount,
                           (synchronizable ? kCFBooleanTrue : kCFBooleanFalse), (__bridge id)kSecAttrSynchronizable,
                           (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnData,
                           nil];
    CFTypeRef keyData = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &keyData);
    if (status != errSecSuccess) {
        NSError *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL];
        DDLogError(@"%s: SecItemCopyMatching failed with error: %@", __FUNCTION__, outError);
        return nil;
    }
    return [[NSString alloc] initWithData:(__bridge_transfer NSData *)keyData encoding:NSUTF8StringEncoding];
}


// Remove the key with the passed ID from the keychain
- (BOOL) removeKeyWithID:(NSString *)keyID
{
//    NSString *service = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
                           keyID, (__bridge id)kSecAttrGeneric,
                           nil];
    OSStatus status = SecItemDelete((CFDictionaryRef)query);
    if (status != errSecSuccess) {
        NSError *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL];
        DDLogError(@"%s: SecItemCopyDelete failed with error: %@", __FUNCTION__, outError);
        return NO;
    }
    return YES;
}

@end
