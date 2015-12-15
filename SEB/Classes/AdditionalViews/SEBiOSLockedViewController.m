//
//  SEBiOSLockedViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03/12/15.
//  Copyright (c) 2010-2015 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2015 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBiOSLockedViewController.h"

@interface SEBiOSLockedViewController() {
    
    __weak IBOutlet UITextField *lockedAlertPasswordField;
    __weak IBOutlet UILabel *passwordWrongLabel;
    __weak IBOutlet UITextView *logTextView;
    
}
@end

@implementation SEBiOSLockedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lockedViewController = [[SEBLockedViewController alloc] init];
    self.lockedViewController.UIDelegate = self;
    self.lockedViewController.controllerDelegate = self.controllerDelegate;
    
    self.lockedViewController.boldFontAttributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]};
    
    [lockedAlertPasswordField addTarget:lockedAlertPasswordField
                  action:@selector(resignFirstResponder)
        forControlEvents:UIControlEventEditingDidEndOnExit];
}


- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime {
    [self.lockedViewController appendErrorString:errorString withTime:errorTime];
}


- (void)scrollToBottom
{
    [logTextView scrollRangeToVisible:NSMakeRange([logTextView.text length], 0)];
}


- (IBAction)passwordEntered:(id)sender {
    [self.lockedViewController passwordEntered:sender];
}


- (void) shouldCloseLockdownWindows {
    [self.lockedViewController shouldCloseLockdownWindows];
}


#pragma mark Delegates

- (void) closeLockdownWindows {
    
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}


- (NSString *)lockedAlertPassword {
    return lockedAlertPasswordField.text;
}


- (void)setLockedAlertPassword:(NSString *)password {
    lockedAlertPasswordField.text = password;
}


- (void)setPasswordWrongLabelHidden:(BOOL)hidden {
    passwordWrongLabel.hidden = hidden;
}


- (void)setResignActiveLogString:(NSAttributedString *)resignActiveLogString {
    logTextView.attributedText = resignActiveLogString;
}

- (NSAttributedString *)resignActiveLogString {
    return logTextView.attributedText;
}


@end
