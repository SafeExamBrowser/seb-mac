//
//  SEBServerOSXViewController.m
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 24.09.21.
//

#import "SEBServerOSXViewController.h"

@interface SEBServerOSXViewController ()

@end

@implementation SEBServerOSXViewController


//- (void)loadView
//{
//
//}


- (void)viewDidLoad {
    [super viewDidLoad];

    NSScrollView *tableContainer = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 10, 460, 250)];
    tableContainer.borderType = NSNoBorder;
    self.examsTableView = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, 444, 250)];

    NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"Column1"];

    [column1 setWidth:444];
    // generally you want to add at least one column to the table view.
    [self.examsTableView addTableColumn:column1];
    self.examsTableView.dataSource = self;
    self.examsTableView.delegate = self;

    [tableContainer setDocumentView:self.examsTableView];
    [tableContainer setHasVerticalScroller:YES];
    [self.view addSubview:tableContainer];

    [self updateExamList];
}

- (void)updateExamList
{
    [self.examsTableView reloadData];
}


- (NSString *)titleForHeader
{
    if (_sebServerController.examList.count > 0) {
        return NSLocalizedString(@"Select Exam", @"'Select Exam' header in 'Connecting to SEB Server' table view.");
    }
    return NSLocalizedString(@"Connecting…", @"'Connecting…' header in 'Connecting to SEB Server' table view.");
}


- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row;
{
    [tableColumn.headerCell setStringValue:[self titleForHeader]];
    [tableView.headerView setNeedsDisplay:YES];
    
    ExamObject *exam = _sebServerController.examList[row];
    return exam.name;
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
    NSArray *examList = _sebServerController.examList;
    NSInteger count = examList.count;
    return count;
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification;
{
    NSInteger row = _examsTableView.selectedRow;
//    [_examsTableView deselectAll:self];
    ExamObject *exam = _sebServerController.examList[row];
    NSString *examId = exam.examId;
    NSString *examURL = exam.url;
    [self.serverControllerDelegate didSelectExamWithExamId:examId url:examURL];
}


/// NSWindowDelegate methods

- (BOOL)windowShouldClose:(NSWindow *)sender
{
    [_serverControllerDelegate closeServerView:sender];
    return YES;
}

@end
