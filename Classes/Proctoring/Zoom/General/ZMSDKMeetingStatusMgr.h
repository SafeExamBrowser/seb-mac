//
//  ZMSDKMeetingStatusMgr.h
//  ZoomSDKSample
//
//  Created by derain on 2018/11/20.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZoomSDK/ZoomSDK.h>
#import "ZoomSDKWindowController.h"


@protocol ZoomProctoringDelegate <NSObject>

- (void) meetingStatusInMeeting;
- (void) meetingStatusEnded;
- (void) meetingReconnect;

@property (readonly) BOOL zoomReceiveAudio;
@property (readonly) BOOL zoomReceiveAudioOverride;
@property (readonly) BOOL zoomReceiveVideo;
@property (readonly) BOOL zoomReceiveVideoOverride;
@property (readonly) BOOL zoomSendAudio;
@property (readonly) BOOL zoomSendVideo;
@property (readonly) NSUInteger remoteProctoringViewShowPolicy;
@property (readonly) BOOL audioMuted;
@property (readonly) BOOL videoMuted;
@property (readonly) BOOL useChat;
@property (readonly) BOOL closeCaptions;
@property (readonly) BOOL raiseHand;
@property (readonly) BOOL tileView;

@end


@interface ZMSDKMeetingStatusMgr : NSObject  <ZoomSDKMeetingServiceDelegate, ZoomSDKMeetingActionControllerDelegate, ZoomSDKWebinarControllerDelegate, ZoomSDKMeetingRecordDelegate>
{
    ZoomSDKMeetingService* _meetingService;
}

@property (weak, nonatomic) id zoomProctoringDelegate;

- (id)initWithProctoringDelegate:(id <ZoomProctoringDelegate>)delegate;
- (void)toggleZoomViewVisibility;

@end
