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
//  Dirk Bauer, Karsten Burger, Marco Lehre,
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
#import "SEBCryptor.h"
#include "x509_crt.h"

@implementation SEBKeychainManager

// We ignore "deprecated" warnings for CSSM methods, since Apple doesn't provide any replacement
// for asymetric public key cryptography as of OS X 10.10
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (NSArray*)getIdentitiesAndNames:(NSArray **)names {
    SecKeychainRef keychain;
    OSStatus status;
    status = SecKeychainCopyDefault(&keychain);
    if (status != noErr) {
        DDLogError(@"Error in %s: SecKeychainCopyDefault returned %@. Cannot access keychain, no identities can be read.",
                   __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
        if (keychain) CFRelease(keychain);
        return nil;
    }
    
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)kSecClassIdentity, (__bridge id)kSecClass,
                           [NSArray arrayWithObject:(__bridge id)keychain], (__bridge id)kSecMatchSearchList,
                           //kCFBooleanTrue, kSecAttrCanEncrypt,
                           //kCFBooleanTrue, kSecAttrCanDecrypt,
                           (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnRef,
                           (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                           nil];
    CFArrayRef items = NULL;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&items);
    if (keychain) CFRelease(keychain);
    if (status != errSecSuccess) {
        DDLogError(@"Error in %s: SecItemCopyMatching(kSecClassIdentity) returned %@. Can't search keychain, no identities can be read.",
                   __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
        if (items) CFRelease(items);
        return nil;
    }
    NSMutableArray *identities = [NSMutableArray arrayWithArray:(__bridge  NSArray*)(items)];
    if (items) CFRelease(items);
    NSMutableArray *identitiesNames = [NSMutableArray arrayWithCapacity:[identities count]];
    
    CFStringRef commonName;
    SecCertificateRef certificateRef;
    SecKeyRef publicKeyRef;
    SecKeyRef privateKeyRef;
    CFArrayRef emailAddressesRef;
    NSString *identityName;
    int i, count = [identities count];
    for (i=0; i<count; i++) {
        SecIdentityRef identityRef = (__bridge SecIdentityRef)[identities objectAtIndex:i];
        if (SecIdentityCopyCertificate(identityRef, &certificateRef) == noErr) {
            if (SecIdentityCopyPrivateKey(identityRef, &privateKeyRef) == noErr) {
                /*SecPolicyRef policyRef = SecPolicyCreateBasicX509();
                 //status = SecPolicySetValue(policyRef, )
                 SecTrustRef trustRef;
                 status = SecTrustCreateWithCertificates((CFArrayRef)certificateRef, policyRef, &trustRef);
                 SecTrustResultType trustResult;
                 if (status == noErr) {
                 status = SecTrustEvaluate(trustRef, &trustResult);
                 }*/
                const CSSM_KEY *pubKey;
                if ((status = SecCertificateCopyPublicKey(certificateRef, &publicKeyRef)) == noErr) {
                    if ((status = SecKeyGetCSSMKey(publicKeyRef, &pubKey)) == noErr) {
                        const CSSM_KEY *privKey;
                        if ((status = SecKeyGetCSSMKey(privateKeyRef, &privKey)) == noErr) {
                            if (((pubKey->KeyHeader.AlgorithmId ==
                                  CSSM_ALGID_RSA) &&
                                 ((pubKey->KeyHeader.KeyUsage & CSSM_KEYUSE_ENCRYPT) ||
                                  (pubKey->KeyHeader.KeyUsage & CSSM_KEYUSE_WRAP) ||
                                  (pubKey->KeyHeader.KeyUsage & CSSM_KEYUSE_ANY)))
                                && ((privKey->KeyHeader.AlgorithmId ==
                                     CSSM_ALGID_RSA) &&
                                    ((privKey->KeyHeader.KeyUsage & CSSM_KEYUSE_DECRYPT) ||
                                     (privKey->KeyHeader.KeyUsage & CSSM_KEYUSE_WRAP) ||
                                     (privKey->KeyHeader.KeyUsage & CSSM_KEYUSE_ANY))))
                            {
                                if ((status = SecCertificateCopyCommonName(certificateRef, &commonName)) == noErr) {
                                    if ((status = SecCertificateCopyEmailAddresses(certificateRef, &emailAddressesRef)) == noErr) {
                                        identityName = [NSString stringWithFormat:@"%@%@",
                                                        (__bridge NSString *)commonName ?
                                                        [NSString stringWithFormat:@"%@ ",(__bridge NSString *)commonName] :
                                                        @"" ,
                                                        CFArrayGetCount(emailAddressesRef) ?
                                                        (__bridge NSString *)CFArrayGetValueAtIndex(emailAddressesRef, 0) :
                                                        @""];
                                        // Check if there is already an identitiy with the identical name (can happen)
                                        if ([identitiesNames containsObject:identityName]) {
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
                                            [identitiesNames addObject:[NSString stringWithFormat:@"%@ %@",identityName, hashedString]];
                                        } else {
                                            [identitiesNames addObject:identityName];
                                        }
                                        
                                        DDLogDebug(@"Common name: %@ %@",
                                                   (__bridge NSString *)commonName ? (__bridge NSString *)commonName : @"" ,
                                                   CFArrayGetCount(emailAddressesRef) ? (__bridge NSString *)CFArrayGetValueAtIndex(emailAddressesRef, 0) : @"");
                                        DDLogDebug(@"Public key can be used for encryption, private key can be used for decryption");
                                        if (emailAddressesRef) CFRelease(emailAddressesRef);
                                        if (commonName) CFRelease(commonName);
                                        if (publicKeyRef) CFRelease(publicKeyRef);
                                        if (privateKeyRef) CFRelease(privateKeyRef);
                                        if (certificateRef) CFRelease(certificateRef);
                                        // Continue with next element
                                        continue;
                                        
                                    } else {
                                        DDLogError(@"Error in %s: SecCertificateCopyEmailAddresses returned %@. This identity will be skipped.",
                                                   __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
                                    }
                                    
                                    if (commonName) CFRelease(commonName);
                                } else {
                                    DDLogError(@"Error in %s: SecCertificateCopyCommonName returned %@. This identity will be skipped.",
                                               __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
                                }
                            }
                        } else {
                            DDLogError(@"Error in %s: SecKeyGetCSSMKey(privateKey) returned %@. This identity will be skipped.",
                                       __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
                        }
                    } else {
                        DDLogError(@"Error in %s: SecKeyGetCSSMKey(publicKey) returned %@. This identity will be skipped.",
                                   __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
                    }
                    
                    if (publicKeyRef) CFRelease(publicKeyRef);
                } else {
                    DDLogError(@"Error in %s: SecCertificateCopyPublicKey returned %@. This identity will be skipped.",
                               __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
                }
                
                if (privateKeyRef) CFRelease(privateKeyRef);
            } else {
                DDLogError(@"Error in %s: SecIdentityCopyPrivateKey returned %@. This identity will be skipped.",
                           __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
            }
            
            if (certificateRef) CFRelease(certificateRef);
        } else {
            DDLogError(@"Error in %s: SecIdentityCopyCertificate returned %@. This identity will be skipped.",
                       __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
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


- (NSArray*)getCertificatesOfType:(certificateTypes)certificateType {
    OSStatus status;
    if (!_allCertificates) {
        SecKeychainRef keychain;
        status = SecKeychainCopyDefault(&keychain);
        if (status != noErr) {
            DDLogError(@"Error in %s: SecKeychainCopyDefault returned %@. Cannot access keychain, no certificates can be read.",
                       __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
            if (keychain) CFRelease(keychain);
            return nil;
        }
        
        NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                               (__bridge id)kSecClassCertificate, (__bridge id)kSecClass,
                               [NSArray arrayWithObject:(__bridge id)keychain], (__bridge id)kSecMatchSearchList,
                               (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnRef,
                               (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                               nil];
        CFTypeRef items = NULL;
        
        status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&items);
        if (keychain) CFRelease(keychain);
        if (status != errSecSuccess) {
            DDLogError(@"Error in %s: SecItemCopyMatching(kSecClassIdentity) returned %@. Can't search keychain, no certificates can be read.",
                       __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
            if (items) CFRelease(items);
            return nil;
        }
        
        _allCertificates = (__bridge_transfer NSArray*)(items);
    }
    NSMutableArray *certificates = [NSMutableArray arrayWithCapacity:1];
    
    CFStringRef commonName = NULL;
    CFArrayRef emailAddressesRef = NULL;
    int i, count = [_allCertificates count];
    for (i=0; i<count; i++) {
        SecCertificateRef certificateRef = (__bridge SecCertificateRef)[_allCertificates objectAtIndex:i];
        if ((status = SecCertificateCopyCommonName(certificateRef, &commonName)) == noErr) {
            if ((status = SecCertificateCopyEmailAddresses(certificateRef, &emailAddressesRef)) == noErr) {
                CFErrorRef error = NULL;
                
                // Get signature, valid from, valid to and extended key usage
                NSDictionary *certSpecifiers = (NSDictionary *)CFBridgingRelease(SecCertificateCopyValues
                                                                                 (certificateRef,
                                                                                  (__bridge CFArrayRef)[NSArray arrayWithObjects:(__bridge id)(kSecOIDX509V1ValidityNotAfter),
                                                                                                        (__bridge id)(kSecOIDX509V1ValidityNotBefore),
                                                                                                        (__bridge id)(kSecOIDExtendedKeyUsage),
                                                                                                        nil],
                                                                                  &error));
                
                // Check validity (from - to) of certfificate
                NSDate *validFrom;
                NSDate *validTo;
                BOOL *isExpired = true;
                if ([certSpecifiers count]) {
                    NSDictionary *validFromDict = [certSpecifiers objectForKey:(__bridge id)(kSecOIDX509V1ValidityNotBefore)];
                    if (validFromDict.count) {
                        validFrom = [NSDate dateWithTimeIntervalSinceReferenceDate:(double)[[validFromDict objectForKey:@"value"] doubleValue]];
                    }
                    NSDictionary *validToDict = [certSpecifiers objectForKey:(__bridge id)(kSecOIDX509V1ValidityNotAfter)];
                    if (validToDict.count) {
                        validTo = [NSDate dateWithTimeIntervalSinceReferenceDate:(double)[[validToDict objectForKey:@"value"] doubleValue]];
                    }
                    
                    NSDate *now = [NSDate date];
                    if ([validFrom compare:now] == NSOrderedAscending) {
                        if ([validTo compare:now] == NSOrderedDescending) {
                            isExpired = false;
                        }
                    }
                }
                
                // Get certificate name
                NSString *certificateName = [NSString stringWithFormat:@"%@",
                                             (__bridge NSString *)commonName ?
                                             // There is a commonName: just take that as a name
                                             [NSString stringWithFormat:@"%@",(__bridge NSString *)commonName] :
                                             // There is no common name: take the e-mail address (if it exists)
                                             CFArrayGetCount(emailAddressesRef) ?
                                             (__bridge NSString *)CFArrayGetValueAtIndex(emailAddressesRef, 0) :
                                             @""];

                // Get certificate signature hash (fingerprint)
                NSData *signatureData = CFBridgingRelease(SecCertificateCopyData(certificateRef));
                if (!signatureData) {
                    // If the hash couldn't be determinded (what actually shouldn't happen): Create random data instead
                    signatureData = [RNCryptor randomDataOfLength:128];
                }
                NSString *signatureHash = [[self generateSHA1HashStringFromData:signatureData] uppercaseString];

                // If the certificate didn't had neither common name or e-mail: Use the fingerprint in brackets as name
                if ([certificateName isEqualToString:@""]) {
                    certificateName = [NSString stringWithFormat:@"(%@)", signatureHash];
                }
                
                // SSL and CA certs need to have a unique certificate name
                if (certificateType != certificateTypeSSLDebug) {
                    // Check for duplicate name
                    NSPredicate * predicate = [NSPredicate predicateWithFormat:@" name ==[cd] %@", certificateName];
                    NSArray * matches = [certificates filteredArrayUsingPredicate:predicate];
                    // If the name isn't unique, append the fingerprint in brackets
                    if (matches.count > 0) {
                        certificateName = [NSString stringWithFormat:@"%@ (%@)", certificateName, signatureHash];
                    }
                }
                
                // Get certificate info
                NSString *certificateInfo = @"";
                mbedtls_x509_crt cert;
                mbedtls_x509_crt_init(&cert);
                
                // Get DER data
                NSData *data = CFBridgingRelease(SecCertificateCopyData(certificateRef));
                
                if (data)
                {
                    if (mbedtls_x509_crt_parse_der(&cert, [data bytes], [data length]) == 0)
                    {
                        char infoBuf[2048];
                        *infoBuf = '\0';
                        mbedtls_x509_crt_info(infoBuf, sizeof(infoBuf) - 1, "   ", &cert);
                        certificateInfo = [NSString stringWithFormat:@"%s", infoBuf];
                        DDLogDebug(@"\n%s\n", infoBuf);
                    }
                }
                
                // Filter certificates according to the requested certificate type
                switch (certificateType) {
                    case certificateTypeSSL:
                    {
                        if (!isExpired) {
                            // Keep only certificates which have an extended key usage server authentification
                            if ([certSpecifiers count]) {
                                NSDictionary *value = [certSpecifiers objectForKey:(__bridge id)(kSecOIDExtendedKeyUsage)];
                                NSArray *extendedKeyUsages = [value objectForKey:(__bridge id)(kSecPropertyKeyValue)];
                                if ([extendedKeyUsages containsObject:[NSData dataWithBytes:keyUsageServerAuthentication length:8]]) {
                                    
                                    [certificates addObject:@{
                                                              @"ref" : (__bridge id)certificateRef,
                                                              @"name" : certificateName
                                                              }];
                                    DDLogDebug(@"Adding SSL certificate with common name: %@", certificateName);
                                    
                                    break;
                                }
                            } else {
                                NSString *errorDescription = @"";
                                if (error != NULL) {
                                    errorDescription = [NSString stringWithFormat:@"SecCertificateCopyValues error: %@. ", CFBridgingRelease(CFErrorCopyDescription(error))];
                                }
                                DDLogDebug(@"Common name: %@. No extended key usage server authentification has been found. %@ This certificate will be skipped.",
                                           certificateName , errorDescription);
                            }
                        }
                        break;
                    }
                        
                        
                    case certificateTypeCA:
                    {
                        if (!isExpired) {
                            if (cert.ext_types & MBEDTLS_X509_EXT_BASIC_CONSTRAINTS)
                            {
                                if (cert.ca_istrue)
                                {
                                    
                                    [certificates addObject:@{
                                                              @"ref" : (__bridge id)certificateRef,
                                                              @"name" : certificateName
                                                              }];
                                    DDLogDebug(@"\nAdding CA certificate:\n%@\n", certificateInfo);
                                    
                                    //                                            break;
                                }
                            }
                        }
                        break;
                    }
                        
                    case certificateTypeSSLDebug:
                    {
                        // Add all certificates, without testing them for properties
                        // which sometimes just are not set on some slacker certs
                        [certificates addObject:@{
                                                  @"ref" : (__bridge id)certificateRef,
                                                  @"name" : certificateName,
                                                  @"valid_from" : validFrom,
                                                  @"valid_to" : validTo,
                                                  @"isExpired" : [NSNumber numberWithBool:isExpired],
                                                  @"info" : certificateInfo
                                                  }];
                        DDLogDebug(@"Adding debug certificate with common name: %@", certificateName);
                        
                        break;
                    }
                        
                    default:
                        break;
                }
                
                mbedtls_x509_crt_free(&cert);
                
                if (emailAddressesRef) CFRelease(emailAddressesRef);
            } else {
                DDLogError(@"Error in %s: SecCertificateCopyEmailAddresses returned %@. This certificate will be skipped.",
                           __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
            }
            if (commonName) CFRelease(commonName);
        } else {
            DDLogError(@"Error in %s: SecCertificateCopyCommonName returned %@. This certificate will be skipped.",
                       __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
        }
    }
    
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortByName];
    NSArray *sortedCertificates = [[NSArray arrayWithArray:certificates] sortedArrayUsingDescriptors:sortDescriptors];
        
    return sortedCertificates; // items contains all applicable SecIdentityRefs in keychain
}


- (NSData*)getPublicKeyHashFromCertificate:(SecCertificateRef)certificate {
    NSData *subjectKeyIdentifier = nil;
    static const UInt32 desiredAttributeTags[1] = { kSecPublicKeyHashItemAttr };
    static const UInt32 desiredAttributeFormats[1] = { CSSM_DB_ATTRIBUTE_FORMAT_BLOB };
    static const SecKeychainAttributeInfo desiredAtts = {
        .count = 1,
        .tag = (UInt32 *)desiredAttributeTags,
        .format = (UInt32 *)desiredAttributeFormats
    };
    
    SecKeychainAttributeList *retrievedAtts = NULL;
    
    SecKeychainItemRef asKCItem = (SecKeychainItemRef)certificate; // Superclass, but the compiler doesn't know that for CFTypes
    OSStatus err = SecKeychainItemCopyAttributesAndData(asKCItem, (SecKeychainAttributeInfo *)&desiredAtts, NULL, &retrievedAtts, NULL, NULL);

    if (err == noErr) {
        if (retrievedAtts->count == 1 &&
            retrievedAtts->attr[0].tag == kSecPublicKeyHashItemAttr) {
            //retrievedAtts->attr[0].length == [subjectKeyIdentifier length] &&
            //memcmp(retrievedAtts->attr[0].data, [subjectKeyIdentifier bytes], retrievedAtts->attr[0].length);
            subjectKeyIdentifier = [NSData dataWithBytes:retrievedAtts->attr[0].data length:retrievedAtts->attr[0].length];
            SecKeychainItemFreeAttributesAndData(retrievedAtts, NULL);
            return subjectKeyIdentifier;
        }
    } else if (err == errKCNotAvailable) {
        DDLogError(@"Keychain Manager was not loaded.");
        SecKeychainItemFreeAttributesAndData(retrievedAtts, NULL);
    }
    return nil;
}


- (SecKeyRef)getPrivateKeyFromPublicKeyHash:(NSData*)publicKeyHash {
    SecKeyRef privateKeyRef = nil;
    SecIdentityRef identityRef = [self getIdentityRefFromPublicKeyHash:publicKeyHash];
    if (!identityRef) {
        return nil;
    }
    OSStatus status = SecIdentityCopyPrivateKey(identityRef, &privateKeyRef);
    if (identityRef) CFRelease(identityRef);
    if (status != errSecSuccess) {
        DDLogError(@"No associated private key found for public key hash.");
        if (privateKeyRef) CFRelease(privateKeyRef);
        return nil;
    }
    return privateKeyRef;
}


- (SecIdentityRef)getIdentityRefFromPublicKeyHash:(NSData*)publicKeyHash {
    SecKeychainRef keychain;
    OSStatus error;
    error = SecKeychainCopyDefault(&keychain);
    if (error) {
        if (keychain) CFRelease(keychain);
        return nil;
    }
    
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)kSecClassCertificate, (__bridge id)kSecClass,
                           (__bridge CFDataRef)publicKeyHash, (__bridge id)kSecAttrPublicKeyHash,
                           [NSArray arrayWithObject:(__bridge id)keychain], (__bridge id)kSecMatchSearchList,
                           (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnRef,
                           nil];
    SecCertificateRef certificateRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&certificateRef);
    if (keychain) CFRelease(keychain);
    if (status != errSecSuccess) {
        if (certificateRef) CFRelease(certificateRef);
        return nil;
    }
    SecIdentityRef identityRef = [self createIdentityWithCertificate:certificateRef];
    if (certificateRef) CFRelease(certificateRef);
    return identityRef;
}


- (SecKeyRef)copyPrivateKeyRefFromIdentityRef:(SecIdentityRef)identityRef {
    SecKeyRef privateKeyRef = nil;
    OSStatus status = SecIdentityCopyPrivateKey(identityRef, &privateKeyRef);
    if (status != errSecSuccess) {
        DDLogError(@"No associated private key found for identity.");
        if (privateKeyRef) CFRelease(privateKeyRef);
        return nil;
    }
    return privateKeyRef;
}


- (SecKeyRef*)copyPublicKeyFromCertificate:(SecCertificateRef)certificate {
    SecKeyRef key = NULL;
    OSStatus status = SecCertificateCopyPublicKey(certificate, &key);
    if (status == errSecItemNotFound) {
        DDLogError(@"No public key found in certificate.");
        if (key) CFRelease(key);
        return nil;
    }
    return (SecKeyRef*)key; // public key contained in certificate
}


- (SecIdentityRef)createIdentityWithCertificate:(SecCertificateRef)certificate {
    SecIdentityRef identityRef;
    OSStatus status = SecIdentityCreateWithCertificate(NULL, certificate, &identityRef);
    if (status == errSecItemNotFound) {
        DDLogError(@"No associated private key found for certificate.");
        if (identityRef) CFRelease(identityRef);
        return nil;
    }
    return identityRef; // public key contained in certificate
}


- (SecCertificateRef)copyCertificateFromIdentity:(SecIdentityRef)identityRef {
    SecCertificateRef certificateRef;
    OSStatus status = SecIdentityCopyCertificate(identityRef, &certificateRef);
    if (status != errSecSuccess) {
        DDLogError(@"No certificate found for identity.");
        if (certificateRef) CFRelease(certificateRef);
        return nil;
    }
    return certificateRef;
}


- (NSData*)getDataForCertificate:(SecCertificateRef)certificate {
    
    SecItemImportExportKeyParameters keyParams;
    
    NSString *password = userDefaultsMasala;

    keyParams.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
    keyParams.flags = 0;
    keyParams.passphrase = (__bridge CFTypeRef)(password);
//    keyParams.passphrase = NULL;
    keyParams.alertTitle = NULL;
    keyParams.alertPrompt = NULL;
    keyParams.accessRef = NULL;
    // These two values are for import
    keyParams.keyUsage = NULL;
    keyParams.keyAttributes = NULL;
    
    CFDataRef exportedData = NULL;
    
    OSStatus success = SecItemExport (
                                      certificate,
//                                      kSecFormatNetscapeCertSequence,
                                      kSecFormatX509Cert,
                                      0,
                                      &keyParams,
                                      &exportedData
                                      );
    
    if (success == errSecSuccess) {
        return (NSData*)CFBridgingRelease(exportedData);
    } else {
        DDLogError(@"Error in %s: SecItemImport of embedded certificate failed %@", __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:success userInfo:NULL]);
        if (exportedData) CFRelease(exportedData);
        return nil;
    }
}


- (BOOL)importCertificateFromData:(NSData*)certificateData {

    SecItemImportExportKeyParameters keyParams;
    
    NSString *password = userDefaultsMasala;
    
    keyParams.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
    keyParams.flags = 0;
    keyParams.passphrase = (__bridge CFTypeRef)(password);
//    keyParams.passphrase = NULL;
    keyParams.alertTitle = NULL;
    keyParams.alertPrompt = NULL;
    keyParams.accessRef = NULL;
    // These two values are for import
//    keyParams.keyUsage = (__bridge CFArrayRef)[NSArray arrayWithObjects:(__bridge id)(kSecAttrCanSign), (__bridge id)(kSecAttrCanWrap), nil];
    keyParams.keyUsage = NULL;
    keyParams.keyAttributes = NULL;
    
    SecExternalItemType itemType = kSecItemTypeUnknown;
//    SecExternalFormat externalFormat = kSecFormatPEMSequence;
//    SecExternalItemType itemType = kSecItemTypeCertificate;
//    SecExternalFormat externalFormat = kSecFormatX509Cert;
//    SecExternalItemType itemType = kSecItemTypeAggregate;
    SecExternalFormat externalFormat = kSecFormatPKCS12;
//    SecExternalFormat externalFormat = kSecFormatUnknown;
//    SecExternalFormat externalFormat = kSecFormatPKCS7;
    int flags = 0;
    
    SecKeychainRef keychain;
    SecKeychainCopyDefault(&keychain);
    
    CFArrayRef outItems;
    
    OSStatus status = SecItemImport((__bridge CFDataRef)certificateData,
//                                    (__bridge CFStringRef)@".cert", // filename or extension
                                    NULL, // filename or extension
                                   &externalFormat, // See SecExternalFormat for details
                                   &itemType, // item type
                                   flags, // See SecItemImportExportFlags for details
                                   &keyParams,
                                   keychain, // Don't import into a keychain
                                   &outItems);
    if (keychain) CFRelease(keychain);
    if (status != noErr) {
        if (status == errKCDuplicateItem) {
            DDLogWarn(@"%s: SecItemImport of embedded certificate failed, because it is already in the keychain.", __FUNCTION__);
        } else {
            DDLogError(@"Error in %s: SecItemImport of embedded certificate failed %@", __FUNCTION__, [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:NULL]);
        }
        return NO;
    }
    return YES;
}


- (NSData*)getDataForIdentity:(SecIdentityRef)identity {
    
    SecItemImportExportKeyParameters keyParams;
    
    NSString *password = userDefaultsMasala;
    
    keyParams.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
    keyParams.flags = 0;
    keyParams.passphrase = (__bridge CFTypeRef)(password);
    keyParams.alertTitle = NULL;
    keyParams.alertPrompt = NULL;
    keyParams.accessRef = NULL;
    // These two values are for import
    keyParams.keyUsage = NULL;
    keyParams.keyAttributes = NULL;
    
    CFDataRef exportedData = NULL;

    OSStatus success = SecItemExport (
                            identity,
                            kSecFormatPKCS12,
                            0,
                            &keyParams,
                            &exportedData
                            );
    
    if (success == errSecSuccess) return (NSData*)CFBridgingRelease(exportedData); else return nil;
}


- (BOOL) importIdentityFromData:(NSData*)identityData
{
    // Create a trusted application object for SEB
    SecTrustedApplicationRef trustedApplicationRef;
    OSStatus oserr = SecTrustedApplicationCreateFromPath(NULL, &trustedApplicationRef);
    if (oserr) {
        DDLogError(@"SecTrustedApplicationCreateFromPath failed, cannot create trusted application object for SEB (oserr=%d)\n", oserr);
        if (trustedApplicationRef) CFRelease(trustedApplicationRef);
        return NO;
    }
    // Create a access control list entry
    NSArray *trustedApplications = [NSArray arrayWithObjects:(__bridge id)trustedApplicationRef, nil];
    SecAccessRef access = NULL;
    NSString *accessLabel = @"Safe Exam Browser";

    oserr = SecAccessCreate((__bridge CFStringRef)accessLabel,(__bridge CFArrayRef)trustedApplications, &access);
    if (trustedApplicationRef) CFRelease(trustedApplicationRef);
    if (oserr) {
        DDLogError(@"SecAccessCreate failed, cannot create access object for SEB (oserr=%d)\n", oserr);
        if (trustedApplicationRef) CFRelease(trustedApplicationRef);
        if (access) CFRelease(access);
        return NO;
    }

    
//    SecACLRef accessControlRef;
//    oserr = SecACLCreateWithSimpleContents(access, (__bridge CFArrayRef)([NSArray arrayWithObject:(__bridge id)trustedApplicationRef]), (__bridge CFStringRef)accessLabel, kSecKeychainPromptUnsigned, &accessControlRef);
//    if (oserr) {
//        DDLogError(@"SecACLCreateWithSimpleContents failed, cannot create access control list entry for SEB (oserr=%d)\n", oserr);
//        if (trustedApplicationRef) CFRelease(trustedApplicationRef);
//        if (access) CFRelease(access);
//        if (accessControlRef) CFRelease(accessControlRef);
//        return NO;
//    }

    SecItemImportExportKeyParameters keyParams;
    
    NSString *password = userDefaultsMasala;
    
    keyParams.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
    keyParams.flags = 0;
    keyParams.passphrase = (__bridge CFTypeRef)(password);
    keyParams.alertTitle = NULL;
    keyParams.alertPrompt = NULL;
    keyParams.accessRef = access;
    // These two values are for import
    keyParams.keyUsage = NULL;

    keyParams.keyAttributes = (__bridge CFArrayRef) @[ @(CSSM_KEYATTR_SENSITIVE) ];;
//    keyParams.keyAttributes = (__bridge CFArrayRef)([NSArray arrayWithObject:(__bridge id)kSecAttrIsPermanent]);

    SecExternalItemType itemType = kSecItemTypeAggregate;
    SecExternalFormat externalFormat = kSecFormatPKCS12;
    int flags = 0;

    SecKeychainRef keychain;
    SecKeychainCopyDefault(&keychain);

    oserr = SecItemImport((__bridge CFDataRef)identityData,
                          NULL, // filename or extension
                          &externalFormat, // See SecExternalFormat for details
                          &itemType, // item type
                          flags, // See SecItemImportExportFlags for details
                          &keyParams,
                          keychain, // Import into a keychain
                          NULL);

//    BOOL                            success;
//    OSStatus                        err;
//    NSArray *                       result;
//    SecExternalFormat               format;
//    SecKeyImportExportParameters    params;
//    CFArrayRef                      importedItems;
//    
//    result = nil;
//    importedItems = NULL;
//    
//    format = kSecFormatPKCS12;
//    memset(&params, 0, sizeof(params));
//    params.passphrase = (__bridge CFTypeRef _Nonnull)(password);
//    params.accessRef = access;
//
//    params.keyAttributes = CSSM_KEYATTR_PERMANENT | CSSM_KEYATTR_SENSITIVE;
//    
//    oserr = SecKeychainItemImport(
//                                (CFDataRef) identityData,     // importedData
//                                NULL,                       // fileNameOrExtension
//                                &format,                    // inputFormat
//                                NULL,                       // itemType
//                                0,                          // flags
//                                &params,                    // keyParams
//                                keychain,             // importKeychain
//                                &importedItems              // outItems
//                                );
//    success = (err == noErr);

    if (access) CFRelease(access);
    if (keychain) CFRelease(keychain);

    if (oserr) {
        DDLogError(@"SecItemImport failed (oserr=%d)\n", oserr);
        return NO;
    }
    return YES;
}


- (NSData*)encryptData:(NSData*)plainData withPublicKeyFromCertificate:(SecCertificateRef)certificate {
    //- (NSData*)encryptData:(NSData*)inputData withPublicKey:(SecKeyRef*)publicKey {
    SecKeyRef publicKeyRef = NULL;
    OSStatus status = SecCertificateCopyPublicKey(certificate, &publicKeyRef);
    if (status != errSecSuccess) {
            DDLogError(@"No public key found in certificate.");
            if (publicKeyRef) CFRelease(publicKeyRef);
            return nil;
    }

    CSSM_RETURN crtn;
    CSSM_DATA		ptext;
    CSSM_DATA		ctext;
    
    ptext.Data = (uint8 *)[plainData bytes];
    ptext.Length = [plainData length];
    ctext.Data = NULL;
    ctext.Length = 0;
    
    const CSSM_ACCESS_CREDENTIALS *creds;
    status = SecKeyGetCredentials(publicKeyRef,
                                  CSSM_ACL_AUTHORIZATION_ENCRYPT,
                                  kSecCredentialTypeWithUI,
                                  &creds);
    
    const CSSM_KEY *pubKey;
    
    CSSM_CSP_HANDLE cspHandle;
    status = SecKeyGetCSPHandle(publicKeyRef, &cspHandle);
    
    status = SecKeyGetCSSMKey(publicKeyRef, &pubKey);
    /*assert(pubKey->KeyHeader.AlgorithmId ==
           CSSM_ALGID_RSA);
    assert(pubKey->KeyHeader.KeyClass ==
           CSSM_KEYCLASS_PUBLIC_KEY);
    assert(pubKey->KeyHeader.KeyUsage ==
           CSSM_KEYUSE_ENCRYPT ||
           pubKey->KeyHeader.KeyUsage ==
           CSSM_KEYUSE_ANY);*/

    CSSM_CC_HANDLE  ccHandle;
    crtn = CSSM_CSP_CreateAsymmetricContext(cspHandle,
                                            CSSM_ALGID_RSA,
                                            creds, pubKey,
                                            CSSM_PADDING_PKCS1, &ccHandle);
    cssmPerror("encrypt context", crtn);
    assert(crtn == CSSM_OK);
    
    CSSM_SIZE       bytesEncrypted;
    CSSM_DATA       remData = {0, NULL};
    crtn = CSSM_EncryptData(ccHandle, &ptext, 1,
                            &ctext, 1, &bytesEncrypted, &remData);
    cssmPerror("encryptdata", crtn);
    assert(crtn == CSSM_OK);
    CSSM_DeleteContext(ccHandle);

    NSData *cipherData = [NSData dataWithBytes:ctext.Data length:ctext.Length];

    if (publicKeyRef) CFRelease(publicKeyRef);
    free(ctext.Data);
    return cipherData;
    //[cipherData encodeBase64ForData];
}

- (NSData*)decryptData:(NSData*)cipherData withPrivateKey:(SecKeyRef)privateKeyRef
{
    OSStatus status = noErr;
            
    const CSSM_ACCESS_CREDENTIALS *creds;
    status = SecKeyGetCredentials(privateKeyRef,
                                       CSSM_ACL_AUTHORIZATION_DECRYPT,
                                       kSecCredentialTypeWithUI,
                                       &creds);
    
    CSSM_CSP_HANDLE cspHandle;
    status = SecKeyGetCSPHandle(privateKeyRef, &cspHandle);
    
    const CSSM_KEY *privKey;
    
    status = SecKeyGetCSSMKey(privateKeyRef, &privKey);
    /*assert(privKey->KeyHeader.AlgorithmId ==
           CSSM_ALGID_RSA);
    assert(privKey->KeyHeader.KeyClass ==
           CSSM_KEYCLASS_PRIVATE_KEY);
    assert(privKey->KeyHeader.KeyUsage ==
           CSSM_KEYUSE_DECRYPT ||
           privKey->KeyHeader.KeyUsage ==
           CSSM_KEYUSE_ANY);*/
    
    CSSM_DATA		ptext;
    CSSM_DATA		ctext;
    CSSM_RETURN		crtn;
    CSSM_SIZE       bytesEncrypted;
    CSSM_DATA       remData = {0, NULL};
    CSSM_CC_HANDLE  ccHandle;
    	   
    ctext.Data = (uint8 *)[cipherData bytes];
    ctext.Length = [cipherData length];
    ptext.Data = NULL;
    ptext.Length = 0;
    
    crtn = CSSM_CSP_CreateAsymmetricContext(cspHandle,
                                            CSSM_ALGID_RSA,
                                            creds, privKey,
                                            CSSM_PADDING_PKCS1, &ccHandle);
    cssmPerror("decrypt context", crtn);
    assert(crtn == CSSM_OK);
    
    crtn = CSSM_DecryptData(ccHandle, &ctext, 1,
                            &ptext, 1, &bytesEncrypted, &remData);
    cssmPerror("decryptdata", crtn);
    assert(crtn == CSSM_OK);
    CSSM_DeleteContext(ccHandle);
    
    if(crtn) {
		cssmPerror("cdsaEncrypt", crtn);
		return nil;
    }
    
    NSData *plainData = [NSData dataWithBytes:ptext.Data length:bytesEncrypted];
	
    if (privateKeyRef) CFRelease(privateKeyRef);
    free(ptext.Data);
    return plainData;
}

// Switch diagnostics for "deprecated" on again
#pragma clang diagnostic pop

- (NSString *) generateSHAHashString:(NSString*)inputString {
    unsigned char hashedChars[32];
    CC_SHA256([inputString UTF8String],
              [inputString lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
              hashedChars);
    NSMutableString* hashedString = [[NSMutableString alloc] init];
    for (int i = 0 ; i < 32 ; ++i) {
        [hashedString appendFormat: @"%02x", hashedChars[i]];
    }
    return hashedString;
}


- (NSString *) generateSHA1HashStringFromData:(NSData *)inputData {
    unsigned char hashedChars[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(inputData.bytes,
              inputData.length,
              hashedChars);
    NSMutableString* hashedString = [[NSMutableString alloc] init];
    for (int i = 0 ; i < CC_SHA1_DIGEST_LENGTH ; ++i) {
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
                           (__bridge id)kSecMatchLimitOne, (__bridge id)kSecMatchLimit,
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
    NSData *keyNSData = (__bridge_transfer NSData *)keyData;
    // Check if we really got data back, as this method sometimes returns success but no proper data(!)
    if (!keyNSData || ![[keyNSData superclass] isKindOfClass:[NSData superclass]]) {
        DDLogError(@"Key with ID could not be retrieved");
        return nil;
    }
    return keyNSData;
}

@end