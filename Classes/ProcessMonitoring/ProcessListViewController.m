//
//  ProcessListViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.07.20.
//

#import "ProcessListViewController.h"
#import "ProcessListElement.h"

@implementation ProcessListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
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
    _processListArrayController.content = allProcesses.copy;
}

@end
