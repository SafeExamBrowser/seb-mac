//
//  SEBActionUITableViewCell.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15/01/16.
//
//

#import <UIKit/UIKit.h>

// Protocol to allow a cell to fire any type of action from a control
@protocol SEBActionUITableViewCellDelegate <NSObject>

@required
-(void)tableViewCell:(UITableViewCell *)cell didFireActionForSender:(id)sender;

@end

@interface SEBActionUITableViewCell : UITableViewCell

@property (nonatomic, weak) id<SEBActionUITableViewCellDelegate> delegate;

-(void)fireAction:(id)sender;

@end