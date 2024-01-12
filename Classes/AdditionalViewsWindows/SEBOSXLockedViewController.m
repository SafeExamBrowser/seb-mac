//
//  SEBLockedView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/09/15.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBOSXLockedViewController.h"

@implementation SEBOSXLockedViewController


- (void)awakeFromNib
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    // viewBoundsDidChange catches scrolling that happens when the caret
    // moves, and scrolling caused by pressing the scrollbar arrows.
    [notificationCenter addObserver:self
    selector:@selector(viewBoundsDidChangeNotification:)
        name:NSViewBoundsDidChangeNotification object:logScrollView];
    [self.view setPostsBoundsChangedNotifications:YES];

    // viewFrameDidChange catches scrolling that happens because text
    // is inserted or deleted.
    // it also catches situations, where window resizing causes changes.
    [notificationCenter addObserver:self
        selector:@selector(viewFrameDidChangeNotification:)
        name:NSViewFrameDidChangeNotification object:logScrollView.documentView];
    [logScrollView.documentView setPostsFrameChangedNotifications:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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


- (SEBLockedViewController*)lockedViewController
{
    if (!_lockedViewController) {
        _lockedViewController = [[SEBLockedViewController alloc] init];
        _lockedViewController.controllerDelegate = _sebController;
        _lockedViewController.UIDelegate = self;
        _lockedViewController.boldFontAttributes = @{NSFontAttributeName:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]]};
    }
    return _lockedViewController;
}


// Manage locking SEB if it is attempted to resume an unfinished exam

- (void)addLockedExam:(NSString *)examURLString configKey:(NSData *)configKey
{
    [self.lockedViewController addLockedExam:examURLString configKey:configKey];
}

- (void)removeLockedExam:(NSString *)examURLString configKey:(NSData *)configKey;
{
    [self.lockedViewController removeLockedExam:examURLString configKey:configKey];
}


- (BOOL) isStartingLockedExam:(NSString *)examURLString configKey:(NSData *)configKey
{
    return [self.lockedViewController isStartingLockedExam:examURLString configKey:configKey];
}

- (void)shouldCloseLockdownWindows {
#ifdef DEBUG
    DDLogInfo(@"%s, self.lockedViewController %@", __FUNCTION__, self.lockedViewController);
#endif
    if (self.quitInsteadUnlockingButton.state == NO && _sebController.noRequiredBuiltInScreenAvailable && self.overrideEnforcingBuiltinScreen.state == NO) {
        DDLogInfo(@"Quit/Unlock password entered in lockscreen, but a required built-in screen is not available and the override button was not selected: Don't close lockscreen.");
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Required built-in display is still not available!", @"")] withTime:nil];
        [self.lockedViewController abortClosingLockdownWindows];
        return;
    }
    [self.lockedViewController closeLockdownWindows];
}

- (float)distanceToBottom
{
    NSRect  visRect;
    NSRect  boundsRect;
    visRect = [logScrollView.documentView visibleRect];
    boundsRect = [logScrollView.documentView bounds];
    return (NSMaxY(visRect) - NSMaxY(boundsRect));
}


/// Forward calls to lockview business logic

- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime
{
    wasAtBottom = [self distanceToBottom] == 0;
    [self.lockedViewController appendErrorString:errorString withTime:errorTime];
}


- (void)setResignActiveLogString:(NSAttributedString *)resignActiveLogString logStringToAppend:(NSAttributedString *)logStringToAppend
{
    [logTextView.textContainer.textView.textStorage appendAttributedString:logStringToAppend];
}

- (void)setResignActiveLogString:(NSAttributedString *)resignActiveLogString
{
    [logTextView.textContainer.textView.textStorage setAttributedString:resignActiveLogString];
}

- (NSAttributedString *)resignActiveLogString {
    return logTextView.textContainer.textView.textStorage.copy;
}


- (IBAction)retryButtonPressed:(id)sender {
    [self.lockedViewController retryButtonPressed];
}


- (IBAction)passwordEntered:(id)sender {
    DDLogInfo(@"Password entered in lock view alert");
    DDLogVerbose(@"Lockdown alert: Covering window has frame %@ and window level %ld",
               (NSDictionary *)CFBridgingRelease(CGRectCreateDictionaryRepresentation(self.view.superview.frame)),
               self.view.window.level);
    [self.lockedViewController passwordEntered];
}


- (IBAction)quitOnlyButtonPressed:(id)sender {
    [_sebController requestedExit:nil];
}


/// Platform specific setup for lockview

- (void)setLockdownAlertTitle:(NSString *)newAlertTitle
                      Message:(NSString *)newAlertMessage
{
    newAlertMessage = [self.lockedViewController appendChallengeToMessage:newAlertMessage];
    self.lockedViewController.currentAlertTitle = newAlertTitle;
    self.lockedViewController.currentAlertMessage = newAlertMessage;
    alertTitle.stringValue = newAlertTitle;
    alertMessage.stringValue = newAlertMessage;
    DDLogError(@"%s: %@: %@", __FUNCTION__, newAlertTitle, newAlertMessage);
}


#pragma mark Delegates

- (void)viewBoundsDidChangeNotification:(NSNotification *)aNotification
{
    [self handleScrollToBottom];
}

- (void)viewFrameDidChangeNotification:(NSNotification *)aNotification
{
    [self handleScrollToBottom];
}

- (void)handleScrollToBottom
{
    if (scrollToBottomPending) {
        scrollToBottomPending = NO;
        [self performScrollToBottom];
    }
}

- (void)performScrollToBottom
{
    if (@available(macOS 10.14, *)) {
        [logScrollView.documentView scrollToEndOfDocument:self];
    } else {
        [logTextView.textContainer.textView scrollRangeToVisible:NSMakeRange(logTextView.textContainer.textView.attributedString.length, 0)];
    }
}

- (void)scrollToBottom
{
    if (wasAtBottom) {
        scrollToBottomPending = YES;
    }
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

- (void) lockdownWindowsWillClose
{
    // Check for status of individual parameters
    if (self.overrideCheckForScreenSharing.state == true) {
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Detecting screen sharing was disabled!", @"")] withTime:nil];
    }
    
    if (self.overrideCheckForSiri.state == true) {
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Detecting Siri was disabled!", @"")] withTime:nil];
    }
    
    if (self.overrideCheckForDictation.state == true) {
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Detecting dictation was disabled!", @"")] withTime:nil];
    }
    
    if (self.overrideCheckForSpecifcProcesses.state == true) {
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Detecting the processes listed above was disabled!", @"")] withTime:nil];
    }
    
    if (self.overrideCheckForAllProcesses.state == true) {
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Detecting processes was completely disabled!", @"")] withTime:nil];
    }
    
    if (self.overrideEnforcingBuiltinScreen.state == true) {
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Overriding required built-in display was enabled!", @"")] withTime:nil];
    }
}

@end
