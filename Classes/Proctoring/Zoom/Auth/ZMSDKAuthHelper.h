//
//  ZMSDKAuthHelper.h
//  ZoomSDKSample
//
//  Created by TOTTI on 2018/11/19.
//  Copyright © 2018 zoom.us. All rights reserved.
//
@class ZMSDKLoginWindowController;
#import <Foundation/Foundation.h>
#import <ZoomSDK/ZoomSDK.h>
@interface ZMSDKAuthHelper : NSObject<ZoomSDKAuthDelegate>
@property(nonatomic, weak,readwrite)ZoomSDKAuthService*  auth;
@property(nonatomic, weak,readwrite)ZMSDKLoginWindowController* loginController;

-(id)initWithWindowController:(ZMSDKLoginWindowController*)loginWindowController;
//interface
-(ZoomSDKError)newAuth:(NSString *)jwtToken;
-(BOOL)isAuthed;

//callback
- (void)onZoomSDKAuthReturn:(ZoomSDKAuthError)returnValue;

@end
