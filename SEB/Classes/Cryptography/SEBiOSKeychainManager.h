//
//  SEBiOSKeychainManager.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15/12/15.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
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
