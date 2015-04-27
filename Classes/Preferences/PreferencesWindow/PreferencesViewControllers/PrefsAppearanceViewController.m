//
//  PrefsAppearanceViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 18.04.11.
//  Copyright (c) 2010-2015 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2015 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences Advanced Pane
// Settings use of third party applications together with SEB

#import "PrefsAppearanceViewController.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"

@implementation PrefsAppearanceViewController

- (NSString *)title
{
	return NSLocalizedString(@"User Interface", @"Title of 'Appearance' preference pane");
}

- (NSString *)identifier
{
	return @"AppearancePane";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"Appearance.icns"];
}


// Before displaying pane set the download directory
- (void)willBeDisplayed
{
    
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) browserViewModeMatrix:(NSMatrix *)sender
{
    BOOL browserViewModeWindowSelected = [sender selectedRow] == browserViewModeWindow;
    
    mainBrowserWindowWidth.enabled = browserViewModeWindowSelected;
    mainBrowserWindowHeight.enabled = browserViewModeWindowSelected;
    mainBrowserWindowPositioning.enabled = browserViewModeWindowSelected;
    
    enableBrowserWindowToolbar.enabled = browserViewModeWindowSelected;
    hideBrowserWindowToolbar.enabled = browserViewModeWindowSelected && enableBrowserWindowToolbar.state;
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) enableBrowserWindowToolbarButton:(NSButton *)sender
{
    hideBrowserWindowToolbar.enabled = [sender state];
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) showTaskBarButton:(NSButton *)sender
{
    taskBarHeight.enabled = [sender state];
}


@end
