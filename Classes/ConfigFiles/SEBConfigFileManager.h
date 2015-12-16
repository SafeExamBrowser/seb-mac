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
 * @brief       Delegate method to display an enter password dialog with the
 *              passed message text
 */
- (NSString *) promptPasswordWithMessageText:(NSString *)messageText;

/**
 * @brief       Delegate method to display an alert when wrong password was entered
 */
- (void) showAlertWrongPassword;

/**
 * @brief       Delegate method to display an alert when settings are corrupted or
 *              in an incompatible format
 */
- (void) showAlertCorruptedSettings;

/**
 * @brief       Delegate method to display an alert with free title and text
 */
- (void) showAlertWithTitle:(NSString *)title andText:(NSString *)informativeText;

/**
 * @brief       Delegate method to display an alert asking if settings should 
 *              be saved unencrypted
 */
- (BOOL) saveSettingsUnencrypted;

/**
 * @brief       Delegate method to display a NSError
 */
- (void) presentErrorAlert:(NSError *)error;

@optional

/**
 * @brief       Delegate method called before SEB is getting reconfigured temporarily
 *              for starting an exam.
 */
- (void) willReconfigureTemporary;

/**
 * @brief       Delegate method called after SEB was reconfigured temporarily for
 *              starting an exam.
 */
- (void) didReconfigureTemporaryForEditing:(BOOL)forEditing sebFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials;

/**
 * @brief       Delegate method called before SEB is getting reconfigured temporarily
 *              for starting an exam.
 */
- (void) willReconfigurePermanently;

/**
 * @brief       Delegate method called after SEB was reconfigured temporarily for
 *              starting an exam.
 */
- (void) didReconfigurePermanentlyForceConfiguringClient:(BOOL)forceConfiguringClient sebFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials;

@end

/**
 * @class       SEBConfigFileManager
 *
 * @brief       SEBConfigFileManager implements a methods to deal with settings contained in
 *              .seb config files, which usually will be encrypted with a password or a$
 *              cryptographic identity (certificate and private key)
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

@end
