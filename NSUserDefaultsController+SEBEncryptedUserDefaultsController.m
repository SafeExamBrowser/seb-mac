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

@implementation NSUserDefaultsController (SEBEncryptedUserDefaultsController)


- (id)secureValueForKeyPath:(NSString *)keyPath
{
    if ([NSUserDefaults userDefaultsPrivate]) {
        NSArray *pathElements = [keyPath componentsSeparatedByString:@"."];
        NSString *key = [pathElements objectAtIndex:[pathElements count]-1];
        id value = [[NSUserDefaults privateUserDefaults] valueForKey:key];
        return value;
    } else {
        NSData *encrypted = [super valueForKeyPath:keyPath];
        
        if (encrypted == nil) {
            // Value = nil -> invalid
            return nil;
        }
        NSError *error;
        NSData *decrypted = [RNDecryptor decryptData:encrypted
                                        withPassword:@"password"
                                               error:&error];
        id value = [NSKeyedUnarchiver unarchiveObjectWithData:decrypted];
        return value;
    }
}


- (void)setSecureValue:(id)value forKeyPath:(NSString *)keyPath
{
    if ([NSUserDefaults userDefaultsPrivate]) {
        NSArray *pathElements = [keyPath componentsSeparatedByString:@"."];
        NSString *key = [pathElements objectAtIndex:[pathElements count]-1];
        [[NSUserDefaults privateUserDefaults] setValue:value forKey:key];
    } else {
        if (value == nil || keyPath == nil) {
            // Use non-secure method
            [super setValue:value forKeyPath:keyPath];
            
        } else {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
            NSError *error;
            NSData *encryptedData = [RNEncryptor encryptData:data
                                                withSettings:kRNCryptorAES256Settings
                                                    password:@"password"
                                                       error:&error];;
            [super setValue:encryptedData forKeyPath:keyPath];
        }
    }
}


@end
