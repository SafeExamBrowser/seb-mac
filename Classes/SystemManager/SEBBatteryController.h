//
//  SEBBatteryController.h
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
