//
//  SEBInitAssistantViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07/03/17.
//  Copyright (c) 2010-2017 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBInitAssistantViewController.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <netdb.h>

@implementation SEBInitAssistantViewController


- (void) evaluateEnteredURLString:(NSString *)URLString
{
    NSString *scheme;
    NSURL *URLFromString;
    _searchingConfigCanceled = NO;
    if (URLString.length > 0) {
        NSRange scanResult = [URLString rangeOfString:@"://"];
        if (scanResult.location != NSNotFound) {
            // URL contains a scheme: Check if it is a seb(s):// scheme
            // if yes, replace it with http(s)
            scheme = [URLString substringToIndex:scanResult.location];
            NSString *newScheme = scheme;
            if ([scheme isEqualToString:SEBProtocolScheme]) {
                newScheme = @"http";
            } else if ([scheme isEqualToString:SEBSSecureProtocolScheme]) {
                newScheme = @"https";
            } else if (!([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])) {
                // if the scheme isn't seb, sebs, http, https, then don't accept the URL
                [_controllerDelegate setConfigURLWrongLabelHidden:false
                                                            error:nil
                                               forClientConfigURL:false];
                return;
            }
            URLString = [NSString stringWithFormat:@"%@%@", newScheme, [URLString substringFromIndex:scanResult.location]];
            URLFromString = [NSURL URLWithString:URLString];
        } else {
            // URL doesn't contain a scheme followed by an authority part,
            // Prefix it with a https:// scheme
            URLString = [NSString stringWithFormat:@"https://%@", URLString];
            URLFromString = [NSURL URLWithString:URLString];
        }
    }
    if (URLFromString) {
        if (URLFromString.path.length > 0 && ![URLFromString.path isEqualToString:@"/"]) {
            NSError *error = [[NSError alloc]
                              initWithDomain:sebErrorDomain
                              code:SEBErrorASCCNoWiFi
                              userInfo:@{ NSLocalizedDescriptionKey :
                                              NSLocalizedString(@"Wrong Institution URL", nil),
                                          NSLocalizedFailureReasonErrorKey :
                                              [NSString stringWithFormat:NSLocalizedString(@"You cannot enter a path to an %@ configuration file here, only a domain URL of your institution (host name with domain and optionally subdomains). Administrators can get more information about Automatic Client Configuration at %@/developer.", nil), SEBExtraShortAppName, SEBWebsiteShort]
                                       }];
            [_controllerDelegate setConfigURLWrongLabelHidden:YES
                                                        error:error
                                           forClientConfigURL:false];
        } else {
            clientConfigURL = NO;
            [self checkSEBClientConfigURL:URLFromString withScheme:SEBClientConfigURLSchemeNone];
        }
    } else {
        [_controllerDelegate setConfigURLWrongLabelHidden:URLString.length == 0
                                                    error:nil
                                       forClientConfigURL:false];
    }
}


- (NSString *)domainForCurrentNetwork
{
    _searchingConfigCanceled = NO;
    
    NSString *ipAddress = [self getIPAddress];
    if (!ipAddress) {
        return @"";
    }
    NSString *fullHost = [self getHostFromIPAddress:ipAddress];
    NSString *hostDomain = @"";
    if (fullHost.length > 0) {
        NSMutableArray *hostSegments = [fullHost componentsSeparatedByString:@"."].mutableCopy;
        if (hostSegments.count > 1) {
            [hostSegments removeObjectAtIndex:0];
        }
        hostDomain = [hostSegments componentsJoinedByString:@"."];
    }
    return hostDomain;
}


