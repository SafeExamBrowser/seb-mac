//
//  SEBDockItemTime.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24/10/15.
//
//

#import "SEBDockItemTime.h"

@implementation SEBDockItemTime

- (id) initWithToolTip:(NSString *)newToolTip
{
    self = [super initWithTitle:nil icon:nil highlightedIcon:nil toolTip:newToolTip menu:nil target:nil action:nil];
    if (self) {
    }
    return self;
}


- (void) startDisplayingTime
{
    NSDate *dateNow = [NSDate date];
    
    NSFont *itemFont = timeTextField.font;
    CGFloat dockHeight = [[NSUserDefaults standardUserDefaults] secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
    CGFloat dockScale = dockHeight / SEBDefaultDockHeight;
    if (preferredMaxLayoutWidth == 0) {
        if (@available(macOS 10.8, *)) {
            preferredMaxLayoutWidth = timeTextField.preferredMaxLayoutWidth;
            timeTextField.preferredMaxLayoutWidth = preferredMaxLayoutWidth * dockScale;
        } else {
            preferredMaxLayoutWidth = timeTextField.frame.size.width * dockScale;
            timeTextField.frame = NSMakeRect(timeTextField.frame.origin.x,
                                             timeTextField.frame.origin.y,
                                             preferredMaxLayoutWidth,
                                             timeTextField.frame.size.height * dockScale);
        }
    }
    CGFloat fontSize = dockScale * SEBDefaultDockTimeItemFontSize;
    
    NSFont *newFont = [NSFont fontWithName:itemFont.fontName size:fontSize];
    timeTextField.font = newFont;
    
    [timeTextField setObjectValue:dateNow];
    
    NSTimeInterval timestamp = [dateNow timeIntervalSinceReferenceDate];
    NSTimeInterval currentFullMinute = timestamp - fmod(timestamp, 60);
    NSTimeInterval nextFullMinute = currentFullMinute + 60;
    
    NSDate *dateNextMinute = [NSDate dateWithTimeIntervalSinceReferenceDate:nextFullMinute];
    
    clockTimer = [[NSTimer alloc] initWithFireDate: dateNextMinute
                                          interval: 60
                                            target: self
                                          selector:@selector(timerFireMethod:)
                                          userInfo:nil repeats:YES];
    
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    [currentRunLoop addTimer:clockTimer forMode: NSDefaultRunLoopMode];
}


- (void)timerFireMethod:(NSTimer *)timer
{
    DDLogVerbose(@"Dock time display timer fired");

    NSTimeInterval timestamp = [[timer fireDate] timeIntervalSinceReferenceDate];
    NSTimeInterval currentFullMinute = timestamp - fmod(timestamp, 60);
    NSTimeInterval nextFullMinute = currentFullMinute + 60;
    
    [timer setFireDate: [NSDate dateWithTimeIntervalSinceReferenceDate:nextFullMinute]];

    [timeTextField setObjectValue:[NSDate date]];
}


// To do: This is not being called and timer not released
- (void) dealloc {
    [clockTimer invalidate];
}


@end
