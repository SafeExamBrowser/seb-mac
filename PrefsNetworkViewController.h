//
//  PrefsNetworkViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 12.02.13.
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

// Preferences Network Pane
// Network/Internet settings like URL white/blacklists, certificates and proxy settings

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"
#import "DropDownButton.h"

@interface PrefsNetworkViewController : NSViewController <MBPreferencesModule> {

	IBOutlet NSTableColumn *groupRowTableColumn;
    IBOutlet NSTreeController *treeController;
	IBOutlet DropDownButton *dropDownButton;

    // Certificates section
    IBOutlet NSPopUpButton *chooseCertificate;
    IBOutlet NSPopUpButton *chooseIdentity;
    IBOutlet NSArrayController *certificatesArrayController;

}

@property(strong) NSTableColumn *groupRowTableColumn;

@property (strong, nonatomic) NSMutableArray *certificatesNames;
@property (strong, nonatomic) NSArray *certificates;
@property (strong, nonatomic) NSMutableArray *identitiesNames;
@property (strong, nonatomic) NSArray *identities;


- (NSString *)identifier;
- (NSImage *)image;

- (IBAction) dropDownAction:(id)sender;
- (IBAction) addRuleItem:(id)sender;

// Certificates section
- (IBAction) identitySelected:(id)sender;
- (IBAction) certificateSelected:(id)sender;


@end
