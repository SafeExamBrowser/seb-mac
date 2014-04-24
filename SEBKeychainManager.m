//
//  SEBKeychainManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07.11.12.
//  Copyright (c) 2010-2014 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2014 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "SEBKeychainManager.h"
#import "Constants.h"

@implementation SEBKeychainManager

// We ignore "deprecated" warnings for CSSM methods, since Apple doesn't provide any replacement
// for asymetric public key cryptography as for OS X 10.8
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (NSArray*)getIdentitiesAndNames:(NSArray **)names {
    SecKeychainRef keychain;
    OSStatus error;
    error = SecKeychainCopyDefault(&keychain);
    if (error) {
        //certReqDbg("GetResult: SecKeychainCopyDefault failure");
        /* oh well, there's nothing we can do about this */
    }
    
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           kSecClassIdentity, kSecClass,
                           [NSArray arrayWithObject:(__bridge id)keychain], kSecMatchSearchList,
                           //kCFBooleanTrue, kSecAttrCanEncrypt,
                           //kCFBooleanTrue, kSecAttrCanDecrypt,
                           kCFBooleanTrue, kSecReturnRef,
                           kSecMatchLimitAll, kSecMatchLimit,
                           nil];
    //NSArray *items = nil;
    CFTypeRef items = NULL;
    OSStatus status = SecItemCopyMatching((__bridge_retained CFDictionaryRef)query, (CFTypeRef *)&items);
    if (status != errSecSuccess) {
            //LKKCReportError(status, @"Can't search keychain");
            return nil;
    }
    NSMutableArray *identities = [NSMutableArray arrayWithArray:(__bridge  NSArray*)(items)];
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
        SecIdentityCopyCertificate(identityRef, &certificateRef);
        SecIdentityCopyPrivateKey(identityRef, &privateKeyRef);
        /*SecPolicyRef policyRef = SecPolicyCreateBasicX509();
        //status = SecPolicySetValue(policyRef, )
        SecTrustRef trustRef;
        status = SecTrustCreateWithCertificates((CFArrayRef)certificateRef, policyRef, &trustRef);
        SecTrustResultType trustResult;
        if (status == noErr) {
            status = SecTrustEvaluate(trustRef, &trustResult);
        }*/
        const CSSM_KEY *pubKey;
        status = SecCertificateCopyPublicKey(certificateRef, &publicKeyRef);
        status = SecKeyGetCSSMKey(publicKeyRef, &pubKey);
        const CSSM_KEY *privKey;
        status = SecKeyGetCSSMKey(privateKeyRef, &privKey);
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
            SecCertificateCopyCommonName(certificateRef, &commonName);
            SecCertificateCopyEmailAddresses(certificateRef, &emailAddressesRef);
            identityName = [NSString stringWithFormat:@"%@%@",
                            (__bridge NSString *)commonName ?
                            [NSString stringWithFormat:@"%@ ",(__bridge NSString *)commonName] :
                            @"" ,
                            CFArrayGetCount(emailAddressesRef) ?
                            (__bridge NSString *)CFArrayGetValueAtIndex(emailAddressesRef, 0) :
                            @""];
            if ([identitiesNames containsObject:identityName]) {
                //get public key hash from selected identity's certificate
                NSData* publicKeyHash = [self getPublicKeyHashFromCertificate:certificateRef];
                unsigned char hashedChars[20];
                [publicKeyHash getBytes:hashedChars length:20];
                NSMutableString* hashedString = [[NSMutableString alloc] init];
                for (int i = 0 ; i < 20 ; ++i) {
                    [hashedString appendFormat: @"%02x", hashedChars[i]];
                }
                [identitiesNames addObject:[NSString stringWithFormat:@"%@ %@",identityName, hashedString]];
            } else {
                [identitiesNames addObject:identityName];
            }
            
#ifdef DEBUG
            NSLog(@"Common name: %@ %@", (__bridge NSString *)commonName ? (__bridge NSString *)commonName : @"" , CFArrayGetCount(emailAddressesRef) ? (__bridge NSString *)CFArrayGetValueAtIndex(emailAddressesRef, 0) : @"");
            NSLog(@"Public key can be used for encryption, private key can be used for decryption");
