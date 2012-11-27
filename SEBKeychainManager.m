//
//  SEBKeychainManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07.11.12.
//
//

/*!
 @function SecKeyEncrypt
 @abstract Encrypt a block of plaintext.
 @param key Public key with which to encrypt the data.
 @param padding See Padding Types above, typically kSecPaddingPKCS1.
 @param plainText The data to encrypt.
 @param plainTextLen Length of plainText in bytes, this must be less
 or equal to the value returned by SecKeyGetBlockSize().
 @param cipherText Pointer to the output buffer.
 @param cipherTextLen On input, specifies how much space is available at
 cipherText; on return, it is the actual number of cipherText bytes written.
 @result A result code. See "Security Error Codes" (SecBase.h).
 @discussion If the padding argument is kSecPaddingPKCS1, PKCS1 padding
 will be performed prior to encryption. If this argument is kSecPaddingNone,
 the incoming data will be encrypted "as is".
 
 When PKCS1 padding is performed, the maximum length of data that can
 be encrypted is the value returned by SecKeyGetBlockSize() - 11.
 
 When memory usage is a critical issue, note that the input buffer
 (plainText) can be the same as the output buffer (cipherText).
 */
OSStatus SecKeyEncrypt(
                       SecKeyRef           key,
                       SecPadding          padding,
                       const uint8_t		*plainText,
                       size_t              plainTextLen,
                       uint8_t             *cipherText,
                       size_t              *cipherTextLen)
;


/*!
 @function SecKeyDecrypt
 @abstract Decrypt a block of ciphertext.
 @param key Private key with which to decrypt the data.
 @param padding See Padding Types above, typically kSecPaddingPKCS1.
 @param cipherText The data to decrypt.
 @param cipherTextLen Length of cipherText in bytes, this must be less
 or equal to the value returned by SecKeyGetBlockSize().
 @param plainText Pointer to the output buffer.
 @param plainTextLen On input, specifies how much space is available at
 plainText; on return, it is the actual number of plainText bytes written.
 @result A result code. See "Security Error Codes" (SecBase.h).
 @discussion If the padding argument is kSecPaddingPKCS1, PKCS1 padding
 will be removed after decryption. If this argument is kSecPaddingNone,
 the decrypted data will be returned "as is".
 
 When memory usage is a critical issue, note that the input buffer
 (plainText) can be the same as the output buffer (cipherText).
 */
OSStatus SecKeyDecrypt(
                       SecKeyRef           key,                /* Private key */
                       SecPadding          padding,			/* kSecPaddingNone,
                                                             kSecPaddingPKCS1,
                                                             kSecPaddingOAEP */
                       const uint8_t       *cipherText,
                       size_t              cipherTextLen,		/* length of cipherText */
                       uint8_t             *plainText,
                       size_t              *plainTextLen)		/* IN/OUT */
;

/*!
 @function SecKeyGetBlockSize
 @abstract Decrypt a block of ciphertext.
 @param key The key for which the block length is requested.
 @result The block length of the key in bytes.
 @discussion If for example key is an RSA key the value returned by
 this function is the size of the modulus.
 */
//size_t SecKeyGetBlockSize(SecKeyRef key);


// CSSM

#define DEFAULT_KEY_SIZE_BITS		2048

typedef struct {
	CSSM_ALGORITHMS		keyAlg;
	uint32				keySizeInBits;
	CSSM_CSP_HANDLE		cspHandle;
	char				*keyFileName;
	char				*plainFileName;
	char				*sigFileName;
	char				*cipherFileName;
} opParams;


#include <Security/cssmapple.h>
#include <Security/cssm.h>

#import "SEBKeychainManager.h"

/*#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <strings.h>
*/
#import "libCdsaCrypt.h"

@implementation SEBKeychainManager

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


- (NSData*)encryptData:(NSData*)plainData withPublicKeyFromCertificate:(SecCertificateRef)certificate {
    //- (NSData*)encryptData:(NSData*)inputData withPublicKey:(SecKeyRef*)publicKey {
    SecKeyRef publicKeyRef = NULL;
    OSStatus status = SecCertificateCopyPublicKey(certificate, &publicKeyRef);
    if (status != errSecSuccess) {
            NSLog(@"No public key found in certificate.");
            if (publicKeyRef) CFRelease(publicKeyRef);
            return nil;
    }

    SecKeychainRef keychainRef = NULL;
    
    //status = SecKeychainItemCopyKeychain((SecKeychainItemRef)publicKeyRef,&keychainRef);
    status = SecKeychainCopyDefault(&keychainRef);

    //
    // The remaining objects' lifetimes are controlled by privKey and
    // keychain above, and don't need to be released on their own.
    
    CSSM_CSP_HANDLE cspHandle;
    status = SecKeychainGetCSPHandle(keychainRef, &cspHandle);
    

    CSSM_RETURN cssm_status;
    //CSSM_DATA		ptext;
    CSSM_DATA		ctext;
    
    const char *plaintext = "ABCDEABCDEABCDEABCDE";
    
    CSSM_DATA ptext = { strlen(plaintext),
        (uint8*)plaintext };

    //ptext.Data = (uint8 *)[plainData bytes];
    //ptext.Length = [plainData length];
    ctext.Data = NULL;
    ctext.Length = 0;
    
    const CSSM_KEY *pubKey;
    //CSSM_KEY_PTR privkey;
    
    status = SecKeyGetCSSMKey(publicKeyRef, &pubKey);
    //status = SecKeyGetCSSMKey(publicKeyRef, (const CSSM_KEY**)&pubKey);

    cssm_status = cspStagedEncrypt(cspHandle,
                                 CSSM_ALGID_RSA,					// CSSM_ALGID_FEED, etc.
                                 0,						// CSSM_ALGMODE_CBC, etc. - only for symmetric algs
                                 CSSM_PADDING_PKCS1,				// CSSM_PADDING_PKCS1, etc.
                                 pubKey,				// public or session key
                                 NULL,				// for CSSM_ALGID_FEED, CSSM_ALGID_FEECFILE only
                                 0,		// 0 means skip this attribute
                                 0,				// ditto
                                 0,						// ditto
                                 NULL,				// init vector, optional
                                 &ptext,
                                 &ctext,				// RETURNED, we malloc
                                 false);				// false:single update, true:multi updates

    
    /*/ Convert input data into a buffer
    const void *bytes = [inputData bytes];
    int length = [inputData length];
    uint8_t *plainText = malloc(length);
    memcpy(plainText, bytes, length);

    // Allocate a buffer to hold the cipher text
    size_t cipherBufferSize;
    uint8_t *cipherBuffer;
    cipherBufferSize = SecKeyGetBlockSize(publicKey);
    cipherBuffer = malloc(cipherBufferSize);

    // Encrypt using the public key
    status = SecKeyEncrypt(publicKey,
                           kSecPaddingPKCS1,
                           plainText,
                           length,
                           cipherBuffer,
                           &cipherBufferSize
                           );
     */
    NSData *cipherData = [NSData dataWithBytes:ctext.Data length:ctext.Length];
    //crtn = cdsaDecrypt(cspHand,privKeyPtr,&ctext,&ptext);

    //CFRelease(publicKey);
    free(ptext.Data);
    //free(ctext.Data);
    return cipherData;
    //[cipherData encodeBase64ForData];

}

