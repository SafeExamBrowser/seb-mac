//
//  SEBLockedView.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/09/15.
//
//

#import <Cocoa/Cocoa.h>
#import "SEBController.h"
#import "SEBKeychainManager.h"

@class SEBController;

@interface SEBLockedViewController : NSViewController

@property (strong) SEBController *sebController;
@property (strong) SEBKeychainManager *keychainManager;
@property (readwrite, copy) NSAttributedString *resignActiveLogString;

- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime;

@end
