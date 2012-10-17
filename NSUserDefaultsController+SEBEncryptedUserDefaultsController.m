//
//  NSUserDefaultsController+SEBEncryptedUserDefaultsController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30.08.12.
//
//

#import "NSUserDefaultsController+SEBEncryptedUserDefaultsController.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "RNCryptor.h"

@implementation NSUserDefaultsController (SEBEncryptedUserDefaultsController)


- (id)secureValueForKeyPath:(NSString *)keyPath
{
    //if ([NSUserDefaults userDefaultsPrivate]) {
    //    return nil;
    //} else {
        NSData *encrypted = [super valueForKeyPath:keyPath];
        
        if (encrypted == nil) {
            // Value = nil -> invalid
            return nil;
        }
        NSError *error;
        NSData *decrypted = [[RNCryptor AES256Cryptor] decryptData:encrypted password:@"password" error:&error];
        id value = [NSKeyedUnarchiver unarchiveObjectWithData:decrypted];
        return value;
    //}
}


- (void)setSecureValue:(id)value forKeyPath:(NSString *)keyPath
{
	if (value == nil || keyPath == nil) {
		// Use non-secure method
		[super setValue:value forKeyPath:keyPath];
		
	} else {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
        NSError *error;
        NSData *encryptedData = [[RNCryptor AES256Cryptor] encryptData:data password:@"password" error:&error];
        [super setValue:encryptedData forKeyPath:keyPath];
	}
}


@end
