//
//  PrefsSecurityViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 15.02.13.
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

// Preferences Security Pane

#import "PrefsSecurityViewController.h"

static NSString * const allowedSEBVersionsKey = @"org_safeexambrowser_SEB_sebAllowedVersions";

@interface PrefsSecurityViewController () <NSTableViewDataSource, NSTableViewDelegate>
{
    // Programmatically created "Allowed SEB Versions" controls.
    NSTableView *allowedSEBVersionsTableView;
    NSMutableArray<NSString *> *allowedSEBVersions;
    BOOL allowedSEBVersionsSectionBuilt;
}
@end

@implementation PrefsSecurityViewController

- (NSString *)title
{
	return NSLocalizedString(@"Security", @"Title of 'Security' preference pane");
}

- (NSString *)identifier
{
	return @"SecurityPane";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"SecurityIcon"];
}


- (void) awakeFromNib
{
    // Add default values (NSNumbers!) to the max displays combo box
    [maxNumberDisplays addItemsWithObjectValues:@[@1, @2, @3]];

    [minMacOSVersionMajor addItemsWithObjectValues:@[@10, @11, @12, @13, @14, @15, @26]];
    [minMacOSVersionMinor addItemsWithObjectValues:@[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9, @10, @11, @12, @13, @14, @15]];
    [minMacOSVersionPatch addItemsWithObjectValues:@[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9]];

    [miniOSVersionMajor addItemsWithObjectValues:@[@12, @13, @14, @15, @16, @17, @18, @26]];
    [miniOSVersionMinor addItemsWithObjectValues:@[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9]];
    [miniOSVersionPatch addItemsWithObjectValues:@[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9]];
    [allowediOSBetaVersion addItemsWithObjectValues:@[@0, [NSNumber numberWithInt:iOSBetaVersion26]]];

    [self buildAllowedSEBVersionsSectionIfNeeded];
}


// Before displaying pane set the download directory
- (void)willBeDisplayed
{
    [self setLogDirectory];
    [self setEnableEnableAAC:self];
    [self loadAllowedSEBVersions];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    [kioskMode selectCellAtRow:2 column:0];

    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_createNewDesktop"]) {
        [kioskMode selectCellAtRow:0 column:0];
        
    } else if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_killExplorerShell"]) {
        [kioskMode selectCellAtRow:1 column:0];
    }
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) setEnableScreenCapture:(NSButton *)sender
{
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) setEnableWindowCapture:(NSButton *)sender
{
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) setEnableLogging:(NSButton *)sender
{
    BOOL loggingEnabled = sender.state;
    
    chooseLogLevelControl.enabled = loggingEnabled;
    chooseLogDirectoryControl.enabled = loggingEnabled;
    selectStandardDirectoryButton.enabled = loggingEnabled;
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction)setEnableEnableAAC:(id)sender
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    lockdownModePolicy policy = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_lockdownModePolicy"];
    BOOL AACDisabled = (policy == lockdownModePolicyEnforceClassic);
    BOOL enforceAAC = (policy == lockdownModePolicyEnforceAAC);

    aacDnsPrePinningButton.enabled = !AACDisabled;
    allowScreenCaptureButton.enabled = !enforceAAC;
    allowWindowCaptureButton.enabled = !enforceAAC;
    blockScreenShotsButton.enabled = !enforceAAC;
    allowScreenSharingButton.enabled = !enforceAAC;
    screenSharingMacEnforceButton.enabled = !enforceAAC;
    enableAppSwitcherButton.enabled = !enforceAAC;
    allowSiriButton.enabled = AACDisabled;
    allowDictationButton.enabled = AACDisabled;
    allowDisplayMirroringButton.enabled = !enforceAAC;

    // The screen proctoring AAC capture policy only applies when screen proctoring
    // is enabled and AAC can actually run (i.e. not in enforced classic kiosk mode).
    BOOL enableScreenProctoring = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableScreenProctoring"];
    BOOL screenProctoringCapturePolicyEnabled = enableScreenProctoring && !AACDisabled;
    screenProctoringAACCapturePolicyButton.enabled = screenProctoringCapturePolicyEnabled;
    screenProctoringAACCapturePolicyLabel.enabled = screenProctoringCapturePolicyEnabled;
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) setEnableAllowUserAppFolderInstall:(NSButton *)sender
{
    allowUserAppFolderInstallButton.enabled = sender.state;
}


