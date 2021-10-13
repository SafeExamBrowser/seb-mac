//
//  ZMSDKPTImageButton.h
//  ZoomSDKSample
//
//  Created by derain on 2018/11/19.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ZMSDKTrackingButton : NSButton
{
    BOOL    _hovered;
    NSTrackingArea* _trackingArea;
}

@property(nonatomic, assign) BOOL hovered;
@property(nonatomic, strong) NSTrackingArea* trackingArea;
- (NSRect)getRectInScreen;
- (void)cleanUp;
@end


@interface ZMSDKPTImageButton : ZMSDKTrackingButton
{
    float               _angle;
    NSColor*            _normalStartColor;
    NSColor*            _normalEndColor;
    NSColor*            _hoverStartColor;
    NSColor*            _hoverEndColor;
    NSColor*            _pressedStartColor;
    NSColor*            _pressedEndColor;
    NSColor*            _disabledStartColor;
    NSColor*            _disabledEndColor;
    
    NSImage *_normalImage;
    NSImage *_highlightImage;
    NSImage *_disabledImage;
    
    NSMutableDictionary *_attributes;
    NSColor *_fontColor;
}
@property (nonatomic, readwrite, assign)float               angle;
@property (nonatomic, readwrite, strong)NSColor*            normalStartColor;
@property (nonatomic, readwrite, strong)NSColor*            normalEndColor;
@property (nonatomic, readwrite, strong)NSColor*            hoverStartColor;
@property (nonatomic, readwrite, strong)NSColor*            hoverEndColor;
@property (nonatomic, readwrite, strong)NSColor*            pressedStartColor;
@property (nonatomic, readwrite, strong)NSColor*            pressedEndColor;
@property (nonatomic, readwrite, strong)NSColor*            disabledStartColor;
@property (nonatomic, readwrite, strong)NSColor*            disabledEndColor;

@property (nonatomic, strong, readwrite) NSImage *normalImage;
@property (nonatomic, strong, readwrite) NSImage *highlightImage;
@property (nonatomic, strong, readwrite) NSImage *disabledImage;
@property (nonatomic, strong, readwrite) NSMutableDictionary *attributes;
@property (nonatomic, strong, readwrite) NSColor *fontColor;

- (void)cleanUp;
- (int)getTitleWidth;

@end
