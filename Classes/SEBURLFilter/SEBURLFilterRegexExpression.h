//
//  SEBURLFilterRegexExpression.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 27.11.14.
//
//

#import <Foundation/Foundation.h>
#import "SEBURLFilterExpression.h"

@interface SEBURLFilterRegexExpression : NSObject

@property NSRegularExpression *scheme;
@property NSRegularExpression *user;
@property NSRegularExpression *password;
@property NSRegularExpression *host;
@property NSNumber *port;
@property NSRegularExpression *path;
@property NSRegularExpression *query;
@property NSRegularExpression *fragment;


+ (SEBURLFilterRegexExpression *) regexFilterExpressionWithString:(NSString *)filterExpressionString error:(NSError **)error;

+ (NSRegularExpression *) regexForFilterString:(NSString *)filterString error:(NSError **)error;

+ (NSRegularExpression *) regexForHostFilterString:(NSString *)filterString error:(NSError **)error;

@end
