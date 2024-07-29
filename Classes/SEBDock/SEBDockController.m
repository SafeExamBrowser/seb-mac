//
//  SEBDockController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/09/14.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
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
        DDLogDebug(@"[SEBDockController init]");
        // Get dock height
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        CGFloat dockHeight = [preferences secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
        // Enforce minimum SEB Dock height
        if (dockHeight < SEBDefaultDockHeight) dockHeight = SEBDefaultDockHeight;

        NSRect initialContentRect = NSMakeRect(0, 0, 1024, dockHeight);
        self.dockWindow = [[SEBDockWindow alloc] initWithContentRect:initialContentRect styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:YES];
        self.dockWindow.releasedWhenClosed = YES;
        self.dockWindow.autorecalculatesKeyViewLoop = YES;
        self.dockWindow.collectionBehavior = NSWindowCollectionBehaviorStationary + NSWindowCollectionBehaviorFullScreenAuxiliary +NSWindowCollectionBehaviorFullScreenDisallowsTiling;
        if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_allowWindowCapture"] == NO) {
            [self.dockWindow setSharingType:NSWindowSharingNone];
        }
        self.dockWindow.height = dockHeight;
        
        NSView *superview = [self.dockWindow contentView];
        SEBDockView *dockView = [[SEBDockView alloc] initWithFrame:initialContentRect];
        [dockView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [dockView setTranslatesAutoresizingMaskIntoConstraints:YES];
        [superview addSubview:dockView];
        
        // Calculate icon sizes and padding according to dock height
        verticalPadding = dockHeight / 10;
        horizontalPadding = (verticalPadding < 10) ? 10 : verticalPadding;
        iconSize = dockHeight - 2 * verticalPadding;
        
        self.window = self.dockWindow;
        [self.window setLevel:NSMainMenuWindowLevel+6];
        [self.window setAcceptsMouseMovedEvents:YES];
        NSString *dockTitle = [NSString stringWithFormat:NSLocalizedString(@"%@ Dock", @""), SEBShortAppName];
        self.window.contentView.accessibilityLabel = dockTitle;
    }
    return self;
}


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (void)windowDidBecomeKey:(NSNotification *)notification
{
    DDLogDebug(@"Dock did become key");
}


- (void)windowDidResignKey:(NSNotification *)notification
{
    DDLogDebug(@"Dock did resign key");
    
}


- (void) lastDockItemResignedFirstResponder
{
    [self.dockButtonDelegate lastDockItemResignedFirstResponder];
}

- (void) firstDockItemResignedFirstResponder
{
    [self.dockButtonDelegate firstDockItemResignedFirstResponder];
}

- (id)currentDockAccessibilityParent {
    return [self.dockButtonDelegate currentDockAccessibilityParent];
}


