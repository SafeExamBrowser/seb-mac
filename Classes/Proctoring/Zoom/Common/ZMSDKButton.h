//
//  ZMSDKButton.h
//  ZoomSDKSample
//
//  Created by derain on 2018/12/4.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ZMSDKPTImageButton.h"

typedef void(^ZMBackgroundDrawer)(NSRect bounds);

enum ZMSDKButtonStyle
{
    Button_Type_Rect,
    Button_Type_RoundRect,
    Button_Type_CircleRect,
    Button_Type_RoundRect_Right,
    Button_Type_RoundRect_Left,
    Button_Type_RoundRect_BottomRight,
    Button_Type_RoundRect_Bottom,
};

@interface ZMSDKButton : ZMSDKTrackingButton
{
    NSImage* _normalImage;
    NSImage* _hoverImage;
    NSImage* _pressImage;
    NSImage* _selectImage;
    NSImage* _disableImage;
    
    ZMBackgroundDrawer _backgroundDrawer;
    ZMBackgroundDrawer _normalBackgroundDrawer;
    ZMBackgroundDrawer _hoverBackgroundDrawer;
    ZMBackgroundDrawer _pressBackgroundDrawer;
    ZMBackgroundDrawer _selectBackgroundDrawer;
    ZMBackgroundDrawer _disableBackgroundDrawer;
    
    NSImage* _backgroundImage;
    NSImage* _normalBackgroundImage;
    NSImage* _hoverBackgroundImage;
    NSImage* _pressBackgroundImage;
    NSImage* _selectBackgroundImage;
    NSImage* _disableBackgroundImage;
    
    NSColor* _backgroundColor;
    NSColor* _normalBackgroundColor;
    NSColor* _hoverBackgroundColor;
    NSColor* _pressBackgroundColor;
    NSColor* _selectBackgroundColor;
    NSColor* _disableBackgroundColor;
    
    NSColor* _titleColor;
    NSColor* _normalTitleColor;
    NSColor* _hoverTitleColor;
    NSColor* _pressTitleColor;
    NSColor* _selectTitleColor;
    NSColor* _disableTitleColor;
    
    NSColor* _borderColor;
    NSColor* _normalBorderColor;
    NSColor* _hoverBorderColor;
    NSColor* _pressBorderColor;
    NSColor* _selectBorderColor;
    NSColor* _disableBorderColor;
    
    float    _topMargin;
    float    _bottomMargin;
    float    _leftMargin;
    float    _rightMargin;
    float    _centerMargin;
    
    //is useful for image and title only
    float    _horizontalAdjust;
    float    _verticalAdjust;
    BOOL     _drawImageOrigalSize;
    
    float   _topBackgroundImageCap;
    float   _bottomBackgroundImageCap;
    float   _leftBackgroundImageCap;
    float   _rightBackgroundImageCap;
    
    int      _buttonStyle;
    int      _textAlignment;
    int      _radius;
    float    _borderWidth;
    NSUnderlineStyle    _textUnderLineStyle;
    NSColor*            _textUnderLineColor;
    
    BOOL     _isSelected;
}
@property(nonatomic, copy) NSImage* normalImage;
@property(nonatomic, copy) NSImage* hoverImage;
@property(nonatomic, copy) NSImage* pressImage;
@property(nonatomic, copy) NSImage* selectImage;
@property(nonatomic, copy) NSImage* disableImage;

@property(copy) ZMBackgroundDrawer backgroundDrawer;
@property(copy) ZMBackgroundDrawer normalBackgroundDrawer;
@property(copy) ZMBackgroundDrawer hoverBackgroundDrawer;
@property(copy) ZMBackgroundDrawer pressBackgroundDrawer;
@property(copy) ZMBackgroundDrawer selectBackgroundDrawer;
@property(copy) ZMBackgroundDrawer disableBackgroundDrawer;

@property(nonatomic, copy) NSImage* backgroundImage;
@property(nonatomic, copy) NSImage* normalBackgroundImage;
@property(nonatomic, copy) NSImage* hoverBackgroundImage;
@property(nonatomic, copy) NSImage* pressBackgroundImage;
@property(nonatomic, copy) NSImage* selectBackgroundImage;
@property(nonatomic, copy) NSImage* disableBackgroundImage;

@property(nonatomic, retain) NSColor* backgroundColor;
@property(nonatomic, retain) NSColor* normalBackgroundColor;
@property(nonatomic, retain) NSColor* hoverBackgroundColor;
@property(nonatomic, retain) NSColor* pressBackgoundColor;
@property(nonatomic, retain) NSColor* selectBackgroundColor;
@property(nonatomic, retain) NSColor* disableBackgroundColor;

@property(nonatomic, retain) NSColor* titleColor;
@property(nonatomic, retain) NSColor* normalTitleColor;
@property(nonatomic, retain) NSColor* hoverTitleColor;
@property(nonatomic, retain) NSColor* pressTitleColor;
@property(nonatomic, retain) NSColor* selectTitleColor;
@property(nonatomic, retain) NSColor* disableTitleColor;

@property(nonatomic, retain) NSColor* borderColor;
@property(nonatomic, retain) NSColor* normalBorderColor;
@property(nonatomic, retain) NSColor* hoverBorderColor;
@property(nonatomic, retain) NSColor* pressBorderColor;
@property(nonatomic, retain) NSColor* selectBorderColor;
@property(nonatomic, retain) NSColor* disableBorderColor;

@property(nonatomic, assign) float    topMargin;
@property(nonatomic, assign) float    bottomMargin;
@property(nonatomic, assign) float    leftMargin;
@property(nonatomic, assign) float    rightMargin;
@property(nonatomic, assign) float    centerMargin;
@property(nonatomic, assign) float    horizontalAdjust;
@property(nonatomic, assign) float    verticalAdjust;
@property(nonatomic, assign) BOOL     drawImageOrigalSize;

@property(nonatomic, assign) float    topBackgroundImageCap;
@property(nonatomic, assign) float    bottomBackgroundImageCap;
@property(nonatomic, assign) float    leftBackgroundImageCap;
@property(nonatomic, assign) float    rightBackgroundImageCap;

@property(nonatomic, assign) int      buttonStyle;
@property(nonatomic, assign) int      textAlignment;
@property(nonatomic, assign) int      radius;
@property(nonatomic, assign) float    borderWidth;
@property(nonatomic, assign) NSUnderlineStyle textUnderLineStyle;
@property(nonatomic, retain) NSColor*   textUnderLineColor;
@property(nonatomic, getter=isSelected, assign) BOOL selected;
- (void)drawBackground;
- (void)drawRectWithImageOnly;
- (void)drawRectWithTitleOnly;
- (void)drawRectWithImageAbove;
- (void)drawRectWithImageLeft;
- (void)drawRectWithImageRight;

- (NSBezierPath*)getBezierPath;
- (NSImage*)getDisplayImage;
- (void)getDisplayImageWidth:(float*)outWidth height:(float*)outHeight;
- (NSColor*)getDisplayTitleColor;
- (NSColor*)getDisplayBgColor;
- (NSInteger)getTitleStringWidth;
- (NSInteger)getFitWidth;

- (CGFloat)widthToFit;
- (CGFloat)widthToFitWithMinWidth:(float)minWidth maxWidth:(float)maxWidth;
- (CGFloat)heightToFit;

@end
