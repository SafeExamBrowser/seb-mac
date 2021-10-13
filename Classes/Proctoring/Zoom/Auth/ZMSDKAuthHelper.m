//
//  ZMSDKAuthHelper.m
//  ZoomSDKSample
//
//  Created by TOTTI on 2018/11/19.
//  Copyright © 2018 zoom.us. All rights reserved.
//


#import "ZMSDKAuthHelper.h"
#import "ZMSDKLoginWindowController.h"
#import "ZMSDKDelegateMgr.h"
#import "ZMSDKCommonHelper.h"

@implementation ZMSDKAuthHelper

-(id)initWithWindowController:(ZMSDKLoginWindowController*)loginWindowController
{
    if (self = [super init]) {
        _loginController = loginWindowController;
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


-(ZoomSDKError)newAuth:(NSString *)jwtToken
{
    if (!jwtToken || jwtToken.length == 0) {
        return ZoomSDKError_InvalidPrameter;
    }
    ZoomSDKAuthContext *content = [[ZoomSDKAuthContext alloc] init];
    content.jwtToken = jwtToken;
    return [[[ZoomSDK sharedSDK] getAuthService] sdkAuth:content];
}

-(BOOL)isAuthed
{
    return [_auth isAuthorized];
}

-(void)onZoomSDKAuthReturn:(ZoomSDKAuthError)returnValue
{
    if(ZoomSDKAuthError_Success == returnValue)
    {
        
        BOOL isEmailLoginEnabled = NO;
        if(([[[ZoomSDK sharedSDK] getAuthService] isEmailLoginEnabled:&isEmailLoginEnabled] == ZoomSDKError_Success) && !isEmailLoginEnabled)
        {
            [_loginController removeEmailLoginTab];
        }
        if([[NSUserDefaults standardUserDefaults] boolForKey:kZMSDKLoginEmailRemember])
        {
            [_loginController switchToLoginTab];
            [ZMSDKCommonHelper sharedInstance].loginType = ZMSDKLoginType_Email;
        }
        else if([[NSUserDefaults standardUserDefaults] boolForKey:kZMSDKLoginSSORemember])
        {
            [_loginController switchToLoginTab];
             [ZMSDKCommonHelper sharedInstance].loginType = ZMSDKLoginType_SSO;
        }
        else
            [_loginController switchToLoginTab];
    }else{
        //error code handle
        NSString* error = @"";
        [_loginController switchToErrorTab];
        switch (returnValue) {
            case ZoomSDKAuthError_KeyOrSecretWrong:
                error = @"Key Or Secret is wrong!";
                break;
            case ZoomSDKAuthError_AccountNotSupport:
                error = @"Your account doesn't support!";
                break;
            case ZoomSDKAuthError_AccountNotEnableSDK:
                error = @"Your account doesn't enable SDK!";
                break;
            case ZoomSDKAuthError_Unknown:
                error = @"Unknow error!";
                break;
            default:
                break;
        }
        [_loginController showErrorMessage:error];
    }
}

-(void)onZoomAuthIdentityExpired
{
    
}
@end
