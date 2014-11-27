//
//  SEBURLFilterRegexExpression.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 27.11.14.
//
//

#import "SEBURLFilterRegexExpression.h"

@implementation SEBURLFilterRegexExpression


+ (SEBURLFilterRegexExpression *) regexFilterExpressionWithString:(NSString *)filterExpressionString error:(NSError **)error
{
    SEBURLFilterRegexExpression *filterExpression = [SEBURLFilterRegexExpression new];
    NSURL *URLFromString = [NSURL URLWithString:filterExpressionString];
    
    filterExpression.scheme = [self regexForFilterString:URLFromString.scheme error:error];
    filterExpression.user = [self regexForFilterString:URLFromString.user error:error];
    filterExpression.password = [self regexForFilterString:URLFromString.password error:error];
    filterExpression.host = [self regexForFilterString:URLFromString.host error:error];
    filterExpression.port = URLFromString.port;
    filterExpression.path = [self regexForFilterString:URLFromString.path error:error];
    filterExpression.query = [self regexForFilterString:URLFromString.query error:error];
    filterExpression.fragment = [self regexForFilterString:URLFromString.fragment error:error];
    
    return filterExpression;
}


+ (NSRegularExpression *) regexForFilterString:(NSString *)filterString error:(NSError **)error
{
    if (filterString.length == 0) {

        return nil;
        
    } else {
        
        NSString *regexString = [NSRegularExpression escapedPatternForString:filterString];
        regexString = [regexString stringByReplacingOccurrencesOfString:@"\\*" withString:@".*?"];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:error];
        return regex;
    }
}


@end
