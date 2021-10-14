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

@class ZMUserNotification;

@protocol ZMNotificationProtocol <NSObject>

@optional
/*
 return - need remove notification BOOL
 click notification, response notification action
 */
- (BOOL)zmDidActiveNotification:(ZMUserNotification *)notification;

/*
 return - need remove notification BOOL
 when user click close button on notification
 */
- (BOOL)zmNotificationCenter:(NSUserNotificationCenter *)center didDismissAlert:(NSUserNotification *)alert;

@end


#endif
