//
//  ProcessListViewControllerTests.m
//  SafeExamBrowserTests
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 2.0 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//

#import <XCTest/XCTest.h>
#import "ProcessListViewController.h"

@interface ProcessListViewController (SEBTests)

- (void)closeWindow;
- (void)forceQuitAllProcessesProceed;

@end


@interface TestProcessListViewController : ProcessListViewController

@end


@implementation TestProcessListViewController

- (void)closeModalAlert
{
}

@end


@interface ProcessListViewControllerDelegateDouble : NSObject <ProcessListViewControllerDelegate>

@property (readwrite) BOOL quittingSession;
@property (nonatomic) NSUInteger closeCallbackCount;
@property (copy, nonatomic) void (^closeCallback)(void);

@end


@implementation ProcessListViewControllerDelegateDouble

- (NSMutableArray *)checkProcessesRunning:(NSMutableArray *)runningProcesses
{
    return runningProcesses;
}

- (void)closeProcessListWindow
{
}

- (void)closeProcessListWindowWithCallback:(id)callback selector:(SEL)selector
{
    self.closeCallbackCount++;
    if (self.closeCallback) {
        self.closeCallback();
    }
}

- (NSAlert *)newAlert
{
    return [NSAlert new];
}

- (void)removeAlertWindow:(NSWindow *)alertWindow
{
}

- (void)runModalAlert:(NSAlert *)alert
conditionallyForWindow:(NSWindow *)window
     completionHandler:(void (^)(NSModalResponse returnCode))handler
{
}

- (void)quitSEBOrSession
{
}

@end


@interface ProcessListViewControllerTests : XCTestCase

@end


@implementation ProcessListViewControllerTests

- (void)testForceQuitCompletionOnlyClosesProcessListOnce
{
    TestProcessListViewController *processListViewController = [TestProcessListViewController new];
    ProcessListViewControllerDelegateDouble *delegate = [ProcessListViewControllerDelegateDouble new];
    processListViewController.delegate = delegate;
    processListViewController.windowOpen = YES;
    processListViewController.runningApplications = [NSMutableArray new];
    processListViewController.runningProcesses = [NSMutableArray new];

    XCTestExpectation *duplicateCallback = [self expectationWithDescription:@"Duplicate close callback"];
    duplicateCallback.inverted = YES;
    delegate.closeCallback = ^{
        if (delegate.closeCallbackCount > 1) {
            [duplicateCallback fulfill];
        }
    };

    [processListViewController closeWindow];
    [processListViewController forceQuitAllProcessesProceed];

    [self waitForExpectations:@[duplicateCallback] timeout:1.5];
    XCTAssertEqual(delegate.closeCallbackCount, 1);
}

@end
