//
//  SEBController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 18.04.11.
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

// Controller for the preferences window, populates it with panes

#import "PreferencesController.h"
#import "PrefsGeneralViewController.h"
#import "PrefsSEBConfigViewController.h"
#import "PrefsAppearanceViewController.h"
#import "PrefsBrowserViewController.h"
#import "PrefsDownUploadsViewController.h"
#import "PrefsExamViewController.h"
#import "PrefsApplicationsViewController.h"
#import "PrefsNetworkViewController.h"
#import "PrefsSecurityViewController.h"

#import "MBPreferencesController.h"


@implementation PreferencesController


- (void)awakeFromNib
{
    [self initPreferencesWindow];
}


- (void)showPreferences:(id)sender
{
	[[MBPreferencesController sharedController] showWindow:sender];
}


- (BOOL)preferencesAreOpen {
    return [[MBPreferencesController sharedController].window isVisible];
}


- (void)windowWillClose:(NSNotification *)notification
{
    [[NSApplication sharedApplication] stopModal];
    // Post a notification that preferences were closed
    if (self.preferencesAreOpen) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"preferencesClosed" object:self];
    }
}


- (void)initPreferencesWindow
{
    [[MBPreferencesController sharedController] openWindow];
    // Set the modules for preferences panes
	PrefsGeneralViewController *general = [[PrefsGeneralViewController alloc] initWithNibName:@"PreferencesGeneral" bundle:nil];
	PrefsSEBConfigViewController *config = [[PrefsSEBConfigViewController alloc] initWithNibName:@"PreferencesSEBConfig" bundle:nil];
	PrefsAppearanceViewController *appearance = [[PrefsAppearanceViewController alloc] initWithNibName:@"PreferencesAppearance" bundle:nil];
	PrefsBrowserViewController *browser = [[PrefsBrowserViewController alloc] initWithNibName:@"PreferencesBrowser" bundle:nil];
	PrefsDownUploadsViewController *downuploads = [[PrefsDownUploadsViewController alloc] initWithNibName:@"PreferencesDownUploads" bundle:nil];
	PrefsExamViewController *exam = [[PrefsExamViewController alloc] initWithNibName:@"PreferencesExam" bundle:nil];
	PrefsApplicationsViewController *applications = [[PrefsApplicationsViewController alloc] initWithNibName:@"PreferencesApplications" bundle:nil];
	PrefsNetworkViewController *network = [[PrefsNetworkViewController alloc] initWithNibName:@"PreferencesNetwork" bundle:nil];
	PrefsSecurityViewController *security = [[PrefsSecurityViewController alloc] initWithNibName:@"PreferencesSecurity" bundle:nil];
	[[MBPreferencesController sharedController] setModules:[NSArray arrayWithObjects:general, config, appearance, browser, downuploads, exam, applications, network, security, nil]];
    // Set self as the window delegate to be able to post a notification when preferences window is closing
    // will be overridden when the general pane is displayed (loaded from nib)
    if (![[MBPreferencesController sharedController].window delegate]) {
        // Set delegate only if it's not yet set!
        [[MBPreferencesController sharedController].window setDelegate:self];
#ifdef DEBUG
        NSLog(@"Set PreferencesController as delegate for preferences window");
#endif
    }
}


- (void)releasePreferencesWindow
{
    [[MBPreferencesController sharedController] unloadNibs];
}


@end
