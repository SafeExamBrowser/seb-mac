//
//  CapWindow.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06.03.14.
//  Copyright (c) 2010-2014 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2014 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "CapWindow.h"
#import "Constants.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"

@implementation CapWindow

@synthesize constrainingToScreenSuspended;

//- (void)orderWindow:(NSWindowOrderingMode)orderingMode relativeTo:(NSInteger)otherWindowNumber
//{
//    [super orderWindow:orderingMode relativeTo:otherWindowNumber];
//    if (orderingMode != NSWindowOut) {
//        
//    }
//}

// This window has its usual -constrainFrameRect:toScreen: behavior temporarily suppressed.
// This enables our window's custom Full Screen Exit animations to avoid being constrained by the
// top edge of the screen and the menu bar.
//
- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen
{
    if (constrainingToScreenSuspended)
    {
        return frameRect;
    }
    else
    {
        return [super constrainFrameRect:frameRect toScreen:screen];
    }
}


- (NSWindowCollectionBehavior)collectionBehavior
{
    NSWindowCollectionBehavior collectionBehavior = NSWindowCollectionBehaviorFullScreenAuxiliary; //NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces;
    
//    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
//    if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowSwitchToApplications"] == NO)
//    {
//        collectionBehavior += NSWindowCollectionBehaviorStationary;
//    }
    return collectionBehavior;
}
//- (BOOL)canBecomeKeyWindow
//{
//    return YES;
//}


@end
