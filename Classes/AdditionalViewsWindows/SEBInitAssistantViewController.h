//
//  SEBInitAssistantViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07/03/17.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <Foundation/Foundation.h>


/**
 * @protocol    SEBInitAssistantViewControllerDelegate
 *
 * @brief       All SEBInitAssistant view controllers must conform to
 *              the SEBInitAssistantViewControllerDelegate protocol.
 */
@protocol SEBInitAssistantDelegate <NSObject>
/**
 * @name		Item Attributes
 */
@required

/**
 * @brief       Entered config URL.
 * @details
 */
@property(readwrite) NSString* configURLString;

/**
 * @brief       Start or stop animating the activity indicator for downloading the config.
 * @details
 */
- (void) activityIndicatorAnimate:(BOOL)animate;

/**
 * @brief       Hide or show the label indicating that the URL entered was wrong
 *              and display the according NSError text
 * @details
 */
- (void) setConfigURLWrongLabelHidden:(BOOL)hidden
                               error:(NSError *)error
                  forClientConfigURL:(BOOL)clientConfigURL;

/**
 * @brief       Store downloaded SEB client settings and inform callback if successful.
 * @details
 */
- (void) storeSEBClientSettings:(NSData *)sebData
                   callback:(id)callback
                   selector:(SEL)selector;

/**
 * @brief       Close Assistant and restart SEB (using new settings).
 * @details
 */
- (void) closeAssistantRestartSEB;

@optional

/**
 * @brief       Indicates if the exam is running.
 * @details
 */
@property(readwrite) BOOL sessionRunning;

@end


@interface SEBInitAssistantViewController : NSObject <NSURLSessionTaskDelegate> {
    BOOL clientConfigURL;

@private
    NSURL *storeClienConfigURL;
    SEBClientConfigURLSchemes storeConfigURLScheme;
}

@property (nonatomic, strong) id< SEBInitAssistantDelegate > controllerDelegate;

@property (strong) id URLSession;
@property (strong) NSURLSessionDataTask *downloadTask;
@property (strong) NSTimer *downloadTimer;
@property (readwrite) BOOL searchingConfigCanceled;


- (void) evaluateEnteredURLString:(NSString *)URLString;
- (void) cancelDownloadingClientConfig;

- (NSString *) domainForCurrentNetwork;

@end
