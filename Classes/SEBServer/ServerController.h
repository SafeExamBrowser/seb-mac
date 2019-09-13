//
//  ServerController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 25.01.19.
//

#import <Foundation/Foundation.h>
#import "SafeExamBrowser-Swift.h"
#import "SEBViewController.h"

@class SEBServerController;
@class SEBViewController;

NS_ASSUME_NONNULL_BEGIN

@interface ServerController : NSObject <ServerControllerDelegate>
{
    @private
    NSString *lmsLoginLastUsername;
    NSString *lmsLoginBaseURL;
}

@property (weak) id delegate;
@property (weak) SEBViewController *sebViewController;

@property (strong) NSDictionary *sebServer;
@property (strong, nonatomic) SEBServerController *sebServerController;

- (BOOL) connectToServer:(NSURL *)url withConfiguration:(NSDictionary *)sebServerConfiguration;
- (void) startExam;
- (void) loginToExam:(NSString * _Nonnull)examId url:(NSString * _Nonnull)url;
- (void) sendLogEventWithLogLevel:(NSUInteger)logLevel
                        timestamp: (NSString *)timestamp
                     numericValue:(double)numericValue
                          message:(NSString *)message;
- (void) quitSession;

- (void) loginToServer;
- (void) queryCredentialsPresetUsername:(NSString *)username;
- (void) loginCanceled;


@end

NS_ASSUME_NONNULL_END
