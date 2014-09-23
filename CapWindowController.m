//
//  CapWindowController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 11.03.14.
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


#import "CapWindowController.h"
#import "CapWindow.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "MyGlobals.h"


@implementation CapWindowController

@synthesize frameForNonFullScreenMode;


- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
//        [self.window setCollectionBehavior:NSWindowCollectionBehaviorStationary | NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];
//        [self.window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary];

    }
#ifdef DEBUG
    NSLog(@"Cap window %@ init.", self);
#endif

    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
#ifdef DEBUG
    NSLog(@"Cap window %@ didLoad.", self.window);
#endif
}


// -------------------------------------------------------------------------------
//	awakeFromNib
// -------------------------------------------------------------------------------
- (void)awakeFromNib
{
    // To specify we want our given window to be the full screen primary one, we can
    // use the following:
    //[self.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    //
    // But since we have already set this in our xib file for our NSWindow object
    //  (Full Screen -> Primary Window) this line of code it not needed.
    
	// listen for these notifications so we can update our image based on the full-screen state
    
#ifdef DEBUG
    NSLog(@"Cap window %@ awakeFromNib.", self.window);
#endif
    [self.window setSharingType:NSWindowSharingNone];
}


@end
