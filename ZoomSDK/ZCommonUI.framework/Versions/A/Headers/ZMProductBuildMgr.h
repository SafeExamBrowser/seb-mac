//
//  ZMProductBuildMgr.h
//  ZCommonUI
//
//  Created by Justin Fang on 3/11/14.
//  Copyright (c) 2014 zoom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "zoom_client_conf.h"


@interface ZMProductBuildMgr : NSObject

+ (BOOL)isBuildForZoomBox;
+ (BOOL)isBuildForCNSpecial;
+ (BOOL)isBuildForRingCentral;
+ (BOOL)isBuildForATT;
+ (BOOL)isBuildForBBM;
+ (BOOL)isBuildForBroadView;
+ (BOOL)isBuildForZhumu;
+ (BOOL)isBuildForBizconf;
+ (BOOL)isBuildForHuihui;
+ (BOOL)isBuildForZoomUs;
+ (BOOL)isBuildForSDK;
+ (BOOL)isITPackage;//[Zoom-35382]


@end
