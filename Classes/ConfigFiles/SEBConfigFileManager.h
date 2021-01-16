//
//  SEBConfigFileManager.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 02.05.13.
//  Copyright (c) 2010-2020 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
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
//  (c) 2010-2020 Daniel R. Schneider, ETH Zurich, Educational Development
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
 *              passed message text asynchronously, calling the callback
 *              method with the entered password when one was entered
 */
- (void) promptPasswordWithMessageText:(NSString *)messageText
                              callback:(id)callback
                              selector:(SEL)aSelector;

/**
 * @brief       Delegate method to display an enter password dialog with the
 *              passed message text asynchronously, calling the callback
 *              method with the entered password when one was entered
 */
- (void) promptPasswordWithMessageText:(NSString *)messageText
                                 title:(NSString *)title
                              callback:(id)callback
                              selector:(SEL)aSelector;

/**
 * @brief       Delegate method to display an enter password dialog with the
 *              passed message text asynchronously, calling the callback
 *              method with the entered password when one was entered
 *              and executing the completion block with the final result
 *              (true = correct password entered)
 */
- (void) promptPasswordForHashedPassword:(NSString *)passwordHash
                             messageText:(NSString *)messageText
                                   title:(NSString *)title
                                attempts:(NSInteger)attempts
                                callback:(id)callback
                                selector:(SEL)aSelector
                       completionHandler:(void (^)(BOOL correctPasswordEntered))enteredPasswordHandler;

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
 * @brief       Delegate method to display an alert for an error
 */
- (void) showAlertWithError:(NSError *)error;

/**
 * @brief       Delegate method to display an alert with free title and text
 */
- (void) showAlertWithTitle:(NSString *)title
                    andText:(NSString *)informativeText;

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
- (void) didReconfigureTemporaryForEditing:(BOOL)forEditing
                        sebFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials;

/**
 * @brief       Delegate method called before SEB is getting reconfigured temporarily
 *              for starting an exam.
 */
- (void) willReconfigurePermanently;

/**
 * @brief       Delegate method called after SEB was reconfigured temporarily for
 *              starting an exam.
 */
- (void) didReconfigurePermanentlyForceConfiguringClient:(BOOL)forceConfiguringClient
                                      sebFileCredentials:(SEBConfigFileCredentials *)sebFileCrentials
                                   showReconfiguredAlert:(BOOL)showReconfiguredAlert;

/**
 * @brief       Delegate method to display an enter password dialog with the
 *              passed message text and title modally
 */
- (NSString *) promptPasswordWithMessageTextModal:(NSString *)messageText
                                            title:(NSString *)title;

/**
 * @brief       Delegate method to fetch persisted client settings
 */
- (NSData *) getSEBClientSettings;

@end

/**
 * @class       SEBConfigFileManager
 *
 * @brief       SEBConfigFileManager implements a methods to deal with settings contained in
 *              .seb config files, which usually will be encrypted with a password or a
 *              cryptographic identity (certificate and private key)
 *
 * @details     SEBConfigFileManager handles the
 *              
 */
@interface SEBConfigFileManager : NSObject {
@private
    NSData *encryptedSEBData;
    NSDictionary *parsedSEBPreferencesDict;
    NSInteger attempts;
    BOOL storeSettingsForEditing;
    BOOL storeSettingsForceConfiguringClient;
    BOOL storeShowReconfiguredAlert;
    id storeSettingsCallback;
    SEL storeSettingsSelector;
    SEBConfigFileCredentials *sebFileCredentials;
    
//    NSString *_currentConfigPassword;
//    BOOL _currentConfigPasswordIsHash;
    //NSData *_currentConfigKeyHash;
}

@property (weak) id delegate;
@property BOOL currentConfigPasswordIsHash;
@property StoreDecryptedSEBSettingsResult storeDecryptedSEBSettingsResult;
@property BOOL suppressFileFormatError;

// Write-only properties
@property (nonatomic) NSString *currentConfigPassword;
@property (nonatomic) NSData *currentConfigKeyHash;
// To make the getter unavailable
- (NSString *)currentConfigPassword UNAVAILABLE_ATTRIBUTE;
- (NSData *)currentConfigKeyHash UNAVAILABLE_ATTRIBUTE;


// Helper methods
- (NSString *) getHashedAdminPassword;
- (NSError *) errorCorruptedSettingsForUnderlyingError:(NSError *)error;
- (void) promptPasswordForHashedPassword:(NSString *)passwordHash
                             messageText:(NSString *)messageText
                                   title:(NSString *)title
                       completionHandler:(void (^)(BOOL correctPasswordEntered))enteredPasswordHandler;

// Load a SebClientSettings.seb file saved in the preferences directory
// and if it existed and was loaded, use it to re-configure SEB
- (void) reconfigureClientWithSebClientSettings;

// Reconfigure SEB with settings received from an MDM server
-(void) reconfigueClientWithMDMSettingsDict:(NSDictionary *)sebPreferencesDict
                                   callback:(id)callback
                                   selector:(SEL)selector;

// Decrypt, parse and store new SEB settings
// Method with selector in the callback object is called after storing settings
// was successful or aborted
-(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
                   callback:(id)callback
                   selector:(SEL)selector;

// Decrypt, parse and store new SEB settings
// When forceConfiguringClient don't show any notification to the user
// Method with selector in the callback object is called after storing settings
// was successful or aborted
-(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
                   callback:(id)callback
                   selector:(SEL)selector;


// Decrypt, parse and store new SEB settings
// When forceConfiguringClient, Exam Settings have the same effect as Client Settings
// When showReconfigureAlert=false then don't show the reconfigured notification to the user
// Method with selector in the callback object is called after storing settings
// was successful or aborted
-(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
      showReconfiguredAlert:(BOOL)showReconfiguredAlert
                   callback:(id)callback
                   selector:(SEL)selector;


-(void) storeIntoUserDefaults:(NSDictionary *)sebPreferencesDict;

// Inform the callback method if decrypting, parsing and storing new settings
// was successful (error = nil) or failed with some error
- (void) storeNewSEBSettingsSuccessful:(NSError *)error;

// Read SEB settings from UserDefaults and encrypt them using provided security credentials
- (NSData *) encryptSEBSettingsWithPassword:(NSString *)settingsPassword
                             passwordIsHash:(BOOL) passwordIsHash
                               withIdentity:(SecIdentityRef) identityRef
                                 forPurpose:(sebConfigPurposes)configPurpose;


@end
