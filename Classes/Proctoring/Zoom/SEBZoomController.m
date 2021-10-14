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
    }
    return self;
}


- (ZoomSDKAuthService *) authService
{
    if (!_authService) {
        _authService = [[ZoomSDK sharedSDK] getAuthService];
        _authService.delegate = self;
    }
    return _authService;
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
        
        BOOL useCustomizedUI = YES;
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


- (void) createMainWindow
{
    if (self.mainWindowController)
    {
        [self.mainWindowController showWindow:nil];
        [self.mainWindowController updateUI];
        return;
    }
    self.mainWindowController = [[ZMSDKMainWindowController alloc] init] ;
    [self.mainWindowController.window makeKeyAndOrderFront:nil];
    [self.mainWindowController showWindow:nil];
}


- (void) updateUIWithLoginStatus:(BOOL)hasLogin
{
//    [ZMSDKCommonHelper sharedInstance].hasLogin = hasLogin;
//    BOOL isEmailLoginEnabled = NO;
//    if([[[ZoomSDK sharedSDK] getAuthService] isEmailLoginEnabled:&isEmailLoginEnabled] == ZoomSDKError_Success && isEmailLoginEnabled)
//    {
//        if (_emailRememerMeButton.state == NSOnState && [ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_Email)
//        {
//            [[NSUserDefaults standardUserDefaults] setBool:hasLogin forKey:kZMSDKLoginEmailRemember];
//            [[NSUserDefaults standardUserDefaults] synchronize];
//        }
//    }
}


- (void) logOut
{
//    if ([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_Email)
//    {
//       [_emailLoginHelper logOutWithEmail];
//    }
//    else if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_SSO)
//    {
//        [_ssoLoginHelper logOutWithSSO];
//    }
    if (self.mainWindowController) {
        [self.mainWindowController close];
    }
}

-(void) cleanUp
{
    _authService.delegate = nil;
}

- (void) dealloc
{
    [self cleanUp];
}


-(ZoomSDKError) newAuth:(NSString *)jwtToken
{
    if (!jwtToken || jwtToken.length == 0) {
        return ZoomSDKError_InvalidPrameter;
    }
    ZoomSDKAuthContext *content = [[ZoomSDKAuthContext alloc] init];
    content.jwtToken = jwtToken;
    return [self.authService sdkAuth:content];
}

-(BOOL) isAuthed
{
    return [_authService isAuthorized];
}

-(void) onZoomSDKAuthReturn:(ZoomSDKAuthError)returnValue
{
    if (returnValue == ZoomSDKAuthError_Success) {

        ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
        [self createMainWindow];
        
        ZoomSDKJoinMeetingElements *joinParams = [[ZoomSDKJoinMeetingElements alloc] init];
        joinParams.userType = ZoomSDKUserType_WithoutLogin;
        joinParams.webinarToken = nil;
        joinParams.customerKey = nil;
        joinParams.meetingNumber = self.room.longLongValue;
        joinParams.displayName = self.userName;
        joinParams.password = self.meetingKey;
        joinParams.isDirectShare = NO;
        joinParams.displayID = 0;
        joinParams.isNoVideo = NO;
        joinParams.isNoAuido = NO;
        joinParams.vanityID = nil;
        joinParams.zak = nil;

        ZoomSDKError error = [meetingService joinMeeting:joinParams];
        DDLogDebug(@"[ZoomSDKMeetingService joinMeeting] error: %u", error);

    } else {
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
