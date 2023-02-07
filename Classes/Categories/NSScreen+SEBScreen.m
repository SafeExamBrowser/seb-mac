//
//  NSScreen+SEBScreen
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.10.16.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider,
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

#import "NSScreen+SEBScreen.h"
#import <IOKit/graphics/IOGraphicsLib.h>
#import "objc/runtime.h"

@implementation NSScreen (SEBScreen)


- (void)setInactive:(BOOL)inactive
{
    NSNumber *inactiveBool = [NSNumber numberWithBool:inactive];
    objc_setAssociatedObject(self, @selector(inactive), inactiveBool, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)inactive
{
    NSNumber *inactiveBool = objc_getAssociatedObject(self, @selector(inactive));
    return inactiveBool.boolValue;
}


+ (NSString*) displayNameForID:(NSInteger)displayID
{
    NSString *screenName = nil;
    
    CGDirectDisplayID directDisplayID = (CGDirectDisplayID)displayID;
    
    NSDictionary *deviceInfo = (NSDictionary *)CFBridgingRelease(IODisplayCreateInfoDictionary(CGDisplayIOServicePort(directDisplayID), kIODisplayOnlyPreferredName));
    NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
    
    if ([localizedNames count] > 0) {
        screenName = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
    }
    
    return screenName;
}


- (NSString*) displayName
{
    CGDirectDisplayID displayID = [[self displayID] intValue];
    
    NSString *screenName = nil;
    
    NSDictionary *deviceInfo = (NSDictionary *)CFBridgingRelease(IODisplayCreateInfoDictionary(CGDisplayIOServicePort(displayID), kIODisplayOnlyPreferredName));
    NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
    
    if ([localizedNames count] > 0) {
        screenName = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
    }
    
    return screenName;
}


- (NSNumber*) displayID
{
    return [[self deviceDescription] valueForKey:@"NSScreenNumber"];
}


- (NSRect) usableFrame
{
    // Get full screen frame
    NSRect newFrame = self.visibleFrame;
    return newFrame;
}

- (CGFloat) menuBarHeight
{
    NSRect visibleFrame = self.visibleFrame;
    CGFloat menuBarHeight = self.frame.size.height - visibleFrame.size.height - (self.visibleFrame.origin.y - self.frame.origin.y) - 1;
    return menuBarHeight;
}

@end
