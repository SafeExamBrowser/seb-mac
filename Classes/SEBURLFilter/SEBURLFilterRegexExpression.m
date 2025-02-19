//
//  SEBURLFilterRegexExpression.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 27.11.14.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBURLFilterRegexExpression.h"

@implementation SEBURLFilterRegexExpression


+ (NSArray<SEBURLFilterRegexExpression*>*) regexFilterExpressionWithString:(NSString *)filterExpressionString error:(NSError **)error
{
    SEBURLFilterRegexExpression *filterExpression = [SEBURLFilterRegexExpression new];
    SEBURLFilterRegexExpression *filterExpression2;
    SEBURLFilterRegexExpression *filterExpression3;
    SEBURLFilterRegexExpression *filterExpression4;
    SEBURLFilterExpression *URLFromString = [SEBURLFilterExpression filterExpressionWithString:filterExpressionString];
    
    filterExpression.scheme = [self regexForFilterString:URLFromString.scheme error:error];
    filterExpression.user = [self regexForFilterString:URLFromString.user error:error];
    filterExpression.password = [self regexForFilterString:URLFromString.password error:error];
    filterExpression.port = URLFromString.port;
    filterExpression.query = [self regexForQueryFilterString:URLFromString.query error:error];
    filterExpression.fragment = [self regexForFilterString:URLFromString.fragment error:error];

    NSArray<NSRegularExpression *>*hostRegexFilterStrings = [self regexForHostFilterString:URLFromString.host error:error];
    if (hostRegexFilterStrings.count > 1) {
        filterExpression2 = filterExpression;
        filterExpression2.host = hostRegexFilterStrings[1];
    }
    filterExpression.host = hostRegexFilterStrings[0];
    
    NSArray<NSRegularExpression *>*pathRegexFilterStrings = [self regexForPathFilterString:URLFromString.path error:error];
    if (pathRegexFilterStrings.count > 1) {
        if (filterExpression2) {
            filterExpression3 = filterExpression;
            filterExpression4 = filterExpression2;
            filterExpression.path = pathRegexFilterStrings[0];
            filterExpression2.path = pathRegexFilterStrings[0];
            filterExpression3.path = pathRegexFilterStrings[1];
            filterExpression4.path = pathRegexFilterStrings[1];
        } else {
            filterExpression2 = filterExpression;
            filterExpression.path = pathRegexFilterStrings[0];
            filterExpression2.path = pathRegexFilterStrings[1];
        }
    } else {
        if (filterExpression2) {
            filterExpression2.path = pathRegexFilterStrings[0];
        }
        filterExpression.path = pathRegexFilterStrings[0];
    }
    NSMutableArray<NSRegularExpression*>* regexFilterExpressions = [NSMutableArray arrayWithObjects:filterExpression, filterExpression2, filterExpression3, filterExpression4, nil];
    return regexFilterExpressions.copy;
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


+ (NSArray<NSRegularExpression *>*) regexForHostFilterString:(NSString *)filterString error:(NSError **)error
{
    if (filterString.length == 0) {
        
        return nil;
        
    } else {
        // Check if host string has a dot "." prefix to disable subdomain matching
        if (filterString.length > 1 && [filterString hasPrefix:@"."]) {
            // Get host string without the "." prefix
            filterString = [filterString substringFromIndex:1];
            // Get regex for host <*://example.com> (without possible subdomains)
            return @[[self regexForFilterString:filterString error:error]];
        }
        // Allow subdomain matching: Create two regex strings for <example.com> and <*.example.com>
        NSString *regexString = [NSRegularExpression escapedPatternForString:filterString];
        regexString = [regexString stringByReplacingOccurrencesOfString:@"\\*" withString:@".*?"];
        
        // Add regex command characters for matching at start and end of a line (part)
        NSString *regexString1 = [NSString stringWithFormat:@"^%@$", regexString];
        NSString *regexString2 = [NSString stringWithFormat:@"^(.*?\\.%@)$", regexString];
        NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:regexString1 options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:error];
        NSRegularExpression *regex2 = [NSRegularExpression regularExpressionWithPattern:regexString2 options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:error];
        return @[regex1, regex2];
    }
}


