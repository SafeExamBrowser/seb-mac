//
//  SEBBrowserController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 22/01/16.
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
//  Contributor(s): dmcd, Copyright (c) 2015-2016 Janison
//


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
 * @brief       Delegate method which returns a placeholder text in case settings
 *              don't allow to display its URL
 */
- (NSString *) showURLplaceholderTitleForWebpage;

-(void) storeNewSEBSettings:(NSData *)sebData
                 forEditing:(BOOL)forEditing
     forceConfiguringClient:(BOOL)forceConfiguringClient
      showReconfiguredAlert:(BOOL)showReconfiguredAlert
                   callback:(id)callback
                   selector:(SEL)selector;

- (void) storeNewSEBSettingsSuccessful:(NSError *)error;

@end


#import <Foundation/Foundation.h>

@interface SEBBrowserController : NSObject <NSURLSessionTaskDelegate> {
    NSString *cachedConfigFileName;
    NSURL *cachedDownloadURL;
    NSURL *cachedHostURL;
}

@property (weak) id delegate;

@property (readwrite) BOOL usingCustomURLProtocol;

@property (strong) NSURLAuthenticationChallenge *pendingChallenge;

@property (strong) id URLSession;
@property (strong) NSURLSessionDataTask *downloadTask;

@property (readwrite) BOOL didReconfigureWithUniversalLink;

- (void) createSEBUserAgentFromDefaultAgent:(NSString *)defaultUserAgent;
- (NSString *) backToStartURLString;

- (void) conditionallyInitCustomHTTPProtocol;

- (void) handleUniversalLink:(NSURL *)universalLink;
- (void) storeNewSEBSettingsSuccessful:(NSError *)error;

@end
