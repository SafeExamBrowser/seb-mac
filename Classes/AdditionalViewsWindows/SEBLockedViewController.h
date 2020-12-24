//
//  SEBLockedViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03/12/15.
//  Copyright (c) 2010-2020 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2020 Daniel R. Schneider, ETH Zurich, Educational Development
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


/**
 * @protocol    SEBLockedViewUIDelegate
 *
 * @brief       A SEBLockedViewUIController delegate handles UI actions inside
 *              the lock screen and must conform to the SEBConfigUIDelegate
 *              protocol.
 */
@protocol SEBLockedViewUIDelegate <NSObject>
/**
 * @name		Item Attributes
 */
@required
/**
 * @brief       Scroll to the bottom of the scroll view displaying log messages.
 * @details
 */
- (void) scrollToBottom;

/**
 * @brief       Get password string for unlocking SEB again.
 * @details
 */
- (NSString *) lockedAlertPassword;

/**
 * @brief       Set string in the password field for unlocking SEB again.
 * @details
 */
- (void) setLockedAlertPassword:(NSString *)password;

/**
 * @brief       Hide or show the label indicating a wrong password was entered.
 * @details
 */
- (void) setPasswordWrongLabelHidden:(BOOL)hidden;

/**
 * @brief       Time when exam was resumed.
 * @details
 */
@property (readwrite, copy) NSAttributedString *resignActiveLogString;

@optional

/**
 * @brief       Open lockdown windows to block access to the exam
.
 * @details
 */
//- (void) openLockdownWindows;

/**
 * @brief       Let UI delegate read state of platform specific checkboxes
 *              before lockdown windows will be closed.
 * @details
 */
- (void) lockdownWindowsWillClose;

@end


/**
 * @protocol    SEBLockedViewControllerDelegate
 *
 * @brief       A SEBLockedViewController delegate opens a lock screen before passing
*               control to SEBLockedViewController and must conform to
 *              the SEBLockedViewControllerDelegate protocol.
 */
@protocol SEBLockedViewControllerDelegate <NSObject>
/**
 * @name		Item Attributes
 */
@required
/**
 * @brief       Time when SEB was lost active state.
 * @details
 */
@property (strong, readwrite) NSDate *didLockSEBTime;

/**
 * @brief       Time when SEB got active again.
 * @details
 */
@property (strong, readwrite) NSDate *didBecomeActiveTime;

/**
 * @brief       Time when exam was resumed.
 * @details
 */
@property (strong, readwrite) NSDate *didResumeExamTime;

/**
 * @brief       Callback executed when the correct password was entered.
 * @details
 */
- (void) correctPasswordEntered;

@optional

/**
 * @brief       Indicates if the exam is running.
 * @details
 */
@property(readwrite) BOOL examRunning;

/**
 * @brief       Indicates if SEB is locked
 * @details
 */
@property(readwrite) BOOL sebLocked;

/**
 * @brief       Indicates that the correct quit/unlock password was entered and
 *              lockdown windows can be closed now.
 * @details
 */
@property(readwrite) BOOL unlockPasswordEntered;

/**
 * @brief       Open a non-modal/overlay alert with details about the last
 *              lockdown event and possible overrides the user activated
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


@interface SEBLockedViewController : NSObject {
    @private
    NSString *challenge;
}

@property (nonatomic, strong) id< SEBLockedViewUIDelegate > UIDelegate;
@property (nonatomic, strong) id< SEBLockedViewControllerDelegate > controllerDelegate;

@property (nonatomic, strong) SEBKeychainManager *keychainManager;


@property (nonatomic, strong) NSString *currentAlertTitle;
@property (nonatomic, strong) NSString *currentAlertMessage;
@property (nonatomic, strong) NSDictionary *boldFontAttributes;

/// Manage locking SEB if it is attempted to resume an unfinished exam
- (void) addLockedExam:(NSString *)examURLString;
- (void) removeLockedExam:(NSString *)examURLString;
- (BOOL) isStartingLockedExam;

/// Lockview business logic
- (NSString *) appendChallengeToMessage:(NSString *)alertMessage;
- (void) appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime;
- (void) passwordEntered;
- (void) closeLockdownWindows;

@end
