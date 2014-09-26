//
//  SEBDockItem.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/09/14.
//
//

#import <Cocoa/Cocoa.h>

@interface SEBDockItemButton : NSButton {
    NSTrackingArea *trackingArea;
}

//@property (strong) NSString *itemTitle;

@property (strong) NSTextField *label;
@property (strong) NSPopover *labelPopover;
//@property (nonatomic, retain) NSTrackingArea *trackingArea;

- (id) initWithFrame:(NSRect)frameRect icon:(NSImage *)itemIcon title:(NSString *)itemTitle;

- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)updateTrackingAreas;

@end
