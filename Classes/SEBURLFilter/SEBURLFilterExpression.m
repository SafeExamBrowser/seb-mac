//
//  SEBURLFilterExpression.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 22.11.14.
//  Copyright (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 2.0 (the "License"); you may not use this file except in
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
//  (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBURLFilterExpression.h"

@implementation SEBURLFilterExpression


+ (SEBURLFilterExpression *) filterExpressionWithString:(NSString *)filterExpressionString
{
    SEBURLFilterExpression *filterExpression = [SEBURLFilterExpression new];

    // Leading/trailing whitespace can't be part of a URL (and a whitespace-only
    // expression is treated like an empty one)
    filterExpressionString = [filterExpressionString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (filterExpressionString.length == 0) {
        return filterExpression;
    }

    // Split the simplified filter expression into its URL components. A SEB filter
    // expression is a pattern with wildcards (e.g. "host.org:*", "user:pw@*",
    // "*tp://host"), NOT a URL, so it must not be parsed with NSURL (which would,
    // for example, read "host.org" in "host.org:2020" as a URI scheme). We use the
    // same grammar as SEB for Windows (SimplifiedRule.URL_DELIMITER_PATTERN) so both
    // platforms split identical expressions identically. Groups:
    // 1 scheme, 2 user, 3 password, 4 host, 5 port, 6 path, 7 query, 8 fragment.
    static NSRegularExpression *delimiter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delimiter = [NSRegularExpression regularExpressionWithPattern:
                     @"(?:([^:]*)://)?(?:([^:@]*)(?::([^@]*))?@)?(?:([^/:?#]*))?(?::([0-9*]*))?([^?#]*)?(?:\\?([^#]*))?(?:#(.*))?"
                                                              options:0
                                                                error:NULL];
    });
    NSTextCheckingResult *match = [delimiter firstMatchInString:filterExpressionString options:0 range:NSMakeRange(0, filterExpressionString.length)];
    if (!match) {
        return filterExpression;
    }

    filterExpression.scheme = [self string:filterExpressionString group:1 inMatch:match];
    filterExpression.user = [self string:filterExpressionString group:2 inMatch:match];
    filterExpression.password = [self string:filterExpressionString group:3 inMatch:match];
    filterExpression.host = [self string:filterExpressionString group:4 inMatch:match];

    // Only a numeric port is a port constraint; "*" or empty means "any port"
    NSString *portString = [self string:filterExpressionString group:5 inMatch:match];
    if (portString.length > 0 &&
        [portString rangeOfCharacterFromSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]].location == NSNotFound) {
        filterExpression.port = @(portString.integerValue);
    }

    filterExpression.path = [[self string:filterExpressionString group:6 inMatch:match] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    filterExpression.query = [self string:filterExpressionString group:7 inMatch:match];
    filterExpression.fragment = [self string:filterExpressionString group:8 inMatch:match];

    return filterExpression;
}


// Returns the substring for a capture group, or nil if the group didn't match or is empty
+ (NSString *) string:(NSString *)string group:(NSUInteger)index inMatch:(NSTextCheckingResult *)match
{
    if (index >= match.numberOfRanges) {
        return nil;
    }
    NSRange range = [match rangeAtIndex:index];
    if (range.location == NSNotFound || range.length == 0) {
        return nil;
    }
    return [string substringWithRange:range];
}


- (id) initWithScheme:(NSString *)scheme user:(NSString *)user password:(NSString *)password host:(NSString *)host port:(NSNumber *)port path:(NSString *)path query:(NSString *)query fragment:(NSString *)fragment
{
    self = [super init];
    if (self) {
        _scheme = scheme;
        _user = user;
        _password = password;
        _host = host;
        _port = port;
        _path = path;
        _query = query;
        _fragment = fragment;
    }
    return self;
}


- (NSString *) string
{
    NSMutableString *expressionString = [NSMutableString new];
    if (_scheme.length > 0) {
        if (_host.length > 0) {
            [expressionString appendFormat:@"%@://", _scheme];
        } else {
            [expressionString appendFormat:@"%@:", _scheme];
        }
    }
    if (_user.length > 0) {
        [expressionString appendString:_user];
        
        if (_password.length > 0) {
            [expressionString appendFormat:@":%@@", _password];
        } else {
            [expressionString appendString:@"@"];
        }
    }
    if (_host.length > 0) {
        [expressionString appendString:_host];
    }
    if (_port && (_port.integerValue > 0) && (_port.integerValue <= 65535)) {
        [expressionString appendFormat:@":%@", _port.stringValue];
    }
    if (_path.length > 0) {
        if ([_path hasPrefix:@"/"]) {
            [expressionString appendString:_path];
        } else {
            [expressionString appendFormat:@"/%@", _path];
        }
    }
    if (_query.length > 0) {
        [expressionString appendFormat:@"?%@", _query];
    }
    if (_fragment.length > 0) {
        [expressionString appendFormat:@"#%@", _fragment];
    }
    
    return expressionString;
}


@end
