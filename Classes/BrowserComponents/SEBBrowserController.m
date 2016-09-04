//
//  SEBBrowserController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 22/01/16.
//
//

#import "SEBBrowserController.h"
#import "CustomHTTPProtocol.h"
#import "SEBCertServices.h"
#include "x509_crt.h"

static const NSString *kHTTPHeaderBrowserExamKey = @"X-SafeExamBrowser-RequestHash";
static const NSString *kSEBRequestWasProcessed = @"X-SEBRequestWasProcessed";

void mbedtls_x509_private_seb_obtainLastPublicKeyASN1Block(unsigned char **block, unsigned int *len);

@interface SEBBrowserController () <CustomHTTPProtocolDelegate>

@property (nonatomic, strong) CustomHTTPProtocol *authenticatingProtocol;
@property (nonatomic, strong) NSString *lastUsername;

@end

@implementation SEBBrowserController

// Initialize and register as delegate for custom URL protocol
- (instancetype)init
{
    self = [super init];
    if (self) {
        // Activate the custom URL protocol if necessary (embedded certs or pinning available)
        [self conditionallyInitCustomHTTPProtocol];
    }
    return self;
}


// Save the default user agent of the installed WebKit version
- (void) createSEBUserAgentFromDefaultAgent:(NSString *)defaultUserAgent
{
    // Get WebKit version number string to use it as Safari version
    NSRange webKitSubstring = [defaultUserAgent rangeOfString:@"AppleWebKit/"];
    NSString *webKitVersion;
    if (webKitSubstring.location != NSNotFound && (webKitSubstring.location + webKitSubstring.length) < defaultUserAgent.length) {
        webKitVersion = [defaultUserAgent substringFromIndex:webKitSubstring.location + webKitSubstring.length];
        webKitVersion = [[webKitVersion stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]  componentsSeparatedByString:@" "][0];
    } else {
        webKitVersion = SEBUserAgentDefaultSafariVersion;
    }
    
    defaultUserAgent = [defaultUserAgent stringByAppendingString:[NSString stringWithFormat:@" %@/%@", SEBUserAgentDefaultBrowserSuffix, webKitVersion]];
    [[MyGlobals sharedMyGlobals] setValue:defaultUserAgent forKey:@"defaultUserAgent"];
}


-(void) conditionallyInitCustomHTTPProtocol
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    SEBCertServices *sharedCertService = [SEBCertServices sharedInstance];

    // Flush cached embedded certificates (as they might have changed with new settings)
    [sharedCertService flushCachedCertificates];

    // Check if the custom URL protocol needs to be activated
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_pinEmbeddedCertificates"]
        || [sharedCertService caCerts].count > 0
        || [sharedCertService tlsCerts].count > 0
        || [sharedCertService debugCerts].count > 0)
    {
        _usingCustomURLProtocol = true;
        // Become delegate of and register custom SEB NSURL protocol class
        [CustomHTTPProtocol setDelegate:self];
        [CustomHTTPProtocol start];
    } else {
        _usingCustomURLProtocol = false;
        // Deactivate the protocol
        [CustomHTTPProtocol stop];
    }
}


- (BOOL)customHTTPProtocol:(CustomHTTPProtocol *)protocol canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    assert(protocol != nil);
#pragma unused(protocol)
    assert(protectionSpace != nil);
    
    // We accept any username/password and server trust authentication challenges.
    NSString *authenticationMethod = protectionSpace.authenticationMethod;
    
    return [authenticationMethod isEqual:NSURLAuthenticationMethodHTTPBasic] ||
    [authenticationMethod isEqual:NSURLAuthenticationMethodHTTPDigest] ||
    [authenticationMethod isEqual:NSURLAuthenticationMethodNTLM] ||
    [authenticationMethod isEqual:NSURLAuthenticationMethodServerTrust];
}



