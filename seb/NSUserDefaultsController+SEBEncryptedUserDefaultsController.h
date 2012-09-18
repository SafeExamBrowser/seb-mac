//
//  NSUserDefaultsController+SEBEncryptedUserDefaultsController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30.08.12.
//
//

#import <Cocoa/Cocoa.h>

@interface NSUserDefaultsController (SEBEncryptedUserDefaultsController)

- (id)secureValueForKeyPath:(NSString *)keyPath;
- (void)setSecureValue:(id)value forKeyPath:(NSString *)keyPath;

@end