- (NSString *)getIPAddress
{
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is a Wi-Fi connection or
                // utun5, which is a VPN connection
                NSString *interfaceName = [NSString stringWithUTF8String:temp_addr->ifa_name];
                if([interfaceName isEqualToString:@"en0"] || [interfaceName isEqualToString:@"utun5"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
        if (!address) {
            // Display warning that not connected to a WiFi network
            [self storeSEBClientSettingsSuccessful:[[NSError alloc]
                                                    initWithDomain:sebErrorDomain
                                                    code:SEBErrorASCCNoWiFi
                                                    userInfo:@{ NSLocalizedDescriptionKey :
                                                                    NSLocalizedString(@"Not Connected to Wi-Fi or VPN", nil),
                                                                NSLocalizedFailureReasonErrorKey :
                                                                    [NSString stringWithFormat:NSLocalizedString(@"Searching local network for Automatic %@ Client Configuration requires a Wi-Fi or VPN connection. You can enter the domain URL of your institution manually too.", nil), SEBExtraShortAppName]
                                                                }]];
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}


-(NSString *)getHostFromIPAddress:(NSString*)ipAddress {
    struct addrinfo *result = NULL;
    struct addrinfo hints;
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_flags = AI_NUMERICHOST;
    hints.ai_family = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = 0;
    
    NSString *hostname = nil;
    
    int errorStatus = getaddrinfo([ipAddress cStringUsingEncoding:NSASCIIStringEncoding], NULL, &hints, &result);
    if (errorStatus == 0) {
        CFDataRef addressRef = CFDataCreate(NULL, (UInt8 *)result->ai_addr, result->ai_addrlen);
        if (addressRef) {
            freeaddrinfo(result);
            CFHostRef hostRef = CFHostCreateWithAddress(kCFAllocatorDefault, addressRef);
            CFRelease(addressRef);
            if (hostRef) {
                BOOL succeeded = CFHostStartInfoResolution(hostRef, kCFHostNames, NULL);
                if (succeeded) {
                    NSMutableArray *hostnames = [NSMutableArray array];
                    
                    CFArrayRef hostnamesRef = CFHostGetNames(hostRef, NULL);
                    if (hostnamesRef) {
                        for (int currentIndex = 0; currentIndex < [(__bridge NSArray *)hostnamesRef count]; currentIndex++) {
                            [hostnames addObject:[(__bridge NSArray *)hostnamesRef objectAtIndex:currentIndex]];
                        }
                        CFRelease(hostnamesRef);
                    }
                    hostname = hostnames.firstObject;
                } else {
//                    CFRelease(hostRef);
                }
            }
        }
    }
    
    if (!hostname || ![hostname containsString:@"."]) {
        // Display warning that not connected to a WiFi network
        [self storeSEBClientSettingsSuccessful:[[NSError alloc]
                                                initWithDomain:sebErrorDomain
                                                code:SEBErrorASCCNoHostnameFound
                                                userInfo:@{ NSLocalizedDescriptionKey :
                                                                NSLocalizedString(@"No Hostname Found", nil),
                                                            NSLocalizedFailureReasonErrorKey :
                                                                NSLocalizedString(@"Could not determine a correct hostname. You can enter the domain URL of your institution manually.", nil)
                                                            }]];
    }
    return hostname;
}


// Check for SEB client config at the passed URL using the next scheme
- (void) checkSEBClientConfigURL:(NSURL *)url
                      withScheme:(SEBClientConfigURLSchemes)configURLScheme
{
    if (_searchingConfigCanceled) {
        [self storeSEBClientSettingsSuccessful:[[NSError alloc]
                                                initWithDomain:sebErrorDomain
                                                code:SEBErrorASCCCanceled
                                                userInfo:@{ NSLocalizedDescriptionKey :
                                                                [NSString stringWithFormat:NSLocalizedString(@"Searching for %@ Configuration Canceled", nil), SEBShortAppName],
                                                            NSLocalizedFailureReasonErrorKey :
                                                                [NSString stringWithFormat:NSLocalizedString(@"If your institution does not support Automatic %@ Client Configuration, follow instructions of your exam administrator.", nil), SEBExtraShortAppName]
                                                            }]];

    } else {
        // Check using the next scheme (we can skip first scheme = none)
        configURLScheme++;
        switch (configURLScheme) {
                
            case SEBClientConfigURLSchemeSubdomainShort:
            {
                NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
                NSString *host = url.host;
                host = [NSString stringWithFormat:@"%@.%@", SEBClientSettingsACCSubdomainShort, host];
                urlComponents.host = host;
                NSURL *newURL = urlComponents.URL;
                [self downloadSEBClientConfigFromURL:newURL originalURL:url withScheme:configURLScheme];
                break;
            }
                
            case SEBClientConfigURLSchemeSubdomainLong:
            {
                NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
                NSString *host = url.host;
                host = [NSString stringWithFormat:@"%@.%@", SEBClientSettingsACCSubdomainLong, host];
                urlComponents.host = host;
                NSURL *newURL = urlComponents.URL;
                [self downloadSEBClientConfigFromURL:newURL originalURL:url withScheme:configURLScheme];
                break;
            }
                
            case SEBClientConfigURLSchemeDomain:
            {
                [self downloadSEBClientConfigFromURL:url originalURL:url withScheme:configURLScheme];
                break;
            }
                
            case SEBClientConfigURLSchemeWellKnown:
            {
                [self downloadSEBClientConfigFromURL:url originalURL:url withScheme:configURLScheme];
                break;
            }
                
            default:
                [self storeSEBClientSettingsSuccessful:[[NSError alloc]
                                                        initWithDomain:sebErrorDomain
                                                        code:SEBErrorASCCNoConfigFound
                                                        userInfo:@{ NSLocalizedDescriptionKey :
                                                                        [NSString stringWithFormat:NSLocalizedString(@"No %@ Configuration Found", nil), SEBShortAppName],
                                                                    NSLocalizedFailureReasonErrorKey :
                                                                        [NSString stringWithFormat:NSLocalizedString(@"Your institution might not support Automatic %@ Client Configuration. Follow the instructions of your exam administrator.", nil), SEBExtraShortAppName]
                                                                    }]];
                break;
        }
    }
}


- (void) downloadSEBClientConfigFromURL:(NSURL *)url originalURL:(NSURL *)originalURL withScheme:(SEBClientConfigURLSchemes)configURLScheme
{
    if (!_searchingConfigCanceled) {
        if (![url.pathExtension isEqualToString:SEBFileExtension]) {
            NSString *clientSettingsPathAAC;
            if (configURLScheme == SEBClientConfigURLSchemeWellKnown) {
                clientSettingsPathAAC = @".well-known";
            } else {
                clientSettingsPathAAC = SEBClientSettingsACCPath;
            }
            url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@", clientSettingsPathAAC, SEBClientSettingsFilename]];
            clientConfigURL = true;
        }
        if (url) {
            [_controllerDelegate activityIndicatorAnimate:true];
            if (!_URLSession) {
                NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
                _URLSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
            }
            _downloadTask = [_URLSession dataTaskWithURL:url
                                       completionHandler:^(NSData *sebFileData, NSURLResponse *response, NSError *error)
                             {
                                 [self didDownloadData:sebFileData
                                              response:response
                                                 error:error
                                                   URL:originalURL
                                            withScheme:configURLScheme];
                             }];
            [_downloadTask resume];
            // Create a timer to cancel the download task if it takes more than 10 seconds
            _downloadTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                              target:self
                                                            selector:@selector(cancelDownloadTask)
                                                            userInfo:nil
                                                             repeats:NO];
        }
    }
}


- (void) didDownloadData:(NSData *)sebFileData
                response:(NSURLResponse *)response
                   error:(NSError *)error
                     URL:(NSURL *)url
              withScheme:(SEBClientConfigURLSchemes)configURLScheme
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_downloadTimer invalidate];
        if (error || !sebFileData || self->_searchingConfigCanceled) {
            [self checkSEBClientConfigURL:url withScheme:configURLScheme];
        } else {
            self->storeClienConfigURL = url;
            self->storeConfigURLScheme = configURLScheme;
            [self->_controllerDelegate storeSEBClientSettings:sebFileData callback:self selector:@selector(storeSEBClientSettingsSuccessful:)];
        }
    });
}


