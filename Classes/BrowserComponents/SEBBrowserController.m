//
//  SEBBrowserController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 22/01/16.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): dmcd, Copyright (c) 2015-2016 Janison
//

#import "SEBBrowserController.h"
#import "CustomHTTPProtocol.h"
#import "SEBCertServices.h"
#include "x509_crt.h"

void mbedtls_x509_private_seb_obtainLastPublicKeyASN1Block(unsigned char **block, unsigned int *len);

static NSString * const authenticationHost = @"host";
static NSString * const authenticationUsername = @"username";
static NSString * const authenticationPassword = @"password";

@interface SEBBrowserController () <CustomHTTPProtocolDelegate> {
    NSMutableArray *authorizedHosts;
    NSMutableArray *previousAuthentications;
}

@property (nonatomic, strong) CustomHTTPProtocol *authenticatingProtocol;
@property (nonatomic, strong) NSString *lastUsername;

@end

@implementation SEBBrowserController

// Initialize and register as delegate for custom URL protocol
- (instancetype)init
{
    self = [super init];
    if (self) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        quitURLTrimmed = [[preferences secureStringForKey:@"org_safeexambrowser_SEB_quitURL"] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        sendHashKeys = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"];
        downloadPDFFiles = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadPDFFiles"];
        self.browserExamKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
        self.configKey = [preferences secureObjectForKey:@"org_safeexambrowser_configKey"];
        self.browserExamKeySalt = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_examKeySalt"];
    }
    return self;
}

- (NSData *)browserExamKey
{
    if (!_browserExamKey) {
        self.browserExamKey = [[NSUserDefaults standardUserDefaults] secureObjectForKey:@"org_safeexambrowser_currentData"];
    }
    return _browserExamKey;
}

- (NSData *)configKey
{
    if (!_configKey) {
        self.configKey = [[NSUserDefaults standardUserDefaults] secureObjectForKey:@"org_safeexambrowser_configKey"];
    }
    return _configKey;
}

/// Save the default user agent of the installed WebKit version
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


// Create browser user agent according to settings
- (NSString*) customSEBUserAgent
{
    if (!_customSEBUserAgent) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSString* versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
        NSString *overrideUserAgent;
        NSString *browserUserAgentSuffix = [[preferences secureStringForKey:@"org_safeexambrowser_SEB_browserUserAgent"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (browserUserAgentSuffix.length != 0) {
            browserUserAgentSuffix = [NSString stringWithFormat:@" %@", browserUserAgentSuffix];
        }
        
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserUserAgentiOS"] == browserUserAgentModeiOSDefault) {
            overrideUserAgent = [[MyGlobals sharedMyGlobals] valueForKey:@"defaultUserAgent"];
        } else if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserUserAgentiOS"] == browserUserAgentModeiOSMacDesktop) {
            overrideUserAgent = SEBiOSUserAgentDesktopMac;
        } else {
            overrideUserAgent = [preferences secureStringForKey:@"org_safeexambrowser_SEB_browserUserAgentiOSCustom"];
        }
        // Add "SEB <version number>" to the browser's user agent, so the LMS SEB plugins recognize us
        overrideUserAgent = [overrideUserAgent stringByAppendingString:[NSString stringWithFormat:@" %@/%@%@", SEBUserAgentDefaultSuffix, versionString, browserUserAgentSuffix]];
        _customSEBUserAgent = overrideUserAgent;
    }
    return _customSEBUserAgent;
}


@synthesize wkWebViewConfiguration;

- (WKWebViewConfiguration *)wkWebViewConfiguration
{
    WKWebViewConfiguration *newSharedWebViewConfiguration = [WKWebViewConfiguration new];
    
    // Set media playback properties on new webview
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (@available(macOS 10.12, *)) {
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserMediaAutoplay"] == NO) {
            newSharedWebViewConfiguration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;
        } else {
            newSharedWebViewConfiguration.mediaTypesRequiringUserActionForPlayback =
            (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserMediaAutoplayAudio"] ? WKAudiovisualMediaTypeAudio : 0) |
            (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserMediaAutoplayVideo"] ? WKAudiovisualMediaTypeVideo : 0);
        }
    }
    
    UIUserInterfaceIdiom currentDevice = UIDevice.currentDevice.userInterfaceIdiom;
    if (currentDevice == UIUserInterfaceIdiomPad) {
        newSharedWebViewConfiguration.allowsInlineMediaPlayback = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileAllowInlineMediaPlayback"];
    } else {
        newSharedWebViewConfiguration.allowsInlineMediaPlayback = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileCompactAllowInlineMediaPlayback"];
    }
    newSharedWebViewConfiguration.allowsPictureInPictureMediaPlayback = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileAllowPictureInPictureMediaPlayback"];
    
    if (@available(macOS 10.11, *)) {
        newSharedWebViewConfiguration.allowsAirPlayForMediaPlayback = NO;
    }
    newSharedWebViewConfiguration.dataDetectorTypes = WKDataDetectorTypeNone;
    
    return newSharedWebViewConfiguration;
}



- (NSString *) urlOrPlaceholderForURL:(NSString *)url
{
    NSString *urlOrPlaceholder = [self.delegate showURLplaceholderTitleForWebpage];
    return urlOrPlaceholder ? urlOrPlaceholder : url;
}


- (NSString *) startURLQueryParameter:(NSURL**)url
{
    // Check URL for additional query string
    NSString *startURLQueryParameter = nil;
    NSString *queryString = (*url).query;
    if (queryString.length > 0) {
        NSArray *additionalQueryStrings = [queryString componentsSeparatedByString:@"?"];
        // There is an additional query string if the full query URL component itself containts
        // a query separator character "?"
        if (additionalQueryStrings.count == 2) {
            // Cache the additional query string for later use
            startURLQueryParameter = additionalQueryStrings.lastObject;
            // Replace the full query string in the download URL with the first query component
            // (which is the actual query of the SEB config download URL)
            queryString = additionalQueryStrings.firstObject;
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:*url resolvingAgainstBaseURL:NO];
            if (queryString.length == 0) {
                queryString = nil;
            }
            urlComponents.query = queryString;
            *url = urlComponents.URL;
        }
    }

    return startURLQueryParameter;
}


