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
    BOOL enableAAC = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableMacOSAAC"];
    allowSwitchToApplicationsButton.hidden = enableAAC;
    allowOpenSavePanelButton.hidden = !enableAAC;
    allowShareSheetButton.hidden = !enableAAC;
    allowFlashFullscreen.enabled = allowSwitchToApplicationsButton.state && ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableMacOSAAC"];;
    [self updateFieldsForOS];
    [self conditionallyShowDependentSettingsWarning:self];
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
                allowManualStartButton.hidden = NO;
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
                allowManualStartButton.hidden = YES;
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
                allowManualStartButton.hidden = YES;
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

- (IBAction)showDependentSettingsWarning:(id)sender {
    [self conditionallyPromptToUpdateSettingsForMultiAppMode];
}

- (IBAction)chooseApplication:(id)sender {
    // Set the default name for the file and show the panel.
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSError *error;
    panel.directoryURL = [NSFileManager.defaultManager URLForDirectory:NSApplicationDirectory inDomain:NSLocalDomainMask appropriateForURL:nil create:NO error:&error];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"app"]];
    [panel beginSheetModalForWindow:self.view.window
                  completionHandler:^(NSInteger result){
                      if (result == NSModalResponseOK)
                      {
                          NSURL *appURL = [panel URL];
                          NSBundle *appBundle = [NSBundle bundleWithURL:appURL];
                          DDLogInfo(@"Selected app with file URL %@", appURL);
                          [self.permittedProcessesArrayController addAppWithBundle:appBundle];
                      }
                  }];
}


- (void)selectedPermittedProccessChanged
{
    [self changedOS:self];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->permittedProcessesTableView scrollRowToVisible:self->permittedProcessesTableView.selectedRow];
        NSPredicate *filterProcessOS = [NSPredicate predicateWithFormat:@"active == YES AND os == %d", SEBSupportedOSmacOS];
        if ([self.permittedProcessesArrayController.content filteredArrayUsingPredicate:filterProcessOS].count == 1) {
            [self conditionallyPromptToUpdateSettingsForMultiAppMode];
        } else if ([self.permittedProcessesArrayController.content filteredArrayUsingPredicate:filterProcessOS].count == 0) {
            self->warningDependentSettingsButton.hidden = YES;
        }
    });
}


- (IBAction)conditionallyShowDependentSettingsWarning:(id)sender {
    NSPredicate *filterProcessOS = [NSPredicate predicateWithFormat:@"active == YES AND os == %d", SEBSupportedOSmacOS];
    if ([self.permittedProcessesArrayController.content filteredArrayUsingPredicate:filterProcessOS].count > 0) {
        warningDependentSettingsButton.hidden = [self checkSettingsForMultiAppMode] && [self checkSettingsForDownOpenUploadFiles];
    }
}


- (void)conditionallyPromptToUpdateSettingsForMultiAppMode
{
    if (![self checkSettingsForMultiAppMode]) {
        NSAlert *newAlert = [self alertUpdateSettingForMultiAppMode];
        [newAlert beginSheetModalForWindow:MBPreferencesController.sharedController.window completionHandler:^(NSInteger result) {
            if (result == NSAlertFirstButtonReturn) {
                self->warningDependentSettingsButton.hidden = YES;
                [self setSettingsForMultiAppMode];
                [self conditionallyPromptToUpdateSettingsForDownOpenUploadFiles];
            } else {
                self->warningDependentSettingsButton.hidden = NO;
                [self conditionallyPromptToUpdateSettingsForDownOpenUploadFiles];
            }
        }];
    } else {
        self->warningDependentSettingsButton.hidden = YES;
        [self conditionallyPromptToUpdateSettingsForDownOpenUploadFiles];
    }
}

