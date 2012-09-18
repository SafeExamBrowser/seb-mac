//
//  AboutWindow.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 30.10.10.
//  Copyright (c) 2010-2012 Daniel R. Schneider, ETH Zurich, 
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
//  (C) 2010-2012 Daniel R. Schneider, ETH Zurich, Educational Development
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
	NSString* versionString = [self infoValueForKey:@"CFBundleVersion"];
	versionString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Version",nil), versionString];
	[version setStringValue: versionString];
	
	NSString* copyrightString = [self infoValueForKey:@"NSHumanReadableCopyright"];
	copyrightString = [NSString stringWithFormat:@"%@\n%@", copyrightString, NSLocalizedString(@"CopyrightPart2",nil)];

	[copyright setStringValue: copyrightString];
}	


// Read Info.plist values from bundle
- (id) infoValueForKey:(NSString*)key
{
    if ([[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key])
        return [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:key];
	
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
}


// Overriding this method to return NO prevents that the Prefereces Window 
// looses key state when the About Window is openend
- (BOOL)canBecomeKeyWindow {
    return NO;
}


// When clicked into the window, close it!
- (void)mouseDown:(NSEvent *)theEvent {
	[self orderOut:self];
    [[NSApplication sharedApplication] stopModal];
}


@end
