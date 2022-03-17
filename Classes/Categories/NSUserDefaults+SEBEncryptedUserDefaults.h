//
//  NSUserDefaults+SEBEncryptedUserDefaults.h
//  Secure-NSUserDefaults
//
//  Copyright (c) 2011 Matthias Plappert <matthiasplappert@me.com>
//  
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
//  to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
//  ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
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
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>


@interface NSUserDefaults (SEBEncryptedUserDefaults)

@property (strong, nonatomic) NSMutableDictionary *cachedUserDefaults;

@property (strong, atomic) NSNumber *logLevel;

// Return (and allocate if necessary) shared secure UserDefaults
+ (NSMutableDictionary *)privateUserDefaults;

// Set up method swizzling for private UserDefaults
+ (void)setupPrivateUserDefaults;

// Set user defaults to be stored privately in memory instead of StandardUserDefaults
+ (void)setUserDefaultsPrivate:(BOOL)flag;

+ (BOOL)userDefaultsPrivate;


- (id)persistedSecureObjectForKey:(NSString *)key;
- (void)setPersistedSecureObject:(id)value forKey:(NSString *)key;

- (BOOL)persistedSecureBoolForKey:(NSString *)key;
- (void)setPersistedSecureBool:(BOOL)boolValue forKey:(NSString *)key;


// Read data from user defaults. If key doesn't exist, valid is YES and the function mimics
// the return behavior of the respective non-secure method.

- (NSArray *)secureArrayForKey:(NSString *)key;
- (BOOL)secureBoolForKey:(NSString *)key;
- (NSData *)secureDataForKey:(NSString *)key;
- (NSDictionary *)secureDictionaryForKey:(NSString *)key;
- (float)secureFloatForKey:(NSString *)key;
- (NSInteger)secureIntegerForKey:(NSString *)key;
- (id)secureObjectForKey:(NSString *)key;
- (NSArray *)secureStringArrayForKey:(NSString *)key;
- (NSString *)secureStringForKey:(NSString *)key;
- (double)secureDoubleForKey:(NSString *)key;


// Write data to user defaults. Only property list objects (NSData, NSString, NSNumber, NSDate, NSArray, NSDictionary)
// are supported. Passing nil as either the value or key mimics the behavior of the non-secure method.

- (void)setSecureBool:(BOOL)value forKey:(NSString *)key;
- (void)setSecureFloat:(float)value forKey:(NSString *)key;
- (void)setSecureInteger:(NSInteger)value forKey:(NSString *)key;
- (void)setSecureObject:(id)value forKey:(NSString *)key;
- (void)setSecureString:(NSString *)value forKey:(NSString *)key;
- (void)setSecureDouble:(double)value forKey:(NSString *)key;

// Convert property list object to secure data
- (NSData *)secureDataForObject:(id)value andKey:(NSString *)key;

// Get value from another application’s preferences
- (id) valueForDefaultsDomain:(NSString *)domain key:(NSString *)key;

// Store value to another application’s preferences
- (void) setValue:(id)value forKey:(NSString *)key forDefaultsDomain:(NSString *)defaultsDomain;

// Get SEB's default settings key/values
- (NSDictionary *)sebDefaultSettings;

// Get SEB's default settings key/values for a specific dictionary, including all sub-dictionaries
- (NSDictionary *) getDefaultDictionaryForKey:(NSString *)dictionaryKey;

// Set default preferences for the case there are no user prefs yet
- (BOOL)setSEBDefaults;

- (BOOL)haveSEBUserDefaults;

// Get dictionary representation of all SEB user defaults
- (NSDictionary *)dictionaryRepresentationSEB;

// Filter UserDefaults so only org_safeexambrowser_SEB_ keys are included in the returned NSSet
- (NSSet *) sebKeysSet;

// Store settings dictionary into UserDefaults
- (void)storeSEBDictionary:(NSDictionary *)sebPreferencesDict;
// Write SEB default values to local preferences
- (void)storeSEBDefaultSettings;

- (NSString *)prefixKey:(NSString *)key;

- (void)resetSEBUserDefaults;
// Helper Method to get SEB's NSRegistrationDomain and application domain UserDefaults
- (NSDictionary *)getSEBUserDefaultsDomains;
- (BOOL)checkClassOfSettings:(NSDictionary *)sebPreferencesDict;

@end
