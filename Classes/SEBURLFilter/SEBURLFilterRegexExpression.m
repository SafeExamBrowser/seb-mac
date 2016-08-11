//
//  SEBURLFilterRegexExpression.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 27.11.14.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider,
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
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
    filterExpression.path = [self regexForFilterString:[URLFromString.path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]] error:error];
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
    }
    
    /// Port
    if (_port && (_port.integerValue > 0) && (_port.integerValue <= 65535)) {
        hostPort = [NSString stringWithFormat:@"%@:%@", hostPort, _port.stringValue];
    }
    
    // When there is a host, but no path
    if (_host && !_path) {
        hostPort = [NSString stringWithFormat:@"((%@)|(%@\\/.*?))", hostPort, hostPort];
    }
    
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
    if (_query) {
        [expressionString appendFormat:@"\\?%@", [self stringForRegexFilter:_query]];
    }
    
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
