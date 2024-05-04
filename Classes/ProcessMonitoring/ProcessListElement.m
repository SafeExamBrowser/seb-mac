//
//  ProcessList.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 31.07.20.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
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

#import "ProcessListElement.h"
#import "ProcessManager.h"

@interface ProcessListElement() {
    @private
    NSRunningApplication *runningApplication;
    NSDictionary *runningProcess;
}
@end

@implementation ProcessListElement

- (instancetype)initWithProcess:(id)process
{
    self = [super init];
    if (self) {
        if ([process isKindOfClass:[NSRunningApplication class]]) {
            runningApplication = (NSRunningApplication *)process;
            if (runningApplication.terminated) {
                return nil;
            }
        } else if ([process isKindOfClass:[NSDictionary class]]) {
            runningProcess = (NSDictionary *)process;
        }
    }
    return self;
}

- (NSImage *)icon
{
    if (runningApplication) {
        return runningApplication.icon;
    } else {
        return nil;
    }
}

- (NSString *)name
{
    if (runningApplication) {
        return runningApplication.localizedName;
    } else {
        return runningProcess[@"name"];
    }
}

- (NSString *)bundleID
{
    if (runningApplication) {
        return runningApplication.bundleIdentifier;
    } else {
        return nil;
    }
}

- (NSString *)path
{
    if (runningApplication) {
        NSURL *fileURL = runningApplication.bundleURL;
        if (!fileURL) {
            fileURL = runningApplication.executableURL;
        }
        return fileURL.path;
    } else {
        NSNumber *PID = runningProcess[@"PID"];
        pid_t processPID = PID.intValue;
        return [ProcessManager getExecutablePathForPID:processPID];
    }
}

- (BOOL)terminated
{
    if (runningApplication) {
        return runningApplication.terminated;
    } else {
        return YES;
    }
}

@end
