//
//  SEBFilterRuleTableColumn.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 22.03.13.
//
//

#import "SEBFilterRuleTableColumn.h"

@implementation SEBFilterRuleTableColumn

- (id)dataCellForRow:(NSInteger)row;
{
	NSOutlineView *outlineView = (NSOutlineView *)[self tableView];
	int level = [outlineView levelForRow:row];
    
    /*if (level == 0) {
        NSLog(@"Table cell identifier: %@", self.identifier);
    }*/
    
	return ( level == 0 ) ? (id)nil : (id)[self dataCell];
}

@end
