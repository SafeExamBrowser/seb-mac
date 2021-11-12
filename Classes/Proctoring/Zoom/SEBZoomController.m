//
//  zoomController.m
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 13.10.21.
//

#import "SEBZoomController.h"
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
        if (self.zoomActive && _authService && _authService.isAuthorized) {
            _receiveAudioFlag = receiveAudioFlag;
            _receiveVideoFlag = receiveVideoFlag;
            _useChatFlag = useChatFlag;
            DDLogInfo(@"%s Zoom is active, need to first end previous meeting.", __FUNCTION__);
            [self closeZoomMeeting:^{
                DDLogInfo(@"%s Starting new meeting after previous was ended.", __FUNCTION__);
                [self openZoomWithReceiveAudioOverride:receiveAudioFlag receiveVideoOverride:receiveVideoFlag useChatOverride:useChatFlag];
            }];
            return;
        }
        self.zoomActive = YES;
        
        if (_authService && _authService.isAuthorized) {
            DDLogInfo(@"%s Starting new meeting", __FUNCTION__);
            [self startZoomMeetingReceiveAudioOverride:receiveAudioFlag receiveVideoOverride:receiveVideoFlag useChatOverride:useChatFlag];
        } else {
            BOOL useCustomizedUI = YES;
            ZoomSDKInitParams* params = [[ZoomSDKInitParams alloc] init];
            params.needCustomizedUI = useCustomizedUI;
            params.teamIdentifier = @"6F38DNSC7X";
            params.enableLog = YES;
            ZoomSDKError error = [[ZoomSDK sharedSDK] initSDKWithParams:params];
            DDLogDebug(@"Zoom SDK initSDKWithParams error: %u", error);
            [ZMSDKCommonHelper sharedInstance].isUseCutomizeUI = useCustomizedUI;
            params = nil;

            ZoomSDK *sdk = [ZoomSDK sharedSDK];
            NSString *domain = @"https://zoom.us";
            [sdk setZoomDomain:domain];

#ifdef DEBUG
            error = [self newAuth:self.sdkToken];
#else
            // UZH SDK JWT
            error = [self newAuth:self.sdkToken]; //@"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBLZXkiOiJySWVDT2hGUkJqc3JhRUFOOXQzSTBDYTJGbjRpbkNFbncwdkIiLCJpYXQiOjE2MzQ1Mzg0NDEsImV4cCI6MTYzNjE1Njc5OSwidG9rZW5FeHAiOjE2MzYxNTY3OTl9.NDtZO83CZ7YpQGzc-ivat0Y8-z6trSahptwUT1muGI4"];
#endif
            DDLogDebug(@"Zoom SDK getAuthService error: %u", error);
            if (error != ZoomSDKError_Success) {
#ifndef DEBUG
//                // Fallback in release build for the case the hardcoded token is expired/revoked
//                if (error == ZoomSDKError_Failed) {
//                    // then use the one delivered by SEB Server (which was hopefully fixed in the meantime)
//                    error = [self newAuth:self.sdkToken];
//                    if (error == ZoomSDKError_Success) {
//                        return;
//                    }
//                }
#endif
                [_proctoringUIDelegate setProctoringViewButtonState:remoteProctoringButtonStateDefault];
                [_proctoringUIDelegate proctoringFailedWithErrorMessage:[NSString stringWithFormat:@"%@ %u", NSLocalizedString(@"Starting authentication for the Zoom proctoring meeting failed with error code", nil), error]];
            }
        }
    }
}


- (void) toggleZoomViewVisibilityWithSender:(id)sender

{
    DDLogDebug(@"%s", __FUNCTION__);
    [_meetingStatusMgr toggleZoomViewVisibility];
}


- (void) closeZoomMeeting:(void (^)(void))completionHandler
{
    _meetingEndedCompletionHandler = completionHandler;
    [self stopZoomMeeting];
}


- (void) retryConnectingToMeeting
{
    retryingToConnect = YES;
    [self openZoomWithReceiveAudioOverride:_receiveAudioFlag receiveVideoOverride:_receiveVideoFlag useChatOverride:_useChatFlag];
}


#pragma mark - Initialize and start Zoom meetings