- (NSString *) backToStartURLString
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString* backToStartURL;
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamUseStartURL"]) {
        // Check if SEB Server started the exam and we have its Start URL
        if (_sebServerExamStartURL) {
            backToStartURL = _sebServerExamStartURL.absoluteString;
        } else {
            // Load start URL from the system's user defaults
            backToStartURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
        }
        DDLogInfo(@"Will load Start URL in main browser window: %@", [self urlOrPlaceholderForURL:backToStartURL]);
    } else {
        backToStartURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamURL"];
        DDLogInfo(@"Will load Back to Start URL in main browser window: %@", [self urlOrPlaceholderForURL:backToStartURL]);
    }
    return backToStartURL;
}


-(void) conditionallyInitCustomHTTPProtocol
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    SEBCertServices *sharedCertService = [SEBCertServices sharedInstance];
    authorizedHosts = [NSMutableArray new];
    previousAuthentications = [NSMutableArray new];
    pinEmbeddedCertificates = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_pinEmbeddedCertificates"];

    // Flush cached embedded certificates (as they might have changed with new settings)
    [sharedCertService flushCachedCertificates];
    
    // Check if the custom URL protocol needs to be activated
#if TARGET_OS_IPHONE
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"]
        || pinEmbeddedCertificates
        || [sharedCertService caCerts].count > 0
        || [sharedCertService tlsCerts].count > 0
        || [sharedCertService debugCerts].count > 0)
#else
        if (pinEmbeddedCertificates
            || [sharedCertService caCerts].count > 0
            || [sharedCertService tlsCerts].count > 0
            || [sharedCertService debugCerts].count > 0)
