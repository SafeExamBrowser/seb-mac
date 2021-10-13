//
//  ZMSDKEmailLogin.h
//  ZoomSDKSample
//
//  Created by derain on 2018/11/16.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ZoomSDK/ZoomSDK.h>
#import "ZMSDKLoginWindowController.h"

#define kZMSDKEmailLoginKey  @"login email"
#define kZMSDKPSWLoginKey @"login psw"

@interface ZMSDKEmailLogin : NSObject <ZoomSDKAuthDelegate>
{
    ZMSDKLoginWindowController* _loginWindowController;
}

- (id)initWithWindowController:(ZMSDKLoginWindowController*)loginWindowController;
- (ZoomSDKError)loginWithEmail:(NSString*)email Password:(NSString*)password RememberMe:(BOOL)rememberMe;
- (ZoomSDKError)logOutWithEmail;

//callback
- (void)onZoomSDKAuthReturn:(ZoomSDKAuthError)returnValue;
- (void)onZoomSDKLoginResult:(ZoomSDKLoginStatus)loginStatus failReason:(ZoomSDKLoginFailReason)reason;
- (void)onZoomSDKLogout;
- (void)onZoomIdentityExpired;

@end
