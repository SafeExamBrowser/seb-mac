//
//  SEBServerViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 04.09.19.
//

#import "SEBServerViewController.h"
#import "ExamCell.h"
#import "SafeExamBrowser-Swift.h"

@interface SEBServerViewController ()

@end

@implementation SEBServerViewController 

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
