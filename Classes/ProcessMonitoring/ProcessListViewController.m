//
//  ProcessListViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.07.20.
//

#import "ProcessListViewController.h"
#import "ProcessListElement.h"

@interface ProcessListViewController () {
    NSMutableArray *allProcesses;
}

@end

@implementation ProcessListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _processListArrayController.content = [self allProcessListElements];
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

}

@end
