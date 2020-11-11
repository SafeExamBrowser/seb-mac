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
    NSString *exam = [sebServerConfiguration valueForKey:@"exam"];
    NSString *username =  [sebServerConfiguration valueForKey:@"clientName"];
    NSString *password =  [sebServerConfiguration valueForKey:@"clientSecret"];
    NSString *discoveryAPIEndpoint = [sebServerConfiguration valueForKey:@"apiDiscovery"];
    if (url && institution && username && password && discoveryAPIEndpoint)
    {
        _sebServerController = [[SEBServerController alloc] initWithBaseURL:url
                                                                institution:institution
                                                                       exam:exam
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
    [_sebViewController storeNewSEBSettings:configData];
}


- (void) startExamFromServer
{
    [_sebServerController loginToExam];
}


- (void) loginToExam:(NSString * _Nonnull)url
{
    [_sebViewController loginToExam:url];
}


- (void) loginToExamAborted
{
    [_sebServerController loginToExamAborted];
}


- (void) didSelectExam:(NSString *)examId url:(NSString *)url
{
    [_sebViewController didSelectExamWithExamId:examId url:url];
}


- (void) examSelected:(NSString * _Nonnull)examId url:(NSString * _Nonnull)url
{
    [_sebServerController examSelected:examId url:url];
}


- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies
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
            if (openEdXUsername) {
                [_sebServerController startMonitoringWithUserSessionId:openEdXUsername];
            }
        }
    }
}


- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url
{
    NSString *query = url.query;
    // Search for the testsession ID query parameter which Moodle sends back
    // after a user logs in to a quiz
    NSRange testsessionRange = [query rangeOfString:@"testsession="];
    if (testsessionRange.location != NSNotFound) {
        NSString *testsessionID = [query substringFromIndex:testsessionRange.location + testsessionRange.length];
        if (testsessionID.length > 0) {
            [_sebServerController startMonitoringWithUserSessionId:testsessionID];
        }
    }
}


- (void)didEstablishSEBServerConnection {
    [_sebViewController didEstablishSEBServerConnection];
}


- (void) sendLogEventWithLogLevel:(NSUInteger)logLevel
                        timestamp: (NSString *)timestamp
                     numericValue:(double)numericValue
                          message:(NSString *)message
{
    [_sebServerController sendLogEvent:logLevel timestamp:timestamp numericValue:numericValue message:message];
}


- (void) executeSEBInstruction:(SEBInstruction *)sebInstruction
{
    if (sebInstruction) {
        NSString *instruction = sebInstruction.instruction;
        
        if ([instruction isEqualToString:@"SEB_QUIT"]) {
            [_sebViewController sessionQuitRestart:NO];
        }
        
        if ([instruction isEqualToString:@"SEB_PROCTORING"]) {
            NSDictionary *attributes = sebInstruction.attributes;
            [_sebViewController startProctoringWithAttributes:(NSDictionary *)attributes];
        }
        
        if ([instruction isEqualToString:@"SEB_RECONFIGURE_SETTINGS"]) {
            NSDictionary *attributes = sebInstruction.attributes;
            [_sebViewController reconfigureWithAttributes:(NSDictionary *)attributes];
        }
    }
}


- (void) quitSession
{
    [_sebServerController quitSession];
}


@end
