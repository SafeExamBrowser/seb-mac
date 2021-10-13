//
//  ZMSDKInitHelper.h
//  ZoomSDKSample
//
//  Created by TOTTI on 2018/11/19.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZMSDKInitHelper : NSObject
+(void)initSDK:(BOOL)useCustomizedUI;
+(void)setDomain:(NSString*)domain;
@end
