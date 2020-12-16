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
    
    powerSourceMonitoringCallbackMethod((__bridge void *)(self));
    [self displayBatteryPercentage];

    powerSourceMonitoringLoop = IOPSNotificationCreateRunLoopSource(powerSourceMonitoringCallbackMethod, (__bridge void *)(self));
    if (powerSourceMonitoringLoop) {
        CFRunLoopAddSource(CFRunLoopGetCurrent(), powerSourceMonitoringLoop, kCFRunLoopDefaultMode);
    }
}


- (void)timerFireMethod:(NSTimer *)timer
{
    DDLogVerbose(@"Dock battery display timer fired");

    [self displayBatteryPercentage];
}


void powerSourceMonitoringCallbackMethod(void *context)
{
    IOPSLowBatteryWarningLevel batteryWarningLevel = IOPSGetBatteryWarningLevel();
    CFTimeInterval remainingTime = IOPSGetTimeRemainingEstimate();
    if (remainingTime == kIOPSTimeRemainingUnlimited) {
        [(__bridge SEBDockItemBattery *)context setPowerConnectedIcon:batteryWarningLevel];
    } else {
        [(__bridge SEBDockItemBattery *)context setPowerNotConnectedIcon:batteryWarningLevel];
    }
}


- (void) displayBatteryPercentage
{
    double batteryLevel = [self batteryLevel];
    CGFloat currentLevelConstraint = batteryLevelWidth - (batteryLevelWidth / 100 * batteryLevel) + batteryLevelTrailingConstant;
    batteryLevelConstraint.constant = currentLevelConstraint;
    CFTimeInterval remainingTime = IOPSGetTimeRemainingEstimate();
    int hoursRemaining = remainingTime/3600;
    int minutesRemaining = (remainingTime - hoursRemaining*3600)/60;
    [self setToolTip:[NSString stringWithFormat:@"Battery Level %.f%%%@", batteryLevel,
                      (remainingTime == kIOPSTimeRemainingUnlimited ?
                       @" (Connected to Power Source)" :
                       ((remainingTime == kIOPSTimeRemainingUnknown ?
                         @"" :
                         [NSString stringWithFormat:@" (%d:%d Remaining)", hoursRemaining, minutesRemaining])))]];
}


- (void) setPowerNotConnectedIcon:(IOPSLowBatteryWarningLevel) batteryWarningLevel
{
    batteryIconButton.image = [NSImage imageNamed:@"SEBBatteryIcon"];
    [self setBatteryColorWarningLevel:batteryWarningLevel];
}

- (void) setPowerConnectedIcon:(IOPSLowBatteryWarningLevel) batteryWarningLevel
{
    batteryIconButton.image = [NSImage imageNamed:@"SEBBatteryIcon_charging"];
    [self setBatteryColorWarningLevel:batteryWarningLevel];
}

- (void) setBatteryColorWarningLevel:(IOPSLowBatteryWarningLevel) batteryWarningLevel
{
    CGColorRef warningLevelColor;
    
    switch (batteryWarningLevel) {
        case kIOPSLowBatteryWarningEarly:
            warningLevelColor = [[NSColor systemOrangeColor] CGColor];
            break;
            
        case kIOPSLowBatteryWarningFinal:
            warningLevelColor = [[NSColor systemRedColor] CGColor];
            break;
            
        default:
            warningLevelColor = [[NSColor systemGreenColor] CGColor];
            break;
    }
    [backgroundView.layer setBackgroundColor:warningLevelColor];
}

- (void) setToolTip:(NSString *)toolTip
{
    batteryIconButton.toolTip = toolTip;
}


// To do: Is this being called?
- (void) dealloc
{
    DDLogVerbose(@"%s", __FUNCTION__);
    
    [batteryTimer invalidate];
    if (powerSourceMonitoringLoop) {
        CFRunLoopSourceInvalidate(powerSourceMonitoringLoop);
        CFRelease(powerSourceMonitoringLoop);
    }
}


- (double) batteryLevel
{
  CFTypeRef blob = IOPSCopyPowerSourcesInfo();
  CFArrayRef sources = IOPSCopyPowerSourcesList(blob);
  
  CFDictionaryRef pSource = NULL;
  const void *psValue;
  
  long numOfSources = CFArrayGetCount(sources);
  if (numOfSources == 0) {
    NSLog(@"Error in CFArrayGetCount");
    return -1.0f;
  }
  
  for (int i = 0 ; i < numOfSources ; i++)
  {
    pSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, i));
    if (!pSource) {
      NSLog(@"Error in IOPSGetPowerSourceDescription");
        continue;;
    }
    psValue = (CFStringRef)CFDictionaryGetValue(pSource, CFSTR(kIOPSNameKey));
    
    int curCapacity = 0;
    int maxCapacity = 0;
    double percent;
    
    psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSCurrentCapacityKey));
    CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &curCapacity);
    
    psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSMaxCapacityKey));
    CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &maxCapacity);
    
    percent = ((double)curCapacity/(double)maxCapacity * 100.0f);
    
    return percent;
  }
  return -1.0f;
}


@end
