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
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"

@interface SEBDockController ()

@end

@implementation SEBDockController

- (id)init {
    self = [super init];
    if (self) {
        // Get dock height
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        CGFloat dockHeight = [preferences secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
        // Enforce minimum SEB Dock height
        if (dockHeight < 40) dockHeight = 40;

        NSRect initialContentRect = NSMakeRect(0, 0, 1024, dockHeight);
        self.dockWindow = [[SEBDockWindow alloc] initWithContentRect:initialContentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES];
        
        NSView *superview = [self.dockWindow contentView];
        SEBDockView *dockView = [[SEBDockView alloc] initWithFrame:initialContentRect];
        [dockView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [superview addSubview:dockView];
        
        // Calculate icon sizes and padding according to dock height
        verticalPadding = dockHeight / 10;
        horizontalPadding = (verticalPadding < 10) ? 10 : verticalPadding;
        iconSize = dockHeight - 2 * verticalPadding;
        
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


// Add dock items passed in array pinned to the left edge of the dock (from left to right)
- (void) setLeftItems:(NSArray *)newLeftDockItems
{
    if (_leftDockItems) {
        _leftDockItems = nil;
    }
    
    if (newLeftDockItems) {
        NSView *superview = [self.dockWindow contentView];
        _leftDockItems = newLeftDockItems;
        NSView *previousDockItemView;
        
        for (id<SEBDockItem> dockItem in self.leftDockItems) {
            NSView *dockItemView;
            if (dockItem.icon) {
                SEBDockItemButton *newDockItemButton = [[SEBDockItemButton alloc] initWithFrame:NSMakeRect(0, 0, iconSize, iconSize) icon:dockItem.icon title:dockItem.title];
                // If the new dock item declares an action, then link this to the dock icon button
                if ([dockItem respondsToSelector:@selector(action)]) {
                    [newDockItemButton setTarget:dockItem];
                    [newDockItemButton setAction:@selector(action)];
                }
                [newDockItemButton setToolTip:dockItem.toolTip];
                dockItemView = newDockItemButton;
            } else {
                if ([dockItem respondsToSelector:@selector(view)]) {
                    dockItemView = dockItem.view;
                } else {
                    dockItemView = nil;
                }
            }
            NSMutableArray *constraints = [NSMutableArray new];
            if (dockItemView) {
                [constraints addObject:[NSLayoutConstraint constraintWithItem:dockItemView attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual toItem:superview
                                                                    attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];

                if (previousDockItemView) {
                    [constraints addObject:[NSLayoutConstraint constraintWithItem:previousDockItemView attribute:NSLayoutAttributeRight
                                                 relatedBy:NSLayoutRelationEqual toItem:dockItemView
                                                 attribute:NSLayoutAttributeLeft multiplier:1.0 constant:8.0]];
                }
                if (constraints.count > 0) {
                    [dockItemView addConstraints:constraints];
                }
                [superview addSubview: dockItemView];
            }

        }
    }
}


// Add dock items passed in array pinned to the right edge of the left items dock area
- (void) setCenterItems:(NSArray *)newCenterDockItems
{
    
}


// Add dock items passed in array pinned to the right edge of the dock (from right to left)
- (void) setRightItems:(NSArray *)newRightDockItems
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
