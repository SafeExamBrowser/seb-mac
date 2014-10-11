//
//  SEBDockItem.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/09/14.
//
//

#import "SEBDockItemButton.h"

@implementation SEBDockItemButton


- (id) initWithFrame:(NSRect)frameRect icon:(NSImage *)itemIcon title:(NSString *)itemTitle menu:(NSMenu *)itemMenu
 {
    self = [super initWithFrame:frameRect];
    if (self) {
        mouseDown = NO;
        // Get image size
        CGFloat iconSize = self.frame.size.width;
        [itemIcon setSize: NSMakeSize(iconSize, iconSize)];
        self.image = itemIcon;
        
        [self setButtonType:NSMomentaryPushInButton];
        [self setImagePosition:NSImageOnly];
        [self setBordered:NO];
        
        // Create text label for dock item, if there was a title set for the item
        if (itemTitle) {
            NSRect frameRect = NSMakeRect(0,0,155,21); // This will change based on the size you need
            self.label = [[NSTextField alloc] initWithFrame:frameRect];
            if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9) {
                // We use white text color only when we have NSPopoverAppearanceHUD, so for OS X <= 10.9
                [self.label setTextColor:[NSColor whiteColor]];
                [self.label setFont:[NSFont boldSystemFontOfSize:14]];
            } else {
                [self.label setTextColor:[NSColor blackColor]];
                [self.label setFont:[NSFont systemFontOfSize:14]];
            }
            self.label.bezeled = NO;
            self.label.editable = NO;
            self.label.drawsBackground = NO;
            [self.label.cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
            self.label.stringValue = itemTitle;
            NSSize dockItemLabelSize = [self.label intrinsicContentSize];
            [self.label setAlignment:NSCenterTextAlignment];
            CGFloat dockItemLabelWidth = dockItemLabelSize.width + 14;
            if (dockItemLabelWidth > 610) {
                dockItemLabelWidth = 610;
            }
            [self.label setFrameSize:NSMakeSize(dockItemLabelWidth, dockItemLabelSize.height + 3)];
            
            // Create view to place label into
            NSView *dockItemLabelView = [[NSView alloc] initWithFrame:self.label.frame];
            [dockItemLabelView addSubview:self.label];
            [dockItemLabelView setContentHuggingPriority:NSLayoutPriorityFittingSizeCompression-1.0 forOrientation:NSLayoutConstraintOrientationVertical];
            
            // Create a view controller for the label view
            NSViewController *controller = [[NSViewController alloc] init];
            controller.view = dockItemLabelView;
            
            // Create the label popover
            NSPopover *popover = [[NSPopover alloc] init];
            [popover setContentSize:dockItemLabelView.frame.size];
            
            // Add the label view controller as content view controller to the popover
            [popover setContentViewController:controller];
            if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9) {
                // We use NSPopoverAppearanceHUD only for OS X <= 10.9, not on OS X 10.10 upwards
                [popover setAppearance:NSPopoverAppearanceHUD];
            }
            [popover setAnimates:NO];
            self.labelPopover = popover;
        }
        
        // Create menu popover if there was a menu set for the item
        if (itemMenu) {
            self.SEBDockMenu = itemMenu; // [itemMenu copy];
            [self.SEBDockMenu setDelegate:self];
            NSSize SEBDockMenuSize = [itemMenu size];
            CGFloat SEBDockMenuWidth = SEBDockMenuSize.width + 14;
            if (SEBDockMenuWidth > 500) {
                SEBDockMenuWidth = 500;
            }
            NSView *SEBDockMenuView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, SEBDockMenuSize.width-13, SEBDockMenuSize.height - 22)];
            DropDownButton *dockMenuDropDownButton = [[DropDownButton alloc] initWithFrame:NSMakeRect(-4, 36, 0, 0)];
            self.dockMenuDropDownButton = dockMenuDropDownButton;
            [dockMenuDropDownButton setMenu:self.SEBDockMenu];
            [SEBDockMenuView addSubview:dockMenuDropDownButton];
            //
            NSViewController *controller = [[NSViewController alloc] init];
            controller.view = SEBDockMenuView;
            
            NSPopover *popover = [[NSPopover alloc] init];
            [popover setContentSize:SEBDockMenuView.frame.size];
            [popover setContentViewController:controller];
            [popover setAnimates:NO];
            self.SEBDockMenuPopover = popover;
        }
    }
    return self;
}


- (void)mouseDown:(NSEvent*)theEvent
{
    mouseDown = YES;
    [self performSelector:@selector(longMouseDown) withObject: nil afterDelay: 0.5];
}


- (void)mouseUp:(NSEvent *)theEvent
{
    if (mouseDown) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        mouseDown = NO;
        [self performClick:self];
    }
    [super mouseUp:theEvent];
}


- (void)longMouseDown
{
    if (mouseDown) {
        mouseDown = NO;
        [self rightMouseDown:nil];
    }
    
}


- (void)rightMouseDown: (NSEvent*) theEvent
{
    if (self.SEBDockMenuPopover)
    {
        [self.labelPopover close];
        [self.SEBDockMenuPopover showRelativeToRect:[self bounds] ofView:self preferredEdge:NSMaxYEdge];
        [self.dockMenuDropDownButton runPopUp:nil];
    }
}


- (void)menuDidClose:(NSMenu *)menu
{
    [self.SEBDockMenuPopover close];
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
[self createTrackingArea];

}


- (void)mouseEntered:(NSEvent *)theEvent
{
    [self.labelPopover showRelativeToRect:[self bounds] ofView:self preferredEdge:NSMaxYEdge];
}


- (void)mouseExited:(NSEvent *)theEvent
{
    [self.labelPopover close];
}


- (void)updateTrackingAreas
{
    [self removeTrackingArea:trackingArea];
    [self createTrackingArea];
    [super updateTrackingAreas]; // Needed, according to the NSView documentation
}


- (void) createTrackingArea
{
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways);
    trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:trackingArea];
    
    NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
    mouseLocation = [self convertPoint: mouseLocation
                              fromView: nil];
    
    if (NSPointInRect(mouseLocation, [self bounds])) {
            [self mouseEntered: nil];
        } else {
            [self mouseExited: nil];
        }
}
    
@end
