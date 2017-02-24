//
//  SEBActionUITableViewCell.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15/01/16.
//
//

#import "SEBActionUITableViewCell.h"

@implementation SEBActionUITableViewCell


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)fireAction:(id)sender
{
    [self.delegate tableViewCell:self didFireActionForSender:sender];
}

@end
