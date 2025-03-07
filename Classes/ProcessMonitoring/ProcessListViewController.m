//
//  ProcessListViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.07.20.
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

#import "ProcessListViewController.h"
#import "ProcessManager.h"
#import "ProcessListElement.h"
#import "NSRunningApplication+SEB.h"

@interface ProcessListViewController () {
    __weak IBOutlet NSButton *forceQuitButton;
    __weak IBOutlet NSButton *quitSEBSessionButton;
    __weak IBOutlet NSTextField *runningProhibitedProcessesText;
}

@end

@implementation ProcessListViewController


- (void)loadView
{
    DDLogDebug(@"Loading ProcessListView");
    [super loadView];
    
    if (@available(macOS 10.10, *)) {
    } else {
        [self viewDidLoad];
    }
}


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
#ifndef VERIFICATOR
        // If the setting autoQuitApplications = true or there are no running applications (only BSD processes)
        // we show the force quit option
        self.autoQuitApplications = _runningApplications.count == 0 ||
        [[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_SEB_autoQuitApplications"];
        quitSEBSessionButton.title = [self quitSEBOrSessionString];
#endif
        [self updateUIStrings];
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
    forceQuitButton.title = self.autoQuitApplications ? NSLocalizedString(@"Force Quit All Processes", @"") : NSLocalizedString(@"Quit All Applications", @"");
#ifdef VERIFICATOR
    runningProhibitedProcessesText.stringValue = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"The applications below are running, they need to be closed before starting SEB. You can quit applications yourself and return to SEB Verificator to start SEB.", @""), self.autoQuitApplications ? NSLocalizedString(@"You can also force quit these processes, but this may lead to loss of data.", @"") : NSLocalizedString(@"You can also send all the listed applications a quit instruction, they can still ask about saving edited documents.", @"")];
    if (self.autoQuitApplications) {
        quitSEBSessionButton.hidden = YES;
    } else {
        quitSEBSessionButton.hidden = NO;
        quitSEBSessionButton.title = NSLocalizedString(@"Start SEB", @"");
    }
#else
    runningProhibitedProcessesText.stringValue = [NSString stringWithFormat:@"%@ %@", [NSString stringWithFormat:NSLocalizedString(@"The applications/processes below are running, they need to be closed before starting the exam. You can quit applications yourself or deactivate/uninstall helper processes and return to %@ to continue to the exam.", @""), SEBShortAppName], self.autoQuitApplications ? NSLocalizedString(@"You can also force quit these processes, but this may lead to loss of data.", @"") : NSLocalizedString(@"You can also send all the listed applications a quit instruction, they can still ask about saving edited documents.", @"")];
#endif
}

- (NSString *)quitSEBOrSessionString
{
    NSString *quitSEBOrSessionString;
    if (self.delegate.quittingSession) {
        quitSEBOrSessionString = NSLocalizedString(@"Quit Session", @"");
    } else {
        quitSEBOrSessionString = [NSString stringWithFormat:NSLocalizedString(@"Quit %@", @""), SEBShortAppName];
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
            if (_runningApplications.count > i) {
                @try {
                    [_runningApplications removeObjectAtIndex:i];
                } @catch (NSException *exception) {
                    DDLogError(@"Caught exception %@ when trying to remove process list element.", exception);
                }
            }
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
    if ([self allProcessListElements].count > 0) {
        if (self.autoQuitApplications) {
            self.modalAlert = [self.delegate newAlert];
            [self.modalAlert setMessageText:NSLocalizedString(@"Force Quit All Processes", @"")];
            [self.modalAlert setInformativeText:NSLocalizedString(@"Do you really want to force quit all running prohibited processes? Applications might loose unsaved changes to documents, especially if they don't support auto save.", @"")];
            [self.modalAlert setAlertStyle:NSAlertStyleCritical];
            [self.modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
            [self.modalAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
            void (^forceQuitAllProcessesAnswer)(NSModalResponse) = ^void (NSModalResponse answer) {
                [self.delegate removeAlertWindow:self.modalAlert.window];
                switch(answer)
                {
                    case NSAlertFirstButtonReturn:
                    {
                        [self forceQuitAllProcessesProceed];
                        return;
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
            self.autoQuitApplications = YES;
            [self updateUIStrings];
        }
    }
}

- (void)forceQuitAllProcessesProceed
{
    NSUInteger i=0;
    while (i < _runningApplications.count) {
        NSRunningApplication *runningApplication = _runningApplications[i];
        NSString *runningApplicationName = runningApplication.localizedName;
        NSString *runningApplicationIdentifier = runningApplication.bundleIdentifier;
        if ([runningApplication kill]) {
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
            [self.modalAlert setMessageText:NSLocalizedString(@"Force Quitting Processes Failed", @"")];
            [self.modalAlert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"%@ was unable to force quit all processes, administrator rights might be necessary. Try using the macOS Activity Monitor application or uninstall helper processes (which might be automatically restarted by the system).", @""), SEBShortAppName]];
            [self.modalAlert setAlertStyle:NSAlertStyleCritical];
            [self.modalAlert addButtonWithTitle:NSLocalizedString(@"OK", @"")];
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
                        return;
                    }
                        
                    case NSModalResponseAbort:
                    {
                        DDLogInfo(@"Alert was dismissed with NSModalResponseAbort.");
                        return;
                    }
                        
                    default:
                    {
                        DDLogError(@"Alert was dismissed by the system with NSModalResponse %ld.", (long)answer);
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


/// NSWindowDelegate methods

- (BOOL)windowShouldClose:(NSWindow *)sender
{
    if ([self allProcessListElements].count == 0) {
        return YES;
    } else {
        [self quitSEBSession:self];
    }
    return YES;
}

@end
