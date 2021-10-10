//
//  SEBDockItemBattery.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 14.12.20.
//

#import "SEBDockItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface SEBDockItemBattery : SEBDockItem {
    __weak IBOutlet NSView *backgroundView;
    CGFloat dockScale;
    CGFloat itemSize;
    CGFloat batteryLevelWidth;
    CGFloat batteryLevelTrailingConstant;
    __weak IBOutlet NSLayoutConstraint *batteryLevelConstraint;
    CGFloat batteryLevelConstant;
    __weak IBOutlet NSLayoutConstraint *batteryLevelLeading;
    CGFloat batteryLevelLeadingConstant;
    __weak IBOutlet NSLayoutConstraint *batteryLevelTop;
    CGFloat batteryLevelTopConstant;
    __weak IBOutlet NSLayoutConstraint *batteryLevelBottom;
    CGFloat batteryLevelBottomConstant;
    __weak IBOutlet NSButton *batteryIconButton;
    __weak IBOutlet NSLayoutConstraint *batteryIconWidthConstraint;
    __weak IBOutlet NSLayoutConstraint *batteryIconHeightConstraint;
    CGColorRef systemGreenCGColor;
    CGColorRef systemOrangeCGColor;
    CGColorRef systemRedCGColor;

    NSTimer *batteryTimer;
    CFRunLoopSourceRef powerSourceMonitoringLoop;
    
    double lastBatteryLevel;
}

@property (strong, nonatomic) IBOutlet NSView *view;
@property (readonly) double batteryLevel;

- (void) startDisplayingBattery;

- (void) setToolTip:(NSString *)toolTip;

@end

NS_ASSUME_NONNULL_END