#endif
    {
        // macOS 10.7 and 10.8: Custom URL protocol isn't supported
        if (@available(macOS 9, *)) {
        } else {
            DDLogError(@"When running on OS X 10.7 or 10.8, embedded TLS/SSL/CA certificates and certificate pinning are not supported!");
            return;
        }
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
#if DEBUG
        NSString *server = [NSString stringWithFormat:@"%@://%@", challenge.protectionSpace.protocol, challenge.protectionSpace.host];
        DDLogDebug(@"Server which requires authentication: %@", server);
#endif
        _authenticatingProtocol = protocol;
        _pendingChallenge = challenge;
        
        NSString *host = challenge.protectionSpace.host;
        NSDictionary *previousAuthentication = [self fetchPreviousAuthenticationForHost:host];
        if (previousAuthentication) {
            NSURLCredential *newCredential;
            newCredential = [NSURLCredential credentialWithUser:[previousAuthentication objectForKey:authenticationUsername]
                                                       password:[previousAuthentication objectForKey:authenticationPassword]
                                                    persistence:NSURLCredentialPersistenceForSession];
            [_authenticatingProtocol resolveAuthenticationChallenge:_authenticatingProtocol.pendingChallenge withCredential:newCredential];
            _authenticatingProtocol = nil;
            return;
        }
        // Allow to enter password 3 times
        if ([challenge previousFailureCount] < 3) {
            // Display authentication dialog
            //            _pendingChallenge = challenge;
            
            NSString *text = [self.delegate showURLplaceholderTitleForWebpage];
            if (!text) {
                text = [NSString stringWithFormat:@"%@://%@", challenge.protectionSpace.protocol, host];
            } else {
                if ([challenge.protectionSpace.protocol isEqualToString:@"https"]) {
                    text = [NSString stringWithFormat:@"%@ (secure connection)", text];
                } else {
                    text = [NSString stringWithFormat:@"%@ (insecure connection!)", text];
                }
            }
            if ([challenge previousFailureCount] == 0) {
                text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Log in to", nil), text];
                _lastUsername = @"";
            } else {
                text = [NSString stringWithFormat:NSLocalizedString(@"The user name or password for %@ was incorrect. Please try again.", nil), text];
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
        NSString *serverHost = challenge.protectionSpace.host;
        NSInteger serverPort = challenge.protectionSpace.port;

        if (serverTrust)
        {
            SEBCertServices *sc = [SEBCertServices sharedInstance];
            
            NSArray *trustStore = nil;
            NSMutableArray *embeddedCertificates = [NSMutableArray arrayWithArray:[sc caCerts]];
            
            if (!pinEmbeddedCertificates)
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
            
            if (pinEmbeddedCertificates || [embeddedCertificates count])
            {
                trustStore = embeddedCertificates;
            }
            
            // If pinned, only embedded CA certs will be in trust store
            // If !pinned, system trust store is extended by embedded CA and SSL/TLS (including debug) certs
            SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)trustStore); // If trustStore == nil, use system default
            SecTrustSetAnchorCertificatesOnly(serverTrust, pinEmbeddedCertificates);
            
            SecTrustResultType result;
            OSStatus status = SecTrustEvaluate(serverTrust, &result);
            
#if DEBUG
            DDLogDebug(@"Server host: %@ and port: %ld", serverHost, (long)serverPort);
#endif

            if (status == errSecSuccess && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified))
            {
                authorized = YES;
                if (![authorizedHosts containsObject:serverHost]) {
                    [authorizedHosts addObject:serverHost];
                }
                
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
                
                // First check if not authorized domain is
                // a subdomain of a previously trused domain
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ contains[c] SELF", serverHost];
                NSArray *results = [authorizedHosts filteredArrayUsingPredicate:predicate];
                if (results.count > 0) {
                    authorized = YES;
                } else {
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
                                    DDLogDebug(@"Server leaf certificate:\n%s", infoBuf);
                                    [serverLeafCertificateDataDER writeToFile:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                                                                               stringByAppendingPathComponent:@"last_server.der"] atomically:YES];
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
                                                                        NSString *certHost = debugCertOverrideURL.host;
                                                                        NSNumber *certPort = debugCertOverrideURL.port;
#if DEBUG
                                                                        DDLogDebug(@"Cert host: %@ and port: %@", certHost, certPort);
#endif
                                                                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self LIKE %@", certHost];
                                                                        if ([predicate evaluateWithObject:serverHost]) {
                                                                            // If the server host name matches the one in the debug cert ...
                                                                            if (!certPort || certPort.integerValue == serverPort) {
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
        }
        
        if (authorized)
        {
            DDLogDebug(@"%s: didReceiveAuthenticationChallenge", __FUNCTION__);
            
            credential = [NSURLCredential credentialForTrust:serverTrust];
            [protocol resolveAuthenticationChallenge:challenge withCredential:credential];
            
        } else {
            
            DDLogWarn(@"%s: didCancelAuthenticationChallenge for host: %@ and port: %ld", __FUNCTION__, serverHost, (long)serverPort);
            
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
            NSString *host = _pendingChallenge.protectionSpace.host;
            NSDictionary *newAuthentication = @{ authenticationHost : host, authenticationUsername : username, authenticationPassword : password};
            BOOL found = NO;
            for (NSUInteger i=0; i < previousAuthentications.count; i++) {
                NSDictionary *previousAuthentication = previousAuthentications[i];
                if ([[previousAuthentication objectForKey:authenticationHost] isEqualToString:host]) {
                    previousAuthentications[i] = newAuthentication;
                    found = YES;
                    break;
                }
            }
            if (!found) {
                [previousAuthentications addObject:newAuthentication];
            }
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


- (NSDictionary *)fetchPreviousAuthenticationForHost:(NSString *)host
{
    NSString *predicateString = [[NSString stringWithFormat:@"%@ contains[c] ", authenticationHost] stringByAppendingString:@"%@"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateString, host];
    NSArray *results = [previousAuthentications filteredArrayUsingPredicate:predicate];
    if (results.count == 1) {
        return results[0];
    } else {
        return nil;
    }
}


- (void)customHTTPProtocol:(CustomHTTPProtocol *)protocol didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    DDLogWarn(@"%s", __FUNCTION__);
    [_delegate hideEnterUsernamePasswordDialog];
}


static NSString *urlStrippedFragment(NSURL* url)
{
    NSString *absoluteRequestURL = url.absoluteString;
    
    NSString *fragment = url.fragment;
    NSString *requestURLStrippedFragment;
    if (fragment.length) {
        // if there is a fragment
        requestURLStrippedFragment = [absoluteRequestURL substringToIndex:absoluteRequestURL.length - fragment.length - 1];
    } else requestURLStrippedFragment = absoluteRequestURL;
    DDLogVerbose(@"Full absolute request URL: %@", absoluteRequestURL);
    DDLogVerbose(@"Request URL used to calculate RequestHash: %@", requestURLStrippedFragment);
    return requestURLStrippedFragment;
}


- (NSURLRequest *)modifyRequest:(NSURLRequest *)request
{
    NSURL *url = request.URL;
    
    //// Check if quit URL has been clicked (regardless of current URL Filter)
    
    // Trim a possible trailing slash "/"    
    NSString *absoluteRequestURLTrimmed = [url.absoluteString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];

    if ([absoluteRequestURLTrimmed isEqualToString:quitURLTrimmed]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"quitLinkDetected" object:self];
    }
    

    NSDictionary *headerFields;
    headerFields = [request allHTTPHeaderFields];
    DDLogVerbose(@"All HTTP header fields: %@", headerFields);
    
//    if ([request valueForHTTPHeaderField:@"Origin"].length == 0) {
//        return request;
//    }
    
    if (sendHashKeys) {
        
        NSMutableURLRequest *modifiedRequest = [request mutableCopy];

        // Browser Exam Key
        
        [modifiedRequest setValue:[self browserExamKeyForURL:url] forHTTPHeaderField:SEBBrowserExamKeyHeaderKey];
        
        // Config Key
        
        [modifiedRequest setValue:[self configKeyForURL:url] forHTTPHeaderField:SEBConfigKeyHeaderKey];
        
        headerFields = [modifiedRequest allHTTPHeaderFields];
        DDLogVerbose(@"All HTTP header fields in modified request: %@", headerFields);
        
        return [modifiedRequest copy];

    } else {

        return request;
    }
}


- (NSString *) browserExamKeyForURL:(NSURL *)url
{
        unsigned char hashedChars[32];
        [self.browserExamKey getBytes:hashedChars length:32];
        
#ifdef DEBUG
        DDLogVerbose(@"Current Browser Exam Key: %@", self.browserExamKey);
#endif

        NSMutableString* browserExamKeyString = [[NSMutableString alloc] initWithString:urlStrippedFragment(url)];
        for (NSUInteger i = 0 ; i < 32 ; ++i) {
            [browserExamKeyString appendFormat: @"%02x", hashedChars[i]];
        }
#ifdef DEBUG
        DDLogVerbose(@"Current request URL + Browser Exam Key: %@", browserExamKeyString);
#endif
        const char *urlString = [browserExamKeyString UTF8String];
        CC_SHA256(urlString,
                  (uint)strlen(urlString),
                  hashedChars);
        
        NSMutableString* hashedString = [[NSMutableString alloc] initWithCapacity:32];
        for (NSUInteger i = 0 ; i < 32 ; ++i) {
            [hashedString appendFormat: @"%02x", hashedChars[i]];
        }
    return hashedString;
}


- (NSString *) configKeyForURL:(NSURL *)url
{
    unsigned char hashedChars[32];

    [self.configKey getBytes:hashedChars length:32];
    
#ifdef DEBUG
    DDLogVerbose(@"Current Config Key: %@", self.configKey);
#endif
    
    NSMutableString* configKeyString = [[NSMutableString alloc] initWithString:urlStrippedFragment(url)];
    for (NSUInteger i = 0 ; i < 32 ; ++i) {
        [configKeyString appendFormat: @"%02x", hashedChars[i]];
    }
#ifdef DEBUG
    DDLogVerbose(@"Current request URL + Config Key: %@", configKeyString);
#endif
    const char *urlString = [configKeyString UTF8String];
    CC_SHA256(urlString,
              (uint)strlen(urlString),
              hashedChars);
    
    NSMutableString* hashedConfigKeyString = [[NSMutableString alloc] initWithCapacity:32];
    for (NSUInteger i = 0 ; i < 32 ; ++i) {
        [hashedConfigKeyString appendFormat: @"%02x", hashedChars[i]];
    }
    return hashedConfigKeyString;
}


- (void)customHTTPProtocol:(CustomHTTPProtocol *)protocol logWithFormat:(NSString *)format arguments:(va_list)arguments;
{
    NSString *message = [[NSString alloc] initWithFormat:format arguments:arguments];
    DDLogVerbose(@"%@", message);
}


// Called by the CustomHTTPProtocol class to let the delegate know that a regular HTTP request
// or a XMLHttpRequest (XHR) successfully completed loading. The delegate can use this callback
// for example to scan the newly received HTML data
- (void)sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task
{
    [_delegate sessionTaskDidCompleteSuccessfully:task];
}


// Check if reconfiguring is allowed depending on settings and referrer URL (if one is passed)
- (BOOL) isReconfiguringAllowedFromURL:(NSURL *)url
{
    // If a quit password is set (= running in exam session),
    // then check if the reconfigure config file URL matches the setting
    // examSessionReconfigureConfigURL (where the wildcard character '*' can be used)
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL secureSession = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length > 0;
    BOOL secureSessionReconfigureAllow = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_examSessionReconfigureAllow"];
    BOOL secureSessionReconfigureURLMatch = NO;
    if (url && secureSession && secureSessionReconfigureAllow) {
        NSString *sebConfigURLString = url.absoluteString;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self LIKE %@", [preferences secureStringForKey:@"org_safeexambrowser_SEB_examSessionReconfigureConfigURL"]];
        secureSessionReconfigureURLMatch = [predicate evaluateWithObject:sebConfigURLString];
    }
    // Check if SEB is in exam mode (= quit password is set) and exam is running,
    // but reconfiguring is allowed by setting and the reconfigure config URL matches the setting
    // or SEB isn't in exam mode, but is running with settings for starting an exam and the
    // reconfigure allow setting isn't set
    if ((secureSession && !(secureSessionReconfigureAllow && secureSessionReconfigureURLMatch)) ||
        (!secureSession && NSUserDefaults.userDefaultsPrivate && !secureSessionReconfigureAllow)) {
        // If yes, we don't download the .seb file
        return NO;
    } else {
        return YES;
    }
}


#pragma mark Downloading SEB Config Files

/// Initiating Opening the Config File Link

// Conditionally open a config from an URL passed to SEB as parameter
// usually with a link using the seb(s):// protocols
- (void) openConfigFromSEBURL:(NSURL *)url
{
    DDLogDebug(@"%s URL: %@", __FUNCTION__, url);
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    // Check first if opening SEB config files is allowed in settings and if no other settings are currently being opened
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"] && !_temporaryWebView) {
        // Check if SEB is in exam mode = private UserDefauls are switched on
        if (_delegate.startingUp || [self isReconfiguringAllowedFromURL:url]) {
            // SEB isn't in exam mode: reconfiguring is allowed
            NSURL *sebURL = url;
            // Figure the download URL out, depending on if http or https should be used
            if ([url.scheme isEqualToString:@"seb"]) {
                // If it's a seb:// URL, we try to download it by http
                url = [url URLByReplacingScheme:@"http"];
            } else if ([url.scheme isEqualToString:@"sebs"]) {
                // If it's a sebs:// URL, we try to download it by https
                url = [url URLByReplacingScheme:@"https"];
            }
            
            // When the URL of the SEB config file to load is on another host than the current page
            // then we might need to clear session cookies before attempting to download the config file
            // when the setting examSessionClearCookiesOnEnd is true
            if (_currentMainHost && ![url.host isEqualToString:_currentMainHost]) {
                if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_examSessionClearCookiesOnEnd"]) {
                    // Empties all cookies, caches and credential stores, removes disk files, flushes in-progress
                    // downloads to disk, and ensures that future requests occur on a new socket.
                    [[NSURLSession sharedSession] resetWithCompletionHandler:^{
                        DDLogInfo(@"Cookies, caches and credential stores were reset when ending browser session (examSessionClearCookiesOnEnd = false)");
                    }];
                }
                // Set the flag for cookies cleared (either they actually were or they would have
                // been settings prevented it)
                examSessionCookiesAlreadyCleared = YES;

            } else if (!_currentMainHost) {
                // When currentMainHost isn't set yet, SEB was started with a config link, possibly
                // to an authenticated server. In this case, session cookies shouldn't be cleared after logging in
                // as they were anyways cleared when SEB was started
                examSessionCookiesAlreadyCleared = YES;
            }
            // Check if we should try to download the config file from the seb(s) URL directly
            // This is the case when the URL has a .seb filename extension
            // But we only try it when it didn't fail in a first attempt
            if (_directConfigDownloadAttempted == NO && [url.pathExtension isEqualToString:@"seb"]) {
                _directConfigDownloadAttempted = YES;
                [self downloadSEBConfigFileFromURL:url originalURL:sebURL];
            } else {
                _directConfigDownloadAttempted = NO;
                _temporaryWebView = [_delegate openTempWebViewForDownloadingConfigFromURL:url];
                _temporaryWebView.originalURL = sebURL;
            }
        }
    } else {
        DDLogDebug(@"%s aborted, downloading and opening settings not allowed or temporary webview already open: %@", __FUNCTION__, _temporaryWebView);
        _delegate.openingSettings = false;
    }
}


