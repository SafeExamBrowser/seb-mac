//
//  ZMTimerMgr.h
//  ZMMenuDemo
//
//  Created by francis zhuo on 2018/7/30.
//  Copyright © 2018 zoom. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^ZMTimerHandler)(NSUInteger repeatCount, BOOL *stop);

typedef NSString* ZMTimerName;
@interface ZMTimer : NSObject
- (id)initWithInterval:(CGFloat)interval;
- (void)cleanUp;
- (BOOL)addTimer:(id)target forTimerName:(ZMTimerName)name interval:(CGFloat)interval repeatNumber:(NSUInteger)repeatNumber handler:(ZMTimerHandler)handler;
- (void)removeAllTimers;
- (void)removeTimerWithTarget:(id)target;
- (void)removeTimerWithName:(ZMTimerName)name;
- (void)removeTimer:(id)target forTimerName:(ZMTimerName)name;
- (BOOL)isExistTimer:(id)target forTimerName:(ZMTimerName)name;
@end
NS_ASSUME_NONNULL_END
