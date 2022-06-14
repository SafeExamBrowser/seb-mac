//
//  SEBBatteryController.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 01.04.22.
//

#import <Foundation/Foundation.h>
#if TARGET_OS_OSX
@import IOKit.ps;
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol SEBBatteryControllerDelegate <NSObject>

- (void) updateBatteryLevel:(double)batteryLevel infoString:(NSString *)infoString;
- (void) setPowerConnected:(BOOL)powerConnected warningLevel:(SEBLowBatteryWarningLevel) batteryWarningLevel;

@end


@interface SEBBatteryController : NSObject {
    NSTimer *batteryTimer;
    CFRunLoopSourceRef powerSourceMonitoringLoop;
    double lastBatteryLevel;
    BOOL lastPowerSourceConnectedState;
}

@property (strong) NSArray *delegates;
@property (readonly) double batteryLevel;
@property (readonly) BOOL powerSourceConnected;

- (void) addDelegate:(id <SEBBatteryControllerDelegate>)delegate;
- (void) startMonitoringBattery;
- (void) stopMonitoringBattery;

@end

NS_ASSUME_NONNULL_END
