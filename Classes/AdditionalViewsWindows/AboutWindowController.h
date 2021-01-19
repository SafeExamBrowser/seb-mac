//
//  AboutWindowController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 19.01.21.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface AboutWindowController: NSWindowController <NSWindowDelegate>

- (void) showAboutWindowForSeconds:(NSInteger)minutes;
- (void) closeAboutWindow:(NSNotification *)notification;

@end

NS_ASSUME_NONNULL_END
