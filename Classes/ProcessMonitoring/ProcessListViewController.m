//
//  ProcessListViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.07.20.
//

#import "ProcessListViewController.h"
#import "ProcessListElement.h"
#import "NSRunningApplication+SEB.h"

@interface ProcessListViewController () {
    __weak IBOutlet NSButton *forceQuitButton;
    __weak IBOutlet NSButton *quitSEBSessionButton;
}

@end

@implementation ProcessListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSArray *allProcessListElements = [self allProcessListElements];
    if (allProcessListElements.count == 0) {
        [_delegate closeProcessListWindowWithCallback:_callback selector:_selector];
    } else {
        _processListArrayController.content = allProcessListElements;
    }
}


- (NSArray *)allProcessListElements
{
    NSMutableArray *allProcesses = [NSMutableArray new];
    for (NSRunningApplication *runningApplication in _runningApplications) {
        ProcessListElement *processListElement = [[ProcessListElement alloc] initWithProcess:runningApplication];
        if (processListElement) {
            [allProcesses addObject:processListElement];
        }
    }
    for (NSDictionary *runningProcess in _runningProcesses) {
        [allProcesses addObject:[[ProcessListElement alloc] initWithProcess:runningProcess]];
    }
    return allProcesses.copy;
}


- (void)didTerminateRunningApplications:(NSArray *)terminatedApplications
{
    for (NSRunningApplication *terminatedApplication in terminatedApplications) {
        if ([_runningApplications containsObject:terminatedApplication]) {
            [_runningApplications removeObject:terminatedApplication];
            _processListArrayController.content = [self allProcessListElements];
        }
    }
    if (_runningApplications.count + _runningProcesses.count == 0) {
        [_delegate closeProcessListWindowWithCallback:_callback selector:_selector];
    }
}


- (IBAction)forceQuitAllProcesses:(id)sender
{
    NSUInteger i=0;
    while (i < _runningApplications.count) {
        NSRunningApplication *runningApplication = _runningApplications[i];
        NSString *runningApplicationName = runningApplication.localizedName;
        NSString *runningApplicationIdentifier = runningApplication.bundleIdentifier;
        if ([runningApplication kill] == ERR_SUCCESS) {
            DDLogDebug(@"Running application %@ (%@) successfully force terminated", runningApplicationName, runningApplicationIdentifier);
            [_runningApplications removeObjectAtIndex:i];
        } else {
            DDLogError(@"Force terminating running application %@ (%@) failed!", runningApplicationName, runningApplicationIdentifier);
            i++;
        }
    }
    i=0;
    while (i < _runningProcesses.count) {
        NSDictionary *runningProcess = _runningProcesses[i];
        NSNumber *PID = runningProcess[@"PID"];
        pid_t processPID = PID.intValue;
        if (kill(processPID, 9) == ERR_SUCCESS) {
            DDLogDebug(@"Running process %@ successfully force terminated", runningProcess[@"name"]);
            // ToDo: Restart terminated BSD processes when quitting
            [_runningProcesses removeObjectAtIndex:i];
        } else {
            DDLogError(@"Force terminating running process %@ failed!", runningProcess[@"name"]);
            i++;
        }
    }
    if (_runningApplications.count + _runningProcesses.count == 0) {
        [_delegate closeProcessListWindowWithCallback:_callback selector:_selector];
    }
}

- (IBAction)quitSEBSession:(id)sender {
}

@end
