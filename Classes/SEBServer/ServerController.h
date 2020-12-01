//
//  ServerController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 25.01.19.
//

#import <Foundation/Foundation.h>
#import "SafeExamBrowser-Swift.h"

@class SEBServerController;

NS_ASSUME_NONNULL_BEGIN

@protocol ServerControllerDelegate <NSObject>

- (void) didSelectExamWithExamId:(NSString *)examId url:(NSString *)url;
- (void) storeNewSEBSettings:(NSData *)configData;
- (void) loginToExam:(NSString *)url;
- (void) didEstablishSEBServerConnection;
- (void) startProctoringWithAttributes:(NSDictionary *)attributes;
- (void) reconfigureWithAttributes:(NSDictionary *)attributes;
- (void) serverSessionQuitRestart:(BOOL)restart;

@end


@interface ServerController : NSObject <SEBServerControllerDelegate>
{
    @private
    NSString *lmsLoginLastUsername;
    NSString *lmsLoginBaseURL;
}

@property (weak) id<ServerControllerDelegate> delegate;

@property (strong) NSDictionary *sebServer;
@property (strong, nonatomic) SEBServerController *sebServerController;

- (BOOL) connectToServer:(NSURL *)url withConfiguration:(NSDictionary *)sebServerConfiguration;
- (void) startExamFromServer;
- (void) loginToExam:(NSString * _Nonnull)url;
- (void) examSelected:(NSString * _Nonnull)examId url:(NSString * _Nonnull)url;
- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies;
- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url;
- (void) sendLogEventWithLogLevel:(NSUInteger)logLevel
                        timestamp: (NSString *)timestamp
                     numericValue:(double)numericValue
                          message:(NSString *)message;
- (void) quitSession;

- (void) loginToExamAborted;

@end

NS_ASSUME_NONNULL_END
