//
//  ZMSDKButton.m
//  ZoomSDKSample
//
//  Created by derain on 2018/12/4.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKButton.h"
#import <ZoomSDK/ZoomSDK.h>

#define DefaultButtonOffset       0
#define TAG_BADGE 123
static const float DEFAULT_IMAGE_MARGIN = 5.0f;

@implementation ZMSDKButton
@synthesize normalImage = _normalImage;
@synthesize hoverImage = _hoverImage;
@synthesize pressImage = _pressImage;
@synthesize selectImage = _selectImage;
@synthesize disableImage = _disableImage;

@synthesize backgroundDrawer = _backgroundDrawer;
@synthesize normalBackgroundDrawer = _normalBackgroundDrawer;
@synthesize hoverBackgroundDrawer = _hoverBackgroundDrawer;
@synthesize pressBackgroundDrawer = _pressBackgroundDrawer;
@synthesize selectBackgroundDrawer = _selectBackgroundDrawer;
@synthesize disableBackgroundDrawer = _disableBackgroundDrawer;

@synthesize backgroundImage = _backgroundImage;
@synthesize normalBackgroundImage = _normalBackgroundImage;
@synthesize hoverBackgroundImage = _hoverBackgroundImage;
@synthesize pressBackgroundImage = _pressBackgroundImage;
@synthesize selectBackgroundImage = _selectBackgroundImage;
@synthesize disableBackgroundImage = _disableBackgroundImage;

@synthesize backgroundColor = _backgroundColor;
@synthesize normalBackgroundColor = _normalBackgroundColor;
@synthesize hoverBackgroundColor = _hoverBackgroundColor;
@synthesize pressBackgoundColor = _pressBackgroundColor;
@synthesize selectBackgroundColor = _selectBackgroundColor;
@synthesize disableBackgroundColor = _disableBackgroundColor;

@synthesize titleColor = _titleColor;
@synthesize normalTitleColor = _normalTitleColor;
@synthesize hoverTitleColor = _hoverTitleColor;
@synthesize pressTitleColor = _pressTitleColor;
@synthesize selectTitleColor = _selectTitleColor;
@synthesize disableTitleColor = _disableTitleColor;

@synthesize borderColor = _borderColor;
@synthesize normalBorderColor = _normalBorderColor;
@synthesize hoverBorderColor = _hoverBorderColor;
@synthesize pressBorderColor = _pressBorderColor;
@synthesize selectBorderColor = _selectBorderColor;
@synthesize disableBorderColor = _disableBorderColor;

@synthesize topMargin = _topMargin;
@synthesize bottomMargin = _bottomMargin;
@synthesize leftMargin = _leftMargin;
@synthesize rightMargin = _rightMargin;
@synthesize centerMargin = _centerMargin;
@synthesize horizontalAdjust = _horizontalAdjust;
@synthesize verticalAdjust = _verticalAdjust;
@synthesize drawImageOrigalSize = _drawImageOrigalSize;

@synthesize topBackgroundImageCap = _topBackgroundImageCap;
@synthesize bottomBackgroundImageCap = _bottomBackgroundImageCap;
@synthesize leftBackgroundImageCap = _leftBackgroundImageCap;
@synthesize rightBackgroundImageCap = _rightBackgroundImageCap;

@synthesize buttonStyle = _buttonStyle;
@synthesize textAlignment = _textAlignment;
@synthesize radius = _radius;
@synthesize borderWidth = _borderWidth;
@synthesize textUnderLineStyle = _textUnderLineStyle;
@synthesize textUnderLineColor = _textUnderLineColor;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setButtonType:NSMomentaryPushInButton];
        [self setImagePosition:NSNoImage];
        [self setBezelStyle:NSTexturedSquareBezelStyle];
        self.bordered = YES;
        
        [self initProperty];
    }
    return self;
}

- (void)awakeFromNib
{
    [self initProperty];
}

- (void)initProperty{
    self.topMargin = 4;
    self.bottomMargin = 4;
    self.leftMargin = 4;
    self.rightMargin = 4;
    self.centerMargin = 4;
    self.horizontalAdjust = 0;
    self.verticalAdjust = 0;
    
    self.topBackgroundImageCap = 0;
    self.bottomBackgroundImageCap = 0;
    self.leftBackgroundImageCap = 5;
    self.rightBackgroundImageCap = 5;
    
    self.textAlignment = NSCenterTextAlignment;
    self.textUnderLineStyle = NSUnderlineStyleNone;
    self.radius = 4;
    self.borderWidth = 1;
}

