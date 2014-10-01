//
//  SEBDockWindow.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.09.14.
//
//

#import <Cocoa/Cocoa.h>

@interface SEBDockWindow : NSWindow

@property(readwrite) CGFloat height;


- (void) setCalculatedFrame:(NSScreen *)screen;

@end
