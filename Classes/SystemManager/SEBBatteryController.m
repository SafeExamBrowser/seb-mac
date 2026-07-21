//
//  SEBBatteryController.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 01.04.22.
//  Copyright (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 2.0 (the "License"); you may not use this file except in
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
//  (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
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

@interface SEBBatteryController ()
- (void) sendCurrentBatteryStateToDelegate:(id <SEBBatteryControllerDelegate>)delegate;
- (NSString *) batteryInfoStringForLevel:(double)batteryLevel;
@end

@implementation SEBBatteryController


- (void) addDelegate:(id <SEBBatteryControllerDelegate>)delegate
{
    NSArray *currentDelegates = _delegates.copy;
    if (!currentDelegates) {
        _delegates = [NSArray arrayWithObject:delegate];
    } else {
        _delegates = [currentDelegates arrayByAddingObject:delegate];
    }
    // Immediately push the current battery state to the newly added delegate.
    // Otherwise a freshly created (or reset) delegate like the Dock battery item
    // stays at its default display until updateBatteryLevel detects a *change* -
    // which never happens if this controller is reused and its cached level
    // already matches the current level (e.g. when the Dock is rebuilt within a
    // session). That is what made the Dock battery indicator stick at "full".
    [self sendCurrentBatteryStateToDelegate:delegate];
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
    // Use common modes so the timer keeps firing while the run loop is in event
    // tracking or modal panel mode (otherwise the indicator freezes during those).
    [currentRunLoop addTimer:batteryTimer forMode: NSRunLoopCommonModes];
    
    powerSourceMonitoringCallbackMethod((__bridge void *)(self));
    [self updateBatteryLevel];

    powerSourceMonitoringLoop = IOPSNotificationCreateRunLoopSource(powerSourceMonitoringCallbackMethod, (__bridge void *)(self));
    if (powerSourceMonitoringLoop) {
        CFRunLoopAddSource(CFRunLoopGetCurrent(), powerSourceMonitoringLoop, kCFRunLoopCommonModes);
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
        NSString *infoString = [self batteryInfoStringForLevel:batteryLevel];
        NSArray *currentDelegates = _delegates.copy;
        for (id <SEBBatteryControllerDelegate> delegate in currentDelegates) {
            [delegate updateBatteryLevel:batteryLevel infoString:infoString];
        }
    }
}


// Push the currently read battery level and power state to a single delegate,
// bypassing the change detection in updateBatteryLevel. Used to initialise a
// newly added delegate.
- (void) sendCurrentBatteryStateToDelegate:(id <SEBBatteryControllerDelegate>)delegate
{
    double batteryLevel = self.batteryLevel;
    NSString *infoString = [self batteryInfoStringForLevel:batteryLevel];
    [delegate updateBatteryLevel:batteryLevel infoString:infoString];
#if TARGET_OS_OSX
    IOPSLowBatteryWarningLevel batteryWarningLevel = IOPSGetBatteryWarningLevel();
    [delegate setPowerConnected:self.powerSourceConnected warningLevel:(SEBLowBatteryWarningLevel)batteryWarningLevel];
#endif
}


- (NSString *) batteryInfoStringForLevel:(double)batteryLevel
{
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
    additionalBatteryInformation = self.powerSourceConnected ? NSLocalizedString(@" (Connected to Power Source)", @"") : @"";
#endif
    return [NSString stringWithFormat:NSLocalizedString(@"Battery Level %.f%%%@", @""), batteryLevel, additionalBatteryInformation];
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
    double percent = -1.0;

    CFTypeRef blob = IOPSCopyPowerSourcesInfo();
    if (!blob) {
        return -1.0;
    }
    CFArrayRef sources = IOPSCopyPowerSourcesList(blob);
    if (sources) {
        long numOfSources = CFArrayGetCount(sources);
        for (int i = 0 ; i < numOfSources ; i++) {
            CFDictionaryRef pSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, i));
            if (!pSource) {
                continue;
            }
            // Only consider the internal battery, and only if it is actually
            // present, so we don't accidentally report another power source
            // (e.g. a UPS) or read a source whose data isn't populated yet.
            CFStringRef psType = CFDictionaryGetValue(pSource, CFSTR(kIOPSTypeKey));
            if (psType && !CFEqual(psType, CFSTR(kIOPSInternalBatteryType))) {
                continue;
            }
            CFBooleanRef isPresent = CFDictionaryGetValue(pSource, CFSTR(kIOPSIsPresentKey));
            if (isPresent && !CFBooleanGetValue(isPresent)) {
                continue;
            }
            int curCapacity = 0;
            int maxCapacity = 0;
            CFNumberRef curValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSCurrentCapacityKey));
            CFNumberRef maxValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSMaxCapacityKey));
            // Skip this source if the capacity values aren't (yet) available or
            // would lead to a division by zero - avoids a bogus reading at launch.
            if (!curValue || !maxValue ||
                !CFNumberGetValue(curValue, kCFNumberSInt32Type, &curCapacity) ||
                !CFNumberGetValue(maxValue, kCFNumberSInt32Type, &maxCapacity) ||
                maxCapacity <= 0) {
                continue;
            }
            percent = ((double)curCapacity / (double)maxCapacity) * 100.0;
            break;
        }
        CFRelease(sources);
    }
    CFRelease(blob);
    return percent;
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
