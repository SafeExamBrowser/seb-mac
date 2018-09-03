//
//  SEBiOSInitAssistantViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07/03/17.
//  Copyright (c) 2010-2018 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, 
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre, 
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2018 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBiOSInitAssistantViewController.h"


@implementation SEBiOSInitAssistantViewController


- (void)didMoveToParentViewController:(UIViewController *)parent
{
    if (parent) {
        // Add the view to the parent view and position it if you want
        [[parent view] addSubview:self.view];
        CGRect viewFrame = parent.view.bounds;
        //viewFrame.origin.y += kNavbarHeight;
        //viewFrame.size.height -= kNavbarHeight;
        [self.view setFrame:viewFrame];
    } else {
        [self.view removeFromSuperview];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _assistantController = [[SEBInitAssistantViewController alloc] init];
    _assistantController.controllerDelegate = self;
    
    [configURLField addTarget:configURLField
                  action:@selector(resignFirstResponder)
        forControlEvents:UIControlEventEditingDidEndOnExit];
    
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    };
}


- (BOOL) prefersStatusBarHidden
{
    return true;
}


- (IBAction)urlEntered:(id)sender {
    if (![enteredConfigURLString isEqualToString:configURLField.text]) {
        enteredConfigURLString = configURLField.text;
        noConfigQRCodeFoundLabel.hidden = true;
        noConfigFoundLabel = noConfigURLFoundLabel;
        [_assistantController evaluateEnteredURLString:enteredConfigURLString];
    } else {
        enteredConfigURLString = nil;
    }
    [configURLField resignFirstResponder];
}


- (IBAction)typingURL:(id)sender {
    [self setConfigURLWrongLabelHidden:true forClientConfigURL:false];
}


#pragma mark Delegates

- (NSString *)configURLString {
    return configURLField.text;
}


- (void)setConfigURLString:(NSString *)URLString {
    configURLField.text = URLString;
}


- (void)setConfigURLWrongLabelHidden:(BOOL)hidden forClientConfigURL:(BOOL)clientConfigURL {
    noConfigFoundLabel.hidden = hidden;

    // The first time a wrong SEB client config URL is entered, we display a warning
    // that not all institutions support Automatic SEB Client Configuration
    if (!hidden && clientConfigURL && ![[NSUserDefaults standardUserDefaults] boolForKey:@"configURLWarningDisplayed"]) {
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"configURLWarningDisplayed"];
        [_sebViewController showConfigURLWarning];
    }
}


- (void)activityIndicatorAnimate:(BOOL)animate
{
    if (animate) {
        loadingConfig.hidden = false;
        [loadingConfig startAnimating];
    } else {
        [loadingConfig stopAnimating];
        loadingConfig.hidden = true;
    }
}

// Store downloaded SEB client settings and inform callback if successful.
-(void) storeSEBClientSettings:(NSData *)sebData
                      callback:(id)callback
                      selector:(SEL)selector
{
    [_sebViewController.configFileController storeNewSEBSettings:sebData forEditing:false callback:callback selector:selector];
}


-(void)closeAssistantRestartSEB
{
    [self dismissViewControllerAnimated:YES completion:^{
        _sebViewController.initAssistantOpen = false;
        [_sebViewController storeNewSEBSettingsSuccessful:nil];
    }];
}


- (IBAction)scanQRCode
{
    configURLField.text = @"";
    noConfigURLFoundLabel.hidden = true;
    noConfigFoundLabel = noConfigQRCodeFoundLabel;
    // Define the ConfigURLManager delegate for evaluating the scanned URL
    _sebViewController.configURLManagerDelegate = self;

    [_sebViewController scanQRCode];
}


- (void)enableQRScanButton:(BOOL)enabled
{
    QRCodeScanButton.enabled = enabled;
}


- (void)evaluateEnteredURLString:(NSString *)inputURLString
{
    [_assistantController evaluateEnteredURLString:inputURLString];
}


- (IBAction)searchNetwork:(id)sender {
    NSString *hostName = [_assistantController domainForCurrentNetwork];
    [self setConfigURLString:hostName];
    [self urlEntered:self];
}


- (IBAction)editSettings:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        _sebViewController.initAssistantOpen = false;
        [_sebViewController conditionallyShowSettingsModal];
    }];
}


@end
