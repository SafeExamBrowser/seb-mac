//
//  SEBDockItemMenu.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 13/10/14.
//
//

#import <Cocoa/Cocoa.h>
#import "DropDownButton.h"

@interface SEBDockItemMenu : NSMenu

@property (strong) NSView *dockMenuView;
@property (strong) NSPopover *dockMenuPopover;
@property (strong) DropDownButton *dockMenuDropDownButton;

- (void) setPopoverMenuSize;

@end
