//
//  SEBURLProtocol.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07/04/15.
//  Copyright (c) 2010-2018 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2018 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBURLProtocol.h"

@interface SEBURLProtocol ()
@property (nonatomic, strong) NSURLConnection *connection;

@end


@implementation SEBURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    return YES;
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    return request;
}

- (void)startLoading
{
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    
//    // Here we set the User Agent
//    [newRequest setValue:@"Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.2 Safari/537.36 Kifi/1.0f" forHTTPHeaderField:@"User-Agent"];
//    
//    [NSURLProtocol setProperty:@YES forKey:@"UserAgentSet" inRequest:newRequest];
    
    self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
}

- (void)stopLoading
{
    [self.connection cancel];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.client URLProtocol:self didFailWithError:error];
    self.connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self.client URLProtocolDidFinishLoading:self];
    self.connection = nil;
}


-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
    if ([protectionSpace authenticationMethod] == NSURLAuthenticationMethodServerTrust) {
        SecTrustRef trust = [protectionSpace serverTrust];
        
        /***** Make specific changes to the trust policy here. *****/
        
        /* Re-evaluate the trust policy. */
        SecTrustResultType secresult = kSecTrustResultInvalid;
        if (SecTrustEvaluate(trust, &secresult) != errSecSuccess) {
            /* Trust evaluation failed. */
            
            [connection cancel];
            
            // Perform other cleanup here, as needed.
            return;
        }
        
        switch (secresult) {
            case kSecTrustResultUnspecified: // The OS trusts this certificate implicitly.
            case kSecTrustResultProceed: // The user explicitly told the OS to trust it.
            {
                NSURLCredential *credential =
                [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
                return;
            }
            default: ;
                /* It's somebody else's key. Fall through. */
        }
        /* The server sent a key other than the trusted key. */
        [connection cancel];
        
        // Perform other cleanup here, as needed.
    }
}


@end
