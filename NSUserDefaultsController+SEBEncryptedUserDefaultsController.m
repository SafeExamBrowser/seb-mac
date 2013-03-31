//
//  NSUserDefaultsController+SEBEncryptedUserDefaultsController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30.08.12.
//
//

#import "NSUserDefaultsController+SEBEncryptedUserDefaultsController.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "Constants.h"

@implementation NSUserDefaultsController (SEBEncryptedUserDefaultsController)


- (id)secureValueForKeyPath:(NSString *)keyPath
{
    if ([NSUserDefaults userDefaultsPrivate]) {
        NSArray *pathElements = [keyPath componentsSeparatedByString:@"."];
        NSString *key = [pathElements objectAtIndex:[pathElements count]-1];
        id value = [[NSUserDefaults privateUserDefaults] valueForKey:key];
        //id value = [self.defaults secureObjectForKey:key];
#ifdef DEBUG
        NSLog(@"keypath: %@ [[NSUserDefaults privateUserDefaults] valueForKey:%@]] = %@", keyPath, key, value);
#endif
        return value;
    } else {
        NSData *encrypted = [super valueForKeyPath:keyPath];
        
        if (encrypted == nil) {
            // Value = nil -> invalid
            return nil;
        }
        NSError *error;
        NSData *decrypted = [RNDecryptor decryptData:encrypted
                                        withPassword:userDefaultsMasala
                                               error:&error];
        id value = [NSKeyedUnarchiver unarchiveObjectWithData:decrypted];
#ifdef DEBUG
        NSLog(@"[super valueForKeyPath:%@] = %@ (decrypted)", keyPath, value);
#endif
        return value;
    }
}


- (void)setSecureValue:(id)value forKeyPath:(NSString *)keyPath
{
    if ([NSUserDefaults userDefaultsPrivate]) {
        NSArray *pathElements = [keyPath componentsSeparatedByString:@"."];
        NSString *key = [pathElements objectAtIndex:[pathElements count]-1];
        if (value == nil) value = [NSNull null];
        [[NSUserDefaults privateUserDefaults] setValue:value forKey:key];
        //[self.defaults setSecureObject:value forKey:key];
#ifdef DEBUG
        NSLog(@"keypath: %@ [[NSUserDefaults privateUserDefaults] setValue:%@ forKey:%@]", keyPath, value, key);
#endif
    } else {
        if (value == nil || keyPath == nil) {
            // Use non-secure method
            [super setValue:value forKeyPath:keyPath];
            
        } else {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
            NSError *error;
            NSData *encryptedData = [RNEncryptor encryptData:data
                                                withSettings:kRNCryptorAES256Settings
                                                    password:userDefaultsMasala
                                                       error:&error];;
#ifdef DEBUG
            NSLog(@"[super setValue:(encrypted %@) forKeyPath:%@]", value, keyPath);
#endif
            [super setValue:encryptedData forKeyPath:keyPath];
        }
    }
}


@end
