//
//  ServerController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 25.01.19.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "ServerController.h"

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
    DDLogDebug(@"ServerController: Did select exam with URL %@", url);
    [self.delegate didSelectExamWithExamId:examId url:url];
}


- (void) examSelected:(NSString * _Nonnull)examId url:(NSString * _Nonnull)url
{
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
            if (openEdXUsername && ![sessionIdentifier isEqualToString:openEdXUsername]) {
                sessionIdentifier = openEdXUsername;
                [_sebServerController startMonitoringWithUserSessionId:openEdXUsername];
            }
        } else if ([cookie.name isEqualToString:@"MoodleSession"]) {
            DDLogDebug(@"Cookie 'MoodleSession': %@", cookie);
            NSString *domain = cookie.domain;
            if ([url.absoluteString containsString:domain]) {
                NSString *moodleSession = cookie.value;
                NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
                urlComponents.path = nil;
                urlComponents.query = nil;
                [_sebServerController getMoodleUserIdWithMoodleSession:moodleSession url:urlComponents.URL endpoint:@"/theme/boost_ethz/sebuser.php"];
            }
        }
    }
}

- (void) didReceiveMoodleUserId:(NSString *)moodleUserId
{
    if (moodleUserId.length > 0  && ![sessionIdentifier isEqualToString:moodleUserId]) {
        DDLogInfo(@"ServerController: Did receive Moodle user ID");
       sessionIdentifier = moodleUserId;
        [_sebServerController startMonitoringWithUserSessionId:moodleUserId];
    }
}


- (void) examineHeaders:(NSDictionary<NSString *,NSString *>*)headerFields forURL:(NSURL *)url
{
    NSString *userID = [headerFields objectForKey:@"X-LMS-USER-ID"];
    DDLogVerbose(@"Examine Headers: %@", headerFields);
    if (userID.length > 0 && ![sessionIdentifier isEqualToString:userID]) {
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
    [_delegate startBatteryMonitoringWithDelegate:delegate];
}


- (NSInteger) sendLockscreenWithMessage:(NSString *)message
{
    return  [_sebServerController sendLockscreenWithMessage:message];
}


- (NSInteger) sendRaiseHandNotificationWithMessage:(NSString *)message
{
    return [_sebServerController sendRaiseHandWithMessage:message];
}

- (void) sendLowerHandNotificationWithUID:(NSInteger)notificationUID
{
    [_sebServerController sendLowerHandWithNotificationUID:notificationUID];
}


- (void) executeSEBInstruction:(SEBInstruction *)sebInstruction
{
    if (sebInstruction) {
        NSString *instruction = sebInstruction.instruction;
        
        if ([instruction isEqualToString:@"SEB_QUIT"]) {
            [self.delegate serverSessionQuitRestart:NO];
        }
        
        if ([instruction isEqualToString:@"SEB_PROCTORING"]) {
            if ([self.delegate respondsToSelector:@selector(startProctoringWithAttributes:)]) {
                NSDictionary *attributes = sebInstruction.attributes;
                [self.delegate startProctoringWithAttributes:(NSDictionary *)attributes];
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
