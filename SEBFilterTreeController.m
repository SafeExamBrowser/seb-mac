//
//  SEBFilterTreeController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 13.05.13.
//
//

#import "SEBFilterTreeController.h"

@implementation SEBFilterTreeController


// Overridden method which checks if a first level object should be added
//- (void)add:(id)sender
//{
//    
//}


//- (void)addChild:(id)sender
//{
//    if (self.selectionIndexPath.length == 1) {
//        [super addChild:sender];
//    }
//}

- (BOOL)canAddChild
{
    if (self.selectionIndexPath.length == 1) {
        return YES;
    }
    return NO;
}

@end
