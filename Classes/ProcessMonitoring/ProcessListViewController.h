//
//  ProcessListViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 29.07.20.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ProcessListViewControllerDelegate <NSObject>

- (BOOL) checkProcessesRunning:(NSMutableArray __strong*_Nonnull*_Nonnull)runningProcesses;
- (void) closeProcessListWindow;
- (void) closeProcessListWindowWithCallback:(id)callback
                                  selector:(SEL)selector;
- (NSAlert *) newAlert;
- (void) removeAlertWindow:(NSWindow *)alertWindow;
- (void) quitSEBOrSession;

@property (readwrite) BOOL quittingMyself;
@property (readwrite) BOOL quitSession;

@end

@interface ProcessListViewController : NSViewController

@property (weak) id <ProcessListViewControllerDelegate> delegate;

@property (strong) IBOutlet NSArrayController *processListArrayController;

@property (strong, nonatomic) NSMutableArray <NSRunningApplication *>*runningApplications;
@property (strong, nonatomic) NSMutableArray <NSDictionary *>*runningProcesses;
@property (readwrite, nonatomic) dispatch_source_t processWatchTimer;

@property (weak, nonatomic) id callback;
@property (readwrite, nonatomic) SEL selector;

@property (strong, nonatomic) NSAlert *modalAlert;

- (void)didTerminateRunningApplications:(NSArray *)terminatedApplications;

@end

NS_ASSUME_NONNULL_END
