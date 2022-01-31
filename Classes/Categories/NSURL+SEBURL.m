//
//  NSURL+SEBURL.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.11.14.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "NSURL+SEBURL.h"
#import "SEBURLFilterExpression.h"

@implementation NSURL (SEBURL)


+ (NSURL *) URLWithScheme:(NSString *)scheme user:(NSString *)user password:(NSString *)password host:(NSString *)host port:(NSNumber *)port path:(NSString *)path query:(NSString *)query fragment:(NSString *)fragment
{
//    NSURL *newURL;
    NSMutableString *newURLString = [NSMutableString new];
    if (scheme.length > 0) {
        [newURLString appendFormat:@"%@://", scheme];
    }
    if (user.length > 0) {
        [newURLString appendString:user];
        
        if (password.length > 0) {
            [newURLString appendFormat:@":%@@", password];
        } else {
            [newURLString appendString:@"@"];
        }
    }
    if (host.length > 0) {
        [newURLString appendString:host];
    }
    if (port && (port.integerValue > 0) && (port.integerValue <= 65535)) {
        [newURLString appendFormat:@":%@", port.stringValue];
    }
    if (path.length > 0) {
        if ([[path substringToIndex:1] isEqualToString:@"/"]) {
            [newURLString appendString:path];
        } else {
            [newURLString appendFormat:@"/%@", scheme];
        }
        
        if (![[path substringFromIndex:path.length-1] isEqualToString:@"/"]) {
            [newURLString appendString:@"/"];
        }
    }
    if (query.length > 0) {
        [newURLString appendFormat:@"?%@", query];
    }
    if (fragment.length > 0) {
        [newURLString appendFormat:@"#%@", fragment];
    }

    return [NSURL URLWithString:newURLString];
}

- (NSURL *) URLByReplacingScheme:(NSString *)scheme
{
    NSString *URLString = self.absoluteString;

    NSRange scanResult = [URLString rangeOfString:@"://"];
    if (scanResult.location != NSNotFound) {
        // URL contains a scheme: replace it with the new one
        URLString = [NSString stringWithFormat:@"%@%@", scheme, [URLString substringFromIndex:scanResult.location]];
    }

    return [NSURL URLWithString:URLString];
}

+ (NSURL *) fileURLWithPathString:(NSString *)pathString
{
    return [NSURL fileURLWithPath:pathString isDirectory:NO];
}

@end
