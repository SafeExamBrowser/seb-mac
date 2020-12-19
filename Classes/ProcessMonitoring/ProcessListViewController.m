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
    __weak IBOutlet NSTextField *runningProhibitedProcessesText;
    BOOL autoQuitApplications;
}

@end

@implementation ProcessListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _windowOpen = YES;
    NSArray *allProcessListElements = [self allProcessListElements];
    if (allProcessListElements.count == 0) {
        DDLogDebug(@"%s calling [self.delegate closeProcessListWindowWithCallback: %@ selector: %@]", __FUNCTION__, self.callback, NSStringFromSelector(self.selector));
        [self.delegate closeProcessListWindowWithCallback:_callback selector:_selector];
        return;
    } else {
        _processListArrayController.content = allProcessListElements;
        // If the setting autoQuitApplications = true or there are no running applications (only BSD processes)
        // we show the force quit option
        autoQuitApplications = _runningApplications.count == 0 ||
        [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_autoQuitApplications"];
        [self updateUIStrings];
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

- (void)updateUIStrings
{
    forceQuitButton.title = autoQuitApplications ? NSLocalizedString(@"Force Quit All Processes", nil) : NSLocalizedString(@"Quit All Applications", nil);
    runningProhibitedProcessesText.stringValue = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"The applications/processes below are running, they need to be closed before starting the exam. You can quit applications yourself or deactivate/uninstall helper processes and return to SEB to continue to the exam.", nil), autoQuitApplications ? NSLocalizedString(@"You can also force quit these processes, but this may lead to loss of data.", nil) : NSLocalizedString(@"You can also send all the listed applications a quit instruction, they can still ask about saving edited documents.", nil)];
}

- (NSString *)quitSEBOrSessionString
{
    NSString *quitSEBOrSessionString;
    if (self.delegate.quitSession) {
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
    if (_windowOpen) {
        [self closeModalAlert];
        dispatch_async(dispatch_get_main_queue(), ^{
            id callbackMethod = self.callback;
            DDLogDebug(@"%s calling [self.delegate closeProcessListWindowWithCallback: %@ selector: %@]", __FUNCTION__, self.callback, NSStringFromSelector(self.selector));
            [self.delegate closeProcessListWindowWithCallback:callbackMethod selector:self.selector];
        });
        _windowOpen = NO;
    }
}

- (void)closeModalAlert
{
    [[NSApplication sharedApplication] abortModal];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.modalAlert.window orderOut:self];
        [self.modalAlert.window close];
        [self.delegate removeAlertWindow:self.modalAlert.window];
    });
}

- (NSArray *)allProcessListElements
{
    NSMutableArray *allProcesses = [NSMutableArray new];
    NSUInteger i=0;
    while (i < _runningApplications.count) {
        NSRunningApplication *runningApplication = _runningApplications[i];
        if (runningApplication && !runningApplication.terminated) {
            ProcessListElement *processListElement = [[ProcessListElement alloc] initWithProcess:runningApplication];
            if (processListElement) {
                [allProcesses addObject:processListElement];
            }
            i++;
        } else {
            [_runningApplications removeObjectAtIndex:i];
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
        DDLogDebug(@"Application %@ was terminated.", terminatedApplication);
        if ([_runningApplications containsObject:terminatedApplication]) {
            [_runningApplications removeObject:terminatedApplication];
            DDLogDebug(@"Terminated application %@ was removed from list of running prohibited processes.", terminatedApplication);
            _processListArrayController.content = [self allProcessListElements];
        }
    }
    if (_runningApplications.count + _runningProcesses.count == 0) {
        [self closeWindow];
    }
}


- (void)checkRunningProcessesTerminated
{
    NSUInteger runningProcessesCount = _runningProcesses.count;
    _runningProcesses = [self.delegate checkProcessesRunning:_runningProcesses];
    self.processListArrayController.content = [self allProcessListElements];
    if (_runningProcesses.count != runningProcessesCount || _runningProcesses.count + _runningApplications.count == 0) {
        if (self.runningApplications.count + self.runningProcesses.count == 0) {
            [self closeWindow];
        }
    }
}


- (IBAction)forceQuitAllProcesses:(id)sender
{
    if (autoQuitApplications) {
        self.modalAlert = [self.delegate newAlert];
        [self.modalAlert setMessageText:NSLocalizedString(@"Force Quit All Processes", nil)];
        [self.modalAlert setInformativeText:NSLocalizedString(@"Do you really want to force quit all running prohibited processes? Applications might loose unsaved changes to documents, especially if they don't support auto save.", nil)];
        [self.modalAlert setAlertStyle:NSCriticalAlertStyle];
        [self.modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        [self.modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        void (^forceQuitAllProcessesAnswer)(NSModalResponse) = ^void (NSModalResponse answer) {
            [self.delegate removeAlertWindow:self.modalAlert.window];
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
                    
                case NSModalResponseAbort:
                {
                    return;
                }
                    
                default:
                {
                    return;
                }
            }
        };
        [self.delegate runModalAlert:self.modalAlert conditionallyForWindow:self.view.window completionHandler:(void (^)(NSModalResponse answer))forceQuitAllProcessesAnswer];
        
    } else {
        for (NSRunningApplication* runningApplication in _runningApplications) {
            [runningApplication terminate];
        }
        autoQuitApplications = YES;
        [self updateUIStrings];
    }
}

- (void)forceQuitAllProcessesProceed
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.runningApplications.count + self.runningProcesses.count == 0) {
            DDLogDebug(@"%s calling [self.delegate closeProcessListWindowWithCallback: %@ selector: %@]", __FUNCTION__, self.callback, NSStringFromSelector(self.selector));
            [self.delegate closeProcessListWindowWithCallback:self.callback selector:self.selector];
        } else {
            self.modalAlert = [self.delegate newAlert];
            DDLogError(@"Force quitting processes failed!");
            [self.modalAlert setMessageText:NSLocalizedString(@"Force Quitting Processes Failed", nil)];
            [self.modalAlert setInformativeText:NSLocalizedString(@"SEB was unable to force quit all processes, administrator rights might be necessary. Try using the macOS Activity Monitor application or uninstall helper processes (which might be automatically restarted by the system).", nil)];
            [self.modalAlert setAlertStyle:NSCriticalAlertStyle];
            [self.modalAlert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
            [self.modalAlert addButtonWithTitle:[self quitSEBOrSessionString]];
            void (^forceQuitAllProcessesFailedAnswer)(NSModalResponse) = ^void (NSModalResponse answer) {
                [self.delegate removeAlertWindow:self.modalAlert.window];
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
                        
                    case NSModalResponseAbort:
                    {
                        return;
                    }
                        
                    default:
                    {
                        return;
                    }
                }
            };
            [self.delegate runModalAlert:self.modalAlert conditionallyForWindow:self.view.window completionHandler:(void (^)(NSModalResponse answer))forceQuitAllProcessesFailedAnswer];
        }
    });
}


- (IBAction)quitSEBSession:(id)sender
{
    // As we are quitting SEB or the session, the callback method should not be called
    [self.delegate closeProcessListWindow];
    [self.delegate quitSEBOrSession];
}

@end