// Try to download the config by opening the URL in the temporary browser window
- (void) tryToDownloadConfigByOpeningURL:(NSURL *)url
{
    DDLogInfo(@"Loading SEB config from URL %@ in temporary browser window.", [url absoluteString]);
    [_temporaryWebView loadURL:url];
    
}


// Called by the browser webview delegate if loading the config URL failed
- (void) openingConfigURLFailed {
    DDLogDebug(@"%s", __FUNCTION__);
    
    // Close the temporary browser window if it was opened
    if (_temporaryWebView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            DDLogDebug(@"Closing temporary browser window in: %s", __FUNCTION__);
            [self.delegate closeWebView:self.temporaryWebView];
        });
    }
    
    [_delegate openingConfigURLRoleBack];
    
    // Also reset the flag for SEB starting up
    _delegate.startingUp = false;
}


- (BOOL)sebWebView:(SEBAbstractWebView*)webView
decidePolicyForMIMEType:(NSString*)mimeType
               url:(NSURL *)url
   canShowMIMEType:(BOOL)canShowMIMEType
    isForMainFrame:(BOOL)isForMainFrame
 suggestedFilename:(NSString *)suggestedFilename
{
    DDLogDebug(@"decidePolicyForMIMEType: %@, URL: %@, canShowMIMEType: %d, isForMainFrame: %d, suggestedFilename %@", mimeType, url.absoluteString, canShowMIMEType, isForMainFrame, suggestedFilename);
    
    // Check if this link had the "download" attribute, then we download the linked resource and don't try to display it
//    if (self.downloadFilename) {
//        DDLogInfo(@"Link to resource %@ had the 'download' attribute, force download it.", request.URL.absoluteString);
//        [listener download];
//        [self startDownloadingURL:request.URL];
//        return;
//    }

//    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // Check if it is a data: scheme to support the W3C saveAs() FileSaver interface
//    if ([request.URL.scheme isEqualToString:@"data"]) {
//        CFStringRef mimeType = (__bridge CFStringRef)type;
//        CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType, NULL);
//        CFStringRef extension = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension);
//        self.downloadFileExtension = (__bridge NSString *)(extension);
//        if (uti) CFRelease(uti);
//        if (extension) CFRelease(extension);
//        DDLogInfo(@"data: content MIME type to download is %@, the file extension will be %@", type, extension);
//        [listener download];
//        [self startDownloadingURL:request.URL];
//
//        // Close the temporary Window or WebView which has been opend by the data: download link
//        SEBWebView *creatingWebView = [self.webView creatingWebView];
//        if (creatingWebView) {
//            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInNewWindow) {
//                // we have to close the new browser window which already has been opened by WebKit
//                // Get the document for my web view
//                DDLogDebug(@"Originating browser window %@", sender);
//                // Close document and therefore also window
//                //Workaround: Flash crashes after closing window and then clicking some other link
//                [[self.webView preferences] setPlugInsEnabled:NO];
//                DDLogDebug(@"Now closing new document browser window for: %@", self.webView);
//                [self.browserController closeWebView:self.webView];
//            }
//            if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_newBrowserWindowByScriptPolicy"] == openInSameWindow) {
//                if (self.webView) {
//                    [sender close]; //close the temporary webview
//                }
//            }
//        }
//        return;
//    } else {
//        self.downloadFileExtension = nil;
//    }

    if (([mimeType isEqualToString:@"application/seb"]) ||
        ([mimeType isEqualToString:@"text/xml"]) ||
        ([url.pathExtension isEqualToString:@"seb"])) {
        // If MIME-Type or extension of the file indicates a .seb file, we (conditionally) download and open it
        NSURL *originalURL = webView.originalURL;
        [self downloadSEBConfigFileFromURL:url originalURL:originalURL];
        return NO;
    }

    // Check for PDF file and according to settings either download or display it inline in the SEB browser
    if (![mimeType isEqualToString:@"application/pdf"] || !downloadPDFFiles) {
        // MIME type isn't PDF or downloading of PDFs isn't allowed
        if (canShowMIMEType) {
            return YES;
        }
    }
    
    // If MIME type cannot be displayed by the WebView, then we download it
    DDLogInfo(@"MIME type to download is %@", mimeType);
//    [self startDownloadingURL:request.URL];
    return NO;
}


