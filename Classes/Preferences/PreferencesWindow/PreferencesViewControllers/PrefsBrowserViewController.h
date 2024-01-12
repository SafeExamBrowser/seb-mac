//
//  PrefsBrowserViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 21.10.11.
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

// Preferences Browser Settings Pane
// Settings for using third party applications together with SEB

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"
#import "PreferencesViewController.h"

@class PreferencesController;

@interface PrefsBrowserViewController : PreferencesViewController <MBPreferencesModule> {
    IBOutlet NSButton *enablePlugIns;
    IBOutlet NSButton *newBrowserWindowByLinkBlockForeignButton;
    __weak IBOutlet NSButton *browserMediaAutoplayVideoButton;
    __weak IBOutlet NSButton *browserMediaAutoplayAudioButton;
    __weak IBOutlet NSTextField *defaultUserAgentMac;
    __weak IBOutlet NSTextField *userAgentWinDesktopDefault;
    __weak IBOutlet NSTextField *userAgentWinTouchDefault;
    __weak IBOutlet NSTextField *userAgentWinTouchiPad;
    __weak IBOutlet NSTextField *userAgentiOSDefault;
    __weak IBOutlet NSTextField *userAgentiOSMacDesktop;
    __weak IBOutlet NSTabView *userAgentEnvironmentTabView;

}

@property(weak, nonatomic) IBOutlet NSScrollView *scrollView;

- (NSString *)identifier;
- (NSImage *)image;


@end
