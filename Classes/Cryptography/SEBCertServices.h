//
//  SEBCertServices.h
//  SafeExamBrowser
//
//  Created by dmcd on 12/02/2016.
//

#import <Foundation/Foundation.h>

@interface SEBCertServices : NSObject

+ (instancetype)sharedInstance;

// Call this if the certificates in the client config are updated
- (void)flushCachedCertificates;

- (NSArray *)caCerts;
- (NSArray *)tlsCerts;
- (NSArray *)debugCerts;
- (NSArray *)debugCertNames;

@end
