//
//  ZMSDKJoinMeetingWindowController.m
//  ZoomSDKSample
//
//  Created by derain on 2018/11/28.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKJoinMeetingWindowController.h"
#import <ZoomSDK/ZoomSDK.h>
#import "ZMSDKMainWindowController.h"
#import "ZMSDKCommonHelper.h"
#import "ZMSDKSSOMeetingInterface.h"
#import "ZMSDKApiMeetingInterface.h"
#import "ZMSDKEmailMeetingInterface.h"

@interface ZMSDKJoinMeetingWindowController ()
{
    ZMSDKMainWindowController* _mainWindowController;
}
@end

@implementation ZMSDKJoinMeetingWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void)awakeFromNib
{
    [self initUI];
}
- (id)initWithMgr:(ZMSDKMainWindowController*)mainWindowController
{
    self = [super initWithWindowNibName:@"ZMSDKJoinMeetingWindowController" owner:self];
    if(self)
    {
        _mainWindowController = mainWindowController;
        return self;
    }
    return nil;
}
- (void)cleanUp
{
    [self close];
}
-(void)dealloc
{
    [self cleanUp];
}
- (void)initUI
{
    ZoomSDKAccountInfo* accountInfo = [[[ZoomSDK sharedSDK] getAuthService] getAccountInfo];
    if(accountInfo)
    {
        if([accountInfo getDisplayName].length > 0)
            _displayNameTextField.stringValue = [accountInfo getDisplayName];
    }
}

- (void)showSelf
{
    [self relayoutWindowPosition];
    [self.window makeKeyAndOrderFront:nil];
}
- (void)relayoutWindowPosition
{
    [self.window setLevel:NSPopUpMenuWindowLevel];
    [self.window center];
}

- (IBAction)onJoinButtonClicked:(id)sender
{
    if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_Email)
    {
        [_mainWindowController.emailMeetingInterface joinMeetingForEmailUser:_meetingNumberTextField.stringValue displayName:_displayNameTextField.stringValue password:_meetingPswTextField.stringValue];
    }
    else if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_SSO)
    {
        if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_SSO)
        {
            [_mainWindowController.ssoMeetingInterface joinMeetingForSSOUser:_meetingNumberTextField.stringValue displayName:_displayNameTextField.stringValue password:_meetingPswTextField.stringValue];
        }
        else if([ZMSDKCommonHelper sharedInstance].loginType == ZMSDKLoginType_WithoutLogin)
        {
            [_mainWindowController.apiMeetingInterface joinMeetingForApiUser:_meetingNumberTextField.stringValue displayName:_displayNameTextField.stringValue password:_meetingPswTextField.stringValue];
        }
    }
}
@end