#endif
            if (commonName) CFRelease(commonName);
            if (emailAddressesRef) CFRelease(emailAddressesRef);
        } else {
            [identities removeObjectAtIndex:i];
            i--;
            count--;
        }

        if (certificateRef) CFRelease(certificateRef);
        if (privateKeyRef) CFRelease(privateKeyRef);
        if (publicKeyRef) CFRelease(publicKeyRef);
    }
    NSArray *foundIdentities;
    foundIdentities = [NSArray arrayWithArray:identities];
    // return array of identity names
    if (names) {
        *names = [NSArray arrayWithArray:identitiesNames];
    }
    return foundIdentities; // items contains all SecIdentityRefs in keychain
}


- (NSArray*)getCertificatesAndNames:(NSArray **)names {
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
    NSMutableArray *certificates = [NSMutableArray arrayWithArray:(__bridge  NSArray*)(items)];
    NSMutableArray *certificatesNames = [NSMutableArray arrayWithCapacity:[certificates count]];
    
    CFStringRef commonName;
    CFArrayRef emailAddressesRef;
    //NSDictionary *values;
    //NSDictionary *value;
    NSString *certificateName;
    int i, count = [certificates count];
    for (i=0; i<count; i++) {
        SecCertificateRef certificateRef = (__bridge SecCertificateRef)[certificates objectAtIndex:i];
        SecCertificateCopyCommonName(certificateRef, &commonName);
        SecCertificateCopyEmailAddresses(certificateRef, &emailAddressesRef);
        NSDictionary *values = (NSDictionary *)CFBridgingRelease(SecCertificateCopyValues (certificateRef, (__bridge CFArrayRef)[NSArray arrayWithObject:(__bridge id)(kSecOIDExtendedKeyUsage)], NULL));
        // Keep only certificates which have an extended key usage server authentification
        if ([values count]) {
            NSDictionary *value = [values objectForKey:(__bridge id)(kSecOIDExtendedKeyUsage)];
            NSArray *extendedKeyUsages = [value objectForKey:(__bridge id)(kSecPropertyKeyValue)];
            if ([extendedKeyUsages containsObject:[NSData dataWithBytes:keyUsageServerAuthentication length:8]]) {
                certificateName = [NSString stringWithFormat:@"%@",
                                   (__bridge NSString *)commonName ?
                                   //There is a commonName: just take that as a name
                                   [NSString stringWithFormat:@"%@ ",(__bridge NSString *)commonName] :
                                   //there is no common name: take the e-mail address (if it exists)
                                   CFArrayGetCount(emailAddressesRef) ?
                                   (__bridge NSString *)CFArrayGetValueAtIndex(emailAddressesRef, 0) :
                                   @""];
                if ([certificateName isEqualToString:@""] || [certificatesNames containsObject:certificateName]) {
                    //get public key hash from selected identity's certificate
                    NSData* publicKeyHash = [self getPublicKeyHashFromCertificate:certificateRef];
                    unsigned char hashedChars[20];
                    [publicKeyHash getBytes:hashedChars length:20];
                    NSMutableString* hashedString = [[NSMutableString alloc] init];
                    for (int i = 0 ; i < 20 ; ++i) {
                        [hashedString appendFormat: @"%02x", hashedChars[i]];
                    }
                    [certificatesNames addObject:[NSString stringWithFormat:@"%@ %@",certificateName, hashedString]];
                } else {
                    [certificatesNames addObject:certificateName];
                }
                
#ifdef DEBUG
                NSLog(@"Common name: %@ %@", (__bridge NSString *)commonName ? (__bridge NSString *)commonName : @"" , CFArrayGetCount(emailAddressesRef) ? (__bridge NSString *)CFArrayGetValueAtIndex(emailAddressesRef, 0) : @"");
#endif
            }
        } else {
            [certificates removeObjectAtIndex:i];
            i--;
            count--;
        }
        if (commonName) CFRelease(commonName);
        if (emailAddressesRef) CFRelease(emailAddressesRef);
        
        if (certificateRef) CFRelease(certificateRef);
    }
    NSArray *foundCertificates;
    foundCertificates = [NSArray arrayWithArray:certificates];
    // return array of identity names
    if (names) {
        *names = [NSArray arrayWithArray:certificatesNames];
    }
    return foundCertificates; // items contains all SecIdentityRefs in keychain
    //return (__bridge  NSArray*)(items); // items contains all SecCertificateRefs in keychain
    
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
        BOOL result;
        
        if (retrievedAtts->count == 1 &&
            retrievedAtts->attr[0].tag == kSecPublicKeyHashItemAttr) {
            //retrievedAtts->attr[0].length == [subjectKeyIdentifier length] &&
            //memcmp(retrievedAtts->attr[0].data, [subjectKeyIdentifier bytes], retrievedAtts->attr[0].length);
            subjectKeyIdentifier = [NSData dataWithBytes:retrievedAtts->attr[0].data length:retrievedAtts->attr[0].length];
            result = YES;
        } else {
            result = NO;
        }
        
        SecKeychainItemFreeAttributesAndData(retrievedAtts, NULL);
        
        return subjectKeyIdentifier;
        
    } else if (err == errKCNotAvailable) {
        NSLog(@"Keychain Manager was not loaded.");
    }
    return nil;
}