/*
 * CLIENT CONFIGURATION
 *
 * SEB internally maintains two arrays of SecCertificateRef certificate objects, tlsCerts and caCerts.
 * These are populated by parsing the SEB config file key 'embeddedCertificates/certificateDataBase64' or 'certificateDataWin'.
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
 * If 'pinEmbeddedCertificates' is FALSE and tlsCerts, debugCerts and caCerts are empty, the standard
 * OS trust store behavior applies.
 *
 * If 'pinEmbeddedCertificates' is FALSE and tlsCerts, debugCerts and/or caCerts contains certificates, these
 * certificates extend the system trust store (as if you had manually added them to the system trust store)
 *
 * If 'pinEmbeddedCertificates' is FALSE and only tlsCerts are present (i.e. no caCerts), the exact
 * behavior of SEB Windows 2.1+ is expected for backward compatibility (these are typically self-signed
 * SSL/TLS certificates being added to the trust store as they do not chain back to an OS trusted CA root)
 *
 * If 'pinEmbeddedCertificates' is TRUE and tlsCerts, debugCerts and caCerts are empty, all HTTPS traffic will
 * be rejected (these arrays could be empty if they were filtered out during loading, e.g. due to date
 * expirations, except debugCerts which are not checked for expiration)
 *
 * If 'pinEmbeddedCertificates' is TRUE and caCerts are available, only the embedded CA roots can act
 * as trust anchors. If any of the embedded root caCerts result in trust being established, HTTPS traffic
 * will be permitted otherwise pinned tlsCerts/debugCerts will be checked. If tlsCerts and debugCerts is empty,
 * HTTPS traffic will be rejected, else each embedded SSL/TLS certificate's public key will be compared against
 * the server SSL/TLS leaf certificate public key and HTTPS traffic will be allowed if a match is detected and
 * other evaluation checks are passed (domain match, expiration, etc.) in case of tlsCerts.
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
- (void)customHTTPProtocol:(CustomHTTPProtocol *)protocol didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    // Check if we deal with a username/password or a server trust authentication challenge
    NSString *authenticationMethod = challenge.protectionSpace.authenticationMethod;
    if ([authenticationMethod isEqual:NSURLAuthenticationMethodHTTPBasic] ||
        [authenticationMethod isEqual:NSURLAuthenticationMethodHTTPDigest] ||
        [authenticationMethod isEqual:NSURLAuthenticationMethodNTLM])
    {
        DDLogDebug(@"%s: authentication challenge method: %@", __FUNCTION__, authenticationMethod);
        _authenticatingProtocol = protocol;
        _pendingChallenge = challenge;

        // Allow to enter password 3 times
        if ([challenge previousFailureCount] < 3) {
            // Display authentication dialog
//            _pendingChallenge = challenge;
            
            NSString *text = [NSString stringWithFormat:@"%@://%@", challenge.protectionSpace.protocol, challenge.protectionSpace.host];
            if ([challenge previousFailureCount] == 0) {
                text = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"To proceed, you must log in to", nil), text];
                _lastUsername = @"";
            } else {
                text = [NSString stringWithFormat:NSLocalizedString(@"The user name or password you entered for %@ was incorrect. Make sure you’re entering them correctly, and then try again.", nil), text];
            }
            
            [self.delegate showEnterUsernamePasswordDialog:text
                                                     title:NSLocalizedString(@"Authentication Required", nil)
                                                  username:_lastUsername
                                             modalDelegate:self
                                            didEndSelector:@selector(enteredUsername:password:returnCode:)];
            
        } else {
            [challenge.sender cancelAuthenticationChallenge:challenge];
            // inform the user that the user name and password
            // in the preferences are incorrect
        }
    } else {
        // Server trust authentication challenge
        
        BOOL authorized = NO;
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        NSURLCredential *credential;
        
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
                
                // Also add embedded debug certs, which we also use to extend
                // the system trust store (note: they might fail the first check
                // because of expiration or common name/alternative names not
                // matching domain
                [embeddedCertificates addObjectsFromArray:[sc debugCerts]];
            }
            
            if (pinned || [embeddedCertificates count])
            {
                trustStore = embeddedCertificates;
            }
            
            // If pinned, only embedded CA certs will be in trust store
            // If !pinned, system trust store is extended by embedded CA and SSL/TLS (including debug) certs
            SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)trustStore); // If trustStore == nil, use system default
            SecTrustSetAnchorCertificatesOnly(serverTrust, pinned);
            
            SecTrustResultType result;
            OSStatus status = SecTrustEvaluate(serverTrust, &result);
            
            if (status == errSecSuccess && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified))
            {
                authorized = YES;
                
            } else {
                // Because the CA trust evaluation above failed, we know that the
                // server's SSL/TLS cert does not chain back to a CA root cert from
                // any embedded CA root certs (or if it did, it was deemed invalid
                // on other grounds such as expiration, or required private
                // intermediate CA certs were not included in caCerts)
                //
                // We now need to explicitly handle the case of the user wanting to
                // pin a (usually self-signed) SSL/TLS cert or use a debug cert which
                // can be expired or issued for another server domain (in the debug case
                // we check if the server domain matches the debug cert's "name" field.
                // For this check, we must have
                // an embedded SSL/TLS cert whose public key matches the server's
                // SSL/TLS cert (we compare against the public key because the
                // server's cert could be re-issued with the same PK but with other
                // differences)
                
                // Use embedded debug certs if some are available
                embeddedCertificates = [NSMutableArray arrayWithArray:[sc debugCerts]];
                NSInteger debugCertsCount = embeddedCertificates.count;
                NSArray *debugCertNames = [sc debugCertNames];
                
                // Add regular TLS certs
                [embeddedCertificates addObjectsFromArray:[sc tlsCerts]];
                
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
                                    // Now we have the public key bytes in serverPkBuffer
                                    
                                    mbedtls_x509_crt tlsList;
                                    mbedtls_x509_crt_init(&tlsList);
                                    
                                    NSString *serverHost = challenge.protectionSpace.host;
                                    NSInteger serverPort = challenge.protectionSpace.port;
#if DEBUG
                                    NSLog(@"Server host: %@ and port: %ld", serverHost, (long)serverPort);
#endif
                                    
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
                                                            // If the cert didn't pass this basic validation
                                                        } else if (i < debugCertsCount) {
                                                            // and it is a debug cert, check if server domain (host:port) matches the "name" subkey of this embedded debug cert
                                                            NSString *debugCertOverrideURLString = debugCertNames[i];
                                                            
                                                            // Check if filter expression contains a scheme
                                                            if (debugCertOverrideURLString.length > 0) {
                                                                // We can abort if there is no override domain for the cert
                                                                NSRange scanResult = [debugCertOverrideURLString rangeOfString:@"://"];
                                                                if (scanResult.location == NSNotFound) {
                                                                    // Filter expression doesn't contain a scheme, prefix it with a https:// scheme
                                                                    debugCertOverrideURLString = [NSString stringWithFormat:@"https://%@", debugCertOverrideURLString];
                                                                    // Convert override domain string to a NSURL
                                                                }
                                                                NSURL *debugCertOverrideURL = [NSURL URLWithString:debugCertOverrideURLString];
                                                                if (debugCertOverrideURL) {
                                                                    // If certificate doesn't have any correct override domain in its name field, abort
                                                                    NSString *host = debugCertOverrideURL.host;
                                                                    NSNumber *port = debugCertOverrideURL.port;
#if DEBUG
                                                                    NSLog(@"Cert host: %@ and port: %@", host, port);
#endif
                                                                    if ([host isEqualToString:serverHost]) {
                                                                        // If the server host name matches the one in the debug cert ...
                                                                        if (!port || port.integerValue == serverPort) {
                                                                            // ... and there either is not port indicated in the cert
                                                                            // or it is same as the one of the server we're connecting to, we accept it
                                                                            authorized = YES;
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
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
            
            credential = [NSURLCredential credentialForTrust:serverTrust];
            [protocol resolveAuthenticationChallenge:challenge withCredential:credential];
            
        } else {
            
            DDLogWarn(@"%s: didCancelAuthenticationChallenge", __FUNCTION__);
            
            [challenge.sender cancelAuthenticationChallenge:challenge];
        }
    }
}

// We don't need to implement -customHTTPProtocol:didCancelAuthenticationChallenge: because we always resolve
// the challenge synchronously within -customHTTPProtocol:didReceiveAuthenticationChallenge:.


- (void)enteredUsername:(NSString *)username password:(NSString *)password returnCode:(NSInteger)returnCode
{
    DDLogDebug(@"Enter username password sheetDidEnd with return code: %ld", (long)returnCode);
    
    if (_authenticatingProtocol) {
        if (returnCode == SEBEnterPasswordOK) {
            _lastUsername = username;
            NSURLCredential *newCredential;
            newCredential = [NSURLCredential credentialWithUser:username
                                                       password:password
                                                    persistence:NSURLCredentialPersistenceForSession];
            [_authenticatingProtocol resolveAuthenticationChallenge:_authenticatingProtocol.pendingChallenge withCredential:newCredential];
            _authenticatingProtocol = nil;
        } else if (returnCode == SEBEnterPasswordCancel) {
//            [_authenticatingProtocol performSelectorOnMainThread:@selector(stopLoading)
//                                                            withObject:NULL waitUntilDone:YES];
            if (_pendingChallenge == _authenticatingProtocol.pendingChallenge) {
                DDLogDebug(@"_pendingChallenge is same as _authenticatingProtocol.pendingChallenge");
            } else {
                DDLogDebug(@"_pendingChallenge is not same as _authenticatingProtocol.pendingChallenge");
            }
            [[_pendingChallenge sender] cancelAuthenticationChallenge:_pendingChallenge];

            _authenticatingProtocol = nil;
        } else {
            // Any other case as when the server aborted the authentication challenge
            _authenticatingProtocol = nil;
        }
    }
}


- (void)customHTTPProtocol:(CustomHTTPProtocol *)protocol didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    DDLogWarn(@"%s", __FUNCTION__);
    [_delegate hideEnterUsernamePasswordDialog];
}


@end
