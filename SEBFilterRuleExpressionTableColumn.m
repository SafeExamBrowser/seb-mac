//
//  SEBFilterRuleExpresssionTableColumn.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 23.03.13.
//
//

#import "SEBFilterRuleExpressionTableColumn.h"

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
	return [self dataCell];
}

@end
