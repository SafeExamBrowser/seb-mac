//
//  ZMSDKCommonHelper.m
//  ZoomSDKSample
//
//  Created by derain on 2018/11/28.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKCommonHelper.h"
#import "ZMSDKDelegateMgr.h"

@implementation ZMSDKCommonHelper

@synthesize  delegateMgr = _delegateMgr;
@synthesize  hasLogin = _hasLogin;
@synthesize  loginType = _loginType;
@synthesize  isUseCutomizeUI = _isUseCutomizeUI;

+ (ZMSDKCommonHelper*)sharedInstance
{
    static ZMSDKCommonHelper* sdkCommonHelper = nil;
    if ( sdkCommonHelper == nil) {
        sdkCommonHelper = [[ZMSDKCommonHelper alloc] init];
    }
    return sdkCommonHelper;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        self.delegateMgr =  [[ZMSDKDelegateMgr alloc] init];
        self.loginType = ZMSDKLoginType_None;
        self.hasLogin = NO;
        self.isUseCutomizeUI = NO;
        return self;
    }
    return nil;
}

- (void)cleanUp
{
    _loginType = ZMSDKLoginType_None;
    _hasLogin = NO;
    _isUseCutomizeUI = NO;
}

- (void)dealloc
{
    [self cleanUp];
}
@end