// Add dock items passed in array pinned to the left edge of the dock (from left to right)
- (NSArray *) setLeftItems:(NSArray *)newLeftDockItems
{
    DDLogDebug(@"[SEBDockController setLeftItems: %@]", newLeftDockItems);
    
    isLeftmostItemButton = YES;
    NSMutableArray *dockItemButtons = [NSMutableArray new];
    if (newLeftDockItems) {
        NSView *superview = [self.dockWindow contentView];
        NSView *previousDockItemView;
        
        NSView *dockItemView;
        
        for (id<SEBDockItem> dockItem in newLeftDockItems) {
            if (dockItem.icon) {
                SEBDockItemButton *newDockItemButton =
                [[SEBDockItemButton alloc] initWithFrame:NSMakeRect(0, 0, iconSize, iconSize)
                                                    icon:dockItem.icon
                                         highlightedIcon:dockItem.highlightedIcon
                                                   title:dockItem.title
                                                    menu:dockItem.menu];
                if (isLeftmostItemButton) {
                    newDockItemButton.isFirstDockItem = YES;
                    isLeftmostItemButton = NO;
                }
                // If the new dock item declares an action, then link this to the dock icon button
                if ([dockItem respondsToSelector:@selector(action)]) {
                    [newDockItemButton setTarget:dockItem.target];
                    [newDockItemButton setAction:dockItem.action];
                    [newDockItemButton setSecondaryAction:dockItem.secondaryAction];
                }
                [newDockItemButton setToolTip:dockItem.toolTip];
                newDockItemButton.delegate = self;
                dockItemView = newDockItemButton;
                [dockItemButtons addObject:newDockItemButton];
            } else {
                if ([dockItem respondsToSelector:@selector(view)]) {
                    dockItemView = dockItem.view;
                } else {
                    dockItemView = nil;
                }
            }
            [dockItemView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [superview addSubview: dockItemView];
            
            NSMutableArray *constraints = [NSMutableArray new];
            if (dockItemView) {
                [constraints addObject:[NSLayoutConstraint constraintWithItem:dockItemView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:dockItemView.superview
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0]];
                
                if (previousDockItemView) {
                    [constraints addObject:[NSLayoutConstraint constraintWithItem:previousDockItemView
                                                                        attribute:NSLayoutAttributeRight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:dockItemView
                                                                        attribute:NSLayoutAttributeLeft
                                                                       multiplier:1.0
                                                                         constant:-8.0]];
                } else {
                    [constraints addObject:[NSLayoutConstraint constraintWithItem:dockItemView.superview
                                                                        attribute:NSLayoutAttributeLeft
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:dockItemView
                                                                        attribute:NSLayoutAttributeLeft
                                                                       multiplier:1.0
                                                                         constant:-8.0]];
                }
                
                previousDockItemView = dockItemView;
                
                if (constraints.count > 0) {
                    [dockItemView.superview addConstraints:constraints];
                }
            }
        }
        // Save the last (= right most) left item
        self.rightMostLeftItemView = dockItemView;
    }
    return [dockItemButtons copy];
}


// Add dock items passed in array pinned to the right edge of the left items dock area
- (NSArray *) setCenterItems:(NSArray *)newCenterDockItems
{
    DDLogDebug(@"[SEBDockController setCenterItems: %@]", newCenterDockItems);
    
    NSMutableArray *dockItemButtons = [NSMutableArray new];
    if (newCenterDockItems) {
        NSView *superview = [self.dockWindow contentView];
        NSView *previousDockItemView;
        
        for (id<SEBDockItem> dockItem in newCenterDockItems) {
            NSView *dockItemView;
            if (dockItem.icon) {
                SEBDockItemButton *newDockItemButton =
                [[SEBDockItemButton alloc] initWithFrame:NSMakeRect(0, 0, iconSize, iconSize)
                                                    icon:dockItem.icon
                                         highlightedIcon:dockItem.highlightedIcon
                                                   title:dockItem.title
                                                    menu:dockItem.menu];
                newDockItemButton.bundleID = dockItem.bundleID;
                newDockItemButton.allowManualStart = dockItem.allowManualStart;
                if (isLeftmostItemButton) {
                    newDockItemButton.isFirstDockItem = YES;
                    isLeftmostItemButton = NO;
                }
                // If the new dock item declares an action, then link this to the dock icon button
                if ([dockItem respondsToSelector:@selector(action)]) {
                    [newDockItemButton setTarget:dockItem.target];
                    [newDockItemButton setAction:dockItem.action];
                    [newDockItemButton setSecondaryAction:dockItem.secondaryAction];
                }
                [newDockItemButton setToolTip:dockItem.toolTip];
                newDockItemButton.delegate = self;
                dockItemView = newDockItemButton;
                [dockItemButtons addObject:newDockItemButton];
            } else {
                if ([dockItem respondsToSelector:@selector(view)]) {
                    dockItemView = dockItem.view;
                } else {
                    dockItemView = nil;
                }
            }
            [dockItemView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [superview addSubview: dockItemView];
            
            NSMutableArray *constraints = [NSMutableArray new];
            if (dockItemView) {
                [constraints addObject:[NSLayoutConstraint constraintWithItem:dockItemView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:superview
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0]];
                
                if (previousDockItemView) {
                    [constraints addObject:[NSLayoutConstraint constraintWithItem:previousDockItemView
                                                                        attribute:NSLayoutAttributeRight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:dockItemView
                                                                        attribute:NSLayoutAttributeLeft
                                                                       multiplier:1.0
                                                                         constant:-8.0]];
                } else {
                    if (self.rightMostLeftItemView) {
                        [constraints addObject:[NSLayoutConstraint constraintWithItem:self.rightMostLeftItemView
                                                                            attribute:NSLayoutAttributeRight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:dockItemView
                                                                            attribute:NSLayoutAttributeLeft
                                                                           multiplier:1.0
                                                                             constant:-8.0]];
                    } else {
                        [constraints addObject:[NSLayoutConstraint constraintWithItem:superview
                                                                            attribute:NSLayoutAttributeLeft
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:dockItemView
                                                                            attribute:NSLayoutAttributeLeft
                                                                           multiplier:1.0
                                                                             constant:-8.0]];
                    }
                }
                
                previousDockItemView = dockItemView;
                
                if (constraints.count > 0) {
                    [dockItemView.superview addConstraints:constraints];
                }
            }
        }
    }
    return [dockItemButtons copy];
}


// Add dock items passed in array pinned to the right edge of the dock (from right to left)
- (NSArray *) setRightItems:(NSArray *)newRightDockItems
{
    DDLogDebug(@"[SEBDockController setRightItems: %@]", newRightDockItems);
    
    NSMutableArray *dockItemButtons = [NSMutableArray new];
    if (newRightDockItems) {
        NSView *superview = [self.dockWindow contentView];
        NSView *previousDockItemView;
        BOOL rightmostItemButton = YES;
        
        for (id<SEBDockItem> dockItem in newRightDockItems) {
            NSView *dockItemView;
            if (dockItem.icon) {
                SEBDockItemButton *newDockItemButton =
                [[SEBDockItemButton alloc] initWithFrame:NSMakeRect(0, 0, iconSize, iconSize)
                                                    icon:dockItem.icon
                                         highlightedIcon:dockItem.highlightedIcon
                                                   title:dockItem.title
                                                    menu:dockItem.menu];
                if (isLeftmostItemButton) {
                    newDockItemButton.isFirstDockItem = YES;
                    isLeftmostItemButton = NO;
                } else if (rightmostItemButton) {
                    newDockItemButton.isLastDockItem = YES;
                    rightmostItemButton = NO;
                }
                // If the new dock item declares an action, then link this to the dock icon button
                if ([dockItem respondsToSelector:@selector(action)]) {
                    [newDockItemButton setTarget:dockItem.target];
                    [newDockItemButton setAction:dockItem.action];
                    [newDockItemButton setSecondaryAction:dockItem.secondaryAction];
                    [newDockItemButton setButtonType:NSMomentaryLightButton];
                }
                [newDockItemButton setToolTip:dockItem.toolTip];
                newDockItemButton.delegate = self;
                dockItemView = newDockItemButton;
                [dockItemButtons addObject:newDockItemButton];
            } else {
                if ([dockItem respondsToSelector:@selector(view)]) {
                    dockItemView = dockItem.view;
                } else {
                    dockItemView = nil;
                }
            }
            [dockItemView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [superview addSubview: dockItemView];
            
            NSMutableArray *constraints = [NSMutableArray new];
            if (dockItemView) {
                [constraints addObject:[NSLayoutConstraint constraintWithItem:dockItemView
                                                                    attribute:NSLayoutAttributeCenterY
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:dockItemView.superview
                                                                    attribute:NSLayoutAttributeCenterY
                                                                   multiplier:1.0
                                                                     constant:0.0]];
                
                if (previousDockItemView) {
                    [constraints addObject:[NSLayoutConstraint constraintWithItem:previousDockItemView
                                                                        attribute:NSLayoutAttributeLeft
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:dockItemView
                                                                        attribute:NSLayoutAttributeRight
                                                                       multiplier:1.0
                                                                         constant:8.0]];
                } else {
                    [constraints addObject:[NSLayoutConstraint constraintWithItem:dockItemView.superview
                                                                        attribute:NSLayoutAttributeRight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:dockItemView
                                                                        attribute:NSLayoutAttributeRight
                                                                       multiplier:1.0
                                                                         constant:8.0]];
                }
                
                previousDockItemView = dockItemView;
                
                if (constraints.count > 0) {
                    [dockItemView.superview addConstraints:constraints];
                }
            }
        }
    }
    return [dockItemButtons copy];
}


- (void) showDockOnScreen:(NSScreen *)screen
{
    DDLogDebug(@"[SEBDockController showDock]");
    [self.dockWindow setCalculatedFrame:screen];
    
    [self.window recalculateKeyViewLoop];
    
    [self showWindow:self];
}


- (void) activateDockFirstControl:(BOOL)firstControl
{
    [self.window makeKeyAndOrderFront:self];
    if (firstControl) {
        [self makeFirstDockItemFirstResponder];
    } else {
        [self makeLastDockItemFirstResponder];
    }
}


- (void) makeFirstDockItemFirstResponder
{
    DDLogDebug(@"[SEBDockController makeFirstDockItemFirstResponder]");
    [self makeDockItemFirstResponderFirst:YES];
}


- (void) makeLastDockItemFirstResponder
{
    DDLogDebug(@"[SEBDockController makeLastDockItemFirstResponder]");
    [self makeDockItemFirstResponderFirst:NO];
}


- (void) makeDockItemFirstResponderFirst:(BOOL)firstItem
{
    DDLogDebug(@"[SEBDockController makeDockItemFirstResponder]");
    
    NSArray *dockItems = self.dockWindow.contentView.subviews;
    SEBDockItemButton *dockItemToMakeFirstResponder = nil;
    for (SEBDockItemButton *dockItem in dockItems) {
        if (dockItem.class == SEBDockItemButton.class) {
            if (firstItem) {
                if (dockItem.isFirstDockItem) {
                    dockItemToMakeFirstResponder = dockItem;
                    break;
                }
            } else {
                if (dockItem.isLastDockItem) {
                    dockItemToMakeFirstResponder = dockItem;
                    break;
                }
            }
        }
    }
    if (dockItemToMakeFirstResponder) {
        [self.window makeFirstResponder:dockItemToMakeFirstResponder];
        
//        id windowElement =  NSAccessibilityUnignoredDescendant(NSApp.mainWindow);
//        NSArray *windowElements = [windowElement accessibilityAttributeValue:NSAccessibilityChildrenAttribute];
//        DDLogDebug(@"NSAccessibilityUnignoredDescendant NSAccessibilityChildren: %@", windowElements);

//        NSApp.mainWindow.accessibilityFocusedWindow = self.window;
//        self.window.contentView.accessibilityFocused = YES;
//        dockItemToMakeFirstResponder.accessibilityFocused = YES;
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSDictionary *userInfo = @{
//                NSAccessibilityUIElementsKey: @[self.window, dockItemToMakeFirstResponder],
//                NSAccessibilityFocusedWindowAttribute: self.window
//            };
//            NSAccessibilityPostNotificationWithUserInfo(NSApp.mainWindow, NSAccessibilityFocusedUIElementChangedNotification, userInfo);
//        });
    }
}


- (void) hideDock
{
    DDLogDebug(@"[SEBDockController hideDock]");
    [self.window close];
}


- (void) adjustDock
{
    DDLogDebug(@"[SEBDockController adjustDock]");
    [self.dockWindow setCalculatedFrame:self.window.screen];
}


- (void) moveDockToScreen:(NSScreen *)screen
{
    DDLogDebug(@"[SEBDockController moveDockToScreen: %@]", screen);
    [self.dockWindow setCalculatedFrame:screen];
}


@end
