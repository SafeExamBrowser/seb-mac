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
    NSPopUpButtonCell *popUpCell;
}

//@property (strong) NSString *itemTitle;

@property (strong) NSTextField *label;
@property (strong) NSPopover *labelPopover;
@property (strong) NSMenu *SEBDockMenu;
@property (strong) NSPopover *SEBDockMenuPopover;

- (id) initWithFrame:(NSRect)frameRect icon:(NSImage *)itemIcon title:(NSString *)itemTitle;

- (void)setUsesSEBDockMenu:(BOOL)flag;
- (BOOL)usesSEBDockMenu;

- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)updateTrackingAreas;

@end
