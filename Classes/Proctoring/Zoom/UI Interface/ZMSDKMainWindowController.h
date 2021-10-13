//
//  ZMSDKMainWindowController.h
//  ZoomSDKSample
//
//  Created by derain on 2018/11/16.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ZMSDKPTImageButton.h"
#import <ZoomSDK/ZoomSDK.h>
#import "ZMSDKSettingWindowController.h"

enum {
    ZMSDKPTImageButton_orange = 0,
    //Orange:
    //Normal    :FCA83E -FF8F00
    //Hover     :FCA83E
    //Press     :F38A03
    //Disable   :E3E3ED- D9D9E3
    //Angle     :0°
    
    ZMSDKPTImageButton_blue,
    //Blue:
    //Normal    :2DB9FF-2DA5FF
    //Hover     :2DB9FF
    //Press     :26A0ED
    //Disable   :E3E3ED- D9D9E3
    //Angle     :0°
    
    ZMSDKPTImageButton_red,
    //Red:
    //Normal    :EB5A5A-F56464
    //Hover     :F56464
    //Press     :EB5A5A
    //Disable   :E3E3ED- D9D9E3
    //Angle     :0°
    
};

@interface ZMSDKAPIUserInfo: NSObject
@property (nonatomic, copy, readwrite) NSString*    userID;
@property (nonatomic, copy, readwrite) NSString*    zak;
@end

@class ZMSDKJoinMeetingWindowController;
@class ZMSDKEmailMeetingInterface;
@class ZMSDKSSOMeetingInterface;
@class ZMSDKApiMeetingInterface;
@class ZMSDKMeetingStatusMgr;
@class ZMSDKLoginWindowController;

@interface ZMSDKMainWindowController : NSWindowController <ZoomSDKDirectShareHelperDelegate>
{
    IBOutlet ZMSDKPTImageButton*         _startVideoMeetingButton;
    IBOutlet ZMSDKPTImageButton*         _startAudioMeetingButton;
    IBOutlet ZMSDKPTImageButton*         _joinMeetingButton;
    IBOutlet ZMSDKPTImageButton*         _scheduleMeetingButton;
    IBOutlet ZMSDKPTImageButton*         _settingButton;
}

@property (nonatomic, strong, readwrite) ZMSDKEmailMeetingInterface*        emailMeetingInterface;
@property (nonatomic, strong, readwrite) ZMSDKSSOMeetingInterface*          ssoMeetingInterface;
@property (nonatomic, strong, readwrite) ZMSDKApiMeetingInterface*          apiMeetingInterface;
@property (nonatomic, strong, readwrite) ZMSDKJoinMeetingWindowController*  joinMeetingWindowController;
@property (nonatomic, strong, readwrite) ZMSDKSettingWindowController*      settingWindowController;
@property (nonatomic, strong, readwrite) ZMSDKAPIUserInfo*                  apiUserInfo;
@property (nonatomic, strong, readwrite) ZMSDKMeetingStatusMgr*             meetingStatusMgr;
@property (nonatomic, weak, readwrite) ZMSDKLoginWindowController*        loginWindowController;

- (IBAction)onStartVideoMeetingButtonClicked:(id)sender;
- (IBAction)onStartAudioMeetingButtonClicked:(id)sender;
- (IBAction)onJoinMeetingButtonClicked:(id)sender;
- (IBAction)onSettingButtonClicked:(id)sender;
- (void)cleanUp;
- (void)updateUI;
- (void)updateMainWindowUIWithMeetingStatus:(ZoomSDKMeetingStatus)status;
- (void)initApiUserInfoWithID:(NSString*)userID zak:(NSString*)zak;
@end
