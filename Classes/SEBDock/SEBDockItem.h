//
//  SEBDockItem.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/09/14.
//
//

#import <Cocoa/Cocoa.h>

@interface SEBDockItem : NSButton {
    NSTrackingArea *trackingArea;
}

@property (strong) NSPopover *labelPopover;
//@property (nonatomic, retain) NSTrackingArea *trackingArea;

- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)updateTrackingAreas;

@end
