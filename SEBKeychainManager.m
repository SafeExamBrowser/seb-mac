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

#define DEFAULT_KEY_SIZE_BITS		512

typedef struct {
	CSSM_ALGORITHMS		keyAlg;
	uint32				keySizeInBits;
	CSSM_CSP_HANDLE		cspHandle;
	char				*keyFileName;
	char				*plainFileName;
	char				*sigFileName;
	char				*cipherFileName;
} opParams;


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
    CFRelease(publicKey);
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


@end