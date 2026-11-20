//
//  SEBURLFilter.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06.10.13.
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


#import "SEBURLFilter.h"
#import "NSURL+SEBURL.h"
#import "SEBURLFilterRegexExpression.h"
#import "SEBCryptor.h"

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


// Returns the filter expressions for a filter rule expression string. Returns an
// empty array for an expression which is empty, whitespace-only or can't be parsed
// (such an expression would otherwise match every URL), or nil and an error if a
// regex expression is invalid
+ (nullable NSArray *) filterExpressionsForExpressionString:(id)expressionString regex:(BOOL)regex error:(NSError **)error
{
    if (![expressionString isKindOfClass:[NSString class]] ||
        [expressionString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        return @[];
    }
    NSError *expressionError;
    NSArray *expressions;
    if (regex) {
        NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:expressionString options:NSRegularExpressionCaseInsensitive | NSRegularExpressionAnchorsMatchLines error:&expressionError];
        expressions = regularExpression ? @[regularExpression] : nil;
    } else {
        expressions = [SEBURLFilterRegexExpression regexFilterExpressionWithString:expressionString error:&expressionError];
        if (!expressionError && expressions.count == 0) {
            DDLogWarn(@"%s: Ignoring URL filter expression '%@', as it can't be parsed", __FUNCTION__, expressionString);
        }
    }
    if (expressionError || !expressions) {
        DDLogError(@"%s: Invalid URL filter expression '%@' (regex: %d): %@", __FUNCTION__, expressionString, regex, expressionError);
        if (error) {
            *error = expressionError ? expressionError : [NSError errorWithDomain:NSCocoaErrorDomain code:NSFormattingError userInfo:nil];
        }
        return nil;
    }
    return expressions;
}


// Updates filter rule arrays with current settings (UserDefaults)
- (NSError *) updateFilterRulesWithStartURL:(NSURL *)startURL
{
    return [self updateFilterRulesSebRules:NO withStartURL:startURL];
}


// Adds the filter expressions of the active rules in the passed rule list to the
// permitted/prohibited lists. Invalid rules (malformed regex, non-dictionary
// entries) are skipped so a single bad rule doesn't discard the whole filter;
// returns the first error encountered (nil if all rules were valid).
- (NSError *) addFilterRuleExpressionsFromRules:(NSArray *)URLFilterRules
{
    NSError *firstError;

    for (id URLFilterRule in URLFilterRules) {
        // Settings could contain anything, so skip rule entries which aren't a dictionary
        if (![URLFilterRule isKindOfClass:[NSDictionary class]]) {
            DDLogWarn(@"%s: Ignoring URL filter rule which isn't a dictionary: %@", __FUNCTION__, URLFilterRule);
            continue;
        }

        if ([URLFilterRule[@"active"] boolValue] == YES) {

            NSError *error;
            NSArray *expressions = [SEBURLFilter filterExpressionsForExpressionString:URLFilterRule[@"expression"] regex:[URLFilterRule[@"regex"] boolValue] error:&error];
            if (!expressions) {
                // This single rule couldn't be parsed: skip it (it was logged in the
                // helper) and remember the error, but keep the other valid rules
                if (!firstError) {
                    firstError = error;
                }
                continue;
            }
            if (expressions.count > 0) {
                int action = [URLFilterRule[@"action"] intValue];
                switch (action) {
                    case URLFilterActionBlock:
                        [self.prohibitedList addObjectsFromArray:expressions];
                        break;

                    case URLFilterActionAllow:
                        [self.permittedList addObjectsFromArray:expressions];
                        break;
                }
            }
        }
    }
    return firstError;
}


// Updates filter rule arrays with current settings (UserDefaults)
- (NSError *) updateFilterRulesSebRules:(BOOL)updateSebRules withStartURL:(NSURL *)startURL
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
    self.urlFilterMessage = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_URLFilterMessage"];
    
    NSArray *URLFilterRules = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_URLFilterRules"];
    // A single invalid rule (e.g. a malformed regex) must not discard the whole
    // filter, so invalid rules are skipped and only the first error is remembered
    NSError *firstError = [self addFilterRuleExpressionsFromRules:URLFilterRules];

    // If URL filtering is enabled, then
    // check if Start URL gets allowed by current filter rules and if not add a rule for the Start URL
    NSString *startURLString = startURL.absoluteString;
    if (self.enableURLFilter && [self testURLAllowed:startURL] != URLFilterActionAllow) {
        // If Start URL is not allowed: Create one using the full Start URL
        NSError *error;
        NSArray *expressions = [SEBURLFilter filterExpressionsForExpressionString:startURLString regex:NO error:&error];
        if (expressions) {
            // Add this Start URL filter expression to the permitted filter list
            [self.permittedList addObjectsFromArray:expressions];
        } else if (!firstError) {
            firstError = error;
        }
    }

    // Return the first error encountered (nil if all rules were valid); invalid
    // individual rules were skipped, so the filter still applies the valid rules
    return firstError;
}


