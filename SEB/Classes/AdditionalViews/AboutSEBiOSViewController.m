//
//  AboutSEBiOSViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 25/05/17.
//  Copyright (c) 2010-2017 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel, 
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre, 
//  Brigitte Schmucki, Oliver Rahs.
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
//  The Original Code is SafeExamBrowser for iOS.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2017 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "AboutSEBiOSViewController.h"

@implementation AboutSEBiOSViewController


- (void) didMoveToParentViewController:(UIViewController *)parent
{
    if (parent) {
        // Add the view to the parent view and position it if you want
        [[parent view] addSubview:self.view];
        CGRect viewFrame = parent.view.bounds;
        [self.view setFrame:viewFrame];
    } else {
        [self.view removeFromSuperview];
    }
}


- (void) viewDidLoad
{
    [super viewDidLoad];
    
    SEBAboutController *aboutController = [SEBAboutController new];
    appExtraShortName.text = SEBExtraShortAppName;
    if (@available(iOS 10.0, *)) {
        appExtraShortName.textColor = [UIColor colorWithDisplayP3Red:SEBTintColorRedValue
                                                               green:SEBTintColorGreenValue
                                                                blue:SEBTintColorBlueValue
                                                               alpha:1.0];
    }
    appName.text = SEBFullAppName;
    versionLabel.text = [aboutController version];
    copyrightLabel.text = [aboutController copyright];
    NSString *sendLogsButtonTitle = [NSString stringWithFormat:NSLocalizedString(@"Send Logs to %@ Developers", @""), SEBExtraShortAppName];
    [sendLogsButton setTitle:sendLogsButtonTitle forState:UIControlStateNormal];
    [sendLogsButton setTitle:sendLogsButtonTitle forState:UIControlStateHighlighted];

    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    };
}


- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.sebViewController.aboutSEBViewDisplayed = false;
    self.sebViewController.aboutSEBViewController = nil;
}


- (BOOL) prefersStatusBarHidden
{
    return true;
}


-(IBAction) closeAbout
{
    [self dismissViewControllerAnimated:YES completion:^{
        self.sebViewController.aboutSEBViewDisplayed = false;
        self.sebViewController.aboutSEBViewController = nil;
        [self.sebViewController becomeFirstResponder];
    }];
}


- (IBAction)sendLogsByEmail
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    BOOL examSession = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"].length > 0;

    if (examSession) {
        
        if (_sebViewController.alertController) {
            [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
        }
        _sebViewController.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Can't Send Log File", @"")
                                                                                  message:NSLocalizedString(@"You can't send log files while in an exam session. Finish the exam first and try it again.", @"")
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                                               style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                                   self->_sebViewController.alertController = nil;
                                                                               }]];
        
        [_sebViewController.topMostController presentViewController:_sebViewController.alertController animated:NO completion:nil];

    } else if ([MFMailComposeViewController canSendMail]) {
        
        // If there is a hashed admin password the user has to enter it before editing settings
        NSString *hashedAdminPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
        
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_logSendingRequiresAdminPassword"] &&
            hashedAdminPassword.length > 0) {
            // Allow up to 5 attempts for entering password
            attempts = 5;
            NSString *enterPasswordString = [NSString stringWithFormat:NSLocalizedString(@"You can only send log files after entering the %@ administrator password:", @""), SEBShortAppName];
            
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [_sebViewController.configFileController promptPasswordWithMessageText:enterPasswordString
                                                                             title:NSLocalizedString(@"Send Log File",nil)
                                                                          callback:self
                                                                          selector:@selector(enteredAdminPassword:)];
            return;
        } else {
            [self composeEmailWithDebugAttachment];
        }
    } else {
        if (_sebViewController.alertController) {
            [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
        }
        _sebViewController.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"Can't Send Log File", @"")
                                                                                  message:NSLocalizedString(@"This device isn't configured for sending email.", @"")
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                                               style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                                   self->_sebViewController.alertController = nil;
                                                                               }]];
        
        [_sebViewController.topMostController presentViewController:_sebViewController.alertController animated:NO completion:nil];
    }
}


