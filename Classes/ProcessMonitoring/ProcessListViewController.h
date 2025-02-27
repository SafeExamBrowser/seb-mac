//
//  ProcessListViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.07.20.
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

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ProcessListViewControllerDelegate <NSObject>

- (NSMutableArray *)checkProcessesRunning:(NSMutableArray *)runningProcesses;
- (void) closeProcessListWindow;
- (void) closeProcessListWindowWithCallback:(id _Nullable)callback
                                  selector:(SEL)selector;
- (NSAlert *) newAlert;
- (void) removeAlertWindow:(NSWindow *)alertWindow;
- (void) runModalAlert:(NSAlert *)alert
conditionallyForWindow:(NSWindow *)window
     completionHandler:(nullable void (^)(NSModalResponse returnCode))handler;
- (void) quitSEBOrSession;

@property (readwrite) BOOL quittingSession;

@end

@interface ProcessListViewController : NSViewController <NSWindowDelegate>

@property (weak) id <ProcessListViewControllerDelegate> delegate;

@property (strong) IBOutlet NSArrayController *processListArrayController;

@property (strong, atomic) NSMutableArray <NSRunningApplication *>*runningApplications;
@property (strong, atomic) NSMutableArray <NSDictionary *>*runningProcesses;
@property (readwrite, nonatomic) dispatch_source_t processWatchTimer;
@property (readwrite) BOOL windowOpen;
@property (readwrite) BOOL autoQuitApplications;
@property (readwrite) BOOL starting;
@property (readwrite) BOOL restarting;

@property (weak, nonatomic) id callback;
@property (readwrite, nonatomic) SEL selector;

@property (strong, nonatomic) NSAlert *_Nullable modalAlert;

- (void)didTerminateRunningApplications:(NSArray *)terminatedApplications;

@end

NS_ASSUME_NONNULL_END