// Update Ignore List
- (NSError *) updateIgnoreRuleList
{
    // Remove all entries in the ignore list or create the mutable array if it didn't exist
    if (self.ignoreList) {
        [self.ignoreList removeAllObjects];
    } else {
        self.ignoreList = [NSMutableArray new];
    }
    
    // Read ignore list from settings and save it into the local array
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSArray *URLFilterIgnoreRules = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_URLFilterIgnoreList"];
    // Remember the first error, but keep the other valid ignore rules
    NSError *firstError;
    id expressionString;
    NSArray<SEBURLFilterRegexExpression*>*expressions;

    for (expressionString in URLFilterIgnoreRules) {
        // Empty/unparseable expressions are skipped, as an empty expression would
        // match (= ignore) every URL
        NSError *error;
        expressions = [SEBURLFilter filterExpressionsForExpressionString:expressionString regex:NO error:&error];
        if (!expressions) {
            // Skip this invalid entry but keep the other valid ignore rules
            if (!firstError) {
                firstError = error;
            }
            continue;
        }
        [self.ignoreList addObjectsFromArray:expressions];
    }
    return firstError;
}


// Clear Ignore List
- (void) clearIgnoreRuleList
{
    [self.ignoreList removeAllObjects];
    [[NSUserDefaults standardUserDefaults] setSecureObject:[NSArray array] forKey:@"org_safeexambrowser_SEB_URLFilterIgnoreList"];
}


- (NSArray<NSString*>*) regexFilterRuleStringsForSEBURLFilterRuleList:(NSArray*)filterRuleList
{
    if (filterRuleList.count == 0) {
        // No rules defined
        return @[];
    }
    id expression;
    NSMutableArray *regexFilterRuleStrings = [NSMutableArray new];
    for (expression in filterRuleList) {
        if (expression) {
            
            if ([expression isKindOfClass:[NSRegularExpression class]]) {
                [regexFilterRuleStrings addObject:[expression pattern]];
            }
            
            if ([expression isKindOfClass:[SEBURLFilterRegexExpression class]]) {
                [regexFilterRuleStrings addObjectsFromArray:[expression strings]];
            }
        }
    }
    return regexFilterRuleStrings.copy;
}

- (NSArray<NSString*>*)regexAllowList {
    return [self regexFilterRuleStringsForSEBURLFilterRuleList:self.permittedList];
}

- (NSArray<NSString*>*)regexBlockList {
    return [self regexFilterRuleStringsForSEBURLFilterRuleList:self.prohibitedList];
}


// Filter URL and return YES if it is allowed
- (URLFilterRuleActions) testURLAllowed:(NSURL *)URLToFilter
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
        return URLFilterActionBlock;
    }
    
    // Check if URL starts with "about:" and ignore such URLs
    if ([URLToFilter.scheme isEqualToString:@"about"]) {
        return URLFilterActionAllow;
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
    // Return URLFilterActionAllow if URL is allowed or
    // URLFilterActionUnknown if it's unknown (= it will anyways be blocked)
    return allowURL ? URLFilterActionAllow : URLFilterActionUnknown;
}


