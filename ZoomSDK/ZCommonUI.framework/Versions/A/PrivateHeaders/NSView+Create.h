//
//  NSView+Create.h
//  zChatUI
//
//  Created by groot.ding on 2018/6/14.
//  Copyright © 2018年 Zipow. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ZMButton.h"
#import "ZMTextField.h"

typedef enum : NSUInteger {
    ZMButtonStyleRoundFillBlue,
    ZMButtonStyleRoundFillRed,
    ZMButtonStyleRoundBorderHoverBlue,
    ZMButtonStyleRoundNoBorer,
} ZMButtonStyle;

@interface NSTextField (Create)


/**
 create TextField

 @return NSTextField instance and need release
 */
+ (instancetype)createTextField;

@end

@interface ZMTextField(Create)

+ (instancetype)createActiveBuleInputTextField;

@end


@interface ZMButton (Create)


/**
 create button by ZMButtonStyle ,this style is from design : < https://www.figma.com/file/QuGWPtIB5YPfh4hzUHr8Occ4/🌎-All-Components?node-id=8%3A4831 >
 
 @param style
 @return ZMButton instance and need release
 */
+ (instancetype)createButtonByStyle:(ZMButtonStyle)style;


/**
 create button by ZMButtonStyleRoundBorderHoverBlue style and
 title is "cancle",
 keyEquivalent is esc,

 @return ZMButton instance
 */
+ (instancetype)createCancelButton;


/**
 create button by ZMButtonStyleRoundFillBlue style and
 keyEquivalent is enter,
 
 @return ZMButton instance
 */
+ (instancetype)createComfirmButton;


/**
 create button by ZMButtonStyleRoundFillBlue style 
 
 @return ZMButton instance
 */
+ (instancetype)createBorderFillBlueButton;

@end
