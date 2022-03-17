//
//  SEBServerViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 04.09.19.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
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
    if (@available(iOS 15.0, *)) {
        self.examsTableView.sectionHeaderTopPadding = 0.0;
    }

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


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *tableHeader = (UITableViewHeaderFooterView *)view;
    tableHeader.contentView.backgroundColor = UIColor.groupTableViewBackgroundColor;
    tableHeader.textLabel.textColor = UIColor.blackColor;
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
