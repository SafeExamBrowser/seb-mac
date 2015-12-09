//
//  SEBLockedViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03/12/15.
//
//

#import "SEBLockedViewController.h"

@implementation SEBLockedViewController


- (void)passwordEntered:(id)sender {
    // Check if restarting is protected with the quit/restart password (and one is set)
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedQuitPassword = @"155290511d5c4bfb1369217d6846c8eef1ed6a564579516eaf36cf5598ac92de"; //[preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
    //NSString *screensLockedText = NSLocalizedString(@"SEB is locked because a user switch was attempted. It's only possible to unlock SEB with the restart/quit password, which usually exam supervision/support knows.", nil);
    
    NSString *password = [self.UIDelegate lockedAlertPassword];
    //    DDLogDebug(@"Lockdown alert user entered password: %@, compare it with hashed quit password %@", password, hashedQuitPassword);
    
//    if (!self.keychainManager) {
//        self.keychainManager = [[SEBKeychainManager alloc] init];
//    }
    if (hashedQuitPassword.length == 0 || [hashedQuitPassword caseInsensitiveCompare:[self generateSHAHashString:password]] == NSOrderedSame) {
        [self.UIDelegate setLockedAlertPassword:@""];
        [self.UIDelegate setPasswordWrongLabelHidden:true];

        // Add log string for becoming active
        self.controllerDelegate.didBecomeActiveTime = [NSDate date];
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Guided  Access switched on again", nil)]
                       withTime:self.controllerDelegate.didBecomeActiveTime];

        // Add log information about closing lockdown alert
        DDLogError(@"Lockdown alert: Correct password entered, closing lockdown windows");
        self.controllerDelegate.didResumeExamTime = [NSDate date];
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Correct password entered, closing lockdown windows", nil)] withTime:self.controllerDelegate.didResumeExamTime];
        // Calculate time difference between session resigning active and closing lockdown alert
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [calendar components:NSCalendarUnitMinute | NSCalendarUnitSecond
                                                   fromDate:self.controllerDelegate.didResignActiveTime
                                                     toDate:self.controllerDelegate.didResumeExamTime
                                                    options:false];
        
        DDLogError(@"Lockdown alert: Correct password entered, closing lockdown windows");
        NSString *lockedTimeInfo = [NSString stringWithFormat:NSLocalizedString(@"SEB was locked (exam interrupted) for %ld:%.2ld (minutes:seconds)", nil), components.minute, components.second];
        DDLogError(@"Lockdown alert: %@", lockedTimeInfo);
        [self appendErrorString:[NSString stringWithFormat:@"  %@\n", lockedTimeInfo]
                       withTime:nil];
        
        if ([self.UIDelegate respondsToSelector:@selector(closeLockdownWindows)]) {
            [self.UIDelegate closeLockdownWindows];
        }
        if ([self.controllerDelegate respondsToSelector:@selector(closeLockdownWindows)]) {
            [self.controllerDelegate closeLockdownWindows];
        }
        if ([self.controllerDelegate respondsToSelector:@selector(openInfoHUD:)]) {
            [self.controllerDelegate openInfoHUD:lockedTimeInfo];
        }
        return;
    }
    DDLogError(@"Lockdown alert: Wrong quit/restart password entered, asking to try again");
    [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Wrong password entered!", nil)]
                   withTime:[NSDate date]];
    [self.UIDelegate setLockedAlertPassword:@""];
    [self.UIDelegate setPasswordWrongLabelHidden:false];
}


- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime {
    NSMutableAttributedString *logString = [self.UIDelegate.resignActiveLogString mutableCopy];
    if (errorTime) {
        NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
        [timeFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss "];
        NSString *theTime = [timeFormat stringFromDate:errorTime];
        NSAttributedString *attributedTimeString = [[NSAttributedString alloc] initWithString:theTime];
        [logString appendAttributedString:attributedTimeString];
    }
    NSMutableAttributedString *attributedErrorString = [[NSMutableAttributedString alloc] initWithString:errorString];
    
    [attributedErrorString setAttributes:self.boldFontAttributes range:NSMakeRange(0, attributedErrorString.length)];
    [logString appendAttributedString:attributedErrorString];
    
    [self.UIDelegate setResignActiveLogString:[logString copy]];

    [self.UIDelegate scrollToBottom];
}

- (NSString *) generateSHAHashString:(NSString*)inputString {
    unsigned char hashedChars[32];
    CC_SHA256([inputString UTF8String],
              [inputString lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
              hashedChars);
    NSMutableString* hashedString = [[NSMutableString alloc] init];
    for (int i = 0 ; i < 32 ; ++i) {
        [hashedString appendFormat: @"%02x", hashedChars[i]];
    }
    return hashedString;
}

@end
