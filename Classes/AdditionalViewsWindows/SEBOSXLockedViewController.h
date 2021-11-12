//
//  SEBLockedView.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/09/15.
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

#import <Cocoa/Cocoa.h>
#import "SEBController.h"
#import "SEBLockedViewController.h"
#import "SEBTextField.h"

@class SEBController;
@class SEBLockedViewController;

@interface SEBOSXLockedViewController : NSViewController <SEBLockedViewUIDelegate> {

    SEBController *_sebController;
    
    __weak IBOutlet SEBTextField *alertTitle;
    __weak IBOutlet SEBTextField *alertMessage;
    __unsafe_unretained IBOutlet NSTextView *logTextView;
    __weak IBOutlet NSSecureTextField *lockedAlertPasswordField;
    __weak IBOutlet NSTextField *passwordWrongLabel;
    __weak IBOutlet NSScrollView *logScrollView;
}

@property (strong, nonatomic) SEBLockedViewController *lockedViewController;
@property (strong, nonatomic) SEBController *sebController;
@property (readwrite, copy) NSAttributedString *resignActiveLogString;

@property (weak) IBOutlet NSButton *retryButton;

@property (weak) IBOutlet NSButton *quitInsteadUnlockingButton;
@property (weak) IBOutlet NSButton *overrideCheckForScreenSharing;
@property (weak) IBOutlet NSButton *overrideEnforcingBuiltinScreen;
@property (weak) IBOutlet NSButton *overrideCheckForSiri;
@property (weak) IBOutlet NSButton *overrideCheckForDictation;
@property (weak) IBOutlet NSButton *overrideCheckForSpecifcProcesses;
@property (weak) IBOutlet NSButton *overrideCheckForAllProcesses;

- (void)setLockdownAlertTitle:(NSString *)newAlertTitle
                      Message:(NSString *)newAlertMessage;
- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime;

- (void) addLockedExam:(NSString *)examURLString;
- (void) removeLockedExam:(NSString *)examURLString;

- (BOOL) isStartingLockedExam:(NSString *)examURLString;
- (void) shouldCloseLockdownWindows;

@end
