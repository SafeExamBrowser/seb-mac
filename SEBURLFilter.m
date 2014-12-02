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
#import "SEBURLFilterRegexExpression.h"
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
- (NSError *) updateFilterRules
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
    NSError *error;
    
    for (URLFilterRule in URLFilterRules) {
        
        if ([URLFilterRule[@"active"] boolValue] == YES) {
            
            NSString *expressionString = URLFilterRule[@"expression"];
            id expression;
            
            BOOL regex = [URLFilterRule[@"regex"] boolValue];
            if (regex) {
                expression = [NSRegularExpression regularExpressionWithPattern:expressionString options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&error];
            } else {
                expression = [SEBURLFilterRegexExpression regexFilterExpressionWithString:expressionString error:&error];
            }
            if (error) {
                [self.prohibitedList removeAllObjects];
                [self.permittedList removeAllObjects];
                return error;
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
    
    // Check if Start URL gets allowed by current filter rules and if not add a rule for the Start URL
    NSString *startURLString = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    NSURL *startURL = [NSURL URLWithString:startURLString];
    if (![self testURLAllowed:startURL]) {
        // If Start URL is not allowed: Create one using the full Start URL
        id expression = [SEBURLFilterRegexExpression regexFilterExpressionWithString:startURLString error:&error];
        if (error) {
            [self.prohibitedList removeAllObjects];
            [self.permittedList removeAllObjects];
            return error;
        }
        // Add this Start URL filter expression to the permitted filter list
        [self.permittedList addObject:expression];
    }
    // Updating filter rules worked; don't return any NSError
    return nil;
}


// Filter URL and return YES if it is allowed
- (BOOL) testURLAllowed:(NSURL *)URLToFilter
{
    NSString* URLToFilterString = [URLToFilter absoluteString];
    // By default URLs are blocked
    BOOL allowURL = NO;
    BOOL blockURL = NO;
    id expression;
    
    /// Apply current filter rules (expressions/actions) to URL
    /// Apply prohibited filter expressions
    
    for (expression in self.prohibitedList) {
        
        if ([expression isKindOfClass:[NSRegularExpression class]]) {
            if ([self regexFilterExpression:expression hasMatchesInString:URLToFilterString]) {
                blockURL = YES;
                break;
            }
        }
        
        if ([expression isKindOfClass:[SEBURLFilterRegexExpression class]]) {
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
        
        if ([expression isKindOfClass:[NSRegularExpression class]]) {
            if ([self regexFilterExpression:expression hasMatchesInString:URLToFilterString]) {
                allowURL = YES;
                break;
            }
        }
        
        if ([expression isKindOfClass:[SEBURLFilterRegexExpression class]]) {
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
// and returning YES (= allow or block) if it matches
- (BOOL) URL:(NSURL *)URLToFilter matchesFilterExpression:(SEBURLFilterRegexExpression *)filterExpression
{
    NSRegularExpression *filterComponent;
    
    // If a scheme is indicated in the filter expression, it has to match
    filterComponent = filterExpression.scheme;
    if (filterComponent &&
        ![self regexFilterExpression:filterComponent hasMatchesInString:URLToFilter.scheme]) {
            // Scheme of the URL to filter doesn't match the one from the filter expression: Exit with matching = NO
            return NO;
        }
    
    filterComponent = filterExpression.user;
    if (filterComponent &&
        ![self regexFilterExpression:filterComponent hasMatchesInString:URLToFilter.user]) {
            return NO;
        }
    
    filterComponent = filterExpression.password;
    if (filterComponent &&
        ![self regexFilterExpression:filterComponent hasMatchesInString:URLToFilter.password]) {
            return NO;
        }
    
    filterComponent = filterExpression.host;
    if (filterComponent &&
        ![self regexFilterExpression:filterComponent hasMatchesInString:URLToFilter.host]) {
            return NO;
        }
    
    if (filterExpression.port && URLToFilter.port &&
        URLToFilter.port.intValue != filterExpression.port.intValue) {
            return NO;
        }
    
    filterComponent = filterExpression.path;
    if (filterComponent &&
        ![self regexFilterExpression:filterComponent hasMatchesInString:URLToFilter.path]) {
            return NO;
        }
    
    filterComponent = filterExpression.query;
    if (filterComponent &&
        ![self regexFilterExpression:filterComponent hasMatchesInString:URLToFilter.query]) {
            return NO;
        }
    
    filterComponent = filterExpression.fragment;
    if (filterComponent &&
        ![self regexFilterExpression:filterComponent hasMatchesInString:URLToFilter.fragment]) {
            return NO;
        }
    
    // URL matches the filter expression
    return YES;
}


- (BOOL) regexFilterExpression:(NSRegularExpression *)regexFilter hasMatchesInString:(NSString *)stringToMatch
{
    if (!stringToMatch) return NO;
    return [regexFilter rangeOfFirstMatchInString:stringToMatch options:NSRegularExpressionCaseInsensitive |  NSRegularExpressionAnchorsMatchLines range:NSMakeRange(0, stringToMatch.length)].location != NSNotFound;
}


- (void) allowURL:(NSURL *)URLToAllow
{
    NSError *error;
    id expression;
    expression = [SEBURLFilterRegexExpression regexFilterExpressionWithString:URLToAllow.absoluteString error:&error];
    [self.permittedList addObject:expression];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSMutableArray *URLFilterRules = [NSMutableArray arrayWithArray:[preferences secureArrayForKey:@"org_safeexambrowser_SEB_URLFilterRules"]];
    NSDictionary *URLFilterRule = @{
                                    @"active" : @YES,
                                    @"regex" : @NO,
                                    @"action" : [NSNumber numberWithLong:URLFilterActionAllow],
                                    @"expression" : URLToAllow.absoluteString,
                                    };
    
    [URLFilterRules addObject:URLFilterRule];
    [preferences setSecureObject:URLFilterRules forKey:@"org_safeexambrowser_SEB_URLFilterRules"];

}


@end