- (void)setFrame:(NSRect)frame
{//for tooptip rect error on some 10.11 machine
    [super setFrame:frame];
    if (self.toolTip && ![self isHiddenOrHasHiddenAncestor])
    {
        NSString* tip = self.toolTip;
        self.toolTip = nil;
        self.toolTip = tip;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];//for system will add some notify
    self.hoverImage = nil;
    self.normalImage = nil;
    self.pressImage = nil;
    self.selectImage = nil;
    self.disableImage = nil;
    
    self.backgroundDrawer = nil;
    self.normalBackgroundDrawer = nil;
    self.hoverBackgroundDrawer = nil;
    self.pressBackgroundDrawer = nil;
    self.selectBackgroundDrawer = nil;
    self.disableBackgroundDrawer = nil;
    
    self.backgroundImage = nil;
    self.normalBackgroundImage = nil;
    self.hoverBackgroundImage = nil;
    self.pressBackgroundImage = nil;
    self.selectBackgroundImage = nil;
    self.disableBackgroundImage = nil;
    
    self.backgroundColor = nil;
    self.normalBackgroundColor = nil;
    self.hoverBackgroundColor = nil;
    self.pressBackgoundColor = nil;
    self.selectBackgroundColor = nil;
    self.disableBackgroundColor = nil;
    
    self.titleColor = nil;
    self.normalTitleColor = nil;
    self.hoverTitleColor = nil;
    self.pressTitleColor = nil;
    self.selectTitleColor = nil;
    self.disableTitleColor = nil;
    
    self.borderColor = nil;
    self.normalBorderColor = nil;
    self.hoverBorderColor = nil;
    self.pressBorderColor = nil;
    self.selectBorderColor = nil;
    self.disableBorderColor = nil;
    
    self.textUnderLineColor = nil;
    
    self.target = nil;
    self.action = nil;
}
#pragma mark select
- (BOOL)isSelected{
    return _isSelected;
}
- (void)setSelected:(BOOL)selected{
    _isSelected = selected;
    [self setNeedsDisplay:YES];
}
#pragma mark resize
- (CGFloat)widthToFit
{
    CGFloat newWidth = [self getFitWidth];
    [self setFrameSize:NSMakeSize(newWidth, NSHeight(self.bounds))];
    return newWidth;
}


- (CGFloat)widthToFitWithMinWidth:(float)minWidth maxWidth:(float)maxWidth
{
    if(minWidth < 0 || maxWidth < 0)
        return 0;
    
    if(maxWidth > 1e-5 && maxWidth < minWidth)
        return 0;
    
    CGFloat newWidth = [self getFitWidth];
    if(newWidth < minWidth)
        newWidth = minWidth;
    if(newWidth > maxWidth && maxWidth > 1e-5)
        newWidth = maxWidth;
    
    [self setFrameSize:NSMakeSize(newWidth, NSHeight(self.bounds))];
    return newWidth;
}

