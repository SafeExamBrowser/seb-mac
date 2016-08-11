//
//  SEBURLFilterExpression.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 22.11.14.
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

#import "SEBURLFilterExpression.h"

@implementation SEBURLFilterExpression


+ (SEBURLFilterExpression *) filterExpressionWithString:(NSString *)filterExpressionString
{
    SEBURLFilterExpression *filterExpression = [SEBURLFilterExpression new];
    
    // Check if filter expression contains a scheme
    NSString *scheme;
    NSURL *URLFromString;
    
    if (filterExpressionString.length > 0) {
        NSRange scanResult = [filterExpressionString rangeOfString:@"://"];
        if (scanResult.location != NSNotFound) {
            // Filter expression contains a scheme: save it and replace it with http
            // (in case scheme contains a wildcard [NSURL URLWithString:... fails)
            scheme = [filterExpressionString substringToIndex:scanResult.location];
            filterExpressionString = [NSString stringWithFormat:@"http%@", [filterExpressionString substringFromIndex:scanResult.location]];
            // Convert filter expression string to a NSURL
            URLFromString = [NSURL URLWithString:filterExpressionString];
        } else {
            // Filter expression doesn't contain a scheme followed by an authority part,
            // check for scheme followed by only a path (like about:blank or data:...)
            // Convert filter expression string to a NSURL
            URLFromString = [NSURL URLWithString:filterExpressionString];
            scheme = URLFromString.scheme;
            if (!scheme) {
                // Temporary prefix it with a http:// scheme
                filterExpressionString = [NSString stringWithFormat:@"http://%@", filterExpressionString];
                // Convert filter expression string to a NSURL
                URLFromString = [NSURL URLWithString:filterExpressionString];
            }
        }
    }
    
//    // Create a muatable array to hold results of scanning the filter expression for relevant separators
//    NSMutableArray *foundSeparators = [NSMutableArray new];
//    
//    /// Scan the filter expression string for all relevant URL separators
//    // Scan for the scheme separator
//    NSString *separator = @"://";
//    NSRange scanResult = [filterExpressionString rangeOfString:separator];
//    if (scanResult.location != NSNotFound) {
//        NSDictionary *foundSeparator = @{
//                                         @"separator" : separator,
//                                         @"location" : [NSNumber numberWithInteger:scanResult.location],
//                                         @"length" : [NSNumber numberWithInteger:scanResult.length],
//                                         };
//
//        [foundSeparators addObject:foundSeparator];
//    }
    
    /// Convert NSURL to a SEBURLFilterExpression
    // Use the saved scheme instead of the temporary http://
    filterExpression.scheme = scheme;
    filterExpression.user = URLFromString.user;
    filterExpression.password = URLFromString.password;
    filterExpression.host = URLFromString.host;
    filterExpression.port = URLFromString.port;
    filterExpression.path = [URLFromString.path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    filterExpression.query = URLFromString.query;
    filterExpression.fragment = URLFromString.fragment;
    
    return filterExpression;
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
    //    NSURL *newURL;
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
        
//        if (![_path hasSuffix:@"/"]) {
//            [expressionString appendString:@"/"];
//        }
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
