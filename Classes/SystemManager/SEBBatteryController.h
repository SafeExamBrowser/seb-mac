//
//  SEBBatteryController.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 01.04.22.
//

#import <Foundation/Foundation.h>
@import IOKit.ps;

NS_ASSUME_NONNULL_BEGIN

@protocol SEBBatteryControllerDelegate <NSObject>

- (void) updateBatteryLevel:(double)batteryLevel infoString:(NSString *)infoString;
- (void) setPowerConnected:(BOOL)powerConnected warningLevel:(IOPSLowBatteryWarningLevel) batteryWarningLevel;

@end


@interface SEBBatteryController : NSObject {
    NSTimer *batteryTimer;
    CFRunLoopSourceRef powerSourceMonitoringLoop;
    double lastBatteryLevel;
}

@property (strong) NSArray *delegates;
@property (readonly) double batteryLevel;

- (void) addDelegate:(id <SEBBatteryControllerDelegate>)delegate;
- (void) startMonitoringBattery;
- (void) stopMonitoringBattery;

@end

NS_ASSUME_NONNULL_END
