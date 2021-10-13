//
//  ZMSDKMutipleDelegate.m
//  ZoomSDKSample
//
//  Created by derain on 2018/11/22.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKDelegateMgr.h"

@interface ZMSDKDelegateMgr()
{
    ZoomSDKAuthService* _authService;
}
@end

@implementation ZMSDKDelegateMgr

static ZMSDKDelegateMgr* delegateMgr = nil;
- (id)init
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delegateMgr = [super init];
        if(delegateMgr)
        {
            _authService = [[ZoomSDK sharedSDK] getAuthService];
            _authService.delegate = self;
            _authDelegateArray = [[NSMutableArray alloc] init];
        }
    });
    return delegateMgr;
}
-(void)cleanUp
{
    if(_authDelegateArray)
    {
        [_authDelegateArray removeAllObjects];
        _authDelegateArray = nil;
    }
    _authService = [[ZoomSDK sharedSDK] getAuthService];
    _authService.delegate = nil;
}
- (void)dealloc
{
    [self cleanUp];
}

- (void)addAuthDelegateListener:(id<ZoomSDKAuthDelegate>)authDelegate
{
    [_authDelegateArray addObject:authDelegate];
}
- (void)removeAuthDelegateListener:(id<ZoomSDKAuthDelegate>)authDelegate
{
    [_authDelegateArray removeObject:authDelegate];
}

/**********ZoomSDKAuthDelegate***********/
-(void)onZoomSDKLoginResult:(ZoomSDKLoginStatus)loginStatus failReason:(ZoomSDKLoginFailReason)reason
{
    if(!_authDelegateArray)
        return;
    for (id target in _authDelegateArray)
    {
        if ([target respondsToSelector:@selector(onZoomSDKLoginResult:failReason:)])
        {
            [target onZoomSDKLoginResult:loginStatus failReason:reason];
        }
    }
}
- (void)onZoomSDKLogout
{
    if(!_authDelegateArray)
        return;
    for (id target in _authDelegateArray)
    {
        if ([target respondsToSelector:@selector(onZoomSDKLogout)])
        {
            [target onZoomSDKLogout];
        }
    }
}

- (void)onZoomIdentityExpired
{
    if(!_authDelegateArray)
        return;
    for (id target in _authDelegateArray)
    {
        if ([target respondsToSelector:@selector(onZoomIdentityExpired)])
        {
            [target onZoomIdentityExpired];
        }
    }
}

- (void)onZoomSDKAuthReturn:(ZoomSDKAuthError)returnValue
{
    if(!_authDelegateArray)
        return;
    for (id target in _authDelegateArray)
    {
        if ([target respondsToSelector:@selector(onZoomSDKAuthReturn:)])
        {
            [target onZoomSDKAuthReturn:returnValue];
        }
    }
}

@end
