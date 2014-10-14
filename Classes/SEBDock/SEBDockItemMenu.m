//
//  SEBDockItemMenu.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 13/10/14.
//
//

#import "SEBDockItemMenu.h"

@implementation SEBDockItemMenu

- (void) setPopoverMenuSize
{
    NSSize SEBDockMenuSize = [self size];
#ifdef DEBUG
    NSLog(@"SEBDockItemMenu size: %f, %f", SEBDockMenuSize.width, SEBDockMenuSize.height);
#endif
    int numberOfItems = self.numberOfItems;
    NSRect newMenuViewFrame = NSMakeRect(0, 0, SEBDockMenuSize.width, SEBDockMenuSize.height - (numberOfItems == 2 ? 3 : numberOfItems));
    NSRect currentMenuViewFrame = self.dockMenuView.frame;
    
    // Set the drop down button position and menu view and popover size only when the frame changed
    if (!(newMenuViewFrame.size.width == currentMenuViewFrame.size.width && newMenuViewFrame.size.height == currentMenuViewFrame.size.height))
    {
        NSView *sizingMenuItemView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, SEBDockMenuSize.width, 0)];
        [[self itemAtIndex:0] setView:sizingMenuItemView];
        [self.dockMenuView setFrame:newMenuViewFrame];
        [self.dockMenuPopover setContentSize:newMenuViewFrame.size];
        
        if (numberOfItems == 2) {
            [self.dockMenuDropDownButton setFrame:NSMakeRect(-4, 38, 0, 0)];
        } else {
            [self.dockMenuDropDownButton setFrame:NSMakeRect(-4, 14, 0, 0)];
        }
    }
}

@end
