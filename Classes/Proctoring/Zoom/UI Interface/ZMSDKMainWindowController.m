//
//  ZMSDKMainWindowController.m
//  ZoomSDKSample
//
//  Created by derain on 2018/11/16.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKMainWindowController.h"
#import "ZMSDKLoginWindowController.h"
#import "NSColor+Category.h"
#import "ZMSDKCommonHelper.h"
#import "ZMSDKJoinMeetingWindowController.h"
#import "ZMSDKSSOMeetingInterface.h"
#import "ZMSDKApiMeetingInterface.h"
#import "ZMSDKMeetingStatusMgr.h"
#import "ZMSDKEmailMeetingInterface.h"

@implementation ZMSDKAPIUserInfo: NSObject
- (id)initWithUserID:(NSString*)userID zak:(NSString*)zak
{
    self = [super init];
    if(self)
    {
        self.userID = userID;
        self.zak = zak;
        return self;
    }
    return nil;
}
- (void)cleanUp
{
    _userID = nil;
    _zak = nil;
}
-(void)dealloc
{
    [self cleanUp];
}

@end


@implementation ZMSDKMainWindowController
- (id)init
{
    self = [super initWithWindowNibName:@"ZMSDKMainWindowController" owner:self];
    if(self)
    {
        _emailMeetingInterface = [[ZMSDKEmailMeetingInterface alloc] init];
        _ssoMeetingInterface = [[ZMSDKSSOMeetingInterface alloc] init];
        _apiMeetingInterface = [[ZMSDKApiMeetingInterface alloc] initWithWindowController:self];
        _joinMeetingWindowController = [[ZMSDKJoinMeetingWindowController alloc] initWithMgr:self];
        _settingWindowController = [[ZMSDKSettingWindowController alloc] init];
        _meetingStatusMgr = [[ZMSDKMeetingStatusMgr alloc] init];
        return self;
    }
    return nil;
}
- (void)cleanUp
{
    if(_settingWindowController)
    {
        _settingWindowController = nil;
    }
    if(_emailMeetingInterface)
    {
        _emailMeetingInterface = nil;
    }
    if(_ssoMeetingInterface)
    {
        _ssoMeetingInterface = nil;
    }
    if(_apiMeetingInterface)
    {
        _apiMeetingInterface = nil;
    }
    if(_apiUserInfo)
    {
        _apiUserInfo = nil;
    }
    if(_meetingStatusMgr)
    {
        _meetingStatusMgr = nil;
    }
    if(_joinMeetingWindowController)
    {
        _joinMeetingWindowController = nil;
    }
    [_startVideoMeetingButton  setAction:nil];
    [_startVideoMeetingButton  setTarget:nil];
    [_startAudioMeetingButton  setAction:nil];
    [_startAudioMeetingButton  setTarget:nil];
    [_joinMeetingButton  setAction:nil];
    [_joinMeetingButton  setTarget:nil];
    [_scheduleMeetingButton  setAction:nil];
    [_scheduleMeetingButton  setTarget:nil];
    [_settingButton  setAction:nil];
    [_settingButton  setTarget:nil];
    [self close];
}
-(void)dealloc
{
    [self cleanUp];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.window setLevel:NSPopUpMenuWindowLevel];
    [self updateUI];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
}
- (void)updateUI
{
    if([ZMSDKCommonHelper sharedInstance].hasLogin)
    {
        [_startVideoMeetingButton setEnabled:YES];
        [_startAudioMeetingButton setEnabled:YES];
        [_joinMeetingButton setEnabled:YES];
        [_settingButton setEnabled:YES];
        if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_WithoutLogin)
            [_scheduleMeetingButton setEnabled:NO];
        else
            [_scheduleMeetingButton setEnabled:YES];
    }
    else
    {
        [_startVideoMeetingButton setEnabled:NO];
        [_startAudioMeetingButton setEnabled:NO];
        [_joinMeetingButton setEnabled:YES];
        [_settingButton setEnabled:YES];
        [_scheduleMeetingButton setEnabled:NO];
    }
}
- (void)awakeFromNib
{
    [self.window setBackgroundColor:[NSColor colorWithDeviceRed:249.0f/255 green:249.0f/255 blue:249.0f/255 alpha:1.0f]];
    
    [_startVideoMeetingButton setBordered:NO];
    [_startAudioMeetingButton setBordered:NO];
    [_joinMeetingButton setBordered:NO];
    [_scheduleMeetingButton setBordered:NO];
    [_settingButton setBordered:NO];
    
    [self setColor4ZMSDKPTImageButton:_startVideoMeetingButton colorType:ZMSDKPTImageButton_orange];
    [self changeHangoutButtonToStart];
    
    [_startAudioMeetingButton setNormalImage:[NSImage imageNamed:@"btn_startshare_normal"]];
    [_startAudioMeetingButton setHighlightImage:[NSImage imageNamed:@"btn_startshare_normal"]];
    [_startAudioMeetingButton setDisabledImage:[NSImage imageNamed:@"btn_startshare_normal"]];
    [_startAudioMeetingButton setTitle:@"Audio Meeting"];
    [self setColor4ZMSDKPTImageButton:_startAudioMeetingButton colorType:ZMSDKPTImageButton_orange];
    
    [_joinMeetingButton setNormalImage:[NSImage imageNamed:@"btn_joinmeeting_normal"]];
    [_joinMeetingButton setHighlightImage:[NSImage imageNamed:@"btn_joinmeeting_normal"]];
    [_joinMeetingButton setDisabledImage:[NSImage imageNamed:@"btn_joinmeeting_normal"]];
    [_joinMeetingButton setTitle:@"Join"];
    [self setColor4ZMSDKPTImageButton:_joinMeetingButton colorType:ZMSDKPTImageButton_blue];
    
    [_scheduleMeetingButton setNormalImage:[NSImage imageNamed:@"btn_schedule_normal"]];
    [_scheduleMeetingButton setHighlightImage:[NSImage imageNamed:@"btn_schedule_normal"]];
    [_scheduleMeetingButton setDisabledImage:[NSImage imageNamed:@"btn_schedule_normal"]];
    [_scheduleMeetingButton setTitle:@"Schedule"];
    [self setColor4ZMSDKPTImageButton:_scheduleMeetingButton colorType:ZMSDKPTImageButton_blue];
    
    
    [_settingButton setNormalImage:[NSImage imageNamed:@"btn_setting_normal"]];
    [_settingButton setHighlightImage:[NSImage imageNamed:@"btn_setting_normal"]];
    [_settingButton setDisabledImage:[NSImage imageNamed:@"btn_setting_normal"]];
    [_settingButton setTitle:@"Settings"];
     [self setColor4ZMSDKPTImageButton:_settingButton colorType:ZMSDKPTImageButton_blue];
    
    [self changeHangoutButtonToStart];
    //[self updateHangoutButtonByStatus:[[[ZPLoader sharedInstance] confStatus] conferenceStatus] ];
    //[self updateScheduleButton];
    
}
- (void)setColor4ZMSDKPTImageButton:(ZMSDKPTImageButton*)button colorType:(int)color
{
    switch (color) {
        case ZMSDKPTImageButton_orange://orange
            button.normalStartColor = [NSColor colorWithRGBString:@"FCA83E"];
            button.normalEndColor = [NSColor colorWithRGBString:@"FF8F00"];
            button.hoverStartColor = [NSColor colorWithRGBString:@"FCA83E"];
            button.hoverEndColor = [NSColor colorWithRGBString:@"FCA83E"];
            button.pressedStartColor = [NSColor colorWithRGBString:@"F38A03"];
            button.pressedEndColor = [NSColor colorWithRGBString:@"F38A03"];
            button.disabledStartColor = [NSColor colorWithRGBString:@"E3E3ED"];
            button.disabledEndColor = [NSColor colorWithRGBString:@"D9D9E3"];
            button.angle = 0.0;
            break;
        case ZMSDKPTImageButton_blue://blue
            button.normalStartColor = [NSColor colorWithRGBString:@"2DB9FF"];
            button.normalEndColor = [NSColor colorWithRGBString:@"2DA5FF"];
            button.hoverStartColor = [NSColor colorWithRGBString:@"2DB9FF"];
            button.hoverEndColor = [NSColor colorWithRGBString:@"2DB9FF"];
            button.pressedStartColor = [NSColor colorWithRGBString:@"26A0ED"];
            button.pressedEndColor = [NSColor colorWithRGBString:@"26A0ED"];
            button.disabledStartColor = [NSColor colorWithRGBString:@"E3E3ED"];
            button.disabledEndColor = [NSColor colorWithRGBString:@"D9D9E3"];
            button.angle = 0.0;
            break;
        case ZMSDKPTImageButton_red://red
            button.normalStartColor = [NSColor colorWithRGBString:@"EB5A5A"];
            button.normalEndColor = [NSColor colorWithRGBString:@"F56464"];
            button.hoverStartColor = [NSColor colorWithRGBString:@"F56464"];
            button.hoverEndColor = [NSColor colorWithRGBString:@"F56464"];
            button.pressedStartColor = [NSColor colorWithRGBString:@"EB5A5A"];
            button.pressedEndColor = [NSColor colorWithRGBString:@"EB5A5A"];
            button.disabledStartColor = [NSColor colorWithRGBString:@"E3E3ED"];
            button.disabledEndColor = [NSColor colorWithRGBString:@"D9D9E3"];
            button.angle = 0.0;
            break;
            
        default:
            break;
    }
}

