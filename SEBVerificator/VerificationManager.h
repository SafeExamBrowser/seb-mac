//
//  VerficationManager.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 13.07.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VerificationManager : NSObject

- (NSArray *)associatedAppsForFile:(NSURL *)fileURL;
- (NSArray *)associatedAppsForFileExtension:(NSString *)pathExtension;
- (NSArray *)associatedAppsForURLScheme:(NSString *)scheme;
- (BOOL)signedSEBExecutable:(NSString *)executablePath;

@end

NS_ASSUME_NONNULL_END
