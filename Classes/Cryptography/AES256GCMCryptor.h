//
//  AES256GCMCryptor.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 28.02.23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AES256GCMCryptor : NSObject

+ (BOOL) aes256gcmEncrypt:(NSData*)plaintext
               ciphertext:(NSMutableData*_Nonnull*_Nonnull)ciphertext
                      aad:(NSData*_Nullable)aad
                      key:(const unsigned char*)key
                     ivec:(const unsigned char*)ivec
                      tag:(unsigned char*)tag;

+ (BOOL) aes256gcmDecrypt:(NSData*)ciphertext
                plaintext:(NSMutableData*_Nonnull*_Nonnull)plaintext
                      aad:(NSData*_Nullable)aad
                      key:(const unsigned char *)key
                     ivec:(const unsigned char *)ivec
                      tag:(unsigned char *)tag;

@end

NS_ASSUME_NONNULL_END
