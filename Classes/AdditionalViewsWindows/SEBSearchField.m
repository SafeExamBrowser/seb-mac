//
//  SEBSearchField.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 11.03.22.
//

#import "SEBSearchFieldCell.h"

@implementation SEBSearchFieldCell

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ( menuItem.action == @selector(performFindPanelAction:)) {
        return menuItem.tag != NSFindPanelActionSetFindString; // No use allowing "Use Selection for Find", since it will always be equal to the current find string, where it exists.
    } else {
        return [super validateMenuItem:menuItem];
    }
}

@end
