//
//  PrefsSecurityViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 15.02.13.
//  Copyright (c) 2010-2018 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2018 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences Security Pane

#import "PrefsSecurityViewController.h"

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
    
}


// Before displaying pane set the download directory
- (void)willBeDisplayed
{
    [self setLogDirectory];
    
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
- (IBAction) setEnableLogging:(NSButton *)sender
{
    BOOL loggingEnabled = sender.state;
    
    chooseLogLevelControl.enabled = loggingEnabled;
    chooseLogDirectoryControl.enabled = loggingEnabled;
    selectStandardDirectoryButton.enabled = loggingEnabled;
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) setEnableAllowUserAppFolderInstall:(NSButton *)sender
{
    allowUserAppFolderInstallButton.enabled = sender.state;
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
    [openFilePanel beginSheetModalForWindow:[MBPreferencesController sharedController].window
                      completionHandler:^(NSInteger result) {
                          if (result == NSFileHandlingPanelOKButton) {
                              // Get an array containing the full filenames of all
                              // files and directories selected.
                              NSArray* files = [openFilePanel URLs];
                              NSString* fileName = [[files objectAtIndex:0] path];
                              NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
                              [preferences setSecureObject:[fileName stringByAbbreviatingWithTildeInPath] forKey:@"org_safeexambrowser_SEB_logDirectoryOSX"];
                              [self setLogDirectory];
                          } else {
                              [chooseLogDirectoryControl selectItemAtIndex:0];
                              [chooseLogDirectoryControl synchronizeTitleAndSelectedItem];
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


@end