- (CGFloat)heightToFit
{
    CGFloat newHeight = [self getFitHeight];
    [self setFrameSize:NSMakeSize(NSWidth(self.bounds), newHeight)];
    return newHeight;
}
- (void)sizeToFit{
    CGFloat newWidth = [self getFitWidth];
    CGFloat newHeight = [self getFitHeight];
    [self setFrameSize:NSMakeSize(newWidth, newHeight)];
}
- (NSSize)intrinsicContentSize
{
    CGFloat newWidth = [self getFitWidth];
    CGFloat newHeight = [self getFitHeight];
    return NSMakeSize(newWidth, newHeight);
}
- (NSInteger)getFitWidth{
    NSUInteger titleWidth = [self getTitleStringWidth];
    NSUInteger imageWidth = [self getMaxDisplayImageWidth];
    
    CGFloat newWidth = NSWidth(self.bounds);
    if(self.imagePosition == NSImageOnly)
        newWidth = imageWidth + _leftMargin + _rightMargin;
    else if(self.imagePosition == NSNoImage)
        newWidth = titleWidth + _leftMargin + _rightMargin;
    else if(self.imagePosition == NSImageAbove)
        newWidth = MAX(titleWidth, imageWidth) + _leftMargin + _rightMargin;
    else if(self.imagePosition == NSImageLeft)
        newWidth = titleWidth + imageWidth + _leftMargin + _centerMargin + _rightMargin;
    else if(self.imagePosition == NSImageRight)
        newWidth = titleWidth + imageWidth + _leftMargin + _centerMargin + _rightMargin;
    return ceil(newWidth);
}
- (NSInteger)getFitHeight{
    NSUInteger titleHeight = [self getTitleStringHeight];
    NSUInteger imageHeight = [self getMaxDisplayImageHeight];
    
    CGFloat newHeight = NSHeight(self.bounds);
    if(self.imagePosition == NSImageOnly)
        newHeight = imageHeight + _topMargin + _bottomMargin;
    else if(self.imagePosition == NSNoImage)
        newHeight = titleHeight + _topMargin + _bottomMargin;
    else if(self.imagePosition == NSImageAbove)
        newHeight = imageHeight + titleHeight + _topMargin + _centerMargin + _bottomMargin;
    else if(self.imagePosition == NSImageLeft)
        newHeight = MAX(titleHeight, imageHeight) + _topMargin  + _bottomMargin;
    else if(self.imagePosition == NSImageRight)
        newHeight = MAX(titleHeight, imageHeight) + _topMargin  + _bottomMargin;
    return ceil(newHeight);
}
- (float)getMaxDisplayImageWidth{
    float maxWidth = 0;
    if(self.image)
        maxWidth = MAX(self.image.size.width, maxWidth);
    if(self.normalImage)
        maxWidth = MAX(self.normalImage.size.width, maxWidth);
    if(self.hoverImage)
        maxWidth = MAX(self.hoverImage.size.width, maxWidth);
    if(self.pressImage)
        maxWidth = MAX(self.pressImage.size.width, maxWidth);
    if(self.selectImage)
        maxWidth = MAX(self.selectImage.size.width, maxWidth);
    if(self.disableImage)
        maxWidth = MAX(self.disableImage.size.width, maxWidth);
    return ceilf(maxWidth);
}
- (float)getMaxDisplayImageHeight{
    float maxHeight = 0;
    if(self.image)
        maxHeight = MAX(self.image.size.height, maxHeight);
    if(self.normalImage)
        maxHeight = MAX(self.normalImage.size.height, maxHeight);
    if(self.hoverImage)
        maxHeight = MAX(self.hoverImage.size.height, maxHeight);
    if(self.pressImage)
        maxHeight = MAX(self.pressImage.size.height, maxHeight);
    if(self.selectImage)
        maxHeight = MAX(self.selectImage.size.height, maxHeight);
    if(self.disableImage)
        maxHeight = MAX(self.disableImage.size.height, maxHeight);
    return ceilf(maxHeight);
}
#pragma mark drawRect
- (void)drawRect:(NSRect)dirtyRect
{
    [self drawBackground];
    
    if(self.imagePosition == NSImageOnly)
        [self drawRectWithImageOnly];
    else if(self.imagePosition == NSNoImage)
        [self drawRectWithTitleOnly];
    else if(self.imagePosition == NSImageAbove)
        [self drawRectWithImageAbove];
    else if(self.imagePosition == NSImageLeft)
        [self drawRectWithImageLeft];
    else if(self.imagePosition == NSImageRight)
        [self drawRectWithImageRight];
    else
        [self drawRectWithTitleOnly];
}

- (void)drawBackground
{
    //draw background drawer
    ZMBackgroundDrawer bgDrawer = [self getDisplayDrawer];
    if(bgDrawer){
        bgDrawer(self.bounds);
        return;
    }
    
    //draw background color
    NSBezierPath* thePath = [self getBezierPath];
    if(thePath){
        NSColor* bgColor = [self getDisplayBgColor];
        if(bgColor){
            [bgColor set];
            [thePath fill];
        }
        
        NSColor* borderColor = [self getDisplayBorderColor];
        if(borderColor)
        {
            [borderColor set];
            [thePath stroke];
        }
        return;
    }
}

