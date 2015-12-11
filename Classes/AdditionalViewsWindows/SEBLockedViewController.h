//
//  SEBLockedViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03/12/15.
//
//

#import <Foundation/Foundation.h>
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "SEBKeychainManager.h"
#include <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

/**
 * @protocol    SEBLockedViewUIDelegate
 *
 * @brief       All SEBLockedView UI controller must conform to the SEBConfigUIDelegate
 *              protocol.
 */
@protocol SEBLockedViewUIDelegate <NSObject>
/**
 * @name		Item Attributes
 */
@required
/**
 * @brief       Scroll to the bottom of the locked view scroll view.
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
 * @brief       Hide or show label indicating wrong password was entered.
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
 * @brief       Hide or show label indicating wrong password was entered.
 * @details
 */
- (void) closeLockdownWindows;

@end


/**
 * @protocol    SEBLockedViewControllerDelegate
 *
 * @brief       All SEBLockedView root controller must conform to 
 *              the SEBLockedViewControllerDelegate protocol.
 */
@protocol SEBLockedViewControllerDelegate <NSObject>
/**
 * @name		Item Attributes
 */
@required
/**
 * @brief       Return time when active state/Guided Access was
 *              interrupted.
 * @details
 */
@property (strong, readwrite) NSDate *didResignActiveTime;

/**
 * @brief       Return time when active state/Guided Access was activated again.
 * @details
 */
@property (strong, readwrite) NSDate *didBecomeActiveTime;

/**
 * @brief       Time when exam was resumed.
 * @details
 */
@property (strong, readwrite) NSDate *didResumeExamTime;

/**
 * @brief       Hide or show the label indicating that the password was entered wrong.
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
 * @brief       Hide or show label indicating wrong password was entered.
 * @details
 */
- (void) closeLockdownWindows;

@end


@interface SEBLockedViewController : NSObject

@property (nonatomic, strong) id< SEBLockedViewUIDelegate > UIDelegate;
@property (nonatomic, strong) id< SEBLockedViewControllerDelegate > controllerDelegate;

//@property (strong) SEBKeychainManager *keychainManager;

@property (strong) NSDictionary *boldFontAttributes;

- (void) passwordEntered:(id)sender;
- (void) shouldCloseLockdownWindows;
- (void) appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime;

@end
