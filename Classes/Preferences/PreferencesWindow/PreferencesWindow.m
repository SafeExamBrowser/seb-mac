//
//  PreferencesWindow.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 31/08/14.
//
//

#import "PreferencesWindow.h"

@implementation PreferencesWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
     self = [super initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation];
    if (self) {
        [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    }
    return self;
}


- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender {
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    return NSDragOperationCopy;
}


- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
    
    if (1 == filenames.count)
        if ([[NSApp delegate] respondsToSelector:@selector(application:openFile:)])
            return [[NSApp delegate] application:NSApp openFile:[filenames lastObject]];
    
    return NO;
}

@end
