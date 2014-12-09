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
    SEBURLFilterExpression *URLFromString = [SEBURLFilterExpression filterExpressionWithString:filterExpressionString];
    
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


- (NSString *) string
{
    NSMutableString *expressionString = [NSMutableString new];
    NSString *part;
    [expressionString appendString:@"^"];
    
    // If there is a regex filter for scheme
    if (_scheme) {
        // get stripped regex pattern
        part = [self stringForRegexFilter:_scheme];
    } else {
        // otherwise use the regex wildcard pattern for scheme
        part = @".*?";
    }
    [expressionString appendFormat:@"%@://", part];

    
    if (_user) {
        part = [self stringForRegexFilter:_user];

        [expressionString appendString:[self stringForRegexFilter:_user]];
        
        if (_password) {
            [expressionString appendFormat:@":%@@", [self stringForRegexFilter:_password]];
        } else {
            [expressionString appendString:@"@"];
        }
    }
    if (_host) {
        [expressionString appendString:[self stringForRegexFilter:_host]];
    }
    if (_port && (_port.integerValue > 0) && (_port.integerValue <= 65535)) {
        [expressionString appendFormat:@":%@", _port.stringValue];
    }
    if (_path) {
        NSString *path = [self stringForRegexFilter:_path];
        if ([path hasPrefix:@"/"]) {
            [expressionString appendString:path];
        } else {
            [expressionString appendFormat:@"/%@", path];
        }
        
        if (![path hasSuffix:@"/"]) {
            [expressionString appendString:@"/"];
        }
    }
    if (_query) {
        [expressionString appendFormat:@"?%@", [self stringForRegexFilter:_query]];
    }
    if (_fragment) {
        [expressionString appendFormat:@"#%@", [self stringForRegexFilter:_fragment]];
    }
    [expressionString appendString:@"$"];

    return expressionString;
}


- (NSString *) stringForRegexFilter:(NSRegularExpression *) regexFilter
{
    // Get pattern string from regular expression
    NSString *regexPattern = [regexFilter pattern];
    if (regexPattern.length <= 2) {
        return @"";
    }
    // Remove the regex command characters for matching at start and end of a line
    regexPattern = [regexPattern substringWithRange:NSMakeRange(1, regexPattern.length - 2)];
    return regexPattern;
}

@end
