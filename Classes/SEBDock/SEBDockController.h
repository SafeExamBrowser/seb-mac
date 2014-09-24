//
//  SEBDockController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/09/14.
//
//

#import <Cocoa/Cocoa.h>
#import "SEBDockWindow.h"

@interface SEBDockController : NSWindowController

@property (strong) SEBDockWindow *dockWindow;


- (void) showDock;
- (void) hideDock;
- (void) adjustDock;


@end
