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

@interface SEBOSXLockedViewController : NSViewController <SEBLockedViewUIDelegate>

@property (strong) SEBKeychainManager *keychainManager;
@property (strong) SEBLockedViewController *lockedViewController;
@property (strong) id< SEBLockedViewControllerDelegate > controllerDelegate;

@property (readwrite, copy) NSAttributedString *resignActiveLogString;

- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime;

- (void)scrollToBottom;

@end