- (void)drawRectWithImageOnly
{
    float xPos = 0;
    float yPos = 0;
    float width = 0;
    float height = 0;
    
    //Draw image
    NSImage* image = [self getDisplayImage];
    if(image)
    {
        if (self.drawImageOrigalSize)
        {
            width = image.size.width;
            height = image.size.height;
        }
        else
            [self getDisplayImageWidth:&width height:&height];
        
        xPos = ceilf((NSWidth(self.bounds)-width)/2.0f);
        xPos += self.horizontalAdjust;
        yPos = ceilf((NSHeight(self.bounds)-height)/2.0f);
        yPos += self.verticalAdjust;
        
        [image drawInRect:NSMakeRect(xPos, yPos, width, height)
                 fromRect:NSZeroRect
                operation:NSCompositeSourceOver
                 fraction:1.0f
           respectFlipped:YES
                    hints:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSImageInterpolationNone], NSImageHintInterpolation, nil]];
    }
}

- (void)drawRectWithTitleOnly
{
    float xPos = 0;
    float yPos = 0;
    float width = 0;
    float height = 0;
    
    NSString* title = self.title;
    if(title)
    {
        NSDictionary* titleAttri = [self getDispalyTitleAttribute];
        NSAttributedString* attriString = [[NSAttributedString alloc] initWithString:title attributes:titleAttri];
        
        height = attriString.size.height;
        width = MIN(attriString.size.width+1,NSWidth(self.bounds));
        xPos = ceilf((NSWidth(self.bounds)-width)/2.0f);
        xPos += self.horizontalAdjust;
        yPos = floorf((NSHeight(self.bounds)-height)/2.0f);
        yPos += self.verticalAdjust;
        
        if(self.textAlignment == NSLeftTextAlignment || self.textAlignment == NSRightTextAlignment){
            width = NSWidth(self.bounds)-self.leftMargin-self.rightMargin;
            xPos = self.leftMargin;
        }
        
        [attriString drawInRect:NSMakeRect(xPos, yPos, width, height)];
    }
}

- (void)drawRectWithImageAbove
{
    float xPos = 0;
    float yPos = 0;
    float width = 0;
    float height = 0;
    
    //Draw image
    NSImage* image = [self getDisplayImage];
    if(image)
    {
        width = image.size.width;
        height = image.size.height;
        xPos = ceilf((self.bounds.size.width-width)/2.0f);
        xPos += self.horizontalAdjust;
        yPos = self.topMargin;
        
        [image drawInRect:NSMakeRect(xPos, yPos, width, height)
                 fromRect:NSZeroRect
                operation:NSCompositeSourceOver
                 fraction:1.0f
           respectFlipped:YES
                    hints:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSImageInterpolationNone], NSImageHintInterpolation, nil]];
        yPos += height;
    }
    
    //Draw title
    NSString* title = self.title;
    if(title)
    {
        yPos += image ? self.centerMargin : self.topMargin;
        width = NSWidth(self.bounds);
        xPos = 0;
        
        NSDictionary* attribute = [self getDispalyTitleAttribute];
        NSAttributedString* attriString = [[NSAttributedString alloc] initWithString:title attributes:attribute];
        height = attriString.size.height;
        
        [attriString drawInRect:NSMakeRect(xPos, yPos, width, height)];
    }
}

- (void)drawRectWithImageLeft
{
    float xPos = 0;
    float yPos = 0;
    float width = 0;
    float height = 0;
    
    //Draw image
    NSImage* image = [self getDisplayImage];
    if(image)
    {
        height = image.size.height;
        width = image.size.width;
        yPos = ceilf((self.bounds.size.height-height)/2.0f);
        yPos += self.verticalAdjust;
        xPos = self.leftMargin;
        
        [image drawInRect:NSMakeRect(xPos, yPos, width, height)
                 fromRect:NSZeroRect
                operation:NSCompositeSourceOver
                 fraction:1.0f
           respectFlipped:YES
                    hints:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSImageInterpolationNone], NSImageHintInterpolation, nil]];
        
        xPos += width;
    }
    
    //Draw title
    NSString* title = self.title;
    if(title)
    {
        NSDictionary* attribute = [self getDispalyTitleAttribute];
        
        NSAttributedString* attriString = [[NSAttributedString alloc] initWithString:title attributes:attribute];
        height = attriString.size.height;
        xPos += image ? self.centerMargin : self.leftMargin;
        width = self.bounds.size.width-xPos-self.rightMargin;
        yPos = ceilf((self.bounds.size.height-height)/2.0f);
        if(width>0)
            [attriString drawInRect:NSMakeRect(xPos, yPos, width, height)];
    }
}

