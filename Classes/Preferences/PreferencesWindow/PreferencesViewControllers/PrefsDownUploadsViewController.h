//
//  PrefsDownUploadsViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 18.04.11.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences Advanced Pane
// Settings use of third party applications together with SEB

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"

@interface PrefsDownUploadsViewController : NSViewController <MBPreferencesModule> {

    __weak IBOutlet NSButton *allowDownloadsButton;
    __weak IBOutlet NSPopUpButton *chooseDownloadDirectory;
    __weak IBOutlet NSButton *openDownloadsButton;
    __weak IBOutlet NSButton *allowCustomDownUploadDirectoryButton;
    __weak IBOutlet NSButton *useTemporaryDownUploadDirectoryButton;
    __weak IBOutlet NSMenuItem *downloadDirectory;
    __weak IBOutlet NSTextField *downloadDirectoryWin;
    __weak IBOutlet NSButton *downloadPDFFilesButton;
    __weak IBOutlet NSButton *allowPDFPlugInButton;
    __weak IBOutlet NSButton *allowUploadsButton;
    __weak IBOutlet NSPopUpButton *chooseFileToUploadPolicyControl;
}

- (NSString *)identifier;
- (NSImage *)image;

- (void) setDownloadDirectory;

- (IBAction) chooseDirectory:(id)sender;


@end
