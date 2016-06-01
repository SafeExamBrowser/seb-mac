//
//  SEBWebViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 29/05/16.
//
//

#import "SEBWebViewController.h"

@interface SEBWebViewController ()

@end

@implementation SEBWebViewController

- (void)viewDidAppear {
    [super viewDidAppear];
    // Do view setup here.
   
    NSPressureConfiguration* pressureConfiguration;
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDictionaryLookup"]) {
        pressureConfiguration = [[NSPressureConfiguration alloc]
                                 initWithPressureBehavior:NSPressureBehaviorPrimaryDefault];
    } else {
        pressureConfiguration = [[NSPressureConfiguration alloc]
                                 initWithPressureBehavior:NSPressureBehaviorPrimaryClick];
    }

    for (NSView *subview in [self.view subviews]) {
        if ([subview respondsToSelector:@selector(setPressureConfiguration:)]) {
            subview.pressureConfiguration = pressureConfiguration;
        }
    }
}


@end
