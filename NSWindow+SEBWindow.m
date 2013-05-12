//
//  NSWindow+SEBWindow.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 19.01.12.
//  Copyright (c) 2010-2013 Daniel R. Schneider, ETH Zurich, 
//  Educational Development and Technology (LET), 
//  based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, 
//  Dirk Bauer, Karsten Burger, Marco Lehre, 
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
//  (c) 2010-2013 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import "NSWindow+SEBWindow.h"
#import "MethodSwizzling.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"

@implementation NSWindow (SEBWindow)


- (void)newSetLevel:(NSInteger)windowLevel
{
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"]) {
        if (windowLevel == NSNormalWindowLevel) {
            windowLevel = NSModalPanelWindowLevel;
#ifdef DEBUG
            NSLog(@"Window %@ level NSNormalWindowLevel changed to NSModalPanelWindowLevel", self);
#endif
        }
        if (windowLevel == NSModalPanelWindowLevel) {
            windowLevel = NSScreenSaverWindowLevel;
#ifdef DEBUG
            NSLog(@"Window %@ level NSModalPanelWindowLevel changed to NSScreenSaverWindowLevel", self);
#endif
        }
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
    
    NSUInteger mask = 0;
    if( x > self.frame.size.width / 2.0 )
    {
        mask |= NSViewMinXMargin;
    }
    else
    {
        mask |= NSViewMaxXMargin;
    }
    [viewToAdd setAutoresizingMask:mask | NSViewMinYMargin];
    
    [[[self contentView] superview] addSubview:viewToAdd];
}

-(void)addViewToTitleBar:(NSView*)viewToAdd atRightOffset:(CGFloat)x
{
    //viewToAdd.frame = NSMakeRect(self.frame.size.width-x-viewToAdd.frame.size.width, [[self contentView] frame].size.height, viewToAdd.frame.size.width, [self heightOfTitleBar]);
    viewToAdd.frame = NSMakeRect(self.frame.size.width-x-viewToAdd.frame.size.width, [[[self contentView] superview] frame].size.height - viewToAdd.frame.size.height - 3, viewToAdd.frame.size.width, viewToAdd.frame.size.height);
    
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
    //[viewToAdd setAutoresizingMask:mask | NSViewMaxYMargin];
    
    [[[self contentView] superview] addSubview:viewToAdd];
}

-(CGFloat)heightOfTitleBar
{
    NSRect outerFrame = [[[self contentView] superview] frame];
    NSRect innerFrame = [[self contentView] frame];
    
    return outerFrame.size.height - innerFrame.size.height;
}


@end
