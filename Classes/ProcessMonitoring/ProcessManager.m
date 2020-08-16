//
//  ProcessManager.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 07.07.20.
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


// Updates process arrays with current settings (UserDefaults)
- (void) updateMonitoredProcesses
{
    if (self.prohibitedRunningApplications) {
        [self.prohibitedRunningApplications removeAllObjects];
    } else {
        self.prohibitedRunningApplications = [NSMutableArray new];
    }
    
    if (self.permittedRunningApplications) {
        [self.permittedRunningApplications removeAllObjects];
    } else {
        self.permittedRunningApplications = [NSMutableArray new];
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

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    NSArray *prohibitedProcesses = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_prohibitedProcesses"];
    NSDictionary *prohibitedProcess;
    
    BOOL isAACActive;
//    if (@available(macOS 10.15.4, *)) {
//        isAACActive = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableAAC"];
//    } else {
        isAACActive = NO;
//    }
    
    for (prohibitedProcess in prohibitedProcesses) {
        
        if ([prohibitedProcess[@"active"] boolValue] == YES &&
            !(isAACActive && [prohibitedProcess[@"ignoreInAAC"] boolValue] == YES)) {
            
            NSString *bundleID = prohibitedProcess[@"identifier"];
            if (bundleID.length > 0) {
                [self.prohibitedRunningApplications addObject:bundleID];
            } else {
                [self.prohibitedBSDProcesses addObject:prohibitedProcess[@"executable"]];
            }
        }
    }
    
    if (!isAACActive && [preferences secureBoolForKey:@"org_safeexambrowser_SEB_terminateProcesses"]) {
        NSArray *permittedProcesses = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_permittedProcesses"];
        NSDictionary *permittedProcess;
        
        for (permittedProcess in permittedProcesses) {
            
            if ([permittedProcess[@"active"] boolValue] == YES) {
                
                NSString *bundleID = permittedProcess[@"identifier"];
                if (bundleID.length > 0) {
                    [self.permittedRunningApplications addObject:bundleID];
                } else {
                    [self.permittedBSDProcesses addObject:permittedProcess[@"executable"]];
                }
            }
        }
    }
}


- (NSDictionary *) prohibitedProcessWithIdentifier:(NSString *)bundleID
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSArray *prohibitedProcesses = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_prohibitedProcesses"];

    NSPredicate *filterProcessIdentifier = [NSPredicate predicateWithFormat:@" identifier ==[cd] %@", bundleID];
    NSArray *foundProcesses = [prohibitedProcesses filteredArrayUsingPredicate:filterProcessIdentifier];
    if (foundProcesses) {
        return foundProcesses[0];
    } else {
        return nil;
    }
}


- (NSDictionary *) prohibitedProcessWithExecutable:(NSString *)executable
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSArray *prohibitedProcesses = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_prohibitedProcesses"];

    NSPredicate *filterProcessIdentifier = [NSPredicate predicateWithFormat:@" executable ==[cd] %@", executable];
    NSArray *foundProcesses = [prohibitedProcesses filteredArrayUsingPredicate:filterProcessIdentifier];
    if (foundProcesses) {
        return foundProcesses[0];
    } else {
        return nil;
    }
}


@end