// Filter URL and return YES if it is allowed
- (BOOL) testURLIgnored:(NSURL *)URLToFilter
{
    // By default URLs are not ignored
    BOOL ignoreURL = NO;
    SEBURLFilterRegexExpression *expression;
    
    /// Apply current ignore filter rules (expressions) to URL
    for (expression in self.ignoreList) {
        
        if ([self URL:(NSURL *)URLToFilter matchesFilterExpression:expression]) {
            ignoreURL = YES;
            break;
        }
    }
    return ignoreURL;
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
    
    // Match userinfo against the empty string when the URL has none, so a userinfo
    // wildcard ("*@host") matches URLs without userinfo (as SEB for Windows does)
    filterComponent = filterExpression.user;
    if (filterComponent &&
        ![self regexFilterExpression:filterComponent hasMatchesInString:(URLToFilter.user ?: @"")]) {
        return NO;
    }

    filterComponent = filterExpression.password;
    if (filterComponent &&
        ![self regexFilterExpression:filterComponent hasMatchesInString:(URLToFilter.password ?: @"")]) {
        return NO;
    }

    filterComponent = filterExpression.host;
    if (filterComponent &&
        ![self regexFilterExpression:filterComponent hasMatchesInString:URLToFilter.host]) {
        return NO;
    }

    // If the filter expression specifies a port, the URL must carry that exact port.
    // A URL without a port therefore doesn't match a port-specific rule (SEB for
    // Windows compares the resolved port, which for a port-less URL is never equal).
    if (filterExpression.port &&
        (URLToFilter.port == nil || URLToFilter.port.intValue != filterExpression.port.intValue)) {
        return NO;
    }
    
    filterComponent = filterExpression.path;
    if (filterComponent &&
        ![self regexFilterExpression:filterComponent hasMatchesInString:[URLToFilter.path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]]]) {
        return NO;
    }
    
    filterComponent = filterExpression.query;
    if (filterComponent) {
        // If there's a query filter component, then we need to even filter empty URL query strings
        // as the filter might either allow some specific queries or no query at all ("?." query filter)
        NSString *queryString = URLToFilter.query;
        if (!queryString) {
            queryString = @"";
        }
        if (![self regexFilterExpression:filterComponent hasMatchesInString:queryString]) {
            return NO;
        }
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
    return [regexFilter rangeOfFirstMatchInString:stringToMatch options:NSRegularExpressionCaseInsensitive |
            NSRegularExpressionAnchorsMatchLines range:NSMakeRange(0, stringToMatch.length)].location != NSNotFound;
}


- (void) addRuleAction:(URLFilterRuleActions)action withFilterExpression:(SEBURLFilterExpression *)filterExpression
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSError *error;
    NSString *filterExpressionString = filterExpression.string;
    if (filterExpressionString.length > 0) {
        NSArray *expressions;
        expressions = [SEBURLFilterRegexExpression regexFilterExpressionWithString:filterExpressionString error:&error];
        if (!error && expressions.count > 0) {
            switch (action) {
                case URLFilterActionAllow:
                    [self.permittedList addObjectsFromArray:expressions];
                    break;
                    
                case URLFilterActionBlock:
                    [self.prohibitedList addObjectsFromArray:expressions];
                    break;
                    
                case URLFilterActionIgnore: {
                    // Add an filter rule expression to the ignore list
                    [self.ignoreList addObjectsFromArray:expressions];
                    // And to settings
                    NSMutableArray *URLFilterRules = [NSMutableArray arrayWithArray:[preferences secureArrayForKey:@"org_safeexambrowser_SEB_URLFilterIgnoreList"]];
                    [URLFilterRules addObject:filterExpression.string];
                    [preferences setSecureObject:URLFilterRules forKey:@"org_safeexambrowser_SEB_URLFilterIgnoreList"];
                    
                    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
                    
                    return;
                }
            }
            
            NSMutableArray *URLFilterRules = [NSMutableArray arrayWithArray:[preferences secureArrayForKey:@"org_safeexambrowser_SEB_URLFilterRules"]];
            NSMutableDictionary *URLFilterRule = [NSMutableDictionary dictionaryWithDictionary:@{
                @"active" : @YES,
                @"regex" : @NO,
                @"action" : [NSNumber numberWithLong:action],
                @"expression" : filterExpression.string,
            }];
            
            // Post a notification that a new filter rule action should be added
            [[NSNotificationCenter defaultCenter]
             postNotificationName:@"filterExpressionAdded" object:self userInfo:[NSDictionary dictionaryWithDictionary:URLFilterRule]];
            
            [URLFilterRules addObject:URLFilterRule];
            [preferences setSecureObject:URLFilterRules forKey:@"org_safeexambrowser_SEB_URLFilterRules"];
            
            [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
        }
    }
}


- (NSArray <NSString*>*) permittedDomains
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSArray *URLFilterRules = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_URLFilterRules"];
    NSMutableArray <NSString *>* permittedDomains = [NSMutableArray new];

    for (id URLFilterRule in URLFilterRules) {
        // Settings could contain anything, so skip rule entries which aren't a dictionary
        if (![URLFilterRule isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *expressionString = URLFilterRule[@"expression"];
        if ([expressionString isKindOfClass:[NSString class]] && expressionString.length > 0) {
            if ([URLFilterRule[@"regex"] boolValue] == NO &&
                [URLFilterRule[@"action"] intValue] == URLFilterActionAllow) {
                SEBURLFilterExpression *urlFromString = [SEBURLFilterExpression filterExpressionWithString:expressionString];
                // Expressions like "about:blank" don't contain a host
                if (urlFromString.host.length > 0) {
                    [permittedDomains addObject:urlFromString.host];
                }
            }
        }
    }
    return permittedDomains.copy;
}


@end
