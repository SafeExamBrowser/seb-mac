//
//  ZMSDKSSOMeetingInterface.h
//  ZoomSDKSample
//
//  Created by derain on 2018/11/26.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZMSDKMainWindowController.h"

@interface ZMSDKSSOMeetingInterface : NSObject


- (ZoomSDKError)startVideoMeetingForSSOUser;
- (ZoomSDKError)startAudioMeetingForSSOUser;
- (ZoomSDKError)joinMeetingForSSOUser:(NSString*)meetingNumber displayName:(NSString*)name password:(NSString*)psw;
@end