- (IBAction) setAllowMacOSVersionNumberCheckFullButton:(NSButton *)sender
{
    minMacOSVersionPopUpButton.enabled = !sender.state;
    minMacOSVersionMajor.enabled = sender.state;
    minMacOSVersionMinor.enabled = sender.state;
    minMacOSVersionPatch.enabled = sender.state;
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) setEnableAllowedDisplayBuiltin:(NSButton *)sender
{
    allowedDisplayBuiltinEnforceButton.hidden = !sender.state;
    allowedDisplayBuiltinExceptDesktopButton.hidden = !sender.state || !allowedDisplayBuiltinEnforceButton.state;
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction)setEnableAllowedDisplayBuiltinEnforced:(NSButton *)sender {
    allowedDisplayBuiltinExceptDesktopButton.hidden = !sender.state;
}


- (void) setLogDirectory {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	//NSMenuItem *downloadDirectory = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    NSString *logPath = [preferences secureStringForKey:@"org_safeexambrowser_SEB_logDirectoryOSX"];
    if (logPath.length == 0) {
        //if there's no path saved in preferences, set empty image for folder icon
        // Clear log directory path in menu
        [logDirectory setTitle:@""];
        [logDirectory setImage:nil];
        selectStandardDirectoryButton.state = NSOnState;
        chooseLogDirectoryControl.enabled = NO;
    } else {
        // display the download directory path in the menu
        [logDirectory setTitle:[[NSFileManager defaultManager] displayNameAtPath:logPath]];
        NSImage *logFolderIcon = [[NSWorkspace sharedWorkspace] iconForFile:[logPath stringByExpandingTildeInPath]];
        [logFolderIcon setSize:NSMakeSize(16, 16)];
        [logDirectory setImage:logFolderIcon];
        selectStandardDirectoryButton.state = NSOffState;
        chooseLogDirectoryControl.enabled = YES;
    }
    [chooseLogDirectoryControl selectItemAtIndex:0];
    [chooseLogDirectoryControl synchronizeTitleAndSelectedItem];
}


- (IBAction) chooseDirectory:(id)sender {
    // Create the File Open Dialog class.
    NSOpenPanel* openFilePanel = [NSOpenPanel openPanel];
    
    // Disable the selection of files in the dialog
    [openFilePanel setCanChooseFiles:NO];
    
    // Enable the selection of directories in the dialog
    [openFilePanel setCanChooseDirectories:YES];
    
    // Change text of the open button in file dialog
    [openFilePanel setPrompt:NSLocalizedString(@"Select",nil)];
    
    // Display the dialog.  If the OK button was pressed,
    // process the files.
    // beginSheetModalForWindow: completionHandler: is available from macOS 10.9,
    // which also is the minimum macOS version the Preferences window is available from
    [openFilePanel beginSheetModalForWindow:[MBPreferencesController sharedController].window
                      completionHandler:^(NSInteger result) {
                          if (result == NSModalResponseOK) {
                              // Get an array containing the full filenames of all
                              // files and directories selected.
                              NSArray* files = [openFilePanel URLs];
                              NSString* fileName = [[files objectAtIndex:0] path];
                              NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
                              [preferences setSecureObject:[fileName stringByAbbreviatingWithTildeInPath] forKey:@"org_safeexambrowser_SEB_logDirectoryOSX"];
                              [self setLogDirectory];
                          } else {
                              [self->chooseLogDirectoryControl selectItemAtIndex:0];
                              [self->chooseLogDirectoryControl synchronizeTitleAndSelectedItem];
                          }
                      }];
}