- (void) enteredAdminPassword:(NSString *)password
{
    // Check if the cancel button was pressed
    if (!password) {
        // Abort sending logs
        return;
    }
    
    attempts--;
    
    if (![self correctAdminPassword:password]) {
        // wrong password entered, are there still attempts left?
        if (attempts > 0) {
            // Let the user try it again
            NSString *enterPasswordString = [NSString stringWithFormat:NSLocalizedString(@"Wrong password! Try again to enter the current %@ administrator password:",nil), SEBShortAppName];
            // Ask the user to enter the settings password and proceed to the callback method after this happend
            [_sebViewController.configFileController promptPasswordWithMessageText:enterPasswordString
                                                                             title:[NSString stringWithFormat:NSLocalizedString(@"Send %@ Logfiles",nil), SEBExtraShortAppName]
                                                                          callback:self
                                                                          selector:@selector(enteredAdminPassword:)];
            return;
            
        } else {
            // Wrong password entered in the last allowed attempts: Stop reading .seb file
            DDLogError(@"%s: Cannot Send SEB Logs: User didn't enter the correct SEB administrator password.", __FUNCTION__);
            
            NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Cannot Send %@ Logs", @""), SEBExtraShortAppName];
            NSString *informativeText = [NSString stringWithFormat:NSLocalizedString(@"You didn't enter the correct %@ administrator password.", @""), SEBShortAppName];
            [_sebViewController.configFileController showAlertWithTitle:title andText:informativeText];
            
            // Abort sending logs
            return;
        }
        
    } else {
        // The correct admin password was entered: Send logs by email
        [self composeEmailWithDebugAttachment];
        return;
    }
}


- (BOOL)correctAdminPassword: (NSString *)password {
    // Get admin password hash from current client settings
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *hashedAdminPassword = [preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
    if (!hashedAdminPassword) {
        hashedAdminPassword = @"";
    } else {
        hashedAdminPassword = [hashedAdminPassword uppercaseString];
    }
    
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSString *hashedPassword;
    if (password.length == 0) {
        // An empty password has to be an empty hashed password string
        hashedPassword = @"";
    } else {
        hashedPassword = [keychainManager generateSHAHashString:password];
        hashedPassword = [hashedPassword uppercaseString];
    }
    return [hashedPassword caseInsensitiveCompare:hashedAdminPassword] == NSOrderedSame;
}


- (void)composeEmailWithDebugAttachment
{
    if (_sebViewController.alertController) {
        [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _sebViewController.alertController = [UIAlertController  alertControllerWithTitle:NSLocalizedString(@"GitHub Issue/Discussion Required for Log Submission", @"")
                                                                              message:NSLocalizedString(@"Please create an issue or discussion on our GitHub repository https://github.com/SafeExamBrowser/seb-mac and provide a detailed description of the issue you would like to report there. You can send SEB logs to your own email address and attach these to your GitHub issue/discussion. Direct log submissions without an issue description will be ignored, as most issues cannot be analyzed without additional information.", @"")
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.sebViewController.mailViewController) {
                self.sebViewController.mailViewController = [[MFMailComposeViewController alloc] init];
                self.sebViewController.mailViewController.mailComposeDelegate = self;
                NSMutableData *errorLogData = [NSMutableData data];
                for (NSData *errorLogFileData in [self errorLogData]) {
                    [errorLogData appendData:errorLogFileData];
                }
                [self.sebViewController.mailViewController addAttachmentData:errorLogData mimeType:@"text/plain" fileName:[NSString stringWithFormat:@"%@-iOS-Client.log", SEBExtraShortAppName]];
                [self.sebViewController.mailViewController setSubject:[NSString stringWithFormat:NSLocalizedString(@"Log File %@ iOS", @""), SEBShortAppName]];
                [self.sebViewController.mailViewController setMessageBody:[NSString stringWithFormat:@"%@\n", NSLocalizedString(@"Please add a GitHub Issue/Discussion number/link or describe the issue you observed (what were you doing when the issue happened, what did you expect and what actually happened, step-by-step instructions to reproduce the issue):", @"")] isHTML:NO];
//                [self.sebViewController.mailViewController setToRecipients:[NSArray arrayWithObject:SEBSupportEmail]];
                
                [self.sebViewController.topMostController presentViewController:self.sebViewController.mailViewController animated:YES completion:nil];
            }
        });
    }]];
    
    [_sebViewController.topMostController presentViewController:_sebViewController.alertController animated:NO completion:nil];
}


- (NSMutableArray *)errorLogData
{
    DDFileLogger *ddFileLogger = [DDFileLogger new];
    NSArray <NSString *> *logFilePaths = [ddFileLogger.logFileManager sortedLogFilePaths];
    NSMutableArray <NSData *> *logFileDataArray = [NSMutableArray new];
    for (NSString* logFilePath in logFilePaths) {
        NSURL *fileUrl = [NSURL fileURLWithPath:logFilePath];
        NSData *logFileData = [NSData dataWithContentsOfURL:fileUrl options:NSDataReadingMappedIfSafe error:nil];
        if (logFileData) {
            [logFileDataArray insertObject:logFileData atIndex:0];
        }
    }
    return logFileDataArray;
}


- (void)mailComposeController:(MFMailComposeViewController *)mailer didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self becomeFirstResponder];
    [mailer dismissViewControllerAnimated:YES completion:nil];
    _sebViewController.mailViewController = nil;
}


@end
