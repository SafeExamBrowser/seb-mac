//
//  ProhibitedProcessesArrayController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 23.08.20.
//

#import <Cocoa/Cocoa.h>
#import "PrefsApplicationsViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ProhibitedProcessesArrayController : NSArrayController
@property (weak) IBOutlet PrefsApplicationsViewController *prefsApplicationViewController;

@end

NS_ASSUME_NONNULL_END
