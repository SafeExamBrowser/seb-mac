//
//  PrefsApplicationsViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 08.02.13.
//  Copyright (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel, 
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre, 
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 2.0 (the "License"); you may not use this file except in
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
//  (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
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
    lockdownModePolicy policy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_lockdownModePolicy"];
    BOOL enableAAC = (policy != lockdownModePolicyEnforceClassic);
    allowSwitchToApplicationsButton.hidden = enableAAC;
    allowOpenSavePanelButton.hidden = !enableAAC;
    allowShareSheetButton.hidden = !enableAAC;
    allowFlashFullscreen.enabled = allowSwitchToApplicationsButton.state && !enableAAC;
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
        [newAlert setInformativeText:NSLocalizedString(@"This setting allows to switch to any application on the exam client computer. Use this option only for open book exams (without lock down) or for debugging.", @"")];
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
                runningInBackgroundButton.hidden = NO;
                userSelectLocation.hidden = YES;
                forceQuitButton.hidden = NO;
                allowAccessibilityButton.hidden = NO;
                break;
                
            case SEBSupportedOSWindows:
                chooseApplicationButton.hidden = YES;
                executableView.hidden = NO;
                originalNameView.hidden = NO;
                pathView.hidden = NO;
                pathLabel.stringValue = NSLocalizedString(@"Path", @"Label for path property of a Windows permitted process");
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
                allowAccessibilityButton.hidden = YES;
                break;
                
            case SEBSupportedOSiPadOS:
                chooseApplicationButton.hidden = NO;
                executableView.hidden = YES;
                originalNameView.hidden = YES;
                pathView.hidden = NO;
                pathLabel.stringValue = NSLocalizedString(@"Custom Scheme", @"Label for custom (URL protocol) scheme property of an iPadOS/iOS permitted process/Additional App");
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
                allowAccessibilityButton.hidden = YES;
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


