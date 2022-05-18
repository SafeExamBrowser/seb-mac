//
//  SEBiOSInitAssistantViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07/03/17.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel, 
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
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBiOSInitAssistantViewController.h"


@implementation SEBiOSInitAssistantViewController


#pragma mark - UIViewController Overrides

- (void) didMoveToParentViewController:(UIViewController *)parent
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


- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _assistantController = [[SEBInitAssistantViewController alloc] init];
    _assistantController.controllerDelegate = self;
    
    initAssistantTitle.text = [NSString stringWithFormat:NSLocalizedString(@"Options to start an exam or configure %@ for your institution", nil), SEBFullAppName];
    if (@available(iOS 10.0, *)) {
        initAssistantTitleView.backgroundColor = [UIColor colorWithDisplayP3Red:SEBTintColorRedValue
                                                                          green:SEBTintColorGreenValue
                                                                           blue:SEBTintColorBlueValue
                                                                          alpha:1.0];
    }
    openSEBLinkText.text = [NSString stringWithFormat:NSLocalizedString(@"Open %@ %@ exam or configuration link from Safari, Mail or a messenger app.", nil), SEBExtraShortAppNameAArticle, SEBExtraShortAppName];
    automaticClientConfigText.text =[NSString stringWithFormat:NSLocalizedString(@"Enter the URL of an institution which supports %@", nil), SEBExtraShortAppName];
    scanQRConfigText.text = [NSString stringWithFormat:NSLocalizedString(@"Scan %@ configuration QR code", nil), SEBExtraShortAppName];
    noConfigQRCodeFoundLabel.text = [NSString stringWithFormat:NSLocalizedString(@"No %@ configuration found!", nil), SEBExtraShortAppName];

    [configURLField addTarget:configURLField
                  action:@selector(resignFirstResponder)
        forControlEvents:UIControlEventEditingDidEndOnExit];
    
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    };
}


- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_assistantController cancelDownloadingClientConfig];
}


- (BOOL) prefersStatusBarHidden
{
    return true;
}


#pragma mark - IB Action Handler

- (IBAction)aboutSEBIcon:(id)sender
{
    [_sebViewController showAboutSEB];
}


- (IBAction) urlEntered:(id)sender
{
    [_assistantController cancelDownloadingClientConfig];

    NSString *enteredConfigURLString = configURLField.text;
    // Hide the other "config not found" label
    noConfigQRCodeFoundLabel.hidden = true;
    // Keep a reference for the URL textfield "config not found" label
    noConfigFoundLabel = noConfigURLFoundLabel;
    [self evaluateEnteredURLString:enteredConfigURLString];
    [configURLField resignFirstResponder];
}


- (IBAction) typingURL:(id)sender
{
    [_assistantController cancelDownloadingClientConfig];
    
    [self setConfigURLWrongLabelHidden:true
                                 error:nil
                    forClientConfigURL:false];
}


- (IBAction) scanQRCode
{
    [_assistantController cancelDownloadingClientConfig];

    configURLField.text = @"";
    // Hide the other "config not found" label
    noConfigURLFoundLabel.hidden = true;
    // Keep a reference for the scan QR code "config not found" label
    noConfigFoundLabel = noConfigQRCodeFoundLabel;
    
    // Define the ConfigURLManager delegate for evaluating the scanned URL
    _sebViewController.configURLManagerDelegate = self;
    
    [_sebViewController scanQRCode];
}


- (IBAction) searchNetwork:(id)sender
{
    [_assistantController cancelDownloadingClientConfig];
    configURLField.text = @"";
    // Hide the other "config not found" label
    noConfigURLFoundLabel.hidden = true;
    // Keep a reference for the scan QR code "config not found" label
    noConfigFoundLabel = noConfigURLFoundLabel;

    NSString *hostName = [_assistantController domainForCurrentNetwork];
    if ([hostName hasSuffix:@"ethz.ch"]) {
        hostName = @"let.ethz.ch";
    }
    [self setConfigURLString:hostName];
    [self urlEntered:self];
}