// Cancel a processing download after the timeout passed
- (void) cancelDownloadTask
{
    [_downloadTimer invalidate];
    if (_downloadTask) {
        [_controllerDelegate activityIndicatorAnimate:false];
        // The completion handler will be called with an NSError
        [_downloadTask cancel];
        _downloadTask = nil;
    }
}


// Cancel a processing download
- (void) cancelDownloadingClientConfig
{
    _searchingConfigCanceled = YES;
    if (_downloadTask) {
        [_controllerDelegate activityIndicatorAnimate:false];
        [_downloadTask cancel];
        _downloadTask = nil;
    }
}


- (void) storeSEBClientSettingsSuccessful:(NSError *)error
{
    if (error) {
        NSInteger errorCode = error.code;
        if (!_searchingConfigCanceled &&
            !(errorCode == SEBErrorASCCNoWiFi ||
              errorCode == SEBErrorASCCNoHostnameFound ||
              errorCode == SEBErrorASCCCanceled ||
              errorCode == SEBErrorASCCNoConfigFound)) {
                [self checkSEBClientConfigURL:storeClienConfigURL
                                   withScheme:storeConfigURLScheme];
                return;
            }
    }
    [_controllerDelegate activityIndicatorAnimate:false];
    
    if (_searchingConfigCanceled) {
        [_controllerDelegate setConfigURLWrongLabelHidden:true
                                                    error:nil
                                       forClientConfigURL:clientConfigURL];
        
    } else {
        if (!error) {
            [_controllerDelegate setConfigURLWrongLabelHidden:true
                                                        error:nil
                                           forClientConfigURL:clientConfigURL];
            _controllerDelegate.configURLString = @"";
            [_controllerDelegate closeAssistantRestartSEB];
        } else {
            [_controllerDelegate setConfigURLWrongLabelHidden:false
                                                        error:error
                                           forClientConfigURL:clientConfigURL];
        }
    }
}


@end
