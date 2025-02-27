//
//  SEBKeychainManager.h
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


#include <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

@class SEBKeychainManager;

/**
 * @protocol    SEBKeychainManagerDelegate
 *
 * @brief       OS-specific SEBKeychainManager delegates confirming to the SEBKeychainManagerDelegate
 *              protocol are connecting SEBKeychainManager to the keychain.
 */
@protocol SEBKeychainManagerDelegate <NSObject>
/**
 * @name		Item Attributes
 */
@required
- (NSArray*)getIdentitiesAndNames:(NSArray **)names;
- (NSArray*)getCertificatesAndNames:(NSArray **)names;
- (NSData*)getPublicKeyHashFromIdentity:(SecIdentityRef)identityRef;
- (NSData*)getPublicKeyHashFromCertificate:(SecCertificateRef)certificate;
- (SecKeyRef)getPrivateKeyFromPublicKeyHash:(NSData*)publicKeyHash;
- (SecIdentityRef)getIdentityRefFromPublicKeyHash:(NSData*)publicKeyHash;
- (SecKeyRef)copyPrivateKeyRefFromIdentityRef:(SecIdentityRef)identityRef;
- (SecKeyRef*)copyPublicKeyFromCertificate:(SecCertificateRef)certificate;

- (SecCertificateRef)copyCertificateFromIdentity:(SecIdentityRef)identityRef;
- (NSData*)getDataForCertificate:(SecCertificateRef)certificate;
- (BOOL)importCertificateFromData:(NSData*)certificateData;
- (NSData*)getDataForIdentity:(SecIdentityRef)identity;
- (BOOL)importIdentityFromData:(NSData*)identityData;

- (NSData*)encryptData:(NSData*)plainData withPublicKeyFromCertificate:(SecCertificateRef)certificate;
- (NSData*)decryptData:(NSData*)cipherData withPrivateKey:(SecKeyRef)privateKey;

@optional
- (NSArray*)getCertificatesOfType:(certificateTypes)certificateType;
- (NSData*)generatePKCS12IdentityWithName:(NSString *)commonName;

@property (nonatomic, retain) SEBKeychainManager *keychainManager;

@end


@interface SEBKeychainManager : NSObject

@property (strong) id<SEBKeychainManagerDelegate> delegate;

- (NSArray*)getIdentitiesAndNames:(NSArray **)names;
- (NSArray*)getCertificatesAndNames:(NSArray **)names;
- (NSArray*)getCertificatesOfType:(certificateTypes)certificateType;
- (NSData*)getPublicKeyHashFromIdentity:(SecIdentityRef)identityRef;
- (NSData*)getPublicKeyHashFromCertificate:(SecCertificateRef)certificate;
- (SecKeyRef)getPrivateKeyFromPublicKeyHash:(NSData*)publicKeyHash;
- (SecIdentityRef)getIdentityRefFromPublicKeyHash:(NSData*)publicKeyHash;
- (SecKeyRef)copyPrivateKeyRefFromIdentityRef:(SecIdentityRef)identityRef;
- (SecKeyRef*)copyPublicKeyFromCertificate:(SecCertificateRef)certificate;

- (SecCertificateRef)copyCertificateFromIdentity:(SecIdentityRef)identityRef;
- (NSData*)getDataForCertificate:(SecCertificateRef)certificate;
- (BOOL)importCertificateFromData:(NSData*)certificateData;
- (NSData*)getDataForIdentity:(SecIdentityRef)identity;
- (BOOL)importIdentityFromData:(NSData*)identityData;
- (NSData*)generatePKCS12IdentityWithName:(NSString *)commonName;
- (BOOL)generateIdentityWithName:(NSString *)commonName;
- (BOOL)removeIdentityFromKeychain:(SecIdentityRef)identityRef;
- (NSData *)retrieveKeyForIdentity:(SecIdentityRef)identityRef;

- (NSData*)encryptData:(NSData*)plainData withPublicKeyFromCertificate:(SecCertificateRef)certificate;
- (NSData*)decryptData:(NSData*)cipherData withPrivateKey:(SecKeyRef)privateKey;
- (NSString*)generateSHAHashString:(NSString*)inputString;

- (BOOL) storeKey:(NSData *)keyData;
- (BOOL) storeKeyWithID:(NSString *)keyID keyData:(NSData *)keyData;
- (BOOL) storeInternetPassword:(NSString *)password
                       account:(NSString *)account
                        server:(NSString *)server
                synchronizable:(BOOL)synchronizable;
- (BOOL) updateKey:(NSData *)keyData;
- (BOOL) updateKeyWithID:(NSString *)keyID keyData:(NSData *)keyData;
- (BOOL) updateInternetPassword:(NSString *)password
                        account:(NSString *)account
                         server:(NSString *)server
                 synchronizable:(BOOL)synchronizable;
- (NSData *) retrieveKey;
- (NSData *) retrieveKeyWithID:(NSString *)keyID;
- (NSArray *) retrieveInternetPasswordsForServer:(NSString *)server;
- (NSString *) retrieveInternetPasswordForAccount:(NSString *)account
                                           server:(NSString *)server
                                   synchronizable:(BOOL)synchronizable;
- (BOOL) removeKeyWithID:(NSString *)keyID;

@end
