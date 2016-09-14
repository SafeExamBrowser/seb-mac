//
//  HUDWindow.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 14/09/16.
//
//

#import <Cocoa/Cocoa.h>

@interface HUDPanel : NSPanel

- (BOOL)canBecomeMainWindow;
- (BOOL)canBecomeKeyWindow;

@end