- (IBAction) selectStandardDirectory:(NSButton *)sender
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if (sender.state) {
        chooseLogDirectoryControl.enabled = NO;
        [preferences setSecureString:@"" forKey:@"org_safeexambrowser_SEB_logDirectoryOSX"];
        // Clear log directory path in menu
        [logDirectory setTitle:@""];
        [logDirectory setImage:nil];
        [chooseLogDirectoryControl selectItemAtIndex:0];
        [chooseLogDirectoryControl synchronizeTitleAndSelectedItem];
    } else {
        chooseLogDirectoryControl.enabled = YES;
        //[self setLogDirectory];
    }
}


- (IBAction) setAllowiOSScreenCapture:(NSButton *)sender {
    enablePrintScreenButton.state = sender.state;
}


- (IBAction) changedKioskMode:(NSMatrix *)sender
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    NSUInteger kioskModeSelectedRow = [sender selectedRow];
    switch (kioskModeSelectedRow) {
        case 0:
            [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_createNewDesktop"];
            [preferences setSecureBool:NO forKey:@"org_safeexambrowser_SEB_killExplorerShell"];
            break;
            
        case 1:
            [preferences setSecureBool:NO forKey:@"org_safeexambrowser_SEB_createNewDesktop"];
            [preferences setSecureBool:YES forKey:@"org_safeexambrowser_SEB_killExplorerShell"];
            break;
            
        case 2:
            [preferences setSecureBool:NO forKey:@"org_safeexambrowser_SEB_createNewDesktop"];
            [preferences setSecureBool:NO forKey:@"org_safeexambrowser_SEB_killExplorerShell"];
            break;
    }
}


- (IBAction)setEnablePrintScreen:(NSButton *)sender {
    allowiOSScreenCaptureButton.state = sender.state;
}


#pragma mark - Allowed SEB Versions

