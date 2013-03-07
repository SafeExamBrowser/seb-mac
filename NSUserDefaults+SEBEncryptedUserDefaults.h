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

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>


@interface NSUserDefaults (SEBEncryptedUserDefaults)

// Return (and allocate if necessary) shared secure UserDefaults
+ (NSMutableDictionary *)privateUserDefaults;

// Set up method swizzling for private UserDefaults
+ (void)setupPrivateUserDefaults;

// Set user defaults to be stored privately in memory instead of StandardUserDefaults
+ (void)setUserDefaultsPrivate:(BOOL)flag;

+ (BOOL)userDefaultsPrivate;

/**
 * Sets the secret. Make sure that your secret is stored in a save place, it is recommanded to write it
 * directly into your code. Required property.
 */
+ (void)setSecret:(NSString *)secret;

/**
 * Sets the device identifier. You can use this to link user defaults to a specific machine.
 * This is particularly useful if users are likely to share plist files, e.g. if you use user defaults
 * to store product license information. Optional property.
 */
+ (void)setDeviceIdentifier:(NSString *)deviceIdentifier;

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
- (NSData *)secureDataForObject:(id)value;

// 
- (NSDictionary *)sebDefaultSettings;

// Get dictionary representation of all SEB user defaults
- (NSDictionary *)dictionaryRepresentationSEB;

@end
