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
#import "SEBDockItem.h"
#import "SEBDockItemLabelTextField.h"

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
        
        int x = 10;
        int y = 4;
        
        int iconSize = 32;
        
        SEBDockItem *dockItem = [[SEBDockItem alloc] initWithFrame:NSMakeRect(x, y, iconSize, iconSize)];
        [superview addSubview: dockItem];
        NSImage *icon = [NSApp applicationIconImage];
        [icon setSize: NSMakeSize(iconSize, iconSize)];
        [dockItem setImage:icon];
       
        [dockItem setButtonType:NSMomentaryPushInButton];
        [dockItem setImagePosition:NSImageOnly];
        [dockItem setBordered:NO];

        [dockItem setTarget:self];
        [dockItem setAction:@selector(buttonPressed)];

        // Create text label for dock item
        NSRect frameRect = NSMakeRect(0,0,155,21); // This will change based on the size you need
        NSTextField *dockItemLabel = [[NSTextField alloc] initWithFrame:frameRect];
        [dockItemLabel setTextColor:[NSColor whiteColor]];
        dockItemLabel.bezeled = NO;
        dockItemLabel.editable = NO;
        dockItemLabel.drawsBackground = NO;
        [dockItemLabel setFont:[NSFont boldSystemFontOfSize:14]];
        [dockItemLabel.cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
        dockItemLabel.stringValue = @"Safe Exam Browser";
        NSSize dockItemLabelSize = [dockItemLabel intrinsicContentSize];
        [dockItemLabel setAlignment:NSCenterTextAlignment];
        CGFloat dockItemLabelWidth = dockItemLabelSize.width + 14;
        if (dockItemLabelWidth > 610) {
            dockItemLabelWidth = 610;
        }
        [dockItemLabel setFrameSize:NSMakeSize(dockItemLabelWidth, dockItemLabelSize.height + 3)];
        NSView *dockItemLabelView = [[NSView alloc] initWithFrame:dockItemLabel.frame];
        [dockItemLabelView addSubview:dockItemLabel];
        [dockItemLabelView setContentHuggingPriority:NSLayoutPriorityFittingSizeCompression-1.0 forOrientation:NSLayoutConstraintOrientationVertical];
        
        NSViewController *controller = [[NSViewController alloc] init];
        controller.view = dockItemLabelView;
        
        NSPopover *popover = [[NSPopover alloc] init];
        [popover setContentSize:dockItemLabelView.frame.size];
        [popover setContentViewController:controller];
        [popover setAppearance:NSPopoverAppearanceHUD];
        [popover setAnimates:NO];
        
        dockItem.labelPopover = popover;

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

@end
