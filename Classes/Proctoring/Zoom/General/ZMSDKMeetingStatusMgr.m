//
//  ZMSDKMeetingStatusMgr.m
//  ZoomSDKSample
//
//  Created by derain on 2018/11/20.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKMeetingStatusMgr.h"
#import "ZMSDKCommonHelper.h"
#import "ZMSDKLoginWindowController.h"
#import "ZMSDKJoinMeetingWindowController.h"
#import "ZMSDKMeetingMainWindowController.h"
#import "ZMSDKConfUIMgr.h"
#import "ZMSDKMeetingMainWindowController.h"

@interface ZMSDKMeetingStatusMgr()
@end

@implementation ZMSDKMeetingStatusMgr
- (id)initWithWindowController:(ZMSDKMainWindowController*)mainWindowController
{
    self = [super init];
    if(self)
    {
        if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI) {
           [ZMSDKConfUIMgr initConfUIMgr];
        }
        _meetingService = [[ZoomSDK sharedSDK] getMeetingService];
        _meetingService.delegate = self;
        _meetingService.getWebinarController.delegate = self;
        _meetingService.getMeetingActionController.delegate = self;
        _meetingService.getRecordController.delegate = self;
        _mainWindowController = mainWindowController;
        return self;
    }
    return nil;
}

-(void)cleanUp
{
    _meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    _meetingService.delegate = nil;
    _meetingService.getMeetingActionController.delegate = nil;
    _meetingService.getWebinarController.delegate = nil;
    _meetingService.getRecordController.delegate = nil;
   
}
- (void)dealloc
{
    [self cleanUp];
}

/**************ZoomSDKMeetingServiceDelegate***********/
- (void)onMeetingStatusChange:(ZoomSDKMeetingStatus)state meetingError:(ZoomSDKMeetingError)error EndReason:(EndMeetingReason)reason
{
    NSLog(@"MeetingStatus change %d", state);
    switch (state) {
        case ZoomSDKMeetingStatus_Connecting:
        {
            if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
            {
                [[ZMSDKConfUIMgr sharedConfUIMgr] createMeetingMainWindow];
            }
        }
            break;
        case ZoomSDKMeetingStatus_InMeeting:
        {
            if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
            {
                [[[ZMSDKConfUIMgr sharedConfUIMgr] getMeetingMainWindowController] updateInMeetingUI];
            }
            
            if(_mainWindowController)
            {
                if([_mainWindowController.loginWindowController.window isVisible])
                {
                    [_mainWindowController.loginWindowController close];
                }
                if([_mainWindowController.joinMeetingWindowController.window isVisible])
                {
                    [_mainWindowController.joinMeetingWindowController close];
                }
            }
            ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
            if (meetingService)
            {
                ZoomSDKMeetingActionController* meetingActionController = [meetingService getMeetingActionController];
                if(meetingActionController)
                {
                    [meetingActionController setShareSettingType:ShareSettingType_AnyoneCanGrab];
                }
            }
        }
            break;
        case ZoomSDKMeetingStatus_Webinar_Promote:
        case ZoomSDKMeetingStatus_Webinar_Depromote:
        case ZoomSDKMeetingStatus_Join_Breakout_Room:
        case ZoomSDKMeetingStatus_Leave_Breakout_Room:
        {
            [ZMSDKConfUIMgr uninitConfUIMgr];
        }
            break;
        case ZoomSDKMeetingStatus_AudioReady:
            break;
        case ZoomSDKMeetingStatus_Failed:
        {
            if (error == ZoomSDKMeetingError_PasswordError) {
                NSLog(@"Password is Wrong!");
                return;
            }
            else if(error == ZoomSDKMeetingError_RemovedByHost)
            {
                NSLog(@"Has been removed by host!");
            }
            if([ZMSDKCommonHelper sharedInstance].hasLogin)
            {
                [_mainWindowController showWindow:nil];
            }
            else
            {
                [_mainWindowController.loginWindowController showSelf];
            }
            [ZMSDKConfUIMgr uninitConfUIMgr];
        }
            break;
        case ZoomSDKMeetingStatus_Ended:
        {
            if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
            {
                [ZMSDKConfUIMgr uninitConfUIMgr];
            }
            if([ZMSDKCommonHelper sharedInstance].hasLogin)
            {
                [_mainWindowController showWindow:nil];
            }
            else
            {
                [_mainWindowController.loginWindowController showSelf];
            }
            switch (reason) {
                case EndMeetingReason_KickByHost:
                    NSLog(@"leave meeting kicked by host");
                    break;
                    
                case EndMeetingReason_EndByHost:
                    NSLog(@"leave meeting end by host");
                    break;
                default:
                    break;
            }
        }
            break;
        case ZoomSDKMeetingStatus_Disconnecting:
        {
            
        }
            break;
        case ZoomSDKMeetingStatus_Reconnecting:
        {
            if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
            {
                [ZMSDKConfUIMgr uninitConfUIMgr];
                if([ZMSDKCommonHelper sharedInstance].hasLogin)
                {
                    [_mainWindowController showWindow:nil];
                }
                else
                {
                    [_mainWindowController.loginWindowController showSelf];
                }
            }
        }
            break;
        case ZoomSDKMeetingStatus_InWaitingRoom:
        {
            if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
            {
                [[[ZMSDKConfUIMgr sharedConfUIMgr] getMeetingMainWindowController] updateUIInWaitingRoom];
            }
        }
            break;
        default:
        {
            
        }
            break;
    }
    [_mainWindowController updateMainWindowUIWithMeetingStatus:state];
}
- (void)onWaitMeetingSessionKey:(NSData*)key
{
    NSLog(@"Huawei Session key:%@", key);
    NSString* testVideoSessionKey =@"abcdefghijkmnopr";
    ZoomSDKSecuritySessionKey* sessionkey = [[ZoomSDKSecuritySessionKey alloc] init];
    sessionkey.component = SecuritySessionComponet_Video;
    sessionkey.sessionKey = [NSData dataWithBytes:(const char*)testVideoSessionKey.UTF8String length:16];
    sessionkey.iv = nil;
    NSArray* array = [NSArray arrayWithObjects:sessionkey, nil];
}
- (void)onMeetingStatisticWarning:(StatisticWarningType)type
{
    
}