// Builds the "Allowed SEB Versions" section (title, description, editable table
// and add/remove buttons) and appends it to the Security pane's main stack view.
// The section is built once; guard against awakeFromNib being called repeatedly.
- (void)buildAllowedSEBVersionsSectionIfNeeded
{
    if (allowedSEBVersionsSectionBuilt || securitySettingsStackView == nil) {
        return;
    }
    allowedSEBVersionsSectionBuilt = YES;

    NSTextField *titleLabel = [NSTextField labelWithString:[NSString stringWithFormat:NSLocalizedString(@"Allowed %@ Versions", @""), SEBShortAppName]];
    titleLabel.font = [NSFont boldSystemFontOfSize:[NSFont systemFontSize]];

    NSTextField *descriptionLabel = [NSTextField wrappingLabelWithString:[NSString stringWithFormat:NSLocalizedString(@"Specify one or more %@ version(s) required to use this configuration, one per row. Format: OS.Major.Minor.[Patch].[Build].[AE].[min] (OS is Win, Mac or iOS; optional parts in brackets). Example: \"Win.3.9.min\" allows %@ for Windows 3.9 or newer.", @""), SEBShortAppName, SEBShortAppName]];
    descriptionLabel.font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
    descriptionLabel.textColor = [NSColor secondaryLabelColor];
    descriptionLabel.selectable = NO;
    descriptionLabel.preferredMaxLayoutWidth = 460;

    // Cell-based, single-column, editable table view.
    allowedSEBVersionsTableView = [[NSTableView alloc] initWithFrame:NSZeroRect];
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"version"];
    column.editable = YES;
    column.title = [NSString stringWithFormat:NSLocalizedString(@"%@ Version", @""), SEBShortAppName];
    [allowedSEBVersionsTableView addTableColumn:column];
    allowedSEBVersionsTableView.headerView = nil;
    allowedSEBVersionsTableView.usesAlternatingRowBackgroundColors = YES;
    allowedSEBVersionsTableView.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    allowedSEBVersionsTableView.allowsMultipleSelection = YES;
    allowedSEBVersionsTableView.rowHeight = 19;
    allowedSEBVersionsTableView.dataSource = self;
    allowedSEBVersionsTableView.delegate = self;

    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    scrollView.documentView = allowedSEBVersionsTableView;
    scrollView.hasVerticalScroller = YES;
    scrollView.borderType = NSBezelBorder;
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    // Nudge the content down slightly so the first row isn't drawn flush against the top
    // bezel (otherwise it looks shifted up by ~2 pt).
    scrollView.automaticallyAdjustsContentInsets = NO;
    scrollView.contentInsets = NSEdgeInsetsMake(2, 0, 0, 0);
    // Size the visible area to a whole number of rows so the bottom row is never cropped
    // with default macOS 26 metrics. Derived from the actual row height + intercell spacing
    // (plus the content insets) so it stays correct if those change.
    NSInteger visibleRows = 3;
    CGFloat rowUnit = allowedSEBVersionsTableView.rowHeight + allowedSEBVersionsTableView.intercellSpacing.height;
    NSSize contentSize = NSMakeSize(460, rowUnit * visibleRows + scrollView.contentInsets.top + scrollView.contentInsets.bottom);
    NSSize frameSize = [NSScrollView frameSizeForContentSize:contentSize
                                     horizontalScrollerClass:Nil
                                       verticalScrollerClass:Nil
                                                  borderType:scrollView.borderType
                                                 controlSize:NSControlSizeRegular
                                               scrollerStyle:NSScrollerStyleOverlay];
    [scrollView.heightAnchor constraintEqualToConstant:frameSize.height].active = YES;
    [scrollView.widthAnchor constraintEqualToConstant:460].active = YES;

    // Add/remove buttons matching the Network / Filter tab: two shadowless-square
    // NSButtons (22 x 21) with the standard +/- template images, overlapping by 1 pt
    // so their borders merge into a shared middle edge (like there).
    NSButton *addButton = [NSButton buttonWithImage:[NSImage imageNamed:NSImageNameAddTemplate] target:self action:@selector(addAllowedSEBVersion:)];
    NSButton *removeButton = [NSButton buttonWithImage:[NSImage imageNamed:NSImageNameRemoveTemplate] target:self action:@selector(removeAllowedSEBVersion:)];
    addButton.toolTip = NSLocalizedString(@"Add", @"");
    removeButton.toolTip = NSLocalizedString(@"Remove", @"");
    for (NSButton *button in @[addButton, removeButton]) {
        button.bezelStyle = NSBezelStyleShadowlessSquare;
        button.imagePosition = NSImageOnly;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button.widthAnchor constraintEqualToConstant:22].active = YES;
        [button.heightAnchor constraintEqualToConstant:21].active = YES;
    }

    // Overlap the two buttons by 1 pt so their 1 pt borders coincide and they share
    // the middle edge (matches the Network tab). The size constraints are required,
    // so the enclosing vertical stack can't stretch them.
    NSStackView *addRemoveRow = [NSStackView stackViewWithViews:@[addButton, removeButton]];
    addRemoveRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    addRemoveRow.spacing = -1;
    addRemoveRow.translatesAutoresizingMaskIntoConstraints = NO;

    NSStackView *section = [[NSStackView alloc] initWithFrame:NSZeroRect];
    section.orientation = NSUserInterfaceLayoutOrientationVertical;
    section.alignment = NSLayoutAttributeLeading;
    section.spacing = 6;
    section.translatesAutoresizingMaskIntoConstraints = NO;
    [section addArrangedSubview:titleLabel];
    [section addArrangedSubview:descriptionLabel];
    [section addArrangedSubview:scrollView];
    [section addArrangedSubview:addRemoveRow];

    [securitySettingsStackView addArrangedSubview:section];
}


