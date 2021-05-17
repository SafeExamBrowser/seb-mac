//
//  AboutWindow.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 30.10.10.
//  Copyright (c) 2010-2020 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2020 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import "AboutWindow.h"

@implementation AboutWindow



- (void) awakeFromNib
{
	// Write application version and localized copyright into text label fields 
	NSString* versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
	versionString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Version",nil), versionString];
	[version setStringValue: versionString];
	
	NSString* copyrightString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"NSHumanReadableCopyright"];
	copyrightString = [NSString stringWithFormat:@"%@\n\n%@", copyrightString, NSLocalizedString(@"Parts of this project have been carried out as part of the program 'AAA/SWITCH – e-Infrastructure for e-Science' lead by SWITCH, the Swiss National Research and Education Network and the cooperative CRUS project 'Learning Infrastructure' coordinated by SWITCH, and was supported by funds from the ETH Board.",nil)];

	[copyright setStringValue: copyrightString];
}	


// Overriding this method to return NO prevents that the Preferences Window 
// looses key state when the About Window is openend
- (BOOL)canBecomeKeyWindow {
    return NO;
}


// When clicked into the window, close it!
- (void)mouseDown:(NSEvent *)theEvent {
	[self orderOut:self];
    [[NSApplication sharedApplication] stopModal];
}


- (void)showAboutWindowForSeconds:(NSInteger)seconds {
    // Show the About SEB Window
    [self setDelegate:self];
    [self setStyleMask:NSBorderlessWindowMask];
    [self center];
    [self setLevel:NSFloatingWindowLevel];
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"]) {
        [self setLevel:NSMainMenuWindowLevel+5];
    }
    DDLogDebug(@"orderFront About Window");
	[self orderFront:self];
    
    // Close the About SEB Window after a delay
    [self performSelector:@selector(closeAboutWindow:) withObject: nil afterDelay: seconds];

}


// Close the About Window
- (void) closeAboutWindow:(NSNotification *)notification {
    DDLogDebug(@"Attempting to close About Window %@", self);
    [self orderOut:self];
}


@end
