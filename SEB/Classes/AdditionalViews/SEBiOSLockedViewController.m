//
//  SEBiOSLockedViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03/12/15.
//  Copyright (c) 2010-2019 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2019 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBiOSLockedViewController.h"

@implementation SEBiOSLockedViewController


- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if (parent) {
        // Add the view to the parent view and position it if you want
        [[parent view] addSubview:self.view];
        CGRect viewFrame = parent.view.bounds;
        //viewFrame.origin.y += kNavbarHeight;
        //viewFrame.size.height -= kNavbarHeight;
        [self.view setFrame:viewFrame];
    } else {
        [self.view removeFromSuperview];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _lockedViewController = [[SEBLockedViewController alloc] init];
    _lockedViewController.UIDelegate = self;
    _lockedViewController.controllerDelegate = self.controllerDelegate;
    
    _lockedViewController.boldFontAttributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]};
    
    [lockedAlertPasswordField addTarget:lockedAlertPasswordField
                  action:@selector(resignFirstResponder)
        forControlEvents:UIControlEventEditingDidEndOnExit];
}


- (void)viewDidLayoutSubviews
{
    logTextView.textContainerInset = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0);
}


- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self scrollToBottom];
}


- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime {
    [_lockedViewController appendErrorString:errorString withTime:errorTime];
}


- (void)scrollToBottom
{
    [logTextView scrollRangeToVisible:NSMakeRange([logTextView.text length], 0)];
}


- (IBAction)passwordEntered:(id)sender {
    [_lockedViewController passwordEntered:sender];
}


- (BOOL) shouldOpenLockdownWindows {
    return [_lockedViewController shouldOpenLockdownWindows];
}

- (void) didOpenLockdownWindows {
    [_lockedViewController didOpenLockdownWindows];
}

- (void) shouldCloseLockdownWindows {
    [_lockedViewController closeLockdownWindows];
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
    [logTextView setScrollEnabled:NO];
    logTextView.attributedText = resignActiveLogString;
    [logTextView sizeToFit];
    [logTextView setScrollEnabled:YES];
//    [logTextView resignFirstResponder];
//    [logTextView becomeFirstResponder];
}

- (NSAttributedString *)resignActiveLogString {
    return logTextView.attributedText;
}


@end
