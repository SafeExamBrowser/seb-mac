//
//  SEBKeychainManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07.11.12.
//
//


#import "SEBKeychainManager.h"

@implementation SEBKeychainManager

- (NSArray*)getIdentities {
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
    
    int i, count = [identities count];
    for (i=0; i<count; i++) {
        SecIdentityRef identityRef = (__bridge SecIdentityRef)[identities objectAtIndex:i];
        CFStringRef commonName;
        SecCertificateRef certificateRef;
        SecKeyRef publicKeyRef;
        SecKeyRef privateKeyRef;
        SecIdentityCopyCertificate(identityRef, &certificateRef);
        SecIdentityCopyPrivateKey(identityRef, &privateKeyRef);
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
            CFArrayRef *emailAddresses;
            SecCertificateCopyEmailAddresses(certificateRef, emailAddresses);
#ifdef DEBUG
            NSLog(@"Common name: %@ %@", (__bridge NSString *)commonName ? (__bridge NSString *)commonName : @"" , CFArrayGetCount(*emailAddresses) ? (__bridge NSString *)CFArrayGetValueAtIndex(*emailAddresses, 0) : @"");
            NSLog(@"Public key can be used for encryption, private key can be used for decryption");
#endif
        } else {
            [identities removeObjectAtIndex:i];
            i--;
            count--;
        }
    }
    NSArray *foundIdentities;
    foundIdentities = [NSArray arrayWithArray:identities];
    return foundIdentities; // items contains all SecIdentityRefs in keychain
}


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


- (SecKeyRef)privateKeyFromIdentity:(SecIdentityRef*)identityRef {
    SecKeyRef privateKeyRef = NULL;
    OSStatus status = SecIdentityCopyPrivateKey (*identityRef, &privateKeyRef);
    if (status != errSecSuccess) {
        NSLog(@"No associated private key found for identity.");
        return nil;
    }
    return privateKeyRef;
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
    assert(pubKey->KeyHeader.AlgorithmId ==
           CSSM_ALGID_RSA);
    assert(pubKey->KeyHeader.KeyClass ==
           CSSM_KEYCLASS_PUBLIC_KEY);
    /*assert(pubKey->KeyHeader.KeyUsage ==
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
            
    CSSM_CSP_HANDLE cspHandle;
    status = SecKeyGetCSPHandle(privateKeyRef, &cspHandle);
    
    const CSSM_ACCESS_CREDENTIALS *creds;
    status = SecKeyGetCredentials(privateKeyRef,
                                       CSSM_ACL_AUTHORIZATION_DECRYPT,
                                       kSecCredentialTypeWithUI,
                                       &creds);
    
    const CSSM_KEY *privKey;
    
    status = SecKeyGetCSSMKey(privateKeyRef, &privKey);
    assert(privKey->KeyHeader.AlgorithmId ==
           CSSM_ALGID_RSA);
    assert(privKey->KeyHeader.KeyClass ==
           CSSM_KEYCLASS_PRIVATE_KEY);
    /*assert(privKey->KeyHeader.KeyUsage ==
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
    
    fprintf(stderr, "DecryptData output %ld bytes\n",
            ptext.Length);
    fprintf(stderr, "[%s]\n", ptext.Data);
    if(crtn) {
		cssmPerror("cdsaEncrypt", crtn);
		return nil;
    }
    
    NSData *plainData = [NSData dataWithBytes:ptext.Data length:bytesEncrypted];
	
    CFRelease(privateKeyRef);
    free(ptext.Data);
    return plainData;
}

@end