//
//  PrefsBrowserViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 21.10.11.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences Browser Settings Pane
// Settings for using third party applications together with SEB

#import "PrefsBrowserViewController.h"

@implementation PrefsBrowserViewController

- (void) awakeFromNib {
#ifdef __i386__        // Plugins can't be switched on in the 32-bit Intel build
    [enablePlugIns setEnabled:NO]; // disable the checkbox for plug-ins
#endif
    [userAgentWinDesktopDefault setStringValue:SEBWinUserAgentDesktopDefault];
    [userAgentWinTouchDefault setStringValue:SEBWinUserAgentTouchDefault];
    [userAgentWinTouchiPad setStringValue:SEBWinUserAgentTouchiPad];
}


- (NSString *)title
{
	return NSLocalizedString(@"Browser", @"Title of 'Browser' preference pane");
}

- (NSString *)identifier
{
	return @"BrowserPane";
}

- (NSImage *)image
{
    //NSImage *browserIcon = [[NSImage alloc] initWithContentsOfFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/BrowserIcon.png"]];
    //if (browserIcon) return browserIcon; else return [NSImage imageNamed:@"NSAdvanced"];
    return [NSImage imageNamed:@"BrowserIcon"];
}


- (void)willBeDisplayed
{
    NSString *defaultUserAgent = [[MyGlobals sharedMyGlobals] valueForKey:@"defaultUserAgent"];
    if (defaultUserAgent.length == 0) {
        defaultUserAgent = @"";
    }
    [defaultUserAgentMac setStringValue:defaultUserAgent];
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) newBrowserWindowByLinkPolicyChanged:(NSPopUpButton *)sender
{
    
    newBrowserWindowByLinkBlockForeignButton.enabled = [sender indexOfSelectedItem] != getGenerallyBlocked;
}

// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) newBrowserWindowByScriptPolicyChanged:(NSPopUpButton *)sender
{
    newBrowserWindowByScriptBlockForeignButton.enabled = [sender indexOfSelectedItem] != getGenerallyBlocked;
}

// Action to change the displayed browser user agent environment tab
// This is necessary because bindings don't work with private user defaults
- (IBAction) browserUserAgentEnvironmentChanged:(NSPopUpButton *)sender
{
    [userAgentEnvironmentTabView selectTabViewItemAtIndex:sender.indexOfSelectedItem];
}

@end
