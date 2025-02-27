//
//  ProcessManager.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 07.07.20.
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

@interface ProcessManager : NSObject

@property (strong, nonatomic) NSArray *prohibitedProcesses;
@property (strong, nonatomic) NSArray *permittedProcesses;
@property (strong, nonatomic) NSMutableArray *prohibitedRunningApplications;
@property (strong, nonatomic) NSMutableArray *permittedRunningApplications;
@property (strong, nonatomic) NSMutableArray *prohibitedBSDProcesses;
@property (strong, nonatomic) NSMutableArray *permittedBSDProcesses;

+ (ProcessManager *) sharedProcessManager;

+ (dispatch_source_t) createDispatchTimerWithInterval: (uint64_t)interval
                                               leeway:(uint64_t)leeway
                                        dispatchQueue:(dispatch_queue_t)queue
                                        dispatchBlock:(dispatch_block_t)block;

+ (NSString *) getExecutablePathForPID:(pid_t) runningExecutablePID;

- (void) updateMonitoredProcesses;
- (void) removeOverriddenProhibitedBSDProcesses:(NSArray *)overriddenProhibitedProcesses;
- (NSDictionary *) prohibitedProcessWithIdentifier:(NSString *)bundleID;
- (NSDictionary *) prohibitedProcessWithExecutable:(NSString *)executable;

@end
