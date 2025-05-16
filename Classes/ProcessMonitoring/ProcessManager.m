//
//  ProcessManager.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 07.07.20.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "ProcessManager.h"
#include <libproc.h>

@implementation ProcessManager

static ProcessManager *sharedProcessManager = nil;

+ (ProcessManager *)sharedProcessManager
{
    @synchronized(self)
    {
        if (sharedProcessManager == nil)
        {
            sharedProcessManager = [[self alloc] init];
        }
    }
    
    return sharedProcessManager;
}


+ (dispatch_source_t) createDispatchTimerWithInterval: (uint64_t)interval
                                               leeway:(uint64_t)leeway
                                        dispatchQueue:(dispatch_queue_t)queue
                                        dispatchBlock:(dispatch_block_t)block
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}



+ (NSString *)getExecutablePathForPID:(pid_t) runningExecutablePID
{
    int ret;
    char pathbuf[PROC_PIDPATHINFO_MAXSIZE];
    
    ret = proc_pidpath (runningExecutablePID, pathbuf, sizeof(pathbuf));
    #ifdef DEBUG
    if ( ret <= 0 ) {
        fprintf(stderr, "PID %d: proc_pidpath ();\n", runningExecutablePID);
        fprintf(stderr, "    %s\n", strerror(errno));
    } else {
        printf("proc %d: %s\n", runningExecutablePID, pathbuf);
    }
    #endif

    NSString *executablePath = [NSString stringWithCString:pathbuf encoding:NSUTF8StringEncoding];
    return executablePath;
}


#ifndef VERIFICATOR
// Updates process arrays with current settings (UserDefaults) for processes and applications which should be monitored
- (void) updateMonitoredProcesses
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSArray *allProhibitedProcesses = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_prohibitedProcesses"];
    NSArray *allPermittedProcesses = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_permittedProcesses"];
    NSPredicate *filterProcessOS = [NSPredicate predicateWithFormat:@"active == YES AND os == %d", SEBSupportedOSmacOS];
    _prohibitedProcesses = [allProhibitedProcesses filteredArrayUsingPredicate:filterProcessOS];
    _permittedProcesses = [allPermittedProcesses filteredArrayUsingPredicate:filterProcessOS];

    if (self.prohibitedApplications) {
        [self.prohibitedApplications removeAllObjects];
    } else {
        self.prohibitedApplications = [NSMutableArray new];
    }
    
    if (self.permittedApplications) {
        [self.permittedApplications removeAllObjects];
    } else {
        self.permittedApplications = [NSMutableArray new];
    }

    if (self.prohibitedBSDProcesses) {
        [self.prohibitedBSDProcesses removeAllObjects];
    } else {
        self.prohibitedBSDProcesses = [NSMutableArray new];
    }
    
    if (self.permittedBSDProcesses) {
        [self.permittedBSDProcesses removeAllObjects];
    } else {
        self.permittedBSDProcesses = [NSMutableArray new];
    }

    NSDictionary *prohibitedProcess;
    
    BOOL isAACActive;
    if (@available(macOS 10.15.4, *)) {
        isAACActive = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableMacOSAAC"];
    } else {
        isAACActive = NO;
    }
    
    for (prohibitedProcess in _prohibitedProcesses) {
        
        if (!(isAACActive && [prohibitedProcess[@"ignoreInAAC"] boolValue] == YES)) {
            NSString *bundleID = prohibitedProcess[@"identifier"];
            if (bundleID.length > 0) {
                [self.prohibitedApplications addObject:bundleID];
            } else {
                [self.prohibitedBSDProcesses addObject:prohibitedProcess[@"executable"]];
            }
        }
    }
    
    NSDictionary *permittedProcess;
    for (permittedProcess in _permittedProcesses) {
        if ([permittedProcess[@"runInBackground"] boolValue] == NO) {
            NSString *bundleID = permittedProcess[@"identifier"];
            if (bundleID.length > 0) {
                [self.permittedApplications addObject:bundleID];
            } else {
                [self.permittedBSDProcesses addObject:permittedProcess[@"executable"]];
            }
        }
    }
}
#endif


- (void) removeOverriddenProhibitedBSDProcesses:(NSArray *)overriddenProhibitedProcesses
{
    NSUInteger i = 0;
    while (i < _prohibitedBSDProcesses.count) {
        NSString *processName = _prohibitedBSDProcesses[i];
        NSPredicate *processFilter = [NSPredicate predicateWithFormat:@"name ==[cd] %@", processName];
        NSArray *filteredOverriddenProcesses = [overriddenProhibitedProcesses filteredArrayUsingPredicate:processFilter];
        if (filteredOverriddenProcesses.count != 0) {
            [_prohibitedBSDProcesses removeObjectAtIndex:i];
        } else {
            i++;
        }
    }
}


- (NSDictionary *) prohibitedProcessWithIdentifier:(NSString *)bundleID
{
    NSPredicate *filterProcessIdentifier = [NSPredicate predicateWithFormat:@"%@ LIKE identifier", bundleID];
    NSArray *foundProcesses = [_prohibitedProcesses filteredArrayUsingPredicate:filterProcessIdentifier];
    if (foundProcesses.count > 0) {
        return foundProcesses[0];
    } else {
        return nil;
    }
}


- (NSDictionary *) prohibitedProcessWithExecutable:(NSString *)executable
{
    NSPredicate *filterProcessIdentifier = [NSPredicate predicateWithFormat:@"%@ LIKE executable", executable];
    NSArray *foundProcesses = [_prohibitedProcesses filteredArrayUsingPredicate:filterProcessIdentifier];
    if (foundProcesses.count > 0) {
        return foundProcesses[0];
    } else {
        return nil;
    }
}


@end
