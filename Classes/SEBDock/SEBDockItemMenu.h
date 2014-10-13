//
//  SEBDockItemMenu.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 13/10/14.
//
//

#import <Cocoa/Cocoa.h>

@interface SEBDockItemMenu : NSMenu

@property (strong) NSView *dockMenuView;
@property (strong) NSPopover *dockMenuPopover;

- (void) setPopoverMenuSize;

@end
