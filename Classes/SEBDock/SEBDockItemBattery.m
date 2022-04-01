//
//  SEBDockItemBattery.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 14.12.20.
//

#import "SEBDockItemBattery.h"

@import Foundation;
@import IOKit.ps;

@implementation SEBDockItemBattery

- (void) startDisplayingBattery
{
    CGFloat dockHeight = [[NSUserDefaults standardUserDefaults] secureDoubleForKey:@"org_safeexambrowser_SEB_taskBarHeight"];
    dockScale = dockHeight / SEBDefaultDockHeight;
    
    if (@available(macOS 10.14.0, *)) {
    } else {
        backgroundView.alphaValue = 0.5;
    }
    if (itemSize == 0) {
        itemSize = self.view.frame.size.width;
    }
    batteryIconWidthConstraint.constant = itemSize * dockScale;
    batteryIconHeightConstraint.constant = itemSize * dockScale;

    if (batteryLevelConstant == 0) {
        batteryLevelConstant = batteryLevelConstraint.constant;
    }
    batteryLevelTrailingConstant = batteryLevelConstant * dockScale;
    batteryLevelConstraint.constant = batteryLevelTrailingConstant;
    
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
    
    batteryLevelWidth = batteryIconWidthConstraint.constant - batteryLevelLeading.constant - batteryLevelConstraint.constant;
    
    systemGreenCGColor = [[NSColor systemGreenColor] CGColor];
    systemOrangeCGColor = [[NSColor systemOrangeColor] CGColor];
    systemRedCGColor = [[NSColor systemRedColor] CGColor];

    [backgroundView setWantsLayer:YES];
    
    _batteryLevel = 100;
    [backgroundView.layer setBackgroundColor:systemGreenCGColor];
    
    [_batteryController addDelegate:self];
}


- (void) updateBatteryLevel:(double)batteryLevel infoString:(nonnull NSString *)infoString
{
    _batteryLevel = batteryLevel;
    CGFloat currentLevelConstraint = batteryLevelWidth - (batteryLevelWidth / 110 * (batteryLevel+10)) + batteryLevelTrailingConstant;
    batteryLevelConstraint.constant = currentLevelConstraint;
    [self setToolTip:infoString];
}


- (void) setPowerConnected:(BOOL)powerConnected warningLevel:(IOPSLowBatteryWarningLevel)batteryWarningLevel
{
    if (powerConnected) {
        batteryIconButton.image = [NSImage imageNamed:@"SEBBatteryIcon_charging"];
    } else {
        batteryIconButton.image = [NSImage imageNamed:@"SEBBatteryIcon"];
    }
    [self setBatteryColorWarningLevel:batteryWarningLevel];
}


- (void) setBatteryColorWarningLevel:(IOPSLowBatteryWarningLevel) batteryWarningLevel
{
    CGColorRef warningLevelColor;
    
    switch (batteryWarningLevel) {
        case kIOPSLowBatteryWarningEarly:
            warningLevelColor = systemOrangeCGColor;
            break;
            
        case kIOPSLowBatteryWarningFinal:
            warningLevelColor = systemRedCGColor;
            break;
            
        default:
            if (self.batteryLevel < 10.0) {
                warningLevelColor = systemOrangeCGColor;
            } else {
                warningLevelColor = systemGreenCGColor;
            }
            break;
    }
    [backgroundView.layer setBackgroundColor:warningLevelColor];
}


- (void) setToolTip:(NSString *)toolTip
{
    batteryIconButton.toolTip = toolTip;
}


@end