- (void)drawRectWithImageRight
{
    float xPos = 0;
    float yPos = 0;
    float width = 0;
    float height = 0;
    
    NSImage* image = [self getDisplayImage];
    //Draw title
    NSString* title = self.title;
    if(title)
    {
        NSDictionary* attribute = [self getDispalyTitleAttribute];
        NSAttributedString* attriString = [[NSAttributedString alloc] initWithString:title attributes:attribute];
        height = attriString.size.height;
        xPos = self.leftMargin;
        width = self.bounds.size.width-xPos-self.centerMargin-image.size.width - self.rightMargin;
        yPos = floorf((self.bounds.size.height-height)/2.0f);
        
        if(width>0)
            [attriString drawInRect:NSMakeRect(xPos, yPos, width, height)];
        
        xPos += width;
    }
    
    //Draw image
    if(image)
    {
        width = image.size.width;
        height = image.size.height;
        
        xPos += title ? self.centerMargin : self.leftMargin;
        yPos = floorf((NSHeight(self.bounds)-height)/2.0f);
        yPos += self.verticalAdjust;
        
        [image drawInRect:NSMakeRect(xPos, yPos, width, height)
                 fromRect:NSZeroRect
                operation:NSCompositeSourceOver
                 fraction:1.0f
           respectFlipped:YES
                    hints:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSImageInterpolationNone], NSImageHintInterpolation, nil]];
    }
}