/// Performing the Download

// This method is called by the browser webview delegate if the file to download has a .seb extension
- (void) downloadSEBConfigFileFromURL:(NSURL *)url originalURL:(NSURL *)originalURL
{
    DDLogDebug(@"%s URL: %@", __FUNCTION__, url);
    
    startURLQueryParameter = [self startURLQueryParameter:&url];
    
    // Use modern NSURLSession for downloading .seb files which also allows handling
    // basic/digest/NTLM authentication without having to open a temporary webview
    if (!_URLSession) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        _URLSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    }
    NSURLSessionDataTask *downloadTask = [_URLSession dataTaskWithURL:url
                                                    completionHandler:^(NSData *sebFileData, NSURLResponse *response, NSError *error)
                                          {
                                              [self didDownloadConfigData:sebFileData response:response error:error URL:url originalURL:originalURL];
                                          }];
    
    [downloadTask resume];
    
}


- (void) didDownloadConfigData:(NSData *)sebFileData
                      response:(NSURLResponse *)response
                         error:(NSError *)error
                           URL:(NSURL *)url
                   originalURL:(NSURL *)originalURL
{
    DDLogDebug(@"%s URL: %@, error: %@", __FUNCTION__, url, error);
    
    if (error) {
        if (error.code == NSURLErrorCancelled) {
            // Only close temp browser window if this wasn't a direct download attempt
            if (!_directConfigDownloadAttempted) {
                // Close the temporary browser window
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate closeWebView:self.temporaryWebView];
                });
                [_delegate openingConfigURLRoleBack];
                
            } else {
                _directConfigDownloadAttempted = false;
            }
            return;
        }
        if ([url.scheme isEqualToString:@"http"] && !_usingCustomURLProtocol) {
            // If it was a seb:// URL, and http failed, we try to download it by https
            NSURL *downloadURL = [url URLByReplacingScheme:@"https"];
            if (_directConfigDownloadAttempted) {
                [self downloadSEBConfigFileFromURL:downloadURL originalURL:originalURL];
            } else {
                [self tryToDownloadConfigByOpeningURL:downloadURL];
            }
        } else {
            if (_directConfigDownloadAttempted) {
                // If we tried a direct download first, now try to download it
                // by opening the URL in a temporary webview
                dispatch_async(dispatch_get_main_queue(), ^{
                    // which needs to be done on the main thread!
                    self.temporaryWebView = [self.delegate openTempWebViewForDownloadingConfigFromURL:url];
                    self.temporaryWebView.originalURL = originalURL;
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self downloadingSEBConfigFailed:error];
                });
            }
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self processDownloadedSEBConfigData:sebFileData fromURL:url originalURL:originalURL];
        });
    }
}


