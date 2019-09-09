//
//  ServerController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 25.01.19.
//

#import "ServerController.h"

@implementation ServerController


- (BOOL) connectToServer:(NSURL *)url withConfiguration:(NSDictionary *)sebServerConfiguration
{
    NSString *institution =  [sebServerConfiguration valueForKey:@"institution"];
    NSString *username =  [sebServerConfiguration valueForKey:@"clientName"];
    NSString *password =  [sebServerConfiguration valueForKey:@"clientSecret"];
    NSString *discoveryAPIEndpoint = [sebServerConfiguration valueForKey:@"apiDiscovery"];
    if (url && institution && username && password && discoveryAPIEndpoint)
    {
        _sebServerController = [[SEBServerController alloc] initWithBaseURL:url
                                                                institution:institution
                                                                   username:username
                                                                   password:password
                                                          discoveryEndpoint:discoveryAPIEndpoint
                                                                   delegate:self];
        [_sebServerController getServerAPI];
        return YES;
    }
    return NO;
}


- (void) reconfigureWithServerExamConfig: (NSData *)configData
{
    [_sebServerController loginToExam];
}


- (void) loginToExam:(NSString * _Nonnull)examId url:(NSString * _Nonnull)url {
    [_sebViewController loginToExamWithExamId:examId url:url];
}



- (void) loginToServer
{
//    if ([_sebServer[@"type"] intValue] == lmsTypeMoodle) {
//        lmsLoginBaseURL = _lmsServer[@"baseURL"];
//        NSArray *userAccounts = _lmsServer[@"userAccounts"];
//        NSString *username;
//        NSString *password;
//        lmsLoginLastUsername = nil;
//
//        // Check if settings contain a username and even a password
//        if (userAccounts.count > 0) {
//            NSDictionary *userAccount = userAccounts[0];
//            username = userAccount[@"username"];
//            password = userAccount[@"password"];
//            lmsLoginLastUsername = username;
//
//            // If there was a username and password defined, we try to get a user token directly
//            if (username.length > 0 && password.length > 0) {
//                _lmsController = [[MoodleController alloc] initWithBaseUrl: lmsLoginBaseURL
//                                                                  username: username
//                                                                  password: password
//                                                                  delegate: self];
//                [(MoodleController *)_lmsController getUserToken];
//                return;
//            }
//
//        }
//        [self queryCredentialsPresetUsername:username];
//    }
}


- (void) queryCredentialsPresetUsername:(NSString *)username
{
    // Ask the user to enter LMS login credentials
//    [_delegate showEnterUsernamePasswordDialog:[NSString stringWithFormat:NSLocalizedString(@"Enter your login credentials for %@", nil), _lmsServer[@"title"]]
//                                    title:NSLocalizedString(@"Authentication Required", nil)
//                                 username:username
//                            modalDelegate:self
//                           didEndSelector:@selector(enteredLMSCredentials:password:returnCode:)];
}

- (void)didGetUserToken { 
}



- (void) enteredLMSCredentials:(NSString *)username password:(NSString *)password returnCode:(NSInteger)returnCode
{
//    DDLogDebug(@"Enter username password sheetDidEnd with return code: %ld", (long)returnCode);
//
//    lmsLoginLastUsername = username;
//
//    if (returnCode == SEBEnterPasswordOK) {
//        _lmsController = [[MoodleController alloc] initWithBaseUrl: lmsLoginBaseURL
//                                                          username: username
//                                                          password: password
//                                                          delegate: self];
//        [(MoodleController *)_lmsController getUserToken];
//
//    } else if (returnCode == SEBEnterPasswordCancel) {
//        [_delegate lmsControllerCancledLogin:self];
//    } else {
//        // Ask the user to enter LMS login credentials
//        [_delegate showEnterUsernamePasswordDialog:[NSString stringWithFormat:NSLocalizedString(@"Wrong login credentials entered! Try again.", nil)]
//                                        title:NSLocalizedString(@"Authentication Required", nil)
//                                     username:username
//                                modalDelegate:self
//                               didEndSelector:@selector(enteredLMSCredentials:password:returnCode:)];
//    }
}


- (void) loginCanceled
{
    
}

@end