- (void)conditionallyPromptToUpdateSettingsForDownOpenUploadFiles
{
    if (![self checkSettingsForDownOpenUploadFiles]) {
        NSAlert *newAlert = [self alertUpdateSettingForDownOpenUploadFiles];
        [newAlert beginSheetModalForWindow:MBPreferencesController.sharedController.window completionHandler:^(NSInteger result) {
            if (result == NSAlertFirstButtonReturn) {
                self->warningDependentSettingsButton.hidden = YES;
                [self setSettingsForDownOpenUploadFiles];
            } else {
                self->warningDependentSettingsButton.hidden = NO;
            }
        }];
    }
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


- (NSAlert *)alertUpdateSettingForMultiAppMode
{
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Update Settings for Multi App Mode", @"")];
    [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"For using permitted macOS third-party applications, AAC Assessment Mode must be enabled, file and share dialogs blocked and macOS 12 or newer enforced. Do you want to update your %@ settings accordingly?", @""), SEBShortAppName]];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Update Settings", @"")];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Ignore", @"")];
    [newAlert setAlertStyle:NSAlertStyleCritical];
    return newAlert;
}


- (BOOL)checkSettingsForMultiAppMode
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL multiAppModeSettings = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableMacOSAAC"] &&
    [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowOpenAndSavePanel"] &&
    [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowShareSheet"] &&
    [self checkSettingsForMinMacOSVersionMajor:12 minor:0 patch:0];
    
    return multiAppModeSettings;
}


- (void)setSettingsForMultiAppMode
{
    // Release preferences window so bindings get synchronized properly with the new loaded values
    [_preferencesController releasePreferencesWindow];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_enableMacOSAAC"];
    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowOpenAndSavePanel"];
    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowShareSheet"];
    
    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberCheckFull"];
    [preferences setSecureInteger:12 forKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberMajor"];
    [preferences setSecureInteger:0 forKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberMinor"];
    [preferences setSecureInteger:0 forKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberPatch"];
    
    // Re-initialize and open preferences window
    [_preferencesController initPreferencesWindow];
    [_preferencesController reopenPreferencesWindow];
}


- (NSAlert *)alertUpdateSettingForDownOpenUploadFiles
{
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Update Settings for Download/Opening/Upload Files", @"")];
    [newAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"When using additional, permitted macOS third-party applications in exams, it often makes sense to allow secure download and upload of files from a web-based assessment system. %@ opens these files automatically with the according additional app after downloading. Examinees can then edit these template files in the additional app and save them with the same file name (cmd-S). When the assessment system contains an upload/choose file button, those files can be uploaded and submitted with the exam. Do you want to update your %@ settings accordingly?", @""), SEBShortAppName, SEBShortAppName]];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Update Settings", @"")];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Ignore", @"")];
    [newAlert setAlertStyle:NSAlertStyleCritical];
    return newAlert;
}


