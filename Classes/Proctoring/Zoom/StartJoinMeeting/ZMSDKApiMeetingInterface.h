//
//  ZMSDKApiMeetingInterface.h
//  ZoomSDKSample
//
//  Created by derain on 2018/11/29.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZoomSDK/ZoomSDK.h>

@class ZMSDKMainWindowController;

@interface ZMSDKApiMeetingInterface : NSObject
{
    ZMSDKMainWindowController* _mainWindowController;
}
- (id)initWithWindowController:(ZMSDKMainWindowController*)mainWindowController;
- (ZoomSDKError)startVideoMeetingForApiUser;
- (ZoomSDKError)startAudioMeetingForApiUser;
- (ZoomSDKError)joinMeetingForApiUser:(NSString*)meetingNumber displayName:(NSString*)name password:(NSString*)psw;

@end
