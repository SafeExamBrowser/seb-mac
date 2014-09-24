//
//  SEBDockView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/09/14.
//
//

#import "SEBDockView.h"

@implementation SEBDockView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}


- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent {
    return YES;
}


- (void)mouseDown:(NSEvent *)theEvent
{
    [NSApp preventWindowOrdering];  //prevent that the cap window is ordered front when clicked in
    return;
}

@end
