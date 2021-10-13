//
//  ZMSDKRoundImageView.m
//  ZoomSDKSample
//
//  Created by derain on 2018/12/4.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKRoundImageView.h"

#define kZMPTRoundImageViewRadius           7

@implementation ZMSDKRoundImageView

@synthesize image = _image;
@synthesize messageNumber = _messageNumber;
@synthesize isRound = _isRound;
@synthesize radius = _radius;
@synthesize notCompressSize = _notCompressSize;
@synthesize alpha = _alpha;

+ (NSImage*)generateFixedSizeImageWithName:(NSString*)name userID:(NSString*)userID
{
    if (!name)
        return nil;
    
    NSArray* sepName = [name componentsSeparatedByString:@" "];
    
    if (sepName.count <= 0)
        return nil;
    NSString* tempStr = @"";
    for (NSString* str in sepName)
    {
        if ([str isEqualToString:@""])
            continue;
        tempStr = [NSString stringWithFormat:@"%@%C", tempStr, [str characterAtIndex:0]];
        if (tempStr.length > 1)
            break;
    }
    
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(32, 32)];
    NSColor* color = [ZMSDKRoundImageView getColorWithUserID:userID];
    if (!color)
        return nil;
    [image lockFocus];
    [color set];
    NSRect rect = NSMakeRect(0, 0, 32, 32);
    NSRectFill(rect);
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:([NSFont fontWithName:@"Helvetica Neue" size:16]?:[NSFont systemFontOfSize:16]), NSFontAttributeName, [NSColor whiteColor] ,NSForegroundColorAttributeName, nil];
    NSSize size = [tempStr sizeWithAttributes:dict];
    [tempStr drawAtPoint:NSMakePoint((rect.size.width - size.width) / 2, (rect.size.height - size.height) / 2 + 1) withAttributes:dict];
    [image unlockFocus];
    return image;
}

+ (NSImage*)generateImageWithIcon:(NSImage*)inIcon string:(NSString*)inString imageSize:(NSSize)inSize
{
    if(!inIcon && !inString)
        return nil;
    
    NSImage* outImage = [[NSImage alloc] initWithSize:inSize];
    if(!outImage)
        return nil;
    
    NSColor* bgColor = [ZMSDKRoundImageView getColorWithUserID:inString];
    if(!bgColor)
        bgColor = [NSColor colorWithCalibratedRed:41.0/255.0f green:128.0/255.0f blue:185.0/255.0f alpha:1];
    
    [outImage lockFocus];
    
    [bgColor set];
    NSRectFill(NSMakeRect(0, 0, inSize.width, inSize.height));
    
    if(inIcon)
    {
        NSSize iconSize = inIcon.size;
        float xPos = (inSize.width-iconSize.width)/2.0;
        float yPos= (inSize.height-iconSize.height)/2.0;
        [inIcon drawInRect:NSMakeRect(xPos, yPos, iconSize.width, iconSize.height) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
    else if(inString)
    {
        NSArray* sepName = [inString componentsSeparatedByString:@" "];
        if(sepName.count <= 0)
        {
            [outImage unlockFocus];
            return nil;
        }
        
        NSString* tempStr = @"";
        for(__strong NSString* str in sepName)
        {
            str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if([str isEqualToString:@""])
                continue;
            tempStr = [NSString stringWithFormat:@"%@%C", tempStr, [str characterAtIndex:0]];
            if(tempStr.length > 1)
                break;
        }
        
        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:([NSFont fontWithName:@"Helvetica Neue" size:inSize.height/2]?:[NSFont systemFontOfSize:inSize.height/2]), NSFontAttributeName, [NSColor whiteColor] ,NSForegroundColorAttributeName, nil];
        NSSize size = [tempStr sizeWithAttributes:dict];
        [tempStr drawAtPoint:NSMakePoint((inSize.width-size.width)/2, (inSize.height-size.height)/2 + (inSize.height > 35 ? 0 : 1)) withAttributes:dict];
    }
    
    [outImage unlockFocus];
    
    return outImage;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _radius = -1;
        _alpha = 1.0;
    }
    return self;
}

- (void)cleanup
{
    
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];//for system will add some notify
    _image = nil;
}

- (void)awakeFromNib
{
    _isRound = YES;
    _radius = -1;
    _alpha = 1.0;
}