// Show a dialog listing the preset permitted processes which can be added to the current
// settings: the hardcoded inactive preset processes and, when editing an exam configuration
// (private user defaults active), the permitted processes from the local client settings.
// Processes already present in the current settings are omitted. The user can select one or
// several of them; the selected processes are added to the settings with active = YES.
- (IBAction)addPresetPermittedProcess:(id)sender {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSArray *currentProcesses = (NSArray *)self.permittedProcessesArrayController.arrangedObjects;
    NSMutableArray<NSDictionary *> *availablePresets = [NSMutableArray new];
    // Client settings processes are added first, so the first clientProcessCount entries of
    // availablePresets originate from the local client settings
    NSUInteger clientProcessCount = 0;

    // When editing an exam configuration (private user defaults active), also offer the
    // permitted processes from the local client settings. This way an admin user can build
    // their own library of regularly used processes in the client settings on their admin Mac
    // and quickly add them to exam configurations with this feature.
    if (NSUserDefaults.userDefaultsPrivate) {
        NSArray *clientProcesses = (NSArray *)[preferences persistedSecureObjectForKey:@"org_safeexambrowser_SEB_permittedProcesses"];
        for (NSDictionary *clientProcess in clientProcesses) {
            NSString *identifier = clientProcess[@"identifier"];
            NSString *executable = clientProcess[@"executable"];
            if (identifier.length == 0 && executable.length == 0) {
                // Skip empty template rows which couldn't be matched or meaningfully displayed
                continue;
            }
            if ([self permittedProcess:clientProcess existsInProcesses:currentProcesses] ||
                [self permittedProcess:clientProcess existsInProcesses:availablePresets]) {
                continue;
            }
            [availablePresets addObject:clientProcess];
        }
        clientProcessCount = availablePresets.count;
    }

    // Add the hardcoded inactive preset permitted processes which aren't already present in the
    // current settings (active presets are added to every configuration automatically)
    NSDictionary *defaultSEBSettings = [preferences sebDefaultSettings];
    NSArray *presetProcesses = defaultSEBSettings[@"org_safeexambrowser_SEB_permittedProcesses"];
    for (NSDictionary *presetProcess in presetProcesses) {
        if ([presetProcess[@"active"] boolValue]) {
            continue;
        }
        if ([self permittedProcess:presetProcess existsInProcesses:currentProcesses]) {
            continue;
        }
        // If a process representing the same app (same identifier and executable and, when set on
        // both, the same team identifier) is already offered from the client settings, prefer that
        // one, so the admin's customized properties (e.g. hiding the Dock icon) are used instead of
        // the hardcoded preset's properties.
        BOOL sameAppAlreadyOffered = NO;
        for (NSDictionary *offeredProcess in availablePresets) {
            if ([self permittedProcess:offeredProcess isSameAppAs:presetProcess]) {
                sameAppAlreadyOffered = YES;
                break;
            }
        }
        if (sameAppAlreadyOffered) {
            continue;
        }
        [availablePresets addObject:presetProcess];
    }

    if (availablePresets.count == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:NSLocalizedString(@"No Preset Processes Available", @"")];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"There are currently no additional preset permitted processes which could be added to your %@ settings.", @""), SEBShortAppName]];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
        [alert beginSheetModalForWindow:MBPreferencesController.sharedController.window completionHandler:nil];
        return;
    }

    // Build a checkbox for each available preset process, listing its title (or executable if no title)
    NSStackView *stackView = [NSStackView new];
    stackView.orientation = NSUserInterfaceLayoutOrientationVertical;
    stackView.alignment = NSLayoutAttributeLeading;
    stackView.spacing = 6;
    stackView.edgeInsets = NSEdgeInsetsMake(6, 6, 6, 6);
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    NSMutableArray<NSButton *> *checkboxes = [NSMutableArray new];
    for (NSUInteger i = 0; i < availablePresets.count; i++) {
        NSDictionary *presetProcess = availablePresets[i];
        NSString *title = presetProcess[@"title"];
        if (title.length == 0) {
            title = presetProcess[@"executable"];
        }
        if (title.length == 0) {
            title = NSLocalizedString(@"(Unnamed process)", @"");
        }
        if (i < clientProcessCount) {
            // Mark processes which originate from the local client settings
            title = [title stringByAppendingString:NSLocalizedString(@" (from client settings)", @"Suffix marking a process offered from the local client settings")];
        }
        NSButton *checkbox = [NSButton checkboxWithTitle:title target:nil action:nil];
        checkbox.translatesAutoresizingMaskIntoConstraints = NO;
        [checkboxes addObject:checkbox];
        [stackView addArrangedSubview:checkbox];
    }

    CGFloat width = 380;
    CGFloat visibleHeight = MIN(stackView.fittingSize.height, 220);
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, width, visibleHeight)];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    scrollView.borderType = NSBezelBorder;
    scrollView.drawsBackground = NO;
    scrollView.documentView = stackView;
    [NSLayoutConstraint activateConstraints:@[
        [stackView.leadingAnchor constraintEqualToAnchor:scrollView.contentView.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:scrollView.contentView.trailingAnchor],
        [stackView.topAnchor constraintEqualToAnchor:scrollView.contentView.topAnchor],
    ]];

    NSString *informativeText;
    if (clientProcessCount > 0) {
        informativeText = [NSString stringWithFormat:NSLocalizedString(@"Select the permitted processes you want to add to your %@ exam settings. The list includes the built-in preset processes and the permitted processes from your local client settings (marked accordingly). They will be added as active processes.", @""), SEBShortAppName];
    } else {
        informativeText = [NSString stringWithFormat:NSLocalizedString(@"Select the preset permitted processes you want to add to your %@ settings. They will be added as active processes.", @""), SEBShortAppName];
    }

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:NSLocalizedString(@"Add Preset Permitted Process", @"")];
    [alert setInformativeText:informativeText];
    [alert addButtonWithTitle:NSLocalizedString(@"Add", @"")];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    alert.accessoryView = scrollView;
    [alert beginSheetModalForWindow:MBPreferencesController.sharedController.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn) {
            for (NSUInteger i = 0; i < availablePresets.count; i++) {
                if (checkboxes[i].state == NSControlStateValueOn) {
                    NSMutableDictionary *newProcess = [availablePresets[i] mutableCopy];
                    [newProcess setValue:@YES forKey:@"active"];
                    [self.permittedProcessesArrayController addObject:newProcess];
                }
            }
        }
    }];
}


