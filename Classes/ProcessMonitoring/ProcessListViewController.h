//
//  ProcessListViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.07.20.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ProcessListViewControllerDelegate <NSObject>

- (void)closeProcessListWindowWithCallback:(id)callback
                                  selector:(SEL)selector;

@end

@interface ProcessListViewController : NSViewController

@property (weak) id delegate;

@property (strong) IBOutlet NSArrayController *processListArrayController;

@property (strong, nonatomic) NSMutableArray <NSRunningApplication *>*runningApplications;
@property (strong, nonatomic) NSMutableArray <NSDictionary *>*runningProcesses;

@property (weak, nonatomic) id callback;
@property (readwrite, nonatomic) SEL selector;

- (void)didTerminateRunningApplications:(NSArray *)terminatedApplications;

@end

NS_ASSUME_NONNULL_END
