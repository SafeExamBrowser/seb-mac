//
//  SEBLockedViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03/12/15.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBLockedViewController.h"

@interface SEBLockedViewController()
{
    BOOL closingLockdownWindowsInProgress;
}

@end


@implementation SEBLockedViewController


- (BOOL) shouldOpenLockdownWindows
{
    BOOL shouldOpenLockdownWindows = false;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *startURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    NSMutableArray *lockedExams = [NSMutableArray arrayWithArray:[preferences persistedSecureObjectForKey:@"org_safeexambrowser_additionalResources"]];
    if ([[lockedExams valueForKey:@"startURL"] containsObject:startURL]) {
        shouldOpenLockdownWindows = true;
    }
    return shouldOpenLockdownWindows;
}


- (void) didOpenLockdownWindows {
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *startURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    NSMutableArray *lockedExams = [NSMutableArray arrayWithArray:[preferences persistedSecureObjectForKey:@"org_safeexambrowser_additionalResources"]];
    NSAttributedString *logString = self.UIDelegate.resignActiveLogString;
    NSUInteger indexOfLockedExamDictionary = [self getIndexOfLockedExam:lockedExams withStartURL:startURL];
    if (indexOfLockedExamDictionary != NSNotFound) {
        // Append the new log string to the persisted one
        NSDictionary *persistedLockedExam = lockedExams[indexOfLockedExamDictionary];
        NSMutableAttributedString *persistedLogString = [[NSKeyedUnarchiver unarchiveObjectWithData:[persistedLockedExam objectForKey:@"logString"]] mutableCopy];
        [persistedLogString appendAttributedString:logString];
        logString = [persistedLogString copy];
        self.UIDelegate.resignActiveLogString = logString;
        // Remove the old entry for the persisted locked exam
        [lockedExams removeObjectAtIndex:indexOfLockedExamDictionary];
    }
    NSData *logStringArchived = [NSKeyedArchiver archivedDataWithRootObject:logString];
    NSDictionary *interruptedLockedExam = @{
                                            @"startURL" : startURL,
                                            @"logString" : logStringArchived,
                                            };
    [lockedExams addObject:interruptedLockedExam];
    [preferences setPersistedSecureObject:lockedExams forKey:@"org_safeexambrowser_additionalResources"];
}


- (void) addLockedExam:(NSString *)examURLString
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSMutableArray *lockedExams = [NSMutableArray arrayWithArray:[preferences persistedSecureObjectForKey:@"org_safeexambrowser_additionalResources"]];
    NSAttributedString *logString = [self errorStringWithString:[NSString stringWithFormat:@"%@%@\n", NSLocalizedString(@"Started exam with URL ", nil), examURLString] andTime:[NSDate date]];
    NSUInteger indexOfLockedExamDictionary = [self getIndexOfLockedExam:lockedExams withStartURL:examURLString];
    if (indexOfLockedExamDictionary != NSNotFound) {
        // Append the new log string to the persisted one
        NSDictionary *persistedLockedExam = lockedExams[indexOfLockedExamDictionary];
        NSMutableAttributedString *persistedLogString = [[NSKeyedUnarchiver unarchiveObjectWithData:[persistedLockedExam objectForKey:@"logString"]] mutableCopy];
        [persistedLogString appendAttributedString:logString];
        logString = [persistedLogString copy];
        // Remove the old entry for the persisted locked exam
        [lockedExams removeObjectAtIndex:indexOfLockedExamDictionary];
    }
    NSData *logStringArchived = [NSKeyedArchiver archivedDataWithRootObject:logString];
    NSDictionary *interruptedLockedExam = @{
                                            @"startURL" : examURLString,
                                            @"logString" : logStringArchived,
                                            };
    [lockedExams addObject:interruptedLockedExam];
    [preferences setPersistedSecureObject:lockedExams forKey:@"org_safeexambrowser_additionalResources"];
}


- (void) removeLockedExam:(NSString *)examURLString
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSMutableArray *lockedExams = [NSMutableArray arrayWithArray:[preferences persistedSecureObjectForKey:@"org_safeexambrowser_additionalResources"]];
    NSUInteger indexOfLockedExamDictionary = [self getIndexOfLockedExam:lockedExams withStartURL:examURLString];
    if (indexOfLockedExamDictionary != NSNotFound) {
        [lockedExams removeObjectAtIndex:indexOfLockedExamDictionary];
        [preferences setPersistedSecureObject:lockedExams forKey:@"org_safeexambrowser_additionalResources"];
    }
    [self appendErrorString:[NSString stringWithFormat:@"%@%@\n", NSLocalizedString(@"Quit exam with URL ", nil), examURLString]
                   withTime:[NSDate date]];
}

