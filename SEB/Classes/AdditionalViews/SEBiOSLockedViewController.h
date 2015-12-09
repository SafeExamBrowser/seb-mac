//
//  SEBiOSLockedViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03/12/15.
//
//

#import <UIKit/UIKit.h>
#import "SEBLockedViewController.h"

@interface SEBiOSLockedViewController : UIViewController <SEBLockedViewUIDelegate>

@property (strong) SEBLockedViewController *lockedViewController;
@property (nonatomic, strong) id< SEBLockedViewControllerDelegate > controllerDelegate;

@property (readwrite, copy) NSAttributedString *resignActiveLogString;

- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime;

- (void)scrollToBottom;

@end
