//
//  ShareContentView.m
//  ZoomSDKSample
//
//  Created by TOTTI on 2018/7/26.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import "ShareContentView.h"
#import <ZoomSDK/ZoomSDK.h>
@implementation ShareContentView
-(id)initWithFrame:(NSRect)frameRect
{
    if(self = [super initWithFrame:frameRect])
    {
        self.userid = 0;
        self.shareView  = nil;
        return self;
    }
    return nil;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)dealloc
{
    self.userid = 0;
    self.shareView  = nil;
}

- (NSFocusRingType)focusRingType
{
    return NSFocusRingTypeNone;
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    [self sendRemoteControlEvent:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    [self sendRemoteControlEvent:theEvent];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    [super mouseMoved:theEvent];
    [self sendRemoteControlEvent:theEvent];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    [self sendRemoteControlEvent:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    [super rightMouseDown:theEvent];
    [self sendRemoteControlEvent:theEvent];
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
    [super rightMouseDragged:theEvent];
    [self sendRemoteControlEvent:theEvent];
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
    [super rightMouseUp:theEvent];
    [self sendRemoteControlEvent:theEvent];
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
    [super otherMouseDown:theEvent];
    [self sendRemoteControlEvent:theEvent];
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
    [self sendRemoteControlEvent:theEvent];
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
    [super otherMouseUp:theEvent];
    [self sendRemoteControlEvent:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
    [self sendRemoteControlEvent:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
    [super keyUp:theEvent];
    [self sendRemoteControlEvent:theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
    [super flagsChanged:theEvent];
    [self sendRemoteControlEvent:theEvent];
}

- (void)cursorUpdate:(NSEvent *)event
{
    [super cursorUpdate:event];
}


- (void)sendRemoteControlEvent:(NSEvent *)theEvent
{
    ZoomSDKRemoteControllerHelper* helper = [[[[ZoomSDK sharedSDK] getMeetingService] getASController] getRemoteControllerHelper];
    if(helper)
    {
        if([self isController])
           [helper sendRemoteControlEvent:theEvent ShareView:self.shareView];
    }
}

- (BOOL)isController
{
    ZoomSDKRemoteControllerHelper* helper = [[[[ZoomSDK sharedSDK] getMeetingService] getASController] getRemoteControllerHelper];
    if(helper)
    {
         if([helper isInRemoteControlling:self.userid] == ZoomSDKError_Success)
             return YES;
    }
    return NO;
}
@end
