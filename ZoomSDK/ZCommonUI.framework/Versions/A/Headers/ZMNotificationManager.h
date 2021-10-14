//
//  ZMNotificationManager.h
//  zChatUI
//
//  Created by javenlee on 2019/5/14.
//  Copyright © 2019 Zoom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZMNotificationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ZMNotfCallbackBlock)(NSUserNotification *notification, BOOL *remove);

@interface ZMNotificationManager : NSObject <NSUserNotificationCenterDelegate>

+ (ZMNotificationManager *)sharedInstance;

- (void)removeNotificationWithTarget:(id)target;
- (void)removeNotificationWithDelegate:(id)delegate;

- (void)deliverNotification:(NSUserNotification *)notification delegate:(id<ZMNotificationProtocol>)delegate;
- (void)deliverNotification:(NSUserNotification *)notification callBackTarget:(id)target block:(nullable ZMNotfCallbackBlock)completion;

- (void)deliverNotification:(NSUserNotification *)notification;
- (void)removeDeliveredNotification:(NSUserNotification *)notification;
- (BOOL)removeDeliveredNotificationWithIdentifier:(NSString *)identifier;

- (void)scheduleNotification:(NSUserNotification *)notification;
- (void)removeScheduledNotification:(NSUserNotification *)notification;

- (NSArray<NSUserNotification *>*)deliveredNotifications;
- (void)removeAllDeliveredNotifications;

@end
NS_ASSUME_NONNULL_END

