//
//  SEBiOSLockedViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03/12/15.
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
    
    if (!passwordWrongFont) {
        passwordWrongFont = passwordWrongLabel.font.copy;
    }
    passwordWrongLabel.font = [[UIFontMetrics defaultMetrics] scaledFontForFont:passwordWrongFont];
    
    [lockedAlertPasswordField addTarget:lockedAlertPasswordField
                  action:@selector(resignFirstResponder)
        forControlEvents:UIControlEventEditingDidEndOnExit];
}


- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    logTextView.textContainerInset = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0);
}


- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self scrollToBottom];
}


- (SEBViewController *)sebViewController
{
    return _sebViewController;
}

- (void)setSebViewController:(SEBViewController *)sebViewController
{
    _sebViewController = sebViewController;
    self.lockedViewController.controllerDelegate = sebViewController;
}


- (SEBLockedViewController*)lockedViewController
{
    if (!_lockedViewController) {
        _lockedViewController = [[SEBLockedViewController alloc] init];
        _lockedViewController.UIDelegate = self;
        _lockedViewController.boldFontAttributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]};
    }
    return _lockedViewController;
}


// Manage locking SEB if it is attempted to resume an unfinished exam

- (void) addLockedExam:(NSString *)examURLString configKey:(NSData *)configKey
{
    [self.lockedViewController addLockedExam:examURLString configKey:configKey];
}

- (void) removeLockedExam:(NSString *)examURLString configKey:(NSData *)configKey
{
    [self.lockedViewController removeLockedExam:examURLString configKey:configKey];
}


- (BOOL) isStartingLockedExam:(NSString *)examURLString configKey:(NSData *)configKey
{
    return [self.lockedViewController isStartingLockedExam:examURLString configKey:configKey];
}

- (void) shouldCloseLockdownWindows {
#ifdef DEBUG
    DDLogInfo(@"%s, self.lockedViewController %@", __FUNCTION__, self.lockedViewController);
#endif
    [self.lockedViewController closeLockdownWindows];
}

/// Forward calls to lockview business logic

- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime {
    [self.lockedViewController appendErrorString:errorString withTime:errorTime];
}


- (IBAction)passwordEntered:(id)sender {
    [self.lockedViewController passwordEntered];
}


/// Platform specific setup for lockview

- (void)setLockdownAlertTitle:(NSString *)newAlertTitle
                      Message:(NSString *)newAlertMessage
{
    if (!alertTitleFont) {
        alertTitleFont = alertTitle.font.copy;
    }
    alertTitle.font = [[UIFontMetrics defaultMetrics] scaledFontForFont:alertTitleFont];
    if (newAlertTitle.length > 0) {
        alertTitle.text = newAlertTitle;
    } else {
        alertTitle.text = [NSString stringWithFormat:NSLocalizedString(@"%@ Is Locked!", @"Default title of lock screen alert."), SEBShortAppName];
    }
    if (newAlertMessage.length > 0) {
        alertMessage.text = newAlertMessage;
    } else {
        alertMessage.text = [NSString stringWithFormat:NSLocalizedString(@"Unlock %@ with the quit password, which usually exam supervision/support knows.", @"Default message of lock screen alert."), SEBShortAppName];
    }
}


#pragma mark Delegates

- (void)scrollToBottom
{
    [logTextView scrollRangeToVisible:NSMakeRange([logTextView.text length], 0)];
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


- (void) lockdownWindowsWillClose
{
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}


- (void)setResignActiveLogString:(NSAttributedString *)resignActiveLogString logStringToAppend:(NSAttributedString *)logStringToAppend
{
    [logTextView setScrollEnabled:NO];
    logTextView.attributedText = resignActiveLogString;
    [logTextView sizeToFit];
    [logTextView setScrollEnabled:YES];
//    [logTextView resignFirstResponder];
//    [logTextView becomeFirstResponder];
}

- (void)setResignActiveLogString:(NSAttributedString *)resignActiveLogString
{
    [logTextView setScrollEnabled:NO];
    logTextView.attributedText = resignActiveLogString;
    [logTextView sizeToFit];
    [logTextView setScrollEnabled:YES];
}

- (NSAttributedString *)resignActiveLogString 
{
    return logTextView.attributedText;
}


@end
