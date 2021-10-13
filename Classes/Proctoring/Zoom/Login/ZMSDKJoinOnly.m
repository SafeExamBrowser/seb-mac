//
//  ZMSDKJoinOnly.m
//  ZoomSDKSample
//
//  Created by derain on 2018/11/19.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKJoinOnly.h"

@implementation ZMSDKJoinOnly

- (id)initWithWindowController:(ZMSDKLoginWindowController*)loginWindowController
{
    self = [super init];
    if(self)
    {
        _loginWindowController = loginWindowController;
        return self;
    }
    return nil;
}

-(void)cleanUp
{
}
- (void)dealloc
{
    [self cleanUp];
}
- (ZoomSDKError)joinMeetingOnly:(NSString*)meetingNumber displayName:(NSString*)userName meetingPSW:(NSString*)pwd
{
    if(meetingNumber.length <= 0)
        return ZoomSDKError_InvalidPrameter;
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    [_loginWindowController createMainWindow];
    [_loginWindowController.mainWindowController.window close];
    
    ZoomSDKJoinMeetingElements *joinParams = [[ZoomSDKJoinMeetingElements alloc] init];
    joinParams.userType = ZoomSDKUserType_WithoutLogin;
    joinParams.webinarToken = nil;
    joinParams.customerKey = nil;
    joinParams.meetingNumber = meetingNumber.longLongValue;
    joinParams.displayName = userName;
    joinParams.password = pwd;
    joinParams.isDirectShare = NO;
    joinParams.displayID = 0;
    joinParams.isNoVideo = NO;
    joinParams.isNoAuido = NO;
    joinParams.vanityID = nil;
    joinParams.zak = nil;

    ZoomSDKError ret = [meetingService joinMeeting:joinParams];
    return ret;
}

@end
