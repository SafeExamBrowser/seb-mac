//
//  ZMSDKMeetingStatusMgr.m
//  ZoomSDKSample
//
//  Created by derain on 2018/11/20.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKMeetingStatusMgr.h"
#import "ZMSDKCommonHelper.h"
#import "ZMSDKMeetingMainWindowController.h"
#import "ZMSDKConfUIMgr.h"

@interface ZMSDKMeetingStatusMgr()
@end

@implementation ZMSDKMeetingStatusMgr

- (id)init
{
    self = [super init];
    if (self)
    {
        if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI) {
           [ZMSDKConfUIMgr initConfUIMgr];
        }
        _meetingService = [[ZoomSDK sharedSDK] getMeetingService];
        _meetingService.delegate = self;
        _meetingService.getWebinarController.delegate = self;
        _meetingService.getMeetingActionController.delegate = self;
        _meetingService.getRecordController.delegate = self;
        return self;
    }
    return nil;
}

- (void)cleanUp
{
    [ZMSDKConfUIMgr uninitConfUIMgr];

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
            [ZMSDKConfUIMgr uninitConfUIMgr];
        }
            break;
        case ZoomSDKMeetingStatus_Ended:
        {
            if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
            {
                [ZMSDKConfUIMgr uninitConfUIMgr];
            }

            switch (reason) {
                case EndMeetingReason_KickByHost:
                    NSLog(@"leave meeting kicked by host");
                    break;
                    
                case EndMeetingReason_EndByHost:
                    NSLog(@"leave meeting end by host");
                    break;

                case EndMeetingReason_NetworkBroken:
                    NSLog(@"Meeting ended because of broken network");
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
            }
        }
            break;
        case ZoomSDKMeetingStatus_InWaitingRoom:
        {
            if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI)
            {
//                [[[ZMSDKConfUIMgr sharedConfUIMgr] getMeetingMainWindowController] updateUIInWaitingRoom];
            }
        }
            break;
        default:
        {
            
        }
            break;
    }
}

- (void)onWaitMeetingSessionKey:(NSData*)key
{
    
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

- (void)onCloudRecordingStatus:(ZoomSDKRecordingStatus)status {

}


- (void)onCustomizedRecordingSourceReceived:(CustomizedRecordingLayoutHelper *)helper {

}


- (void)onRecord2MP4Done:(BOOL)success Path:(NSString *)recordPath {

}


- (void)onRecord2MP4Progressing:(int)percentage {

}


- (void)onRecordPrivilegeChange:(BOOL)canRec {

}


- (void)onActiveSpeakerVideoUserChanged:(unsigned int)userID {

}


- (void)onActiveVideoUserChanged:(unsigned int)userID {

}


- (void)onHostAskStartVideo {

}


- (void)onHostAskUnmute {

}


- (void)onInvalidReclaimHostKey {

}


- (void)onMultiToSingleShareNeedConfirm:(ZoomSDKMultiToSingleShareConfirmHandler *)confirmHandle {

}


- (void)onSpotlightVideoUserChange:(NSArray *)spotlightedUserList {

}


- (void)onUserActiveAudioChange:(NSArray *)useridArray {

}


- (void)onUserNameChanged:(unsigned int)userid userName:(NSString *)userName {

}

@end
