//
//  SEBDockWindow.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 17.09.14.
//
//

#import "SEBDockWindow.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"

@implementation SEBDockWindow

- (void) setCalculatedFrame
{
    // Get frame of the main screen
    NSRect screenFrame = self.screen.frame;

    // Get SEB Dock height
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    double dockHeight = [preferences secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
    // Enforce minimum SEB Dock height
    if (dockHeight < 40) dockHeight = 40;
    
    // Calculate frame of SEB Dock
    NSRect windowFrame;
    windowFrame.origin.x = screenFrame.origin.x;

    windowFrame.size.width = screenFrame.size.width;
    windowFrame.size.height = dockHeight;

    // Calculate y position: On bottom of screen
    windowFrame.origin.y = screenFrame.origin.y;
    // Change Window size
    [self setFrame:windowFrame display:YES];    
}


@end
