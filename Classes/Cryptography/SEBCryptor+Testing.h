//
//  SEBCryptor+Testing.h
//  SafeExamBrowser
//
//  Exposes otherwise private SEBCryptor helpers to the (DEBUG-only) test-support
//  shim so the platform-independent Config Key JSON serialization can be
//  verified. Not intended to be imported by product code.
//

#import "SEBCryptor.h"

@interface SEBCryptor (Testing)

// Serializes a single value the way it is included in the Config Key JSON.
// See -jsonStringForObject: in SEBCryptor.m.
- (NSString *)jsonStringForObject:(id)object;

@end
