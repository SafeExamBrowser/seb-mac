//
//  SEBiOSLockedViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03/12/15.
//
//

#import "SEBiOSLockedViewController.h"

@interface SEBiOSLockedViewController() {
    
    __weak IBOutlet UITextField *lockedAlertPasswordField;
    __weak IBOutlet UILabel *passwordWrongLabel;
    __weak IBOutlet UITextView *logTextView;
    
}
@end

@implementation SEBiOSLockedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lockedViewController = [[SEBLockedViewController alloc] init];
    self.lockedViewController.UIDelegate = self;
    self.lockedViewController.controllerDelegate = self.controllerDelegate;
    
    self.lockedViewController.boldFontAttributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:[UIFont systemFontSize]]};
    
    [lockedAlertPasswordField addTarget:lockedAlertPasswordField
                  action:@selector(resignFirstResponder)
        forControlEvents:UIControlEventEditingDidEndOnExit];
}


- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime {
    [self.lockedViewController appendErrorString:errorString withTime:errorTime];
}


- (void)scrollToBottom
{
    [logTextView scrollRangeToVisible:NSMakeRange([logTextView.text length], 0)];
}


- (IBAction)passwordEntered:(id)sender {
    [self.lockedViewController passwordEntered:sender];
}


- (void) closeLockdownWindows {
    
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}


- (NSString *)lockedAlertPassword {
    return lockedAlertPasswordField.text;
}


- (void)setLockedAlertPassword:(NSString *)password {
    lockedAlertPasswordField.text = password;
}


- (void)setPasswordWrongLabelHidden:(BOOL)hidden {
    passwordWrongLabel.hidden = hidden;
}


- (void)setResignActiveLogString:(NSAttributedString *)resignActiveLogString {
    logTextView.attributedText = resignActiveLogString;
}

- (NSAttributedString *)resignActiveLogString {
    return logTextView.attributedText;
}


@end
