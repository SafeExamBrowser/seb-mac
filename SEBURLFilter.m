//
//  SEBURLFilter.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06.10.13.
//  Copyright (c) 2010-2014 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2014 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "SEBURLFilter.h"

@implementation SEBURLFilter

static SEBURLFilter *sharedSEBURLFilter = nil;

+ (SEBURLFilter *)sharedSEBURLFilter
{
    @synchronized(self)
    {
        if (sharedSEBURLFilter == nil)
        {
            sharedSEBURLFilter = [[self alloc] init];
        }
    }
    
    return sharedSEBURLFilter;
}


// Updates filter rule arrays with current settings (UserDefaults)
- (void) updateFilterRules
{
    
}


// Filter passed URL and return YES if it is allowed
- (BOOL) allowURL:(NSURL *)URLToFilter
{
    // By default URLs are blocked
    BOOL allowURL = NO;
    
    /// Apply current filter rules (expressions/actions) to URL
    /// Apply prohibited filter expressions
    
//    NSString *regEx = [NSString stringWithFormat:@".*%@.*", yourSearchString];
//    NSRange range = [stringToSearch rangeOfString:regEx options:NSRegularExpressionSearch];
//    if (range.location != NSNotFound) {
//        
//    }
    
    // Return YES if URL is allowed or NO if it should be blocked
    return allowURL;
}


- (NSString *)escapeBackslashes:(NSString *)regexString
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\\\" options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionAnchorsMatchLines | NSRegularExpressionAllowCommentsAndWhitespace error:&error];
    if (error == NULL)
    {
        return [regex stringByReplacingMatchesInString:regexString options:0 range:NSMakeRange(0, [regexString length]) withTemplate:@"\\\\"];
    }
    else
    {
        return regexString;
    }
}

@end
