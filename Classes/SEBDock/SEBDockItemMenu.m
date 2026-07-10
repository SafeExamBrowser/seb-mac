//
//  SEBDockItemMenu.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 13/10/14.
//  Copyright (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 2.0 (the "License"); you may not use this file except in
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
//  (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBDockItemMenu.h"
#include <Carbon/Carbon.h>


// Flipped content view for the popover so rows can be laid out top-to-bottom by a
// fixed offset from the top, independent of the view's actual height (which the
// popover may set differently on repeated shows).
@interface SEBDockMenuContentView : NSView
@end

@implementation SEBDockMenuContentView
- (BOOL)isFlipped { return YES; }
@end


@class SEBDockItemMenu;

// A single interactive row in the dock item popover menu: a check mark column (for
// the active window), an optional icon and the title. Highlights on hover and on
// keyboard focus, invokes a selection handler on click / Return / Space, supports
// arrow-key and Tab navigation, and exposes itself to VoiceOver as a button.
// Because the popover is both the visible menu and what screen proctoring captures
// (no native NSMenu is overlaid), what the user sees and what appears in the
// composited screen shot are identical.
@interface SEBDockMenuItemView : NSView
@property (nonatomic, weak, readonly) NSMenuItem *menuItem;
- (instancetype)initWithMenuItem:(NSMenuItem *)menuItem
                       rowHeight:(CGFloat)rowHeight
                           width:(CGFloat)width
                            font:(NSFont *)font
                       ownerMenu:(SEBDockItemMenu *)ownerMenu
                selectionHandler:(void (^)(NSMenuItem *item))selectionHandler;
@end

@interface SEBDockMenuItemView ()
@property (nonatomic, weak, readwrite) NSMenuItem *menuItem;
@property (nonatomic, weak) SEBDockItemMenu *ownerMenu;
@property (nonatomic, copy) void (^selectionHandler)(NSMenuItem *item);
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, assign, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, strong) NSTrackingArea *rowTrackingArea;
@end


// Row-callback methods implemented by SEBDockItemMenu, declared here so the row view
// can call them (the full SEBDockItemMenu implementation is later in this file).
@interface SEBDockItemMenu (SEBDockMenuItemRowActions)
- (void)focusRowRelativeToRow:(SEBDockMenuItemView *)row byDelta:(NSInteger)delta wrap:(BOOL)wrap;
- (void)closeMenuPopover;
@end


@implementation SEBDockMenuItemView

- (instancetype)initWithMenuItem:(NSMenuItem *)menuItem
                       rowHeight:(CGFloat)rowHeight
                           width:(CGFloat)width
                            font:(NSFont *)font
                       ownerMenu:(SEBDockItemMenu *)ownerMenu
                selectionHandler:(void (^)(NSMenuItem *))selectionHandler
{
    self = [super initWithFrame:NSMakeRect(0, 0, width, rowHeight)];
    if (self) {
        _menuItem = menuItem;
        _ownerMenu = ownerMenu;
        _selectionHandler = selectionHandler;

        CGFloat checkmarkWidth = 18;
        CGFloat iconSize = MIN(16, rowHeight - 4);
        CGFloat iconTitleGap = 5;
        CGFloat trailingInset = 12;
        CGFloat x = 4;

        NSTextField *checkmark = [NSTextField labelWithString:(menuItem.state == NSControlStateValueOn ? @"✓" : @"")];
        checkmark.font = font;
        checkmark.textColor = NSColor.labelColor;
        checkmark.alignment = NSTextAlignmentCenter;
        CGFloat checkmarkHeight = checkmark.fittingSize.height;
        checkmark.frame = NSMakeRect(x, (rowHeight - checkmarkHeight) / 2.0, checkmarkWidth, checkmarkHeight);
        checkmark.accessibilityElement = NO;
        [self addSubview:checkmark];
        x += checkmarkWidth;

        if (menuItem.image) {
            NSImageView *iconView = [NSImageView imageViewWithImage:menuItem.image];
            iconView.imageScaling = NSImageScaleProportionallyUpOrDown;
            iconView.frame = NSMakeRect(x, (rowHeight - iconSize) / 2.0, iconSize, iconSize);
            iconView.accessibilityElement = NO;
            [self addSubview:iconView];
            x += iconSize + iconTitleGap;
        }

        NSTextField *title = [NSTextField labelWithString:(menuItem.title ?: @"")];
        title.font = font;
        title.textColor = NSColor.labelColor;
        title.lineBreakMode = NSLineBreakByTruncatingTail;
        CGFloat titleHeight = title.fittingSize.height;
        title.frame = NSMakeRect(x, (rowHeight - titleHeight) / 2.0, MAX(0, width - x - trailingInset), titleHeight);
        title.accessibilityElement = NO;
        [self addSubview:title];
        _titleLabel = title;

        // Accessibility: expose the row as a single button element with a label
        // describing the window (and whether it is the current one), so VoiceOver can
        // navigate the list and activate a row.
        self.accessibilityElement = YES;
        self.accessibilityRole = NSAccessibilityButtonRole;
        NSString *accessibilityLabel = (menuItem.title ?: @"");
        if (menuItem.state == NSControlStateValueOn) {
            accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@, current window", @"Accessibility label for the active window in the SEB Dock open windows menu"), accessibilityLabel];
        }
        self.accessibilityLabel = accessibilityLabel;
    }
    return self;
}

- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)canBecomeKeyView { return YES; }

- (BOOL)becomeFirstResponder
{
    self.highlighted = YES;
    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    self.highlighted = NO;
    return [super resignFirstResponder];
}

- (void)updateTrackingAreas
{
    [super updateTrackingAreas];
    if (self.rowTrackingArea) {
        [self removeTrackingArea:self.rowTrackingArea];
    }
    self.rowTrackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                        options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect)
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:self.rowTrackingArea];
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (_highlighted == highlighted) {
        return;
    }
    _highlighted = highlighted;
    self.titleLabel.textColor = highlighted ? NSColor.selectedMenuItemTextColor : NSColor.labelColor;
    self.needsDisplay = YES;
}

- (void)mouseEntered:(NSEvent *)event
{
    // Move keyboard focus to the hovered row so there is always exactly one
    // highlighted row: the highlight follows the first responder, for both mouse
    // and keyboard navigation.
    [self.window makeFirstResponder:self];
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (self.highlighted) {
        [[NSColor selectedContentBackgroundColor] setFill];
        NSRectFill(self.bounds);
    }
}

- (void)mouseUp:(NSEvent *)event
{
    [self triggerSelection];
}

- (void)triggerSelection
{
    if (self.selectionHandler) {
        self.selectionHandler(self.menuItem);
    }
}

#pragma mark - Keyboard navigation

- (void)keyDown:(NSEvent *)event
{
    // Space activates the row; other keys go through the standard interpretation
    // (arrows -> moveUp:/moveDown:, Return -> insertNewline:, Esc -> cancelOperation:).
    if ([event.charactersIgnoringModifiers isEqualToString:@" "]) {
        [self triggerSelection];
        return;
    }
    [self interpretKeyEvents:@[event]];
}

- (void)moveUp:(id)sender { [self.ownerMenu focusRowRelativeToRow:self byDelta:-1 wrap:NO]; }
- (void)moveDown:(id)sender { [self.ownerMenu focusRowRelativeToRow:self byDelta:1 wrap:NO]; }
// Tab / Shift-Tab navigate the rows too (the NSStackView's custom views aren't picked
// up by the window key-view loop), wrapping around for accessibility.
- (void)insertTab:(id)sender { [self.ownerMenu focusRowRelativeToRow:self byDelta:1 wrap:YES]; }
- (void)insertBacktab:(id)sender { [self.ownerMenu focusRowRelativeToRow:self byDelta:-1 wrap:YES]; }
- (void)insertNewline:(id)sender { [self triggerSelection]; }
- (void)insertLineBreak:(id)sender { [self triggerSelection]; }
- (void)cancelOperation:(id)sender { [self.ownerMenu closeMenuPopover]; }

#pragma mark - Accessibility

- (BOOL)accessibilityPerformPress
{
    [self triggerSelection];
    return YES;
}

@end


@interface SEBDockItemMenu () <NSPopoverDelegate>
// The interactive row views currently shown in the popover (one per menu item).
// The popover is both the visible menu AND what screen proctoring captures: no
// native NSMenu is overlaid on top of it, so the composited screen shot matches
// exactly what the user sees, with no misaligned overlay.
@property (strong) NSMutableArray<SEBDockMenuItemView *> *menuItemRows;
@property (strong) NSStackView *menuRowsStackView;
@end

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
        NSView *dockMenuView = [[SEBDockMenuContentView alloc] initWithFrame:NSMakeRect(0, 0, dockMenuSize.width, dockMenuSize.height)];
        self.dockMenuView = dockMenuView;
        NSViewController *controller = [[NSViewController alloc] init];
        controller.view = dockMenuView;

        // Create drop down button which is needed to anchor and display the NSMenu
        DropDownButton *dockMenuDropDownButton = [[DropDownButton alloc] initWithFrame:NSMakeRect(-4, 38, 0, 0)];
        self.dockMenuDropDownButton = dockMenuDropDownButton;
        [dockMenuDropDownButton setMenu:self];
        [dockMenuView addSubview:dockMenuDropDownButton];
        
        // Create menu popover to place the menu into. The popover itself is the
        // interactive menu (see buildMenuRows); we no longer overlay a native NSMenu
        // on top of it, so it renders identically on screen and in the screen
        // proctoring composite (which captures the popover window).
        NSPopover *popover = [[NSPopover alloc] init];
        self.dockMenuPopover = popover;
        [popover setContentSize:dockMenuView.frame.size];
        [popover setContentViewController:controller];
        [popover setAnimates:NO];
        popover.behavior = NSPopoverBehaviorTransient;
        popover.delegate = self;

        self.menuItemRows = [NSMutableArray array];
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


