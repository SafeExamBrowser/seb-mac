//
//  SEBLockedView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/09/15.
//
//

#import "SEBLockedView.h"

@interface SEBLockedView() {
    
    __weak IBOutlet NSSecureTextFieldCell *lockedAlertPasswordField;
    __weak IBOutlet NSTextField *passwordWrongLabel;
}
@end


@implementation SEBLockedView



- (IBAction)passwordEntered:(id)sender {
    DDLogDebug(@"Lockdown alert: Covering window has frame %@ and window level %ld", CGRectCreateDictionaryRepresentation(self.superview.frame), self.window.level);

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
        [self removeFromSuperview];
        [self.sebController closeLockdownWindows];
        return;
    }
    [lockedAlertPasswordField setStringValue:@""];
    passwordWrongLabel.hidden = false;
}


@end
