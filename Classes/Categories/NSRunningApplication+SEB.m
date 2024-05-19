//
//  NSRunningApplication+SEB
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.10.16.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "NSRunningApplication+SEB.h"


@implementation NSRunningApplication (SEB)


+ (BOOL)killApplicationWithBundleIdentifier:(NSString *)bundleID
{
    NSArray *runningApplicationInstances = [NSRunningApplication runningApplicationsWithBundleIdentifier:bundleID];
    BOOL success = NO;
    if (runningApplicationInstances.count != 0) {
        for (NSRunningApplication *runningApplication in runningApplicationInstances) {
            DDLogWarn(@"Terminating %@", bundleID);
            success = success || [runningApplication kill];
        }
    }
    return success;
}


- (BOOL)kill
{
    if (!self.terminated) {
        NSError *error;
        BOOL success = [NSRunningApplication killProcessWithPID:[self processIdentifier] error:&error];
        DDLogVerbose(@"Success of terminating %@: %ld", self, (long)success);
        if (success == NO) {
            success = [self filterKillErrors:error];
        }
        return success;
    } else {
        DDLogVerbose(@"Process %@ alread terminated", self);
        return YES;
    }
}


- (BOOL)filterKillErrors:(NSError*)error
{
    NSInteger killSuccess = [[error.userInfo objectForKey:SEBErrorKillProcessSuccessKey] intValue];
    long errorNumber = [[error.userInfo objectForKey:SEBErrorKillProcessErrnoKey] longValue];
    if (killSuccess == -1 && errorNumber == 1 && [self.bundleIdentifier isEqualToString:WebKitNetworkingProcessBundleID] ) {
        // WebKit networking process couldn't be killed because it's running with elevated user rights, ignore it
        return YES;
    }
    return NO;
}


+ (BOOL)killProcessWithPID:(pid_t)processPID error:(NSError* _Nullable *)error
{
    NSInteger killSuccess = (NSInteger)kill(processPID, 9);
    NSString *localizedDescription;
    NSString *debugDescription;
    if (killSuccess == ESRCH) {
        debugDescription = @"No such process.";
        DDLogError(@"Couldn't terminate process: %@", debugDescription);
        return YES;
    } else if (killSuccess == -1) {
        debugDescription = [NSString stringWithFormat:@"kill(9) success: %ld, errno: %ld, error: %s", (long)killSuccess, (long)errno, strerror(errno)];
        localizedDescription = debugDescription;
        if (errno == 3) { // No such process (already terminated)
            DDLogInfo(@"%@", debugDescription);
            return YES;
        } else {
            DDLogError(@"%@", debugDescription);
        }
    } else if (killSuccess != ERR_SUCCESS) {
        debugDescription = [NSString stringWithFormat:@"kill(9) not successful: %ld, errno: %ld, error: %s", (long)killSuccess, (long)errno, strerror(errno)];
        localizedDescription = debugDescription;
        DDLogError(@"%@", debugDescription);
    } else {
        DDLogVerbose(@"killProcessWithPID:%d Successfully terminated process", (int)processPID);
        return YES;
    }
    if (error) {
        *error = [NSError errorWithDomain:sebErrorDomain
                                           code:SEBErrorKillProcessFailed
                                       userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Couldn't terminate process: %@", @""), localizedDescription],
                                                  NSDebugDescriptionErrorKey : [NSString stringWithFormat:@"Couldn't terminate process: %@", debugDescription],
                                                  SEBErrorKillProcessSuccessKey: [NSNumber numberWithLong:killSuccess],
                                                  SEBErrorKillProcessErrnoKey: [NSNumber numberWithInt:errno]  //[NSString stringWithFormat:@"%@", errno]
                                                }];
    }
    return NO;
}

@end
