//
//  SEBKeychainManager.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07.11.12.
//
//

#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <CoreServices/CoreServices.h>
#import <SSCrypto/SSCrypto.h>
#import "libCdsaCrypt.h"

@interface SEBKeychainManager : NSObject

- (NSArray*) getCertificates;
- (SecKeyRef*)copyPublicKeyFromCertificate:(SecCertificateRef)certificate;
- (SecIdentityRef*)createIdentityWithCertificate:(SecCertificateRef)certificate;

- (NSData*)encryptData:(NSData*)inputData withPublicKey:(SecKeyRef*)publicKey;

@end
