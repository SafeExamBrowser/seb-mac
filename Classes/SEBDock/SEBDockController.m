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
#import "SEBDockItemButton.h"

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
        
        CGFloat x = 10;
        CGFloat y = 4;
        
        iconSize = 32;
        
        SEBDockItemButton *dockItem = [[SEBDockItemButton alloc] initWithFrame:NSMakeRect(x, y, iconSize, iconSize) icon:[NSApp applicationIconImage] title:@"Safe Exam Browser"];
        [dockItem setTarget:self];
        [dockItem setAction:@selector(buttonPressed)];

        [superview addSubview: dockItem];
        
        x = self.dockWindow.screen.frame.size.width - iconSize - 10;
        
        dockItem = [[SEBDockItemButton alloc] initWithFrame:NSMakeRect(x, y, iconSize, iconSize) icon:[NSImage imageNamed:@"SEBShutDownIcon"] title:nil];
        [dockItem setToolTip:@"Quit SEB"];
        [dockItem setTarget:self];
        [dockItem setAction:@selector(quitButtonPressed)];
        
        [superview addSubview: dockItem];

        
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


- (void) setLeftItems:(NSArray *)leftDockItems
{
    
}


- (void) setCenterItems:(NSArray *)centerDockItems
{
    
}


- (void) setRightItems:(NSArray *)rightDockItems
{
    
}


- (void) showDock
{
    [self.dockWindow setCalculatedFrame:self.window.screen];
    [self showWindow:self];
}


- (void) hideDock
{
    [self.window orderOut:self];
}


- (void) adjustDock
{
    [self.dockWindow setCalculatedFrame:self.window.screen];
}


- (void) moveDockToScreen:(NSScreen *)screen
{
    [self.dockWindow setCalculatedFrame:screen];
}


- (void) buttonPressed
{
    [[NSRunningApplication currentApplication] activateWithOptions:(NSApplicationActivateAllWindows | NSApplicationActivateIgnoringOtherApps)];
    //[browserWindow makeKeyAndOrderFront:self];
}

- (void) quitButtonPressed
{
    // Post a notification that SEB should conditionally quit
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestExitNotification" object:self];
}

@end