- (void) passwordEntered:(id)sender {
    // Check if restarting is protected with the quit/restart password (and one is set)
    if (!closingLockdownWindowsInProgress) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSString *hashedQuitPassword = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
        
        NSString *password = [self.UIDelegate lockedAlertPassword];
#ifdef DEBUG
        DDLogDebug(@"Lockdown alert user entered password: %@, compare it with hashed quit password %@", password, hashedQuitPassword);
#endif
        if (!self.keychainManager) {
            self.keychainManager = [[SEBKeychainManager alloc] init];
        }
        if (hashedQuitPassword.length == 0 || [hashedQuitPassword caseInsensitiveCompare:[self generateSHAHashString:password]] == NSOrderedSame) {
            // Correct password entered
            closingLockdownWindowsInProgress = true;
            [self.UIDelegate setLockedAlertPassword:@""];
            [self.UIDelegate setPasswordWrongLabelHidden:true];
            
            // Add log string for Correct password entered
            [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Correct password entered", nil)]
                           withTime:[NSDate date]];
            
            self.controllerDelegate.unlockPasswordEntered = true;
            [self.controllerDelegate correctPasswordEntered];
            return;
        }
        DDLogError(@"Lockdown alert: Wrong quit/restart password entered, asking to try again");
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Wrong password entered!", nil)]
                       withTime:[NSDate date]];
        [self.UIDelegate setLockedAlertPassword:@""];
        [self.UIDelegate setPasswordWrongLabelHidden:false];
    }
}


- (void) closeLockdownWindows {
    // Add log information about closing lockdown alert
    DDLogError(@"Lockdown alert: Correct password entered, closing lockdown windows");
    self.controllerDelegate.didResumeExamTime = [NSDate date];
    [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Closing lockdown windows", nil)] withTime:self.controllerDelegate.didResumeExamTime];
    // Calculate time difference between session resigning active and closing lockdown alert
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:NSCalendarUnitMinute | NSCalendarUnitSecond
                                               fromDate:self.controllerDelegate.didResignActiveTime
                                                 toDate:self.controllerDelegate.didResumeExamTime
                                                options:false];
    
    DDLogError(@"Lockdown alert: Closing lockdown windows");
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
    if ([self.controllerDelegate respondsToSelector:@selector(sebLocked)]) {
        self.controllerDelegate.sebLocked = false;
    }
    closingLockdownWindowsInProgress = false;
}


- (NSUInteger) getIndexOfLockedExam:(NSArray *)lockedExams withStartURL:(NSString *)startURL
{
    NSUInteger indexOfLockedExamDictionary = [lockedExams indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([[obj valueForKey:@"startURL"] isEqualToString:startURL]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    return indexOfLockedExamDictionary;
}


- (void) appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime {
    NSMutableAttributedString *logString = [self.UIDelegate.resignActiveLogString mutableCopy];
    if (errorTime) {
        NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
        [timeFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss  "];
        NSString *theTime = [timeFormat stringFromDate:errorTime];
        NSAttributedString *attributedTimeString = [[NSAttributedString alloc] initWithString:theTime];
        [logString appendAttributedString:attributedTimeString];
    }
    NSMutableAttributedString *attributedErrorString = [[NSMutableAttributedString alloc] initWithString:errorString];
    
    [attributedErrorString setAttributes:self.boldFontAttributes range:NSMakeRange(0, attributedErrorString.length)];
    [logString appendAttributedString:attributedErrorString];
    
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *startURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    NSMutableArray *lockedExams = [NSMutableArray arrayWithArray:[preferences persistedSecureObjectForKey:@"org_safeexambrowser_additionalResources"]];
    NSUInteger indexOfLockedExamDictionary = [self getIndexOfLockedExam:lockedExams withStartURL:startURL];
    if (indexOfLockedExamDictionary != NSNotFound) {
        // Persist the new log string
        NSData *logStringArchived = [NSKeyedArchiver archivedDataWithRootObject:logString];
        // Add the new (modified) entry
        NSDictionary *interruptedLockedExam = @{
                                                @"startURL" : startURL,
                                                @"logString" : logStringArchived,
                                                };
        [lockedExams addObject:interruptedLockedExam];
        // Remove the old entry for the persisted locked exam
        NSLog(@"%s: remove locked exam directiory", __FUNCTION__);
        [lockedExams removeObjectAtIndex:indexOfLockedExamDictionary];
        [preferences setPersistedSecureObject:lockedExams forKey:@"org_safeexambrowser_additionalResources"];
    }

    
    [self.UIDelegate setResignActiveLogString:[logString copy]];

    [self.UIDelegate scrollToBottom];
}


- (NSAttributedString *) errorStringWithString:(NSString *)errorString andTime:(NSDate *)errorTime {
    NSMutableAttributedString *logString = [NSMutableAttributedString new];
    if (errorTime) {
        NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
        [timeFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss  "];
        NSString *theTime = [timeFormat stringFromDate:errorTime];
        NSAttributedString *attributedTimeString = [[NSAttributedString alloc] initWithString:theTime];
        [logString appendAttributedString:attributedTimeString];
    }
    NSMutableAttributedString *attributedErrorString = [[NSMutableAttributedString alloc] initWithString:errorString];
    
    [attributedErrorString setAttributes:self.boldFontAttributes range:NSMakeRange(0, attributedErrorString.length)];
    [logString appendAttributedString:attributedErrorString];
    
    return logString;
}


- (NSString *) generateSHAHashString:(NSString*)inputString {
    unsigned char hashedChars[32];
    CC_SHA256([inputString UTF8String],
              (CC_LONG)[inputString lengthOfBytesUsingEncoding:NSUTF8StringEncoding],
              hashedChars);
    NSMutableString* hashedString = [[NSMutableString alloc] init];
    for (int i = 0 ; i < 32 ; ++i) {
        [hashedString appendFormat: @"%02x", hashedChars[i]];
    }
    return hashedString;
}

@end
