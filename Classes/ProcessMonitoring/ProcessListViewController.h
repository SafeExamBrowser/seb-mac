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

@property (strong, nonatomic) NSArray <NSRunningApplication *>*runningApplications;
@property (strong, nonatomic) NSArray <NSDictionary *>*runningProcesses;

@end

NS_ASSUME_NONNULL_END
