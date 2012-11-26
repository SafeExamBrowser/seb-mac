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


- (NSData*)encryptData:(NSData*)inputData withPublicKeyFromCertificate:(SecCertificateRef)certificate {
    //- (NSData*)encryptData:(NSData*)inputData withPublicKey:(SecKeyRef*)publicKey {
    SecKeyRef publicKey = NULL;
    OSStatus status = SecCertificateCopyPublicKey(certificate, &publicKey);
    if (status) {
        if (status == errSecItemNotFound) {
            NSLog(@"No public key found in certificate.");
            if (publicKey) CFRelease(publicKey);
            return nil;
        }
    }


    status = noErr;
    
    // Convert input data into a buffer
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
    
    NSData *cipherData = [NSData dataWithBytes:cipherBuffer length:cipherBufferSize];
    //crtn = cdsaDecrypt(cspHand,privKeyPtr,&ctext,&ptext);

    /* Free the Security Framework Five! */
    //CFRelease(publicKey);
    free(plainText);
    free(cipherBuffer);
    return cipherData;
    //[cipherData encodeBase64ForData];
 
    
    /*/ Encrypting using CSSM/CDSA
    CSSM_KEY 		pubKey;
	CSSM_DATA		ptext;
	CSSM_DATA		ctext;
	CSSM_RETURN		crtn;
	CSSM_KEYHEADER_PTR	hdr = &pubKey.KeyHeader;
	CSSM_KEY_SIZE 		keySize;
	opParams			op;
    
	memset(&pubKey, 0, sizeof(CSSM_KEY));
    
	op.keySizeInBits = DEFAULT_KEY_SIZE_BITS;
	op.keyAlg = CSSM_ALGID_RSA;
    
	crtn = cdsaCspAttach(&op.cspHandle);
	if(crtn) {
		cssmPerror("Attach to CSP", crtn);
		return nil;
	}
    
	pubKey.KeyData.Data = (char *)[key bytes];
	pubKey.KeyData.Length = [key length];
	
	hdr->Format = CSSM_KEYBLOB_RAW_FORMAT_PKCS1;
	hdr->HeaderVersion = CSSM_KEYHEADER_VERSION;
	hdr->BlobType = CSSM_KEYBLOB_RAW;
	hdr->AlgorithmId = CSSM_ALGID_RSA;
	hdr->KeyClass = CSSM_KEYCLASS_PUBLIC_KEY;
	hdr->KeyAttr = CSSM_KEYATTR_EXTRACTABLE;
	hdr->KeyUsage = CSSM_KEYUSE_ANY;
    
	crtn = CSSM_QueryKeySizeInBits(op.cspHandle, NULL, &pubKey, &keySize);
	if(crtn) {
		cssmPerror("CSSM_QueryKeySizeInBits", crtn);
		return nil;
	}
    
	hdr->LogicalKeySizeInBits = keySize.LogicalKeySizeInBits;
    
	ctext.Data = NULL;
	ctext.Length = 0;
	ptext.Data = (char *)[text cString];
	ptext.Length = [text length];
    
	crtn = cdsaEncrypt(op.cspHandle,
                       &pubKey,
                       &ptext,
                       &ctext);
    
	if(crtn) {
		cssmPerror("cdsaEncrypt", crtn);
		return nil;
	}
    
	NSString * cipherText = [[NSData dataWithBytes: ctext.Data length: ctext.Length] description];
    
    //	cdsaFreeKey(op.cspHandle, &pubKey);
    //	free(ptext.Data);				// allocd by readFile
	free(ctext.Data);				// allocd by CSP
    
	return cipherText;*/
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
	    
    ctext.Data = (uint8 *)[cipherData bytes];
    ctext.Length = [cipherData length];
    ptext.Data = NULL;
    ptext.Length = 0;
    
    crtn = CSSM_CSP_CreateAsymmetricContext(csp,
                                            CSSM_ALGID_RSA,
                                            creds, &pubKey,
                                            CSSM_PADDING_PKCS1, &ccHandle);
    cssmPerror("decrypt context", crtn);
    assert(crtn == CSSM_OK);
    
    CSSM_SIZE bytesEncrypted;
    CSSM_DATA remData = {0, NULL};

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

@end