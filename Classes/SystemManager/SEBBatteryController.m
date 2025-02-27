//
//  SEBBatteryController.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 01.04.22.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
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
                                        NSLocalizedString(@" (Connected to Power Source)", @"") :
                                        ((remainingTime == kIOPSTimeRemainingUnknown ?
                                          @"" :
                                          [NSString stringWithFormat:NSLocalizedString(@" (%d:%d Remaining)", @""), hoursRemaining, minutesRemaining]));
#else
        additionalBatteryInformation = powerSourceConnectedState ? NSLocalizedString(@" (Connected to Power Source)", @"") : @"";
#endif
        NSString *infoString = [NSString stringWithFormat:NSLocalizedString(@"Battery Level %.f%%%@", @""), batteryLevel, additionalBatteryInformation];
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
