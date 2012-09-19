//
//  NSUserDefaults+SEBEncryptedUserDefaults.m
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

#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "RNCryptor.h"


@interface NSUserDefaults (SEBEncryptedUserDefaultsPrivate)

- (BOOL)_isValidPropertyListObject:(id)object;
- (id)_objectForKey:(NSString *)key;
- (NSString *)_hashObject:(id)object;
- (NSString *)_hashData:(NSData *)data;

@end


@implementation NSUserDefaults (SEBEncryptedUserDefaults)

static NSData *_secretData           = nil;
static NSData *_deviceIdentifierData = nil;

static NSUserDefaults *secureUserDefaults = nil;
static BOOL _usePrivateUserDefaults = NO;


+ (NSUserDefaults *)secureUserDefaults
{
    @synchronized(self)
    {
        if (secureUserDefaults == nil)
        {
            if (_usePrivateUserDefaults) {
                // private UserDefaults will be saved in memory
                secureUserDefaults = [[self alloc] init];
            } else {
                // StandardUserDefaults are saved in Preferences/org.safeexambrowser.Safe-Exam-Browser.plist
                secureUserDefaults = [NSUserDefaults secureUserDefaults];
            }
        }
    }
    
    return secureUserDefaults;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if (secureUserDefaults == nil)
        {
            secureUserDefaults = [super allocWithZone:zone];
            return secureUserDefaults;
        }
    }
    
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;
}

// Set user defaults to be stored privately in memory instead of StandardUserDefaults
+ (void)setUserDefaultsPrivate:(BOOL)flag
{
    _usePrivateUserDefaults=flag;
}


+ (void)setSecret:(NSString *)secret
{
	if (_secretData == nil) {
		_secretData = [[secret dataUsingEncoding:NSUTF8StringEncoding] retain];
	} else {
		NSAssert(NO, @"The secret has already been set");
	}
}

+ (void)setDeviceIdentifier:(NSString *)deviceIdentifier
{
	if (_deviceIdentifierData == nil) {
		_deviceIdentifierData = [[deviceIdentifier dataUsingEncoding:NSUTF8StringEncoding] retain];
	} else {
		NSAssert(NO, @"The device identifier has already been set");
	}
}

#pragma mark -
#pragma mark Read accessors

- (NSArray *)secureArrayForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object isKindOfClass:[NSArray class]]) {
		return object;
	} else {
		return nil;
	}
}

- (BOOL)secureBoolForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object respondsToSelector:@selector(boolValue)]) {
		return [object boolValue];
	} else {
		return NO;
	}
}

- (NSData *)secureDataForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object isKindOfClass:[NSData class]]) {
		return object;
	} else {
		return nil;
	}
}

- (NSDictionary *)secureDictionaryForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object isKindOfClass:[NSDictionary class]]) {
		return object;
	} else {
		return nil;
	}
}

- (float)secureFloatForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object respondsToSelector:@selector(floatValue)]) {
		return [object floatValue];
	} else {
		return 0.0f;
	}
}

- (NSInteger)secureIntegerForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object respondsToSelector:@selector(intValue)]) {
		return [object intValue];
	} else {
		return 0;
	}
}

- (id)secureObjectForKey:(NSString *)key
{
	id object = [self _objectForKey:key];
	return object;
}

- (NSArray *)secureStringArrayForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object isKindOfClass:[NSArray class]]) {
		for (id child in object) {
			if (![child isKindOfClass:[NSString class]]) {
				return nil;
			}
		}
		return object;
	} else {
		return nil;
	}
}

- (NSString *)secureStringForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object isKindOfClass:[NSString class]]) {
		return object;
	} else if ([object respondsToSelector:@selector(stringValue)]) {
		return [object stringValue];
	} else {
		return nil;
	}
}

- (double)secureDoubleForKey:(NSString *)key
{
	id object = [self secureObjectForKey:key];
	if ([object respondsToSelector:@selector(doubleValue)]) {
		return [object doubleValue];
	} else {
		return 0.0f;
	}
}


#pragma mark -
#pragma mark Write accessors

- (void)setSecureBool:(BOOL)value forKey:(NSString *)key
{
	[self setSecureObject:[NSNumber numberWithBool:value] forKey:key];
}


