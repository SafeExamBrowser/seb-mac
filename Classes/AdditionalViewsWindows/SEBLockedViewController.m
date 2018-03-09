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

#import "SEBLockedViewController.h"

@interface SEBLockedViewController() {
    
    __weak IBOutlet SEBTextField *alertMessage;
    __weak IBOutlet NSSecureTextField *lockedAlertPasswordField;
    __weak IBOutlet NSTextField *passwordWrongLabel;
    __weak IBOutlet NSScrollView *logScrollView;
    
}
@end


@implementation SEBLockedViewController


- (void)setLockdownAlertMessage:(NSString *)newAlertMessage
{
    if (newAlertMessage.length > 0) {
        alertMessage.stringValue = newAlertMessage;
    } else {
        alertMessage.stringValue = NSLocalizedString(@"SEB is locked because it was attempted to switch the user. SEB can only be unlocked by entering the restart/quit password, which usually exam supervision/support knows.", @"Default lockdown window alert text");
    }
}


- (IBAction)passwordEntered:(id)sender {
    DDLogDebug(@"Lockdown alert: Covering window has frame %@ and window level %ld", CGRectCreateDictionaryRepresentation(self.view.superview.frame), self.view.window.level);

    // Check if restarting is protected with the quit/restart password (and one is set)
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
 
    NSString *password = lockedAlertPasswordField.stringValue;
//    DDLogDebug(@"Lockdown alert user entered password: %@, compare it with hashed quit password %@", password, hashedQuitPassword);
    
    if (!self.keychainManager) {
        self.keychainManager = [[SEBKeychainManager alloc] init];
    }
    if (hashedQuitPassword.length == 0 || [hashedQuitPassword caseInsensitiveCompare:[self.keychainManager generateSHAHashString:password]] == NSOrderedSame) {
        [lockedAlertPasswordField setStringValue:@""];
        [passwordWrongLabel setHidden:true];

        // Add log information about closing lockdown alert
        DDLogError(@"Lockdown alert: Correct password entered, closing lockdown windows");
        self.sebController.didResumeExamTime = [NSDate date];
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Correct password entered, closing lockdown windows", nil)] withTime:self.sebController.didResumeExamTime];
        if (self.overrideSecurityCheck.state == true) {
            [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Overriding security check is enabled!", nil)] withTime:nil];
        }
        // Calculate time difference between session resigning active and closing lockdown alert
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [calendar components:NSMinuteCalendarUnit | NSSecondCalendarUnit
                                                   fromDate:self.sebController.didResignActiveTime
                                                     toDate:self.sebController.didResumeExamTime
                                                    options:false];
        
        DDLogError(@"Lockdown alert: Correct password entered, closing lockdown windows");
        NSString *lockedTimeInfo = [NSString stringWithFormat:NSLocalizedString(@"SEB was locked (exam interrupted) for %ld:%.2ld (minutes:seconds)", nil), components.minute, components.second];
        DDLogError(@"Lockdown alert: %@", lockedTimeInfo);
        [self appendErrorString:[NSString stringWithFormat:@"  %@\n", lockedTimeInfo] withTime:nil];

        [self.sebController closeLockdownWindows];
        [self.sebController openInfoHUD:lockedTimeInfo];
        return;
    }
    DDLogError(@"Lockdown alert: Wrong quit/restart password entered, asking to try again");
    [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Wrong password entered!", nil)] withTime:[NSDate date]];
    [lockedAlertPasswordField setStringValue:@""];
    passwordWrongLabel.hidden = false;
}


- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime {
    NSMutableAttributedString *logString = [self.resignActiveLogString mutableCopy];
    if (errorTime) {
        NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
        [timeFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss "];
        NSString *theTime = [timeFormat stringFromDate:errorTime];
        NSAttributedString *attributedTimeString = [[NSAttributedString alloc] initWithString:theTime];
        [logString appendAttributedString:attributedTimeString];
    }
    NSMutableAttributedString *attributedErrorString = [[NSMutableAttributedString alloc] initWithString:errorString];
    [attributedErrorString setAttributes:@{NSFontAttributeName:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]]} range:NSMakeRange(0, attributedErrorString.length)];
    [logString appendAttributedString:attributedErrorString];
    
    [self setResignActiveLogString:[logString copy]];
    
    [self scrollToBottom];
}


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

@end