- (BOOL)checkSettingsForDownOpenUploadFiles
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL downOpenUploadSettings = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDownUploads"] &&
    [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDownloads"] &&
    [preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowUploads"] &&
    [preferences secureBoolForKey:@"org_safeexambrowser_SEB_openDownloads"] &&
    [preferences secureBoolForKey:@"org_safeexambrowser_SEB_useTemporaryDownUploadDirectory"] &&
    [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_chooseFileToUploadPolicy"] == onlyAllowUploadSameFileDownloadedBefore;

    return downOpenUploadSettings;
}


- (void)setSettingsForDownOpenUploadFiles
{
    // Release preferences window so bindings get synchronized properly with the new loaded values
    [_preferencesController releasePreferencesWindow];

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowDownUploads"];
    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowDownloads"];
    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowUploads"];
    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_openDownloads"];
    [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_useTemporaryDownUploadDirectory"];
    [preferences setSecureInteger:onlyAllowUploadSameFileDownloadedBefore forKey:@"org_safeexambrowser_SEB_chooseFileToUploadPolicy"];
    
    // Re-initialize and open preferences window
    [_preferencesController initPreferencesWindow];
    [_preferencesController reopenPreferencesWindow];
}


- (BOOL)checkSettingsForMinMacOSVersionMajor:(NSUInteger)currentOSMajorVersion
                            minor:(NSUInteger)currentOSMinorVersion
                            patch:(NSUInteger)currentOSPatchVersion
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSUInteger allowMacOSVersionMajor = SEBMinMacOSVersionSupportedMajor;
    NSUInteger allowMacOSVersionMinor = SEBMinMacOSVersionSupportedMinor;
    NSUInteger allowMacOSVersionPatch = SEBMinMacOSVersionSupportedPatch;

    if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberCheckFull"]) {
        // Manage old check only for allowed major version
        SEBMinMacOSVersion minMacOSVersion = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_minMacOSVersion"];
        switch (minMacOSVersion) {
            case SEBMinMacOS10_14:
                allowMacOSVersionMajor = 10;
                allowMacOSVersionMinor = 14;
                allowMacOSVersionPatch = 0;
                break;
                
            case SEBMinMacOS10_15:
                allowMacOSVersionMajor = 10;
                allowMacOSVersionMinor = 15;
                allowMacOSVersionPatch = 0;
                break;
                
            case SEBMinMacOS11:
                allowMacOSVersionMajor = 11;
                allowMacOSVersionMinor = 0;
                allowMacOSVersionPatch = 0;
                break;
                
            case SEBMinMacOS12:
                allowMacOSVersionMajor = 12;
                allowMacOSVersionMinor = 0;
                allowMacOSVersionPatch = 0;
                break;
                
            case SEBMinMacOS13:
                allowMacOSVersionMajor = 13;
                allowMacOSVersionMinor = 0;
                allowMacOSVersionPatch = 0;
                break;
                
            case SEBMinMacOS14:
                allowMacOSVersionMajor = 14;
                allowMacOSVersionMinor = 0;
                allowMacOSVersionPatch = 0;
                break;
                
            case SEBMinMacOS15:
                allowMacOSVersionMajor = 15;
                allowMacOSVersionMinor = 0;
                allowMacOSVersionPatch = 0;
                break;
                
            default:
                break;
        }
    } else {
        // Full granular check for allowed major, minor and patch version
        allowMacOSVersionMajor = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberMajor"];
        allowMacOSVersionMinor = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberMinor"];
        allowMacOSVersionPatch = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberPatch"];
    }
    
    // Check for minimal macOS version requirements of this SEB version
    if (allowMacOSVersionMajor < SEBMinMacOSVersionSupportedMajor) {
        allowMacOSVersionMajor = SEBMinMacOSVersionSupportedMajor;
        allowMacOSVersionMinor = SEBMinMacOSVersionSupportedMinor;
        allowMacOSVersionPatch = SEBMinMacOSVersionSupportedPatch;
    } else if (allowMacOSVersionMajor == SEBMinMacOSVersionSupportedMajor) {
        if (allowMacOSVersionMinor < SEBMinMacOSVersionSupportedMinor) {
            allowMacOSVersionMinor = SEBMinMacOSVersionSupportedMinor;
            allowMacOSVersionPatch = SEBMinMacOSVersionSupportedPatch;
        } else if (allowMacOSVersionMinor == SEBMinMacOSVersionSupportedMinor && allowMacOSVersionPatch < SEBMinMacOSVersionSupportedPatch) {
            allowMacOSVersionPatch = SEBMinMacOSVersionSupportedPatch;
        }
    }

    return !(currentOSMajorVersion < allowMacOSVersionMajor ||
        (currentOSMajorVersion == allowMacOSVersionMajor &&
         currentOSMinorVersion < allowMacOSVersionMinor) ||
        (currentOSMajorVersion == allowMacOSVersionMajor &&
         currentOSMinorVersion == allowMacOSVersionMinor &&
         currentOSPatchVersion < allowMacOSVersionPatch)
            );
}


@end
