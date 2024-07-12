//
//  PrefsApplicationsViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 08.02.13.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences Applications Pane
// Settings use of third party applications together with SEB

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"
#import "SafeExamBrowser-Swift.h"

@interface PrefsApplicationsViewController : NSViewController <MBPreferencesModule, ApplicationsPreferencesDelegate, NSTableViewDelegate> {

    __weak IBOutlet NSButton *allowSwitchToApplicationsButton;
    __weak IBOutlet NSButton *allowFlashFullscreen;
    __weak IBOutlet NSButton *chooseApplicationButton;
    __weak IBOutlet NSStackView *executableView;
    __weak IBOutlet NSStackView *originalNameView;
    __weak IBOutlet NSStackView *pathView;
    __weak IBOutlet NSStackView *argumentsView;
    __weak IBOutlet NSButton *iconInTaskbarButton;
    __weak IBOutlet NSButton *autostartButton;
    __weak IBOutlet NSStackView *identifierView;
    __weak IBOutlet NSStackView *teamIdentifierView;
    __weak IBOutlet NSButton *networkAccessButton;
    __weak IBOutlet NSButton *runningInBackgroundButton;
    __weak IBOutlet NSButton *userSelectLocation;
    __weak IBOutlet NSButton *forceQuitButton;
    __weak IBOutlet NSPopUpButton *osPopUpButton;
    __weak IBOutlet NSTableView *permittedProcessesTableView;
}

- (NSString *)identifier;
- (NSImage *)image;

- (IBAction) allowSwitchToApplicationsButton:(NSButton *)sender;
- (IBAction) chooseApplication:(id)sender;
- (void) showAlertCannotRemoveProcess;
- (IBAction) changedOS:(id)sender;


@end
