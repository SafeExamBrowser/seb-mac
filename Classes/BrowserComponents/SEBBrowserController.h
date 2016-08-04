//
//  SEBBrowserController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 22/01/16.
//
//

#import <Foundation/Foundation.h>

@interface SEBBrowserController : NSObject

- (void) createSEBUserAgentFromDefaultAgent:(NSString *)defaultUserAgent;
- (void) conditionallyInitCustomHTTPProtocol;

@end
