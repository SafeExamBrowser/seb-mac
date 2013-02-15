//
//  SEBController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 15.02.13.
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
    [self setDownloadDirectory];
    
}


//  
- (void) setDownloadDirectory {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
	//NSMenuItem *downloadDirectory = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
    NSString *downloadPath = [preferences secureStringForKey:@"org_safeexambrowser_SEB_downloadDirectoryOSX"];
    if (!downloadPath) {
        //if there's no path saved in preferences, set standard path
        downloadPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Downloads"];
        [preferences setSecureObject:downloadPath forKey:@"org_safeexambrowser_SEB_downloadDirectoryOSX"];
    }    
    // display the download directory path in the menu
    [downloadDirectory setTitle:[[NSFileManager defaultManager] displayNameAtPath:downloadPath]];
    [downloadDirectory setImage:[[NSWorkspace sharedWorkspace] iconForFile:downloadPath]];
    [chooseDownloadDirectory selectItemAtIndex:0];
    [chooseDownloadDirectory synchronizeTitleAndSelectedItem];
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
                              [preferences setSecureObject:fileName forKey:@"org_safeexambrowser_SEB_downloadDirectoryOSX"];
                              [self setDownloadDirectory];
                          } else {
                              [chooseDownloadDirectory selectItemAtIndex:0];
                              [chooseDownloadDirectory synchronizeTitleAndSelectedItem];
                          }
                      }];
}


@end