- (void) showRelativeToRect:(NSRect)positioningRect
                    ofView:(NSView *)positioningView
{
    [self buildMenuRows];
    [self.dockMenuPopover showRelativeToRect:NSZeroRect ofView:positioningView preferredEdge:NSMaxYEdge];

    // Enable keyboard / Tab navigation and move focus (and the VoiceOver cursor) to
    // the current window's row, or the first row. Deferred to the next run loop cycle
    // so the popover's window exists and has finished presenting; we also make that
    // window key so it actually receives key events.
    dispatch_async(dispatch_get_main_queue(), ^{
        NSWindow *popoverWindow = self.dockMenuView.window;
        if (!popoverWindow) {
            return;
        }
        popoverWindow.autorecalculatesKeyViewLoop = YES;
        [popoverWindow makeKeyWindow];
        SEBDockMenuItemView *focusRow = [self initialFocusRow];
        if (focusRow) {
            [popoverWindow makeFirstResponder:focusRow];
        }
    });
}


// Builds the interactive rows (check mark for the active window, optional icon and
// title) shown in the popover. The popover is both the visible menu and what screen
// proctoring captures, so there is no separate native menu to align with.
- (void) buildMenuRows
{
    [self.menuRowsStackView removeFromSuperview];
    self.menuRowsStackView = nil;
    [self.menuItemRows removeAllObjects];

    NSFont *menuFont = [NSFont menuFontOfSize:0];
    CGFloat rowHeight = 22;
    CGFloat separatorHeight = 9;
    CGFloat verticalPadding = 5;
    CGFloat checkmarkWidth = 18;
    CGFloat iconColumnWidth = 16 + 5;   // icon + gap
    CGFloat leadingInset = 4;
    CGFloat trailingInset = 16;

    // Collect the displayable entries (window items and separator items) in order,
    // and determine the content width from the widest item title.
    NSMutableArray<NSMenuItem *> *entries = [NSMutableArray array];
    CGFloat maxTitleWidth = 0;
    BOOL anyImage = NO;
    NSDictionary *titleAttributes = @{ NSFontAttributeName: menuFont };
    for (NSMenuItem *item in self.itemArray) {
        if (item.isSeparatorItem) {
            [entries addObject:item];
        } else if (item.action != nil || item.title.length > 0) {
            [entries addObject:item];
            CGFloat titleWidth = [(item.title ?: @"") sizeWithAttributes:titleAttributes].width;
            maxTitleWidth = MAX(maxTitleWidth, titleWidth);
            if (item.image) {
                anyImage = YES;
            }
        }
    }
    // Drop separators with no item above/below them to divide.
    while (entries.firstObject.isSeparatorItem) {
        [entries removeObjectAtIndex:0];
    }
    while (entries.lastObject.isSeparatorItem) {
        [entries removeLastObject];
    }

    CGFloat contentWidth = leadingInset + checkmarkWidth + (anyImage ? iconColumnWidth : 0) + ceil(maxTitleWidth) + trailingInset;
    contentWidth = MAX(160, MIN(contentWidth, 520));

    // Lay the rows out with a vertical stack view pinned to all edges of the content
    // view. The content view's height is then determined by the (fixed-height) rows,
    // so it is identical on every show and the rows always start at the top - manual
    // frame/height math drifted across repeated popover shows.
    NSStackView *stackView = [[NSStackView alloc] initWithFrame:NSZeroRect];
    stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
    stackView.alignment = NSLayoutAttributeLeading;
    stackView.spacing = 0;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;

    __weak SEBDockItemMenu *weakSelf = self;
    CGFloat totalEntriesHeight = 0;
    for (NSMenuItem *item in entries) {
        if (item.isSeparatorItem) {
            NSView *separator = [self separatorRowViewWithWidth:contentWidth height:separatorHeight];
            [stackView addArrangedSubview:separator];
            totalEntriesHeight += separatorHeight;
            continue;
        }
        SEBDockMenuItemView *row = [[SEBDockMenuItemView alloc] initWithMenuItem:item
                                                                       rowHeight:rowHeight
                                                                           width:contentWidth
                                                                            font:menuFont
                                                                       ownerMenu:self
                                                                selectionHandler:^(NSMenuItem *selectedItem) {
            [weakSelf selectMenuItem:selectedItem];
        }];
        row.translatesAutoresizingMaskIntoConstraints = NO;
        [row.heightAnchor constraintEqualToConstant:rowHeight].active = YES;
        [row.widthAnchor constraintEqualToConstant:contentWidth].active = YES;
        [stackView addArrangedSubview:row];
        [self.menuItemRows addObject:row];
        totalEntriesHeight += rowHeight;
    }

    [self.dockMenuView addSubview:stackView];
    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:self.dockMenuView.topAnchor constant:verticalPadding],
        [stackView.bottomAnchor constraintEqualToAnchor:self.dockMenuView.bottomAnchor constant:-verticalPadding],
        [stackView.leadingAnchor constraintEqualToAnchor:self.dockMenuView.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:self.dockMenuView.trailingAnchor],
    ]];
    self.menuRowsStackView = stackView;

    CGFloat contentHeight = totalEntriesHeight + 2 * verticalPadding;
    [self.dockMenuPopover setContentSize:NSMakeSize(contentWidth, contentHeight)];
}