- (void)setSecureFloat:(float)value forKey:(NSString *)key
{
	[self setSecureObject:[NSNumber numberWithFloat:value] forKey:key];
}


- (void)setSecureInteger:(NSInteger)value forKey:(NSString *)key
{
	[self setSecureObject:[NSNumber numberWithInt:value] forKey:key];
}


- (void)setSecureObject:(id)value forKey:(NSString *)key
{
	if (value == nil || key == nil) {
		// Use non-secure method
		[self setObject:value forKey:key];
		
	} else if ([self _isValidPropertyListObject:value]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
        NSError *error;
        NSData *encryptedData = [[RNCryptor AES256Cryptor] encryptData:data password:@"password" error:&error];
        [self setObject:encryptedData forKey:key];
	}
}


- (void)setSecureString:(NSString *)value forKey:(NSString *)key
{
    [self setSecureObject:value forKey:key];
}


- (void)setSecureDouble:(double)value forKey:(NSString *)key
{
	[self setSecureObject:[NSNumber numberWithDouble:value] forKey:key];
}



// Convert property list object to secure data
- (NSData *)secureDataForObject:(id)value
{
	if ([self _isValidPropertyListObject:value]) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
        NSError *error;
        NSData *encryptedData = [[RNCryptor AES256Cryptor] encryptData:data password:@"password" error:&error];
        return encryptedData;
	} else {
        return nil;
    }
}


#pragma mark -
#pragma mark Private methods


- (BOOL)_isValidPropertyListObject:(id)object
{
	if ([object isKindOfClass:[NSData class]] || [object isKindOfClass:[NSString class]] ||
		[object isKindOfClass:[NSNumber class]] || [object isKindOfClass:[NSDate class]]) {
		return YES;
		
	} else if ([object isKindOfClass:[NSDictionary class]]) {
		for (NSString *key in object) {
			if (![self _isValidPropertyListObject:key]) {
				// Abort
				return NO;
			} else {
				id value = [object objectForKey:key];
				if (![self _isValidPropertyListObject:value]) {
					// Abort
					return NO;
				}
			}
		}
		return YES;
		
	} else if ([object isKindOfClass:[NSArray class]]) {
		for (id value in object) {
			if (![self _isValidPropertyListObject:value]) {
				// Abort
				return NO;
			}
		}
		return YES;
		
	} else {
		static NSString *format = @"*** -[NSUserDefaults setSecureObject:forKey:]: Attempt to insert non-property value '%@' of class '%@'.";
		NSLog(format, object, [object class]);
		return NO;
	}
}


- (id)_objectForKey:(NSString *)key
{
    NSData *encrypted = [self objectForKey:key];
		
	if (encrypted == nil) {
		// Value = nil -> invalid
		return nil;
	}
    NSError *error;
    NSData *decrypted = [[RNCryptor AES256Cryptor] decryptData:encrypted password:@"password" error:&error];
    id value = [NSKeyedUnarchiver unarchiveObjectWithData:decrypted];
	return value;
}


- (NSString *)_hashObject:(id)object
{
	if (_secretData == nil) {
		// Use if statement in case asserts are disabled
		NSAssert(NO, @"Provide a secret before using any secure writing or reading methods!");
		return nil;
	}
    
    // Copy object to make sure it is immutable (thanks Stephen)
    object = [[object copy] autorelease];
	
	// Archive & hash
	NSMutableData *archivedData = [[NSKeyedArchiver archivedDataWithRootObject:object] mutableCopy];
	[archivedData appendData:_secretData];
	if (_deviceIdentifierData != nil) {
		[archivedData appendData:_deviceIdentifierData];
	}
	NSString *hash = [self _hashData:archivedData];
	[archivedData release];
	
	return hash;
}


- (NSString *)_hashData:(NSData *)data
{
	const char *cStr = [data bytes];
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	CC_MD5(cStr, [data length], digest);
	
	static NSString *format = @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x";
	NSString *hash = [NSString stringWithFormat:format, digest[0], digest[1], 
														digest[2], digest[3],
														digest[4], digest[5],
														digest[6], digest[7],
														digest[8], digest[9],
														digest[10], digest[11],
														digest[12], digest[13],
														digest[14], digest[15]];
	return hash;
}

@end