// Checks whether a process matching the given preset process (by bundle identifier, or by
// executable name if no identifier is set) already exists for the same OS in the passed array
- (BOOL)permittedProcess:(NSDictionary *)presetProcess existsInProcesses:(NSArray *)processes {
    NSString *identifier = presetProcess[@"identifier"];
    NSString *executable = presetProcess[@"executable"];
    NSInteger os = [presetProcess[@"os"] longValue];
    for (NSDictionary *process in processes) {
        if ([process[@"os"] longValue] != os) {
            continue;
        }
        if (identifier.length > 0) {
            if ([process[@"identifier"] caseInsensitiveCompare:identifier] == NSOrderedSame) {
                return YES;
            }
        } else if (executable.length > 0 &&
                   [process[@"executable"] caseInsensitiveCompare:executable] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}


// Returns YES if the two permitted processes represent the same application: same OS, same bundle
// identifier and same executable name, and — when a team identifier is set on both processes — the
// same team identifier. Used to detect a preset process which is available both as a hardcoded
// preset and (possibly customized) in the local client settings.
- (BOOL)permittedProcess:(NSDictionary *)process isSameAppAs:(NSDictionary *)otherProcess {
    if ([process[@"os"] longValue] != [otherProcess[@"os"] longValue]) {
        return NO;
    }
    NSString *identifier = process[@"identifier"] ?: @"";
    NSString *otherIdentifier = otherProcess[@"identifier"] ?: @"";
    if ([identifier caseInsensitiveCompare:otherIdentifier] != NSOrderedSame) {
        return NO;
    }
    NSString *executable = process[@"executable"] ?: @"";
    NSString *otherExecutable = otherProcess[@"executable"] ?: @"";
    if ([executable caseInsensitiveCompare:otherExecutable] != NSOrderedSame) {
        return NO;
    }
    // Only discriminate by team identifier if it is set on both processes
    NSString *teamIdentifier = process[@"teamIdentifier"] ?: @"";
    NSString *otherTeamIdentifier = otherProcess[@"teamIdentifier"] ?: @"";
    if (teamIdentifier.length > 0 && otherTeamIdentifier.length > 0 &&
        [teamIdentifier caseInsensitiveCompare:otherTeamIdentifier] != NSOrderedSame) {
        return NO;
    }
    return YES;
}


- (IBAction)chooseProhibitedApplication:(id)sender {
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
                          DDLogInfo(@"Selected prohibited app with file URL %@", appURL);
                          [self.prohibitedProcessesArrayController addAppWithBundle:appBundle];
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
    lockdownModePolicy policy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_lockdownModePolicy"];

    BOOL multiAppModeSettings = ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowOpenAndSavePanel"] &&
    ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowShareSheet"] &&
    ((policy == lockdownModePolicyEnforceAAC) &&
    [self checkSettingsForMinMacOSVersionMajor:12 minor:0 patch:0]);
    
    return multiAppModeSettings;
}


- (void)setSettingsForMultiAppMode
{
    // Release preferences window so bindings get synchronized properly with the new loaded values
    [_preferencesController releasePreferencesWindow];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureInteger:lockdownModePolicyEnforceAAC forKey:@"org_safeexambrowser_SEB_lockdownModePolicy"];
    [preferences setSecureBool:NO forKey:@"org_safeexambrowser_SEB_allowOpenAndSavePanel"];
    [preferences setSecureBool:NO forKey:@"org_safeexambrowser_SEB_allowShareSheet"];
    
    if (![self checkSettingsForMinMacOSVersionMajor:12 minor:0 patch:1]) {
        [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberCheckFull"];
        [preferences setSecureInteger:12 forKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberMajor"];
        [preferences setSecureInteger:0 forKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberMinor"];
        [preferences setSecureInteger:0 forKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberPatch"];
    }
    DDLogInfo(@"Settings updated for AAC Multi-App Mode.");
    
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


- (BOOL)settingsRequireMinMacOSVersionMajor:(NSUInteger)majorVersion
                                      minor:(NSUInteger)minorVersion
                                      patch:(NSUInteger)patchVersion
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSUInteger allowMacOSVersionMajor = SEBMinMacOSVersionSupportedMajor;
    NSUInteger allowMacOSVersionMinor = SEBMinMacOSVersionSupportedMinor;
    NSUInteger allowMacOSVersionPatch = SEBMinMacOSVersionSupportedPatch;

    if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberCheckFull"]) {
        SEBMinMacOSVersion minMacOSVersion = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_minMacOSVersion"];
        switch (minMacOSVersion) {
            case SEBMinMacOS10_14:
                allowMacOSVersionMajor = 10; allowMacOSVersionMinor = 14; allowMacOSVersionPatch = 0; break;
            case SEBMinMacOS10_15:
                allowMacOSVersionMajor = 10; allowMacOSVersionMinor = 15; allowMacOSVersionPatch = 0; break;
            case SEBMinMacOS11:
                allowMacOSVersionMajor = 11; allowMacOSVersionMinor = 0; allowMacOSVersionPatch = 0; break;
            case SEBMinMacOS12:
                allowMacOSVersionMajor = 12; allowMacOSVersionMinor = 0; allowMacOSVersionPatch = 0; break;
            case SEBMinMacOS13:
                allowMacOSVersionMajor = 13; allowMacOSVersionMinor = 0; allowMacOSVersionPatch = 0; break;
            case SEBMinMacOS14:
                allowMacOSVersionMajor = 14; allowMacOSVersionMinor = 0; allowMacOSVersionPatch = 0; break;
            case SEBMinMacOS15:
                allowMacOSVersionMajor = 15; allowMacOSVersionMinor = 0; allowMacOSVersionPatch = 0; break;
            default:
                break;
        }
    } else {
        allowMacOSVersionMajor = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberMajor"];
        allowMacOSVersionMinor = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberMinor"];
        allowMacOSVersionPatch = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_allowMacOSVersionNumberPatch"];
    }

    // Clamp to SEB's own minimum supported version
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

    // Return YES if the configured minimum version is >= the requested version
    return (allowMacOSVersionMajor > majorVersion ||
            (allowMacOSVersionMajor == majorVersion && allowMacOSVersionMinor > minorVersion) ||
            (allowMacOSVersionMajor == majorVersion && allowMacOSVersionMinor == minorVersion && allowMacOSVersionPatch >= patchVersion));
}


@end
