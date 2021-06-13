//
//  SEBInAppSettingsViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 26.10.18.
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

#import <UIKit/UIKit.h>

#import "IASKAppSettingsViewController.h"
#import "SEBViewController.h"
#import "SEBKeychainManager.h"

@class SEBViewController;

@interface SEBInAppSettingsViewController : UIViewController <IASKSettingsDelegate, UITextViewDelegate> {
}

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;
@property (nonatomic, retain) IBOutlet IASKAppSettingsViewController *tabAppSettingsViewController;
@property (nonatomic, strong) SEBKeychainManager *keychainManager;
@property (nonatomic, weak) SEBViewController *sebViewController;

@property (readwrite) BOOL permanentSettingsChanged;
@property (readwrite) BOOL configModified;

@property (nonatomic, strong) NSMutableArray *configFileIdentitiesNames;
@property (nonatomic, strong) NSMutableArray *configFileIdentitiesCounter;
@property (nonatomic, strong) NSMutableArray *identitiesNames;
@property (nonatomic, strong) NSMutableArray *identitiesCounter;
@property (nonatomic, strong) NSArray *identities;

@property (nonatomic, strong) NSMutableArray *certificatesNames;
@property (nonatomic, strong) NSMutableArray *certificatesCounter;
@property (nonatomic, strong) NSArray *certificates;

@property (nonatomic, strong) NSMutableDictionary *customCells;

@property (nonatomic, strong) NSMutableArray *combinedURLFilterRules;
@property (nonatomic, strong) NSMutableArray *combinedURLFilterRulesCounter;

@property (nonatomic, strong) NSMutableArray *embeddedCertificatesList;
@property (nonatomic, strong) NSMutableArray *embeddedCertificatesListCounter;

- (id)initWithIASKAppSettingsViewController:(IASKAppSettingsViewController *)appSettingsViewController
                          sebViewController:(SEBViewController *)sebViewController;
- (void) selectLatestSettingsIdentity;
- (SecIdentityRef) getSelectedIdentity;
- (NSString *) getSelectedIdentityName;

@end