- (void)updateScheduleButton
{
    if ([ZMSDKCommonHelper sharedInstance].hasLogin && [ZMSDKCommonHelper sharedInstance].loginType != ZMSDKLoginType_WithoutLogin) {
        [_scheduleMeetingButton setEnabled:YES];
    } else {
        [_scheduleMeetingButton setEnabled:NO];
    }
}

- (void)changeHangoutButtonToStart
{
    [_startVideoMeetingButton setTitle:@"Video Meeting"];
    [_startVideoMeetingButton setNormalImage:[NSImage imageNamed:@"btn_startvideo_normal"]];
    [_startVideoMeetingButton setHighlightImage:[NSImage imageNamed:@"btn_startvideo_normal"]];
    [_startVideoMeetingButton setDisabledImage:[NSImage imageNamed:@"btn_startvideo_normal"]];
}

- (IBAction)onStartVideoMeetingButtonClicked:(id)sender
{
    if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_Email && [ZMSDKCommonHelper sharedInstance].hasLogin)
    {
        [_emailMeetingInterface startVideoMeetingForEmailUser];
    }
    if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_SSO && [ZMSDKCommonHelper sharedInstance].hasLogin)
    {
        [_ssoMeetingInterface startVideoMeetingForSSOUser];
    }
    if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_WithoutLogin && [ZMSDKCommonHelper sharedInstance].hasLogin)
    {
        [_apiMeetingInterface startVideoMeetingForApiUser];
    }
}
- (IBAction)onStartAudioMeetingButtonClicked:(id)sender
{
    if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_Email && [ZMSDKCommonHelper sharedInstance].hasLogin)
    {
        [_emailMeetingInterface startAudioMeetingForEmailUser];
    }
    if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_SSO && [ZMSDKCommonHelper sharedInstance].hasLogin)
    {
        [_ssoMeetingInterface startAudioMeetingForSSOUser];
    }
    if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_WithoutLogin && [ZMSDKCommonHelper sharedInstance].hasLogin)
    {
        [_apiMeetingInterface startAudioMeetingForApiUser];
    }
}

