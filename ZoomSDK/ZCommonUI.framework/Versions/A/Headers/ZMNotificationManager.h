//
//  ZMNotificationManager.h
//  zChatUI
//
//  Created by javenlee on 2019/5/14.
//  Copyright © 2019 Zoom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZMNotificationProtocol.h"
#import <UserNotifications/UserNotifications.h>

typedef NS_ENUM(NSUInteger, ZMUserNotificationActivationType)
{
    ZMUserNotificationActivationTypeNone,
    ZMUserNotificationActivationTypeDismiss,
    ZMUserNotificationActivationTypeContentsClicked,
    ZMUserNotificationActivationTypeOtherButtonClicked,
    ZMUserNotificationActivationTypeActionButtonClicked
};

NS_ASSUME_NONNULL_BEGIN

typedef void(^ZMNotfCallbackBlock)(ZMUserNotification *notification, BOOL *remove);

@interface ZMUserNotification : NSObject

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *subtitle;
@property (nonatomic, retain) NSString *body;
@property (nonatomic, retain) NSImage *contentImage;
@property (nonatomic, retain) NSURL *contentImageURL;
@property (nonatomic, assign) BOOL hasReplyButton;// default NO
@property (nonatomic, assign) BOOL hasActionButton;// default NO
@property (nonatomic, retain) NSString *actionButtonTitle;// if hasActionButton = YES, need set this property
@property (nonatomic, retain) NSString *otherButtonTitle;
@property (nonatomic, retain) NSDictionary *userInfo;
@property (nonatomic, assign) BOOL playSound;// default NO
@property (nonatomic, readonly) NSString *userText;
@property (nonatomic, readonly) ZMUserNotificationActivationType activationType;

@end

@interface ZMNotificationManager : NSObject <NSUserNotificationCenterDelegate, UNUserNotificationCenterDelegate>

+ (ZMNotificationManager *)sharedInstance;

- (void)removeNotificationWithTarget:(id)target;
- (void)removeNotificationWithDelegate:(id)delegate;

- (void)deliverNotification:(ZMUserNotification *)notification;
- (void)deliverNotification:(ZMUserNotification *)notification delegate:(id<ZMNotificationProtocol>)delegate;
- (void)deliverNotification:(ZMUserNotification *)notification callBackTarget:(id)target block:(nullable ZMNotfCallbackBlock)completion;

- (void)getDeliveredNotificationsWithCompletionHandler:(void(^)(NSArray<ZMUserNotification *> *notifications))completionHandler;

- (void)removeDeliveredNotificationWithIdentifier:(NSString *)identifier;
- (void)removeAllDeliveredNotifications;

@end
NS_ASSUME_NONNULL_END

