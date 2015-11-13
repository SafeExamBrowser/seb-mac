//
//  SEBLockedView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/09/15.
//
//

#import "SEBLockedViewController.h"

@interface SEBLockedViewController() {
    
    __weak IBOutlet NSSecureTextField *lockedAlertPasswordField;
    __weak IBOutlet NSTextField *passwordWrongLabel;
    __weak IBOutlet NSScrollView *logScrollView;

}
@end


@implementation SEBLockedViewController



- (IBAction)passwordEntered:(id)sender {
    DDLogDebug(@"Lockdown alert: Covering window has frame %@ and window level %ld", CGRectCreateDictionaryRepresentation(self.view.superview.frame), self.view.window.level);

    // Check if restarting is protected with the quit/restart password (and one is set)
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    //NSString *screensLockedText = NSLocalizedString(@"SEB is locked because a user switch was attempted. It's only possible to unlock SEB with the restart/quit password, which usually exam supervision/support knows.", nil);

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
