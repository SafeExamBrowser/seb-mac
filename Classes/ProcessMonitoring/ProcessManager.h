//
//  ProcessManager.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 07.07.20.
//

#import <Foundation/Foundation.h>

@interface ProcessManager : NSObject

@property (strong, nonatomic) NSArray *prohibitedProcesses;
@property (strong, nonatomic) NSArray *permittedProcesses;
@property (strong, nonatomic) NSMutableArray *prohibitedRunningApplications;
@property (strong, nonatomic) NSMutableArray *permittedRunningApplications;
@property (strong, nonatomic) NSMutableArray *prohibitedBSDProcesses;
@property (strong, nonatomic) NSMutableArray *permittedBSDProcesses;

+ (ProcessManager *) sharedProcessManager;

+ (dispatch_source_t) createDispatchTimerWithInterval: (uint64_t)interval
                                               leeway:(uint64_t)leeway
                                        dispatchQueue:(dispatch_queue_t)queue
                                        dispatchBlock:(dispatch_block_t)block;

+ (NSString *) getExecutablePathForPID:(pid_t) runningExecutablePID;

- (void) updateMonitoredProcesses;
- (void) removeOverriddenProhibitedBSDProcesses:(NSArray *)overriddenProhibitedProcesses;
- (NSDictionary *) prohibitedProcessWithIdentifier:(NSString *)bundleID;
- (NSDictionary *) prohibitedProcessWithExecutable:(NSString *)executable;

@end
