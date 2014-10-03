//
//  SEBDockItem.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/09/14.
//
//

#import <Cocoa/Cocoa.h>
#import "DropDownButton.h"

@interface SEBDockItemButton : NSButton <NSMenuDelegate>
{
    NSTrackingArea *trackingArea;
    NSPopUpButtonCell *popUpCell;
    
    BOOL mouseDown;
}

//@property (strong) NSString *itemTitle;

@property (strong) NSTextField *label;
@property (strong) NSPopover *labelPopover;
@property (strong) NSMenu *SEBDockMenu;
@property (strong) NSPopover *SEBDockMenuPopover;
@property (strong) DropDownButton *dockMenuDropDownButton;

- (id) initWithFrame:(NSRect)frameRect icon:(NSImage *)itemIcon title:(NSString *)itemTitle menu:(NSMenu *)itemMenu;

- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)updateTrackingAreas;

@end
