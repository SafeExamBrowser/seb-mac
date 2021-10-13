//
//  ZMSDKPTImageButton.m
//  ZoomSDKSample
//
//  Created by derain on 2018/11/19.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKPTImageButton.h"

@implementation ZMSDKTrackingButton

@synthesize hovered = _hovered;
@synthesize trackingArea = _trackingArea;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        return self;
    }
    return nil;
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(self.trackingArea)
    {
        [self removeTrackingArea:self.trackingArea];
        self.trackingArea = nil;
    }
    self.target = nil;
    self.action = nil;
}

- (void)cleanUp
{
    if(self.trackingArea)
    {
        [self removeTrackingArea:self.trackingArea];
        self.trackingArea = nil;
    }
    self.target = nil;
    self.action = nil;
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    if(self.trackingArea)
    {
        [self removeTrackingArea:self.trackingArea];
        self.trackingArea = nil;
    }
    
    if(self.trackingArea == nil)
        self.trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                          options:NSTrackingInVisibleRect | NSTrackingActiveAlways | NSTrackingMouseEnteredAndExited | NSTrackingAssumeInside
                                                            owner:self
                                                         userInfo:nil];
    
    if(![self.trackingAreas containsObject:self.trackingArea])
        [self addTrackingArea:self.trackingArea];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    self.hovered = YES;
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    self.hovered = NO;
    [self setNeedsDisplay:YES];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
    if(self.trackingArea)
    {
        [self removeTrackingArea:self.trackingArea];
        self.trackingArea = nil;
    }
}

- (void)viewDidMoveToWindow
{
    if(self.window)
        [self updateTrackingAreas];
}

- (void)setHidden:(BOOL)flag
{
    if ( flag ) {
        self.hovered = NO;
    }
    
    [self setNeedsDisplay:YES];
    [super setHidden:flag];
}

- (NSRect)getRectInScreen
{
    NSRect theRect = self.frame;
    if(self.superview)
        theRect = [self.superview convertRect:theRect toView:nil];
    if(self.window)
        theRect.origin = [self.window convertRectToScreen:theRect].origin;
    
    
    float yPos = theRect.origin.y-30;
    NSScreen* theScreen = self.window.screen;
    if(!theScreen)
        return theRect;
    
    NSRect theScreenRect = theScreen.frame;
    if(yPos < NSMinY(theScreenRect))
        yPos = NSMaxY(theRect)+10;
    if(NSMinX(theRect) < NSMinX(theScreenRect))
        theRect.origin.x = NSMinX(theScreenRect)+NSWidth(theRect)+10;
    if(NSMaxX(theRect) > NSMaxX(theScreenRect))
        theRect.origin.x = NSMaxX(theScreenRect)-NSWidth(theRect)-10;
    
    theRect.origin.y = yPos;
    
    return theRect;
}
@end


@implementation ZMSDKPTImageButton
@synthesize angle = _angle;
@synthesize normalStartColor = _normalStartColor;
@synthesize normalEndColor =  _normalEndColor;
@synthesize hoverStartColor = _hoverStartColor;
@synthesize hoverEndColor =  _hoverEndColor;
@synthesize pressedStartColor = _pressedStartColor;
@synthesize pressedEndColor =  _pressedEndColor;
@synthesize disabledStartColor = _disabledStartColor;
@synthesize disabledEndColor = _disabledEndColor;
@synthesize normalImage = _normalImage;
@synthesize highlightImage = _highlightImage;
@synthesize disabledImage = _disabledImage;
@synthesize attributes = _attributes;
@synthesize fontColor = _fontColor;

- (id)init
{
    if (self = [super init]) {
        [self setBordered:NO];
    }
    return self;
}

- (NSFocusRingType)focusRingType
{
    return  NSFocusRingTypeNone;
}

- (void)cleanUp
{
    self.normalStartColor = nil;
    self.normalEndColor = nil;
    self.hoverStartColor = nil;
    self.hoverEndColor = nil;
    self.pressedStartColor = nil;
    self.pressedEndColor = nil;
    self.disabledStartColor = nil;
    self.disabledEndColor = nil;
    self.normalImage = nil;
    self.highlightImage = nil;
    self.disabledImage = nil;
    self.attributes = nil;
}

