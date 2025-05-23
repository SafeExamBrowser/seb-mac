//
//  SEBLockedViewController.m
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

#import "SEBLockedViewController.h"

@interface SEBLockedViewController()
{
@private
    
    BOOL closingLockdownWindowsInProgress;
}

@end


@implementation SEBLockedViewController


void run_block_on_main_thread(dispatch_block_t block)
{
    if ([NSThread isMainThread])
        block();
    else
        dispatch_sync(dispatch_get_main_queue(), block);
}

/// Manage locking SEB if it is attempted to resume an unfinished exam

- (void) addLockedExam:(NSString *)examURLString configKey:(NSData *)configKey
{
    currentExamURL = examURLString;
    NSString *examInfo;
    if ([[NSUserDefaults standardUserDefaults] secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowShowURL"] >= browserWindowShowURLBeforeTitle) {
        examInfo = [NSString stringWithFormat:@"%@%@\n", NSLocalizedString(@"Secure exam session was started, URL: ", @""), examURLString];
    } else {
        examInfo = [NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Secure session was started", @"")];
    }
    // Append the new string about the started exam and create/update the persisted exam
    [self appendErrorString:examInfo withTime:[NSDate date] configKey:configKey];
    DDLogDebug(@"%s: %@", __FUNCTION__, examInfo);
}


- (void) removeLockedExam:(NSString *)examURLString configKey:(NSData *)configKey
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSMutableArray *lockedExams = [NSMutableArray arrayWithArray:[preferences persistedSecureObjectForKey:@"org_safeexambrowser_additionalResources"]];
    NSUInteger indexOfLockedExamDictionary = [self getIndexOfLockedExam:lockedExams withConfigKey:configKey];
    if (indexOfLockedExamDictionary != NSNotFound) {
        NSString *examInfo = ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowShowURL"] >= browserWindowShowURLBeforeTitle) ? examURLString : @"";
        DDLogDebug(@"%s: Finished exam %@", __FUNCTION__, examInfo);
        [lockedExams removeObjectAtIndex:indexOfLockedExamDictionary];
        [preferences setPersistedSecureObject:lockedExams forKey:@"org_safeexambrowser_additionalResources"];
    }
    currentExamURL = nil;
}

- (NSUInteger) getIndexOfLockedExam:(NSArray *)lockedExams withConfigKey:(NSData *)configKey
{
    NSUInteger indexOfLockedExamDictionary = [lockedExams indexOfObjectPassingTest:
                                              ^BOOL(id  _Nonnull obj,
                                                    NSUInteger idx,
                                                    BOOL * _Nonnull stop) {
                                                  if ([[obj valueForKey:@"configKey"] isEqualToData:configKey]) {
                                                      *stop = YES;
                                                      return YES;
                                                  }
                                                  return NO;
                                              }];
    return indexOfLockedExamDictionary;
}


- (BOOL) isStartingLockedExam:(NSString *)examURLString configKey:(NSData *)configKey;
{
    BOOL isStartingLockedExam = NO;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSMutableArray *lockedExams = [NSMutableArray arrayWithArray:[preferences persistedSecureObjectForKey:@"org_safeexambrowser_additionalResources"]];
    if ([[lockedExams valueForKey:@"configKey"] containsObject:configKey]) {
        if (!([[NSUserDefaults standardUserDefaults] secureIntegerForKey:@"org_safeexambrowser_SEB_browserWindowShowURL"] >= browserWindowShowURLBeforeTitle)) {
            examURLString = @"";
            [lockedExams removeAllObjects];
        }
        DDLogError(@"Attempting to start an exam %@ which is on the list %@ of previously interrupted and not properly finished exams.", examURLString, lockedExams);
        isStartingLockedExam = YES;
    }
    return isStartingLockedExam;
}


/// Lockview business logic

- (NSString *) appendChallengeToMessage:(NSString *)alertMessage
{
    return alertMessage;
}


- (void) appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime
{
    NSData *configKey = self.controllerDelegate.configKey;
    [self appendErrorString:errorString withTime:errorTime configKey:configKey];
}

- (void) appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime configKey:(NSData *)configKey
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSMutableAttributedString *logString = [self.UIDelegate.resignActiveLogString mutableCopy];
    BOOL setConsoleLogString = NO;
    NSMutableAttributedString *appendedLogString = [[NSMutableAttributedString alloc] initWithString:@""];
    NSUInteger indexOfLockedExamDictionary = 0;
    NSMutableArray *lockedExams;
    NSString *startURL;
    BOOL secureExam = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length != 0;
    
    // Persist log strings for a "secure exam" (has a quit password)
    if (secureExam) {
        if (currentExamURL) {
            startURL = currentExamURL;
        } else {
            startURL = self.controllerDelegate.startURL.absoluteString;
        }
        if (!startURL) {
            startURL = @"";
        }
        lockedExams = [NSMutableArray arrayWithArray:[preferences persistedSecureObjectForKey:@"org_safeexambrowser_additionalResources"]];
        // Check if an exam with this Start URL already was persisted
        indexOfLockedExamDictionary = [self getIndexOfLockedExam:lockedExams withConfigKey:configKey];
        if (indexOfLockedExamDictionary != NSNotFound) {
            // Get the persisted log string
            NSDictionary *persistedLockedExam = lockedExams[indexOfLockedExamDictionary];
            if (logString.length == 0) {
                setConsoleLogString = YES;
            }
            logString = [[NSKeyedUnarchiver unarchiveObjectWithData:[persistedLockedExam objectForKey:@"logString"]] mutableCopy];
        }
    }
    
    if (!logString) {
        logString = [[NSMutableAttributedString alloc] initWithString:@""];
    }
    
    NSString *theTime = @"";
    if (errorTime) {
        NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
        [timeFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss  "];
        theTime = [timeFormat stringFromDate:errorTime];
        NSAttributedString *attributedTimeString = [[NSAttributedString alloc] initWithString:theTime];
        [logString appendAttributedString:attributedTimeString];
        [appendedLogString appendAttributedString:attributedTimeString];
    }
    DDLogInfo(@"%s: %@ %@", __FUNCTION__, errorString, theTime);
    NSMutableAttributedString *attributedErrorString = [[NSMutableAttributedString alloc] initWithString:errorString];
    
    [attributedErrorString setAttributes:self.boldFontAttributes range:NSMakeRange(0, attributedErrorString.length)];
    [logString appendAttributedString:attributedErrorString];
    [appendedLogString appendAttributedString:attributedErrorString];

    if (secureExam) {
        // Persist the new log string
        NSData *logStringArchived = [NSKeyedArchiver archivedDataWithRootObject:logString];
        // Add the new (modified) entry
        NSDictionary *interruptedLockedExam = @{
                                                @"startURL" : startURL,
                                                @"configKey" : configKey,
                                                @"logString" : logStringArchived,
                                                };
        [lockedExams addObject:interruptedLockedExam];
        
        if (indexOfLockedExamDictionary != NSNotFound) {
            // Remove the old entry for the persisted locked exam
            [lockedExams removeObjectAtIndex:indexOfLockedExamDictionary];
        }
        
        [preferences setPersistedSecureObject:lockedExams forKey:@"org_safeexambrowser_additionalResources"];
        if (setConsoleLogString) {
            self.UIDelegate.resignActiveLogString = logString.copy;
        }
    }

    run_block_on_main_thread(^{
        [self.UIDelegate setResignActiveLogString:[logString copy] logStringToAppend:appendedLogString];
        [self.UIDelegate scrollToBottom];
    });
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


- (void) retryButtonPressed {
    [self.controllerDelegate retryButtonPressed];
}


- (void) passwordEntered {
    // Check if the exam is protected with the quit/unlock password (and one is set)
    if (!closingLockdownWindowsInProgress) {
        if (!self.keychainManager) {
            self.keychainManager = [[SEBKeychainManager alloc] init];
        }
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSString *hashedQuitPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
        
        NSString *password = [self.UIDelegate lockedAlertPassword];
        if (hashedQuitPassword.length == 0 || (hashedQuitPassword && [hashedQuitPassword caseInsensitiveCompare:[self.keychainManager generateSHAHashString:password]] == NSOrderedSame)) {
            // Correct password entered
            closingLockdownWindowsInProgress = YES;
            [self.UIDelegate setLockedAlertPassword:@""];
            [self.UIDelegate setPasswordWrongLabelHidden:YES];
            
            // Add log string for Correct password entered
            [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Correct password entered", @"")]
                           withTime:[NSDate date]];
            
            if ([self.controllerDelegate respondsToSelector:@selector(unlockPasswordEntered)]) {
                self.controllerDelegate.unlockPasswordEntered = YES;
            }
#ifdef DEBUG
            DDLogInfo(@"%s, [self.controllerDelegate (%@) correctPasswordEntered]", __FUNCTION__, self.controllerDelegate);
#endif
            [self.controllerDelegate correctPasswordEntered];
            return;
        }
        DDLogError(@"Lockdown alert: Wrong quit/unlock password entered, asking to try again");
        [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Wrong password entered!", @"")]
                       withTime:[NSDate date]];
        [self.UIDelegate setLockedAlertPassword:@""];
        [self.UIDelegate setPasswordWrongLabelHidden:NO];
    }
}


- (void) closeLockdownWindows {
    // Add log information about closing lockdown alert
    DDLogInfo(@"Lockdown alert: Correct password entered, closing lockdown windows");
    self.controllerDelegate.didResumeExamTime = [NSDate date];
    [self appendErrorString:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Closing lockdown windows", @"")] withTime:self.controllerDelegate.didResumeExamTime];
    // Calculate time difference between session resigning active and closing lockdown alert
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:NSCalendarUnitMinute | NSCalendarUnitSecond
                                               fromDate:self.controllerDelegate.didLockSEBTime
                                                 toDate:self.controllerDelegate.didResumeExamTime
                                                options:NSCalendarWrapComponents];
    
    DDLogInfo(@"Lockdown alert: Closing lockdown windows");
    NSString *lockedTimeInfo = [NSString stringWithFormat:NSLocalizedString(@"%@ was locked (exam interrupted) for %ld:%.2ld (minutes:seconds)", @""), SEBShortAppName, components.minute, components.second];
    
    if ([self.UIDelegate respondsToSelector:@selector(lockdownWindowsWillClose)]) {
        [self.UIDelegate lockdownWindowsWillClose];
    }

    DDLogInfo(@"Lockdown alert: %@", lockedTimeInfo);
    [self appendErrorString:[NSString stringWithFormat:@"  %@\n", lockedTimeInfo]
                   withTime:nil];
    
    if ([self.controllerDelegate respondsToSelector:@selector(closeLockdownWindowsAllowOverride:)]) {
        [self.controllerDelegate closeLockdownWindowsAllowOverride:YES];
    }
    if ([self.controllerDelegate respondsToSelector:@selector(openInfoHUD:)]) {
        [self.controllerDelegate openInfoHUD:lockedTimeInfo];
    }
    if ([self.controllerDelegate respondsToSelector:@selector(sebLocked)]) {
        self.controllerDelegate.sebLocked = NO;
    }
    closingLockdownWindowsInProgress = NO;
}


- (void) abortClosingLockdownWindows
{
    closingLockdownWindowsInProgress = NO;
}


@end