- (NSData*)decryptData:(NSData*)cipherData withPrivateKey:(SecKeyRef)privateKeyRef
{
    OSStatus status = noErr;
        
    //SecKeyRef privKey = NULL;
    SecKeychainRef keychain = NULL;
    
    //status = SecIdentityCopyPrivateKey(ident, &privKey);
    status = SecKeychainItemCopyKeychain((SecKeychainItemRef)privateKeyRef,
                                              &keychain);
    
    //
    // The remaining objects' lifetimes are controlled by privKey and
    // keychain above, and don't need to be released on their own.
    
    CSSM_CSP_HANDLE cspHandle;
    status = SecKeychainGetCSPHandle(keychain, &cspHandle);
    
    const CSSM_ACCESS_CREDENTIALS *creds;
    status = SecKeyGetCredentials(privateKeyRef,
                                       CSSM_ACL_AUTHORIZATION_DECRYPT,
                                       kSecCredentialTypeWithUI,
                                       &creds);
    
    //const CSSM_KEY *key;
    CSSM_KEY_PTR privkey;
    
    //status = SecKeyGetCSSMKey(privateKeyRef, &key);
    status = SecKeyGetCSSMKey(privateKeyRef, (const CSSM_KEY**)&privkey);
    assert(privkey->KeyHeader.AlgorithmId ==
           CSSM_ALGID_RSA);
    assert(privkey->KeyHeader.KeyClass ==
           CSSM_KEYCLASS_PRIVATE_KEY);

    /*/ Convert input cipher data into a buffer
    const void *bytes = [cipherData bytes];
    int cipherBufferSize = [cipherData length];
    CSSM_DATA *cipherBuffer = malloc(cipherBufferSize);
    memcpy(cipherBuffer, bytes, cipherBufferSize);
    
    // Allocate a buffer to hold the plain text
    size_t plainBufferSize;
    uint8_t *plainBuffer;
    plainBufferSize = SecKeyGetBlockSize(privateKeyRef);
    plainBuffer = malloc(plainBufferSize);*/

    
    //CSSM_KEY 		pubKey;
    CSSM_DATA		ptext;
    CSSM_DATA		ctext;
    CSSM_RETURN		crtn;
    CSSM_SIZE       bytesEncrypted;
    CSSM_DATA       remData = {0, NULL};
    //CSSM_KEY_SIZE 		keySize;
    //opParams		op;

    //CSSM_CC_HANDLE  ccHandle = 0;
    CSSM_CC_HANDLE  ccHandle;
    
    //memset(&pubKey, 0, sizeof(CSSM_KEY));
    
    //op.keySizeInBits = DEFAULT_KEY_SIZE_BITS;
    //op.keyAlg = CSSM_ALGID_RSA;
    
    //crtn = cdsaCspAttach(&op.cspHandle);
    /*if(crtn) {
		cssmPerror("Attach to CSP", crtn);
		return nil;
    }*/
	   
    ctext.Data = (uint8 *)[cipherData bytes];
    ctext.Length = [cipherData length];
    ptext.Data = NULL;
    ptext.Length = 0;
    
    crtn = CSSM_CSP_CreateAsymmetricContext(cspHandle,
                                            CSSM_ALGID_RSA,
                                            creds, privkey,
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
    
    //NSString *plainText = [NSString stringWithCString: ptext.Data length: ptext.Length];
    NSData *plainData = [NSData dataWithBytes:ptext.Data length:ptext.Length];
	
    free(ptext.Data);				// allocd by readFile
    //	free(ctext.Data);				// allocd by CSP
    return plainData;

    
/*
    NSData *plainData = [NSData dataWithBytes:plainBuffer length:plainBufferSize];

    //if(privateKeyRef) CFRelease(privateKeyRef);
    free(cipherBuffer);
    free(plainBuffer);
    
    return plainData;*/
}

/*
 - (NSData*)decryptData:(NSData*)cipherData withPrivateKey:(SecKeyRef)privateKeyRef
 {
 OSStatus status = noErr;
 
 SecKeyRef privKey = NULL;
 SecKeychainRef keychain = NULL;
 
 //status = SecIdentityCopyPrivateKey(ident, &privKey);
 status = SecKeychainItemCopyKeychain((SecKeychainItemRef)privateKeyRef,
 &keychain);
 
 //
 // The remaining objects' lifetimes are controlled by privKey and
 // keychain above, and don't need to be released on their own.
 
 CSSM_CSP_HANDLE csp;
 status = SecKeychainGetCSPHandle(keychain, &csp);
 
 const CSSM_ACCESS_CREDENTIALS *creds;
 status = SecKeyGetCredentials(privateKeyRef,
 CSSM_ACL_AUTHORIZATION_DECRYPT,
 kSecCredentialTypeWithUI,
 &creds);
 
 const CSSM_KEY *key;
 status = SecKeyGetCSSMKey(privateKeyRef, &key);
 
 // Convert input cipher data into a buffer
 const void *bytes = [cipherData bytes];
 int cipherBufferSize = [cipherData length];
 CSSM_DATA *cipherBuffer = malloc(cipherBufferSize);
 memcpy(cipherBuffer, bytes, cipherBufferSize);
 
 // Allocate a buffer to hold the plain text
 size_t plainBufferSize;
 uint8_t *plainBuffer;
 plainBufferSize = SecKeyGetBlockSize(privateKeyRef);
 plainBuffer = malloc(plainBufferSize);
 
 
 CSSM_KEY 		pubKey;
 CSSM_DATA		ptext;
 CSSM_DATA		ctext;
 CSSM_RETURN		crtn;
 CSSM_KEY_SIZE 		keySize;
 opParams			op;
 CSSM_CC_HANDLE  ccHandle = 0;
 
 memset(&pubKey, 0, sizeof(CSSM_KEY));
 pubKey = *(CSSM_KEY*)key;
 
 op.keySizeInBits = DEFAULT_KEY_SIZE_BITS;
 op.keyAlg = CSSM_ALGID_RSA;
 
 crtn = cdsaCspAttach(&op.cspHandle);
 if(crtn) {
 cssmPerror("Attach to CSP", crtn);
 return nil;
 }
 
 crtn = CSSM_QueryKeySizeInBits(op.cspHandle, ccHandle, &pubKey, &keySize);
 if(crtn) {
 cssmPerror("CSSM_QueryKeySizeInBits", crtn);
 return nil;
 }
 
 ctext.Data = (uint8 *)[cipherData bytes];
 ctext.Length = [cipherData length];
 ptext.Data = NULL;
 ptext.Length = 0;
 
 crtn = cdsaDecrypt(op.cspHandle,
 &pubKey,
 &ctext,
 &ptext);
 if(crtn) {
 cssmPerror("cdsaEncrypt", crtn);
 return nil;
 }
 
 //NSString *plainText = [NSString stringWithCString: ptext.Data length: ptext.Length];
 NSData *plainData = [NSData dataWithBytes:ptext.Data length:ptext.Length];
 
 free(ptext.Data);				// allocd by readFile
 //	free(ctext.Data);				// allocd by CSP
 return plainData;


// Convert input cipher data into a buffer
const void *bytes = [cipherData bytes];
int cipherBufferSize = [cipherData length];
uint8_t *cipherBuffer = malloc(cipherBufferSize);
memcpy(cipherBuffer, bytes, cipherBufferSize);

// Allocate a buffer to hold the plain text
size_t plainBufferSize;
uint8_t *plainBuffer;
plainBufferSize = SecKeyGetBlockSize(privateKeyRef);
plainBuffer = malloc(plainBufferSize);

 if (plainBufferSize < cipherBufferSize) {
 // Ordinarily, you would split the data up into blocks
 // equal to plainBufferSize, with the last block being
 // shorter. For simplicity, this example assumes that
 // the data is short enough to fit.
 printf("Could not decrypt.  Packet too large.\n");
 return nil;
 }
 
 //  Error handling
 
 status = SecKeyDecrypt(
 privateKeyRef,
 kSecPaddingPKCS1,
 cipherBuffer,
 cipherBufferSize,
 plainBuffer,
 &plainBufferSize
 );                              // 3
 
 //  Error handling
 if (status != errSecSuccess) {
 NSLog(@"Decryption failed.");
 return nil;
 }

crtn = CSSM_CSP_CreateAsymmetricContext(cspHandle,
                                        CSSM_ALGID_RSA,
                                        &creds, privkey,
                                        CSSM_PADDING_PKCS1, &ccHandle);
cssmPerror("decrypt context", crtn);
assert(crtn == CSSM_OK);

crtn = CSSM_DecryptData(ccHandle, &cipherText, 1,
                        &decipherText, 1, &bytesEncrypted, &remData);
cssmPerror("decryptdata", crtn);
assert(crtn == CSSM_OK);
CSSM_DeleteContext(ccHandle);

fprintf(stderr, "DecryptData output %ld bytes\n",
        decipherText.Length);
fprintf(stderr, "[%s]\n", decipherText.Data);


NSData *plainData = [NSData dataWithBytes:plainBuffer length:plainBufferSize];

//if(privateKeyRef) CFRelease(privateKeyRef);
free(cipherBuffer);
free(plainBuffer);

return plainData;
}


*/

#define InfoLog(x) fprintf(stderr, "%s\n", (x))
#define ErrLog(x) fprintf(stderr, "%s\n", (x))

/*
typedef void *(*MallocFunc)(uint32, void*);
typedef void (*FreeFunc)(void*, void*);
typedef void *(*ReallocFunc)(void*, uint32, void*);
typedef void *(*CallocFunc)(uint32, uint32, void*);
static CSSM_API_MEMORY_FUNCS memFuncs = {
    (MallocFunc)malloc,
    (FreeFunc)free,
    (ReallocFunc)realloc,
    (CallocFunc)calloc,
    NULL
};
*/
- (int)test {
    OSStatus status;
    CSSM_RETURN crtn;
    
    CSSM_CSP_HANDLE cspHandle;
    CSSM_KEY_PTR privkey, pubkey;
    CSSM_KEY key;
    
#if 1 // retrieve certificate from keychain
    
    SecCertificateRef certRef;
    SecKeyRef keyRef;
    
    SecKeychainRef keychain;
    status = SecKeychainCopyDefault(&keychain);
    if (status != noErr) {
        ErrLog( "Cannot open default keychain" );
        assert(0);
        return 0;
    }
    
    SecIdentitySearchRef searchRef = NULL;
    status = SecIdentitySearchCreate(keychain,
                                       CSSM_KEYUSE_ANY, &searchRef);
    if (status != noErr) {
        ErrLog( "Cannot search default keychain" );
        assert(0);
        return 0;
    }
    
    while (1) {
        
        SecIdentityRef identityRef;
        status = SecIdentitySearchCopyNext(searchRef,
                                             &identityRef);
        if (status == errSecItemNotFound)
            break;
        if (status != noErr) {
            assert(0);
            continue;
        }
        
        status = SecIdentityCopyCertificate(identityRef,
                                              &certRef);
        if (status != noErr) {
            ErrLog( "Error obtaining certificate reference" );
            CFRelease(identityRef);
            assert(0);
            continue;
        }
        
        status = SecIdentityCopyPrivateKey(identityRef,
                                             &keyRef);
        CFRelease(identityRef);
        if (status != noErr) {
            ErrLog( "Error obtaining key reference" );
            assert(0);
            continue;
        }
        
        status = SecKeychainGetCSPHandle(keychain,
                                           &cspHandle);
        assert(status == noErr);
        
        // this is what libCDSA does, but it seems bogus
        pubkey = &key;
        CSSM_DATA_PTR certData = &pubkey->KeyData;
        status = SecCertificateGetData(certRef, certData);
        assert(status == noErr);
        CSSM_KEYHEADER_PTR hdr = &pubkey->KeyHeader;
        hdr->HeaderVersion = CSSM_KEYHEADER_VERSION;
        hdr->BlobType = CSSM_KEYBLOB_RAW;
        hdr->Format = CSSM_KEYBLOB_RAW_FORMAT_PKCS1;
        hdr->AlgorithmId = CSSM_ALGID_RSA;
        hdr->KeyClass = CSSM_KEYCLASS_PUBLIC_KEY;
        hdr->KeyUsage = CSSM_KEYUSE_ANY;
        hdr->KeyAttr = CSSM_KEYATTR_EXTRACTABLE;
        hdr->LogicalKeySizeInBits = 2048;
        
#if 0
        // this is what the mailing list recommends - equally
        bogus
        CSSM_CL_HANDLE clHandle;
        status = SecCertificateGetCLHandle(certRef,
                                             &clHandle);
        assert(status == noErr);
        crtn = CSSM_CL_CertGetKeyInfo(clHandle, certData,
                                        (CSSM_KEY_PTR *)&pubkey);
        assert(crtn == CSSM_OK);
#endif
        
        status = SecKeyGetCSSMKey(keyRef, (const CSSM_KEY
                                             **)&privkey);
        assert(status == noErr);
        assert(privkey->KeyHeader.AlgorithmId ==
               CSSM_ALGID_RSA);
        assert(privkey->KeyHeader.KeyClass ==
               CSSM_KEYCLASS_PRIVATE_KEY);
        
        break;
        
    }
    
    CFRelease(keychain);
    
#else // generate a public/private key pair
    
    CSSM_VERSION vers = {2, 0};
    const CSSM_GUID testGuid = { 0xFADE, 0, 0, {
        1,2,3,4,5,6,7,0 }};
    
    CSSM_PVC_MODE policy = CSSM_PVC_NONE;
    crtn = CSSM_Init(&vers,
                       CSSM_PRIVILEGE_SCOPE_NONE,
                       &testGuid,
                       CSSM_KEY_HIERARCHY_NONE,
                       &policy,
                       NULL);
    assert(crtn == CSSM_OK);
    
    crtn = CSSM_ModuleLoad(&gGuidAppleCSP,
                             CSSM_KEY_HIERARCHY_NONE,
                             NULL,                   // eventHandler
                             NULL);                  //
    AppNotifyCallbackCtx
    assert(crtn == CSSM_OK);
    
    crtn = CSSM_ModuleAttach(&gGuidAppleCSP,
                               &vers,
                               &memFuncs,                      // memFuncs
                               0,                                      //
                               SubserviceID
                               CSSM_SERVICE_CSP,
                               0,                                      //
                               AttachFlags
                               CSSM_KEY_HIERARCHY_NONE,
                               NULL,                           //
                               FunctionTable
                               0,                                      //
                               NumFuncTable
                               NULL,                           // reserved
                               &cspHandle);
    assert(crtn == CSSM_OK);
    
    SecKeyRef publicKeyRef;
    SecKeyRef privateKeyRef;
    status = SecKeyCreatePair(NULL, CSSM_ALGID_RSA, 512,
                                NULL,
                                CSSM_KEYUSE_ENCRYPT |
                                CSSM_KEYUSE_VERIFY,
                                CSSM_KEYATTR_RETURN_REF |
                                CSSM_KEYATTR_EXTRACTABLE | CSSM_KEYATTR_PERMANENT,
                                CSSM_KEYUSE_DECRYPT |
                                CSSM_KEYUSE_SIGN,
                                CSSM_KEYATTR_RETURN_REF |
                                CSSM_KEYATTR_EXTRACTABLE | CSSM_KEYATTR_PERMANENT |
                                CSSM_KEYATTR_SENSITIVE,
                                NULL,
                                &publicKeyRef,
                                &privateKeyRef);
    cssmPerror("SecKeyCreatePair", status);
    assert(status == noErr);
    
    status = SecKeyGetCSSMKey(privateKeyRef, (const CSSM_KEY
                                                **)&privkey);
    assert(status == noErr);
    assert(privkey->KeyHeader.AlgorithmId == CSSM_ALGID_RSA);
    assert(privkey->KeyHeader.KeyClass ==
           CSSM_KEYCLASS_PRIVATE_KEY);
    
    status = SecKeyGetCSSMKey(publicKeyRef, (const CSSM_KEY
                                               **)&pubkey);
    assert(status == noErr);
    assert(pubkey->KeyHeader.AlgorithmId == CSSM_ALGID_RSA);
    assert(pubkey->KeyHeader.KeyClass ==
           CSSM_KEYCLASS_PUBLIC_KEY);
    
    // this only works after calling SecKeyCreatePair ???
    status = SecKeychainGetCSPHandle(NULL, &cspHandle);
    assert(status == noErr);
    
#endif
    
    const char *plaintext = "ABCDEABCDEABCDEABCDE";
    
    CSSM_DATA plainText = { strlen(plaintext),
        (uint8*)plaintext };
    CSSM_DATA cipherText = {0, NULL};
    CSSM_DATA decipherText = {0, NULL};
    CSSM_DATA signatureText = { 256, (uint8*)malloc(256) };
    CSSM_DATA remData = {0, NULL};
    
    CSSM_ACCESS_CREDENTIALS creds;
    memset(&creds, 0, sizeof(CSSM_ACCESS_CREDENTIALS));
    
    CSSM_CC_HANDLE ccHandle;
    
    uint32 bytesEncrypted;
    
#if 1
    
    //
    // Encrypt Test
    //
    InfoLog( "Doing Encrypt Test" );
    
    crtn = CSSM_CSP_CreateAsymmetricContext(cspHandle,
                                            CSSM_ALGID_RSA,
                                            &creds, pubkey,
                                            CSSM_PADDING_PKCS1, &ccHandle);
    cssmPerror("encrypt context", crtn);
    assert(crtn == CSSM_OK);
    
    crtn = CSSM_EncryptData(ccHandle, &plainText, 1,
                              &cipherText, 1, &bytesEncrypted, &remData);
    cssmPerror("encryptdata", crtn);
    assert(crtn == CSSM_OK);
    CSSM_DeleteContext(ccHandle);
    
    fprintf(stderr, "EncryptData output %ld bytes\n",
            cipherText.Length);
    //fprintf(stderr, "[%s]\n", cipherText.Data);
    
    InfoLog( "Encrypt Test successful!" );
    
#endif
    
#if 1
    
    //
    // Decrypt Test
    //
    InfoLog( "Doing Decrypt Test" );
    
    crtn = CSSM_CSP_CreateAsymmetricContext(cspHandle,
                                              CSSM_ALGID_RSA,
                                              &creds, privkey,
                                              CSSM_PADDING_PKCS1, &ccHandle);
    cssmPerror("decrypt context", crtn);
    assert(crtn == CSSM_OK);
    
    crtn = CSSM_DecryptData(ccHandle, &cipherText, 1,
                              &decipherText, 1, &bytesEncrypted, &remData);
    cssmPerror("decryptdata", crtn);
    assert(crtn == CSSM_OK);
    CSSM_DeleteContext(ccHandle);
    
    fprintf(stderr, "DecryptData output %ld bytes\n",
            decipherText.Length);
    fprintf(stderr, "[%s]\n", decipherText.Data);
    
    InfoLog( "Decrypt Test successful!" );
    
#endif
    
#if 1
    
    //
    // Sign Test
    //
    InfoLog( "Doing Sign Test" );
    
    crtn = CSSM_CSP_CreateSignatureContext(cspHandle,
                                             CSSM_ALGID_RSA, NULL, privkey, &ccHandle);
    cssmPerror("sign", crtn);
    assert(crtn == CSSM_OK);
    
    //crtn = CSSM_SignData(ccHandle, &plainText, 1,
    CSSM_ALGID_SHA1, &signatureText;
    crtn = CSSM_SignData(ccHandle, &plainText, 1,
                           CSSM_ALGID_NONE, &signatureText);
    cssmPerror("signdata", crtn);
    assert(crtn == CSSM_OK);
    CSSM_DeleteContext(ccHandle);
    
    fprintf(stderr, "SignData output %ld bytes\n",
            signatureText.Length);
    fprintf(stderr, "[%s]\n", signatureText.Data);
    
    InfoLog( "Sign Test successful!" );
    
#endif
    
    //delete signatureText.Data;
    return 1;

}

#pragma mark --------- Encrypt/Decrypt ---------

/*
 * Encrypt/Decrypt
 */
/*
 * Common routine for encrypt/decrypt - cook up an appropriate context handle
 */
/*
 * When true, effectiveKeySizeInBits is passed down via the Params argument.
 * Otherwise, we add a customized context attribute.
 * Setting this true works with the stock Intel CSSM; this may well change.
 * Note this overloading prevent us from specifying RC5 rounds....
 */
#define EFFECTIVE_SIZE_VIA_PARAMS		0
CSSM_CC_HANDLE genCryptHandle(CSSM_CSP_HANDLE cspHand,
                              uint32 algorithm,					// CSSM_ALGID_FEED, etc.
                              uint32 mode,						// CSSM_ALGMODE_CBC, etc. - only for symmetric algs
                              CSSM_PADDING padding,				// CSSM_PADDING_PKCS1, etc.
                              const CSSM_KEY *key0,
                              const CSSM_KEY *key1,				// for CSSM_ALGID_FEED only - must be the
                              // public key
                              const CSSM_DATA *iv,				// optional
                              uint32 effectiveKeySizeInBits,		// 0 means skip this attribute
                              uint32 rounds)						// ditto
{
	CSSM_CC_HANDLE cryptHand = 0;
	uint32 params;
	CSSM_RETURN crtn;
	CSSM_ACCESS_CREDENTIALS	creds;
	
	memset(&creds, 0, sizeof(CSSM_ACCESS_CREDENTIALS));
#if	EFFECTIVE_SIZE_VIA_PARAMS
	params = effectiveKeySizeInBits;
#else
	params = 0;
#endif
	switch(algorithm) {
		case CSSM_ALGID_DES:
		case CSSM_ALGID_3DES_3KEY_EDE:
		case CSSM_ALGID_DESX:
		case CSSM_ALGID_ASC:
		case CSSM_ALGID_RC2:
		case CSSM_ALGID_RC4:
		case CSSM_ALGID_RC5:
		case CSSM_ALGID_AES:
		case CSSM_ALGID_BLOWFISH:
		case CSSM_ALGID_CAST:
		case CSSM_ALGID_IDEA:
		case CSSM_ALGID_NONE:		// used for wrapKey()
			crtn = CSSM_CSP_CreateSymmetricContext(cspHand,
                                                   algorithm,
                                                   mode,
                                                   NULL,			// access cred
                                                   key0,
                                                   iv,				// InitVector
                                                   padding,
                                                   NULL,			// Params
                                                   &cryptHand);
			if(crtn) {
				printError("CSSM_CSP_CreateSymmetricContext", crtn);
				return 0;
			}
			break;
		case CSSM_ALGID_FEED:
		case CSSM_ALGID_FEEDEXP:
		case CSSM_ALGID_RSA:
            crtn = CSSM_CSP_CreateAsymmetricContext(cspHand,
                                                    algorithm,
                                                    &creds,			// access
                                                    key0,
                                                    padding,
                                                    &cryptHand);
			if(crtn) {
				printError("CSSM_CSP_CreateAsymmetricContext", crtn);
				return 0;
			}
			if(key1 != NULL) {
				/*
				 * FEED, some CFILE. Add (non-standard) second key attribute.
				 */
				crtn = AddContextAttribute(cryptHand,
                                           CSSM_ATTRIBUTE_PUBLIC_KEY,
                                           sizeof(CSSM_KEY),			// currently sizeof CSSM_DATA
                                           CAT_Ptr,
                                           key1,
                                           0);
				if(crtn) {
					printError("AddContextAttribute", crtn);
					return 0;
				}
			}
			if(mode != CSSM_ALGMODE_NONE) {
				/* special case, e.g., CSSM_ALGMODE_PUBLIC_KEY */
				crtn = AddContextAttribute(cryptHand,
                                           CSSM_ATTRIBUTE_MODE,
                                           sizeof(uint32),
                                           CAT_Uint32,
                                           NULL,
                                           mode);
				if(crtn) {
					printError("AddContextAttribute", crtn);
					return 0;
				}
			}
			break;
		default:
			printf("genCryptHandle: bogus algorithm\n");
			return 0;
	}
#if		!EFFECTIVE_SIZE_VIA_PARAMS
	/* add optional EffectiveKeySizeInBits and rounds attributes */
	if(effectiveKeySizeInBits != 0) {
		CSSM_CONTEXT_ATTRIBUTE attr;
		attr.AttributeType = CSSM_ATTRIBUTE_EFFECTIVE_BITS;
		attr.AttributeLength = sizeof(uint32);
		attr.Attribute.Uint32 = effectiveKeySizeInBits;
		crtn = CSSM_UpdateContextAttributes(
                                            cryptHand,
                                            1,
                                            &attr);
		if(crtn) {
			printError("CSSM_UpdateContextAttributes", crtn);
			return crtn;
		}
	}
#endif
	
	if(rounds != 0) {
		CSSM_CONTEXT_ATTRIBUTE attr;
		attr.AttributeType = CSSM_ATTRIBUTE_ROUNDS;
		attr.AttributeLength = sizeof(uint32);
		attr.Attribute.Uint32 = rounds;
		crtn = CSSM_UpdateContextAttributes(
                                            cryptHand,
                                            1,
                                            &attr);
		if(crtn) {
			printError("CSSM_UpdateContextAttributes", crtn);
			return crtn;
		}
	}
    
	return cryptHand;
}

CSSM_RETURN cspEncrypt(CSSM_CSP_HANDLE cspHand,
                       uint32 algorithm,					// CSSM_ALGID_FEED, etc.
                       uint32 mode,						// CSSM_ALGMODE_CBC, etc. - only for symmetric algs
                       CSSM_PADDING padding,				// CSSM_PADDING_PKCS1, etc.
                       const CSSM_KEY *key,				// public or session key
                       const CSSM_KEY *pubKey,				// for CSSM_ALGID_FEED, CSSM_ALGID_FEECFILE only
                       uint32 effectiveKeySizeInBits,		// 0 means skip this attribute
                       uint32 rounds,						// ditto
                       const CSSM_DATA *iv,				// init vector, optional
                       const CSSM_DATA *ptext,
                       CSSM_DATA_PTR ctext,				// RETURNED
                       CSSM_BOOL mallocCtext)				// if true, and ctext empty, malloc
// by getting size from CSP
{
	CSSM_CC_HANDLE 	cryptHand;
	CSSM_RETURN		crtn;
	CSSM_SIZE		bytesEncrypted;
	CSSM_DATA		remData = {0, NULL};
	CSSM_RETURN		ocrtn = CSSM_OK;
	unsigned		origCtextLen;			// the amount we malloc, if any
	CSSM_RETURN		savedErr = CSSM_OK;
	CSSM_BOOL		restoreErr = CSSM_FALSE;
	
	cryptHand = genCryptHandle(cspHand,
                               algorithm,
                               mode,
                               padding,
                               key,
                               pubKey,
                               iv,
                               effectiveKeySizeInBits,
                               rounds);
	if(cryptHand == 0) {
		return CSSMERR_CSSM_INTERNAL_ERROR;
	}
	if(mallocCtext && (ctext->Length == 0)) {
		CSSM_QUERY_SIZE_DATA querySize;
		querySize.SizeInputBlock = ptext->Length;
		crtn = CSSM_QuerySize(cryptHand,
                              CSSM_TRUE,						// encrypt
                              1,
                              &querySize);
		if(crtn) {
			printError("CSSM_QuerySize", crtn);
			ocrtn = crtn;
			goto abort;
		}
		if(querySize.SizeOutputBlock == 0) {
			/* CSP couldn't figure this out; skip our malloc */
			printf("***cspEncrypt: warning: cipherTextSize unknown; "
                   "skipping malloc\n");
			origCtextLen = 0;
		}
		else {
			ctext->Data = (uint8 *)
            appMalloc(querySize.SizeOutputBlock, NULL);
			if(ctext->Data == NULL) {
				printf("Insufficient heap space\n");
				ocrtn = CSSM_ERRCODE_MEMORY_ERROR;
				goto abort;
			}
			ctext->Length = origCtextLen = querySize.SizeOutputBlock;
			memset(ctext->Data, 0, ctext->Length);
		}
	}
	else {
		origCtextLen = ctext->Length;
	}
	crtn = CSSM_EncryptData(cryptHand,
                            ptext,
                            1,
                            ctext,
                            1,
                            &bytesEncrypted,
                            &remData);
	if(crtn == CSSM_OK) {
		/*
		 * Deal with remData - its contents are included in bytesEncrypted.
		 */
		if((remData.Length != 0) && mallocCtext) {
			/* shouldn't happen - right? */
			if(bytesEncrypted > origCtextLen) {
				/* malloc and copy a new one */
				uint8 *newCdata = (uint8 *)appMalloc(bytesEncrypted, NULL);
				printf("**Warning: app malloced cipherBuf, but got nonzero "
                       "remData!\n");
				if(newCdata == NULL) {
					printf("Insufficient heap space\n");
					ocrtn = CSSM_ERRCODE_MEMORY_ERROR;
					goto abort;
				}
				memmove(newCdata, ctext->Data, ctext->Length);
				memmove(newCdata+ctext->Length, remData.Data, remData.Length);
				CSSM_FREE(ctext->Data);
				ctext->Data = newCdata;
			}
			else {
				/* there's room left over */
				memmove(ctext->Data+ctext->Length, remData.Data, remData.Length);
			}
			ctext->Length = bytesEncrypted;
		}
		// NOTE: We return the proper length in ctext....
		ctext->Length = bytesEncrypted;
	}
	else {
		savedErr = crtn;
		restoreErr = CSSM_TRUE;
		printError("CSSM_EncryptData", crtn);
	}
abort:
	crtn = CSSM_DeleteContext(cryptHand);
	if(crtn) {
		printError("CSSM_DeleteContext", crtn);
		ocrtn = crtn;
	}
	if(restoreErr) {
		ocrtn = savedErr;
	}
	return ocrtn;
}

#define PAD_IMPLIES_RAND_PTEXTSIZE	1
#define LOG_STAGED_OPS				0
#if		LOG_STAGED_OPS
#define soprintf(s)	printf s
#else
#define soprintf(s)
#endif

CSSM_RETURN cspStagedEncrypt(CSSM_CSP_HANDLE cspHand,
                             uint32 algorithm,					// CSSM_ALGID_FEED, etc.
                             uint32 mode,						// CSSM_ALGMODE_CBC, etc. - only for symmetric algs
                             CSSM_PADDING padding,				// CSSM_PADDING_PKCS1, etc.
                             const CSSM_KEY *key,				// public or session key
                             const CSSM_KEY *pubKey,				// for CSSM_ALGID_FEED, CSSM_ALGID_FEECFILE only
                             uint32 effectiveKeySizeInBits,		// 0 means skip this attribute
                             uint32 cipherBlockSize,				// ditto
                             uint32 rounds,						// ditto
                             const CSSM_DATA *iv,				// init vector, optional
                             const CSSM_DATA *ptext,
                             CSSM_DATA_PTR ctext,				// RETURNED, we malloc
                             CSSM_BOOL multiUpdates)				// false:single update, true:multi updates
{
	CSSM_CC_HANDLE 	cryptHand;
	CSSM_RETURN		crtn;
	CSSM_SIZE		bytesEncrypted;			// per update
	CSSM_SIZE		bytesEncryptedTotal = 0;
	CSSM_RETURN		ocrtn = CSSM_OK;		// 'our' crtn
	unsigned		toMove;					// remaining
	unsigned		thisMove;				// bytes to encrypt on this update
	CSSM_DATA		thisPtext;				// running ptr into ptext
	CSSM_DATA		ctextWork;				// per update, mallocd by CSP
	CSSM_QUERY_SIZE_DATA querySize;
	uint8			*origCtext;				// initial ctext->Data
	unsigned		origCtextLen;			// amount we mallocd
	CSSM_BOOL		restoreErr = CSSM_FALSE;
	CSSM_RETURN		savedErr = CSSM_OK;
	
	
	cryptHand = genCryptHandle(cspHand,
                               algorithm,
                               mode,
                               padding,
                               key,
                               pubKey,
                               iv,
                               effectiveKeySizeInBits,
                               rounds);
	if(cryptHand == 0) {
		return CSSMERR_CSP_INTERNAL_ERROR;
	}
	if(cipherBlockSize) {
		crtn = AddContextAttribute(cryptHand,
                                   CSSM_ATTRIBUTE_BLOCK_SIZE,
                                   sizeof(uint32),
                                   CAT_Uint32,
                                   NULL,
                                   cipherBlockSize);
		if(crtn) {
			printError("CSSM_UpdateContextAttributes", crtn);
			goto abort;
		}
	}
	
	/* obtain total required ciphertext size and block size */
	querySize.SizeInputBlock = ptext->Length;
	crtn = CSSM_QuerySize(cryptHand,
                          CSSM_TRUE,						// encrypt
                          1,
                          &querySize);
	if(crtn) {
		printError("CSSM_QuerySize(1)", crtn);
		ocrtn = CSSMERR_CSP_INTERNAL_ERROR;
		goto abort;
	}
	if(querySize.SizeOutputBlock == 0) {
		/* CSP couldn't figure this out; skip our malloc - caller is taking its
		 * chances */
		printf("***cspStagedEncrypt: warning: cipherTextSize unknown; aborting\n");
		ocrtn = CSSMERR_CSP_INTERNAL_ERROR;
		goto abort;
	}
	else {
		origCtextLen = querySize.SizeOutputBlock;
		if(algorithm == CSSM_ALGID_ASC) {
			/* ASC is weird - the more chunks we do, the bigger the
			 * resulting ctext...*/
			origCtextLen *= 2;
		}
		ctext->Length = origCtextLen;
		ctext->Data   = origCtext = (uint8 *)appMalloc(origCtextLen, NULL);
		if(ctext->Data == NULL) {
			printf("Insufficient heap space\n");
			ocrtn = CSSMERR_CSP_MEMORY_ERROR;
			goto abort;
		}
		memset(ctext->Data, 0, ctext->Length);
	}
    
	crtn = CSSM_EncryptDataInit(cryptHand);
	if(crtn) {
		printError("CSSM_EncryptDataInit", crtn);
		ocrtn = crtn;
		goto abort;
	}
	
	toMove = ptext->Length;
	thisPtext.Data = ptext->Data;
	while(toMove) {
		if(multiUpdates) {
			thisMove = genRand(1, toMove);
		}
		else {
			/* just do one pass thru this loop */
			thisMove = toMove;
		}
		thisPtext.Length = thisMove;
		/* let CSP do the individual mallocs */
		ctextWork.Data = NULL;
		ctextWork.Length = 0;
		soprintf(("*** EncryptDataUpdate: ptextLen 0x%x\n", thisMove));
		crtn = CSSM_EncryptDataUpdate(cryptHand,
                                      &thisPtext,
                                      1,
                                      &ctextWork,
                                      1,
                                      &bytesEncrypted);
		if(crtn) {
			printError("CSSM_EncryptDataUpdate", crtn);
			ocrtn = crtn;
			goto abort;
		}
		// NOTE: We return the proper length in ctext....
		ctextWork.Length = bytesEncrypted;
		soprintf(("*** EncryptDataUpdate: ptextLen 0x%x  bytesEncrypted 0x%x\n",
                  thisMove, bytesEncrypted));
		thisPtext.Data += thisMove;
		toMove         -= thisMove;
		if(bytesEncrypted > ctext->Length) {
			printf("cspStagedEncrypt: ctext overflow!\n");
			ocrtn = crtn;
			goto abort;
		}
		if(bytesEncrypted != 0) {
			memmove(ctext->Data, ctextWork.Data, bytesEncrypted);
			bytesEncryptedTotal += bytesEncrypted;
			ctext->Data         += bytesEncrypted;
			ctext->Length       -= bytesEncrypted;
		}
		if(ctextWork.Data != NULL) {
			CSSM_FREE(ctextWork.Data);
		}
	}
	/* OK, one more */
	ctextWork.Data = NULL;
	ctextWork.Length = 0;
	crtn = CSSM_EncryptDataFinal(cryptHand, &ctextWork);
	if(crtn) {
		printError("CSSM_EncryptDataFinal", crtn);
		savedErr = crtn;
		restoreErr = CSSM_TRUE;
		goto abort;
	}
	if(ctextWork.Length != 0) {
		bytesEncryptedTotal += ctextWork.Length;
		if(ctextWork.Length > ctext->Length) {
			printf("cspStagedEncrypt: ctext overflow (2)!\n");
			ocrtn = CSSMERR_CSP_INTERNAL_ERROR;
			goto abort;
		}
		memmove(ctext->Data, ctextWork.Data, ctextWork.Length);
	}
	if(ctextWork.Data) {
		/* this could have gotten mallocd and Length still be zero */
		CSSM_FREE(ctextWork.Data);
	}
    
	/* retweeze ctext */
	ctext->Data   = origCtext;
	ctext->Length = bytesEncryptedTotal;
abort:
	crtn = CSSM_DeleteContext(cryptHand);
	if(crtn) {
		printError("CSSM_DeleteContext", crtn);
		ocrtn = crtn;
	}
	if(restoreErr) {
		/* give caller the error from the encrypt */
		ocrtn = savedErr;
	}
	return ocrtn;
}

CSSM_RETURN cspDecrypt(CSSM_CSP_HANDLE cspHand,
                       uint32 algorithm,					// CSSM_ALGID_FEED, etc.
                       uint32 mode,						// CSSM_ALGMODE_CBC, etc. - only for symmetric algs
                       CSSM_PADDING padding,				// CSSM_PADDING_PKCS1, etc.
                       const CSSM_KEY *key,				// public or session key
                       const CSSM_KEY *pubKey,				// for CSSM_ALGID_FEED, CSSM_ALGID_FEECFILE only
                       uint32 effectiveKeySizeInBits,		// 0 means skip this attribute
                       uint32 rounds,						// ditto
                       const CSSM_DATA *iv,				// init vector, optional
                       const CSSM_DATA *ctext,
                       CSSM_DATA_PTR ptext,				// RETURNED
                       CSSM_BOOL mallocPtext)				// if true and ptext->Length = 0,
//   we'll malloc
{
	CSSM_CC_HANDLE 	cryptHand;
	CSSM_RETURN		crtn;
	CSSM_RETURN		ocrtn = CSSM_OK;
	CSSM_SIZE		bytesDecrypted;
	CSSM_DATA		remData = {0, NULL};
	unsigned		origPtextLen;			// the amount we malloc, if any
    
	cryptHand = genCryptHandle(cspHand,
                               algorithm,
                               mode,
                               padding,
                               key,
                               pubKey,
                               iv,
                               effectiveKeySizeInBits,
                               rounds);
	if(cryptHand == 0) {
		return CSSMERR_CSP_INTERNAL_ERROR;
	}
	if(mallocPtext && (ptext->Length == 0)) {
		CSSM_QUERY_SIZE_DATA querySize;
		querySize.SizeInputBlock = ctext->Length;
		crtn = CSSM_QuerySize(cryptHand,
                              CSSM_FALSE,						// encrypt
                              1,
                              &querySize);
		if(crtn) {
			printError("CSSM_QuerySize", crtn);
			ocrtn = crtn;
			goto abort;
		}
		if(querySize.SizeOutputBlock == 0) {
			/* CSP couldn't figure this one out; skip our malloc */
			printf("***cspDecrypt: warning: plainTextSize unknown; "
                   "skipping malloc\n");
			origPtextLen = 0;
		}
		else {
			ptext->Data =
            (uint8 *)appMalloc(querySize.SizeOutputBlock, NULL);
			if(ptext->Data == NULL) {
				printf("Insufficient heap space\n");
				ocrtn = CSSMERR_CSP_MEMORY_ERROR;
				goto abort;
			}
			ptext->Length = origPtextLen = querySize.SizeOutputBlock;
			memset(ptext->Data, 0, ptext->Length);
		}
	}
	else {
		origPtextLen = ptext->Length;
	}
	crtn = CSSM_DecryptData(cryptHand,
                            ctext,
                            1,
                            ptext,
                            1,
                            &bytesDecrypted,
                            &remData);
	if(crtn == CSSM_OK) {
		/*
		 * Deal with remData - its contents are included in bytesDecrypted.
		 */
		if((remData.Length != 0) && mallocPtext) {
			/* shouldn't happen - right? */
			if(bytesDecrypted > origPtextLen) {
				/* malloc and copy a new one */
				uint8 *newPdata = (uint8 *)appMalloc(bytesDecrypted, NULL);
				printf("**Warning: app malloced ClearBuf, but got nonzero "
                       "remData!\n");
				if(newPdata == NULL) {
					printf("Insufficient heap space\n");
					ocrtn = CSSMERR_CSP_MEMORY_ERROR;
					goto abort;
				}
				memmove(newPdata, ptext->Data, ptext->Length);
				memmove(newPdata + ptext->Length,
                        remData.Data, remData.Length);
				CSSM_FREE(ptext->Data);
				ptext->Data = newPdata;
			}
			else {
				/* there's room left over */
				memmove(ptext->Data + ptext->Length,
                        remData.Data, remData.Length);
			}
			ptext->Length = bytesDecrypted;
		}
		// NOTE: We return the proper length in ptext....
		ptext->Length = bytesDecrypted;
		
		// FIXME - sometimes get mallocd RemData here, but never any valid data
		// there...side effect of CSPFullPluginSession's buffer handling logic;
		// but will we ever actually see valid data in RemData? So far we never
		// have....
		if(remData.Data != NULL) {
			appFree(remData.Data, NULL);
		}
	}
	else {
		printError("CSSM_DecryptData", crtn);
		ocrtn = crtn;
	}
abort:
	crtn = CSSM_DeleteContext(cryptHand);
	if(crtn) {
		printError("CSSM_DeleteContext", crtn);
		ocrtn = crtn;
	}
	return ocrtn;
}

CSSM_RETURN cspStagedDecrypt(CSSM_CSP_HANDLE cspHand,
                             uint32 algorithm,					// CSSM_ALGID_FEED, etc.
                             uint32 mode,						// CSSM_ALGMODE_CBC, etc. - only for symmetric algs
                             CSSM_PADDING padding,				// CSSM_PADDING_PKCS1, etc.
                             const CSSM_KEY *key,				// public or session key
                             const CSSM_KEY *pubKey,				// for CSSM_ALGID_FEED, CSSM_ALGID_FEECFILE only
                             uint32 effectiveKeySizeInBits,		// 0 means skip this attribute
                             uint32 cipherBlockSize,				// ditto
                             uint32 rounds,						// ditto
                             const CSSM_DATA *iv,				// init vector, optional
                             const CSSM_DATA *ctext,
                             CSSM_DATA_PTR ptext,				// RETURNED, we malloc
                             CSSM_BOOL multiUpdates)				// false:single update, true:multi updates
{
	CSSM_CC_HANDLE 	cryptHand;
	CSSM_RETURN		crtn;
	CSSM_SIZE		bytesDecrypted;			// per update
	CSSM_SIZE		bytesDecryptedTotal = 0;
	CSSM_RETURN		ocrtn = CSSM_OK;		// 'our' crtn
	unsigned		toMove;					// remaining
	unsigned		thisMove;				// bytes to encrypt on this update
	CSSM_DATA		thisCtext;				// running ptr into ptext
	CSSM_DATA		ptextWork;				// per update, mallocd by CSP
	CSSM_QUERY_SIZE_DATA querySize;
	uint8			*origPtext;				// initial ptext->Data
	unsigned		origPtextLen;			// amount we mallocd
	
	cryptHand = genCryptHandle(cspHand, 
                               algorithm, 
                               mode, 
                               padding,
                               key, 
                               pubKey, 
                               iv,
                               effectiveKeySizeInBits,
                               rounds);
	if(cryptHand == 0) {
		return CSSMERR_CSP_INTERNAL_ERROR;
	}
	if(cipherBlockSize) {
		crtn = AddContextAttribute(cryptHand,
                                   CSSM_ATTRIBUTE_BLOCK_SIZE,
                                   sizeof(uint32),
                                   CAT_Uint32,
                                   NULL,
                                   cipherBlockSize);
		if(crtn) {
			printError("CSSM_UpdateContextAttributes", crtn);
			goto abort;
		}
	}
	
	/* obtain total required ciphertext size and block size */
	querySize.SizeInputBlock = ctext->Length;
	crtn = CSSM_QuerySize(cryptHand,
                          CSSM_FALSE,						// encrypt
                          1,
                          &querySize);
	if(crtn) {
		printError("CSSM_QuerySize(1)", crtn);
		ocrtn = crtn;
		goto abort;
	}
	
	/* required ptext size should be independent of number of chunks */
	if(querySize.SizeOutputBlock == 0) {
		printf("***warning: cspStagedDecrypt: plainTextSize unknown; aborting\n");
		ocrtn = CSSMERR_CSP_INTERNAL_ERROR;
		goto abort;
	}
	else {
		// until exit, ptext->Length indicates remaining bytes of usable data in
		// ptext->Data
		ptext->Length = origPtextLen = querySize.SizeOutputBlock;
		ptext->Data   = origPtext    = 
        (uint8 *)appMalloc(origPtextLen, NULL);
		if(ptext->Data == NULL) {
			printf("Insufficient heap space\n");
			ocrtn = CSSMERR_CSP_INTERNAL_ERROR;
			goto abort;
		}
		memset(ptext->Data, 0, ptext->Length);
	}
	
	crtn = CSSM_DecryptDataInit(cryptHand);
	if(crtn) {
		printError("CSSM_DecryptDataInit", crtn);
		ocrtn = crtn;
		goto abort;
	}
	toMove = ctext->Length;
	thisCtext.Data = ctext->Data;
	while(toMove) {
		if(multiUpdates) {
			thisMove = genRand(1, toMove);
		}
		else {
			/* just do one pass thru this loop */
			thisMove = toMove;
		}
		thisCtext.Length = thisMove;
		/* let CSP do the individual mallocs */
		ptextWork.Data = NULL;
		ptextWork.Length = 0;
		soprintf(("*** DecryptDataUpdate: ctextLen 0x%x\n", thisMove));
		crtn = CSSM_DecryptDataUpdate(cryptHand,
                                      &thisCtext,
                                      1,
                                      &ptextWork,
                                      1,
                                      &bytesDecrypted);
		if(crtn) {
			printError("CSSM_DecryptDataUpdate", crtn);
			ocrtn = crtn;
			goto abort;
		}
		//
		// NOTE: We return the proper length in ptext....
		ptextWork.Length = bytesDecrypted;
		thisCtext.Data += thisMove;
		toMove         -= thisMove;
		if(bytesDecrypted > ptext->Length) {
			printf("cspStagedDecrypt: ptext overflow!\n");
			ocrtn = CSSMERR_CSP_INTERNAL_ERROR;
			goto abort;
		}
		if(bytesDecrypted != 0) {
			memmove(ptext->Data, ptextWork.Data, bytesDecrypted);
			bytesDecryptedTotal += bytesDecrypted;
			ptext->Data         += bytesDecrypted;
			ptext->Length       -= bytesDecrypted;
		}
		if(ptextWork.Data != NULL) {
			CSSM_FREE(ptextWork.Data);
		}
	}
	/* OK, one more */
	ptextWork.Data = NULL;
	ptextWork.Length = 0;
	crtn = CSSM_DecryptDataFinal(cryptHand, &ptextWork);
	if(crtn) {
		printError("CSSM_DecryptDataFinal", crtn);
		ocrtn = crtn;
		goto abort;
	}
	if(ptextWork.Length != 0) {
		bytesDecryptedTotal += ptextWork.Length;
		if(ptextWork.Length > ptext->Length) {
			printf("cspStagedDecrypt: ptext overflow (2)!\n");
			ocrtn = CSSMERR_CSP_INTERNAL_ERROR;
			goto abort;
		}
		memmove(ptext->Data, ptextWork.Data, ptextWork.Length);
	}
	if(ptextWork.Data) {
		/* this could have gotten mallocd and Length still be zero */
		CSSM_FREE(ptextWork.Data);
	}
	
	/* retweeze ptext */
	ptext->Data   = origPtext;
	ptext->Length = bytesDecryptedTotal;
abort:
	crtn = CSSM_DeleteContext(cryptHand);
	if(crtn) {
		printError("CSSM_DeleteContext", crtn);
		ocrtn = crtn;
	}
	return ocrtn;
}


/*
 * Given a context specified via a CSSM_CC_HANDLE, add a new
 * CSSM_CONTEXT_ATTRIBUTE to the context as specified by AttributeType,
 * AttributeLength, and an untyped pointer.
 *
 * This is currently used to add a second CSSM_KEY attribute when performing
 * ops with algorithm CSSM_ALGID_FEED and CSSM_ALGID_FEECFILE.
 */
CSSM_RETURN AddContextAttribute(CSSM_CC_HANDLE CCHandle,
                                uint32 AttributeType,
                                uint32 AttributeLength,
                                ContextAttrType attrType,
                                /* specify exactly one of these */
                                const void *AttributePtr,
                                uint32 attributeInt)
{
	CSSM_CONTEXT_ATTRIBUTE		newAttr;
	CSSM_RETURN					crtn;
	
	newAttr.AttributeType     = AttributeType;
	newAttr.AttributeLength   = AttributeLength;
	if(attrType == CAT_Uint32) {
		newAttr.Attribute.Uint32  = attributeInt;
	}
	else {
		newAttr.Attribute.Data    = (CSSM_DATA_PTR)AttributePtr;
	}
	crtn = CSSM_UpdateContextAttributes(CCHandle, 1, &newAttr);
	if(crtn) {
		printError("CSSM_UpdateContextAttributes", crtn);
	}
	return crtn;
}


/*
 * We can't enable this until all of these are fixed and integrated:
 * 2890978 CSP
 * 2927474 CSPDL
 * 2928357 TP
 */
#define DETECT_MALLOC_ABUSE		1

#if		DETECT_MALLOC_ABUSE

/*
 * This set of allocator functions detects when we free something
 * which was mallocd by CDSA or a plugin using something other than
 * our callback malloc/realloc/calloc. With proper runtime support
 * (which is present in Jaguar 6C35), the reverse is also detected
 * by malloc (i.e., we malloc something and CDSA or a plugin frees
 * it).
 */
#define APP_MALLOC_MAGIC		'Util'

void * appMalloc (CSSM_SIZE size, void *allocRef) {
	void *ptr;
    
	/* scribble magic number in first four bytes */
	ptr = malloc(size + 4);
	*(uint32 *)ptr = APP_MALLOC_MAGIC;
	ptr = (char *)ptr + 4;
    
	return ptr;
}

void appFree (void *ptr, void *allocRef) {
	if(ptr == NULL) {
		return;
	}
	ptr = (char *)ptr - 4;
	if(*(uint32 *)ptr != APP_MALLOC_MAGIC) {
		printf("ERROR: appFree() freeing a block that we didn't allocate!\n");
		return;		// this free is not safe
	}
	*(uint32 *)ptr = 0;
	free(ptr);
}

/* Realloc - adjust both original pointer and size */
void * appRealloc (void *ptr, CSSM_SIZE size, void *allocRef) {
	if(ptr == NULL) {
		/* no ptr, no existing magic number */
		return appMalloc(size, allocRef);
	}
	ptr = (char *)ptr - 4;
	if(*(uint32 *)ptr != APP_MALLOC_MAGIC) {
		printf("ERROR: appRealloc() on a block that we didn't allocate!\n");
	}
	*(uint32 *)ptr = 0;
	ptr = realloc(ptr, size + 4);
	*(uint32 *)ptr = APP_MALLOC_MAGIC;
	ptr = (char *)ptr + 4;
	return ptr;
}

/* Have to do this manually */
void * appCalloc (uint32 num, CSSM_SIZE size, void *allocRef) {
	uint32 memSize = num * size;
	
	void *ptr = appMalloc(memSize, allocRef);
	memset(ptr, 0, memSize);
	return ptr;
}

#else	/* DETECT_MALLOC_ABUSE */
/*
 * Standard app-level memory functions required by CDSA.
 */
void * appMalloc (CSSM_SIZE size, void *allocRef) {
	return( malloc(size) );
}
void appFree (void *mem_ptr, void *allocRef) {
	free(mem_ptr);
 	return;
}
void * appRealloc (void *ptr, CSSM_SIZE size, void *allocRef) {
	return( realloc( ptr, size ) );
}
void * appCalloc (uint32 num, CSSM_SIZE size, void *allocRef) {
	return( calloc( num, size ) );
}
#endif	/* DETECT_MALLOC_ABUSE */

static CSSM_API_MEMORY_FUNCS memFuncs = {
	appMalloc,
	appFree,
	appRealloc,
 	appCalloc,
 	NULL
};


/* min <= return <= max */
unsigned genRand(unsigned min, unsigned max)
{
	unsigned i;
	if(min == max) {
		return min;
	}
	//appGetRandomBytes(&i, 4);
    unsigned char *buf;
    int result = SecRandomCopyBytes(kSecRandomDefault, 4, buf);
    i=*buf;
    //NSAssert(result == 0, @"Unable to generate random bytes: %d", errno);

	return (min + (i % (max - min + 1)));
}

/*
 * Log CSSM error.
 */
void printError(const char *op, CSSM_RETURN err)
{
	cssmPerror(op, err);
}

@end