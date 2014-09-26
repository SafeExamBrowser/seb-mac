//
//  SEBDockController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/09/14.
//
//

#import <Cocoa/Cocoa.h>
#import "SEBDockWindow.h"
#import "SEBDockItemButton.h"
#import "Constants.h"

@protocol SEBDockItem <NSObject>

- (NSImage *) icon;
- (NSString *) title;
- (SEBDockItemPosition) itemType;
- (void) action;
- (NSString *) toolTip;
- (NSMenu *) menu;

@end


@interface SEBDockController : NSWindowController

@property (strong) SEBDockWindow *dockWindow;

- (void) showDock;
- (void) hideDock;
- (void) adjustDock;
- (void) moveDockToScreen:(NSScreen *)screen;

@end
