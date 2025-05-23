//
//  SEBBrowserController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 22/01/16.
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
//  Contributor(s): dmcd, Copyright (c) 2015-2016 Janison
//

#import "SEBURLFilter.h"
#import "NSURL+SEBURL.h"
#import <Foundation/Foundation.h>
#import "SEBAbstractWebView.h"

NS_ASSUME_NONNULL_BEGIN

@class SEBURLFilter;
@class AdditionalApplicationsController;

/**
 * @protocol    SEBBrowserControllerDelegate
 *
 * @brief       SEB browser controllers confirming to the SEBBrowserControllerDelegate
 *              protocol are providing the platform specific browser controller
 *              functions.
 */
@protocol SEBBrowserControllerDelegate <NSObject>
/**
 * @name        Item Attributes
 */
@required
/**
 * @brief       Delegate method to display an enter password dialog with the
 *              passed message text asynchronously, calling the callback
 *              method with the entered password when one was entered
 */
- (void) showEnterUsernamePasswordDialog:(NSString *)text
                                   title:(NSString *)title
                                username:(NSString *)username
                           modalDelegate:(id)modalDelegate
                          didEndSelector:(SEL)didEndSelector;

/**
 * @brief       Delegate method to hide the previously displayed enter password dialog
 */
- (void) hideEnterUsernamePasswordDialog;

/**
 * @brief       Delegate method which returns if the main web view (browser window or tab)
 *              is the currently active (selected, displayed) one
 */

- (BOOL) isMainBrowserWebViewActive;

/**
 * @brief       Open a new, temporary webView for downloading the linked config file
 *              This allows the user to authenticate if the link target is stored on a secured server
 */
- (SEBAbstractWebView *) openTempWebViewForDownloadingConfigFromURL:(NSURL *)url originalURL:(NSURL *)originalURL;
- (void) closeWebView:(SEBAbstractWebView *) webViewToClose;
- (void) downloadingSEBConfigFailed:(NSError *)error;
- (void) openDownloadedSEBConfigData:(NSData *)sebFileData fromURL:(NSURL *)url originalURL:(NSURL *)originalURL;

- (void) openingConfigURLRoleBack;


/**
 * @brief       Delegate method which should display a dialog when a config file
 *              is being downloaded, providing a cancel button. When tapped, then
 *              the callback method should be invoked (with no parameter).
 */
- (void) showOpeningConfigFileDialog:(NSString *)text
                               title:(NSString *)title
                      cancelCallback:(id)callback
                            selector:(SEL)selector;

/**
 * @brief       Delegate method to close the dialog displayed while a config file
 *              is being downloaded,
 */
- (void) closeOpeningConfigFileDialog;

/**
 * @brief       Delegate method called when settings data was downloaded.
 *              The method should attempt to decrypt, parse and store
 *              the config data and invoke the callback method passing
 *              an NSError object indicating if it was successful.
 */
