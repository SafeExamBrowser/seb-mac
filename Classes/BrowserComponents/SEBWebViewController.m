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

- (void)viewWillAppear {
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
    NSPressureConfiguration *oldPressureConfiguration = self.view.pressureConfiguration;
    NSPressureBehavior oldPressureBehavior = oldPressureConfiguration.pressureBehavior;
    DDLogDebug(@"Subview %@ had pressureConfiguration %@ and pressureBehavior %ld", self.view, oldPressureConfiguration, (long)oldPressureBehavior);
    [self.view setPressureConfiguration:pressureConfiguration];
    NSPressureConfiguration *newPressureConfiguration = self.view.pressureConfiguration;
    NSPressureBehavior newPressureBehavior = newPressureConfiguration.pressureBehavior;
    DDLogDebug(@"Now subview %@ has new pressureConfiguration %@ and pressureBehavior %ld", self.view, newPressureConfiguration, (long)newPressureBehavior);

    [super viewWillAppear];
}


@end
