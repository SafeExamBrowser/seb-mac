//
//  SEBServerViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 04.09.19.
//

#import <UIKit/UIKit.h>
#import "SEBViewController.h"

@class SEBViewController;


NS_ASSUME_NONNULL_BEGIN

@interface SEBServerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ServerControllerUIDelegate>

@property (weak) SEBServerController *sebServerController;
@property (weak) SEBViewController *sebViewController;
@property (nonatomic, weak) NSArray * exams;

@property (weak, nonatomic) IBOutlet UITableView *examsTableView;


@end

NS_ASSUME_NONNULL_END
