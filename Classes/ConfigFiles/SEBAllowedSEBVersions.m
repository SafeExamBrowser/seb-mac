//
//  SEBAllowedSEBVersions.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 14.08.26.
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

#import "SEBAllowedSEBVersions.h"

#pragma mark - Helpers

/// Returns YES if the string consists solely of decimal digits (and is non-empty).
static BOOL SEBIsNonNegativeInteger(NSString *string)
{
    if (string.length == 0) {
        return NO;
    }
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [string rangeOfCharacterFromSet:nonDigits].location == NSNotFound;
}


#pragma mark - Parsed restriction

/// A single parsed version restriction (one entry of the sebAllowedVersions array).
@interface SEBVersionRestriction : NSObject
@property (nonatomic) SEBAllowedVersionPlatform platform;
@property (nonatomic) NSInteger major;
@property (nonatomic) NSInteger minor;
@property (nonatomic) NSInteger patch;
@property (nonatomic) NSInteger build;
@property (nonatomic) BOOL allianceEdition;
@property (nonatomic) BOOL minimum;
/// Number of version-number components explicitly specified (2...4).
@property (nonatomic) NSUInteger specifiedComponents;
+ (nullable instancetype)restrictionFromString:(NSString *)string;
/// The specified version components joined with ".", e.g. "3.9" or "3.4.1".
- (NSString *)versionString;
@end


@implementation SEBVersionRestriction

+ (nullable instancetype)restrictionFromString:(NSString *)string
{
    NSString *trimmed = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return nil;
    }
    NSArray<NSString *> *tokens = [trimmed componentsSeparatedByString:@"."];
    // At minimum OS.Major.Minor is required.
    if (tokens.count < 3) {
        return nil;
    }

    SEBVersionRestriction *restriction = [SEBVersionRestriction new];

    // OS token
    NSString *osToken = tokens[0];
    if ([osToken caseInsensitiveCompare:@"Mac"] == NSOrderedSame) {
        restriction.platform = SEBAllowedVersionPlatformMac;
    } else if ([osToken caseInsensitiveCompare:@"Win"] == NSOrderedSame) {
        restriction.platform = SEBAllowedVersionPlatformWin;
    } else if ([osToken caseInsensitiveCompare:@"iOS"] == NSOrderedSame) {
        restriction.platform = SEBAllowedVersionPlatformiOS;
    } else {
        return nil;
    }

    // Major and minor (required integers)
    if (!SEBIsNonNegativeInteger(tokens[1]) || !SEBIsNonNegativeInteger(tokens[2])) {
        return nil;
    }
    restriction.major = tokens[1].integerValue;
    restriction.minor = tokens[2].integerValue;

    // Remaining optional tokens, left to right: up to two integers (patch, build),
    // then optional "AE", then optional "min" (which must be last).
    NSUInteger numericComponents = 0;
    for (NSUInteger i = 3; i < tokens.count; i++) {
        NSString *token = tokens[i];
        if ([token caseInsensitiveCompare:@"min"] == NSOrderedSame) {
            if (restriction.minimum || i != tokens.count - 1) {
                return nil; // duplicate, or "min" not the last token
            }
            restriction.minimum = YES;
        } else if ([token caseInsensitiveCompare:@"AE"] == NSOrderedSame) {
            if (restriction.allianceEdition || restriction.minimum) {
                return nil; // duplicate, or "AE" after "min"
            }
            restriction.allianceEdition = YES;
        } else if (SEBIsNonNegativeInteger(token)) {
            if (restriction.allianceEdition || restriction.minimum || numericComponents >= 2) {
                return nil; // numeric token after AE/min, or more than patch+build
            }
            if (numericComponents == 0) {
                restriction.patch = token.integerValue;
            } else {
                restriction.build = token.integerValue;
            }
            numericComponents++;
        } else {
            return nil; // unknown token
        }
    }

    restriction.specifiedComponents = 2 + numericComponents;
    return restriction;
}

- (NSString *)versionString
{
    NSMutableArray<NSString *> *components = [NSMutableArray arrayWithObjects:
                                              @(self.major).stringValue,
                                              @(self.minor).stringValue, nil];
    if (self.specifiedComponents >= 3) {
        [components addObject:@(self.patch).stringValue];
    }
    if (self.specifiedComponents >= 4) {
        [components addObject:@(self.build).stringValue];
    }
    return [components componentsJoinedByString:@"."];
}

@end


#pragma mark - SEBAllowedSEBVersions

@implementation SEBAllowedSEBVersions

