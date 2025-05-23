//
//  ServerController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 25.01.19.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "ServerController.h"

static NSString __unused *moodleUserIDEndpointETHTheme = @"/theme/boost_ethz/sebuser.php";
static NSString __unused *moodleUserIDEndpointSEBServerPlugin = @"/mod/quiz/accessrule/sebserver/classes/external/user.php";

@implementation ServerController


- (NSError *) connectToServer:(NSURL *)url withConfiguration:(NSDictionary *)sebServerConfiguration
{
    NSError *error = nil;
    NSString *institution =  [sebServerConfiguration valueForKey:@"institution"];
    NSString *exam = [sebServerConfiguration valueForKey:@"exam"];
    NSString *username =  [sebServerConfiguration valueForKey:@"clientName"];
    NSString *password =  [sebServerConfiguration valueForKey:@"clientSecret"];
    NSString *discoveryAPIEndpoint = [sebServerConfiguration valueForKey:@"apiDiscovery"];
    double pingInterval = [[sebServerConfiguration valueForKey:@"pingInterval"] doubleValue];
    if (pingInterval <= 0) {
        pingInterval = SEBServerDefaultPingInterval;
    }
    pingInterval = pingInterval / 1000;
    
    if (url && institution && username && password && discoveryAPIEndpoint)
    {
        _url = url;
        _sebServerController = [[SEBServerController alloc] initWithBaseURL:url
                                                                institution:institution
                                                                       exam:exam
                                                                   username:username
                                                                   password:password
                                                          discoveryEndpoint:discoveryAPIEndpoint
                                                               pingInterval:pingInterval
                                                                   delegate:self];
        _sebServerController.clientUserId = MyGlobals.userName;
        _sebServerController.osName = MyGlobals.osName;
        _sebServerController.sebVersion = MyGlobals.versionString;
        _sebServerController.machineName = MyGlobals.computerName;
        [_sebServerController getServerAPI];
    } else {
        error = [[NSError alloc] initWithDomain:sebErrorDomain
                                           code:SEBErrorConnectionSettingsInvalid
                                       userInfo:@{NSLocalizedDescriptionKey : NSLocalizedString(@"Missing Connection Settings", comment: ""),
                                                  NSLocalizedRecoverySuggestionErrorKey : NSLocalizedString(@"Check your server connection configuration.", comment: ""),
                                                  NSDebugDescriptionErrorKey : @"Cannot connect to SEB Server. Some connection settings are missing."}];
    }
    return error;
}


- (BOOL) fallbackEnabled
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    return [preferences secureBoolForKey:@"org_safeexambrowser_SEB_sebServerFallback"];
}


- (void) closeServerViewWithCompletion:(void (^)(void))completion
{
    [self.delegate closeServerViewWithCompletion:completion];
}


- (void) reconfigureWithServerExamConfig: (NSData *)configData
{
    DDLogInfo(@"ServerController: Reconfigure with server exam config");
    [self.delegate storeNewSEBSettingsFromData:configData];
}


- (void) startExamFromServer
{
    DDLogInfo(@"ServerController: Start exam from server");
    [_sebServerController loginToExam];
}


- (void) loginToExam:(NSString * _Nonnull)url
{
    DDLogInfo(@"ServerController: Login to exam");
    DDLogDebug(@"ServerController: Login to exam with URL %@", url);
    sessionIdentifier = nil;
    [self.delegate loginToExam:url];
}


- (void) loginToExamAbortedWithCompletion:(void (^)(BOOL))completion
{
    DDLogInfo(@"ServerController: Abort SEB Server login to exam");
    [_sebServerController loginToExamAbortedWithCompletion:completion];
}


- (void) didSelectExam:(NSString *)examId url:(NSString *)url
{
    DDLogInfo(@"ServerController: Did select exam");
    DDLogDebug(@"ServerController: Did select exam ID %@ with URL %@", examId, url);
    [self.delegate didSelectExamWithExamId:examId url:url];
}


- (NSString * _Nullable)appSignatureKey {
    return self.delegate.appSignatureKey;
}


- (void)didReceiveExamSalt:(NSString * _Nonnull)examSalt connectionToken:(NSString * _Nonnull)connectionToken {
    DDLogDebug(@"ServerController: Did receive exam salt and connection token");
    [self.delegate didReceiveExamSalt:examSalt connectionToken:connectionToken];
}