-(void)dealloc
{
    [self cleanUp];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    NSRect bounds = self.bounds;
    NSColor* startColor = nil;
    NSColor* endColor = nil;
    NSImage* image = nil;
    float y_offset = 0;
    
    if ([self isEnabled]) {
        if ([self.cell isHighlighted]) {
            startColor = self.pressedStartColor;
            endColor = self.pressedEndColor;
            image = self.highlightImage;
        } else if (self.hovered){
            startColor = self.hoverStartColor;
            endColor = self.hoverEndColor;
            image = self.normalImage;
        } else {
            startColor = self.normalStartColor;
            endColor = self.normalEndColor;
            image = self.normalImage;
        }
    } else {
        startColor = self.disabledStartColor;
        endColor = self.disabledEndColor;
        image = self.disabledImage;
    }
    
    bounds.size = NSMakeSize(102, 102);
    bounds.origin.y = floorf(self.bounds.size.height - 102);
    bounds.origin.x = floorf((self.bounds.size.width - 102) / 2.0f);
    y_offset = bounds.origin.y;
    
    NSColor* backGroundColor = [NSColor colorWithDeviceRed:249.0f/255 green:249.0f/255 blue:249.0f/255 alpha:1.0f];
    [backGroundColor set];
    [NSBezierPath fillRect:self.bounds];
    
    NSGradient* gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
    NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(bounds, 1, 1) xRadius:18 yRadius:18];
    [gradient drawInBezierPath:path angle:self.angle-90];
    
    bounds.origin.y = floorf( self.bounds.size.height - (bounds.size.height + image.size.height)/2.0);
    bounds.origin.x = floorf(( self.bounds.size.width - image.size.width ) / 2.0f);
    bounds.size = image.size;
    
    [image drawInRect:bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f respectFlipped:YES hints:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSImageInterpolationHigh], NSImageHintInterpolation, nil]];
    
    if(self.title)
    {
        NSColor *fontColor = self.fontColor;
        if (!fontColor) {
            fontColor = [NSColor colorWithDeviceRed:0.34f green:0.34f blue:0.42f alpha:1.0f];
        }
        NSFont* font = [NSFont systemFontOfSize:11];
        NSTextStorage* textStorage = [[NSTextStorage alloc] initWithString:self.title];
        NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setAlignment:NSCenterTextAlignment];
        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
        [textStorage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle
                            range:NSMakeRange(0, [textStorage length])];
        
        if (fontColor)
            [textStorage addAttribute:NSForegroundColorAttributeName value:fontColor range:NSMakeRange(0, [textStorage length])];
        if (font)
            [textStorage addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [textStorage length])];
        
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(self.bounds.size.width, y_offset)];
        [textContainer setLineFragmentPadding:0.0f];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];
        
        NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
        NSPoint point = NSMakePoint(0, -3);
        
        [layoutManager drawGlyphsForGlyphRange: glyphRange atPoint: point];
    }
}
- (int)getTitleWidth
{
    int ret = 0;
    if(self.title)
    {
        NSColor *fontColor = self.fontColor;
        if (!fontColor) {
            fontColor = [NSColor colorWithDeviceRed:0.34f green:0.34f blue:0.42f alpha:1.0f];
        }
        NSFont* font = [NSFont systemFontOfSize:11];
        NSTextStorage* textStorage = [[NSTextStorage alloc] initWithString:self.title];
        NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setAlignment:NSCenterTextAlignment];
        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
        [textStorage addAttribute:NSParagraphStyleAttributeName value:paragraphStyle
                            range:NSMakeRange(0, [textStorage length])];
        
        if (fontColor)
            [textStorage addAttribute:NSForegroundColorAttributeName value:fontColor range:NSMakeRange(0, [textStorage length])];
        if (font)
            [textStorage addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [textStorage length])];
        
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(360, self.bounds.size.height)];
        [textContainer setLineFragmentPadding:0.0f];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];
        
        [layoutManager glyphRangeForTextContainer:textContainer];
        NSSize size = [layoutManager usedRectForTextContainer:textContainer].size;
        ret = ceilf(size.width) + 4;
    }
    return ret;
}

- (void)setTitle:(NSString *)title
{
    [super setTitle:title];
    [self.cell accessibilitySetOverrideValue:self.title forAttribute:NSAccessibilityDescriptionAttribute];
}

- (BOOL)isFlipped
{
    return NO;
}

@end
