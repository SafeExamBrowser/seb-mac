//
//  SEBDockController.h
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

#import <Cocoa/Cocoa.h>
#import "SEBDockWindow.h"
#import "SEBDockItemButton.h"
#import "SEBDockItemMenu.h"


/**
 * @protocol    SEBDockItem
 *
 * @brief       All items to be installed in a SEBDockController-driven SEB Dock bar
 *              must conform to the SEBDockItem protocol. This ensures that
 *              SEBDockController has enough information to accurately populate the
 *              dock.
 */
@protocol SEBDockItem <NSObject>
/**
 * @name		Item Attributes
 */
@required
/**
 * @brief       The title of the dock item.
 * @details     This value will be used for the dock item's label which is displayed
 *              when the mouse pointer is moved over the dock item. If no label
 *              should be displayed, then this property has to be set to nil.
 */
- (NSString *) title;

/**
 * @brief       The icon to be displayed in the dock bar. The NSImage should idealy
 *              provide several resolutions, minimum is 32 and 64 (@2x) pixels.
 *              If the Dock item should not display an icon, then this property
 *              has to be set to nil and the optional property view has to contain
 *              an NSView to be displayed instead.
 */
- (NSImage *) icon;

/**
 * @brief       The icon to be displayed in the dock bar while its button is clicked.
 *              As soon as the button is released, the default icon is displayed again.
 *              If the Dock item should not be highlighted when its button is clicked,
 *              then this property has to be set to nil.
 */
- (NSImage *) highlightedIcon;

/**
 * @brief		A tool tip string which should only be used for items which don't 
 *              have a title defined and therefore don't display a label. 
 *              Has to be set to nil if no tool tip should be displayed.
 */
- (NSString *) toolTip;

/**
 * @brief       A menu which should be displayed when there is a long left mouse
 *              button click or a right mouse button click/ctrl-click/double tap
 *              (contextual menu) detected (similar to the OS X Dock).
 */
- (SEBDockItemMenu *) menu;

@optional

/**
 * @brief       Target for the action to be performed when a mouse click on the
 *              dock item is performed.
 */
- (id) target;

/**
 * @brief       Action to be performed when a mouse click on the dock item is
 *              performed.
 */
- (SEL) action;

/**
 * @brief       Action to be performed when a right or long mouse click on the dock item is
 *              performed.
 */
- (SEL) secondaryAction;

/**
 * @brief       Rectangular view to be displayed instead of an icon (when icon is nil).
 */
- (NSView *) view;

@end

/**
 * @class       SEBDockController
 *
 * @brief       SEBDockController implements a custom control which is designed to be a
 *              mixture of the OS X Dock and a Windows task bar, intended to provide an easy
 *              way of switching between allowed third party applications and resources or
 *              opening them if they are not yet running/open. All items placed in the 
 *              SEB Dock have to be scalable (preferably rectangular), with a minimum size of
 *              32 points (32 or 64 pixels @2x resolution). The SEB Dock bar has a min. 
 *              height of SEBDefaultDockHeight (40 points) and is pinned to the botton of a screen.
 *              The SEB Dock is divided into three sections left, center and right. 
 *              The item(s) in the left section are pinned to the left edge of the dock 
 *              (and screen), the right section items to the right edge of the dock and
 *              the center items start at (are pinned to) the right edge of the left section.
 *              The center section can contain a scroll view so if a large number of 
 *              center items don't fit into the space available for the center section,
 *              users can scroll the center section horizontally to show all items.
 *              Items in the right section are intended to be controls providing functions
 *              and information which should be accessible application wide (like a quit
 *              button, battery and current time/clock, WLAN control etc.).
 *
 * @details     SEBDockController handles the creation and display of the SEB Dock hovering
 *              window as well as switching between different items using the dock bar.
 */
@interface SEBDockController : NSWindowController <SEBDockItemButtonDelegate> {

    @private
    CGFloat horizontalPadding;
    CGFloat verticalPadding;
    CGFloat iconSize;
    BOOL isLeftmostItemButton;
}

@property (strong, nonatomic) SEBDockWindow *dockWindow;

@property (weak, nonatomic) NSArray *leftDockItems;
@property (weak, nonatomic) NSArray *centerDockItems;
@property (weak, nonatomic) NSArray *rightDockItems;
@property (weak, nonatomic) NSView *rightMostLeftItemView;

@property (strong, nonatomic) id<SEBDockItemButtonDelegate> dockButtonDelegate;

- (NSArray *) setLeftItems:(NSArray *)newLeftDockItems;
- (NSArray *) setCenterItems:(NSArray *)newCenterDockItems;
- (NSArray *) setRightItems:(NSArray *)newRightDockItems;

- (void) showDockOnScreen:(NSScreen *)screen;
- (void) activateDockFirstControl:(BOOL)firstControl;
- (void) hideDock;
- (void) adjustDock;
- (void) moveDockToScreen:(NSScreen *)screen;

@end
