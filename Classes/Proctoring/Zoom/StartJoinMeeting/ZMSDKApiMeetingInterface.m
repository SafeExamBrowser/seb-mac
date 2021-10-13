//
//  ZMSDKApiMeetingInterface.m
//  ZoomSDKSample
//
//  Created by derain on 2018/11/29.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKApiMeetingInterface.h"
#import "ZMSDKMainWindowController.h"

@implementation ZMSDKApiMeetingInterface
- (id)initWithWindowController:(ZMSDKMainWindowController*)mainWindowController
{
    self = [super init];
    if(self)
    {
        _mainWindowController = mainWindowController;
        return self;
    }
    return nil;
}

-(void)cleanUp
{
    if(_mainWindowController)
    {
        _mainWindowController = nil;
    }
}
- (void)dealloc
{
    [self cleanUp];
}
- (ZoomSDKError)startVideoMeetingForApiUser;
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    if (meetingService && _mainWindowController.apiUserInfo)
    {
        ZoomSDKStartMeetingUseZakElements *params = [[ZoomSDKStartMeetingUseZakElements alloc] init];
        params.zak = _mainWindowController.apiUserInfo.zak;
        params.userType = ZoomSDKUserType_WithoutLogin;
        params.userId = _mainWindowController.apiUserInfo.userID;
        params.displayName = @"ee";
        params.meetingNumber = 0;
        params.isDirectShare = NO;
        params.displayID = 0;
        params.isNoVideo = NO;
        params.isNoAuido = NO;
        params.vanityID = nil;
        ZoomSDKError ret = [meetingService startMeetingWithZAK:params];
        return ret;
    }
    return ZoomSDKError_Failed;
}
- (ZoomSDKError)startAudioMeetingForApiUser
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    if (meetingService && _mainWindowController.apiUserInfo)
    {
        ZoomSDKStartMeetingUseZakElements *params = [[ZoomSDKStartMeetingUseZakElements alloc] init];
        params.zak = _mainWindowController.apiUserInfo.zak;
        params.userType = ZoomSDKUserType_WithoutLogin;
        params.userId = _mainWindowController.apiUserInfo.userID;
        params.displayName = @"ee";
        params.meetingNumber = 0;
        params.isDirectShare = NO;
        params.displayID = 0;
        params.isNoVideo = YES;
        params.isNoAuido = NO;
        params.vanityID = nil;
        ZoomSDKError ret = [meetingService startMeetingWithZAK:params];
        return ret;
    }
    return ZoomSDKError_Failed;
}
- (ZoomSDKError)joinMeetingForApiUser:(NSString*)meetingNumber displayName:(NSString*)name password:(NSString*)psw
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    if (meetingService && meetingNumber.length > 0)
    {
        ZoomSDKJoinMeetingElements *joinParams = [[ZoomSDKJoinMeetingElements alloc] init];
        joinParams.userType = ZoomSDKUserType_WithoutLogin;
        joinParams.webinarToken = nil;
        joinParams.customerKey = nil;
        joinParams.meetingNumber = meetingNumber.longLongValue;
        joinParams.displayName = name;
        joinParams.password = psw;
        joinParams.isDirectShare = NO;
        joinParams.displayID = 0;
        joinParams.isNoVideo = NO;
        joinParams.isNoAuido = NO;
        joinParams.vanityID = nil;
        ZoomSDKError ret = [meetingService joinMeeting:joinParams];
        return ret;
    }
    return ZoomSDKError_Failed;
}

@end