- (SecKeyRef)getPrivateKeyFromPublicKeyHash:(NSData*)publicKeyHash {
    SecKeychainRef keychain;
    OSStatus error;
    error = SecKeychainCopyDefault(&keychain);
    if (error) {
        //certReqDbg("GetResult: SecKeychainCopyDefault failure");
        /* oh well, there's nothing we can do about this */
    }
    
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           kSecClassCertificate, kSecClass,
                           (CFDataRef)publicKeyHash, kSecAttrPublicKeyHash,
                           [NSArray arrayWithObject:(__bridge id)keychain], kSecMatchSearchList,
                           kCFBooleanTrue, kSecReturnRef,
                           nil];
    //NSArray *items = nil;
    SecCertificateRef certificateRef = NULL;
    OSStatus status = SecItemCopyMatching((__bridge_retained CFDictionaryRef)query, (CFTypeRef *)&certificateRef);
    if (status != errSecSuccess) {
        return nil;
    }
    //NSMutableArray *identities = [NSMutableArray arrayWithArray:(__bridge  NSArray*)(items)];
    
    //SecKeyRef publicKeyRef;
    SecKeyRef privateKeyRef = nil;
    SecIdentityRef identityRef = [self createIdentityWithCertificate:certificateRef];
    if (status != errSecSuccess) {
        return nil;
    }
    status = SecIdentityCopyPrivateKey(identityRef, &privateKeyRef);
    return privateKeyRef;
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


- (SecIdentityRef)createIdentityWithCertificate:(SecCertificateRef)certificate {
    SecIdentityRef identityRef;
    OSStatus status = SecIdentityCreateWithCertificate(NULL, certificate, &identityRef);
    if (status) {
        if (status == errSecItemNotFound) {
            NSLog(@"No associated private key found for certificate.");
            return nil;
        }
    }
    return identityRef; // public key contained in certificate
}


- (SecKeyRef)privateKeyFromIdentity:(SecIdentityRef*)identityRef {
    SecKeyRef privateKeyRef = NULL;
    OSStatus status = SecIdentityCopyPrivateKey (*identityRef, &privateKeyRef);
    if (status != errSecSuccess) {
        NSLog(@"No associated private key found for identity.");
        return nil;
    }
    return privateKeyRef;
}


- (SecCertificateRef)getCertificateFromIdentity:(SecIdentityRef)identityRef {
    SecCertificateRef certificateRef;
    SecIdentityCopyCertificate(identityRef, &certificateRef);
    return certificateRef;
}


