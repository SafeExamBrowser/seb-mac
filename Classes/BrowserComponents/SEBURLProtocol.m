//
//  SEBURLProtocol.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07/04/15.
//  Updated for embedded SSL/CA cert support by Janison.
//
//

#import "SEBURLProtocol.h"
#import "SEBCertServices.h"
#include "x509_crt.h"

static const NSString *kHTTPHeaderBrowserExamKey = @"X-SafeExamBrowser-RequestHash";
static const NSString *kSEBRequestWasProcessed = @"X-SEBRequestWasProcessed";

void mbedtls_x509_private_seb_obtainLastPublicKeyASN1Block(unsigned char **block, unsigned int *len);

@interface SEBURLProtocol ()
@property (nonatomic, strong) NSURLConnection *connection;
@end

@implementation SEBURLProtocol

- (void)dealloc
{
    _connection = nil;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    if ([request.URL.scheme hasPrefix:@"http"])
    {
        if (![NSURLProtocol propertyForKey:(NSString *)kSEBRequestWasProcessed inRequest:request])
        {
            return YES;
        }
    }
    
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}


- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {

    if (response) {
        // Not sure if this "if" block is necessary, it seems not to be called anyways
        DDLogDebug(@"%s: redirect response: %@", __FUNCTION__, response);

        NSMutableURLRequest *redirect = [request mutableCopy];
        [NSURLProtocol removePropertyForKey:(NSString *)kSEBRequestWasProcessed inRequest:redirect];
        
        [self.client URLProtocol:self wasRedirectedToRequest:redirect redirectResponse:response];
        
        return redirect;
    }
    return request;
}


- (void)startLoading
{
    NSMutableURLRequest *request = [self.request mutableCopy];

    [NSURLProtocol setProperty:@YES forKey:(NSString *)kSEBRequestWasProcessed inRequest:request];
    
//    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:self.request];
//    if (cachedResponse) {
//        [self connection:nil didReceiveResponse:[cachedResponse response]];
//        [self connection:nil didReceiveData:[cachedResponse data]];
//        [self connectionDidFinishLoading:nil];
//    } else {
        _connection = [NSURLConnection connectionWithRequest:request delegate:self];
//    }
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
 * SEB internally maintains two arrays of SecCertificateRef certificate objects, tlsCerts and caCerts.
 * These are populated by parsing the SEB config file key 'embeddedCertificates/certificateDataWin'.
 *
 * The handling of these certs depends on the setting of 'pinEmbeddedCertificates' in the SEB config file.
 *
 * Pinning can be used as an additional layer of security to decrease the MITM attack surface by avoiding
 * the use of CA roots which are included in the OS trust store for which there is no legitimate reason
 * to actually trust them because the server endpoint's CA is known to us and its root cert (and intermediate
 * CA certs, if applicable) are embedded. Pinning can also be performed directly against an SSL/TLS server
 * cert (usually self-signed) for which we have prior knowledge of the public key (this cert must also
 * be embedded for matching purposes)
 *
 * If 'pinEmbeddedCertificates' is FALSE and both tlsCerts and caCerts are empty, the standard OS trust
 * store behavior applies.
 *
 * If 'pinEmbeddedCertificates' is FALSE and tlsCerts and/or caCerts contains certificates, these
 * certificates extend the system trust store (as if you had manually added them to the system trust store)
 *
 * If 'pinEmbeddedCertificates' is FALSE and only tlsCerts are present (i.e. no caCerts), the exact
 * behavior of SEB Windows 2.1+ is expected for backward compatibility (these are typically self-signed
 * SSL/TLS certificates being added to the trust store as they do not chain back to an OS trusted CA root)
 *
 * If 'pinEmbeddedCertificates' is TRUE and both tlsCerts and caCerts are empty, all HTTPS traffic will
 * be rejected (these arrays could be empty if they were filtered out during loading, e.g. due to date
 * expirations)
 *
 * If 'pinEmbeddedCertificates' is TRUE and caCerts are available, only the embedded CA roots can act
 * as trust anchors. If any of the embedded root caCerts result in trust being established, HTTPS traffic
 * will be permitted otherwise pinned tlsCerts will be checked. If tlsCerts is empty, HTTPS traffic will be
 * rejected, else each embedded SSL/TLS certificate's public key will be compared against the server SSL/TLS
 * leaf certificate public key and HTTPS traffic will be allowed if a match is detected and other evaluation
 * checks are passed (domain match, expiration, etc.)
 *
 * For compatibility, the above behavior must be exactly duplicated by other client ports.
 *
 * SERVER CONFIGURATION
 *
 * If the server's SSL/TLS leaf cert is not directly signed by a trusted CA root cert then in addition to the
 * server's SSL/TLS leaf cert the intermediate CA certs must be sent as a bundle during SSL/TLS handshake
 * (this also applies if a private CA intermediate cert was used to sign the server's SSL/TLS cert, except
 * the private CA root cert needs to be embedded). If the server will be sending a self-signed SSL/TLS cert
 * then a copy of the leaf cert must be embedded in the client's config file.
 */
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    BOOL authorized = NO;
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    
    if (serverTrust)
    {
        SEBCertServices *sc = [SEBCertServices sharedInstance];
        
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        BOOL pinned = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_pinEmbeddedCertificates"];
        
        NSArray *trustStore = nil;
        NSMutableArray *embeddedCertificates = [NSMutableArray arrayWithArray:[sc caCerts]];
        
        if (!pinned)
        {
            // Embedded SSL/TLS certs extend system trust store if
            // not pinned (these would typically be self-signed)
            [embeddedCertificates addObjectsFromArray:[sc tlsCerts]];
        }
        
        if (pinned || [embeddedCertificates count])
        {
            trustStore = embeddedCertificates;
        }
        
        // If pinned, only embedded CA certs will be in trust store
        // If !pinned, system trust store is extended by embedded CA and SSL/TLS certs
        SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)trustStore); // If trustStore == nil, use system default
        SecTrustSetAnchorCertificatesOnly(serverTrust, pinned);
        
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
            // on other grounds such as expiration, or required private
            // intermediate CA certs were not included in caCerts)
            //
            // We now need to explicitly handle the case of the user wanting to
            // pin a (usually self-signed) SSL/TLS cert. For this, we must have
            // an embedded SSL/TLS cert whose public key matches the server's
            // SSL/TLS cert (we compare against the public key because the
            // server's cert could be re-issued with the same PK but with other
            // differences)
            embeddedCertificates = [NSMutableArray arrayWithArray:[sc tlsCerts]];
            
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
                            [serverLeafCertificateDataDER writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"last_server.der"] atomically:YES];
#endif
                            unsigned char *pkBuffer;
                            unsigned int pkBufferSize;
                            
                            // We're extracting the SPKI, not just the PK bit string.
                            // This is an additional level of security. See here:
                            // https://www.imperialviolet.org/2011/05/04/pinning.html
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
                                                    // such as domain and expiration checks which we let the
                                                    // OS handle by evaluating a custom trust store.
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
        DDLogWarn(@"%s: didReceiveAuthenticationChallenge", __FUNCTION__);

        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
        [self.client URLProtocol:self didReceiveAuthenticationChallenge:challenge];
    }
    
    else
    {
        DDLogWarn(@"%s: didCancelAuthenticationChallenge", __FUNCTION__);

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
