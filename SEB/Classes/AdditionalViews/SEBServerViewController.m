//
//  SEBServerViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 04.09.19.
//

#import "SEBServerViewController.h"
#import "ExamCell.h"
#import "SafeExamBrowser-Swift.h"


@implementation SEBServerViewController


- (BOOL) prefersStatusBarHidden
{
    return true;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.examsTableView.dataSource = self;
    self.examsTableView.delegate = self;

    [self updateExamList];
}


- (void)updateExamList
{
    [self.examsTableView reloadData];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_sebServerController.examList.count > 0) {
        return NSLocalizedString(@"Select Exam", @"'Select Exam' header in 'Connecting to SEB Server' table view.");
    }
    return NSLocalizedString(@"Connecting…", @"'Connecting…' header in 'Connecting to SEB Server' table view.");
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ExamCell *cell = [tableView dequeueReusableCellWithIdentifier:@"examListCell" forIndexPath:indexPath];
    ExamObject *exam = _sebServerController.examList[indexPath.row];
    cell.examLabel.text = exam.name;
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *examList = _sebServerController.examList;
    NSInteger count = examList.count;
    return count;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    ExamObject *exam = _sebServerController.examList[indexPath.row];
    NSString *examId = exam.examId;
    NSString *examURL = exam.url;
    [_sebViewController didSelectExamWithExamId:examId url:examURL];
}


#pragma mark - IB Action Handler

- (IBAction)closeButtonAction:(id)sender
{
    [_sebViewController closeServerView:sender];
}


- (IBAction)aboutSEBIcon:(id)sender
{
    [_sebViewController showAboutSEB];
}


@end
