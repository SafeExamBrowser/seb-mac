//
//  SEBiOSKeychainManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15/12/15.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBiOSKeychainManager.h"
#import "SEBCryptor.h"
#import "RNCryptor.h"
#import "MscCertificateSigningRequest.h"
#import "MscCertificate.h"
#import "MscCertificate_OpenSSL_X509.h"
#import "MscPKCS12.h"
#import "MscPKCS7.h"
#import "MscRSAKey.h"
#import "MscRSAKey_OpenSSL_RSA.h"
#import <openssl/rsa.h>
#import <openssl/pem.h>
#import <openssl/rsa.h>
#import <openssl/pem.h>

@implementation SEBiOSKeychainManager

- (NSArray*)getIdentitiesAndNames:(NSArray **)names
{
    OSStatus status;
    
    NSDictionary *query = @{
                            (id)kSecClass: (id)kSecClassIdentity,
                            (id)kSecMatchLimit: (id)kSecMatchLimitAll,
                            (id)kSecReturnRef: @YES,
                           };
    CFArrayRef items = NULL;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&items);
    if (status != errSecSuccess) {
        DDLogError(@"Error in %s: SecItemCopyMatching(kSecClassIdentity) returned %@. Can't search keychain, no identities can be read.", __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
        if (items) CFRelease(items);
        return nil;
    }
    NSMutableArray *identities = [NSMutableArray arrayWithArray:(__bridge  NSArray*)(items)];
    if (items) CFRelease(items);
    NSMutableArray *identitiesNames = [NSMutableArray arrayWithCapacity:[identities count]];
    
    SecCertificateRef certificateRef;
    SecKeyRef publicKeyRef;
    SecKeyRef privateKeyRef;
    NSString *identityName;
    NSUInteger count = [identities count];
    for (NSUInteger i=0; i<count; i++) {
        SecIdentityRef identityRef = (__bridge SecIdentityRef)[identities objectAtIndex:i];
        if (SecIdentityCopyCertificate(identityRef, &certificateRef) == noErr) {
            if (SecIdentityCopyPrivateKey(identityRef, &privateKeyRef) == noErr) {
                if ((publicKeyRef = [self copyPublicKeyFromCertificate:certificateRef])) {
                    NSString *commonNameString = [self getCommonNameForCertificate:certificateRef];
                    if (commonNameString) {
                        NSString *emailAdress = [self getEmailForCertificate:certificateRef];
                        commonNameString = [commonNameString  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        emailAdress = [emailAdress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        identityName = [NSString stringWithFormat:@"%@",
                                        commonNameString ?
                                        //There is a commonName: just take that as a name
                                        [NSString stringWithFormat:@"%@", commonNameString] :
                                        //there is no common name: take the e-mail address (if it exists)
                                        emailAdress ? [NSString stringWithFormat:@"%@", emailAdress] : @""];
                        // Check if there is already an identitiy with the identical name (can happen)
                        if (identityName.length == 0 || [identitiesNames containsObject:identityName]) {
                            // If yes, we need to make the name unique; we add the public key hash
                            // Get public key hash from selected identity's certificate
                            NSData* publicKeyHash = [self getPublicKeyHashFromCertificate:certificateRef];
                            if (!publicKeyHash) {
                                DDLogError(@"Error in %s: Could not get public key hash form certificate. Generated a random hash.", __FUNCTION__);
                                // If the hash couldn't be determinded (what actually shouldn't happen): Create random data instead
                                publicKeyHash = [RNCryptor randomDataOfLength:20];
                            }
                            unsigned char hashedChars[20];
                            [publicKeyHash getBytes:hashedChars length:20];
                            NSMutableString* hashedString = [NSMutableString new];
                            for (int i = 0 ; i < 20 ; ++i) {
                                [hashedString appendFormat: @"%02x", hashedChars[i]];
                            }
                            identityName.length == 0 ? identityName = hashedString : [NSString stringWithFormat:@"%@ %@", identityName, hashedString];
                        }
                        [identitiesNames addObject:identityName];
                        DDLogDebug(@"Identity name: %@", identityName);
                        DDLogDebug(@"Public key can be used for encryption, private key can be used for decryption");
                        if (publicKeyRef) CFRelease(publicKeyRef);
                        if (privateKeyRef) CFRelease(privateKeyRef);
                        if (certificateRef) CFRelease(certificateRef);
                        // Continue with next element
                        continue;
                    } else {
                        DDLogError(@"Error in %s: SecCertificateCopyCommonName returned %@. This identity will be skipped.", __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
                    }
                    if (publicKeyRef) {
                        CFRelease(publicKeyRef);
                    }
                } else {
                    DDLogError(@"Error in %s: SecCertificateCopyPublicKey returned %@. This identity will be skipped.", __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
                }
                if (privateKeyRef) {
                    CFRelease(privateKeyRef);
                }
            } else {
                DDLogError(@"Error in %s: SecIdentityCopyPrivateKey returned %@. This identity will be skipped.", __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
            }
            if (certificateRef) {
                CFRelease(certificateRef);
            }
        } else {
            DDLogError(@"Error in %s: SecIdentityCopyCertificate returned %@. This identity will be skipped.", __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
        }
        
        // Currently iterated identity cannot be used: remove it from the list
        [identities removeObjectAtIndex:i];
        i--;
        count--;
    }
    NSArray *foundIdentities;
    foundIdentities = [NSArray arrayWithArray:identities];
    // return array of identity names
    if (names) {
        *names = [NSArray arrayWithArray:identitiesNames];
    }
    return foundIdentities; // items contains all SecIdentityRefs in keychain
}


- (NSArray*)getCertificatesAndNames:(NSArray **)names
{
    OSStatus status;
    
    NSDictionary *query = @{
                            (id)kSecClass: (id)kSecClassCertificate,
                            (id)kSecMatchLimit: (id)kSecMatchLimitAll,
                            (id)kSecReturnRef: @YES,
                            };
    CFTypeRef items = NULL;
    
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&items);
    if (status != errSecSuccess) {
        DDLogError(@"Error in %s: SecItemCopyMatching(kSecClassIdentity) returned %@. Can't search keychain, no identities can be read.", __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
        if (items) CFRelease(items);
        return nil;
    }
    
    NSMutableArray *certificates = [NSMutableArray arrayWithArray:(__bridge_transfer NSArray*)(items)];
    NSMutableArray *certificatesNames = [NSMutableArray arrayWithCapacity:[certificates count]];
    
    NSString *certificateName;
    NSUInteger i, count = [certificates count];
    for (i=0; i<count; i++) {
        SecCertificateRef certificateRef = (__bridge SecCertificateRef)[certificates objectAtIndex:i];
        NSString *commonNameString = [self getCommonNameForCertificate:certificateRef];
        if (commonNameString) {
            NSString *emailAdress = [self getEmailForCertificate:certificateRef];
            emailAdress = [emailAdress  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            certificateName = [NSString stringWithFormat:@"%@",
                               commonNameString ?
                               //There is a commonName: just take that as a name
                               [NSString stringWithFormat:@"%@", commonNameString] :
                               //there is no common name: take the e-mail address (if it exists)
                               emailAdress ? [NSString stringWithFormat:@"%@", emailAdress] : @""];
            if (certificateName.length == 0 || [certificatesNames containsObject:certificateName]) {
                //get public key hash from selected identity's certificate
                NSData* publicKeyHash = [self getPublicKeyHashFromCertificate:certificateRef];
                if (!publicKeyHash) {
                    DDLogError(@"Error in %s: Could not get public key hash form certificate. Generated a random hash.", __FUNCTION__);
                    // If the hash couldn't be determinded (what actually shouldn't happen): Create random data instead
                    publicKeyHash = [RNCryptor randomDataOfLength:20];
                }
                unsigned char hashedChars[20];
                [publicKeyHash getBytes:hashedChars length:20];
                NSMutableString* hashedString = [NSMutableString new];
                for (int i = 0 ; i < 20 ; ++i) {
                    [hashedString appendFormat: @"%02x", hashedChars[i]];
                }
                certificateName.length == 0 ? certificateName = hashedString : [NSString stringWithFormat:@"%@ %@", certificateName, hashedString];
            }
            [certificatesNames addObject:certificateName];
            DDLogDebug(@"Certificate name: %@", certificateName);
            continue;
        } else {
            DDLogError(@"Error in %s: SecCertificateCopyCommonName returned %@. This identity will be skipped.", __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
        }
        // Currently iterated certificate cannot be used: remove it from the list
        [certificates removeObjectAtIndex:i];
        i--;
        count--;
    }
    NSArray *foundCertificates;
    foundCertificates = [NSArray arrayWithArray:certificates];
    // return array of identity names
    if (names) {
        *names = [NSArray arrayWithArray:certificatesNames];
    }
    return foundCertificates; // items contains all SecIdentityRefs in keychain
}


- (NSData*)getPublicKeyHashFromIdentity:(SecIdentityRef)identityRef
{
    SecCertificateRef certificateRef = [self copyCertificateFromIdentity:identityRef];
    return [self getPublicKeyHashFromCertificate:certificateRef];
}


- (NSData*)getPublicKeyHashFromCertificate:(SecCertificateRef)certificate
{
    SecKeyRef publicKeyRef = [self copyPublicKeyFromCertificate:certificate];
    NSData *publicKeyData;

    if (@available(iOS 10.0, *)) {
        CFErrorRef error = NULL;
        publicKeyData = (NSData*)CFBridgingRelease(SecKeyCopyExternalRepresentation(publicKeyRef, &error));
        if (publicKeyRef) CFRelease(publicKeyRef);
        if (!publicKeyData) {
            DDLogError(@"Could not extract public key data:  %@", error);
            return nil;
        }
    } else {
        // iOS 9 didn't had the API above, ugly workaround to follow:
        NSString *const keychainTag = @"X509_KEY";
        OSStatus putResult, delResult = noErr;
        
        // Params for putting the key first
        NSMutableDictionary *putKeyParams = [NSMutableDictionary new];
        putKeyParams[(__bridge id) kSecClass] = (__bridge id) kSecClassKey;
        putKeyParams[(__bridge id) kSecAttrKeyType] = (__bridge id) kSecAttrKeyTypeRSA;
        putKeyParams[(__bridge id) kSecAttrApplicationTag] = keychainTag;
        putKeyParams[(__bridge id) kSecValueRef] = (__bridge id) (publicKeyRef);
        putKeyParams[(__bridge id) kSecReturnData] = (__bridge id) (kCFBooleanTrue); // Request the key's data to be returned too
        
        // Params for deleting the data
        NSMutableDictionary *delKeyParams = [[NSMutableDictionary alloc] init];
        delKeyParams[(__bridge id) kSecClass] = (__bridge id) kSecClassKey;
        delKeyParams[(__bridge id) kSecAttrApplicationTag] = keychainTag;
        delKeyParams[(__bridge id) kSecReturnData] = (__bridge id) (kCFBooleanTrue);
        
        // Put the key
        putResult = SecItemAdd((__bridge CFDictionaryRef) putKeyParams, (void *)&publicKeyData);
        // Delete the key
        delResult = SecItemDelete((__bridge CFDictionaryRef)(delKeyParams));
        if (publicKeyRef) CFRelease(publicKeyRef);

        if ((putResult != errSecSuccess) || (delResult != errSecSuccess))
        {
            DDLogError(@"Could not extract public key data: %d", (int)putResult);
            return nil;
        }
    }

    NSData *publicKeyHash = [self generateSHA1HashForData:publicKeyData];

    return publicKeyHash;
}


- (NSString *) getCommonNameForCertificate:(SecCertificateRef)certificateRef
{
    NSString *commonNameString = nil;
    
    if (@available(iOS 10.0, *)) {
        CFStringRef commonName = NULL;
        OSStatus status = SecCertificateCopyCommonName(certificateRef, &commonName);
        if (status == noErr) {
            commonNameString = (__bridge NSString *)commonName;
        }
        if (commonName) CFRelease(commonName);
        
    } else {
        NSData *certificateData = [self getDataForCertificate:certificateRef];
        MscX509CommonError *error = nil;
        MscCertificate *certificate = [[MscCertificate alloc] initWithData:certificateData error:&error];
        if (certificate) {
            MscX509Name* subject = certificate.subject;
            commonNameString = subject.commonName;
            if (!commonNameString) {
                commonNameString = @"";
            }
        }
    }
    commonNameString = [commonNameString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return commonNameString;
}


- (NSString *) getEmailForCertificate:(SecCertificateRef)certificateRef
{
    NSString *emailAdress = nil;
    
    if (@available(iOS 10.0, *)) {
        CFArrayRef emailAddressesRef = NULL;
        OSStatus status = SecCertificateCopyEmailAddresses(certificateRef, &emailAddressesRef);
        if (status == noErr) {
            NSArray *emailAdresses = (__bridge NSArray *)(emailAddressesRef);
            emailAdress = emailAdresses.count > 0 ? emailAdresses[0] : nil;
            emailAdress = [emailAdress  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
    } else {
        
    }
    return emailAdress;
}


- (NSData*) generateSHA1HashForData:(NSData *)inputData {
    unsigned char hashedChars[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(inputData.bytes,
              (uint)inputData.length,
              hashedChars);
    NSData *hashedData = [NSData dataWithBytes:hashedChars length:CC_SHA1_DIGEST_LENGTH];
    return hashedData;
}


- (SecKeyRef)getPrivateKeyFromPublicKeyHash:(NSData*)publicKeyHash
{
    SecIdentityRef identityRef = [self getIdentityRefFromPublicKeyHash:publicKeyHash];
    if (!identityRef) {
        return NULL;
    }
    SecKeyRef privateKeyRef = nil;
    OSStatus status = SecIdentityCopyPrivateKey(identityRef, &privateKeyRef);
    if (status != errSecSuccess) {
        DDLogError(@"No associated private key found for public key hash.");
        if (privateKeyRef) CFRelease(privateKeyRef);
        return NULL;
    }
    return privateKeyRef;
}


- (SecIdentityRef)getIdentityRefFromPublicKeyHash:(NSData*)publicKeyHash
{
    OSStatus status;
    NSDictionary *query = @{
                            (id)kSecClass: (id)kSecClassIdentity,
                            (id)kSecMatchLimit: (id)kSecMatchLimitAll,
                            (id)kSecReturnRef: @YES,
                            };
    CFArrayRef items = NULL;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&items);
    if (status != errSecSuccess) {
        DDLogError(@"Error in %s: SecItemCopyMatching(kSecClassIdentity) returned %@. Can't search keychain, no identities can be read.", __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
        if (items) CFRelease(items);
        return NULL;
    }
    NSArray *identities = (__bridge  NSArray*)(items);
    if (items) CFRelease(items);
    
    SecIdentityRef identityRef = NULL;
    SecCertificateRef certificateRef;
    for (id keychainIdentity in identities) {
        status = SecIdentityCopyCertificate((SecIdentityRef)keychainIdentity, &certificateRef);
        if (status == errSecSuccess) {
            NSData *keychainIdentityPublicKeyHash = [self getPublicKeyHashFromCertificate:certificateRef];
            if ([keychainIdentityPublicKeyHash isEqualToData:publicKeyHash]) {
                identityRef = (SecIdentityRef)CFBridgingRetain(keychainIdentity);
            }
        }
    }
    if (identityRef == NULL) {
        DDLogError(@"No associated identity found for certificate.");
        return NULL;
    }
    return identityRef;
}


- (SecKeyRef)copyPrivateKeyRefFromIdentityRef:(SecIdentityRef)identityRef
{
    SecKeyRef privateKeyRef = nil;
    OSStatus status = SecIdentityCopyPrivateKey(identityRef, &privateKeyRef);
    if (status != errSecSuccess) {
        DDLogError(@"No associated private key found for identity.");
        if (privateKeyRef) CFRelease(privateKeyRef);
        return NULL;
    }
    return privateKeyRef;
}


- (SecKeyRef)copyPublicKeyFromCertificate:(SecCertificateRef)certificateRef
{
    SecKeyRef publicKey = NULL;
    
    if (@available(iOS 10.0, *)) {
        publicKey = SecCertificateCopyPublicKey(certificateRef);
        if (publicKey == NULL) {
            DDLogError(@"No proper public key found in certificate.");
            return NULL;
        }
    } else {
        // SecCertificateCopyPublicKey() isn't available in iOS 9
        SecPolicyRef policy = SecPolicyCreateBasicX509();
        SecTrustRef trust = NULL;
        OSStatus status = SecTrustCreateWithCertificates(certificateRef, policy, &trust);
        CFRelease(policy);
        if (errSecSuccess != status) {
            DDLogError(@"SecTrustCreateWithCertificates status:%d",(int)status);
        }
        
        if (trust) {
            publicKey = SecTrustCopyPublicKey(trust);
            CFRelease(trust);
        }
    }
    
    return publicKey;
}


- (SecIdentityRef)createIdentityWithCertificate:(SecCertificateRef)certificate
{
    OSStatus status;
    
    NSDictionary *query = @{
                            (id)kSecClass: (id)kSecClassIdentity,
                            (id)kSecMatchLimit: (id)kSecMatchLimitAll,
                            (id)kSecReturnRef: @YES,
                            };
    CFArrayRef items = NULL;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&items);
    if (status != errSecSuccess) {
        DDLogError(@"Error in %s: SecItemCopyMatching(kSecClassIdentity) returned %@. Can't search keychain, no identities can be read.", __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
        if (items) CFRelease(items);
        return NULL;
    }
    NSArray *identities = (__bridge  NSArray*)(items);
    if (items) CFRelease(items);

    SecIdentityRef identityRef = NULL;
    SecCertificateRef certificateRef;
    for (id keychainIdentity in identities) {
        status = SecIdentityCopyCertificate((SecIdentityRef)keychainIdentity, &certificateRef);
        if (status == errSecSuccess && certificateRef == certificate) {
            identityRef = (__bridge SecIdentityRef)keychainIdentity;
        }
    }
    if (identityRef == NULL) {
        DDLogError(@"No associated identity found for certificate.");
        return NULL;
    }
    return identityRef;
}


- (SecCertificateRef)copyCertificateFromIdentity:(SecIdentityRef)identityRef
{
    SecCertificateRef certificateRef;
    OSStatus status = SecIdentityCopyCertificate(identityRef, &certificateRef);
    if (status != errSecSuccess) {
        DDLogError(@"No certificate found for identity.");
        if (certificateRef) CFRelease(certificateRef);
        return NULL;
    }
    return certificateRef;
}


- (NSData*)getDataForCertificate:(SecCertificateRef)certificate
{
    CFDataRef exportedData = SecCertificateCopyData(certificate);
    return (NSData*)CFBridgingRelease(exportedData);
}


- (BOOL)importCertificateFromData:(NSData*)certificateData
{
    //
    //    SecItemImportExportKeyParameters keyParams;
    //
    //    NSString *password = userDefaultsMasala;
    //
    //    keyParams.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
    //    keyParams.flags = 0;
    //    keyParams.passphrase = (__bridge CFTypeRef)(password);
    ////    keyParams.passphrase = NULL;
    //    keyParams.alertTitle = NULL;
    //    keyParams.alertPrompt = NULL;
    //    keyParams.accessRef = NULL;
    //    // These two values are for import
    ////    keyParams.keyUsage = (__bridge CFArrayRef)[NSArray arrayWithObjects:(__bridge id)(kSecAttrCanSign), (__bridge id)(kSecAttrCanWrap), nil];
    //    keyParams.keyUsage = NULL;
    //    keyParams.keyAttributes = NULL;
    //
    //    SecExternalItemType itemType = kSecItemTypeUnknown;
    ////    SecExternalFormat externalFormat = kSecFormatPEMSequence;
    ////    SecExternalItemType itemType = kSecItemTypeCertificate;
    ////    SecExternalFormat externalFormat = kSecFormatX509Cert;
    ////    SecExternalItemType itemType = kSecItemTypeAggregate;
    //    SecExternalFormat externalFormat = kSecFormatPKCS12;
    ////    SecExternalFormat externalFormat = kSecFormatUnknown;
    ////    SecExternalFormat externalFormat = kSecFormatPKCS7;
    //    int flags = 0;
    //
    //    SecKeychainRef keychain;
    //    SecKeychainCopyDefault(&keychain);
    //
    //    CFArrayRef outItems;
    //
    //    OSStatus status = SecItemImport((__bridge CFDataRef)certificateData,
    ////                                    (__bridge CFStringRef)@".cert", // filename or extension
    //                                    NULL, // filename or extension
    //                                   &externalFormat, // See SecExternalFormat for details
    //                                   &itemType, // item type
    //                                   flags, // See SecItemImportExportFlags for details
    //                                   &keyParams,
    //                                   keychain, // Don't import into a keychain
    //                                   &outItems);
    //    if (keychain) CFRelease(keychain);
    //    if (status != noErr) {
    //        if (status == errKCDuplicateItem) {
    //            DDLogDebug(@"%s: SecItemImport of embedded certificate failed, because it is already in the keychain.", __FUNCTION__);
    //        } else {
    //            DDLogError(@"Error in %s: SecItemImport of embedded certificate failed %@", __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
    //        }
    //        return NO;
    //    }
    //    return YES;
    return NO;
}


- (NSData*)getDataForPrivateKey:(SecKeyRef)privateKeyRef
{
    NSData *privateKeyData;
    
    if (@available(iOS 10.0, *)) {
        CFErrorRef error = NULL;
        privateKeyData = (NSData*)CFBridgingRelease(SecKeyCopyExternalRepresentation(privateKeyRef, &error));
        if (privateKeyRef) CFRelease(privateKeyRef);
        if (!privateKeyData) {
            DDLogError(@"Could not extract private key data:  %@", error);
            return nil;
        }
    } else {
        // iOS 9 didn't had the API above, ugly workaround to follow:
        NSString *const keychainTag = @"X509_KEY";
        OSStatus putResult, delResult = noErr;
        
        // Params for putting the key first
        NSMutableDictionary *putKeyParams = [NSMutableDictionary new];
        putKeyParams[(__bridge id) kSecClass] = (__bridge id) kSecClassKey;
        putKeyParams[(__bridge id) kSecAttrKeyType] = (__bridge id) kSecAttrKeyTypeRSA;
        putKeyParams[(__bridge id) kSecAttrApplicationTag] = keychainTag;
        putKeyParams[(__bridge id) kSecValueRef] = (__bridge id) (privateKeyRef);
        putKeyParams[(__bridge id) kSecReturnData] = (__bridge id) (kCFBooleanTrue); // Request the key's data to be returned too
        
        // Params for deleting the data
        NSMutableDictionary *delKeyParams = [[NSMutableDictionary alloc] init];
        delKeyParams[(__bridge id) kSecClass] = (__bridge id) kSecClassKey;
        delKeyParams[(__bridge id) kSecAttrApplicationTag] = keychainTag;
        delKeyParams[(__bridge id) kSecReturnData] = (__bridge id) (kCFBooleanTrue);
        
        // Put the key
        putResult = SecItemAdd((__bridge CFDictionaryRef) putKeyParams, (void *)&privateKeyData);
        // Delete the key
        delResult = SecItemDelete((__bridge CFDictionaryRef)(delKeyParams));
        
        if ((putResult != errSecSuccess) || (delResult != errSecSuccess))
        {
            DDLogError(@"Could not extract public key data: %d", (int)putResult);
            if (privateKeyRef) CFRelease(privateKeyRef);
            return nil;
        }
    }
    
    return privateKeyData;
}


- (NSData*)getDataForIdentity:(SecIdentityRef)identityRef
{
    SecCertificateRef certificateRef = [self copyCertificateFromIdentity:identityRef];
    NSData *certificateData = [self getDataForCertificate:certificateRef];
    MscX509CommonError *error = nil;
    MscCertificate *certificate = [[MscCertificate alloc] initWithData:certificateData error:&error];
    
    SecKeyRef privateKey = [self copyPrivateKeyRefFromIdentityRef:identityRef];
    NSData *privateKeyData = [self getDataForPrivateKey:privateKey];
    NSString *pemPrivateKey = [NSString stringWithFormat:@"-----BEGIN RSA PRIVATE KEY-----\n%@\n-----END RSA PRIVATE KEY-----\n", [privateKeyData base64EncodedStringWithOptions:0]];

    const char *key = [pemPrivateKey UTF8String];
    BIO *bio = BIO_new_mem_buf((void *) key, (int) strlen(key));
    RSA *privateKeyRSA = PEM_read_bio_RSAPrivateKey(bio, NULL, 0, NULL);
    BIO_free(bio);

    MscRSAKey *mscRSAKey = [[MscRSAKey alloc] initWithRSA:privateKeyRSA];
    
    MscPKCS12 *mscPKCS12 = [[MscPKCS12 alloc]initWithRSAKey:mscRSAKey certificate:certificate password:userDefaultsMasala error:&error];
    
    return [mscPKCS12 data];
}


- (BOOL) importIdentityFromData:(NSData*)identityData
{
    
    NSString *password = userDefaultsMasala;
    NSDictionary* options = @{ (id)kSecImportExportPassphrase : password };
    
    CFArrayRef rawItems = NULL;
    OSStatus status = SecPKCS12Import((__bridge CFDataRef)identityData,
                                      (__bridge CFDictionaryRef)options,
                                      &rawItems);

    NSArray* items = (NSArray*)CFBridgingRelease(rawItems); // Transfer to ARC
    NSDictionary* firstItem = nil;
    if ((status == errSecSuccess) && (items.count > 0)) {
        firstItem = items[0];
    } else {
        DDLogError(@"Importing an identity from PKCS12 data using SecItemImport failed (oserr=%d)\n", (int)status);
        return NO;
    }

    SecIdentityRef identity =
    (SecIdentityRef)CFBridgingRetain(firstItem[(id)kSecImportItemIdentity]);

    NSDictionary* addQuery = @{ (id)kSecValueRef:   (__bridge_transfer id)identity,
                                (id)kSecAttrLabel:  SEBFullAppName,
                                };

    status = SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL);
    if (status != errSecSuccess) {
        if (status == errSecDuplicateItem) {
            DDLogInfo(@"Not adding an identity to the Keychain: The item already exists.");
        } else {
            DDLogError(@"Adding an identity to the Keychain using SecItemAdd failed (oserr=%d)\n", (int)status);
        }
        return NO;
    }
    DDLogInfo(@"Successfully imported identity into the Keychain");
    
    // Save the current SEB admin password hash for the identity
    NSData *publicKeyHash = [self getPublicKeyHashFromIdentity:identity];
    NSString *publicKeyHashBase64 = [publicKeyHash base64EncodedStringWithOptions:(0)];
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *adminPasswordHash = [[preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"].uppercaseString dataUsingEncoding:NSUTF8StringEncoding];
    [self.keychainManager storeKeyWithID:publicKeyHashBase64 keyData:adminPasswordHash];
    return YES;
}


// Generate PKCS12 identity data
- (NSData *)generatePKCS12IdentityWithName:(NSString *)commonName
{
    EVP_PKEY * pkey;
    pkey = EVP_PKEY_new();
    
    RSA * rsa;
    rsa = RSA_generate_key(
                           2048,   /* number of bits for the key - 2048 is a sensible value */
                           RSA_F4, /* exponent - RSA_F4 is defined as 0x10001L */
                           NULL,   /* callback - can be NULL if we aren't displaying progress */
                           NULL    /* callback argument - not needed in this case */
                           );
    
    if (!rsa) {
        DDLogError(@"%s: RSA_generate_key failed!", __FUNCTION__);
    }
    
    EVP_PKEY_assign_RSA(pkey, rsa);
    
    X509 * x509;
    x509 = X509_new();
    
    ASN1_INTEGER_set(X509_get_serialNumber(x509), 1);
    
    X509_gmtime_adj(X509_get_notBefore(x509), 0);
    X509_gmtime_adj(X509_get_notAfter(x509), 31536000L);
    
    X509_set_pubkey(x509, pkey);
    
    X509_NAME * name;
    name = X509_get_subject_name(x509);
    
    X509_NAME_add_entry_by_txt(name, "C",  MBSTRING_ASC,
                               (unsigned char *)[SEBCountry UTF8String], -1, -1, 0);
    X509_NAME_add_entry_by_txt(name, "O",  MBSTRING_ASC,
                               (unsigned char *)[SEBWebsiteShort UTF8String], -1, -1, 0);
    X509_NAME_add_entry_by_txt(name, "CN", MBSTRING_ASC,
                               (unsigned char *)[commonName UTF8String], -1, -1, 0);
    
    X509_set_issuer_name(x509, name);
    
    X509_sign(x509, pkey, EVP_sha256());
    
    MscRSAKey *mscRSAKey = [[MscRSAKey alloc] initWithRSA:rsa];
    MscCertificate *certificate = [[MscCertificate alloc] initWithX509:x509];
    if (!certificate) {
        DDLogError(@"%s: [[MscCertificate alloc] initWithX509:x509] failed!", __FUNCTION__);
    }

    MscX509CommonError *error = nil;
    MscPKCS12 *mscPKCS12 = [[MscPKCS12 alloc] initWithRSAKey:mscRSAKey certificate:certificate password:userDefaultsMasala error:&error];

    if (!mscPKCS12) {
        DDLogError(@"%s: Generating PKCS12 data from private key and certificate failed!", __FUNCTION__);
        return nil;
    }
    return [mscPKCS12 data];
}


- (NSData*)encryptData:(NSData*)plainData withPublicKeyFromCertificate:(SecCertificateRef)certificateRef
{
    SecKeyRef publicKeyRef = [self copyPublicKeyFromCertificate:certificateRef];
    if (!publicKeyRef) {
        DDLogError(@"No public key found in certificate.");
        return nil;
    }

    const uint8_t *srcbuf = (const uint8_t *)[plainData bytes];
    size_t srclen = (size_t)plainData.length;
    
    size_t block_size = SecKeyGetBlockSize(publicKeyRef) * sizeof(uint8_t);
    void *outbuf = malloc(block_size);
    size_t src_block_size = block_size - 11;
    
    NSMutableData *cipherData = [[NSMutableData alloc] init];
    for (int idx=0; idx<srclen; idx+=src_block_size) {
        //NSLog(@"%d/%d block_size: %d", idx, (int)srclen, (int)block_size);
        size_t data_len = srclen - idx;
        if (data_len > src_block_size) {
            data_len = src_block_size;
        }
        size_t outlen = block_size;
        OSStatus status = noErr;
//        if (isSign) {
//            status = SecKeyRawSign(publicKeyRef,
//                                   kSecPaddingPKCS1,
//                                   srcbuf + idx,
//                                   data_len,
//                                   outbuf,
//                                   &outlen
//                                   );
//    }
        status = SecKeyEncrypt(publicKeyRef,
                               kSecPaddingPKCS1,
                               srcbuf + idx,
                               data_len,
                               outbuf,
                               &outlen
                               );
        if (status != 0) {
            DDLogError(@"Encrypting data using private key failed! Error Code: %d", (int)status);
            free(outbuf);
            CFRelease(publicKeyRef);
            return nil;
        } else {
            [cipherData appendBytes:outbuf length:outlen];
        }
    }
    free(outbuf);
    CFRelease(publicKeyRef);
    return cipherData;
}


- (NSData*)decryptData:(NSData*)cipherData withPrivateKey:(SecKeyRef)privateKeyRef
{
    size_t blockSize = SecKeyGetBlockSize(privateKeyRef);
    uint8_t *buffer = calloc(blockSize, sizeof(uint8_t));
    
    NSMutableData *plainData = [NSMutableData new];
    for (NSUInteger i = 0; i < [cipherData length]; i += blockSize) {
        NSData *subCipherText = [cipherData subdataWithRange:NSMakeRange(i, MIN(blockSize, [cipherData length] - i))];
        size_t plainTextLen = blockSize;
        
        OSStatus status = SecKeyDecrypt(privateKeyRef, kSecPaddingPKCS1, [subCipherText bytes], [subCipherText length], buffer, &plainTextLen);
        if (status != errSecSuccess) {
            DDLogError(@"Decrypting data using private key failed! (oserr=%d)\n", (int)status);
            free(buffer);
            return nil;
        }
        [plainData appendBytes:buffer length:plainTextLen];
    }
    free(buffer);
    
    if (privateKeyRef) {
        CFRelease(privateKeyRef);
    }
    return plainData;
}

@end
