//
//  ZMSDKRestAPILogin.m
//  ZoomSDKSample
//
//  Created by TOTTI on 2018/11/20.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import "ZMSDKRestAPILogin.h"
#import "ZMSDKLoginWindowController.h"
#import "ZMSDKCommonHelper.h"
#import <CommonCrypto/CommonHMAC.H>

@implementation ZMSDKRestAPILogin
@synthesize loginWindowCtrl = _loginWindowCtrl;

-(id)initWithWindowController:(ZMSDKLoginWindowController*)loginWindowController
{
    if (self = [super init]) {
        _loginWindowCtrl = loginWindowController;
        return self;
    }
    return nil;
}
- (void)cleanUp
{
    
}
-(void)dealloc
{
    [self cleanUp];
}

-(void)loginRestApiWithUserID:(NSString*)userID zak:(NSString*)zak
{
    if(userID.length > 0 && zak.length > 0)
    {
        [ZMSDKCommonHelper sharedInstance].hasLogin = YES;
        [ZMSDKCommonHelper sharedInstance].loginType = ZMSDKLoginType_WithoutLogin;
        [_loginWindowCtrl createMainWindow];
        [_loginWindowCtrl.window close];
        [_loginWindowCtrl.mainWindowController updateUI];
        
        NSMenuItem* appMenuItem =[[[NSApplication sharedApplication] mainMenu] itemWithTag:0];
        NSMenu* appSubMenu = appMenuItem.submenu;
        NSMenuItem* logOutMenuItem =[appSubMenu itemWithTag:12];
        [logOutMenuItem setHidden:NO];
        [_loginWindowCtrl.mainWindowController initApiUserInfoWithID:userID zak:zak];
    }
}
@end
