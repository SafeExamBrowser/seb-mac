//
//  ZRMinuteClockTimerHelper.h
//  ZoomPresence
//
//  Created by Southay on 2019/4/12.
//  Copyright © 2019 zoom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZRCommonTimerSinkProtocol.h"

@interface ZRMinuteClockTimerHelper : NSObject {
    dispatch_source_t               _dispatch_timer;
    NSMutableSet*                   _timerSinkItems;
    unsigned int                    _timeTick;
}

@property(nonatomic, readwrite, retain)NSMutableSet*          timerSinkItems;

+ (void)initZRMinuteClockTimerHelper;
+ (void)unInitZRMinuteClockTimerHelper;
+ (ZRMinuteClockTimerHelper*)shareInstance;

- (void)addSinkItem:(id<ZRClockTimerSinkProtocol>)sink;
- (void)removeSinkItem:(id<ZRClockTimerSinkProtocol>)sink;
- (void)cleanup;

@end
