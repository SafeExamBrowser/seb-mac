//
//  SEBiOSInitAssistantViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07/03/17.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
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
    
    if (!initAssistantTitleFont) {
        initAssistantTitleFont = initAssistantTitle.font.copy;
    }
    initAssistantTitle.text = [NSString stringWithFormat:NSLocalizedString(@"Options to start an exam or configure %@ for your institution", @""), SEBFullAppName];
    initAssistantTitleView.backgroundColor = [UIColor colorWithDisplayP3Red:SEBTintColorRedValue
                                                                      green:SEBTintColorGreenValue
                                                                       blue:SEBTintColorBlueValue
                                                                      alpha:1.0];
    searchNetworkButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    quitSessionButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    moreInformationButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    [self adjustDynamicFontSizes];
    openSEBLinkText.text = [NSString stringWithFormat:NSLocalizedString(@"Open %@ exam or configuration link from Safari, Mail or a messenger app.", @""), SEBExtraShortAppName];
    automaticClientConfigText.text =[NSString stringWithFormat:NSLocalizedString(@"Enter the URL of an institution which supports %@", @""), SEBExtraShortAppName];
    scanQRConfigText.text = [NSString stringWithFormat:NSLocalizedString(@"Scan %@ configuration QR code", @""), SEBExtraShortAppName];
    noConfigQRCodeFoundLabel.text = [NSString stringWithFormat:NSLocalizedString(@"No %@ configuration found!", @""), SEBExtraShortAppName];

    [configURLField addTarget:configURLField
                  action:@selector(resignFirstResponder)
        forControlEvents:UIControlEventEditingDidEndOnExit];
    
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    };
}


- (void) viewWillAppear:(BOOL)animated
{
    quitSessionButton.hidden = !NSUserDefaults.userDefaultsPrivate;
    [super viewWillAppear:animated];
    
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [self adjustDynamicFontSizes];
}


- (void) adjustDynamicFontSizes
{
    initAssistantTitle.font = [[UIFontMetrics defaultMetrics] scaledFontForFont:initAssistantTitleFont];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self setConfigURLString:@""];
    self.sebViewController.initAssistantOpen = NO;
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


- (IBAction) urlEnteredConfirmButton:(id)sender
{
    [configURLField resignFirstResponder];
}


- (IBAction) urlEntered:(id)sender
{
    [_assistantController cancelDownloadingClientConfig];

    NSString *enteredConfigURLString = configURLField.text;
    // Hide the other "config not found" label
    noConfigQRCodeFoundLabel.hidden = YES;
    // Keep a reference for the URL textfield "config not found" label
    noConfigFoundLabel = noConfigURLFoundLabel;
    [self evaluateEnteredURLString:enteredConfigURLString];
}


- (IBAction) typingURL:(id)sender
{
    [_assistantController cancelDownloadingClientConfig];
    
    [self setConfigURLWrongLabelHidden:YES
                                 error:nil
                    forClientConfigURL:NO];
}


- (IBAction) scanQRCode
{
    [_assistantController cancelDownloadingClientConfig];

    configURLField.text = @"";
    // Hide the other "config not found" label
    noConfigURLFoundLabel.hidden = YES;
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
    noConfigURLFoundLabel.hidden = YES;
    // Keep a reference for the scan QR code "config not found" label
    noConfigFoundLabel = noConfigURLFoundLabel;
    
    void (^completionHandler)(BOOL) = ^void(BOOL authorized) {
        if (authorized) {
            NSString *hostName = [self.assistantController domainForCurrentNetwork];
            if ([hostName hasSuffix:@"ethz.ch"]) {
                hostName = @"let.ethz.ch";
            }
            [self setConfigURLString:hostName];
            [self urlEntered:self];
        } else {
            self.sebViewController.alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Local Network Access", @"")
                                                                                         message:[NSString stringWithFormat:NSLocalizedString(@"Local network access is needed when using Automatic Client Configuration to search the local network for a %@ client configuration. You can allow access to the local network for %@ in Settings.", @""), SEBShortAppName, SEBShortAppName]
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
            [self.sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                                                                       style:UIAlertActionStyleDefault
                                                                                     handler:^(UIAlertAction *action) {
                
                self.sebViewController.alertController = nil;
            }]];
            [self.sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", @"")
                                                                                       style:UIAlertActionStyleDefault
                                                                                     handler:^(UIAlertAction *action) {
                self.sebViewController.alertController = nil;
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                
            }]];
            [self.sebViewController.topMostController presentViewController:self.sebViewController.alertController animated:NO completion:nil];
        }
    };
    if (@available(iOS 14.0, *)) {
        if (!_localNetworkAuthorizationManager) {
            _localNetworkAuthorizationManager = [LocalNetworkAuthorizationManager new];
        }
        [_localNetworkAuthorizationManager requestAuthorizationWithCompletion:completionHandler];
    } else {
        completionHandler(YES);
    }
}


