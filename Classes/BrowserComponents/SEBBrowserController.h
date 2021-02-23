//
//  SEBBrowserController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 22/01/16.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): dmcd, Copyright (c) 2015-2016 Janison
//

#import "SEBURLFilter.h"

@class SEBURLFilter;

/**
 * @protocol    SEBBrowserControllerDelegate
 *
 * @brief       SEB browser controllers confirming to the SEBBrowserControllerDelegate
 *              protocol are providing the platform specific browser controller
 *              functions.
 */
@protocol SEBBrowserControllerDelegate <NSObject>
/**
 * @name		Item Attributes
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
 * @brief       Delegate method which returns a placeholder text in case settings
 *              don't allow to display its URL
 */
- (NSString *) showURLplaceholderTitleForWebpage;

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
- (void) storeNewSEBSettingsSuccessful:(NSError *)error;

/**
 * @brief       Delegate method called when a regular HTTP request or a XMLHttpRequest (XHR)
 *              successfully completed loading. The delegate can use this callback
 *              for example to scan the newly received HTML data is being downloaded.
 */
- (void) sessionTaskDidCompleteSuccessfully:(NSURLSessionTask *)task;

@end


#import <Foundation/Foundation.h>

@interface SEBBrowserController : NSObject <NSURLSessionTaskDelegate> {
    
    @private
    
    NSString *cachedConfigFileName;
    NSURL *cachedDownloadURL;
    NSURL *cachedHostURL;
    NSURL *cachedUniversalLink;
    NSString *quitURLTrimmed;
    BOOL sendHashKeys;
}

@property (weak) id delegate;

@property (readwrite) BOOL usingCustomURLProtocol;

@property (strong) NSURLAuthenticationChallenge *pendingChallenge;

@property (strong) id URLSession;
@property (strong) NSURLSessionDataTask *downloadTask;

@property (strong) SEBURLFilter *urlFilter;

@property (strong, nonatomic) NSData *browserExamKey;
@property (strong, nonatomic) NSData *browserExamKeySalt;
@property (strong, nonatomic) NSData *configKey;

@property (readwrite) BOOL isShowingOpeningConfigFileDialog;

@property (readwrite) BOOL didReconfigureWithUniversalLink;
@property (readwrite) BOOL cancelReconfigureWithUniversalLink;

- (void) createSEBUserAgentFromDefaultAgent:(NSString *)defaultUserAgent;
- (NSString *) startURLQueryParameter:(NSURL**)url;
- (NSString *) backToStartURLString;

- (void) conditionallyInitCustomHTTPProtocol;

- (BOOL) isReconfiguringAllowedFromURL:(NSURL *)url;

/**
 * @brief       Checks if a URL is in an associated domain and therefore might have
 *              been invoked with a Universal Link
 */
- (BOOL) isAssociatedDomain:(NSURL *)url;

- (void) handleUniversalLink:(NSURL *)universalLink;
- (void) storeNewSEBSettingsSuccessful:(NSError *)error;

@end
