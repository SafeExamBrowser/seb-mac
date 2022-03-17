//
//  SEBDockItemMenu.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 13/10/14.
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

#import "SEBDockItemMenu.h"

@implementation SEBDockItemMenu


- (instancetype)initWithTitle:(NSString *)aTitle
{
    self = [super initWithTitle:aTitle];
    if (self) {
        // Add an empty NSMenuItem necessary for showing the menu as a popup
        [self addItemWithTitle:@"" action:nil keyEquivalent:@""];

        // Create view controller with view to place the menu into
        [self setDelegate:self];
        NSSize dockMenuSize = [self size];
        NSView *dockMenuView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, dockMenuSize.width, dockMenuSize.height)];
        self.dockMenuView = dockMenuView;
        NSViewController *controller = [[NSViewController alloc] init];
        controller.view = dockMenuView;
        
        // Create drop down button which is needed to anchor and display the NSMenu
        DropDownButton *dockMenuDropDownButton = [[DropDownButton alloc] initWithFrame:NSMakeRect(-4, 38, 0, 0)];
        self.dockMenuDropDownButton = dockMenuDropDownButton;
        [dockMenuDropDownButton setMenu:self];
        [dockMenuView addSubview:dockMenuDropDownButton];
        
        // Create menu popover to place the menu into
        NSPopover *popover = [[NSPopover alloc] init];
        self.dockMenuPopover = popover;
        [popover setContentSize:dockMenuView.frame.size];
        [popover setContentViewController:controller];
        [popover setAnimates:NO];
    }
    return self;
}


- (void) insertItem:(NSMenuItem *)newItem
           atIndex:(NSInteger)index
{
    [super insertItem:newItem atIndex:index];
    [self setPopoverMenuSize];
    
}


- (void) removeItemAtIndex:(NSInteger)index
{
    [super removeItemAtIndex:index];
    [self setPopoverMenuSize];
}


- (void) menuDidClose:(NSMenu *)menu
{
    [self.dockMenuPopover close];
    [_dockItemButton unhighlight];
}


- (void) showRelativeToRect:(NSRect)positioningRect
                    ofView:(NSView *)positioningView
{
//    [self.dockMenuPopover showRelativeToRect:positioningRect ofView:positioningView preferredEdge:NSMaxYEdge];
    [self.dockMenuPopover showRelativeToRect:NSZeroRect ofView:positioningView preferredEdge:NSMaxYEdge];
    [self.dockMenuDropDownButton runPopUp:nil];
}


// Adjusts size of the NSPopover containing the dock item NSMenu.
// This method needs to be called after changing the title of a NSMenuItem contained in the dock item menu.
- (void) setPopoverMenuSize
{
    NSSize SEBDockMenuSize = [self size];
    DDLogVerbose(@"setPopoverMenuSize – SEBDockItemMenu size: %f, %f", SEBDockMenuSize.width, SEBDockMenuSize.height);
    NSUInteger numberOfItems = self.numberOfItems;
    NSRect newMenuViewFrame = NSMakeRect(0, 0, SEBDockMenuSize.width, SEBDockMenuSize.height - (numberOfItems == 2 ? 3 : numberOfItems));
    NSRect currentMenuViewFrame = self.dockMenuView.frame;
    
    // Set the drop down button position and menu view and popover size only when the frame changed
    if (!(newMenuViewFrame.size.width == currentMenuViewFrame.size.width && newMenuViewFrame.size.height == currentMenuViewFrame.size.height))
    {
        NSView *sizingMenuItemView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, SEBDockMenuSize.width, 0)];
        [[self itemAtIndex:0] setView:sizingMenuItemView];
        [self.dockMenuView setFrame:newMenuViewFrame];
        [self.dockMenuPopover setContentSize:newMenuViewFrame.size];
        
        if (numberOfItems == 2) {
            [self.dockMenuDropDownButton setFrame:NSMakeRect(-4, 38, 0, 0)];
        } else {
            [self.dockMenuDropDownButton setFrame:NSMakeRect(-4, 14, 0, 0)];
        }
    }
}

@end
