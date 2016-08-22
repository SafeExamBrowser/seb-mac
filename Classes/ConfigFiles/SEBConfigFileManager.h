//
//  SEBConfigFileManager.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 02.05.13.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import <Foundation/Foundation.h>
#import "SEBController.h"

@class SEBController;

@interface SEBConfigFileManager : NSObject {
//@private
//    NSString *_currentConfigPassword;
//    BOOL _currentConfigPasswordIsHash;
    //SecKeyRef _currentConfigKeyRef;
}

@property (nonatomic, strong) SEBController *sebController;
@property BOOL currentConfigPasswordIsHash;
@property BOOL storeDecryptedSEBSettingsResult;
@property BOOL suppressFileFormatError;

// Write-only properties
@property (nonatomic) NSString *currentConfigPassword;
@property (nonatomic) SecKeyRef currentConfigKeyRef;
// To make the getter unavailable
- (NSString *)currentConfigPassword UNAVAILABLE_ATTRIBUTE;
- (SecKeyRef)currentConfigKeyRef UNAVAILABLE_ATTRIBUTE;

// Load a SebClientSettings.seb file saved in the preferences directory
// and if it existed and was loaded, use it to re-configure SEB
- (BOOL) reconfigureClientWithSebClientSettings;

// Decrypt, parse and store SEB settings to UserDefaults
-(storeDecryptedSEBSettingsResult) storeDecryptedSEBSettings:(NSData *)sebData forEditing:(BOOL)forEditing;
-(storeDecryptedSEBSettingsResult) storeDecryptedSEBSettings:(NSData *)sebData forEditing:(BOOL)forEditing suppressFileFormatError:(BOOL)suppressFileFormatError;

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
