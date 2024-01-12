//
//  PreferencesWindow.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 31/08/14.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

// Subclass for the preferences window, implements drag and drop for .seb files

#import "PreferencesWindow.h"

@implementation PreferencesWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation
{
    self = [super initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)style backing:(NSBackingStoreType)bufferingType defer:(BOOL)deferCreation];
    if (self) {
        if (@available(macOS 10.13, *)) {
            [self registerForDraggedTypes:[NSArray arrayWithObject:NSPasteboardTypeURL]];
        } else {
            [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
        }
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
    NSString *filename;
    if (@available(macOS 10.13, *)) {
//        NSDictionary *filteringOptions = @
        NSArray<NSURL*> *fileURLs = [pboard readObjectsForClasses:@[NSURL.class] options:@{}];
        if (fileURLs.count == 1) {
            NSURL *fileURL = fileURLs.lastObject.filePathURL;
            filename = fileURL.absoluteString;
        }
    } else {
        NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
        if (filenames.count == 1) {
            filename = [filenames lastObject];
        }
    }
    
    if (filename) {
        if ([[NSApp delegate] respondsToSelector:@selector(application:openFile:)]) {
            if (filename.pathExtension && [filename.pathExtension caseInsensitiveCompare:SEBFileExtension] == NSOrderedSame) {
                return [(SEBController *)[NSApp delegate] application:NSApp openFile:filename];
            }
        }
    }
    
    return NO;
}


@end
