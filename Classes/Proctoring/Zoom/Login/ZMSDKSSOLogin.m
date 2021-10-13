//
//  ZMSDKSSOLogin.m
//  ZoomSDKSample
//
//  Created by derain on 2018/11/19.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKSSOLogin.h"
#import "ZMSDKDelegateMgr.h"
#import "ZMSDKCommonHelper.h"

@implementation ZMSDKSSOLogin

- (id)initWithWindowController:(ZMSDKLoginWindowController*)loginWindowController
{
    self = [super init];
    if(self)
    {
        _loginWindowController = loginWindowController;
        [[ZMSDKCommonHelper sharedInstance].delegateMgr addAuthDelegateListener:self];
        return self;
    }
    return nil;
}

-(void)cleanUp
{
    [[ZMSDKCommonHelper sharedInstance].delegateMgr removeAuthDelegateListener:self];
}
- (void)dealloc
{
    [self cleanUp];
}
- (ZoomSDKError)loginSSO:(NSString*)ssoToken  RememberMe:(BOOL)rememberMe
{
    if(ssoToken.length == 0)
        return ZoomSDKError_InvalidPrameter;
    
//    ZoomSDKAuthService* authService = [[ZoomSDK sharedSDK] getAuthService];
//    if (authService)
//    {
//        ZoomSDKError ret = [authService loginSSO:ssoToken RememberMe:rememberMe];
//        [_loginWindowController switchToConnectingTab];
//        return ret;
//    }
    return ZoomSDKError_Failed;
}
- (ZoomSDKError)logOutWithSSO
{
    ZoomSDKAuthService* authService = [[ZoomSDK sharedSDK] getAuthService];
    if (authService)
    {
        ZoomSDKError ret = [authService logout];
        return ret;
    }
    return ZoomSDKError_Failed;
}
/*********ZoomSDKAuthDelegate**********/
-(void)onZoomSDKLoginResult:(ZoomSDKLoginStatus)loginStatus failReason:(ZoomSDKLoginFailReason)reason
{
    NSLog(@"onZoomSDKLoginResult:%d,failReason:%d",loginStatus,reason);
    switch (loginStatus)
    {
        case ZoomSDKLoginStatus_Processing:
        {
            [_loginWindowController switchToConnectingTab];
        }
            break;
        case ZoomSDKLoginStatus_Success:
        {
            [_loginWindowController createMainWindow];
            [ZMSDKCommonHelper sharedInstance].hasLogin = YES;
            [ZMSDKCommonHelper sharedInstance].loginType = ZMSDKLoginType_SSO;
            [_loginWindowController updateUIWithLoginStatus:YES];
            [_loginWindowController.window close];
            [_loginWindowController.mainWindowController updateUI];
            NSMenuItem* appMenuItem =[[[NSApplication sharedApplication] mainMenu] itemWithTag:0];
            NSMenu* appSubMenu = appMenuItem.submenu;
            NSMenuItem* logOutMenuItem =[appSubMenu itemWithTag:12];
            [logOutMenuItem setHidden:NO];
            
        }
            break;
        case ZoomSDKLoginStatus_Failed:
        {
            [ZMSDKCommonHelper sharedInstance].hasLogin = NO;
            [_loginWindowController updateUIWithLoginStatus:NO];
            [_loginWindowController switchToErrorTab];
            if(reason != ZoomSDKLoginFailReason_None)
                [_loginWindowController showErrorMessage:[NSString stringWithFormat:@"login fail reason:%d",reason]];
            NSMenuItem* appMenuItem =[[[NSApplication sharedApplication] mainMenu] itemWithTag:0];
            NSMenu* appSubMenu = appMenuItem.submenu;
            NSMenuItem* logOutMenuItem =[appSubMenu itemWithTag:12];
            [logOutMenuItem setHidden:YES];
            
        }
            break;
        default:
            break;
    }
}

- (void)onZoomSDKLogout
{
    if([ZMSDKCommonHelper sharedInstance].loginType != ZMSDKLoginType_SSO)
        return;
    [_loginWindowController switchToLoginTab];
    [ZMSDKCommonHelper sharedInstance].hasLogin = NO;
    [_loginWindowController.mainWindowController updateUI];
    [_loginWindowController updateUIWithLoginStatus:NO];
    NSMenuItem* appMenuItem =[[[NSApplication sharedApplication] mainMenu] itemWithTag:0];
    NSMenu* appSubMenu = appMenuItem.submenu;
    NSMenuItem* logOutMenuItem =[appSubMenu itemWithTag:12];
    [logOutMenuItem setHidden:YES];
}

- (void)onZoomIdentityExpired
{
    if([ZMSDKCommonHelper sharedInstance].loginType != ZMSDKLoginType_SSO)
        return;
    [_loginWindowController switchToLoginTab];
    [ZMSDKCommonHelper sharedInstance].hasLogin = NO;
    [_loginWindowController.mainWindowController updateUI];
    NSMenuItem* appMenuItem =[[[NSApplication sharedApplication] mainMenu] itemWithTag:0];
    NSMenu* appSubMenu = appMenuItem.submenu;
    NSMenuItem* logOutMenuItem =[appSubMenu itemWithTag:12];
    [logOutMenuItem setHidden:YES];
}

- (void)onZoomSDKAuthReturn:(ZoomSDKAuthError)returnValue
{
    return;
}

@end
