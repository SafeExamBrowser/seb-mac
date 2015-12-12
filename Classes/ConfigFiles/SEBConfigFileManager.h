//
//  SEBConfigFileManager.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 02.05.13.
//  Copyright (c) 2010-2015 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2015 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import <Foundation/Foundation.h>
#import "SEBConfigFileCredentials.h"

//#import "SEBController.h"


/**
 * @protocol    SEBConfigUIDelegate
 *
 * @brief       SEB config file controllers confirming to the SEBConfigUIDelegate
 *              protocol are displaying alerts and password dialogs for 
 *              SEBConfigFileManager.
 */
@protocol SEBConfigUIDelegate <NSObject>
/**
 * @name		Item Attributes
 */
@required
/**
 * @brief       The title of the dock item.
 * @details     This value will be used for the dock item's label which is displayed
 *              when the mouse pointer is moved over the dock item. If no label
 *              should be displayed, then this property has to be set to nil.
 */
- (NSString *) title;


@optional

/**
 * @brief       Target for the action to be performed when a mouse click on the
 *              dock item is performed.
 */
- (void) willReconfigureTemporary;

/**
 * @brief       Action to be performed when a mouse click on the dock item is
 *              performed.
 */
- (void) didReconfigureTemporaryForEditing:(BOOL)forEditing;

/**
 * @brief       Rectangular view to be displayed instead of an icon (when icon is nil).
 */
- (NSView *) view;

@end

/**
 * @class       SEBConfigFileManager
 *
 * @brief       SEBDockController implements a custom control which is designed to be a
 *              mixture of the OS X Dock and a Windows task bar, intended to provide an easy
 *              way of switching between allowed third party applications and resources or
 *              opening them if they are not yet running/open. All items placed in the
 *              SEB Dock have to be scalable (preferably rectangular), with a minimum size of
 *              32 points (32 or 64 pixels @2x resolution). The SEB Dock bar has a min.
 *              height of 40 points and is pinned to the botton of a screen.
 *              The SEB Dock is divided into three sections left, center and right.
 *              The item(s) in the left section are pinned to the left edge of the dock
 *              (and screen), the right section items to the right edge of the dock and
 *              the center items start at (are pinned to) the right edge of the left section.
 *              The center section can contain a scroll view so if a large number of
 *              center items don't fit into the space available for the center section,
 *              users can scroll the center section horizontally to show all items.
 *              Items in the right section are intended to be controls providing functions
 *              and information which should be accessible application wide (like a quit
 *              button, battery and current time/clock, WLAN control etc.).
 *
 * @details     SEBConfigFileManager handles the
 *              
 */
@interface SEBConfigFileManager : NSObject {
//@private
//    NSString *_currentConfigPassword;
//    BOOL _currentConfigPasswordIsHash;
    //SecKeyRef _currentConfigKeyRef;
}

@property (weak) id delegate;
@property BOOL currentConfigPasswordIsHash;

// Write-only properties
@property (nonatomic) NSString *currentConfigPassword;
@property (nonatomic) SecKeyRef currentConfigKeyRef;
// To make the getter unavailable
- (NSString *)currentConfigPassword UNAVAILABLE_ATTRIBUTE;
- (SecKeyRef)currentConfigKeyRef UNAVAILABLE_ATTRIBUTE;

// Load a SebClientSettings.seb file saved in the preferences directory
// and if it existed and was loaded, use it to re-configure SEB
- (BOOL) reconfigureClientWithSebClientSettings;

// Decrypt, parse and use new SEB settings
-(BOOL) storeDecryptedSEBSettings:(NSData *)sebData forEditing:(BOOL)forEditing forceConfiguringClient:(BOOL)forceConfiguringClient;

// Decrypt, parse and store SEB settings to UserDefaults
-(BOOL) storeDecryptedSEBSettings:(NSData *)sebData forEditing:(BOOL)forEditing;

-(void) storeIntoUserDefaults:(NSDictionary *)sebPreferencesDict;

// Read SEB settings from UserDefaults and encrypt them using provided security credentials
- (NSData *) encryptSEBSettingsWithPassword:(NSString *)settingsPassword
                             passwordIsHash:(BOOL) passwordIsHash
                               withIdentity:(SecIdentityRef) identityRef
                                 forPurpose:(sebConfigPurposes)configPurpose;

// Encrypt preferences using a certificate
- (NSData*) encryptData:(NSData*)data usingIdentity:(SecIdentityRef) identityRef;

// Encrypt preferences using a password
- (NSData*) encryptData:(NSData*)data usingPassword:(NSString *)password passwordIsHash:(BOOL)passwordIsHash forPurpose:(sebConfigPurposes)configPurpose;

// Basic helper methods

- (NSString *) getPrefixStringFromData:(NSData **)data;

- (NSData *) getPrefixDataFromData:(NSData **)data withLength:(NSUInteger)prefixLength;

- (void) showAlertCorruptedSettings;
- (void) showAlertCorruptedSettingsWithTitle:(NSString *)title andText:(NSString *)informativeText;

@end
