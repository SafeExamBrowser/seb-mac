//
//  SEBFilteredURLCache.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 31.10.18.
//

#import "SEBFilteredURLCache.h"
#import "SEBURLFilter.h"

@implementation SEBFilteredURLCache

- (NSCachedURLResponse*)cachedResponseForRequest:(NSURLRequest*)request
{
    NSURL *url = [request URL];
    SEBURLFilter *urlFilter;
    
    if (urlFilter.enableURLFilter && urlFilter.enableContentFilter) {
        URLFilterRuleActions filterActionResponse = [urlFilter testURLAllowed:url];
        if (filterActionResponse != URLFilterActionAllow) {
            /// Content is not allowed: Show teach URL alert if activated or just indicate URL is blocked filterActionResponse == URLFilterActionBlock ||
            //            if (![self showURLFilterAlertSheetForWindow:self forRequest:request forContentFilter:YES filterResponse:filterActionResponse]) {
            /// User didn't allow the content, don't load it
            DDLogWarn(@"This content was blocked by the content filter: %@", url.absoluteString);
            //            }
            
            NSURLResponse *response =
            [[NSURLResponse alloc] initWithURL:url
                                      MIMEType:@"text/plain"
                         expectedContentLength:1
                              textEncodingName:nil];
            
            NSCachedURLResponse *cachedResponse =
            [[NSCachedURLResponse alloc] initWithResponse:response
                                                     data:[NSData dataWithBytes:" " length:1]];
            
            [super storeCachedResponse:cachedResponse forRequest:request];
        }
    }
    
    return [super cachedResponseForRequest:request];
}

@end
