//
//  SEBSettings.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 21.08.17.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import <Foundation/Foundation.h>

/**
 * @protocol    SEBExtension
 *
 * @brief       Classes conforming to the SEBExtension protocol provide
 *              default values for additional settings used in the extension.
 */
@protocol SEBExtension <NSObject>
/**
 * @name        Item Attributes
 */
@required
/**
 * @brief       Provides default values for settings used by the extension.
 *              The key name identifies a settings dictionary, at least "rootSettings"
 *              must be provided.
 */
+ (NSDictionary *)defaultSettings;

@optional
/**
 * @brief       Provides default values for exam settings used by the extension.
 *              The key name identifies a settings dictionary, at least "rootSettings"
 *              must be provided.
 */
+ (NSDictionary *)defaultExamSettings;


@end


@interface SEBSettings : NSDictionary

+ (SEBSettings *)sharedSEBSettings;

@property (strong, nonatomic) NSDictionary *defaultSettings;
@property (strong, nonatomic) NSDictionary *defaultExamSettings;

- (NSDictionary *)defaultSEBSettings;

@end
