//
//  zoomController.m
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 13.10.21.
//

#import "SEBZoomController.h"
#import "ZMSDKMainWindowController.h"
#import "ZMSDKDelegateMgr.h"
#import "ZMSDKCommonHelper.h"

@implementation SEBZoomController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[ZMSDKCommonHelper sharedInstance].delegateMgr addAuthDelegateListener:self];
    }
    return self;
}


- (void) openZoomWithSender:(id)sender
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *zoomServerURLString = [preferences secureStringForKey:@"org_safeexambrowser_SEB_zoomServerURL"];
    NSURL *zoomServerURL = [NSURL URLWithString:zoomServerURLString];
    NSString *zoomUserName = [preferences secureStringForKey:@"org_safeexambrowser_SEB_zoomUserName"];
    NSString *zoomRoom = [preferences secureStringForKey:@"org_safeexambrowser_SEB_zoomRoom"];
    NSString *zoomSubject = [preferences secureStringForKey:@"org_safeexambrowser_SEB_zoomSubject"];
    NSString *zoomToken = [preferences secureStringForKey:@"org_safeexambrowser_SEB_zoomToken"];
    NSString *zoomSDKToken = [preferences secureStringForKey:@"org_safeexambrowser_SEB_zoomSDKToken"];
    NSString *zoomAPIKey = [preferences secureStringForKey:@"org_safeexambrowser_SEB_zoomAPIKey"];
    NSString *zoomMeetingKey = [preferences secureStringForKey:@"org_safeexambrowser_SEB_zoomMeetingKey"];
    [self openZoomWithServerURL:zoomServerURL
                                      userName:zoomUserName
                                          room:zoomRoom
                                       subject:zoomSubject
                                         token:zoomToken
                                      sdkToken:zoomSDKToken
                                        apiKey:zoomAPIKey
                                    meetingKey:zoomMeetingKey];
}


- (void) openZoomWithServerURL:(NSURL *)serverURL
                      userName:(NSString *)userName
                          room:(NSString *)room
                       subject:(NSString *)subject
                         token:(NSString *)token
                      sdkToken:(NSString *)sdkToken
                        apiKey:(NSString *)apiKey
                    meetingKey:(NSString *)meetingKey
{
    self.serverURL = serverURL;
    self.userName = userName;
    self.room = room;
    self.subject = subject;
    self.token = token;
    self.sdkToken = sdkToken;
    self.apiKey = apiKey;
    self.meetingKey = meetingKey;
    [self openZoomWithReceiveAudioOverride:NO receiveVideoOverride:NO useChatOverride:NO];
}


- (void) openZoomWithReceiveAudioOverride:(BOOL)receiveAudioFlag
                     receiveVideoOverride:(BOOL)receiveVideoFlag
                          useChatOverride:(BOOL)useChatFlag
{
    if (self.zoomActive) {
        [self closeZoomMeeting:self];
    }
    self.zoomActive = YES;
    
    [self newAuth:self.sdkToken];
}


- (void) toggleZoomViewVisibilityWithSender:(id)sender

{
    
}


- (void) updateProctoringViewButtonState
{
    
}


- (void) closeZoomMeeting:(id)sender
{
    
}


-(void)cleanUp
{
    [[ZMSDKCommonHelper sharedInstance].delegateMgr removeAuthDelegateListener:self];
}

- (void)dealloc
{
    [self cleanUp];
}


-(ZoomSDKError)newAuth:(NSString *)jwtToken
{
    if (!jwtToken || jwtToken.length == 0) {
        return ZoomSDKError_InvalidPrameter;
    }
    ZoomSDKAuthContext *content = [[ZoomSDKAuthContext alloc] init];
    content.jwtToken = jwtToken;
    return [[[ZoomSDK sharedSDK] getAuthService] sdkAuth:content];
}

-(BOOL)isAuthed
{
    return [_auth isAuthorized];
}

-(void)onZoomSDKAuthReturn:(ZoomSDKAuthError)returnValue
{
    if( ZoomSDKAuthError_Success == returnValue)
    {
        
        //error code handle
        NSString* error = @"";
        switch (returnValue) {
            case ZoomSDKAuthError_KeyOrSecretWrong:
                error = @"Key Or Secret is wrong!";
                break;
            case ZoomSDKAuthError_AccountNotSupport:
                error = @"Your account doesn't support!";
                break;
            case ZoomSDKAuthError_AccountNotEnableSDK:
                error = @"Your account doesn't enable SDK!";
                break;
            case ZoomSDKAuthError_Unknown:
                error = @"Unknow error!";
                break;
            default:
                break;
        }

    }
}

-(void)onZoomAuthIdentityExpired
{
    
}

@end
