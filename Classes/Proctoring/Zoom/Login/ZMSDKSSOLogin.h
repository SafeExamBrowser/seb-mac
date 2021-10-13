//
//  ZMSDKSSOLogin.h
//  ZoomSDKSample
//
//  Created by derain on 2018/11/19.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZoomSDK/ZoomSDK.h>
#import "ZMSDKLoginWindowController.h"

#define kZMSDKSSOToken  @"sso token"

@interface ZMSDKSSOLogin : NSObject <ZoomSDKAuthDelegate>
{
    ZMSDKLoginWindowController* _loginWindowController;
}

- (id)initWithWindowController:(ZMSDKLoginWindowController*)loginWindowController;
- (ZoomSDKError)loginSSO:(NSString*)ssoToken RememberMe:(BOOL)rememberMe;
- (ZoomSDKError)logOutWithSSO;

//callback
- (void)onZoomSDKAuthReturn:(ZoomSDKAuthError)returnValue;
-(void)onZoomSDKLoginResult:(ZoomSDKLoginStatus)loginStatus failReason:(ZoomSDKLoginFailReason)reason;
- (void)onZoomSDKLogout;
- (void)onZoomIdentityExpired;
@end
