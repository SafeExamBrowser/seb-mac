//
//  SEBBrowserController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 22/01/16.
//
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

@end


#import <Foundation/Foundation.h>

@interface SEBBrowserController : NSObject

@property (weak) id delegate;

@property (readwrite) BOOL usingCustomURLProtocol;

@property (strong) NSURLAuthenticationChallenge *pendingChallenge;

- (void) createSEBUserAgentFromDefaultAgent:(NSString *)defaultUserAgent;
- (void) conditionallyInitCustomHTTPProtocol;

@end