- (void) startZoomMeetingReceiveAudioOverride:(BOOL)receiveAudioOverride
                         receiveVideoOverride:(BOOL)receiveVideoOverride
                              useChatOverride:(BOOL)useChatOverride
{
    self.zoomActive = YES;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    _zoomReceiveAudio = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomReceiveAudio"];
    _zoomReceiveAudioOverride = receiveAudioOverride;
    _zoomReceiveVideo = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomReceiveVideo"];
    _zoomReceiveVideoOverride = receiveVideoOverride;
    _zoomSendAudio = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomSendAudio"];
    _zoomSendVideo = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomSendVideo"];
    _remoteProctoringViewShowPolicy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_remoteProctoringViewShow"];

    _audioMuted = !receiveAudioOverride &&
    _remoteProctoringViewShowPolicy != remoteProctoringViewShowNever &&
    [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomAudioMuted"];
    _videoMuted = !receiveVideoOverride &&
    _remoteProctoringViewShowPolicy != remoteProctoringViewShowNever &&
    [preferences secureBoolForKey:@"org_safeexambrowser_SEB_zoomVideoMuted"];
    _useChat = useChatOverride || [preferences secureBoolForKey:@"zoomFeatureFlagChat"];
    _closeCaptions = [preferences secureBoolForKey:@"zoomFeatureFlagCloseCaptions"];
    _raiseHand = [preferences secureBoolForKey:@"zoomFeatureFlagRaiseHand"];
    _tileView = [preferences secureBoolForKey:@"zoomFeatureFlagTileView"];
    
    if (!_meetingStatusMgr) {
        _meetingStatusMgr = [[ZMSDKMeetingStatusMgr alloc] initWithProctoringDelegate:self];
    }

    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    
    ZoomSDKJoinMeetingElements *joinParams = [[ZoomSDKJoinMeetingElements alloc] init];
    joinParams.userType = ZoomSDKUserType_WithoutLogin;
    joinParams.webinarToken = nil;
    joinParams.customerKey = nil;
    joinParams.meetingNumber = self.room.longLongValue;
    joinParams.displayName = self.userName;
    joinParams.password = self.meetingKey;
    joinParams.isDirectShare = NO;
    joinParams.displayID = 0;
    joinParams.isNoVideo = _videoMuted;
    joinParams.isNoAuido = _audioMuted;
    joinParams.vanityID = nil;
    joinParams.zak = nil;

    ZoomSDKError error = [meetingService joinMeeting:joinParams];
    DDLogDebug(@"[ZoomSDKMeetingService joinMeeting] error: %u", error);
    if (error != ZoomSDKError_Success) {
        [_proctoringUIDelegate setProctoringViewButtonState:remoteProctoringButtonStateDefault];
        [_proctoringUIDelegate proctoringFailedWithErrorMessage:[NSString stringWithFormat:@"%@ %u", NSLocalizedString(@"Joining the Zoom proctoring meeting failed with error code", nil), error]];
    } else {
        if (retryingToConnect) {
            retryingToConnect = NO;
            [_proctoringUIDelegate successfullyRetriedToConnect];
        }
        [_proctoringUIDelegate setProctoringViewButtonState:remoteProctoringButtonStateAIInactive];
    }
}


- (void) stopZoomMeeting
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    if (meetingService) {
        [meetingService leaveMeetingWithCmd:(LeaveMeetingCmd_End)];
    } else {
        [_proctoringUIDelegate setProctoringViewButtonState:remoteProctoringButtonStateDefault];
        _meetingEndedCompletionHandler();
    }
}


- (void) cleanUp
{
    if (_meetingStatusMgr) {
        _meetingStatusMgr = nil;
    }
//    _authService.delegate = nil;
//    _authService = nil;
}


- (void) dealloc
{
    [self cleanUp];
}


- (ZoomSDKError) newAuth:(NSString *)jwtToken
{
    if (!jwtToken || jwtToken.length == 0) {
        return ZoomSDKError_InvalidPrameter;
    }
    ZoomSDKAuthContext *content = [[ZoomSDKAuthContext alloc] init];
    content.jwtToken = jwtToken;
    return [self.authService sdkAuth:content];
}

- (BOOL) isAuthed
{
    return [_authService isAuthorized];
}

- (void) onZoomSDKAuthReturn:(ZoomSDKAuthError)returnValue
{
    if (returnValue == ZoomSDKAuthError_Success) {

        [self startZoomMeetingReceiveAudioOverride:_receiveAudioFlag receiveVideoOverride:_receiveVideoFlag useChatOverride:_useChatFlag];

    } else {
        NSString* error = @"";
        switch (returnValue) {
            case ZoomSDKAuthError_KeyOrSecretWrong:
                error = @"Key Or Secret is wrong!";
                break;
            case ZoomSDKAuthError_AccountNotSupport:
                error = @"Your account doesn't support the SDK!";
                break;
            case ZoomSDKAuthError_AccountNotEnableSDK:
                error = @"Your account doesn't enable the SDK!";
                break;
            case ZoomSDKAuthError_JwtTokenWrong:
                error = @"Used SDK JWT Token is wrong!";
                break;
            case ZoomSDKAuthError_Timeout:
                error = @"Authentication failed with timeout!";
                break;
            case ZoomSDKAuthError_Client_Incompatible:
                error = @"The client is incompatible with the current Zoom infrastructure, use a newer version!";
                break;
            case ZoomSDKAuthError_Unknown:
                error = @"Unknow error!";
                break;
            default:
                break;
        }
        DDLogError(@"Authentication failed: %@", error);
        [_proctoringUIDelegate setProctoringViewButtonState:remoteProctoringButtonStateDefault];
        [_proctoringUIDelegate proctoringFailedWithErrorMessage:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Authentication with the Zoom proctoring meeting failed with error", nil), error]];
    }
}


- (void) onZoomAuthIdentityExpired
{
    DDLogError(@"Zoom authentication identity is expired!");
    [_proctoringUIDelegate setProctoringViewButtonState:remoteProctoringButtonStateDefault];
    [_proctoringUIDelegate proctoringFailedWithErrorMessage:NSLocalizedString(@"Starting Zoom proctoring failed, because authentication identity is expired.", nil)];
}


- (void) meetingStatusInMeeting {
    self.zoomActive = YES;
    DDLogInfo(@"Connected to Zoom meeting");
}


- (void) meetingStatusEnded {
    DDLogInfo(@"Zoom meeting ended.");
    self.zoomActive = NO;
    if (_meetingEndedCompletionHandler) {
        [_proctoringUIDelegate setProctoringViewButtonState:remoteProctoringButtonStateDefault];
        _meetingEndedCompletionHandler();
        _meetingEndedCompletionHandler = nil;
    } else {
        [self meetingReconnect];
    }
}


- (void) meetingReconnect {
    DDLogInfo(@"Zoom meeting was interrupted or ended without SEB Server command to do so, need to reconnect");
    [self startZoomMeetingReceiveAudioOverride:_receiveAudioFlag receiveVideoOverride:_receiveVideoFlag useChatOverride:_useChatFlag];
}


@end
