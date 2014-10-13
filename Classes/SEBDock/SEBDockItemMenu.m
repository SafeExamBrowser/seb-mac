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
    CGFloat SEBDockMenuWidth = SEBDockMenuSize.width + 14;
    if (SEBDockMenuWidth > 500) {
        SEBDockMenuWidth = 500;
    }
    [self.dockMenuView setFrame:NSMakeRect(0, 0, SEBDockMenuSize.width-13, SEBDockMenuSize.height - 22)];
    [self.dockMenuPopover setContentSize:self.dockMenuView.frame.size];

}

@end
