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

@end


@interface ZMSDKMeetingStatusMgr : NSObject  <ZoomSDKMeetingServiceDelegate, ZoomSDKMeetingActionControllerDelegate, ZoomSDKWebinarControllerDelegate, ZoomSDKMeetingRecordDelegate>
{
    ZoomSDKMeetingService* _meetingService;
}

@property (strong, nonatomic) id zoomProctoringDelegate;

- (id)initWithProctoringDelegate:(id <ZoomProctoringDelegate>)delegate;

@end
