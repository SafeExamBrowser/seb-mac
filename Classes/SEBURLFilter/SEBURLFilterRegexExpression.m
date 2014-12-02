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
    filterExpression.host = [self regexForHostFilterString:URLFromString.host error:error];
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
        // Add regex command characters for matching at start and end of a line (part)
        regexString = [NSString stringWithFormat:@"^%@$", regexString];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:error];
        return regex;
    }
}


+ (NSRegularExpression *) regexForHostFilterString:(NSString *)filterString error:(NSError **)error
{
    if (filterString.length == 0) {
        
        return nil;
        
    } else {
        // Check if host string has a dot "." prefix to disable subdomain matching
        if (filterString.length > 1 && [filterString hasPrefix:@"."]) {
            // Get host string without the "." prefix
            filterString = [filterString substringFromIndex:1];
            // Get regex for host <*://example.com> (without possible subdomains)
            return [self regexForFilterString:filterString error:error];
        }
        // Allow subdomain matching: Create combined regex for <example.com> and <*.example.com>
        NSString *regexString = [NSRegularExpression escapedPatternForString:filterString];
        regexString = [regexString stringByReplacingOccurrencesOfString:@"\\*" withString:@".*?"];
        // Add regex command characters for matching at start and end of a line (part)
        regexString = [NSString stringWithFormat:@"^((%@)|(.*?\\.%@))$", regexString, regexString];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:error];
        return regex;
    }
}


@end