#pragma mark Get
- (NSBezierPath*)getBezierPath
{
    NSBezierPath* thePath = nil;
    NSRect bounds = self.bounds;
    if ([self getDisplayBorderColor])
    {
        bounds.size.height -= self.borderWidth;
        bounds.size.width -= self.borderWidth;
        bounds.origin.x += self.borderWidth/2.0;
        bounds.origin.y += self.borderWidth/2.0;
    }
    if(self.buttonStyle == Button_Type_Rect)
        thePath = [NSBezierPath bezierPathWithRect:bounds];
    else if(self.buttonStyle == Button_Type_RoundRect)
        thePath = [NSBezierPath bezierPathWithRoundedRect:bounds xRadius:self.radius yRadius:self.radius];
    else if(self.buttonStyle == Button_Type_CircleRect)
    {
        thePath = [NSBezierPath bezierPath];
        float radius = bounds.size.height/2.0;
        [thePath moveToPoint:NSMakePoint(radius + bounds.origin.x, bounds.origin.y)];
        [thePath lineToPoint:NSMakePoint(bounds.size.width - radius + bounds.origin.x, bounds.origin.y)];
        [thePath appendBezierPathWithArcWithCenter:NSMakePoint(bounds.size.width - radius + bounds.origin.x, bounds.size.height/2.0+ bounds.origin.y) radius:radius startAngle:270 endAngle:90];
        [thePath lineToPoint:NSMakePoint(radius + bounds.origin.x, bounds.size.height + bounds.origin.y)];
        [thePath appendBezierPathWithArcWithCenter:NSMakePoint(radius + bounds.origin.x, bounds.size.height/2.0 + bounds.origin.y) radius:radius startAngle:90 endAngle:270];
        [thePath closePath];
    }
    else if(self.buttonStyle == Button_Type_RoundRect_Left)
    {
        thePath = [NSBezierPath bezierPath];
        float radius = self.radius;
        NSPoint thePoint = NSMakePoint(NSWidth(bounds)+bounds.origin.x, NSHeight(bounds)+bounds.origin.y);
        [thePath moveToPoint:thePoint];
        
        thePoint = NSMakePoint(bounds.origin.x+radius, NSHeight(bounds)+bounds.origin.y);
        [thePath lineToPoint:thePoint];
        
        thePoint = NSMakePoint(bounds.origin.x, NSHeight(bounds)+bounds.origin.y);
        NSPoint tmpPoint = NSMakePoint(bounds.origin.x,  NSHeight(bounds)+bounds.origin.y-radius);
        [thePath appendBezierPathWithArcFromPoint:thePoint toPoint:tmpPoint radius:radius];
        
        thePoint = NSMakePoint(bounds.origin.x, bounds.origin.y+radius);
        [thePath lineToPoint:thePoint];
        
        thePoint = NSMakePoint(bounds.origin.x, bounds.origin.y);
        tmpPoint = NSMakePoint(bounds.origin.x+radius, bounds.origin.y);
        [thePath appendBezierPathWithArcFromPoint:thePoint toPoint:tmpPoint radius:radius];
        
        thePoint = NSMakePoint(NSWidth(bounds)+bounds.origin.x, bounds.origin.y);
        [thePath lineToPoint:thePoint];
        
        [thePath closePath];
    }
    else if(self.buttonStyle == Button_Type_RoundRect_Right)
    {
        thePath = [NSBezierPath bezierPath];
        float radius = self.radius;
        NSPoint thePoint = NSMakePoint(bounds.origin.x, bounds.origin.y);
        [thePath moveToPoint:thePoint];
        
        thePoint = NSMakePoint(NSWidth(bounds)+bounds.origin.x-radius, bounds.origin.y);
        [thePath lineToPoint:thePoint];
        
        thePoint = NSMakePoint(NSWidth(bounds)+bounds.origin.x, bounds.origin.y);
        NSPoint tmpPoint = NSMakePoint(NSWidth(bounds)+bounds.origin.x, radius+bounds.origin.y);
        [thePath appendBezierPathWithArcFromPoint:thePoint toPoint:tmpPoint radius:radius];
        
        thePoint = NSMakePoint(NSWidth(bounds)+bounds.origin.x, NSHeight(bounds)+bounds.origin.y-radius);
        [thePath lineToPoint:thePoint];
        
        thePoint = NSMakePoint(NSWidth(bounds)+bounds.origin.x, NSHeight(bounds)+bounds.origin.y);
        tmpPoint = NSMakePoint(NSWidth(bounds)+bounds.origin.x-radius, NSHeight(bounds)+bounds.origin.y);
        [thePath appendBezierPathWithArcFromPoint:thePoint toPoint:tmpPoint radius:radius];
        
        thePoint = NSMakePoint(bounds.origin.x, NSHeight(bounds)+bounds.origin.y);
        [thePath lineToPoint:thePoint];
        
        [thePath closePath];
    }
    else if(self.buttonStyle == Button_Type_RoundRect_BottomRight)
    {
        thePath = [NSBezierPath bezierPath];
        float radius = self.radius;
        NSPoint thePoint = NSMakePoint(bounds.origin.x, NSHeight(bounds)+bounds.origin.y);
        [thePath moveToPoint:thePoint];
        
        thePoint = NSMakePoint(NSWidth(bounds)+bounds.origin.x - radius, NSHeight(bounds)+bounds.origin.y);
        [thePath lineToPoint:thePoint];
        
        thePoint = NSMakePoint(NSWidth(bounds)+bounds.origin.x, NSHeight(bounds)+bounds.origin.y);
        NSPoint tmpPoint = NSMakePoint(NSWidth(bounds)+bounds.origin.x, NSHeight(bounds)+bounds.origin.y - radius);
        [thePath appendBezierPathWithArcFromPoint:thePoint toPoint:tmpPoint radius:radius];
        
        thePoint = NSMakePoint(NSWidth(bounds)+bounds.origin.x, bounds.origin.y);
        [thePath lineToPoint:thePoint];
        
        thePoint = NSMakePoint(bounds.origin.x, bounds.origin.y);
        [thePath lineToPoint:thePoint];
        [thePath closePath];
    }
    else if(self.buttonStyle == Button_Type_RoundRect_Bottom){
        thePath = [self getBezierPath4RoundRect_Bottom:bounds];
    }
    if(thePath)
        [thePath setLineWidth:self.borderWidth];
    
    return thePath;
}
- (NSBezierPath*)getBezierPath4RoundRect_Bottom:(NSRect)bounds{
    NSBezierPath* thePath = nil;
    thePath = [NSBezierPath bezierPath];
    float radius = self.radius;
    NSPoint thePoint = NSMakePoint(NSMinX(bounds), NSMinY(bounds));
    [thePath moveToPoint:thePoint];
    
    thePoint = NSMakePoint(NSMaxX(bounds), NSMinY(bounds));
    [thePath lineToPoint:thePoint];
    
    thePoint = NSMakePoint(NSMaxX(bounds), NSMaxY(bounds) - radius);
    [thePath lineToPoint:thePoint];
    
    thePoint = NSMakePoint(NSMaxX(bounds), NSMaxY(bounds));
    NSPoint tmpPoint = NSMakePoint(NSMaxX(bounds) - radius, NSMaxY(bounds));
    [thePath appendBezierPathWithArcFromPoint:thePoint toPoint:tmpPoint radius:radius];
    
    thePoint = NSMakePoint(NSMinX(bounds) + radius, NSMaxY(bounds));
    [thePath lineToPoint:thePoint];
    
    thePoint = NSMakePoint(NSMinX(bounds), NSMaxY(bounds));
    tmpPoint = NSMakePoint(NSMinX(bounds), NSMaxY(bounds) - radius);
    [thePath appendBezierPathWithArcFromPoint:thePoint toPoint:tmpPoint radius:radius];
    
    [thePath closePath];
    
    return thePath;
}