// NSURLSession download basic/digest/NTLM authentication challenge delegate
// Only called when downloading .seb files
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    DDLogInfo(@"URLSession: %@ task: %@ didReceiveChallenge: %@", session, task, challenge);
    
    // We accept any username/password authentication challenges.
    NSString *authenticationMethod = challenge.protectionSpace.authenticationMethod;
    
    if ([authenticationMethod isEqual:NSURLAuthenticationMethodHTTPBasic] ||
        [authenticationMethod isEqual:NSURLAuthenticationMethodHTTPDigest] ||
        [authenticationMethod isEqual:NSURLAuthenticationMethodNTLM]) {
        DDLogInfo(@"URLSession didReceive HTTPBasic/HTTPDigest/NTLM challenge");
        // If we have credentials from a previous login to the server we're on, try these first
        // but not when the credentials are from a failed username/password attempt
        if (_enteredCredential &&!_pendingChallengeCompletionHandler) {
            completionHandler(NSURLSessionAuthChallengeUseCredential, _enteredCredential);
            // We reset the cached previously entered credentials, because subsequent
            // downloads in this session won't need authentication anymore
            _enteredCredential = nil;
        } else {
            // Allow to enter password 3 times
            if ([challenge previousFailureCount] < 3) {
                // Display authentication dialog
                _pendingChallengeCompletionHandler = completionHandler;
                
                NSString *text = [NSString stringWithFormat:@"%@://%@", challenge.protectionSpace.protocol, challenge.protectionSpace.host];
                if ([challenge previousFailureCount] == 0) {
                    text = [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"To proceed, you must log in to", nil), text];
                    _lastUsername = @"";
                } else {
                    text = [NSString stringWithFormat:NSLocalizedString(@"The user name or password you entered for %@ was incorrect. Make sure you’re entering them correctly, and then try again.", nil), text];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate showEnterUsernamePasswordDialog:text
                                                             title:NSLocalizedString(@"Authentication Required", nil)
                                                          username:self.lastUsername
                                                     modalDelegate:self
                                                    didEndSelector:@selector(enteredUsername:password:returnCode:)];
                });
                
            } else {
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
                // inform the user that the user name and password
                // in the preferences are incorrect
                
                [_delegate openingConfigURLRoleBack];
            }
        }
    } else {
        DDLogInfo(@"URLSession didReceive other challenge (default handling)");
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, NULL);
    }
}


// Called when downloading the config file failed
- (void) downloadingSEBConfigFailed:(NSError *)error
{
    DDLogError(@"%s error: %@", __FUNCTION__, error);
    _delegate.openingSettings = false;
    
    // Only show the download error and close temp browser window if this wasn't a direct download attempt
    if (!_directConfigDownloadAttempted) {
        [_delegate downloadingSEBConfigFailed:error];
    }
}


// Called when SEB successfully downloaded the config file
- (void) processDownloadedSEBConfigData:(NSData *)sebFileData fromURL:(NSURL *)url originalURL:(NSURL *)originalURL
{
    DDLogDebug(@"%s URL: %@", __FUNCTION__, url);
    
    // Close the temporary browser window
    if (_temporaryWebView) {
        [_delegate closeWebView:_temporaryWebView];
        _temporaryWebView = nil;
    }
    
    if (_delegate.startingUp || [self isReconfiguringAllowedFromURL:originalURL ? originalURL : url]) {
        _delegate.openingSettings = true;
        
        if (examSessionCookiesAlreadyCleared == NO) {
            if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_examSessionClearCookiesOnEnd"] == YES) {
                // Empties all cookies, caches and credential stores, removes disk files, flushes in-progress
                // downloads to disk, and ensures that future requests occur on a new socket.
                [[NSURLSession sharedSession] resetWithCompletionHandler:^{
                    DDLogInfo(@"Cookies, caches and credential stores were reset when ending browser session (examSessionClearCookiesOnEnd = false)");
                }];
            }
            // Set the flag for cookies cleared (either they actually were or they would have
            // been settings prevented it)
            examSessionCookiesAlreadyCleared = YES;
        }
        downloadedSEBConfigDataURL = url;
        [_delegate openDownloadedSEBConfigData:sebFileData fromURL:url originalURL:originalURL];
        
    } else {
        // Opening downloaded SEB config data definitely failed:
        // we might need to quit (if SEB was just started)
        // or reset the opening settings flag which prevents opening URLs concurrently
        [_delegate openingConfigURLRoleBack];
    }
}


