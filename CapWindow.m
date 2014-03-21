//
//  CapWindow.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06.03.14.
//
//

#import "CapWindow.h"

@implementation CapWindow

@synthesize constrainingToScreenSuspended;

//- (void)orderWindow:(NSWindowOrderingMode)orderingMode relativeTo:(NSInteger)otherWindowNumber
//{
//    [super orderWindow:orderingMode relativeTo:otherWindowNumber];
//    if (orderingMode != NSWindowOut) {
//        
//    }
//}

// This window has its usual -constrainFrameRect:toScreen: behavior temporarily suppressed.
// This enables our window's custom Full Screen Exit animations to avoid being constrained by the
// top edge of the screen and the menu bar.
//
- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen
{
    if (constrainingToScreenSuspended)
    {
        return frameRect;
    }
    else
    {
        return [super constrainFrameRect:frameRect toScreen:screen];
    }
}


//- (BOOL)canBecomeKeyWindow
//{
//    return YES;
//}


@end
