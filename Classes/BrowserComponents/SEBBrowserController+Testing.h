//
//  SEBBrowserController+Testing.h
//  SafeExamBrowser
//
//  Exposes the otherwise internal server-trust authorization decision to the
//  (DEBUG-only) unit tests, so the embedded-certificate / public-key-pinning
//  trust evaluation can be verified against crafted certificates without a live
//  TLS connection. Regression coverage for the removed authorizedHosts substring
//  fallback (CWE-295). Not intended to be imported by product code.
//

#import "SEBBrowserController.h"
#import <Security/Security.h>

@interface SEBBrowserController (Testing)

// Pure server-trust authorization decision, see +shouldAuthorizeServerTrust:...
// in SEBBrowserController.m. Holds no cross-connection state: a previously
// successful evaluation can never influence the result for a later challenge.
+ (BOOL)shouldAuthorizeServerTrust:(SecTrustRef)serverTrust
                              host:(NSString *)serverHost
                              port:(NSInteger)serverPort
                           caCerts:(NSArray *)caCerts
                          tlsCerts:(NSArray *)tlsCerts
                        debugCerts:(NSArray *)debugCerts
                    debugCertNames:(NSArray *)debugCertNames
           pinEmbeddedCertificates:(BOOL)pinEmbeddedCertificates;

@end
