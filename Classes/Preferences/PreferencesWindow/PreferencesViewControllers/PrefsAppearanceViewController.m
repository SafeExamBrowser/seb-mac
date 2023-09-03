//
//  PrefsAppearanceViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 18.04.11.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences Advanced Pane
// Settings use of third party applications together with SEB

#import "PrefsAppearanceViewController.h"

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

- (void)awakeFromNib {
    [self scrollToTop:_scrollView];
}

// Before displaying pane set browser view mode correctly even when touch optimized is selected
- (void)willBeDisplayed
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL browserViewModeTouchSelected = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_touchOptimized"];
    if (browserViewModeTouchSelected) {
        [browserViewModeMatrix selectCellAtRow:browserViewModeTouch column:0];
    }
    [self browserViewModeMatrix:browserViewModeMatrix];
    
    allowDictionaryLookupButton.enabled = ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableMacOSAAC"];
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) browserViewModeMatrix:(NSMatrix *)sender
{
    BOOL browserViewModeWindowSelected = [sender selectedRow] == browserViewModeWindow;
    
    mainBrowserWindowWidth.enabled = browserViewModeWindowSelected;
    mainBrowserWindowHeight.enabled = browserViewModeWindowSelected;
    mainBrowserWindowPositioning.enabled = browserViewModeWindowSelected;
       
    BOOL browserViewModeTouchSelected = [sender selectedRow] == browserViewModeTouch;
    enableTouchExit.enabled = browserViewModeTouchSelected;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureBool:browserViewModeTouchSelected forKey:@"org_safeexambrowser_SEB_touchOptimized"];
    [preferences setSecureBool:browserViewModeTouchSelected forKey:@"org_safeexambrowser_SEB_browserScreenKeyboard"];
    
    if ([[MBPreferencesController sharedController].window isVisible] && !self.touchOptimizedWarning && browserViewModeTouchSelected && [preferences secureBoolForKey:@"org_safeexambrowser_SEB_createNewDesktop"]) {
        self.touchOptimizedWarning = true;
        NSAlert *newAlert = [[NSAlert alloc] init];
        [newAlert setMessageText:NSLocalizedString(@"Touch Optimized Mode Warning", @"")];
        [newAlert setInformativeText:NSLocalizedString(@"Touch optimization will not work when kiosk mode is set to 'Create new desktop', please change kiosk mode to 'Disable Explorer Shell' in the Security pane.", @"")];
        [newAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [newAlert setAlertStyle:NSAlertStyleCritical];
        // beginSheetModalForWindow: completionHandler: is available from macOS 10.9,
        // which also is the minimum macOS version the Preferences window is available from
        [newAlert beginSheetModalForWindow:MBPreferencesController.sharedController.window completionHandler:nil];
    }
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


- (IBAction)enablePageZoomButton:(NSButton *)sender {
    // Action to set the enabled property of dependent buttons
    // This is necessary because bindings don't work with private user defaults
    usePageZoomRadioButton.enabled = [sender state];

    // Change zoom mode when disabling page zoom and text zoom is enabled
    if (sender.state == false && enableTextZoomButton.state == true && [zoomModeMatrix selectedRow] == SEBZoomModePage) {
        [zoomModeMatrix selectCellAtRow:SEBZoomModeText column:0];
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences setSecureInteger:SEBZoomModeText forKey:@"org_safeexambrowser_SEB_zoomMode"];
    }
    // Change zoom mode when enabling page zoom and text zoom is disabled
    if (sender.state == true && enableTextZoomButton.state == false && [zoomModeMatrix selectedRow] == SEBZoomModeText) {
        [zoomModeMatrix selectCellAtRow:SEBZoomModePage column:0];
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences setSecureInteger:SEBZoomModePage forKey:@"org_safeexambrowser_SEB_zoomMode"];
    }
}


- (IBAction)enableTextZoomButton:(NSButton *)sender {
    // Action to set the enabled property of dependent buttons
    // This is necessary because bindings don't work with private user defaults
    useTextZoomRadioButton.enabled = [sender state];
    
    // Change zoom mode when disabling text zoom and page zoom is enabled
    if (sender.state == false && enablePageZoomButton.state == true && [zoomModeMatrix selectedRow] == SEBZoomModeText) {
        [zoomModeMatrix selectCellAtRow:SEBZoomModePage column:0];
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences setSecureInteger:SEBZoomModePage forKey:@"org_safeexambrowser_SEB_zoomMode"];
    }
    // Change zoom mode when enabling text zoom and page zoom is enabled
    if (sender.state == true && enablePageZoomButton.state == false && [zoomModeMatrix selectedRow] == SEBZoomModePage) {
        [zoomModeMatrix selectCellAtRow:SEBZoomModeText column:0];
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences setSecureInteger:SEBZoomModeText forKey:@"org_safeexambrowser_SEB_zoomMode"];
    }
}


@end
