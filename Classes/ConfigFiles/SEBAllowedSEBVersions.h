//
//  SEBAllowedSEBVersions.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SEBAllowedVersionPlatform) {
    SEBAllowedVersionPlatformMac,
    SEBAllowedVersionPlatformWin,
    SEBAllowedVersionPlatformiOS,
};

/// Evaluates whether the running SEB build satisfies the version restrictions
/// specified by the `sebAllowedVersions` configuration key.
///
/// A restriction string has the format `OS.Major.Minor.[Patch].[Build].[AE].[min]`
/// where the bracketed components are optional:
///  - OS: "Win", "Mac" or "iOS"
///  - Major, Minor: required integers
///  - Patch, Build: optional integers
///  - AE: optional literal "AE" token marking the Alliance Edition
///  - min: optional literal "min" token meaning "this version or newer"
///
/// The class is intentionally free of any AppKit / NSUserDefaults / MyGlobals
/// dependency so that it can be unit tested in isolation: the caller passes in the
/// running version, build number, platform and Alliance-Edition flag.
@interface SEBAllowedSEBVersions : NSObject

/// Returns YES if the running build is allowed to run with the given restrictions.
/// An empty or nil `restrictions` array means "no restriction" and returns YES.
/// A non-empty list that contains no satisfiable restriction for `platform` returns
/// NO (the running platform/version is not among the allowed ones).
- (BOOL)allowedSEBVersion:(NSString *)version
              buildNumber:(nullable NSString *)build
                 platform:(SEBAllowedVersionPlatform)platform
          allianceEdition:(BOOL)allianceEdition
       fromVersionStrings:(nullable NSArray<NSString *> *)restrictions;

/// Returns a localized, human-readable description of the version requirement for
/// the given platform, suitable for an alert's informative text (e.g. "SEB version
/// 3.9 or higher is required for this exam."). `appName` is the (possibly custom)
/// short application name substituted into the text (e.g. SEBShortAppName).
/// Returns nil if `restrictions` is empty or nil. Alliance-Edition-only
/// restrictions are omitted because this (non-AE) build can never satisfy them.
- (nullable NSString *)requirementDescriptionForPlatform:(SEBAllowedVersionPlatform)platform
                                                 appName:(NSString *)appName
                                      fromVersionStrings:(nullable NSArray<NSString *> *)restrictions;

@end

NS_ASSUME_NONNULL_END
