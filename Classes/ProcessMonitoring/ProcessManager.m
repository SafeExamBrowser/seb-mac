//
//  ProcessManager.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 07.07.20.
//

#import "ProcessManager.h"

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
    if (@available(macOS 10.15.4, *)) {
        isAACActive = [preferences secureBoolForKey:@"org_safeexambrowser_SEB_enableAAC"];
    } else {
        isAACActive = NO;
    }
    
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


@end
