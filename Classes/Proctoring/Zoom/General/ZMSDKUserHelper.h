//
//  ZMSDKUserHelper.h
//  ZoomSDKSample
//
//  Created by derain on 2018/12/5.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZoomSDK/ZoomSDK.h>
#import "ZMSDKMeetingMainWindowController.h"
#import "ZoomSDKWindowController.h"

@interface ZMSDKUserHelper : NSObject

{
    ZMSDKMeetingMainWindowController*        _meetingMainWindowController;
    ZoomSDKMeetingService*                   _meetingService;
    ZoomSDKMeetingActionController*          _meetingActionController;
    ZoomSDKMeetingRecordController*          _recordController;
}

- (id)initWithWindowController:(ZMSDKMeetingMainWindowController*)meetingMainWindowController;

//ZoomSDKMeetingActionControllerDelegate
- (void)onUserJoin:(NSArray*)array;
- (void)onUserLeft:(NSArray*)array;
- (void)onUserInfoUpdate:(unsigned int)userID;
- (void)onHostChange:(unsigned int)userID;
- (void)onCoHostChange:(unsigned int)userID;
- (void)onSpotlightVideoUserChange:(BOOL)spotlight User:(unsigned int)userID;
- (void)onVideoStatusChange:(ZoomSDKVideoStatus)videoStatus UserID:(unsigned int)userID;
- (void)onUserAudioStatusChange:(NSArray*)userAudioStatusArray;
- (void)onChatMessageNotification:(ZoomSDKChatInfo*)chatInfo;
- (void)onLowOrRaiseHandStatusChange:(BOOL)raise UserID:(unsigned int)userID;
- (void)onJoinMeetingResponse:(ZoomSDKJoinMeetingHelper*)joinMeetingHelper;
- (void)onMultiToSingleShareNeedConfirm;

//ZoomSDKMeetingRecordDelegate
- (void)onRecordStatus:(ZoomSDKRecordingStatus)status;
@end
