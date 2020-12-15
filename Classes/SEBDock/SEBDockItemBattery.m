//
//  SEBDockItemBattery.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 14.12.20.
//

#import "SEBDockItemBattery.h"

@implementation SEBDockItemBattery

- (void) startDisplayingBattery
{
    CGFloat dockHeight = [[NSUserDefaults standardUserDefaults] secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
    dockScale = dockHeight / SEBDefaultDockHeight;
    
    if (itemSize == 0) {
        itemSize = self.view.frame.size.width;
    }
    batteryIconWidthConstraint.constant = itemSize * dockScale;
    batteryIconHeightConstraint.constant = itemSize * dockScale;

    if (batteryLevelConstant == 0) {
        batteryLevelConstant = batteryLevelConstraint.constant;
    }
    batteryLevelConstraint.constant = batteryLevelConstant * dockScale;
    
    if (batteryLevelLeadingConstant == 0) {
        batteryLevelLeadingConstant = batteryLevelLeading.constant;
    }
    batteryLevelLeading.constant = batteryLevelLeadingConstant * dockScale;
    
    if (batteryLevelTopConstant == 0) {
        batteryLevelTopConstant = batteryLevelTop.constant;
    }
    batteryLevelTop.constant = batteryLevelTopConstant * dockScale;
    
    if (batteryLevelBottomConstant == 0) {
        batteryLevelBottomConstant = batteryLevelBottom.constant;
    }
    batteryLevelBottom.constant = batteryLevelBottomConstant * dockScale;
    
    [backgroundView setWantsLayer:YES];
    [backgroundView.layer setBackgroundColor:[[NSColor systemGreenColor] CGColor]];

    NSDate *dateNow = [NSDate date];
    NSTimeInterval timestamp = [dateNow timeIntervalSinceReferenceDate];
    NSTimeInterval currentFullMinute = timestamp - fmod(timestamp, 60);
    NSTimeInterval nextFullMinute = currentFullMinute + 60;
    
    NSDate *dateNextMinute = [NSDate dateWithTimeIntervalSinceReferenceDate:nextFullMinute];
    
    batteryTimer = [[NSTimer alloc] initWithFireDate: dateNextMinute
                                          interval: 60
                                            target: self
                                          selector:@selector(timerFireMethod:)
                                          userInfo:nil repeats:YES];
    
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    [currentRunLoop addTimer:batteryTimer forMode: NSDefaultRunLoopMode];
}


- (void)timerFireMethod:(NSTimer *)timer
{
    DDLogVerbose(@"Dock time display timer fired");

    NSTimeInterval timestamp = [[timer fireDate] timeIntervalSinceReferenceDate];
    NSTimeInterval currentFullMinute = timestamp - fmod(timestamp, 60);
    NSTimeInterval nextFullMinute = currentFullMinute + 60;
    
    [timer setFireDate: [NSDate dateWithTimeIntervalSinceReferenceDate:nextFullMinute]];

//    [timeTextField setObjectValue:[NSDate date]];
}


- (void) setToolTip:(NSString *)toolTip
{
    batteryIconButton.toolTip = toolTip;
}


// To do: This is not being called and timer not released
- (void) dealloc {
    [batteryTimer invalidate];
}


@end