-(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
      showReconfiguredAlert:(BOOL)showReconfiguredAlert
                   callback:(id)callback
                   selector:(SEL)selector;

/**
 * @brief       Delegate method called to report the success of storing
 *              new SEB settings. If settings were stored successfully,
 *              error is nil, otherwise it contains an NSError object
 *              with the failure reason
 */
- (void) storeNewSEBSettingsSuccessfulProceed:(NSError *)error;

/**
 * @brief       Delegate method called when a regular HTTP request or a XMLHttpRequest (XHR)
 *              successfully completed loading. The delegate can use this callback
 *              for example to scan the newly received HTML data is being downloaded.
 */
- (void) sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task;

- (void) presentAlertWithTitle:(NSString *)title
                       message:(NSString *)message;
- (void) presentDownloadError:(NSError *)error;

@property (readwrite) BOOL startingUp;
@property (readonly) NSURL *startURL;
@property (readonly) NSArray* openWebpagesTitles;

@optional
- (void) openDownloadedFile:(NSURL *)fileURL;
- (void) openDownloadedFile:(NSURL *)fileURL withAppBundleId:(NSString *)bundleId;
- (NSURL *) getTempDownUploadDirectory;
- (BOOL) removeTempDownUploadDirectory;

@end


@interface SEBBrowserController : NSObject <NSURLSessionTaskDelegate> {
    
    @private
    
    BOOL examSessionCookiesAlreadyCleared;
    NSURL *downloadDirectoryURL;
    NSURL *downloadedSEBConfigDataURL;
    NSString *cachedConfigFileName;
    NSURL *cachedDownloadURL;
    NSURL *cachedHostURL;
    NSURL *cachedUniversalLink;
    NSString *startURLQueryParameter;
    BOOL sendHashKeys;
    BOOL usingEmbeddedCertificates;
    BOOL pinEmbeddedCertificates;
    BOOL webPageShowURLAlways;
    BOOL newWebPageShowURLAlways;
}

- (NSURL *)downloadDirectoryURL;

- (void) resetBEKCK;
- (void) quitSession;
- (void) resetBrowser;
+ (void) createSEBUserAgentFromDefaultAgent:(NSString *)defaultUserAgent;

@property (weak) id<SEBBrowserControllerDelegate, SEBAbstractWebViewNavigationDelegate> delegate;

- (BOOL) isNavigationAllowedMainWebView:(BOOL)mainWebView;
- (BOOL) isReloadAllowedMainWebView:(BOOL)mainWebView;
- (BOOL) showReloadWarningMainWebView:(BOOL)mainWebView;

@property (readwrite) BOOL finishedInitializing;
@property (readwrite) BOOL directConfigDownloadAttempted;
@property (readwrite) BOOL downloadingInTemporaryWebView;
@property (strong, nonatomic) NSURL *_Nullable openConfigSEBURL;
@property (strong, nonatomic) NSURL *originalURL;

@property (readwrite) BOOL usingCustomURLProtocol;

@property (strong, nonatomic) NSString *currentMainHost;
@property (readonly) NSString* openWebpagesTitlesString;

- (NSString *) windowTitleByRemovingSEBVersionString:(NSString *)browserWindowTitle;

@property (strong) NSURLAuthenticationChallenge *pendingChallenge;

@property (strong) NSURLCredential *enteredCredential;
@property (strong) NSURLSession *URLSession;
@property (strong) void (^pendingChallengeCompletionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *_Nullable credential);
@property (strong) NSURLSessionDataTask *downloadTask;

@property (strong) SEBURLFilter *urlFilter;
@property (strong, nonatomic) NSString *javaScriptFunctions;

@property (strong, nonatomic) NSData *_Nullable browserExamKey;
@property (strong, nonatomic) NSData *_Nullable browserExamKeySalt;
@property (strong, nonatomic) NSData *_Nullable serverBrowserExamKey;
@property (strong, nonatomic) NSData *_Nullable configKey;
@property (strong, nonatomic) NSData *_Nullable examSalt;
@property (strong, nonatomic) NSString *_Nullable connectionToken;
@property (strong, nonatomic) NSData *_Nullable appSignatureKey;

@property (readwrite) BOOL isShowingOpeningConfigFileDialog;

@property (readwrite) BOOL didReconfigureWithUniversalLink;
@property (readwrite) BOOL cancelReconfigureWithUniversalLink;

- (void) resetAllCookiesWithCompletionHandler:(void (^)(void))completionHandler;
- (void) transferCookiesToWKWebViewWithCompletionHandler:(void (^)(void))completionHandler;

@property (strong, nonatomic) NSString*_Nullable customSEBUserAgent;
@property (strong, nonatomic) NSString* quitURL;
@property (readonly) BOOL allowDownloads;
@property (readonly) BOOL allowUploads;

@property (strong, nonatomic) NSArray<NSData *> *privatePasteboardItems;

@property (strong, nonatomic) WKWebViewConfiguration *wkWebViewConfiguration;
- (NSString *) webPageTitle:(NSString *)title orURL:(NSURL *)url mainWebView:(BOOL)mainWebView;
- (NSString *) urlOrPlaceholderForURL:(NSString *)url;
- (NSString *) startURLQueryParameter:(NSURL*_Nonnull*_Nonnull)url;
- (NSString *) backToStartURLString;

- (NSURLRequest *)modifyRequest:(NSURLRequest *)request;
- (NSString *) browserExamKeyForURL:(NSURL *)url;
- (NSString *) configKeyForURL:(NSURL *)url;

- (void) conditionallyInitCustomHTTPProtocol;

- (BOOL) isReconfiguringAllowedFromURL:(NSURL *)url;

- (void)webView:(WKWebView *)webView
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler;

- (BOOL) downloadingInTemporaryWebView;
- (void) openConfigFromSEBURL:(NSURL *)url;
- (void) downloadSEBConfigFileFromURL:(NSURL *)url originalURL:(NSURL *)originalURL cookies:(NSArray <NSHTTPCookie *>*)cookies sender:(nullable id <SEBAbstractBrowserControllerDelegate>)sender;
- (void) openingConfigURLFailed;

@property (weak) SEBAbstractWebView *temporaryWebView;

/**
 * @brief       Checks if a URL is in an associated domain and therefore might have
 *              been invoked with a Universal Link
 */
- (BOOL) isAssociatedDomain:(NSURL *)url;

- (void) handleUniversalLink:(NSURL *)universalLink;
- (void) storeNewSEBSettingsSuccessful:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
