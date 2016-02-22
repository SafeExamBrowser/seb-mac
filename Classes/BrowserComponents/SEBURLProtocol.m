//
//  SEBURLProtocol.m
//  SafeExamBrowser
//
//  JSEBNSURLProtocol.m
//  JSEB
//
//  Created by dmcd on 15/01/2016.
//  Copyright © 2016 Janison. All rights reserved.
//

#import "SEBURLProtocol.h"
#import "x509_crt.h"

static const NSString *kHTTPHeaderBrowserExamKey = @"X-SafeExamBrowser-RequestHash";
static const NSString *kJSEBRequestWasProcessed = @"SEBRequestWasProcessed";

@interface SEBURLProtocol ()
@property (nonatomic, strong) NSURLConnection *connection;
@end

@implementation SEBURLProtocol

- (void)dealloc
{
    self.connection = nil;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([request.URL.scheme hasPrefix:@"http"])
    {
        if (![NSURLProtocol propertyForKey:(NSString *)kJSEBRequestWasProcessed inRequest:request])
        {
            //NSLog(@"%@", request.URL.absoluteString);
            
//            if ([request.URL.absoluteString isEqualToString:[[ns sharedInstance] quitURL].absoluteString])
//            {
//                // TODO: broadcast quit notification and exit ASAM
//                exit(0);
//                return NO;
//            }
            
            return YES;
        }
    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSMutableURLRequest *request = [self.request mutableCopy];
//    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    
//    if ([preferences sendBrowserExamKey])
//    {
//        JSEBAppServices *jap = [JSEBAppServices sharedInstance];
//        NSString *key = [jap browserKeyForURL:request.URL];
//        
//        if ([key length])
//        {
//            [request setValue:key forHTTPHeaderField:(NSString *)kHTTPHeaderBrowserExamKey];
//        }
//    }
    
    [NSURLProtocol setProperty:@YES forKey:(NSString *)kJSEBRequestWasProcessed inRequest:request];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)stopLoading
{
    [self.connection cancel];
    self.connection = nil;
    
    [self.client URLProtocolDidFinishLoading:self];
}

/*
 * CLIENT CONFIGURATION
 *
 * JSEB internally maintains two arrays of SecCertificateRef certificate objects, tlsCerts and caRootCerts.
 * These are populated by parsing the SEB config file key 'CertificateDataDER'.
 *
 * The handling of these certs depends on the setting of 'pinEmbeddedCertificates' in the SEB config file.
 *
 * Pinning can be used as an additional layer of security to decrease the MITM attack surface by avoiding
 * the use of CA roots which are included in the OS trust store for which there is no legitimate reason
 * to actually trust them because the server endpoint's CA is known to us and its root cert is explicitly
 * supplied in 'CertificateDataDER'. Pinning can also be performed directly against a self-signed SSL/TLS
 * server cert for which we have prior knowledge of the public key (this cert must also be present in the
 * 'CertificateDataDER' key for matching purposes)
 *
 * If 'pinEmbeddedCertificates' is FALSE and both tlsCerts and caRootCerts are empty, the standard OS trust
 * store behavior applies.
 *
 * If 'pinEmbeddedCertificates' is FALSE and tlsCerts and/or caRootCerts contains certificates, these
 * certificates extend the system trust store (as if you had manually added them to the system trust store)
 *
 * If 'pinEmbeddedCertificates' is FALSE and only tlsCerts are present (i.e. no caRootCerts), the exact
 * behavior of SEB Windows 2.1+ is expected for backward compatibility (these are typically self-signed
 * SSL/TLS certificates being added to the trust store as they do not chain back to an OS trusted CA root)
 *
 * If 'pinEmbeddedCertificates' is TRUE and both tlsCerts and caRootCerts are empty, all HTTPS traffic will
 * be rejected (these arrays could be empty if they were filtered out during loading, e.g. due to date
 * expirations)
 *
 * If 'pinEmbeddedCertificates' is TRUE and caRootCerts are available, only these embedded CA roots can act
 * as trust anchors. If any of the embedded caRootCerts result in trust being established, HTTPS traffic
 * will be permitted, otherwise pinned tlsCerts will be checked. If tlsCerts is empty, HTTPS traffic will be
 * rejected, else each embedded SSL/TLS certificate's public key will be compared against the server SSL/TLS
 * leaf certificate public key and HTTPS traffic will be allowed if a match is detected and other evaluation
 * checks are passed (domain match, expiration, etc.)
 *
 * For compatibility, the above behavior must be exactly duplicated by any other client ports.
 *
 * SERVER CONFIGURATION
 *
 * If the server's SSL/TLS leaf cert is not directly signed by a trusted CA root cert then in addition to the
 * server's SSL/TLS leaf cert the intermediate CA certs must be sent as a bundle during SSL/TLS handshake
 * (this also applies if a private CA intermediate cert was used to sign the server's SSL/TLS cert, except
 * the private CA root cert needs to be included in 'CertificateDataDER'). If the server will be sending a
 * self-signed SSL/TLS cert then a copy of the leaf must be included in the client's 'CertificateDataDER'.
 */
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    BOOL authorized = NO;
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    
    if (serverTrust)
    {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        BOOL pinned = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_pinEmbeddedCertificates"];
        
        NSArray *trustStore = nil;
        NSMutableArray *embeddedCertificates = [NSMutableArray arrayWithArray:[preferences secureObjectForKey:@"org_safeexambrowser_SEB_embeddedCertificates"]];
        
        if (!pinned)
        {
            // Embedded SSL/TLS certs extend system trust store if
            // not pinned (these would typically be self-signed)
            [embeddedCertificates addObjectsFromArray:[jcs tlsCerts]];
        }
        
        if (pinned || [embeddedCertificates count])
        {
            trustStore = embeddedCertificates;
        }
        
        // If pinned, only embedded CA root certs will be in trust store
        // If !pinned, system trust store is extended by embedded CA root and SSL/TLS certs
        SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)trustStore); // If trustStore == nil, use system default
        SecTrustSetAnchorCertificatesOnly(serverTrust, pinned); // If pinned, only embedded CA roots are trusted, else extended system trust store
        
        SecTrustResultType result;
        OSStatus status = SecTrustEvaluate(serverTrust, &result);
        
        if (status == errSecSuccess && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified))
        {
            authorized = YES;
        }
        
        else if (pinned)
        {
            // Because the CA trust evaluation above failed, we know that the
            // server's SSL/TLS cert does not chain back to a CA root cert from
            // any embedded CA root certs (or if it did, it was deemed invalid
            // on other grounds such as expiration)
            //
            // We now need to explicitly handle the case of the user wanting to
            // pin a self-signed SSL/TLS cert. In addition to being evaluated
            // in the embedded trust store, we must have at least one embedded
            // SSL/TLS cert whose public key matches the server's SSL/TLS cert
            // (we compare against the public key because the server's cert
            // could be re-issued with the same PK but with other differences)
            embeddedCertificates = [NSMutableArray arrayWithArray:[jcs tlsCerts]];
            
            if ([embeddedCertificates count])
            {
                // Index 0 (leaf) is always present
                SecCertificateRef serverLeafCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
                
                if (serverLeafCertificate)
                {
                    NSData *serverLeafCertificateDataDER = CFBridgingRelease(SecCertificateCopyData(serverLeafCertificate));
                    
                    if (serverLeafCertificateDataDER)
                    {
                        mbedtls_x509_crt serverCert;
                        mbedtls_x509_crt_init(&serverCert);
                        
                        if (mbedtls_x509_crt_parse_der(&serverCert, [serverLeafCertificateDataDER bytes], [serverLeafCertificateDataDER length]) == 0)
                        {
#if DEBUG
                            char infoBuf[2048];
                            *infoBuf = '\0';
                            mbedtls_x509_crt_info(infoBuf, sizeof(infoBuf) - 1, "   ", &serverCert);
                            NSLog(@"Server leaf certificate:\n%s", infoBuf);
                            [serverLeafCertificateDataDER writeToFile:[NSString prefixPath:@"last_server.der" withPathType:PATHTYPE_DOCUMENTS] atomically:YES];
#endif
                            unsigned char *pkBuffer;
                            unsigned int pkBufferSize;
                            mbedtls_x509_private_seb_obtainLastPublicKeyASN1Block(&pkBuffer, &pkBufferSize);
                            
                            unsigned int serverPkBufferSize = pkBufferSize;
                            unsigned char *serverPkBuffer = malloc(serverPkBufferSize);
                            
                            if (serverPkBuffer)
                            {
                                memcpy(serverPkBuffer, pkBuffer, serverPkBufferSize);
                                
                                mbedtls_x509_crt tlsList;
                                mbedtls_x509_crt_init(&tlsList);
                                
                                for (NSInteger i = 0; i < [embeddedCertificates count]; i++)
                                {
                                    NSData *tlsData = CFBridgingRelease(SecCertificateCopyData((SecCertificateRef)[embeddedCertificates objectAtIndex:i]));
                                    
                                    if (tlsData)
                                    {
                                        if (mbedtls_x509_crt_parse_der(&tlsList, [tlsData bytes], [tlsData length]) == 0)
                                        {
                                            mbedtls_x509_private_seb_obtainLastPublicKeyASN1Block(&pkBuffer, &pkBufferSize);
                                            
                                            if (serverPkBufferSize == pkBufferSize)
                                            {
                                                if (memcmp(serverPkBuffer, pkBuffer, serverPkBufferSize) == 0)
                                                {
                                                    // We have an exact PK match with the server cert which
                                                    // means that we trust this server because it must have
                                                    // the associated private key to decrypt traffic sent
                                                    // to it. All that remains to be done is basic validation
                                                    // which we let the OS handle by evaluating a custom
                                                    // trust store.
                                                    NSArray *array = [NSArray arrayWithObject:[embeddedCertificates objectAtIndex:i]];
                                                    SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)array);
                                                    status = SecTrustEvaluate(serverTrust, &result);
                                                    
                                                    if (status == errSecSuccess && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified))
                                                    {
                                                        authorized = YES;
                                                    }
                                                    
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                mbedtls_x509_crt_free(&tlsList);
                                free(serverPkBuffer);
                            }
                        }
                        
                        mbedtls_x509_crt_free(&serverCert);
                    }
                }
            }
        }
    }
    
    if (authorized)
    {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
        [self.client URLProtocol:self didReceiveAuthenticationChallenge:challenge];
    }
    
    else
    {
        [challenge.sender cancelAuthenticationChallenge:challenge];
        [self.client URLProtocol:self didCancelAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.client URLProtocolDidFinishLoading:self];
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.client URLProtocol:self didFailWithError:error];
    self.connection = nil;
}

@end