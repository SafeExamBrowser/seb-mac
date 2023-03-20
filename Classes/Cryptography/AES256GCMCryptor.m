//
//  AES256GCMCryptor.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 28.02.23.
//

#import "AES256GCMCryptor.h"
#include <openssl/rand.h>
#include <openssl/ecdsa.h>
#include <openssl/obj_mac.h>
#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/evp.h>


@implementation AES256GCMCryptor

#define AES_256_KEY_LENGTH      32
#define AES_256_KEY_LENGTH_BITS 256
#define AES_256_IVEC_LENGTH     16
#define AES_256_GCM_TAG_LENGTH  16

// encrypt plaintext.
// key, ivec and tag buffers are required, aad is optional
// depending on your use, you may want to convert key, ivec, and tag to NSData/NSMutableData
+ (BOOL) aes256gcmEncrypt:(NSData*)plaintext
               ciphertext:(NSMutableData**)ciphertext
                      aad:(NSData*)aad
                      key:(const unsigned char*)key
                     ivec:(const unsigned char*)ivec
                      tag:(unsigned char*)tag {
    
    int status = 0;
    *ciphertext = [NSMutableData dataWithLength:[plaintext length]];
    if (! *ciphertext)
        return NO;
    
    // set up to Encrypt AES 256 GCM
    int numberOfBytes = 0;
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    EVP_EncryptInit_ex (ctx, EVP_aes_256_gcm(), NULL, NULL, NULL);
    
    // set the key and ivec
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, AES_256_IVEC_LENGTH, NULL);
    EVP_EncryptInit_ex (ctx, NULL, NULL, key, ivec);
    
    // add optional AAD (Additional Auth Data)
    if (aad)
        status = EVP_EncryptUpdate( ctx, NULL, &numberOfBytes, [aad bytes], [aad length]);
    
    unsigned char * ctBytes = [*ciphertext mutableBytes];
    EVP_EncryptUpdate (ctx, ctBytes, &numberOfBytes, [plaintext bytes], (int)[plaintext length]);
    status = EVP_EncryptFinal_ex (ctx, ctBytes+numberOfBytes, &numberOfBytes);
    
    if (status && tag) {
        status = EVP_CIPHER_CTX_ctrl (ctx, EVP_CTRL_GCM_GET_TAG, AES_256_GCM_TAG_LENGTH, tag);
    }
    EVP_CIPHER_CTX_free(ctx);
    return (status != 0); // OpenSSL uses 1 for success
}

// decrypt ciphertext.
// key, ivec and tag buffers are required, aad is optional
// depending on your use, you may want to convert key, ivec, and tag to NSData/NSMutableData
+ (BOOL) aes256gcmDecrypt:(NSData*)ciphertext
                plaintext:(NSMutableData**)plaintext
                      aad:(NSData*)aad
                      key:(const unsigned char *)key
                     ivec:(const unsigned char *)ivec
                      tag:(unsigned char *)tag {
    
    int status = 0;
    
    if (! ciphertext || !plaintext || !key || !ivec)
        return NO;
    
    *plaintext = [NSMutableData dataWithLength:[ciphertext length]];
    if (! *plaintext)
        return NO;
    
    // set up to Decrypt AES 256 GCM
    int numberOfBytes = 0;
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    EVP_DecryptInit_ex (ctx, EVP_aes_256_gcm(), NULL, NULL, NULL);
    
    // set the key and ivec
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, AES_256_IVEC_LENGTH, NULL);
    status = EVP_DecryptInit_ex (ctx, NULL, NULL, key, ivec);
    
    // Set expected tag value. A restriction in OpenSSL 1.0.1c and earlier requires the tag before any AAD or ciphertext
    if (status && tag)
        EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, AES_256_GCM_TAG_LENGTH, tag);
    
    // add optional AAD (Additional Auth Data)
    if (aad)
        EVP_DecryptUpdate(ctx, NULL, &numberOfBytes, [aad bytes], [aad length]);
    
    status = EVP_DecryptUpdate (ctx, [*plaintext mutableBytes], &numberOfBytes, [ciphertext bytes], (int)[ciphertext length]);
    if (! status) {
        //DDLogError(@"aes256gcmDecrypt: EVP_DecryptUpdate failed");
        return NO;
    }
    EVP_DecryptFinal_ex (ctx, NULL, &numberOfBytes);
    EVP_CIPHER_CTX_free(ctx);
    return (status != 0); // OpenSSL uses 1 for success
}

@end