- (NSImage*)getDisplayImage
{
    NSButtonCell* buttonCell = (NSButtonCell*)self.cell;
    NSImage* image = self.image;
    if(self.isEnabled==NO)
        image = self.disableImage?:image;
    else if(self.isSelected)
        image = self.selectImage?:image;
    else if(buttonCell.isHighlighted)
        image = self.pressImage?:image;
    else if(self.hovered)
        image = self.hoverImage?:image;
    else
        image = self.normalImage?:image;
    
    return image;
}

- (void)getDisplayImageWidth:(float*)outWidth height:(float*)outHeight
{
    float width = 0;
    float height = 0;
    NSImage* theImage = [self getDisplayImage];
    if(!theImage)
        return;
    
    float topMargin = DEFAULT_IMAGE_MARGIN;
    float bottomMargin = DEFAULT_IMAGE_MARGIN;
    float leftMargin = DEFAULT_IMAGE_MARGIN;
    float rightMargin = DEFAULT_IMAGE_MARGIN;
    if(fabs(self.topMargin) > 1e-2)
        topMargin = self.topMargin;
    if(fabs(self.bottomMargin) > 1e-2)
        bottomMargin = self.bottomMargin;
    if(fabs(self.leftMargin) > 1e-2)
        leftMargin = self.leftMargin;
    if(fabs(self.rightMargin) > 1e-2)
        rightMargin = self.rightMargin;
    
    if(theImage.size.width > theImage.size.height)
    {
        width = self.bounds.size.width-leftMargin-rightMargin;
        height = (theImage.size.height/theImage.size.width)*width;
    }
    else
    {
        height = self.bounds.size.height-topMargin-bottomMargin;
        width = (theImage.size.width/theImage.size.height)*height;
    }
    
    *outWidth = width;
    *outHeight = height;
}
- (ZMBackgroundDrawer)getDisplayDrawer{
    NSButtonCell* buttonCell = (NSButtonCell*)self.cell;
    ZMBackgroundDrawer bgDrawer = nil;
    
    bgDrawer = self.backgroundDrawer;
    if(self.isEnabled==NO)
        bgDrawer = self.disableBackgroundDrawer?:bgDrawer;
    else if(self.isSelected)
        bgDrawer = self.selectBackgroundDrawer?:bgDrawer;
    else if(buttonCell.isHighlighted)
        bgDrawer = self.pressBackgroundDrawer?:bgDrawer;
    else if(self.hovered)
        bgDrawer = self.hoverBackgroundDrawer?:bgDrawer;
    else
        bgDrawer = self.normalBackgroundDrawer?:bgDrawer;
    
    return bgDrawer;
}

- (NSColor*)getDisplayTitleColor
{
    NSButtonCell* buttonCell = (NSButtonCell*)self.cell;
    NSColor* titleColor = self.titleColor;
    if(self.isEnabled==NO)
        titleColor = self.disableTitleColor?:titleColor;
    else if(self.isSelected)
        titleColor = self.selectTitleColor?:titleColor;
    else if(buttonCell.isHighlighted)
        titleColor = self.pressTitleColor?:titleColor;
    else if(self.hovered)
        titleColor = self.hoverTitleColor?:titleColor;
    else
        titleColor = self.normalTitleColor?:titleColor;
    
    if(!titleColor)
        titleColor = [NSColor blackColor];
    
    return titleColor;
}

- (NSColor*)getDisplayBgColor
{
    NSButtonCell* buttonCell = (NSButtonCell*)self.cell;
    NSColor* bgColor = self.backgroundColor;
    if(self.isEnabled==NO)
        bgColor = self.disableBackgroundColor?:bgColor;
    else if(self.isSelected)
        bgColor = self.selectBackgroundColor?:bgColor;
    else if(buttonCell.isHighlighted)
        bgColor = self.pressBackgoundColor?:bgColor;
    else if(self.hovered)
        bgColor = self.hoverBackgroundColor?:bgColor;
    else
        bgColor = self.normalBackgroundColor?:bgColor;
    
    return bgColor;
}

