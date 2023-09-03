//
//  AboutWindowController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 19.01.21.
//

#import "AboutWindowController.h"

@interface AboutWindowController ()

@end

@implementation AboutWindowController


- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (void)windowWillClose:(NSNotification *)notification
{
    DDLogDebug(@"%s About SEB window will be closed.", __FUNCTION__);
}


- (void)showAboutWindowForSeconds:(NSInteger)seconds {
    // Show the About SEB Window
    [self.window setDelegate:self];
    [self.window setStyleMask:NSWindowStyleMaskBorderless];
    [self.window center];
    if ([[NSUserDefaults standardUserDefaults] secureBoolForKey:@"org_safeexambrowser_elevateWindowLevels"]) {
        [self.window setLevel:NSMainMenuWindowLevel+5];
    } else {
        [self.window setLevel:NSModalPanelWindowLevel-1];
    }
    DDLogDebug(@"orderFront About Window");
//    [self showWindow:nil];
    [self.window orderFront:self];
    
    // Close the About SEB Window after a delay
    DDLogDebug(@"%s Close About SEB window after a delay of %ld seconds", __FUNCTION__, (long)seconds);
    [self performSelector:@selector(closeAboutWindow:) withObject: nil afterDelay: seconds];

}


// Close the About Window
- (void) closeAboutWindow:(NSNotification *)notification {
    DDLogDebug(@"Attempting to close About Window %@", self);
    [self.window orderOut:self];
}


@end
