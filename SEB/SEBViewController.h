//
//  ViewController.h
//  SEB
//
//  Created by Daniel R. Schneider on 10/09/15.
//
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "SEBLockedViewController.h"
#import "SEBiOSLockedViewController.h"

@interface SEBViewController : UIViewController <SEBLockedViewControllerDelegate>

@property (strong, nonatomic) SEBiOSLockedViewController< SEBLockedViewUIDelegate > *lockedViewController;

@property (strong, nonatomic) UIAlertController *alertController;
@property (strong, nonatomic) UIAlertController *guidedAccessWarningAC;

@property (strong, nonatomic) UIView *coveringView;

@property(readwrite) BOOL examRunning;
@property(readwrite) BOOL sebLocked;
@property(readwrite) BOOL unlockPasswordEntered;

@property(readwrite, strong) NSDate *didResignActiveTime;
@property(readwrite, strong) NSDate *didBecomeActiveTime;
@property(readwrite, strong) NSDate *didResumeExamTime;

- (void) showStartGuidedAccess;
- (void) showGuidedAccessWarning;
- (void) startExam;

@end