- (void)addAllowedSEBVersion:(id)sender
{
    if (allowedSEBVersions == nil) {
        allowedSEBVersions = [NSMutableArray array];
    }
    [allowedSEBVersions addObject:@""];
    [allowedSEBVersionsTableView reloadData];
    [self saveAllowedSEBVersions];
    NSInteger row = allowedSEBVersions.count - 1;
    [allowedSEBVersionsTableView editColumn:0 row:row withEvent:nil select:YES];
}


- (void)removeAllowedSEBVersion:(id)sender
{
    NSIndexSet *selectedRows = allowedSEBVersionsTableView.selectedRowIndexes;
    if (selectedRows.count == 0) {
        return;
    }
    // Discard any in-progress cell editing first: otherwise ending the edit while
    // removing commits/queries a row index that no longer exists once the model
    // shrinks (which would crash with an out-of-bounds array access).
    [allowedSEBVersionsTableView abortEditing];
    [allowedSEBVersionsTableView.window makeFirstResponder:allowedSEBVersionsTableView];
    // Only remove indexes that are actually within bounds of the model.
    NSMutableIndexSet *rowsToRemove = [selectedRows mutableCopy];
    [rowsToRemove removeIndexesInRange:NSMakeRange(allowedSEBVersions.count, NSUIntegerMax - allowedSEBVersions.count)];
    if (rowsToRemove.count == 0) {
        return;
    }
    [allowedSEBVersions removeObjectsAtIndexes:rowsToRemove];
    [allowedSEBVersionsTableView reloadData];
    [self saveAllowedSEBVersions];
}


- (void)loadAllowedSEBVersions
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSArray<NSString *> *storedVersions = [preferences secureStringArrayForKey:allowedSEBVersionsKey];
    allowedSEBVersions = storedVersions ? [storedVersions mutableCopy] : [NSMutableArray array];
    [allowedSEBVersionsTableView reloadData];
}


- (void)saveAllowedSEBVersions
{
    // Persist only non-empty, trimmed entries so an accidentally added blank row (or
    // a row left empty) is never stored into the settings array.
    NSMutableArray<NSString *> *versionsToStore = [NSMutableArray arrayWithCapacity:allowedSEBVersions.count];
    for (NSString *version in allowedSEBVersions) {
        NSString *trimmed = [version stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) {
            [versionsToStore addObject:trimmed];
        }
    }
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureObject:[versionsToStore copy] forKey:allowedSEBVersionsKey];
}


#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return allowedSEBVersions.count;
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    // Guard against a stale field-editor callback referencing a removed row.
    if (row < 0 || row >= (NSInteger)allowedSEBVersions.count) {
        return @"";
    }
    return allowedSEBVersions[row];
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row < 0 || row >= (NSInteger)allowedSEBVersions.count) {
        return;
    }
    NSString *value = [object isKindOfClass:[NSString class]] ? (NSString *)object : [object description];
    value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    allowedSEBVersions[row] = value ?: @"";
    [self saveAllowedSEBVersions];
    // Empty rows are removed once editing ends (see controlTextDidEndEditing:).
}


// Removes any empty (or whitespace-only) entries from the model and table. Called after
// editing ends so a blank row never lingers — whether the edit was confirmed empty with
// Enter, cancelled with Escape, or ended by clicking away / closing the window. Deferred
// to the next run loop so the table isn't mutated from within the field editor callback.
- (void)removeEmptyAllowedSEBVersionRows
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSIndexSet *emptyRows = [self->allowedSEBVersions indexesOfObjectsPassingTest:^BOOL(NSString *version, NSUInteger idx, BOOL *stop) {
            return [version stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0;
        }];
        if (emptyRows.count == 0) {
            return;
        }
        [self->allowedSEBVersions removeObjectsAtIndexes:emptyRows];
        [self->allowedSEBVersionsTableView reloadData];
        [self saveAllowedSEBVersions];
    });
}


#pragma mark - NSTableViewDelegate

- (void)controlTextDidEndEditing:(NSNotification *)notification
{
    [self removeEmptyAllowedSEBVersionRows];
}


@end