- (void) storeNewSEBSettingsSuccessful:(NSError *)error
{
    if (!error) {
        DDLogInfo(@"Storing downloaded SEB config data was successful");
        
        // Reset the direct download flag for the case this was a successful direct download
        _directConfigDownloadAttempted = false;
        
        [[NSUserDefaults standardUserDefaults] setSecureString:startURLQueryParameter forKey:@"org_safeexambrowser_startURLQueryParameter"];
        
    } else {
        /// Decrypting new settings wasn't successfull:
        DDLogInfo(@"Decrypting downloaded SEB config data failed or data needs to be downloaded in a temporary WebView after the user performs web-based authentication.");
        
        // Was this an attempt to download the config directly and the downloaded data was corrupted?
        if (_directConfigDownloadAttempted && error.code == SEBErrorNoValidConfigData) {
            // We try to download the config in a temporary WebView
            DDLogInfo(@"Trying to download the config in a temporary WebView");
            [self openConfigFromSEBURL:downloadedSEBConfigDataURL];
            
            return;
        } else {
            // The download failed definitely or was canceled by the user:
            DDLogError(@"Decrypting downloaded SEB config data failed definitely, present error and role back opening URL!");
            
            // Reset the direct download flag for the case this was a successful direct download
            _directConfigDownloadAttempted = false;
        }
    }
    [_delegate storeNewSEBSettingsSuccessfulProceed:error];
}


#pragma mark - Handling Universal Links

// Check if a URL is in an associated domain and therefore might have been
// invoked with a Universal Link
- (BOOL) isAssociatedDomain:(NSURL *)url
{
    if (![url.scheme isEqualToString:@"https"]) {
        // Universal Links must use the https protocol
        return NO;
    }
    NSString *entitlementsPath = [NSBundle.mainBundle pathForResource:[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"]
                                                     ofType:@"entitlements"];
    NSDictionary *entitlements = [[NSDictionary alloc]initWithContentsOfFile:entitlementsPath];
    NSArray *associatedDomains = [entitlements objectForKey:@"com.apple.developer.associated-domains"];
    NSString *host = url.host;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", host];
    NSArray *results = [associatedDomains filteredArrayUsingPredicate:predicate];
    // The URLs host is contained in our associated domains
    return (results.count != 0);
}


// Tries to find SEBSettings.seb or SEBExamSettings.seb files stored at folders
// specified by a Universal Link
- (void) handleUniversalLink:(NSURL *)universalLink
{
    _didReconfigureWithUniversalLink = NO;
    _cancelReconfigureWithUniversalLink = NO;
    if (universalLink &&
        [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_downloadAndOpenSebConfig"]) {
        // Remove query and fragment parts from the Universal Link URL
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:universalLink resolvingAgainstBaseURL:NO];
        urlComponents.query = nil;
        urlComponents.fragment = nil;
        NSURL *urlWithPartialPath = urlComponents.URL;
        
        if (urlWithPartialPath.pathExtension.length != 0) {
            // If the path specified a file, remove it from the path as well
            urlWithPartialPath = [urlWithPartialPath URLByDeletingLastPathComponent];
        }
        
        // Check for a file called "SEBSettings.seb" recursivly in the
        // folder hierarchy specified by the original Universal Link
        [self downloadConfigFile:SEBSettingsFilename
                         fromURL:urlWithPartialPath
               universalLinkHost:urlWithPartialPath
                   universalLink:universalLink];
    }
}


// We didn't find valid SEB settings named configFileName in the
// folder hierarchy specified by the Universal Link
- (void) universalLinkNoConfigFile:(NSString *)configFileName
                            atHost:(NSURL *)host
                     universalLink:(NSURL *)universalLink
{
    if ([configFileName isEqualToString:SEBSettingsFilename]) {
        // No "SEBSettings.seb" file found, search for "SEBExamSettings.seb" file
        // recursivly starting at the folder addressed by the original Universal Link
        [self downloadConfigFile:SEBExamSettingsFilename
                         fromURL:host
               universalLinkHost:host
                   universalLink:universalLink];
    } else {
        // Also no "SEBExamSettings.seb" file found, stop the search
        _downloadTask = nil;
        if (_isShowingOpeningConfigFileDialog) {
            [_delegate closeOpeningConfigFileDialog];
            _isShowingOpeningConfigFileDialog = NO;
        }
        NSError *error = nil;
        // If no valid client config was found (in the "SEBSettings.seb" file), return an error message
        if (_cancelReconfigureWithUniversalLink) {
            error = [[NSError alloc]
                        initWithDomain:sebErrorDomain
                        code:SEBErrorOpeningUniversalLinkFailed
                        userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Opening Universal Link Failed", nil),
                                    NSLocalizedRecoverySuggestionErrorKey : [NSString stringWithFormat:NSLocalizedString(@"Searching for a valid %@ config file was canceled.", nil), SEBShortAppName],
                                    }];
        } else if (!_didReconfigureWithUniversalLink) {
            error = [[NSError alloc]
                     initWithDomain:sebErrorDomain
                     code:SEBErrorOpeningUniversalLinkFailed
                     userInfo:@{ NSLocalizedDescriptionKey : NSLocalizedString(@"Opening Universal Link Failed", nil),
                                 NSLocalizedRecoverySuggestionErrorKey : [NSString stringWithFormat:NSLocalizedString(@"No %@ settings have been found at the specified URL. Use a correct link to configure %@ or start an exam.", nil), SEBShortAppName, SEBShortAppName],
                                 }];
        }

        [_delegate storeNewSEBSettingsSuccessfulProceed:error];
    }
}

