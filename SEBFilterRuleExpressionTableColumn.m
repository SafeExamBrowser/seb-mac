//
//  SEBFilterRuleExpresssionTableColumn.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 23.03.13.
//
//

#import "SEBFilterRuleExpressionTableColumn.h"
#import "PrefsNetworkViewController.h"

@implementation SEBFilterRuleExpressionTableColumn

- (id)dataCellForRow:(NSInteger)row;
{
	NSOutlineView *outlineView = (NSOutlineView *)[self tableView];
	int level = [outlineView levelForRow:row];
    
    /*if (level == 0) {
        [self bind:@"Value"
              toObject:self        withKeyPath:@"arrangedObjects.description"
               options:nil];

    }*/
    PrefsNetworkViewController *viewController = (PrefsNetworkViewController*)[outlineView delegate];
    NSCell *groupRowDataCell = [[viewController groupRowTableColumn] dataCell];
	return ( level == 0 ) ? (id)groupRowDataCell : (id)[self dataCell];
}

@end