- (NSColor*)getDisplayBorderColor
{
    NSButtonCell* buttonCell = (NSButtonCell*)self.cell;
    NSColor* color = self.borderColor;
    if(self.isEnabled==NO)
        color = self.disableBorderColor?:color;
    else if(self.isSelected)
        color = self.selectBorderColor?:color;
    else if(buttonCell.isHighlighted)
        color = self.pressBorderColor?:color;
    else if(self.hovered)
        color = self.hoverBorderColor?:color;
    else
        color = self.normalBorderColor?:color;
    
    return color;
}
- (NSDictionary*)getDispalyTitleAttribute
{
    NSFont* titleFont = self.cell.font?:[NSFont systemFontOfSize:12];
    NSColor* titleColor = [self getDisplayTitleColor];
    
    NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setAlignment:self.textAlignment];
    [paragraphStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];
    NSMutableDictionary* titleAttri = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       titleFont, NSFontAttributeName,
                                       titleColor, NSForegroundColorAttributeName,
                                       paragraphStyle, NSParagraphStyleAttributeName,
                                       nil];
    if(_textUnderLineStyle != NSUnderlineStyleNone){
        [titleAttri setObject:@(_textUnderLineStyle) forKey:NSUnderlineStyleAttributeName];
        if(_textUnderLineColor){
            [titleAttri setObject:_textUnderLineColor forKey:NSUnderlineColorAttributeName];
        }
    }
    
    return titleAttri;
}

- (NSInteger)getTitleStringWidth
{
    NSString* title = self.title;
    if(title)
    {
        NSDictionary* attribute = [self getDispalyTitleAttribute];
        
        NSAttributedString* attriString = [[NSAttributedString alloc] initWithString:title attributes:attribute];
        NSSize size = [attriString size];
        return ceilf(size.width);
    }
    return 0;
}
- (NSInteger)getTitleStringHeight
{
    NSString* title = self.title;
    if(title)
    {
        NSDictionary* attribute = [self getDispalyTitleAttribute];
        
        NSAttributedString* attriString = [[NSAttributedString alloc] initWithString:title attributes:attribute];
        NSSize size = [attriString size];
        return ceilf(size.height);
    }
    return 0;
}

- (void)getDisplayImageX:(float*)outX imageY:(float*)outY width:(float *)outWidth height:(float *)outHeight{
    if(self.imagePosition == NSImageOnly){
        [self getDisplayImageWidth:outWidth height:outHeight];
        *outX = (self.bounds.size.width-*outWidth)/2.0f;
        *outY = (self.bounds.size.height-*outHeight)/2.0f;
    }
    else if(self.imagePosition == NSNoImage){
        *outX = 0;
        *outY = 0;
        *outWidth = self.bounds.size.width;
        *outWidth = self.bounds.size.height;
    }
    else if(self.imagePosition == NSImageAbove){
        NSImage* image = [self getDisplayImage];
        *outWidth = image.size.width;
        *outHeight = image.size.height;
        *outY = 4;
        *outX = (self.bounds.size.width-*outWidth)/2.0f;
        if(fabs(self.horizontalAdjust) > 0)
            *outX += self.horizontalAdjust;
    }
    else if(self.imagePosition == NSImageLeft){
        NSImage* image = [self getDisplayImage];
        *outWidth = image.size.width;
        *outHeight = image.size.height;
        *outY = (self.bounds.size.height-*outHeight)/2.0f;
        *outX = 5;
        if(!self.title)
            *outX = (self.bounds.size.width-*outWidth)/2.0f;
    }
    else if(self.imagePosition == NSImageRight){
        NSImage* image = [self getDisplayImage];
        *outWidth = image.size.width;
        *outHeight = image.size.height;
        *outY = (self.bounds.size.height-*outHeight)/2.0f+1;
        *outX = self.bounds.size.width-4-*outWidth;
        if(!self.title)
            *outX = (self.bounds.size.width-*outWidth)/2.0f;
    }
    else{
        *outX = 0;
        *outY = 0;
        *outWidth = self.bounds.size.width;
        *outWidth = self.bounds.size.height;
    }
}


@end

