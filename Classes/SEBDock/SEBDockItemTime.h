//
//  SEBDockItemTime.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/10/15.
//
//

#import "SEBDockItem.h"

@interface SEBDockItemTime : SEBDockItem {
    
    IBOutlet NSTextField *timeTextField;
    CGFloat preferredMaxLayoutWidth;
    NSTimer *clockTimer;
}

@property (strong, nonatomic) IBOutlet NSView *view;

- (id) initWithToolTip:(NSString *)newToolTip;

- (void) startDisplayingTime;


@end