- (void)mouseDown:(NSEvent *)theEvent
{
   if (self.superview)
        [self.superview mouseDown:theEvent];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    if (self.superview)
        [self.superview rightMouseDown:theEvent];
}

- (NSMenu*)menuForEvent:(NSEvent *)event
{
    if (self.superview)
        return [self.superview menuForEvent:event];
    return nil;
}

+ (NSColor*)getColorWithUserID:(NSString*)userID
{
    int idx = 0;
    for(int i=0; i < userID.length; i++)
    {
        idx += [userID characterAtIndex:i];
        idx %= 8;
    }
    
    NSColor* color = nil;
    switch (idx)
    {
        case 0:
            color = [NSColor colorWithCalibratedRed:39.0/255.0f green:174.0/255.0f blue:96.0/255.0f alpha:1];
            break;
        case 1:
            color = [NSColor colorWithCalibratedRed:22.0/255.0f green:160.0/255.0f blue:133.0/255.0f alpha:1];
            break;
        case 2:
            color = [NSColor colorWithCalibratedRed:41.0/255.0f green:128.0/255.0f blue:185.0/255.0f alpha:1];
            break;
        case 3:
            color = [NSColor colorWithCalibratedRed:142.0/255.0f green:68.0/255.0f blue:173.0/255.0f alpha:1];
            break;
        case 4:
            color = [NSColor colorWithCalibratedRed:52.0/255.0f green:73.0/255.0f blue:94.0/255.0f alpha:1];
            break;
        case 5:
            color = [NSColor colorWithCalibratedRed:243.0/255.0f green:156.0/255.0f blue:18.0/255.0f alpha:1];
            break;
        case 6:
            color = [NSColor colorWithCalibratedRed:211.0/255.0f green:84.0/255.0f blue:0.0/255.0f alpha:1];
            break;
        case 7:
            color = [NSColor colorWithCalibratedRed:192.0/255.0f green:57.0/255.0f blue:43.0/255.0f alpha:1];
            break;
            
        default:
            color = [NSColor whiteColor];
            break;
    }
    return color;
}

- (void)generateBackColorWithUserID:(NSString*)userID
{
    NSColor* color = [ZMSDKRoundImageView getColorWithUserID:userID];
    if (!color)
        return;
    NSSize size = self.bounds.size;
    NSImage* image = [[NSImage alloc] initWithSize:size];
    
    [image lockFocus];
    [color set];
    NSRectFill(self.bounds);
    if (self.image)
    {
        NSSize imageSize = self.image.size;
        if (imageSize.width > size.width || imageSize.height > size.height)
            imageSize = size;
        NSRect rect = NSMakeRect(self.bounds.origin.x + (size.width - imageSize.width) / 2, self.bounds.origin.y + (size.height - imageSize.height) / 2, imageSize.width, imageSize.height);
        [self.image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSImageInterpolationHigh], NSImageHintInterpolation, nil]];
    }
    [image unlockFocus];
    self.image = image;
}

- (void)generateImageWithName:(NSString*)name userID:(NSString*)userID
{
    if (!name)
        return;
    
    NSColor* color = [ZMSDKRoundImageView getColorWithUserID:userID];
    if (!color)
        return;
    
    NSArray* sepName = [name componentsSeparatedByString:@" "];
    
    if (sepName.count <= 0)
        return;
    NSString* tempStr = @"";
    for (NSString* str in sepName)
    {
        if ([str isEqualToString:@""])
            continue;
        tempStr = [NSString stringWithFormat:@"%@%C", tempStr, [str characterAtIndex:0]];
        if (tempStr.length > 1)
            break;
    }
    
    NSImage* image = [[NSImage alloc] initWithSize:self.bounds.size];
    [image lockFocus];
    [color set];
    NSRectFill(self.bounds);
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:([NSFont fontWithName:@"Helvetica Neue" size:self.bounds.size.height/2]?:[NSFont systemFontOfSize:self.bounds.size.height/2]), NSFontAttributeName, [NSColor whiteColor] ,NSForegroundColorAttributeName, nil];
    NSSize size = [tempStr sizeWithAttributes:dict];
    [tempStr drawAtPoint:NSMakePoint((self.bounds.size.width - size.width) / 2, (self.bounds.size.height - size.height) / 2 + (self.bounds.size.height > 35 ? 0 : 1)) withAttributes:dict];
    [image unlockFocus];
    self.image = image;
}

