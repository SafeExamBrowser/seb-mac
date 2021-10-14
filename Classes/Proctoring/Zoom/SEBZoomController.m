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
    if (serverURL && room.length>0 && token.length>0 && sdkToken.length>0) {
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
}


- (void) openZoomWithReceiveAudioOverride:(BOOL)receiveAudioFlag
                     receiveVideoOverride:(BOOL)receiveVideoFlag
                          useChatOverride:(BOOL)useChatFlag
{
    if (self.serverURL) {
        if (self.zoomActive) {
            [self closeZoomMeeting:self];
        }
        self.zoomActive = YES;
        
        BOOL useCustomizedUI = NO;
        ZoomSDKInitParams* params = [[ZoomSDKInitParams alloc] init];
        params.needCustomizedUI = useCustomizedUI;
        params.teamIdentifier = @"6F38DNSC7X";
        params.enableLog = YES;
        ZoomSDKError error = [[ZoomSDK sharedSDK] initSDKWithParams:params];
        DDLogDebug(@"Zoom SDK initSDKWithParams error: %u", error);
        [ZMSDKCommonHelper sharedInstance].isUseCutomizeUI = useCustomizedUI;
        params = nil;

        ZoomSDK* sdk = [ZoomSDK sharedSDK];
        NSString *domain = @"https://zoom.us";
        [sdk setZoomDomain:domain];

        error = [self newAuth:@"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBLZXkiOiJPT2YzSkJBU1BPZFdFWFdkSVZ6ODM3NkJ5TlhiWlAxQnlwVkMiLCJpYXQiOjE2MzQyMzU3MzksImV4cCI6MTYzNDMxNDI1OCwidG9rZW5FeHAiOjE2MzQzMTQyNTh9.phJt8eZRu7Xjul8nBddLJ-783Ew87sMGMzMqjniWfWM"]; //self.sdkToken];
        DDLogDebug(@"Zoom SDK getAuthService error: %u", error);
    }
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
    if (ZoomSDKAuthError_Success == returnValue)
    {
//        BOOL isEmailLoginEnabled = NO;
//        if(([[[ZoomSDK sharedSDK] getAuthService] isEmailLoginEnabled:&isEmailLoginEnabled] == ZoomSDKError_Success) && !isEmailLoginEnabled)
//        {
//            [_loginController removeEmailLoginTab];
//        }
//        if([[NSUserDefaults standardUserDefaults] boolForKey:kZMSDKLoginEmailRemember])
//        {
//            [_loginController switchToLoginTab];
//            [ZMSDKCommonHelper sharedInstance].loginType = ZMSDKLoginType_Email;
//        }
//        else if([[NSUserDefaults standardUserDefaults] boolForKey:kZMSDKLoginSSORemember])
//        {
//            [_loginController switchToLoginTab];
//             [ZMSDKCommonHelper sharedInstance].loginType = ZMSDKLoginType_SSO;
//        }
//        else
//            [_loginController switchToLoginTab];
    } else {
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