// A separator row: a horizontal divider line inset from the edges, matching the
// separator that the previous native menu drew between the additional browser
// windows and the main/exam window.
- (NSView *) separatorRowViewWithWidth:(CGFloat)width height:(CGFloat)height
{
    NSView *container = [[NSView alloc] initWithFrame:NSZeroRect];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.accessibilityElement = NO;

    NSBox *line = [[NSBox alloc] initWithFrame:NSZeroRect];
    line.boxType = NSBoxSeparator;
    line.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:line];

    [NSLayoutConstraint activateConstraints:@[
        [container.heightAnchor constraintEqualToConstant:height],
        [container.widthAnchor constraintEqualToConstant:width],
        [line.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:8],
        [line.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-8],
        [line.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
    ]];
    return container;
}


- (void) selectMenuItem:(NSMenuItem *)item
{
    [self.dockMenuPopover close];
    if (item.action) {
        // Route to the same target/action the native menu used (openWindowSelected:),
        // resolved through the responder chain when the target is nil.
        [NSApp sendAction:item.action to:item.target from:item];
    }
}


// The row to focus when the menu opens: the current window's row, else the first.
- (SEBDockMenuItemView *) initialFocusRow
{
    for (SEBDockMenuItemView *row in self.menuItemRows) {
        if (row.menuItem.state == NSControlStateValueOn) {
            return row;
        }
    }
    return self.menuItemRows.firstObject;
}


// Moves keyboard focus (and the VoiceOver cursor) to the row delta positions away
// from the given row (separators are not focusable). Arrow keys clamp at the ends;
// Tab / Shift-Tab wrap around.
- (void) focusRowRelativeToRow:(SEBDockMenuItemView *)row byDelta:(NSInteger)delta wrap:(BOOL)wrap
{
    NSUInteger index = [self.menuItemRows indexOfObject:row];
    NSInteger count = (NSInteger)self.menuItemRows.count;
    if (index == NSNotFound || count == 0) {
        return;
    }
    NSInteger newIndex = (NSInteger)index + delta;
    if (wrap) {
        newIndex = ((newIndex % count) + count) % count;
    } else {
        newIndex = MAX(0, MIN(newIndex, count - 1));
    }
    SEBDockMenuItemView *targetRow = self.menuItemRows[(NSUInteger)newIndex];
    [self.dockMenuView.window makeFirstResponder:targetRow];
}


- (void) closeMenuPopover
{
    [self.dockMenuPopover close];
}


#pragma mark - NSPopoverDelegate

- (void) popoverDidClose:(NSNotification *)notification
{
    [self.menuRowsStackView removeFromSuperview];
    self.menuRowsStackView = nil;
    [self.menuItemRows removeAllObjects];
    [_dockItemButton unhighlight];
}


// Called by the browser controller after menu items or their titles change. The
// popover is (re)laid out from the current menu items every time it is shown (see
// buildMenuRows), so we only need to rebuild live if it is currently open.
- (void) setPopoverMenuSize
{
    if (self.dockMenuPopover.isShown) {
        [self buildMenuRows];
    }
}

@end