- (void)didReceiveServerBEK:(NSString * _Nonnull)serverBEK {
    DDLogDebug(@"ServerController: Did receive Server BEK");
    [self.delegate didReceiveServerBEK:serverBEK];
}


- (void) examSelected:(NSString * _Nonnull)examId url:(NSString * _Nonnull)url
{
    DDLogInfo(@"ServerController: Exam selected");
    DDLogDebug(@"ServerController: Exam selected: ID %@ with URL %@", examId, url);
    [_sebServerController examSelected:examId url:url];
}


- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies forURL:(nonnull NSURL *)url
{
    // Look for a user cookie if logging in to an exam system/LMS supporting SEB Server
    // ToDo: Only search for cookie when logging in to Open edX
    NSHTTPCookie *cookie;
    for (cookie in cookies) {
        if ([cookie.name isEqualToString:@"edx-user-info"]) {
            NSString *cookieValue = [cookie.value stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
            cookieValue = [cookieValue stringByReplacingOccurrencesOfString:@"\\054" withString:@","];
            cookieValue = [cookieValue stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
            NSError *error = nil;
            NSDictionary* cookieKeyValues = [NSJSONSerialization JSONObjectWithData:[cookieValue dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
            NSString *openEdXUsername = [cookieKeyValues valueForKey:@"username"];
            DDLogDebug(@"Cookie edx username: %@", openEdXUsername);
            if (openEdXUsername && ![sessionIdentifier isEqualToString:openEdXUsername]) {
                sessionIdentifier = openEdXUsername;
                [_sebServerController startMonitoringWithUserSessionId:openEdXUsername];
            }
        } else if ([cookie.name hasPrefix:@"MoodleSession"]) {
            DDLogDebug(@"Cookie '%@': %@", cookie.name, cookie);
            NSString *domain = cookie.domain;
            if ([url.absoluteString containsString:domain]) {
                NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
                urlComponents.path = nil;
                urlComponents.query = nil;
                [_sebServerController getMoodleUserIdWithMoodleCookie:cookie url:urlComponents.URL endpoint:moodleUserIDEndpointSEBServerPlugin];
            }
        }
    }
}

- (void) didReceiveMoodleUserId:(NSString *)moodleUserId moodleCookie:(NSHTTPCookie * _Nonnull)moodleCookie url:(NSURL * _Nonnull)url endpoint:(NSString * _Nonnull)endpoint
{
    if (moodleUserId.length > 0 && ![sessionIdentifier isEqualToString:moodleUserId]) {
        if (![moodleUserId isEqualToString:@"0"]) {
            DDLogInfo(@"ServerController: Did receive Moodle user ID");
           sessionIdentifier = moodleUserId;
            [_sebServerController startMonitoringWithUserSessionId:moodleUserId];
        }
    } else if ([endpoint isEqualToString:moodleUserIDEndpointSEBServerPlugin]) {
        [_sebServerController getMoodleUserIdWithMoodleCookie:moodleCookie url:url endpoint:moodleUserIDEndpointETHTheme];
    }
}


- (void) examineHeaders:(NSDictionary<NSString *,NSString *>*)headerFields forURL:(NSURL *)url
{
    NSString *userID = [headerFields objectForKey:@"X-LMS-USER-ID"];
    DDLogVerbose(@"Examine Headers: %@", headerFields);
    if (userID.length > 0 && ![sessionIdentifier isEqualToString:userID]) {
        DDLogInfo(@"ServerController: Did receive 'X-LMS' user ID");
        sessionIdentifier = userID;
        [_sebServerController startMonitoringWithUserSessionId:userID];
    }
}


- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url
{
    if ([url.absoluteString containsString:@"/login/index.php?testsession"]) {
        NSString *query = url.query;
        // Search for the testsession ID query parameter which Moodle sends back
        // after a user logs in to a quiz
        NSRange testsessionRange = [query rangeOfString:@"testsession="];
        if (query && testsessionRange.location != NSNotFound) {
            DDLogInfo(@"ServerController: Found Moodle testsession ID");
            NSString *testsessionID = [query substringFromIndex:testsessionRange.location + testsessionRange.length];
            if (testsessionID.length > 0 && ![sessionIdentifier isEqualToString:testsessionID]) {
                sessionIdentifier = testsessionID;
                [_sebServerController startMonitoringWithUserSessionId:testsessionID];
            }
        }
    }
}


- (void) didEstablishSEBServerConnection {
    DDLogInfo(@"[ServerController: Did establish SEB Server connection]");
    [self.delegate didEstablishSEBServerConnection];
}


- (void) sendLogEventWithLogLevel:(NSUInteger)logLevel
                        timestamp: (NSString *)timestamp
                     numericValue:(double)numericValue
                          message:(NSString *)message
{
    [_sebServerController sendLogEvent:logLevel timestamp:timestamp numericValue:numericValue message:message];
}


- (void) startBatteryMonitoringWithDelegate:(id)delegate
{
    DDLogInfo(@"ServerController: Starting battery monitoring");
    [_delegate startBatteryMonitoringWithDelegate:delegate];
}


- (NSInteger) sendLockscreenWithMessage:(NSString *)message
{
    DDLogInfo(@"ServerController: Send lock screen with message: %@", message);
    return  [_sebServerController sendLockscreenWithMessage:message];
}

- (void) confirmLockscreensWithUIDs:(NSArray<NSNumber *> *)notificationUIDs
{
    for (NSNumber *notificationUID in notificationUIDs) {
        DDLogInfo(@"ServerController: Confirm lock screen with UID %@", notificationUID);
        [_sebServerController sendLockscreenConfirmWithNotificationUID:notificationUID.integerValue];
    }
}


- (NSInteger) sendRaiseHandNotificationWithMessage:(NSString *)message
{
    DDLogInfo(@"ServerController: Send raise hand notification with message: %@", message);
    return [_sebServerController sendRaiseHandWithMessage:message];
}

- (void) sendLowerHandNotificationWithUID:(NSInteger)notificationUID
{
    DDLogInfo(@"ServerController: Send lower hand notification");
    [_sebServerController sendLowerHandWithNotificationUID:notificationUID];
}


- (void) executeSEBInstruction:(SEBInstruction *)sebInstruction
{
    if (sebInstruction) {
        NSString *instruction = sebInstruction.instruction;
        DDLogInfo(@"ServerController: Received SEB instruction %@ to execute", instruction	);
        
        if ([instruction isEqualToString:@"SEB_QUIT"]) {
            [self.delegate serverSessionQuitRestart:NO];
        }
        
        if ([instruction isEqualToString:@"SEB_PROCTORING"]) {
            if ([self.delegate respondsToSelector:@selector(proctoringInstructionWithAttributes:)]) {
                NSDictionary *attributes = sebInstruction.attributes;
                [self.delegate proctoringInstructionWithAttributes:(NSDictionary *)attributes];
            }
        }
        
        if ([instruction isEqualToString:@"SEB_RECONFIGURE_SETTINGS"]) {
            if ([self.delegate respondsToSelector:@selector(reconfigureWithAttributes:)]) {
                NSDictionary *attributes = sebInstruction.attributes;
                [self.delegate reconfigureWithAttributes:(NSDictionary *)attributes];
            }
        }
        
        if ([instruction isEqualToString:@"SEB_FORCE_LOCK_SCREEN"]) {
            if ([self.delegate respondsToSelector:@selector(lockSEBWithAttributes:)]) {
                NSDictionary *attributes = sebInstruction.attributes;
                [self.delegate lockSEBWithAttributes:(NSDictionary *)attributes];
            }
        }

        if ([instruction isEqualToString:@"NOTIFICATION_CONFIRM"]) {
            if ([self.delegate respondsToSelector:@selector(confirmNotificationWithAttributes:)]) {
                NSDictionary *attributes = sebInstruction.attributes;
                [self.delegate confirmNotificationWithAttributes:(NSDictionary *)attributes];
            }
        }
    }
}


- (void) quitSessionWithRestart:(BOOL)restart completion:(void (^)(BOOL))completion
{
    DDLogInfo(@"ServerController: Quit SEB Server session");
    [_sebServerController quitSessionWithRestart:restart completion:completion];
}


- (void) cancelQuitSessionWithRestart:(BOOL)restart completion:(void (^)(BOOL))completion
{
    DDLogInfo(@"ServerController: Aborting Quit SEB Server session (force disconnect)");
    [_sebServerController cancelQuitSessionWithRestart:restart completion:completion];
}


- (void) didCloseSEBServerConnectionRestart:(BOOL)restart
{
    DDLogInfo(@"ServerController: Did close SEB Server connection");
    [self.delegate didCloseSEBServerConnectionRestart:restart];
}


- (void) didFailWithError:(NSError *)error fatal:(BOOL)fatal
{
    DDLogInfo(@"ServerController: SEB Server connection did fail");
    [self.delegate didFailWithError:error fatal:fatal];
}


@end
