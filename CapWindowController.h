//
//  CapWindowController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 11.03.14.
//
//

#import <Cocoa/Cocoa.h>

@interface CapWindowController : NSWindowController
{
    NSRect frameForNonFullScreenMode;
}

@property (assign) NSRect frameForNonFullScreenMode;


@end
