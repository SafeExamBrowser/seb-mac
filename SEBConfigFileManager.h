//
//  SEBConfigFileManager.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 02.05.13.
//
//

#import <Foundation/Foundation.h>
#import "SEBController.h"
#import "Constants.h"

@interface SEBConfigFileManager : NSObject

@property (nonatomic, strong) SEBController *sebController;


// Decrypt, parse and save SEB settings to UserDefaults
-(BOOL) decryptSEBSettings:(NSData *)sebData;

// Read SEB settings from UserDefaults and encrypt them using provided security credentials
- (NSData *) encryptSEBSettingsWithPassword:(NSString *)settingsPassword
                               withIdentity:(SecIdentityRef) identityRef
                                 forPurpose:(sebConfigPurposes)configPurpose;

// Encrypt preferences using a certificate
- (NSData*) encryptData:(NSData*)data usingIdentity:(SecIdentityRef) identityRef;

// Encrypt preferences using a password
- (NSData*) encryptData:(NSData*)data usingPassword:password forPurpose:(sebConfigPurposes)configPurpose;

// Basic helper methods

- (NSString *) getPrefixStringFromData:(NSData **)data;

- (NSData *) getPrefixDataFromData:(NSData **)data withLength:(NSUInteger)prefixLength;


@end
