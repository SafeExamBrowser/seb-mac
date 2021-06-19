//
//  PreferencesViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 05.09.20.
//

#import "PreferencesViewController.h"

@interface PreferencesViewController ()

@end

@implementation PreferencesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)scrollToTop:(NSScrollView *)scrollView;
{
    NSPoint newScrollOrigin;
 
    if ([[scrollView documentView] isFlipped]) {
        newScrollOrigin=NSMakePoint(0.0, 0.0);
    } else {
        newScrollOrigin=NSMakePoint(0.0, NSMaxY([[scrollView documentView] frame])
                                        -NSHeight([[scrollView contentView] bounds]));
    }
    [[scrollView documentView] scrollPoint:newScrollOrigin];
}

@end
