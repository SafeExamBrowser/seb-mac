//
//  PrefsSecurityViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 15.02.13.
//  Copyright (c) 2010-2014 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2014 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences Security Pane

#import "PrefsSecurityViewController.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"

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


// Before displaying pane set the download directory
- (void)willBeDisplayed
{
    [self setLogDirectory];
    
}


//  
- (void) setLogDirectory {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	//NSMenuItem *downloadDirectory = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    NSString *logPath = [preferences secureStringForKey:@"org_safeexambrowser_SEB_logDirectoryOSX"];
    if (!logPath) {
        //if there's no path saved in preferences, set standard path
        logPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        [preferences setSecureObject:logPath forKey:@"org_safeexambrowser_SEB_logDirectoryOSX"];
    }    
    // display the download directory path in the menu
    [logDirectory setTitle:[[NSFileManager defaultManager] displayNameAtPath:logPath]];
    [logDirectory setImage:[[NSWorkspace sharedWorkspace] iconForFile:logPath]];
    [chooseLogDirectory selectItemAtIndex:0];
    [chooseLogDirectory synchronizeTitleAndSelectedItem];
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
                              [preferences setSecureObject:fileName forKey:@"org_safeexambrowser_SEB_logDirectoryOSX"];
                              [self setLogDirectory];
                          } else {
                              [chooseLogDirectory selectItemAtIndex:0];
                              [chooseLogDirectory synchronizeTitleAndSelectedItem];
                          }
                      }];
}


@end