- (NSData*) getDataForCertificate:(SecCertificateRef)certificate {
    
    SecItemImportExportKeyParameters keyParams;
    
    keyParams.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
    keyParams.flags = 0;
    keyParams.passphrase = NULL;
    keyParams.alertTitle = NULL;
    keyParams.alertPrompt = NULL;
    keyParams.accessRef = NULL;
    // These two values are for import
    keyParams.keyUsage = NULL;
    keyParams.keyAttributes = NULL;
    
    CFDataRef exportedData = NULL;
    
    OSStatus success = SecItemExport (
                                      certificate,
                                      kSecFormatX509Cert,
                                      0,
                                      &keyParams,
                                      &exportedData
                                      );
    
    if (success == errSecSuccess) return (NSData*)CFBridgingRelease(exportedData); else return nil;

    
    
    //    return (NSData*)CFBridgingRelease(SecCertificateCopyData (certificate));
}


- (BOOL) importCertificateFromData:(NSData*)certificateData {

    SecItemImportExportKeyParameters keyParams;
    
    keyParams.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
    keyParams.flags = 0;
    keyParams.passphrase = NULL;
    keyParams.alertTitle = NULL;
    keyParams.alertPrompt = NULL;
    keyParams.accessRef = NULL;
    // These two values are for import
    keyParams.keyUsage = NULL;
    keyParams.keyAttributes = NULL;
    
    SecExternalItemType itemType = kSecItemTypeCertificate;
    SecExternalFormat externalFormat = kSecFormatX509Cert;
    int flags = 0;
    
    SecKeychainRef keychain;
    SecKeychainCopyDefault(&keychain);
    
    OSStatus oserr = SecItemImport((__bridge CFDataRef)certificateData,
                                   NULL, // filename or extension
                                   &externalFormat, // See SecExternalFormat for details
                                   &itemType, // item type
                                   flags, // See SecItemImportExportFlags for details
                                   &keyParams,
                                   keychain, // Don't import into a keychain
                                   NULL);
    if (oserr) {
#ifdef DEBUG
        fprintf(stderr, "SecItemImport failed (oserr=%d)\n", oserr);
#endif
        return NO;
    }
    return YES;
}


- (NSData*) getDataForIdentity:(SecIdentityRef)identity {
    
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

    SecExternalItemType itemType = kSecItemTypeAggregate;
    SecExternalFormat externalFormat = kSecFormatPKCS12;
    int flags = 0;

    SecKeychainRef keychain;
    SecKeychainCopyDefault(&keychain);

    OSStatus oserr = SecItemImport((__bridge CFDataRef)identityData,
                          NULL, // filename or extension
                          &externalFormat, // See SecExternalFormat for details
                          &itemType, // item type
                          flags, // See SecItemImportExportFlags for details
                          &keyParams,
                          keychain, // Don't import into a keychain
                          NULL);
    if (oserr) {
#ifdef DEBUG
        fprintf(stderr, "SecItemImport failed (oserr=%d)\n", oserr);
#endif
        return NO;
    }
    return YES;
}


- (NSData*) encryptData:(NSData*)plainData withPublicKeyFromCertificate:(SecCertificateRef)certificate {
    //- (NSData*)encryptData:(NSData*)inputData withPublicKey:(SecKeyRef*)publicKey {
    SecKeyRef publicKeyRef = NULL;
    OSStatus status = SecCertificateCopyPublicKey(certificate, &publicKeyRef);
    if (status != errSecSuccess) {
            NSLog(@"No public key found in certificate.");
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

    CFRelease(publicKeyRef);
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
    
#ifdef DEBUG
    fprintf(stderr, "DecryptData output %ld bytes\n",
            ptext.Length);
    fprintf(stderr, "[%s]\n", ptext.Data);
#endif
    if(crtn) {
		cssmPerror("cdsaEncrypt", crtn);
		return nil;
    }
    
    NSData *plainData = [NSData dataWithBytes:ptext.Data length:bytesEncrypted];
	
    CFRelease(privateKeyRef);
    free(ptext.Data);
    return plainData;
}

// Switch diagnostics for "deprecated" on again
#pragma clang diagnostic pop

- (NSString*) generateSHAHashString:(NSString*)inputString {
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

@end