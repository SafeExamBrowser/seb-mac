//
//  ZRCommonTimerSinkProtocol.h
//  RoomPTUI
//
//  Created by Justin Fang on 4/4/17.
//  Copyright © 2017 zoom.us. All rights reserved.
//

#import <Foundation/Foundation.h>


#define kZRStandardSecondTimerInterval   1
#define kZRIMContactPresenceUpdateNotificationCheckInterval         1
#define kZRIMContactPresenceUpdateNotificationTriggerInterval       5
#define kZRIMContactListNotificationCheckInterval  1
#define kZRIMContactListNotificationTriggerInterval  3
#define kZRStandardMinuteTimerInterval   1

@protocol ZRCommonTimerSinkProtocol <NSObject>

- (void)onTimerFired:(NSTimer*)timer;
- (int)checkTimeIntervalInSeconds;

@end

@protocol ZRClockTimerSinkProtocol <NSObject>

- (void)onMinuteClockTimerFired:(NSTimer*)timer;
- (int)checkTimeIntervalInMinutes;

@end
