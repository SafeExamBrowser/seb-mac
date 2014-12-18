//
//  SEBFilterArrayController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 18.11.14.
//
//

#import "SEBFilterArrayController.h"

@implementation SEBFilterArrayController

-(id)newObject {
    id newObject = [super newObject];

    [newObject setValue:@YES forKey:@"active"];
    [newObject setValue:@NO forKey:@"regex"];
    [newObject setValue:[NSNumber numberWithLong:URLFilterActionAllow] forKey:@"action"];
    [newObject setValue:@"" forKey:@"expression"];

    return newObject;
}


- (void) remove:(id)sender
{
    NSUInteger selectedObjectIndex = [self selectionIndex];
    [super remove:sender];
    if (selectedObjectIndex != 0) {
        [self setSelectionIndex:selectedObjectIndex-1];
    }
}

//- (void)addObject:(id)object
//{
//    [super addObject:object];
//    [self removeSelectedObjects:[self selectedObjects]];
//    [self setSelectedObjects:@[object]];
//}


@end
