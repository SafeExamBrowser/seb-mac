//
//  CapWindow.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 06.03.14.
//
//

#import <Cocoa/Cocoa.h>

@interface CapWindow : NSWindow {
    BOOL constrainingToScreenSuspended;
}

@property BOOL constrainingToScreenSuspended;

@end
