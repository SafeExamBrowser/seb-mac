//
//  SEBLockedView.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/09/15.
//
//

#import "SEBOSXLockedViewController.h"

@interface SEBOSXLockedViewController() {
    
    __weak IBOutlet NSSecureTextField *lockedAlertPasswordField;
    __weak IBOutlet NSTextField *passwordWrongLabel;
    __weak IBOutlet NSScrollView *logScrollView;

}
@end


@implementation SEBOSXLockedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.lockedViewController = [[SEBLockedViewController alloc] init];
    self.lockedViewController.UIDelegate = self;
    self.lockedViewController.controllerDelegate = self.controllerDelegate;

    self.lockedViewController.boldFontAttributes = @{NSFontAttributeName:[NSFont boldSystemFontOfSize:[NSFont systemFontSize]]};
}


- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime {
    [self.lockedViewController appendErrorString:errorString withTime:errorTime];
}


- (void)scrollToBottom
{
    NSPoint newScrollOrigin;
    
    if ([[logScrollView documentView] isFlipped]) {
        newScrollOrigin = NSMakePoint(0.0,NSMaxY([[logScrollView documentView] frame])
                                      -NSHeight([[logScrollView contentView] bounds]));
    } else {
        newScrollOrigin = NSMakePoint(0.0,0.0);
    }
    DDLogDebug(@"Log scroll view frame: %@, y coordinate to scroll to: %f", CGRectCreateDictionaryRepresentation([[logScrollView documentView] frame]), newScrollOrigin.y);
    
    [[logScrollView documentView] scrollPoint:newScrollOrigin];
}


- (IBAction)passwordEntered:(id)sender {
    [self.lockedViewController passwordEntered:sender];
}


- (NSString *)lockedAlertPassword {
    return lockedAlertPasswordField.stringValue;
}


- (void)setLockedAlertPassword:(NSString *)password {
    lockedAlertPasswordField.stringValue = password;
}


- (void)setPasswordWrongLabelHidden:(BOOL)hidden {
    passwordWrongLabel.hidden = hidden;
}

@end