- (void)drawRect:(NSRect)dirtyRect
{
    //[super drawRect:dirtyRect];
    NSRect drawRect = NSMakeRect(2, 2, self.bounds.size.width - 4, self.bounds.size.height - 4);
    
    if (!self.isRound && _image && [_image isValid])
    {
        [_image drawInRect:drawRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSImageInterpolationHigh], NSImageHintInterpolation, nil]];
        return;
    }
    
    NSBezierPath *path = nil;
    if (self.radius == -1 || self.radius > drawRect.size.width / 2 || self.radius > drawRect.size.height / 2)
        path = [NSBezierPath bezierPathWithRoundedRect:drawRect
                                               xRadius:drawRect.size.width / 2
                                               yRadius:drawRect.size.height / 2];
    else if (self.radius == 0)
        path = [NSBezierPath bezierPathWithRect:drawRect];
    else
        path = [NSBezierPath bezierPathWithRoundedRect:drawRect
                                               xRadius:self.radius
                                               yRadius:self.radius];
    if (_image && [_image isValid])
    {
        [NSGraphicsContext saveGraphicsState];
        [path addClip];
        if (self.notCompressSize)
        {
            NSSize size = [_image size];
            NSRect imageRect = NSZeroRect;
            if (size.width >= drawRect.size.width && size.height >= drawRect.size.width)
            {
                if (size.width > size.height)
                    imageRect = NSMakeRect((size.width - size.height)/2, 0, size.height, size.height);
                else
                    imageRect = NSMakeRect(0, (size.height - size.width)/2, size.width, size.width);
            }
            else if (size.width >= drawRect.size.width && size.height < drawRect.size.width)
            {
                imageRect = NSMakeRect((size.width - drawRect.size.width)/2, 0, drawRect.size.width, size.height);
                drawRect.origin.y = (drawRect.size.height - size.height)/2;
                drawRect.size.height = size.height;
            }
            else if (size.width < drawRect.size.width && size.height >= drawRect.size.width)
            {
                imageRect = NSMakeRect(0, (size.height - drawRect.size.height)/2, size.width, drawRect.size.height);
                drawRect.origin.x = (drawRect.size.width - size.width)/2;
                drawRect.size.width = size.width;
            }
            else
            {
                imageRect = NSMakeRect(0, 0, size.width, size.height);
                drawRect = NSMakeRect((drawRect.size.width - size.width)/2, (drawRect.size.height - size.height)/2, size.width, size.height);
            }
            [_image drawInRect:drawRect fromRect:imageRect operation:NSCompositeSourceOver fraction:_alpha respectFlipped:YES hints:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSImageInterpolationHigh], NSImageHintInterpolation, nil]];
        }
        else
            [_image drawInRect:drawRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:_alpha respectFlipped:YES hints:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:NSImageInterpolationHigh], NSImageHintInterpolation, nil]];
        [NSGraphicsContext restoreGraphicsState];
    }
    if (self.messageNumber > 0)
    {
        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:([NSFont fontWithName:@"Helvetica Neue" size:9]?:[NSFont systemFontOfSize:9]), NSFontAttributeName, [NSColor whiteColor] ,NSForegroundColorAttributeName, nil];
        NSString* str = self.messageNumber > 99 ? @"99+" : [NSString stringWithFormat:@"%d", self.messageNumber];
        NSSize size = [str sizeWithAttributes:dict];
        
        float width = size.width > kZMPTRoundImageViewRadius * 4 / 3 ? size.width + 12 : 18;
        NSRect rect = NSMakeRect(self.bounds.size.width - width , self.bounds.size.height - 2 * kZMPTRoundImageViewRadius, width, 2 * kZMPTRoundImageViewRadius);
        NSBezierPath* bezierPath = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:kZMPTRoundImageViewRadius yRadius:kZMPTRoundImageViewRadius];
        [[NSColor colorWithCalibratedRed:244.0/255.0f green:92.0/255.0f blue:84.0/255.0f alpha:1] set];
        [bezierPath fill];
        
        [str drawAtPoint:NSMakePoint(rect.origin.x  + (rect.size.width - size.width) / 2 + 0.2, rect.origin.y + 1 + (2 * kZMPTRoundImageViewRadius - size.height) / 2 + 1) withAttributes:dict];
        [[NSColor colorWithCalibratedRed:208.0/255.0l green:1.0/255.0l blue:26.0/255.0l alpha:0.05] set];
        [bezierPath stroke];
    }
}

@end
