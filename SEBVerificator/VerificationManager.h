//
//  VerficationManager.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 13.07.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VerificationManager : NSObject

- (NSArray<NSString *> *)associatedAppsForFile:(NSURL *)fileURL;
- (NSArray<NSString *> *)associatedAppsForFileExtension:(NSString *)pathExtension;
- (nullable NSURL *)defaultAppForFileExtension:(NSString *)pathExtension;
- (nullable NSURL *)defaultAppForURLScheme:(NSString *)mimeType;
- (NSArray<NSString *> *)associatedAppsForURLScheme:(NSString *)scheme;
- (BOOL)signedSEBExecutable:(NSString *)executablePath;

@end

NS_ASSUME_NONNULL_END
