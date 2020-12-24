//
//  PrefsApplicationsViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 08.02.13.
//  Copyright (c) 2010-2020 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2020 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences Applications Pane
// Settings use of third party applications together with SEB

#import "PrefsApplicationsViewController.h"

@implementation PrefsApplicationsViewController

- (NSString *)title
{
	return NSLocalizedString(@"Applications", @"Title of 'Applications' preference pane");
}

- (NSString *)identifier
{
	return @"ApplicationsPane";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"ApplicationsIcon"];
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) allowSwitchToApplicationsButton:(NSButton *)sender {
    allowFlashFullscreen.enabled = sender.state;
    if (sender.state) {
        NSAlert *newAlert = [[NSAlert alloc] init];
        [newAlert setMessageText:NSLocalizedString(@"Security Warning", nil)];
        [newAlert setInformativeText:NSLocalizedString(@"This setting allows to switch to any application on the exam client computer. Use this option only when running SEB in a special user account managed by parental controls, with only SEB and the desired applications allowed.", nil)];
        [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [newAlert setAlertStyle:NSCriticalAlertStyle];
        [newAlert beginSheetModalForWindow:MBPreferencesController.sharedController.window completionHandler:nil];
    }
}


- (void) showAlertCannotRemoveProcess
{
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Cannot Remove Preset Prohibited Process", nil)];
    [newAlert setInformativeText:NSLocalizedString(@"This is a preset prohibited process, which cannot be removed. SEB automatically adds it to any configuration. You can deactivate this preset process or change its properties.", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [newAlert setAlertStyle:NSCriticalAlertStyle];
    [newAlert beginSheetModalForWindow:MBPreferencesController.sharedController.window completionHandler:nil];
}


@end
