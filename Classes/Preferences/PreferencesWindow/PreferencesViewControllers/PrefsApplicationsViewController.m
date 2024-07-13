//
//  PrefsApplicationsViewController.m
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


- (void)willBeDisplayed
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    allowSwitchToApplicationsButton.enabled = ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableMacOSAAC"];
    allowFlashFullscreen.enabled = allowSwitchToApplicationsButton.state && ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableMacOSAAC"];;
    [self updateFieldsForOS];
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) allowSwitchToApplicationsButton:(NSButton *)sender {
    allowFlashFullscreen.enabled = sender.state;
    if (sender.state) {
        NSAlert *newAlert = [[NSAlert alloc] init];
        [newAlert setMessageText:NSLocalizedString(@"Security Warning", @"")];
        [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"This setting allows to switch to any application on the exam client computer. Use this option only when running %@ in a special user account, with only %@ and the desired applications allowed.", @""), SEBShortAppName, SEBShortAppName]];
        [newAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [newAlert setAlertStyle:NSAlertStyleCritical];
        // beginSheetModalForWindow: completionHandler: is available from macOS 10.9,
        // which also is the minimum macOS version the Preferences window is available from
        [newAlert beginSheetModalForWindow:MBPreferencesController.sharedController.window completionHandler:nil];
    }
}


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self changedOS:self];
    [self prohibitedProcessChangedOS:self];
}

- (IBAction)changedOS:(id)sender {
    [self updateFieldsForOS];
}

- (void) updateFieldsForOS {
    if (permittedProcessesTableView.selectedRow != -1) {
        NSInteger selectedOS = osPopUpButton.indexOfSelectedItem;
        switch (selectedOS) {
            case SEBSupportedOSmacOS:
                chooseApplicationButton.hidden = NO;
                executableView.hidden = NO;
                originalNameView.hidden = YES;
                pathView.hidden = YES;
                argumentsView.hidden = YES;
                iconInTaskbarButton.hidden = NO;
                autostartButton.hidden = NO;
                identifierView.hidden = NO;
                teamIdentifierView.hidden = NO;
                networkAccessButton.hidden = NO;
                runningInBackgroundButton.hidden = YES;
                userSelectLocation.hidden = YES;
                forceQuitButton.hidden = NO;
                break;
                
            case SEBSupportedOSWindows:
                chooseApplicationButton.hidden = YES;
                executableView.hidden = NO;
                originalNameView.hidden = NO;
                pathView.hidden = NO;
                argumentsView.hidden = NO;
                iconInTaskbarButton.hidden = NO;
                autostartButton.hidden = NO;
                identifierView.hidden = YES;
                teamIdentifierView.hidden = YES;
                networkAccessButton.hidden = YES;
                runningInBackgroundButton.hidden = NO;
                userSelectLocation.hidden = NO;
                forceQuitButton.hidden = NO;
                break;
                
            case SEBSupportedOSiOS:
                chooseApplicationButton.hidden = NO;
                executableView.hidden = YES;
                originalNameView.hidden = YES;
                pathView.hidden = YES;
                argumentsView.hidden = YES;
                iconInTaskbarButton.hidden = YES;
                autostartButton.hidden = YES;
                identifierView.hidden = NO;
                teamIdentifierView.hidden = YES;
                networkAccessButton.hidden = NO;
                runningInBackgroundButton.hidden = YES;
                userSelectLocation.hidden = YES;
                forceQuitButton.hidden = YES;
                break;
                
            default:
                break;
        }
    }
}


- (IBAction)prohibitedProcessChangedOS:(id)sender {
    [self prohibitedProcessUpdateFieldsForOS];
}

- (void) prohibitedProcessUpdateFieldsForOS {
    if (prohibitedProcessesTableView.selectedRow != -1) {
        NSInteger selectedOS = prohibitedProcessesOSPopUpButton.indexOfSelectedItem;
        switch (selectedOS) {
            case SEBSupportedOSmacOS:
                prohibitedProcessIdentifierView.hidden = NO;
                currentUserButton.hidden = YES;
                prohibitedProcessOriginalNameView.hidden = YES;
                ignoreInAACButton.hidden = NO;
                break;
                
            case SEBSupportedOSWindows:
                prohibitedProcessIdentifierView.hidden = YES;
                currentUserButton.hidden = YES;
                prohibitedProcessOriginalNameView.hidden = NO;
                ignoreInAACButton.hidden = YES;
                break;
                
            default:
                break;
        }
    }}

- (void) showAlertCannotRemoveProcess
{
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Cannot Remove Preset Prohibited Process", @"")];
    [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"This is a preset prohibited process, which cannot be removed. %@ automatically adds it to any configuration. You can deactivate this preset process or change its properties.", @""), SEBShortAppName]];
    [newAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
    [newAlert setAlertStyle:NSAlertStyleCritical];
    // beginSheetModalForWindow: completionHandler: is available from macOS 10.9,
    // which also is the minimum macOS version the Preferences window is available from
    [newAlert beginSheetModalForWindow:MBPreferencesController.sharedController.window completionHandler:nil];
}

- (IBAction)chooseExecutable:(id)sender {
}

- (IBAction)chooseApplication:(id)sender {
    
}


- (void)selectedPermittedProccessChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->permittedProcessesTableView scrollRowToVisible:self->permittedProcessesTableView.selectedRow];
    });
}
 

- (void)selectedProhibitedProccessChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->prohibitedProcessesTableView scrollRowToVisible:self->prohibitedProcessesTableView.selectedRow];
    });
}
 

- (BOOL)commitEditingAndReturnError:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    return YES;
}

@end
