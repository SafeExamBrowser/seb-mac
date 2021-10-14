//
//  ZMNotificationProtocol.h
//  SaasBeePTUIModule
//
//  Created by javenlee on 2019/5/16.
//  Copyright © 2019 Zoom. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef ZMNotificationProtocol_h
#define ZMNotificationProtocol_h

@protocol ZMNotificationProtocol <NSObject>

@optional
/*
 return - need remove notification BOOL
 click notification, response notification action
 */
- (BOOL)zmNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification;

/*
 return - need remove notification BOOL
 when user click close button on notification
 */
- (BOOL)zmNotificationCenter:(NSUserNotificationCenter *)center didDismissAlert:(NSUserNotification *)alert;

/*
 return - need remove notification BOOL
 notification did deliver, show in notification center
 */
- (BOOL)zmNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification;

@end


#endif
