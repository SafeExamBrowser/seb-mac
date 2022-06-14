//
//  SEBBatteryController.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 01.04.22.
//

#import "SEBBatteryController.h"

@import Foundation;
#if TARGET_OS_OSX
@import IOKit.ps;
#endif

@implementation SEBBatteryController


- (void) addDelegate:(id <SEBBatteryControllerDelegate>)delegate
{
    NSArray *currentDelegates = _delegates.copy;
    if (!currentDelegates) {
        _delegates = [NSArray arrayWithObject:delegate];
    } else {
        _delegates = [currentDelegates arrayByAddingObject:delegate];
    }
}


- (void) startMonitoringBattery
{
#if TARGET_OS_OSX
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
    [self updateBatteryLevel];

    powerSourceMonitoringLoop = IOPSNotificationCreateRunLoopSource(powerSourceMonitoringCallbackMethod, (__bridge void *)(self));
    if (powerSourceMonitoringLoop) {
        CFRunLoopAddSource(CFRunLoopGetCurrent(), powerSourceMonitoringLoop, kCFRunLoopDefaultMode);
    }
#else
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBatteryLevel)
                                                 name:UIDeviceBatteryLevelDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBatteryLevel)
                                                 name:UIDeviceBatteryStateDidChangeNotification
                                               object:nil];
    [self updateBatteryLevel];
#endif
}

- (void)timerFireMethod:(NSTimer *)timer
{
    DDLogVerbose(@"Dock battery display timer fired");

    [self updateBatteryLevel];
}


#if TARGET_OS_OSX
void powerSourceMonitoringCallbackMethod(void *context)
{
    IOPSLowBatteryWarningLevel batteryWarningLevel = IOPSGetBatteryWarningLevel();
    CFTimeInterval remainingTime = IOPSGetTimeRemainingEstimate();
    [(__bridge SEBBatteryController *)context setPowerConnected:remainingTime == kIOPSTimeRemainingUnlimited warningLevel:batteryWarningLevel];
}


- (void) setPowerConnected:(BOOL)powerConnected warningLevel:(IOPSLowBatteryWarningLevel) batteryWarningLevel
{
    NSArray *currentDelegates = _delegates.copy;
    for (id <SEBBatteryControllerDelegate> delegate in currentDelegates) {
        [delegate setPowerConnected:powerConnected warningLevel:(SEBLowBatteryWarningLevel)batteryWarningLevel];
    }
}
#endif


- (void) updateBatteryLevel
{
    double batteryLevel = self.batteryLevel;
    BOOL powerSourceConnectedState = self.powerSourceConnected;
    if (batteryLevel != lastBatteryLevel ||
        powerSourceConnectedState != lastPowerSourceConnectedState) {
        lastBatteryLevel = batteryLevel;
        lastPowerSourceConnectedState = powerSourceConnectedState;
        NSString *additionalBatteryInformation;
#if TARGET_OS_OSX
        CFTimeInterval remainingTime = IOPSGetTimeRemainingEstimate();
        int hoursRemaining = remainingTime/3600;
        int minutesRemaining = (remainingTime - hoursRemaining*3600)/60;
        additionalBatteryInformation = remainingTime == kIOPSTimeRemainingUnlimited ?
                                        NSLocalizedString(@" (Connected to Power Source)", nil) :
                                        ((remainingTime == kIOPSTimeRemainingUnknown ?
                                          @"" :
                                          [NSString stringWithFormat:NSLocalizedString(@" (%d:%d Remaining)", nil), hoursRemaining, minutesRemaining]));
#else
        additionalBatteryInformation = powerSourceConnectedState ? NSLocalizedString(@" (Connected to Power Source)", nil) : @"";
#endif
        NSString *infoString = [NSString stringWithFormat:NSLocalizedString(@"Battery Level %.f%%%@", nil), batteryLevel, additionalBatteryInformation];
        NSArray *currentDelegates = _delegates.copy;
        for (id <SEBBatteryControllerDelegate> delegate in currentDelegates) {
            [delegate updateBatteryLevel:batteryLevel infoString:infoString];
        }
    }
}


- (void) stopMonitoringBattery
{
    DDLogVerbose(@"%s", __FUNCTION__);
#if TARGET_OS_OSX
    [batteryTimer invalidate];
    if (powerSourceMonitoringLoop) {
        CFRunLoopSourceInvalidate(powerSourceMonitoringLoop);
        CFRelease(powerSourceMonitoringLoop);
    }
#else
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
}


- (double) batteryLevel
{
#if TARGET_OS_OSX
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
#else
    return (double)(UIDevice.currentDevice.batteryLevel*100);
#endif
}


- (BOOL) powerSourceConnected
{
#if TARGET_OS_OSX
        CFTimeInterval remainingTime = IOPSGetTimeRemainingEstimate();
    return remainingTime == kIOPSTimeRemainingUnlimited;
#else
    UIDeviceBatteryState batteryState = UIDevice.currentDevice.batteryState;
    return batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull;
#endif
}


@end
