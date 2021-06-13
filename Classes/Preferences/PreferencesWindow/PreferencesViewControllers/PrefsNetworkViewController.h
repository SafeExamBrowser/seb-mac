//
//  PrefsNetworkViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 12.02.13.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences Network Pane
// Network/Internet settings like URL white/blacklists, certificates and proxy settings

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"

@interface PrefsNetworkViewController : NSViewController <MBPreferencesModule, NSTableViewDelegate> {

    IBOutlet NSTabView *networkTabView;
    IBOutlet NSTabViewItem *urlFilterTab;
    IBOutlet NSMatrix *URLFilterMessageControl;
    
	IBOutlet NSTableColumn *groupRowTableColumn;

    // Filter Section
    IBOutlet NSButton *URLFilterEnableContentFilterButton;
    IBOutlet NSTextField *selectedExpression;
    IBOutlet NSTextField *scheme;
    IBOutlet NSTextField *user;
    IBOutlet NSTextField *password;
    IBOutlet NSTextField *host;
    IBOutlet NSTextField *port;
    IBOutlet NSTextField *path;
    IBOutlet NSTextField *query;
    IBOutlet NSTextField *fragment;
    IBOutlet NSArrayController *filterArrayController;
    __weak IBOutlet NSTableView *filterTableView;

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

@property (strong) NSString *expressionPort;
@property (readwrite) BOOL URLFilterLearningMode;


- (NSString *)identifier;
- (NSImage *)image;

// Filter Section
- (IBAction) updateExpressionFromParts:(NSTextField *)sender;
- (IBAction) addExpression:(id)sender;
- (BOOL) URLFilterLearningMode;
- (void) setURLFilterLearningMode:(BOOL)learningMode;

// Certificates section
- (IBAction) identitySelected:(id)sender;
- (IBAction) certificateSelected:(id)sender;


@end
