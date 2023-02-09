//
//  SEBiOSBrowserController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 27.04.21.
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

#import "SEBiOSBrowserController.h"

@implementation SEBiOSBrowserController

@synthesize startingUp;


- (instancetype)init
{
    self = [super init];
    if (self) {
        self.delegate = self;
    }
    return self;
}


- (NSString *)currentMainHost
{
    return _sebViewController.browserTabViewController.currentMainHost;
}

- (void)setCurrentMainHost:(NSString *)currentMainHost
{
    _sebViewController.browserTabViewController.currentMainHost = currentMainHost;
}


- (void)closeWebView:(SEBAbstractWebView *)webViewToClose
{
    [self.sebViewController.browserTabViewController closeWebView:webViewToClose];
}


#pragma mark Downloading SEB Config Files

// Check if reconfiguring from exam or secure mode is allowed
- (BOOL) isReconfiguringAllowedFromURL:(NSURL *)url
{
    if (![super isReconfiguringAllowedFromURL:url]) {
        [_sebViewController showAlertWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Loading New %@ Settings Not Allowed!", nil), SEBExtraShortAppName]
                         andText:[NSString stringWithFormat:NSLocalizedString(@"%@ is already running in exam mode and it is not allowed to interupt this by starting another exam. Finish the exam session or use the %@ quit button before starting another exam.", nil), SEBShortAppName, SEBShortAppName]];
        return NO;
    } else {
        return YES;
    }
}


- (SEBAbstractWebView *)openTempWebViewForDownloadingConfigFromURL:(NSURL *)url originalURL:originalURL
{
    SEBAbstractWebView *tempWebView = [_sebViewController openTempWebViewForDownloadingConfigFromURL:url originalURL:originalURL];
    
    return tempWebView;
}


- (void) showAlertNotAllowedDownUploading:(BOOL)uploading
{
    NSString *downUploadingString;
    if (uploading) {
        downUploadingString = NSLocalizedString(@"Uploading", nil);
    } else {
        downUploadingString = NSLocalizedString(@"Downloading", nil);
    }
    DDLogWarn(@"Attempted %@ of files is not allowed in current %@ settings", downUploadingString, SEBShortAppName);
    [_sebViewController showAlertWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ Not Allowed!", nil), downUploadingString, nil]
                     andText:[NSString stringWithFormat:NSLocalizedString(@"%@ files is not allowed in current %@ settings. Report this to your exam provider.", nil), downUploadingString, SEBShortAppName]];
}


- (void)openDownloadedSEBConfigData:(NSData *)sebFileData fromURL:(NSURL *)url originalURL:(NSURL *)originalURL
{
    DDLogDebug(@"%s URL: %@", __FUNCTION__, url);
    
    _sebViewController.openingSettings = YES;
    [_sebViewController.configFileController storeNewSEBSettings:sebFileData
                                forEditing:NO
                                  callback:self
                                  selector:@selector(storeNewSEBSettingsSuccessful:)];
}


// Called when downloading the config file failed
- (void) downloadingSEBConfigFailed:(NSError *)error
{
    DDLogError(@"%s error: %@", __FUNCTION__, error);
    _sebViewController.openingSettings = NO;
    
    // Only show the download error and close temp browser window if this wasn't a direct download attempt
    if (!self.directConfigDownloadAttempted) {
        
        // Close the temporary browser window
        [self closeWebView:self.temporaryWebView];
        // Show the load error
        [_sebViewController showAlertWithError:error];
        [self openingConfigURLRoleBack];
    }
}


- (void)openingConfigURLRoleBack {
    if (self.startingUp) {
        // We continue startup with client settings, as decrypting the config
        // which opened SEB wasn't successful
        DDLogError(@"%s: SEB is starting up and opening a config link wasn't successfull, SEB will use client setting", __FUNCTION__);
    }
    // Reset the opening settings flag which prevents opening URLs concurrently
    _sebViewController.openingSettings = NO;
    _sebViewController.scannedQRCode = NO;
}

- (void)closeOpeningConfigFileDialog {
    
}


- (void)sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task {
    [_sebViewController sessionTaskDidCompleteSuccessfully:task];
}


- (BOOL)isStartingUp {
    return _sebViewController.startingUp;
}

- (void)setStartingUp:(BOOL)startingUp {
    _sebViewController.startingUp = startingUp;
}


#pragma mark SEBBrowserControllerDelegate Methods

- (void)showEnterUsernamePasswordDialog:(NSString *)text
                                  title:(NSString *)title
                               username:(NSString *)username
                          modalDelegate:(id)modalDelegate
                         didEndSelector:(SEL)didEndSelector {
    [_sebViewController showEnterUsernamePasswordDialog:text title:title username:username modalDelegate:modalDelegate didEndSelector:didEndSelector];
}


- (void)hideEnterUsernamePasswordDialog {
    
}


- (void)showOpeningConfigFileDialog:(NSString *)text title:(NSString *)title cancelCallback:(id)callback selector:(SEL)selector {
    [_sebViewController showOpeningConfigFileDialog:text title:title cancelCallback:callback selector:selector];
}


- (BOOL) isMainBrowserWebViewActive
{
    return [MyGlobals sharedMyGlobals].currentWebpageIndexPathRow == 0;
}


- (void)storeNewSEBSettings:(NSData *)sebData forEditing:(BOOL)forEditing forceConfiguringClient:(BOOL)forceConfiguringClient showReconfiguredAlert:(BOOL)showReconfiguredAlert callback:(id)callback selector:(SEL)selector
{
    DDLogDebug(@"%s", __FUNCTION__);
    [_sebViewController storeNewSEBSettings:sebData forEditing:forEditing forceConfiguringClient:forceConfiguringClient showReconfiguredAlert:showReconfiguredAlert callback:callback selector:selector];
}


- (void) storeNewSEBSettingsSuccessfulProceed:(NSError *)error
{
    _sebViewController.openingSettings = NO;
    [_sebViewController storeNewSEBSettingsSuccessful:error];
}

- (void)presentAlertWithTitle:(nonnull NSString *)title message:(nonnull NSString *)message {
    [_sebViewController alertWithTitle:title message:message action1Title:NSLocalizedString(@"OK", nil) action1Handler:^{
        self.sebViewController.alertController = nil;
    } action2Title:nil action2Handler:nil];
}


- (void)presentDownloadError:(nonnull NSError *)error {
    [_sebViewController showAlertWithError:error];
}


@end
