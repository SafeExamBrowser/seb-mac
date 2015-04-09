//
//  SEBURLProtocol.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07/04/15.
//
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
