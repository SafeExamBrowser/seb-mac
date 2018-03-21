//
//  SEBOverridableLockedViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 21.03.18.
//

#import "SEBOverridableLockedViewController.h"

@interface SEBOverridableLockedViewController () {
    
    __weak IBOutlet SEBTextField *alertMessage;
    __weak IBOutlet NSSecureTextField *lockedAlertPasswordField;
    __weak IBOutlet NSTextField *passwordWrongLabel;
    __weak IBOutlet NSScrollView *logScrollView;

}

@end


@implementation SEBOverridableLockedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}


- (NSString *)logStringForParameters
{
    if (self.overrideSecurityCheck.state == true) {
        return NSLocalizedString(@"Overriding security check is enabled!", nil);
    } else {
        return @"";
    }
}


@end
