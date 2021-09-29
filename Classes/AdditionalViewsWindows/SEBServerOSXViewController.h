//
//  SEBServerOSXViewController.h
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 24.09.21.
//

#import <Cocoa/Cocoa.h>
#import "ServerController.h"

@class ServerController;

NS_ASSUME_NONNULL_BEGIN

@interface SEBServerOSXViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate, ServerControllerUIDelegate>

@property (weak, nonatomic) SEBServerController *sebServerController;
@property (weak, nonatomic) id <ServerControllerDelegate> serverControllerDelegate;
@property (weak, nonatomic) NSArray * exams;

@property (strong, nonatomic) NSTableView *examsTableView;

@end

NS_ASSUME_NONNULL_END