+ (NSArray<NSRegularExpression *>*) regexForPathFilterString:(NSString *)filterString error:(NSError **)error
{
    // Trim a possible trailing slash "/", we will instead add a rule to also match paths to directories without trailing slash
    filterString = [filterString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    
    if (filterString.length == 0) {
        
        return nil;
        
    } else {
        // Check if path string ends with a "/*" for matching contents of a directory
        if ([filterString hasSuffix:@"/*"]) {
            // As the path filter string matches for a directory, we need to add a string to match directories without trailing slash
            
            // Get path string without the "/*" suffix
            NSString *filterStringDirectory = [filterString substringToIndex:filterString.length-2];
            
            // Create two regex strings, to match with or without the trailing slash
            NSString *regexString = [NSRegularExpression escapedPatternForString:filterString];
            regexString = [regexString stringByReplacingOccurrencesOfString:@"\\*" withString:@".*?"];
            
            NSString *regexStringDir = [NSRegularExpression escapedPatternForString:filterStringDirectory];
            regexStringDir = [regexStringDir stringByReplacingOccurrencesOfString:@"\\*" withString:@".*?"];
            
            // Add regex command characters for matching at start and end of a line (part)
            NSString *regexString1 = [NSString stringWithFormat:@"^%@$", regexString];
            NSString *regexString2 = [NSString stringWithFormat:@"^%@$", regexStringDir];
            
            NSRegularExpression *regex1 = [NSRegularExpression regularExpressionWithPattern:regexString1 options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:error];
            NSRegularExpression *regex2 = [NSRegularExpression regularExpressionWithPattern:regexString2 options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:error];
            return @[regex1, regex2];
        } else {
            return @[[self regexForFilterString:filterString error:error]];
        }
    }
}


+ (NSRegularExpression *) regexForQueryFilterString:(NSString *)filterString error:(NSError **)error
{
    if (filterString.length == 0) {
        
        return nil;
        
    } else {
        if ([filterString isEqualToString:@"."]) {
            // Add regex command characters for matching at start and end of a line (part) and
            // regex for no string allowed
            NSString *regexString = @"^$";
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:error];
            return regex;
        } else {
            return [self regexForFilterString:filterString error:error];
        }
    }
}


- (NSString *) string
{
    NSMutableString *expressionString = [NSMutableString new];
    NSString *part;
    [expressionString appendString:@"^"];
    
    /// Scheme
    if (_scheme) {
        // If there is a regex filter for scheme
        // get stripped regex pattern
        part = [self stringForRegexFilter:_scheme];
    } else {
        // otherwise use the regex wildcard pattern for scheme
        part = @".*?";
    }
    [expressionString appendFormat:@"%@:\\/\\/", part];
    
    /// User/Password
    if (_user) {
        part = [self stringForRegexFilter:_user];
        
        [expressionString appendString:part];
        
        if (_password) {
            [expressionString appendFormat:@":%@@", [self stringForRegexFilter:_password]];
        } else {
            [expressionString appendString:@"@"];
        }
    }
    
    /// Host
    NSString *hostPort = @"";
    if (_host) {
        hostPort = [self stringForRegexFilter:_host];
    } else {
        hostPort = @".*?";
    }
    
    /// Port
    if (_port && (_port.integerValue > 0) && (_port.integerValue <= 65535)) {
        hostPort = [NSString stringWithFormat:@"%@:%@", hostPort, _port.stringValue];
    }
    
    // When there is a host, but no path
//    if (_host && !_path) {
//        hostPort = [NSString stringWithFormat:@"((%@)|(%@\\/.*?))", hostPort, hostPort];
//    }
    
    [expressionString appendString:hostPort];
    
    /// Path
    if (_path) {
        NSString *path = [self stringForRegexFilter:_path];
        if ([path hasPrefix:@"\\/"]) {
            [expressionString appendString:path];
        } else {
            [expressionString appendFormat:@"\\/%@", path];
        }
    }
    
    /// Query
//    if (_query) {
//        // Check for special case Query = "?." which means no query string is allowed
//        if ([[self stringForRegexFilter:_query] isEqualToString:@"."]) {
//            [expressionString appendFormat:@"[^\\?]"];
//        } else {
//            [expressionString appendFormat:@"\\?%@", [self stringForRegexFilter:_query]];
//        }
//    } else {
//        [expressionString appendFormat:@"(()|(\\?.*?))"];
//    }
    
    /// Fragment
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
