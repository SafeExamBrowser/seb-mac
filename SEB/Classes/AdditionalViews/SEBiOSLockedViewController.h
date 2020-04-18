//
//  SEBiOSLockedViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03/12/15.
//  Copyright (c) 2010-2020 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2020 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <UIKit/UIKit.h>
#import "SEBLockedViewController.h"
#import "SEBViewController.h"

@class SEBViewController;
@class SEBLockedViewController;

@interface SEBiOSLockedViewController : UIViewController <SEBLockedViewUIDelegate> {
    
    SEBViewController *_sebViewController;

    __weak IBOutlet UILabel *alertTitle;
    __weak IBOutlet UILabel *alertMessage;
    __weak IBOutlet UITextField *lockedAlertPasswordField;
    __weak IBOutlet UILabel *passwordWrongLabel;
    __weak IBOutlet UITextView *logTextView;
    
}

@property (nonatomic, strong) SEBViewController *sebViewController;
@property (nonatomic, strong) SEBLockedViewController *lockedViewController;
@property (readwrite, copy) NSAttributedString *resignActiveLogString;

- (void)setLockdownAlertTitle:(NSString *)newAlertTitle
                      Message:(NSString *)newAlertMessage;
- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime;

- (void) scrollToBottom;

- (void) addLockedExam:(NSString *)examURLString;
- (void) removeLockedExam:(NSString *)examURLString;

- (BOOL) isStartingLockedExam;
- (void) shouldCloseLockdownWindows;

@end
