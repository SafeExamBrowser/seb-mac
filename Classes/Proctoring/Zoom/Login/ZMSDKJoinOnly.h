//
//  ZMSDKJoinOnly.h
//  ZoomSDKSample
//
//  Created by derain on 2018/11/19.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZoomSDK/ZoomSDK.h>
#import "ZMSDKLoginWindowController.h"

@interface ZMSDKJoinOnly : NSObject
{
    ZMSDKLoginWindowController* _loginWindowController;
}

- (id)initWithWindowController:(ZMSDKLoginWindowController*)loginWindowController;
- (ZoomSDKError)joinMeetingOnly:(NSString*)meetingNumber displayName:(NSString*)userName meetingPSW:(NSString*)pwd;
@end
