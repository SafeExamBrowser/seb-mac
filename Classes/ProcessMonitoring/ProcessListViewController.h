//
//  ProcessListViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.07.20.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProcessListViewController : NSViewController

@property (strong) IBOutlet NSArrayController *processListArrayController;

@property (strong, nonatomic) NSMutableArray <NSRunningApplication *>*runningApplications;
@property (strong, nonatomic) NSMutableArray <NSDictionary *>*runningProcesses;

- (void)didTerminateRunningApplications:(NSArray *)terminatedApplications;

@end

NS_ASSUME_NONNULL_END
