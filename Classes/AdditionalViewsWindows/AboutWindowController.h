//
//  AboutWindowController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 19.01.21.
//

#import <Cocoa/Cocoa.h>


@interface AboutWindowController: NSWindowController <NSWindowDelegate>

- (void) showAboutWindowForSeconds:(NSInteger)minutes;
- (void) closeAboutWindow:(NSNotification *)notification;

@end

