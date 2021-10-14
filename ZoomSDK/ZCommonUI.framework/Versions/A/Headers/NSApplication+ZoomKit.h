//
//  NSApplication+ZoomKit.h
//  ZCommonUI
//
//  Created by Huxley on 2018/4/12.
//  Copyright © 2018 zoom. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN
APPKIT_EXTERN NSString *const NSAccessibilityVoiceOverStatusChanged;//!< Notification
APPKIT_EXTERN NSString *const kZMUserAppearanceKey;
APPKIT_EXTERN NSString *const kZMFontSizeChangedKey;

typedef NS_ENUM(NSInteger, ZMUserAppearance){
    ZMUserAppearanceSystem,
    ZMUserAppearanceLight,
    ZMUserAppearanceDark,
};

@interface NSApplication (ZoomKit)
@property (assign) BOOL canTerminateNow;
@property (getter=isSupportDarkMode,assign) BOOL supportDarkMode;
@property ZMUserAppearance userAppearance;
@property (readonly, getter=isVoiceOverRunning) BOOL voiceOverRunning;//!< for tab control, use 'fullKeyboardAccessEnabled'

@property (nonatomic, assign) BOOL retinaBundleNotReady;
@property (readonly) BOOL isDarkMode;
@property (assign) NSInteger fontSizeRate;
/**
 * check if screen recording in Security&Privacy is turn on
 **/
+ (BOOL)isScreenRecordingOn;

- (BOOL)inTyping;

- (BOOL)checkDarkModeSupport;

@end
NS_ASSUME_NONNULL_END
