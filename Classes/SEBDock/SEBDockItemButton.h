//
//  SEBDockItem.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/09/14.
//
//

#import <Cocoa/Cocoa.h>
#import "DropDownButton.h"
#import "SEBDockItemMenu.h"

@interface SEBDockItemButton : NSButton
{
    NSTrackingArea *trackingArea;
    NSPopUpButtonCell *popUpCell;
    
    BOOL mouseDown;
}

//@property (strong) NSString *itemTitle;

@property (strong) NSTextField *label;
@property (strong) NSPopover *labelPopover;
@property (strong) SEBDockItemMenu *dockMenu;

- (id) initWithFrame:(NSRect)frameRect icon:(NSImage *)itemIcon title:(NSString *)itemTitle menu:(SEBDockItemMenu *)itemMenu;

- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)updateTrackingAreas;

@end
