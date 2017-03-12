//
//  SEBLockedViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 07/03/17.
//  Copyright (c) 2010-2017 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <Foundation/Foundation.h>
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "SEBKeychainManager.h"
#include <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

#import "SEBViewController.h"


@class SEBViewController;


/**
 * @protocol    SEBInitAssistantViewControllerDelegate
 *
 * @brief       All SEBInitAssistant view controllers must conform to
 *              the SEBInitAssistantViewControllerDelegate protocol.
 */
@protocol SEBInitAssistantViewControllerDelegate <NSObject>
/**
 * @name		Item Attributes
 */
@required
/**
 * @brief       Hide or show the label indicating that the URL entered was wrong.
 * @details
 */
- (void) setConfigURLWrongLabelHidden:(BOOL)hidden;

@optional

/**
 * @brief       Indicates if the exam is running.
 * @details
 */
@property(readwrite) BOOL examRunning;

/**
 * @brief       Indicates if the exam is running.
 * @details
 */
@property(readwrite) BOOL sebLocked;

/**
 * @brief       Indicates that the correct quit/restart password was entered and
 *              lockdown windows can be closed now.
 * @details
 */
@property(readwrite) BOOL unlockPasswordEntered;

/**
 * @brief       Hide or show label indicating wrong password was entered.
 * @details
 */
- (void) openInfoHUD:(NSString *)lockedTimeInfo;

/**
 * @brief       Open lockdown windows to block access to the exam.
 .
 * @details
 */
//- (void) openLockdownWindows;

/**
 * @brief       Close lockdown windows and allow to access the exam again.
 * @details
 */
- (void) closeLockdownWindows;

@end


@interface SEBInitAssistantViewController : NSObject

@property (nonatomic, strong) id< SEBInitAssistantViewControllerDelegate > controllerDelegate;
@property (strong, nonatomic) SEBViewController *sebViewController;


- (void) evaluateEnteredURLString:(NSString *)URLString;

@end