- (void)onFreeMeetingRemainTime:(unsigned int)seconds
{
    
}
#pragma mark -- ZoomSDKWebinarControllerDelegate
- (ZoomSDKError)onWebinarNeedRegisterResponse:(ZoomSDKWebinarRegisterHelper *)webinarRegisterHelper {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
        [[[ZMSDKConfUIMgr sharedConfUIMgr] getMeetingMainWindowController] showWebinarRegisterAlert:webinarRegisterHelper];
    return ZoomSDKError_Success;
}

#pragma mark -- ZoomSDKMeetingActionControllerDelegate
- (void)onUserJoin:(NSArray*)array {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onUserJoin:array];
}
- (void)onUserLeft:(NSArray*)array {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onUserLeft:array];
}
- (void)onUserInfoUpdate:(unsigned int)userID {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onUserInfoUpdate:userID];
}
- (void)onHostChange:(unsigned int)userID {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onHostChange:userID];
}
- (void)onCoHostChange:(unsigned int)userID {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onCoHostChange:userID];
}
- (void)onSpotlightVideoUserChange:(BOOL)spotlight User:(unsigned int)userID {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onSpotlightVideoUserChange:spotlight User:userID];
}
- (void)onVideoStatusChange:(ZoomSDKVideoStatus)videoStatus UserID:(unsigned int)userID {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onVideoStatusChange:videoStatus UserID:userID];
}
- (void)onUserAudioStatusChange:(NSArray*)userAudioStatusArray {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onUserAudioStatusChange:userAudioStatusArray];
}
- (void)onChatMessageNotification:(ZoomSDKChatInfo*)chatInfo {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI) {
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onChatMessageNotification:chatInfo];
        [[[ZMSDKConfUIMgr sharedConfUIMgr] getMeetingMainWindowController]onChatMessageNotification:chatInfo];
    }
}
- (void)onLowOrRaiseHandStatusChange:(BOOL)raise UserID:(unsigned int)userID {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onLowOrRaiseHandStatusChange:raise UserID:userID];
}
- (void)onJoinMeetingResponse:(ZoomSDKJoinMeetingHelper*)joinMeetingHelper {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI) {
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onJoinMeetingResponse:joinMeetingHelper];
        [[[ZMSDKConfUIMgr sharedConfUIMgr] getMeetingMainWindowController] showJoinMeetingAlert:joinMeetingHelper];
    }
}
- (void)onMultiToSingleShareNeedConfirm {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onMultiToSingleShareNeedConfirm];
}


#pragma mark -- ZoomSDKMeetingRecordDelegate
- (void)onRecordStatus:(ZoomSDKRecordingStatus)status {
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
        [[ZMSDKConfUIMgr sharedConfUIMgr].userHelper onRecordStatus:status];
}
@end
