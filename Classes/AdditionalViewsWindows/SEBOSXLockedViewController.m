//
//  SEBLockedView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/09/15.
//  Copyright (c) 2010-2018 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2018 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBOSXLockedViewController.h"

@interface SEBOSXLockedViewController() {
    
    __weak IBOutlet SEBTextField *alertTitle;
    __weak IBOutlet SEBTextField *alertMessage;
    __unsafe_unretained IBOutlet NSTextView *logTextView;
    __weak IBOutlet NSSecureTextField *lockedAlertPasswordField;
    __weak IBOutlet NSTextField *passwordWrongLabel;
    __weak IBOutlet NSScrollView *logScrollView;
    
}
@end


@implementation SEBOSXLockedViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lockedViewController = [[SEBLockedViewController alloc] init];
    self.lockedViewController.UIDelegate = self;
    
    self.lockedViewController.boldFontAttributes = @{NSFontAttributeName:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]]};
}

- (SEBController *)sebController
{
    return _sebController;
}

- (void)setSebController:(SEBController *)sebController
{
    _sebController = sebController;
    self.lockedViewController.controllerDelegate = sebController;
}

// Manage locking SEB if it is attempted to resume an unfinished exam

- (void) addLockedExam:(NSString *)examURLString
{
    [self.lockedViewController addLockedExam:examURLString];
}

- (void) removeLockedExam:(NSString *)examURLString;
{
    [self.lockedViewController removeLockedExam:examURLString];
}


- (BOOL) shouldOpenLockdownWindows {
    return [self.lockedViewController shouldOpenLockdownWindows];
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
    DDLogDebug(@"Lockdown alert: Covering window has frame %@ and window level %ld", CGRectCreateDictionaryRepresentation(self.view.superview.frame), self.view.window.level);
    [self.lockedViewController passwordEntered];
}


/// Platform specific setup for lockview

- (void)setLockdownAlertTitle:(NSString *)newAlertTitle
                      Message:(NSString *)newAlertMessage
{
    alertTitle.stringValue = newAlertTitle;
    alertMessage.stringValue = newAlertMessage;
}


#pragma mark Delegates

- (void)scrollToBottom
{
    NSPoint newScrollOrigin;
    
    if ([[logScrollView documentView] isFlipped]) {
        newScrollOrigin = NSMakePoint(0.0,NSMaxY([[logScrollView documentView] frame])
                                      -NSHeight([[logScrollView contentView] bounds]));
    } else {
        newScrollOrigin = NSMakePoint(0.0,0.0);
    }
    DDLogDebug(@"Log scroll view frame: %@, y coordinate to scroll to: %f", CGRectCreateDictionaryRepresentation([[logScrollView documentView] frame]), newScrollOrigin.y);

    [[logScrollView documentView] scrollPoint:newScrollOrigin];
}


- (NSString *)lockedAlertPassword {
    return lockedAlertPasswordField.stringValue;
}


- (void)setLockedAlertPassword:(NSString *)password {
    lockedAlertPasswordField.stringValue = password;
}


- (void)setPasswordWrongLabelHidden:(BOOL)hidden {
    passwordWrongLabel.hidden = hidden;
}

- (void) lockdownWindowsWillClose;
{
    // Check for status of individual parameters
    if (self.overrideCheckForScreenSharing.state == true) {
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Detecting screen sharing was disabled!", nil)] withTime:nil];
    }
    
    if (self.overrideCheckForSiri.state == true) {
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Detecting Siri was disabled!", nil)] withTime:nil];
    }
    
    if (self.overrideCheckForDictation.state == true) {
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Detecting dictation was disabled!", nil)] withTime:nil];
    }
    
    if (self.overrideCheckForSpecifcProcesses.state == true) {
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Detecting the processes listed above was disabled!", nil)] withTime:nil];
    }
    
    if (self.overrideCheckForAllProcesses.state == true) {
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Detecting processes was completely disabled!", nil)] withTime:nil];
    }
}

@end
