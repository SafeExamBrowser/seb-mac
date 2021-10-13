//
//  ZMSDKEmailMeetingInterface.h
//  ZoomSDKSample
//
//  Created by derain on 2018/11/26.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZMSDKMainWindowController.h"

@interface ZMSDKEmailMeetingInterface : NSObject

- (ZoomSDKError)startVideoMeetingForEmailUser;
- (ZoomSDKError)startAudioMeetingForEmailUser;
- (ZoomSDKError)joinMeetingForEmailUser:(NSString*)meetingNumber displayName:(NSString*)name password:(NSString*)psw;
@end
