//
//  ZMSDKCommonHelper.h
//  ZoomSDKSample
//
//  Created by derain on 2018/11/28.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ZMSDKDelegateMgr;

typedef enum{
    ZMSDKLoginType_None,
    ZMSDKLoginType_Email,
    ZMSDKLoginType_WithoutLogin,
    ZMSDKLoginType_SSO,
} ZMSDKLoginType;


@interface ZMSDKCommonHelper : NSObject
{
    ZMSDKDelegateMgr*      _delegateMgr;
    ZMSDKLoginType         _loginType;
    BOOL                   _hasLogin;
    BOOL                   _isUseCutomizeUI;
}
@property(nonatomic, strong, readwrite)ZMSDKDelegateMgr*   delegateMgr;
@property(nonatomic, assign, readwrite)ZMSDKLoginType      loginType;
@property(nonatomic, assign, readwrite)BOOL                hasLogin;
@property (nonatomic, assign, readwrite)BOOL               isUseCutomizeUI;

+ (ZMSDKCommonHelper*)sharedInstance;
@end
