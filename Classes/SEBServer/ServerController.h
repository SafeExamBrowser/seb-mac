//
//  ServerController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 25.01.19.
//

#import <Foundation/Foundation.h>
#import "SafeExamBrowser-Swift.h"

@class SEBServerController;

NS_ASSUME_NONNULL_BEGIN

///**
// * @protocol    ServerControllerUIDelegate
// *
// * @brief       Learning Management System controllers confirming to the LMSControllerDelegate
// *              protocol are providing the interface to connect to LMS specific controllers
// *              and instantiate those.
// */
//@protocol ServerControllerUIDelegate <NSObject>
///**
// * @name        Item Attributes
// */
//
//@required
///**
// * @brief       Delegate method to be called if logging in to the server was canceled
// */
//- (void) lmsControllerCancledLogin:(id)lmsController;
//
///**
// * @brief       Delegate method to display an enter password dialog with the
// *              passed message text asynchronously, calling the callback
// *              method with the entered password when one was entered
// */
//- (void) showEnterUsernamePasswordDialog:(NSString *)text
//                                   title:(NSString *)title
//                                username:(NSString *)username
//                           modalDelegate:(id)modalDelegate
//                          didEndSelector:(SEL)didEndSelector;
///**
// * @brief       Delegate method to hide the previously displayed enter password dialog
// */
//- (void) hideEnterUsernamePasswordDialog;
//
//@end

@interface ServerController : NSObject <ServerControllerDelegate>
{
    @private
    NSString *lmsLoginLastUsername;
    NSString *lmsLoginBaseURL;
}

@property (weak) id delegate;
@property (strong) NSDictionary *sebServer;
@property (strong, nonatomic) id sebServerController;

- (BOOL) connectToServer:(NSURL *)url withConfiguration:(NSDictionary *)sebServerConfiguration;
- (void) loginToServer;
- (void) queryCredentialsPresetUsername:(NSString *)username;
- (void) loginCanceled;


@end

NS_ASSUME_NONNULL_END