- (IBAction) more:(id)sender
{
    [_assistantController cancelDownloadingClientConfig];

    if (_sebViewController.alertController) {
        [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _sebViewController.alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please Select Your Role", nil)
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"%@ needs to be used differently depending on your role.", nil), SEBShortAppName]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Administrator", nil)
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction *action) {
                                                                             // First time show Alert with more information for administrators
                                                                             
                                                                             // Show Alert with more information for students
                                                                             self->_sebViewController.alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Instructions for Administrators", nil)
                                                                                                                                                      message:[NSString stringWithFormat:NSLocalizedString(@"Ask the vendor of your assessment solution about how to use it with %@.\nGeneral instructions on how to configure %@ can be found on %@.", nil), SEBShortAppName, SEBShortAppName, SEBWebsiteShort]
                                                                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                                             
                                                                             [self->_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                                                                                                    style:UIAlertActionStyleCancel
                                                                                                                                                  handler:^(UIAlertAction *action) {
                                                                                                                                                      
                                                                                                                                                      self->_sebViewController.alertController = nil;
                                                                                                                                                  }]];
                                                                             
                                                                             [self->_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Edit Settings", nil)
                                                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                                                  handler:^(UIAlertAction *action) {
                                                                                                                                                      
                                                                                                                                                      self->_sebViewController.alertController = nil;
                                                                                                                                                      // This flag needs to be set to NO to load
                                                                                                                                                      // the Inital Assistant again if editing settings is canceled
                                                                                                                                                      self->_sebViewController.finishedStartingUp = NO;
                                                                                                                                                      [self->_sebViewController conditionallyShowSettingsModal];
                                                                                                                                                  }]];
                                                                             
                                                                             [self->_sebViewController.topMostController presentViewController:self->_sebViewController.alertController animated:NO completion:nil];
                                                                         }]];
    
    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Student", nil)
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction *action) {
                                                                             
                                                                             // Show Alert with more information for students
                                                                             self->_sebViewController.alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Instructions for Students", nil)
                                                                                                                                                      message:[NSString stringWithFormat:NSLocalizedString(@"Follow your educator's instructions about how to start an exam in %@.\nTrying to edit %@ settings yourself may block access to exams.", nil), SEBShortAppName, SEBShortAppName]
                                                                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                                             [self->_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                                                  handler:^(UIAlertAction *action) {
                                                                                                                                                      
                                                                                                                                                      self->_sebViewController.alertController = nil;
                                                                                                                                                  }]];
                                                                             [self->_sebViewController.topMostController presentViewController:self->_sebViewController.alertController animated:NO completion:nil];
                                                                         }]];
    
    [_sebViewController.topMostController presentViewController:_sebViewController.alertController animated:NO completion:nil];
    
}


#pragma mark - Helper Methods

- (void) enableQRScanButton:(BOOL)enabled
{
    QRCodeScanButton.enabled = enabled;
}


- (void) evaluateEnteredURLString:(NSString *)inputURLString
{
    [_assistantController evaluateEnteredURLString:inputURLString];
}


#pragma mark - SEBInitAssistantDelegate Delegate Methods

- (NSString *) configURLString {
    return configURLField.text;
}


- (void) setConfigURLString:(NSString *)URLString {
    configURLField.text = [NSString stringWithFormat:@"%@", URLString];
}


- (void) activityIndicatorAnimate:(BOOL)animate
{
    if (animate) {
        loadingConfig.hidden = NO;
        [loadingConfig startAnimating];
    } else {
        [loadingConfig stopAnimating];
        loadingConfig.hidden = YES;
    }
}


- (void) setConfigURLWrongLabelHidden:(BOOL)hidden
                               error:(NSError *)error
                  forClientConfigURL:(BOOL)isClientConfigURL
{
    noConfigFoundLabel.hidden = hidden;

    // The first time a wrong SEB client config URL is entered, we display a warning
    // that not all institutions support Automatic SEB Client Configuration
    if (error.code == SEBErrorASCCNoWiFi) {
        noConfigFoundLabel.hidden = YES;
        [_sebViewController showConfigURLWarning:error];
    } else if (error.code == SEBErrorASCCNoConfigFound) {
        if (isClientConfigURL && !configURLWarningDisplayed) {
            configURLWarningDisplayed = YES;
            [_sebViewController showConfigURLWarning:error];
        }
    } else if (error) {
        noConfigFoundLabel.hidden = YES;
//        [_sebViewController showConfigURLWarning:error];
    }
}


// Store downloaded SEB client settings and inform callback if successful.
- (void) storeSEBClientSettings:(NSData *)sebData
                      callback:(id)callback
                      selector:(SEL)selector
{
    [_sebViewController.configFileController storeNewSEBSettings:sebData forEditing:false callback:callback selector:selector];
}


- (void) closeAssistantRestartSEB
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self setConfigURLString:@""];
        self->_sebViewController.initAssistantOpen = false;
        [self->_sebViewController storeNewSEBSettingsSuccessful:nil];
    }];
}


@end
