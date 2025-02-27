//
//  SEBDockItem.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/09/14.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <Cocoa/Cocoa.h>
#import "DropDownButton.h"
#import "SEBDockItemMenu.h"

@class SEBDockItemMenu;

@protocol SEBDockItemButtonDelegate <NSObject>

- (void) lastDockItemResignedFirstResponder;
- (void) firstDockItemResignedFirstResponder;

- (id) currentDockAccessibilityParent;

@optional
- (NSWindow *)dockWindow;

@end

@interface SEBDockItemButton : NSButton
{
    @private
    
    NSTrackingArea *trackingArea;
    NSPopUpButtonCell *popUpCell;
    
    BOOL mouseDown;
    
    CAShapeLayer *focusRing;
}

@property (strong) NSImage *defaultImage;
@property (strong) NSImage *highlightedImage;
@property (strong) NSTextField *label;
@property (strong) NSPopover *labelPopover;
@property (strong) SEBDockItemMenu *dockMenu;
@property (strong) NSString *bundleID;
@property (readwrite) BOOL allowManualStart;
@property (readwrite) BOOL isFirstDockItem;
@property (readwrite) BOOL isLastDockItem;
@property (assign, nonatomic) SEL secondaryAction;

@property (strong, nonatomic) id<SEBDockItemButtonDelegate> delegate;

- (id) initWithFrame:(NSRect)frameRect icon:(NSImage *)itemIcon highlightedIcon:(NSImage *)itemHighlightedIcon title:(NSString *)itemTitle menu:(SEBDockItemMenu *)itemMenu;
- (id) initWithFrame:(NSRect)frameRect icon:(NSImage *)itemIcon highlightedIcon:(NSImage *)itemHighlightedIcon title:(NSString *)itemTitle menu:(SEBDockItemMenu *)itemMenu target:(id)newTarget secondaryAction:(SEL)newSecondaryAction;

- (void)unhighlight;
- (void)mouseEntered:(NSEvent *)theEvent;
- (void)mouseExited:(NSEvent *)theEvent;
- (void)updateTrackingAreas;

- (void)setHighlighted:(BOOL)highlighted;

@end