- (IBAction) more:(id)sender
{
    [_assistantController cancelDownloadingClientConfig];

    if (_sebViewController.alertController) {
        [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _sebViewController.alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Please Select Your Role", @"")
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"%@ needs to be used differently depending on your role.", @""), SEBShortAppName]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Administrator", @"")
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction *action) {
                                                                             // First time show Alert with more information for administrators
                                                                             
                                                                             // Show Alert with more information for students
                                                                             self.sebViewController.alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Instructions for Administrators", @"")
                                                                                                                                                      message:[NSString stringWithFormat:NSLocalizedString(@"Ask the vendor of your assessment solution about how to use it with %@.%@General instructions on how to configure %@ can be found on %@.", @""), SEBShortAppName, @"\n", SEBShortAppName, SEBWebsiteShort]
                                                                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                                             
                                                                             [self.sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                                                                                                                                    style:UIAlertActionStyleCancel
                                                                                                                                                  handler:^(UIAlertAction *action) {
                                                                                                                                                      
                                                                                                                                                      self.sebViewController.alertController = nil;
                                                                                                                                                  }]];
                                                                             
                                                                             [self.sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Edit Settings", @"")
                                                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                                                  handler:^(UIAlertAction *action) {
                                                                                                                                                      
                                                                                                                                                      self.sebViewController.alertController = nil;
                                                                                                                                                      // This flag needs to be set to NO to load
                                                                                                                                                      // the Inital Assistant again if editing settings is canceled
                                                                                                                                                      self.sebViewController.finishedStartingUp = NO;
                                                                                                                                                      [self.sebViewController conditionallyShowSettingsModal];
                                                                                                                                                  }]];
                                                                             
                                                                             [self.sebViewController.topMostController presentViewController:self.sebViewController.alertController animated:NO completion:nil];
                                                                         }]];
    
    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Student", @"")
                                                                           style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction *action) {
                                                                             
                                                                             // Show Alert with more information for students
                                                                             self.sebViewController.alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Instructions for Students", @"")
                                                                                                                                                      message:[NSString stringWithFormat:NSLocalizedString(@"Follow your educator's instructions about how to start an exam in %@.%@Trying to edit %@ settings yourself may block access to exams.", @""), SEBShortAppName, @"\n", SEBShortAppName]
                                                                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                                                             [self.sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                                                                                                                    style:UIAlertActionStyleDefault
                                                                                                                                                  handler:^(UIAlertAction *action) {
                                                                                                                                                      
                                                                                                                                                      self.sebViewController.alertController = nil;
                                                                                                                                                  }]];
                                                                             [self.sebViewController.topMostController presentViewController:self.sebViewController.alertController animated:NO completion:nil];
                                                                         }]];
    
    [_sebViewController.topMostController presentViewController:_sebViewController.alertController animated:NO completion:nil];
    
}


- (IBAction) quitSession:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestQuit" object:self];
    }];
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
    DDLogDebug(@"%s", __FUNCTION__);
    [_sebViewController.configFileController storeNewSEBSettings:sebData forEditing:false callback:callback selector:selector];
}


- (void) closeAssistantRestartSEB
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self setConfigURLString:@""];
        self.sebViewController.initAssistantOpen = NO;
        [self.sebViewController storeNewSEBSettingsSuccessful:nil];
    }];
}


@end
