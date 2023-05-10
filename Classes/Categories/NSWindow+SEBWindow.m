//
//  NSWindow+SEBWindow.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 19.01.12.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import "NSWindow+SEBWindow.h"
#import "MethodSwizzling.h"

@implementation NSWindow (SEBWindow)


- (void)newSetLevel:(NSInteger)windowLevel
{
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"]) {
        if (windowLevel == NSNormalWindowLevel) {
            windowLevel = NSMainMenuWindowLevel+5;
            DDLogVerbose(@"Window %@ level NSNormalWindowLevel changed to NSMainMenuWindowLevel+5", self);
        }
        if (windowLevel == NSMainMenuWindowLevel) {
            windowLevel = NSScreenSaverWindowLevel+1;
            DDLogVerbose(@"Window %@ level NSMainMenuWindowLevel changed to NSScreenSaverWindowLevel+1", self);
        }
    }
    if (windowLevel == NSModalPanelWindowLevel) {
        windowLevel = NSMainMenuWindowLevel+6;
        DDLogVerbose(@"Window %@ level NSModalPanelWindowLevel changed to NSMainMenuWindowLevel+6", self);
    }
    [self newSetLevel:windowLevel]; //call the original(!) method
}


+ (void)setupChangingWindowLevels
{
    [self swizzleMethod:@selector(setLevel:)
             withMethod:@selector(newSetLevel:)];
}


-(void)addViewToTitleBar:(NSView*)viewToAdd atLeftOffset:(CGFloat)x
{
    viewToAdd.frame = NSMakeRect(x, [[self contentView] frame].size.height, viewToAdd.frame.size.width, [self heightOfTitleBar]);
    
    [[[self contentView] superview] addSubview:viewToAdd];
}

-(void)addViewToTitleBar:(NSView*)viewToAdd atRightOffset:(CGFloat)x
{
    viewToAdd.frame = NSMakeRect(self.frame.size.width-x-viewToAdd.frame.size.width, [[[self contentView] superview] frame].size.height - viewToAdd.frame.size.height - 3, viewToAdd.frame.size.width, viewToAdd.frame.size.height);

    [self addPositionedViewToTitleBar:viewToAdd atRightOffset:x];
}

-(void)addViewToTitleBar:(NSView*)viewToAdd atRightOffsetToTitle:(CGFloat)x verticalOffset:(CGFloat)y
{
    CGFloat freeSpaceRightFromTitle = (self.frame.size.width
                                       - [NSWindow minFrameWidthWithTitle:self.title styleMask:self.styleMask]
                                       + 86
                                       - 20*(self.representedURL != nil)) / 2;
    
    viewToAdd.frame = NSMakeRect(self.frame.size.width-freeSpaceRightFromTitle+x, [[[self contentView] superview] frame].size.height - viewToAdd.frame.size.height - 3 + y, viewToAdd.frame.size.width, viewToAdd.frame.size.height);
    
    [self addPositionedViewToTitleBar:viewToAdd atRightOffset:x];
}

- (void)addPositionedViewToTitleBar:(NSView *)viewToAdd atRightOffset:(CGFloat)x {
    DDLogVerbose(@"View to add frame size: %f, %f at origin: %f, %f", viewToAdd.frame.size.width, viewToAdd.frame.size.height, viewToAdd.frame.origin.x, viewToAdd.frame.origin.y);
    
    NSUInteger mask = 0;
    if( x > self.frame.size.width / 2.0 )
    {
        mask |= NSViewMaxXMargin;
    }
    else
    {
        mask |= NSViewMinXMargin;
    }
    [viewToAdd setAutoresizingMask:mask | NSViewMinYMargin];
    
    [[[self contentView] superview] addSubview:viewToAdd];
}

-(void)adjustPositionOfViewInTitleBar:(NSView*)viewToAdjust atRightOffsetToTitle:(CGFloat)x verticalOffset:(CGFloat)y
{
    CGFloat freeSpaceRightFromTitle = (self.frame.size.width
                                       - [NSWindow minFrameWidthWithTitle:self.title styleMask:self.styleMask]
                                       + 86
                                       - 20*(self.representedURL != nil)) / 2;
    
    viewToAdjust.frame = NSMakeRect(self.frame.size.width-freeSpaceRightFromTitle+x, [[[self contentView] superview] frame].size.height - viewToAdjust.frame.size.height - 3 + y, viewToAdjust.frame.size.width, viewToAdjust.frame.size.height);
    
    NSUInteger mask = 0;
    if( x > self.frame.size.width / 2.0 )
    {
        mask |= NSViewMaxXMargin;
    }
    else
    {
        mask |= NSViewMinXMargin;
    }
    [viewToAdjust setAutoresizingMask:mask | NSViewMinYMargin];
}

-(CGFloat)heightOfTitleBar
{
    NSRect outerFrame = [[[self contentView] superview] frame];
    NSRect innerFrame = [[self contentView] frame];
    
    return outerFrame.size.height - innerFrame.size.height;
}


@end
