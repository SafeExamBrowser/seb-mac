//
//  SEBInitAssistantViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07/03/17.
//  Copyright (c) 2010-2017 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, 
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBInitAssistantViewController.h"


@implementation SEBInitAssistantViewController


- (void) evaluateEnteredURLString:(NSString *)URLString
{
    NSString *scheme;
    NSURL *URLFromString;
    if (URLString.length > 0) {
        NSRange scanResult = [URLString rangeOfString:@"://"];
        if (scanResult.location != NSNotFound) {
            // Filter expression contains a scheme: Check if it is a seb(s):// scheme
            // if yes, replace it with http(s)
            scheme = [URLString substringToIndex:scanResult.location];
            NSString *newScheme = scheme;
            if ([scheme isEqualToString:@"seb"]) {
                newScheme = @"http";
            } else if ([scheme isEqualToString:@"sebs"]) {
                newScheme = @"https";
            } else if (!([scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"])) {
                // if the scheme isn't seb, sebs, http, https, then don't accept the URL
                [_controllerDelegate setConfigURLWrongLabelHidden:false forClientConfigURL:false];
                return;
            }
            URLString = [NSString stringWithFormat:@"%@%@", newScheme, [URLString substringFromIndex:scanResult.location]];
            // Convert filter expression string to a NSURL
            URLFromString = [NSURL URLWithString:URLString];
        } else {
            // Filter expression doesn't contain a scheme followed by an authority part,
            // Prefix it with a https:// scheme
            URLString = [NSString stringWithFormat:@"https://%@", URLString];
            // Convert filter expression string to a NSURL
            URLFromString = [NSURL URLWithString:URLString];
        }
    }
    if (URLFromString) {
        clientConfigURL = false;
        [self checkSEBClientConfigURL:URLFromString withScheme:0];
    } else {
        [_controllerDelegate setConfigURLWrongLabelHidden:URLString.length == 0 forClientConfigURL:false];
    }
}


// Check for SEB client config at the passed URL using the next scheme
- (void) checkSEBClientConfigURL:(NSURL *)url withScheme:(SEBClientConfigURLSchemes)configURLScheme
{
    // Cancel a processing download of a previously entered URL
    if (_downloadTask) {
        [_downloadTask cancel];
    }
    
    // Check using the next scheme (we can skip first scheme = none)
    configURLScheme++;
    switch (configURLScheme) {
        case SEBClientConfigURLSchemeDomain:
        {
            [self downloadSEBClientConfigFromURL:url originalURL:url withScheme:configURLScheme];
            break;
        }
            
        case SEBClientConfigURLSchemeSubdomainShort:
        {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
            NSString *host = url.host;
            host = [NSString stringWithFormat:@"seb.%@", host];
            urlComponents.host = host;
            NSURL *newURL = urlComponents.URL;
            [self downloadSEBClientConfigFromURL:newURL originalURL:url withScheme:configURLScheme];
            break;
        }
            
        case SEBClientConfigURLSchemeSubdomainLong:
        {
            NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
            NSString *host = url.host;
            host = [NSString stringWithFormat:@"safeexambrowser.%@", host];
            urlComponents.host = host;
            NSURL *newURL = urlComponents.URL;
            [self downloadSEBClientConfigFromURL:newURL originalURL:url withScheme:configURLScheme];
            break;
        }
            
        default:
            [self storeSEBClientSettingsSuccessful:false];
            break;
    }
}


- (void) downloadSEBClientConfigFromURL:(NSURL *)url originalURL:(NSURL *)originalURL withScheme:(SEBClientConfigURLSchemes)configURLScheme
{
    if (![url.pathExtension isEqualToString:@"seb"]) {
        url = [url URLByAppendingPathComponent:@"safeexambrowser/SEBClientSettings.seb"];
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
    }
}


- (void) didDownloadData:(NSData *)sebFileData
                response:(NSURLResponse *)response
                   error:(NSError *)error
                     URL:(NSURL *)url
              withScheme:(SEBClientConfigURLSchemes)configURLScheme
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_controllerDelegate activityIndicatorAnimate:false];
        _downloadTask = nil;
        
        if (error || !sebFileData) {
            if (error.code == NSURLErrorCancelled) {
                return;
            }
            [self checkSEBClientConfigURL:url withScheme:configURLScheme];
        } else {
            [_controllerDelegate storeSEBClientSettings:sebFileData callback:self selector:@selector(storeSEBClientSettingsSuccessful:)];
        }
    });
}


- (void) storeSEBClientSettingsSuccessful:(BOOL)success
{
    if (success) {
        [_controllerDelegate setConfigURLWrongLabelHidden:true forClientConfigURL:clientConfigURL];
        [_controllerDelegate closeAssistantRestartSEB];
    } else {
        [_controllerDelegate setConfigURLWrongLabelHidden:false forClientConfigURL:clientConfigURL];
    }
}


@end
