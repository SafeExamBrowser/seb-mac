//
//  SEBFilteredURLCache.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 31.10.18.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
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

#import "SEBFilteredURLCache.h"
#import "SEBURLFilter.h"

@implementation SEBFilteredURLCache

- (NSCachedURLResponse*)cachedResponseForRequest:(NSURLRequest*)request
{
    NSURL *url = [request URL];
    SEBURLFilter *urlFilter = [SEBURLFilter sharedSEBURLFilter];
    
    if (urlFilter.enableURLFilter && urlFilter.enableContentFilter) {
        URLFilterRuleActions filterActionResponse = [urlFilter testURLAllowed:url];
        if (filterActionResponse != URLFilterActionAllow) {
            /// Content is not allowed: Show teach URL alert if activated or just indicate URL is blocked filterActionResponse == URLFilterActionBlock ||
            //            if (![self showURLFilterAlertSheetForWindow:self forRequest:request forContentFilter:YES filterResponse:filterActionResponse]) {
            /// User didn't allow the content, don't load it
            DDLogWarn(@"This content was blocked by the content filter: %@", url.absoluteString);
            //            }

            NSHTTPURLResponse *response =
            [[NSHTTPURLResponse alloc] initWithURL:url
                                        statusCode:403
                                       HTTPVersion:@"HTTP/1.1"
                                      headerFields:nil];

            NSCachedURLResponse *cachedResponse =
            [[NSCachedURLResponse alloc] initWithResponse:response
                                                     data:[NSData dataWithBytes:" " length:1]];
            
            [super storeCachedResponse:cachedResponse forRequest:request];
        }
    }
    
    return [super cachedResponseForRequest:request];
}

@end
