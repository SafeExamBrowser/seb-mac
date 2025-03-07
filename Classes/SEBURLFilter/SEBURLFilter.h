//
//  SEBURLFilter.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06.10.13.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import <Foundation/Foundation.h>
#import "SEBURLFilterExpression.h"

NS_ASSUME_NONNULL_BEGIN

@interface SEBURLFilter : NSObject

@property (readwrite) BOOL enableURLFilter;
@property (readwrite) BOOL enableContentFilter;
@property (readwrite) BOOL learningMode;
@property (readwrite) NSInteger urlFilterMessage;
@property (strong) NSMutableArray *permittedList;
@property (strong) NSMutableArray *prohibitedList;
@property (strong) NSMutableArray *ignoreList;
@property (strong, nonatomic) NSArray<NSString*>*regexAllowList;
@property (strong, nonatomic) NSArray<NSString*>*regexBlockList;


+ (SEBURLFilter *) sharedSEBURLFilter;

- (NSError *) updateFilterRulesWithStartURL:(NSURL *)startURL;
- (NSError *) updateFilterRulesSebRules:(BOOL)updateSebRules withStartURL:(NSURL *)startURL;

- (NSError *) updateIgnoreRuleList;

- (void) clearIgnoreRuleList;

- (URLFilterRuleActions)testURLAllowed:(NSURL *)URLToFilter;

- (BOOL) testURLIgnored:(NSURL *)URLToFilter;

- (void) addRuleAction:(URLFilterRuleActions)action withFilterExpression:(SEBURLFilterExpression *)filterExpression;

- (NSArray <NSString*>*)permittedDomains;

@end

NS_ASSUME_NONNULL_END
