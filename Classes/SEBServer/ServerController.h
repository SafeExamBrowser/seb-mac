//
//  LMSController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 25.01.19.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/**
 * @protocol    LMSControllerUIDelegate
 *
 * @brief       Learning Management System controllers confirming to the LMSControllerDelegate
 *              protocol are providing the interface to connect to LMS specific controllers
 *              and instantiate those.
 */
@protocol LMSControllerUIDelegate <NSObject>
/**
 * @name        Item Attributes
 */

@required
/**
 * @brief       Delegate method to be called if logging in to the server was canceled
 */
- (void) lmsControllerCancledLogin:(id)lmsController;

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
//- (void) hideEnterUsernamePasswordDialog;

@end

@interface LMSController : NSObject <LMSControllerDelegate> {
    @private
    NSString *lmsLoginLastUsername;
    NSString *lmsLoginBaseURL;
}

@property (weak) id delegate;
@property (strong) NSDictionary *lmsServer;
@property (strong, nonatomic) id lmsController;

- (instancetype) initWithLMSServer:(NSDictionary *)lmsServer;
- (void) loginToServer;
- (void) queryCredentialsPresetUsername:(NSString *)username;
- (void) loginCanceled;


@end

NS_ASSUME_NONNULL_END
