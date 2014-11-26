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
#import "NSURL+SEBURL.h"
#import "SEBURLFilterExpression.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"

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
    if (self.prohibitedList) {
        [self.prohibitedList removeAllObjects];
    } else {
        self.prohibitedList = [NSMutableArray new];
    }
    if (self.permittedList) {
        [self.permittedList removeAllObjects];
    } else {
        self.permittedList = [NSMutableArray new];
    }
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    self.enableURLFilter = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_URLFilterEnable"];
    self.enableContentFilter = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_URLFilterEnableContentFilter"];
    
    NSArray *URLFilterRules = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_URLFilterRules"];
    NSDictionary *URLFilterRule;
    
    for (URLFilterRule in URLFilterRules) {
        
        if ([URLFilterRule[@"active"] boolValue] == YES) {
            
            NSString *expressionString = URLFilterRule[@"expression"];
            id expression;
            
            BOOL regex = [URLFilterRule[@"regex"] boolValue];
            if (regex) {
                expression = expressionString;
            } else {
                expression = [SEBURLFilterExpression filterExpressionWithString:expressionString];
            }
            
            int action = [URLFilterRule[@"action"] intValue];
            switch (action) {
                case URLFilterActionBlock:
                    [self.prohibitedList addObject:expression];
                    break;
                    
                case URLFilterActionAllow:
                    [self.permittedList addObject:expression];
                    break;
            }
        }
    }
}


// Filter passed URL and return YES if it is allowed
- (BOOL) allowURL:(NSURL *)URLToFilter
{
    NSString* URLToFilterString = [URLToFilter absoluteString];
    // By default URLs are blocked
    BOOL allowURL = NO;
    BOOL blockURL = NO;
    id expression;
    
    /// Apply current filter rules (expressions/actions) to URL
    /// Apply prohibited filter expressions
    
    for (expression in self.prohibitedList) {
        
        if ([expression isKindOfClass:[NSString class]]) {
            NSRange range = [URLToFilterString rangeOfString:expression options:NSRegularExpressionSearch || NSCaseInsensitiveSearch];
            if (range.location != NSNotFound) {
                blockURL = YES;
                break;
            }
        }
        
        if ([expression isKindOfClass:[SEBURLFilterExpression class]]) {
            if ([self URL:(NSURL *)URLToFilter matchesFilterExpression:expression]) {
                blockURL = YES;
                break;
            }
        }
    }
    if (blockURL) {
        return NO;
    }
    
    /// Apply permitted filter expressions
    
    for (expression in self.permittedList) {
        
        if ([expression isKindOfClass:[NSString class]]) {
            NSRange range = [URLToFilterString rangeOfString:expression options:NSRegularExpressionSearch || NSCaseInsensitiveSearch];
            if (range.location != NSNotFound) {
                allowURL = YES;
                break;
            }
        }
        
        if ([expression isKindOfClass:[SEBURLFilterExpression class]]) {
            if ([self URL:(NSURL *)URLToFilter matchesFilterExpression:expression]) {
                allowURL = YES;
                break;
            }
        }
    }
    // Return YES if URL is allowed or NO if it should be blocked
    return allowURL;
}


// Method comparing all components of a passed URL with the filter expression
// and returning YES (= block) if it matches
- (BOOL) URL:(NSURL *)URLToFilter matchesFilterExpression:(SEBURLFilterExpression *)filterExpression
{
    NSString *filterComponent;
    
    // If a scheme is indicated in the filter expression, it has to match
    filterComponent = filterExpression.scheme;
    if (filterComponent.length > 0 &&
        [URLToFilter.scheme rangeOfString:filterComponent
                                  options:NSRegularExpressionSearch || NSCaseInsensitiveSearch].location == NSNotFound) {
            // Scheme of the URL to filter doesn't match the one from the filter expression: Exit with matching = NO
            return NO;
        }
    
    filterComponent = filterExpression.user;
    if (filterComponent.length > 0 &&
        [URLToFilter.user rangeOfString:filterComponent
                                options:NSRegularExpressionSearch || NSCaseInsensitiveSearch].location == NSNotFound) {
            return NO;
        }
    
    filterComponent = filterExpression.password;
    if (filterComponent.length > 0 &&
        [URLToFilter.password rangeOfString:filterComponent
                                options:NSRegularExpressionSearch || NSCaseInsensitiveSearch].location == NSNotFound) {
            return NO;
        }
    
    filterComponent = filterExpression.host;
    if (filterComponent.length > 0 &&
        [URLToFilter.host rangeOfString:filterComponent
                                options:NSRegularExpressionSearch || NSCaseInsensitiveSearch].location == NSNotFound) {
            return NO;
        }
    
    if (filterExpression.port && URLToFilter.port &&
        URLToFilter.port.intValue != filterExpression.port.intValue) {
            return NO;
        }
    
    filterComponent = filterExpression.path;
    if (filterComponent.length > 0 &&
        [URLToFilter.path rangeOfString:filterComponent
                                options:NSRegularExpressionSearch || NSCaseInsensitiveSearch].location == NSNotFound) {
            return NO;
        }
    
    filterComponent = filterExpression.query;
    if (filterComponent.length > 0 &&
        [URLToFilter.query rangeOfString:filterComponent
                                options:NSRegularExpressionSearch || NSCaseInsensitiveSearch].location == NSNotFound) {
            return NO;
        }
    
    filterComponent = filterExpression.fragment;
    if (filterComponent.length > 0 &&
        [URLToFilter.fragment rangeOfString:filterComponent
                                options:NSRegularExpressionSearch || NSCaseInsensitiveSearch].location == NSNotFound) {
            return NO;
        }
    
    return YES;
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
