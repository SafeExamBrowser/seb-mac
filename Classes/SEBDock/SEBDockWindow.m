//
//  SEBDockWindow.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.09.14.
//
//

#import "SEBDockWindow.h"

@implementation SEBDockWindow


//- (void)sendEvent:(NSEvent *)theEvent
//{
//    if ([theEvent type] == NSMouseMoved) {
//        NSLog(@"Mouse moved filtered");
//    } else {
//        [super sendEvent:theEvent];
//    }
//}

        
- (void) setCalculatedFrame:(NSScreen *)screen
{
    // Get frame of the screen
    NSRect screenFrame = screen.frame;

    // Calculate frame of SEB Dock
    NSRect windowFrame;
    windowFrame.origin.x = screenFrame.origin.x;

    windowFrame.size.width = screenFrame.size.width;
    windowFrame.size.height = self.height;

    // Calculate y position: On bottom of screen
    windowFrame.origin.y = screenFrame.origin.y;
    // Change Window size
    [self setFrame:windowFrame display:YES];    
}


@end
