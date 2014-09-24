//
//  SEBDockController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/09/14.
//
//

#import "SEBDockController.h"
#import "SEBDockWindow.h"
#import "SEBDockView.h"

@interface SEBDockController ()

@end

@implementation SEBDockController

- (id)init {
    self = [super init];
    if (self) {
        
        // Create the Dock window
        NSRect initialContentRect = NSMakeRect(0, 0, 1024, 40);
        self.dockWindow = [[SEBDockWindow alloc] initWithContentRect:initialContentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
        
        NSView *superview = [self.dockWindow contentView];
        SEBDockView *dockView = [[SEBDockView alloc] initWithFrame:initialContentRect];
        [dockView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [superview addSubview:dockView];

        self.window = self.dockWindow;
        [self.window setLevel:NSMainMenuWindowLevel+2];
        [self.window setAcceptsMouseMovedEvents:YES];

    }
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (void) showDock
{
    [self.dockWindow setCalculatedFrame];
    [self showWindow:self];
}


- (void) hideDock
{
    [self.window orderOut:self];
}


- (void) adjustDock
{
    [self.dockWindow setCalculatedFrame];
}


@end
