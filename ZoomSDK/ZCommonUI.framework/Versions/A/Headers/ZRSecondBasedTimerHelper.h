//
//  ZRSecondBasedTimerHelper.h
//  RoomPTUI
//
//  Created by Justin Fang on 4/4/17.
//  Copyright © 2017 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZRCommonTimerSinkProtocol.h"

@interface ZRSecondBasedTimerHelper : NSObject {
    dispatch_source_t               _dispatch_timer;
    NSMutableSet*                   _timerSinkItems;
    unsigned int                    _timeTick;
}

@property(nonatomic, readwrite, retain)NSMutableSet*          timerSinkItems;

+ (void)initZRSecondBasedTimerHelper;
+ (void)unInitZRSecondBasedTimerHelper;
+ (ZRSecondBasedTimerHelper*)shareInstance;

- (void)addSinkItem:(id<ZRCommonTimerSinkProtocol>)sink;
- (void)removeSinkItem:(id<ZRCommonTimerSinkProtocol>)sink;
- (void)cleanup;

@end