- (BOOL)allowedSEBVersion:(NSString *)version
              buildNumber:(nullable NSString *)build
                 platform:(SEBAllowedVersionPlatform)platform
          allianceEdition:(BOOL)allianceEdition
       fromVersionStrings:(nullable NSArray<NSString *> *)restrictions
{
    if (restrictions.count == 0) {
        return YES; // No restriction specified: any version is allowed.
    }

    NSArray<NSNumber *> *running = [self versionComponentsForVersion:version buildNumber:build];

    NSUInteger validRestrictionCount = 0;
    BOOL foundRelevantRestriction = NO;
    for (NSString *restrictionString in restrictions) {
        SEBVersionRestriction *restriction = [SEBVersionRestriction restrictionFromString:restrictionString];
        if (!restriction) {
            DDLogWarn(@"%s Ignoring empty or malformed sebAllowedVersions entry: %@", __FUNCTION__, restrictionString);
            continue;
        }
        validRestrictionCount++;
        if (restriction.platform != platform) {
            continue; // Restriction is for another platform.
        }
        foundRelevantRestriction = YES;
        // Alliance Edition must match exactly (this build's AE flag vs. the restriction's).
        if (restriction.allianceEdition != allianceEdition) {
            continue;
        }
        if ([self running:running satisfiesRestriction:restriction]) {
            return YES;
        }
    }

    if (validRestrictionCount == 0) {
        // The list contained only empty/malformed entries: treat it as no restriction
        // rather than blocking (e.g. an accidentally added blank row).
        DDLogWarn(@"%s sebAllowedVersions contained only empty/malformed entries; treating as no restriction.", __FUNCTION__);
        return YES;
    }

    if (!foundRelevantRestriction) {
        DDLogWarn(@"%s sebAllowedVersions specifies no version for this platform; running build is not allowed.", __FUNCTION__);
    }
    // A restriction list with valid entries but no satisfiable one for this platform
    // means the running build is not among the allowed versions.
    return NO;
}


- (nullable NSString *)requirementDescriptionForPlatform:(SEBAllowedVersionPlatform)platform
                                                 appName:(NSString *)appName
                                      fromVersionStrings:(nullable NSArray<NSString *> *)restrictions
{
    if (restrictions.count == 0) {
        return nil;
    }

    NSMutableArray<NSString *> *minVersions = [NSMutableArray array];
    NSMutableArray<NSString *> *exactVersions = [NSMutableArray array];
    for (NSString *restrictionString in restrictions) {
        SEBVersionRestriction *restriction = [SEBVersionRestriction restrictionFromString:restrictionString];
        // Skip malformed entries, entries for other platforms and Alliance-Edition
        // entries (this build is never AE, so they can't apply).
        if (!restriction || restriction.platform != platform || restriction.allianceEdition) {
            continue;
        }
        if (restriction.minimum) {
            [minVersions addObject:restriction.versionString];
        } else {
            [exactVersions addObject:restriction.versionString];
        }
    }

    if (minVersions.count == 0 && exactVersions.count == 0) {
        return [NSString stringWithFormat:NSLocalizedString(@"This version of %@ is not allowed for this exam.", @""), appName];
    }

    NSString *minClause = nil;
    if (minVersions.count > 0) {
        NSString *joined = [minVersions componentsJoinedByString:@", "];
        minClause = minVersions.count == 1 ?
            [NSString stringWithFormat:NSLocalizedString(@"%@ version %@ or higher", @""), appName, joined] :
            [NSString stringWithFormat:NSLocalizedString(@"one of the %@ versions %@ or higher", @""), appName, joined];
    }

    NSString *exactClause = nil;
    if (exactVersions.count > 0) {
        NSString *joined = [exactVersions componentsJoinedByString:@", "];
        exactClause = exactVersions.count == 1 ?
            [NSString stringWithFormat:NSLocalizedString(@"%@ version %@", @""), appName, joined] :
            [NSString stringWithFormat:NSLocalizedString(@"one of the %@ versions %@", @""), appName, joined];
    }

    NSString *requirement;
    if (minClause && exactClause) {
        requirement = [NSString stringWithFormat:NSLocalizedString(@"%@, or %@", @""), minClause, exactClause];
    } else {
        requirement = minClause ?: exactClause;
    }
    return [NSString stringWithFormat:NSLocalizedString(@"%@ is required for this exam.", @""), requirement];
}


#pragma mark - Private

/// Maps the running version string and build number into [major, minor, patch, build].
- (NSArray<NSNumber *> *)versionComponentsForVersion:(NSString *)version buildNumber:(nullable NSString *)build
{
    NSInteger major = 0, minor = 0, patch = 0;
    NSArray<NSString *> *parts = [version componentsSeparatedByString:@"."];
    if (parts.count > 0 && SEBIsNonNegativeInteger(parts[0])) {
        major = parts[0].integerValue;
    }
    if (parts.count > 1 && SEBIsNonNegativeInteger(parts[1])) {
        minor = parts[1].integerValue;
    }
    if (parts.count > 2 && SEBIsNonNegativeInteger(parts[2])) {
        patch = parts[2].integerValue;
    }
    // CFBundleVersion is treated as a single integer; -integerValue tolerates a nil
    // or non-numeric build (returns 0 / the leading integer).
    NSInteger buildNumber = build.integerValue;
    return @[@(major), @(minor), @(patch), @(buildNumber)];
}


/// Compares the running version against a restriction, considering only the
/// components the restriction explicitly specified.
- (BOOL)running:(NSArray<NSNumber *> *)running satisfiesRestriction:(SEBVersionRestriction *)restriction
{
    NSArray<NSNumber *> *required = @[@(restriction.major), @(restriction.minor),
                                      @(restriction.patch), @(restriction.build)];
    for (NSUInteger i = 0; i < restriction.specifiedComponents; i++) {
        NSInteger runningValue = running[i].integerValue;
        NSInteger requiredValue = required[i].integerValue;
        if (restriction.minimum) {
            if (runningValue > requiredValue) {
                return YES; // A newer component means the minimum is satisfied.
            }
            if (runningValue < requiredValue) {
                return NO;  // An older component means it is not.
            }
            // Equal component: continue comparing the next one.
        } else if (runningValue != requiredValue) {
            return NO; // Exact match required.
        }
    }
    // All specified components matched (exact) or were equal up to here (minimum).
    return YES;
}

@end
