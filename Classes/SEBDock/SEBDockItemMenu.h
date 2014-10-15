//
//  SEBDockItemMenu.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 13/10/14.
//
//

#import <Cocoa/Cocoa.h>
#import "DropDownButton.h"

@interface SEBDockItemMenu : NSMenu <NSMenuDelegate>

@property (strong) NSView *dockMenuView;
@property (strong) NSPopover *dockMenuPopover;
@property (strong) DropDownButton *dockMenuDropDownButton;

- (void)showRelativeToRect:(NSRect)positioningRect
                    ofView:(NSView *)positioningView;

// Adjusts size of the NSPopover containing the dock item NSMenu.
// This method needs to be called after changing the title of a NSMenuItem contained in the dock item menu.
- (void) setPopoverMenuSize;

@end
