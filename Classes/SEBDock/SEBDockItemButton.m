//
//  SEBDockItem.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/09/14.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBDockItemButton.h"

@implementation SEBDockItemButton


- (id) initWithFrame:(NSRect)frameRect icon:(NSImage *)itemIcon highlightedIcon:(NSImage *)itemHighlightedIcon title:(NSString *)itemTitle menu:(SEBDockItemMenu *)itemMenu
 {
    self = [super initWithFrame:frameRect];
    if (self) {
        mouseDown = NO;
        
        // Get image size
        CGFloat iconSize = self.frame.size.width;
        
        [itemIcon setSize: NSMakeSize(iconSize, iconSize)];
        _defaultImage = itemIcon;

//        if (@available(macOS 10.14, *)) {
//        } else {
//            [itemHighlightedIcon setSize:NSMakeSize(iconSize, iconSize)];
//            _highlightedImage = itemHighlightedIcon;
//        }
        
        self.image = _defaultImage;
        
        [self setButtonType:NSMomentaryPushInButton];
//        [self setButtonType:NSMomentaryLightButton];
//        [self setButtonType:NSMomentaryChangeButton];
        [self setImagePosition:NSImageOnly];
        [self setBordered:NO];
        NSButtonCell *newDockItemButtonCell = self.cell;
        newDockItemButtonCell.highlightsBy = NSChangeGrayCellMask; //NSCellLightsByGray;
        if (@available(macOS 10.14, *)) {
            newDockItemButtonCell.backgroundColor = [NSColor clearColor];
//        } else {
//            newDockItemButtonCell.highlightsBy = NSContentsCellMask; //NSCellLightsByContents;
        }
        // Create text label for dock item, if there was a title set for the item
        if (itemTitle) {
            NSRect frameRect = NSMakeRect(0,0,155,21); // This will change based on the size you need
            self.label = [[NSTextField alloc] initWithFrame:frameRect];
            if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8) {
                // We use white text color only when we have NSPopoverAppearanceHUD, so for OS X <= 10.8
                [self.label setTextColor:[NSColor whiteColor]];
                [self.label setFont:[NSFont systemFontOfSize:14]];
            } else if (floor(NSAppKitVersionNumber) == NSAppKitVersionNumber10_9) {
                // We use white text color only when we have NSPopoverAppearanceHUD, so for OS X == 10.9
                [self.label setTextColor:[NSColor whiteColor]];
                [self.label setFont:[NSFont boldSystemFontOfSize:14]];
            } else {
                [self.label setTextColor:[NSColor darkGrayColor]];
                [self.label setFont:[NSFont systemFontOfSize:14]];
            }
            self.label.bezeled = NO;
            self.label.editable = NO;
            self.label.drawsBackground = NO;
            [self.label.cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
            self.label.stringValue = itemTitle;
            NSSize dockItemLabelSize = [self.label intrinsicContentSize];
            [self.label setAlignment:NSCenterTextAlignment];
            CGFloat dockItemLabelWidth = dockItemLabelSize.width;
            CGFloat dockItemLabelHeight = dockItemLabelSize.height;
            CGFloat dockItemLabelYOffset;
            if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_9) {
                dockItemLabelWidth += 14;
                dockItemLabelHeight += 3;
                dockItemLabelYOffset = 0;
            } else {
                dockItemLabelWidth += 26;
                dockItemLabelHeight += 9;
                dockItemLabelYOffset = -3;
            }
            if (dockItemLabelWidth > 610) {
                dockItemLabelWidth = 610;
            }
            [self.label setFrameSize:NSMakeSize(dockItemLabelWidth, dockItemLabelHeight)];
            [self.label setFrameOrigin:NSMakePoint(0, dockItemLabelYOffset)];
            
            // Create view to place label into
            NSView *dockItemLabelView = [[NSView alloc] initWithFrame:self.label.frame];
            [dockItemLabelView addSubview:self.label];
            [dockItemLabelView setContentHuggingPriority:NSLayoutPriorityFittingSizeCompression-1.0 forOrientation:NSLayoutConstraintOrientationVertical];
            
            // Create a view controller for the label view
            NSViewController *controller = [[NSViewController alloc] init];
            controller.view = dockItemLabelView;
            
            // Create the label popover
            NSPopover *popover = [[NSPopover alloc] init];
            DDLogDebug(@"Dock Item Label View frame size: %f, %f at origin: %f, %f", dockItemLabelView.frame.size.width, dockItemLabelView.frame.size.height, dockItemLabelView.frame.origin.x, dockItemLabelView.frame.origin.y);
            [popover setContentSize:dockItemLabelView.frame.size];
            DDLogDebug(@"Dock Item Label Popover content size: %f, %f", popover.contentSize.width, popover.contentSize.height);
            // Add the label view controller as content view controller to the popover
            [popover setContentViewController:controller];
            [popover setAnimates:NO];
            self.labelPopover = popover;
        }
        
        if (itemMenu) {
            self.dockMenu = itemMenu;
            itemMenu.dockItemButton = self;
        }
    }
    return self;
}


- (void)mouseDown:(NSEvent*)theEvent
{
    mouseDown = YES;

    self.highlighted = true;
//    if (@available(macOS 10.14, *)) {
        self.alphaValue = 0.5;
//    } else {
//        self.image = _highlightedImage;
//    }
    
    [self performSelector:@selector(longMouseDown) withObject: nil afterDelay: 0.5];
}


- (void)mouseUp:(NSEvent *)theEvent
{
    if (mouseDown) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        mouseDown = NO;
        [self performClick:self];
    }
//    if (@available(macOS 10.14, *)) {
        self.alphaValue = 1;
//    } else {
//        self.image = _defaultImage;
//    }
    self.highlighted = false;

    [super mouseUp:theEvent];
}


- (void)longMouseDown
{
    if (mouseDown) {
        mouseDown = NO;
        [self rightMouseDown:[NSEvent new]];
    }
    
}


- (void)rightMouseDown:(NSEvent*)theEvent
{
    self.highlighted = true;
//    if (@available(macOS 10.14, *)) {
        self.alphaValue = 0.5;
//    } else {
//        self.image = _highlightedImage;
//    }
    
    if (self.dockMenu)
    {
        [self.labelPopover close];
        [self.dockMenu showRelativeToRect:[self bounds] ofView:self];
        DDLogDebug(@"Dock menu show relative to rect: %f, %f at origin: %f, %f", self.bounds.size.width, self.bounds.size.height, self.bounds.origin.x, self.bounds.origin.y);

    }
}


// This method is called when the dock item menu is closed
- (void)unhighlight
{
//if (@available(macOS 10.14, *)) {
    self.alphaValue = 1;
//} else {
//    self.image = _defaultImage;
//}
self.highlighted = false;
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
//    if (@available(macOS 10.14, *)) {
        self.alphaValue = 1;
//    } else {
//        self.image = _defaultImage;
//    }
    self.highlighted = false;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
[self createTrackingArea];

}


- (void)mouseEntered:(NSEvent *)theEvent
{
    [self.labelPopover showRelativeToRect:[self bounds] ofView:self preferredEdge:NSMaxYEdge];
    DDLogDebug(@"Dock item label popover show relative to rect: %f, %f at origin: %f, %f", self.bounds.size.width, self.bounds.size.height, self.bounds.origin.x, self.bounds.origin.y);

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


- (void)setHighlighted:(BOOL)highlighted
{
        if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_10) {
            [super setHighlighted:highlighted];
        }
}


@end
