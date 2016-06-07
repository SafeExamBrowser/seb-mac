//
//  SEBCryptor.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24.01.13.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider,
//  Dirk Bauer, Karsten Burger, Marco Lehre,
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

@interface SEBCryptor : NSObject {
    
    @private
    NSData *_currentKey;
}

//@property (nonatomic, readwrite, strong) NSData *HMACKey;

+ (SEBCryptor *)sharedSEBCryptor;

- (BOOL) hasDefaultsKey;
- (BOOL) updateUDKey;
- (NSData *) encryptData:(NSData *)data forKey:(NSString *)key error:(NSError **)error;
- (NSData *) decryptData:(NSData *)encryptedData forKey:(NSString *)key error:(NSError **)error;

- (BOOL) checkExamSettings:(NSData *)examSettingsKey;
- (void) updateExamSettingsKey:(NSDictionary *)settings;
- (BOOL)updateEncryptedUserDefaults:(BOOL)updateUserDefaults updateSalt:(BOOL)generateNewSalt;
- (BOOL)updateEncryptedUserDefaults:(BOOL)updateUserDefaults updateSalt:(BOOL)generateNewSalt newChecksum:(NSData **)newChecksumPtr;
- (NSData *)checksumForPrefDictionary:(NSDictionary *)prefsDict;
- (NSData *)checksumForLocalPrefDictionary:(NSDictionary *)prefsDict;

- (void)presentPreferencesCorruptedError;

- (NSData *)generateExamKeySalt;

- (NSData*) generateSHAHash:(NSString*)inputString;
- (NSData*) generateSHAHashForData:(NSData *)inputData;

@end