- (IBAction)onJoinMeetingButtonClicked:(id)sender
{
    [_joinMeetingWindowController showSelf];
}

- (IBAction)onSettingButtonClicked:(id)sender
{
    if([[ZMSDKCommonHelper sharedInstance] isUseCutomizeUI])
    {
        [_settingWindowController.window makeKeyAndOrderFront:nil];
        [_settingWindowController showWindow:nil];
    }
    else
    {
        ZoomSDKSettingService* setting = [[ZoomSDK sharedSDK] getSettingService];
        [[setting getGeneralSetting] hideSettingComponent:SettingComponent_AdvancedFeatureButton hide:YES];
        [[setting getGeneralSetting] hideSettingComponent:SettingComponent_AdvancedFeatureTab hide:YES];

        ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
        ZoomSDKMeetingUIController* controller = [meetingService getMeetingUIController];
        [controller showMeetingComponent:MeetingComponent_Setting window:nil show:YES InPanel:YES frame:NSZeroRect];
        [[setting getGeneralSetting] setCustomFeedbackURL:@"www.zoom.us"];
    }
}
- (void)updateMainWindowUIWithMeetingStatus:(ZoomSDKMeetingStatus)status
{
    if(!status)
        return;
    switch (status) {
        case ZoomSDKMeetingStatus_Connecting:
        {
            [_startVideoMeetingButton setEnabled:NO];
            [_startAudioMeetingButton setEnabled:NO];
            [_joinMeetingButton setEnabled:NO];
            if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_WithoutLogin || ![ZMSDKCommonHelper sharedInstance].hasLogin)
                [_scheduleMeetingButton setEnabled:NO];
            else
                [_scheduleMeetingButton setEnabled:YES];
        }
            break;
        case ZoomSDKMeetingStatus_InMeeting:
        {
            [_startVideoMeetingButton setEnabled:NO];
            [_startAudioMeetingButton setEnabled:NO];
            [_joinMeetingButton setEnabled:NO];
            if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_WithoutLogin || ![ZMSDKCommonHelper sharedInstance].hasLogin)
                [_scheduleMeetingButton setEnabled:NO];
            else
                [_scheduleMeetingButton setEnabled:YES];
        }
            break;
        case ZoomSDKMeetingStatus_Webinar_Promote:
        case ZoomSDKMeetingStatus_Webinar_Depromote:
        case ZoomSDKMeetingStatus_AudioReady:
            break;
        case ZoomSDKMeetingStatus_Failed:
        case ZoomSDKMeetingStatus_Ended:
        {
            if([ZMSDKCommonHelper sharedInstance].hasLogin)
            {
                [_startVideoMeetingButton setEnabled:YES];
                [_startAudioMeetingButton setEnabled:YES];
                if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_WithoutLogin)
                    [_scheduleMeetingButton setEnabled:NO];
                else
                    [_scheduleMeetingButton setEnabled:YES];
                [_joinMeetingButton setEnabled:YES];
            }
            else
            {
                [_startVideoMeetingButton setEnabled:NO];
                [_startAudioMeetingButton setEnabled:NO];
                [_scheduleMeetingButton setEnabled:NO];
                [_joinMeetingButton setEnabled:YES];
            }
            [self changeHangoutButtonToStart];
        }
        default:
            break;
    }
}

- (void)initApiUserInfoWithID:(NSString*)userID zak:(NSString*)zak
{
    _apiUserInfo = [[ZMSDKAPIUserInfo alloc] initWithUserID:userID zak:zak];
}
@end