// Try to recursivly find SEB settings named configFileName starting at the path in universalLinkHost
// the current path to look for the config file is specified in fromURL
- (void) downloadConfigFile:(NSString *)configFileName
                    fromURL:(NSURL *)url
          universalLinkHost:(NSURL *)host
              universalLink:(NSURL *)universalLink
{
    if (url.path.length == 0 || _cancelReconfigureWithUniversalLink) {
        // Searched the full subdirectory hierarchy of this host address
        [self universalLinkNoConfigFile:configFileName
                                 atHost:host
                          universalLink:universalLink];
    } else {
        if (!_isShowingOpeningConfigFileDialog) {
            [_delegate showOpeningConfigFileDialog:[NSString stringWithFormat:NSLocalizedString(@"Searching for a valid %@ config file …", nil), SEBShortAppName]
                                             title:NSLocalizedString(@"Opening Universal Link", nil)
                                    cancelCallback:self
                                          selector:@selector(cancelDownloadingConfigFile)];
            _isShowingOpeningConfigFileDialog = YES;
        }

        NSURL *newURL = url;
        // Remove the last path component or the trailing slash "/" from the
        // URL we're currently trying to download the config file
        if (![url.lastPathComponent isEqualToString:@"/"]) {
            newURL = [url URLByDeletingLastPathComponent];
        } else {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
            urlComponents.path = nil;
            newURL = urlComponents.URL;
        }
        url = [url URLByAppendingPathComponent:configFileName];
        
        if (!_URLSession) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            _URLSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
        }
        _downloadTask = [_URLSession dataTaskWithURL:url
                                   completionHandler:^(NSData *sebFileData, NSURLResponse *response, NSError *error)
                         {
                             [self didDownloadData:sebFileData
                                        configFile:configFileName
                                 universalLinkHost:host
                                     universalLink:universalLink
                                             error:error
                                               URL:newURL];
                         }];
        [_downloadTask resume];
    }
}


// Callback for trying to download SEB config file recursivly from hierarchy
// of subdirectories specified by universalLinkHost
- (void) didDownloadData:(NSData *)sebFileData
              configFile:(NSString *)fileName
       universalLinkHost:(NSURL *)host
           universalLink:(NSURL *)universalLink
                   error:(NSError *)error
                     URL:(NSURL *)url
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_downloadTask = nil;
        
        if (error || !sebFileData || self->_cancelReconfigureWithUniversalLink) {
            // Couldn't download config file, try it one level down in the path hierarchy
            [self downloadConfigFile:fileName
                             fromURL:url
                   universalLinkHost:host
                       universalLink:universalLink];
        } else {
            // Successfully downloaded SEB settings file or some other HTML data like a
            // 404 http page not found error webpage, therefore we have to check if
            // we downloaded correct SEB settings
            
            // The dialog for opening the config file needs to be closed to prevent
            // issues when another alert is presented in the store method
            if (self->_isShowingOpeningConfigFileDialog) {
                [self->_delegate closeOpeningConfigFileDialog];
                self->_isShowingOpeningConfigFileDialog = NO;
            }

            self->cachedConfigFileName = fileName;
            self->cachedDownloadURL = url;
            self->cachedHostURL = host;
            self->cachedUniversalLink = universalLink;
            [self->_delegate storeNewSEBSettings:sebFileData
                                forEditing:NO
                    forceConfiguringClient:NO
                     showReconfiguredAlert:NO
                                  callback:self
                                  selector:@selector(storeNewSEBSettingsFromUniversalLinkSuccessful:)];
        }
    });
}


// Cancel a processing download
- (void) cancelDownloadingConfigFile
{
    _cancelReconfigureWithUniversalLink = YES;
    if (_downloadTask) {
        [_downloadTask cancel];
        _downloadTask = nil;
    }
}


// Were correct SEB settings downloaded and sucessfully stored?
- (void) storeNewSEBSettingsFromUniversalLinkSuccessful:(NSError *)error
{
    if (error) {
        DDLogDebug(@"%s error: %@", __FUNCTION__, error);
        
        // Downloaded data was either no correct SEB config file
        // or this couldn't be stored (wrong passwords entered etc)
        [self downloadConfigFile:cachedConfigFileName
                         fromURL:cachedDownloadURL
               universalLinkHost:cachedHostURL
                   universalLink:cachedUniversalLink];
    } else {
        // Successfully found and stored some SEB settings
        // Store the file name of the .seb file as current config file path
        DDLogInfo(@"Storing downloaded SEB config data was successful");
        [[MyGlobals sharedMyGlobals] setCurrentConfigURL:[NSURL URLWithString:cachedConfigFileName]];

        // If these SEB settings came from
        // a "SEBSettings.seb" file, we check if they contained Client Settings
        if ([cachedConfigFileName isEqualToString:SEBSettingsFilename] &&
            ![NSUserDefaults userDefaultsPrivate]) {
            // SEB successfully read a SEBSettings.seb file with Client Settings
            // Now we try if there is a "SEBExamSettings.seb" file as well in the
            // same path hierarchy, as one Universal Link SEB can both configure/
            // reconfigure SEB Client Settings and start an exam
            _didReconfigureWithUniversalLink = YES;
            [self downloadConfigFile:SEBExamSettingsFilename
                             fromURL:cachedHostURL
                   universalLinkHost:cachedHostURL
                       universalLink:cachedUniversalLink];
        } else {
            // There either were Exam Settings in the SEBSettings.seb file
            // (no Client Settings), then we can stop searching further and
            // start the exam. Or we found Exam Settings in the
            // SEBExamSettings.seb file, then we can start that exam.
            if (_isShowingOpeningConfigFileDialog) {
                [_delegate closeOpeningConfigFileDialog];
                _isShowingOpeningConfigFileDialog = NO;
            }

            // Check if the Start URL Deep Link feature is allowed and store the
            // original full Universal Link as the deep link
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_startURLAllowDeepLink"]) {
                [preferences setSecureString:cachedUniversalLink.absoluteString
                                      forKey:@"org_safeexambrowser_startURLDeepLink"];
            }

            [_delegate storeNewSEBSettingsSuccessfulProceed:error];
        }
    }
}


@end
