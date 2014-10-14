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
    NSLog(@"SEBDockMenu size: %f, %f", SEBDockMenuSize.width, SEBDockMenuSize.height);
#endif
    NSView *sizingMenuItemView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, SEBDockMenuSize.width, 0)];
    [[self itemAtIndex:0] setView:sizingMenuItemView];
    int numberOfItems = self.numberOfItems;
    [self.dockMenuView setFrame:NSMakeRect(0, 0, SEBDockMenuSize.width, SEBDockMenuSize.height - (numberOfItems == 2 ? 3 : numberOfItems))];
    [self.dockMenuPopover setContentSize:self.dockMenuView.frame.size];
    
    if (numberOfItems == 2) {
            [self.dockMenuDropDownButton setFrame:NSMakeRect(-4, 38, 0, 0)];
    } else {
        [self.dockMenuDropDownButton setFrame:NSMakeRect(-4, 14, 0, 0)];
    }
}

@end
