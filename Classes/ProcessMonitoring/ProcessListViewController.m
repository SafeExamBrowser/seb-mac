//
//  ProcessListViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.07.20.
//

#import "ProcessListViewController.h"
#import "ProcessManager.h"
#import "ProcessListElement.h"
#import "NSRunningApplication+SEB.h"
#import "SEBController.h"

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
        quitSEBSessionButton.title = [self quitSEBOrSessionString];
    }
    if (!_processWatchTimer) {
        dispatch_source_t newProcessWatchTimer =
        [ProcessManager createDispatchTimerWithInterval:0.25 * NSEC_PER_SEC
                                                 leeway:(0.25 * NSEC_PER_SEC) / 10
                                          dispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                                          dispatchBlock:^{
            [self checkRunningProcessesTerminated];
        }];
        _processWatchTimer = newProcessWatchTimer;
    }
}

- (NSString *)quitSEBOrSessionString
{
    NSString *quitSEBOrSessionString;
    if (_delegate.quitSession) {
        quitSEBOrSessionString = NSLocalizedString(@"Quit Session", nil);
    } else {
        quitSEBOrSessionString = NSLocalizedString(@"Quit SEB", nil);
    }
    return quitSEBOrSessionString;
}


- (void)stopProcessWatcher
{
    if (_processWatchTimer) {
        dispatch_source_cancel(_processWatchTimer);
        _processWatchTimer = 0;
    }
}

- (void)closeWindow
{
    [self stopProcessWatcher];
    [_delegate closeProcessListWindowWithCallback:_callback selector:_selector];
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
        [self closeWindow];
    }
}


- (void)checkRunningProcessesTerminated
{
    if ([_delegate checkProcessesRunning:&_runningProcesses]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.processListArrayController.content = [self allProcessListElements];
            if (self.runningApplications.count + self.runningProcesses.count == 0) {
                [self closeWindow];
            }
        });
    }
}


- (IBAction)forceQuitAllProcesses:(id)sender
{
    NSAlert *modalAlert = [self.delegate newAlert];
    [modalAlert setMessageText:NSLocalizedString(@"Force Quit All Processes", nil)];
    [modalAlert setInformativeText:NSLocalizedString(@"Do you really want to force quit all running prohibited processes? Applications might loose unsaved changes to documents, especially if they don't support auto save.", nil)];
    [modalAlert setAlertStyle:NSCriticalAlertStyle];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    [modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    NSInteger answer = [modalAlert runModal];
    [self.delegate removeAlertWindow:modalAlert.window];
    switch(answer)
    {
        case NSAlertFirstButtonReturn:
        {
            break;
        }
            
        case NSAlertSecondButtonReturn:
        {
            // Cancel force quit
            return;
        }
    }
    
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.runningApplications.count + self.runningProcesses.count == 0) {
            [self.delegate closeProcessListWindowWithCallback:self.callback selector:self.selector];
        } else {
            NSAlert *modalAlert = [self.delegate newAlert];
            DDLogError(@"Force quitting processes failed!");
            [modalAlert setMessageText:NSLocalizedString(@"Force Quitting Processes Failed", nil)];
            [modalAlert setInformativeText:NSLocalizedString(@"SEB was unable to force quit all processes, administrator rights might be necessary. Try using the macOS Activity Monitor application or uninstall helper processes (which might be automatically restarted by the system).", nil)];
            [modalAlert setAlertStyle:NSCriticalAlertStyle];
            [modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [modalAlert addButtonWithTitle:[self quitSEBOrSessionString]];
            NSInteger answer = [modalAlert runModal];
            [self.delegate removeAlertWindow:modalAlert.window];
            switch(answer)
            {
                case NSAlertFirstButtonReturn:
                {
                    break;
                }
                    
                case NSAlertSecondButtonReturn:
                {
                    // Quit SEB or the session
                    DDLogInfo(@"User selected Quit SEB or Quit Session in the Force Quitting Processes Failed alert displayed in the 'Running Prohibited Processes' window.");
                    [self quitSEBSession:self];
                }
            }
        }
    });
}


- (IBAction)quitSEBSession:(id)sender
{
    // As we are quitting SEB or the session, the callback method should not be called
    [_delegate closeProcessListWindow];
    [_delegate quitSEBOrSession];
}

@end
