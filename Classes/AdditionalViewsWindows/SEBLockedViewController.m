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
        DDLogDebug(@"Lockdown alert: User entered correct password, closing lockdown windows");
        [lockedAlertPasswordField setStringValue:@""];
        [passwordWrongLabel setHidden:true];
        [self.view removeFromSuperview];
        [self.sebController closeLockdownWindows];
        return;
    }
    DDLogError(@"Lockdown alert: Wrong quit/restart password entred, asking to try again");
    [self appendErrorString:NSLocalizedString(@"Wrong password entered!\n", nil) withTime:[NSDate date]];
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
}


@end
