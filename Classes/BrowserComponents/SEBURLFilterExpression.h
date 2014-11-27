//
//  SEBURLFilterExpression.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 22.11.14.
//
//

#import <Foundation/Foundation.h>

@interface SEBURLFilterExpression : NSObject

@property NSString *scheme;
@property NSString *user;
@property NSString *password;
@property NSString *host;
@property NSNumber *port;
@property NSString *path;
@property NSString *query;
@property NSString *fragment;


+ (SEBURLFilterExpression *) filterExpressionWithString:(NSString *)filterExpressionString;

+ (SEBURLFilterExpression *) regexFilterExpressionWithString:(NSString *)filterExpressionString;

+ (NSString *) regexForFilterString:(NSString *)filterString;

- (id) initWithScheme:(NSString *)scheme user:(NSString *)user password:(NSString *)password host:(NSString *)host port:(NSNumber *)port path:(NSString *)path query:(NSString *)query fragment:(NSString *)fragment;

- (NSString *) string;


@end
