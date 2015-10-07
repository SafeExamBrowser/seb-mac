//
//  SEBLockedView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/09/15.
//
//

#import "SEBLockedView.h"
#import "SEBKeychainManager.h"

@interface SEBLockedView() {
    
    __weak IBOutlet NSSecureTextField *lockedAlertPasswordField;
    __weak IBOutlet NSTextField *passwordWrongLabel;
}
@end


@implementation SEBLockedView


- (IBAction)passwordEntered:(id)sender {
    DDLogDebug(@"Lockdown alert covering window has frame %@ and window level %ld", CGRectCreateDictionaryRepresentation(self.superview.frame), self.window.level);

    // Check if restarting is protected with the quit/restart password (and one is set)
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    NSString *screensLockedText = NSLocalizedString(@"SEB is locked because a user switch was attempted. It's only possible to unlock SEB with the restart/quit password, which usually exam supervision/support knows.", nil);

    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamPasswordProtected"] && ![hashedQuitPassword isEqualToString:@""]) {
        NSString *password = lockedAlertPasswordField.stringValue;
        
        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
        if ([hashedQuitPassword caseInsensitiveCompare:[keychainManager generateSHAHashString:password]] == NSOrderedSame) {
            [lockedAlertPasswordField setStringValue:@""];
            [passwordWrongLabel setHidden:true];
            [self.sebController closeLockdownWindows];
            return;
        }
        [lockedAlertPasswordField setStringValue:@""];
        passwordWrongLabel.hidden = false;
        
    }
}


@end
