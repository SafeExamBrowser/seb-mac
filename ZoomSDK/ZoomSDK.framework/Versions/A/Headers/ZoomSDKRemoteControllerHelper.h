
//  [Used for Customized UI]

#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"
@protocol ZoomSDKRemoteControllerDelegate <NSObject>
/**
 * @brief Notification of remote control status.
 * @param status The status of remote control.
 * @param userID The ID of user who can control others remotely.
 *
 */
- (void)onRemoteControlStatus:(ZoomSDKRemoteControlStatus)status User:(unsigned int)userID;
@end

@interface ZoomSDKRemoteControllerHelper : NSObject
{
    id<ZoomSDKRemoteControllerDelegate> _delegate;
    
}
@property(nonatomic, assign) id<ZoomSDKRemoteControllerDelegate> delegate;
/**
 * @brief Determine if it is able for the current user to request to control others remotely.
 * @param userid The ID of user to be controlled remotely.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)canRequestRemoteControl:(unsigned int)userid;

/**
 * @brief Determine if user has the privilege to control the specified user remotely. 
 * @param userid The ID of user to be checked.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed. 
 */
- (ZoomSDKError)haveRemoteControlPrivilege:(unsigned int)userid;

/**
 * @brief Determine if the current user is controlling the specified user remotely.
 * @param userid The ID of user to be checked.
 * @return If the current user is controlling, it will return ZoomSDKError_Success, otherwise not.
 */
- (ZoomSDKError)isInRemoteControlling:(unsigned int)userid;

/**
 * @brief Start controlling remotely the computer of specified user.
 * @param userid The ID of user to be controlled remotely. 
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)startRemoteControl:(unsigned int)userid;

/**
 * @brief Stop controlling remotely.
 * @param userid The ID of user who is controlled remotely by the current user. 
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)stopRemoteControl:(unsigned int)userid;

/**
 * @brief Request to control remotely the specified user.
 * @param userid The ID of user to be controlled. 
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)requestRemoteControl:(unsigned int)userid;

/**
 * @brief Give up controlling remotely the specified user.
 * @param userid The ID of user having been controlled.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)giveUpRemoteControl:(unsigned int)userid;

/**
 * @brief Give the remote control privilege to the specified user.
 * @param userid The ID of user that you ask to control yourself remotely.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)giveRemoteControlPrivilegeTo:(unsigned int)userid;

/**
 * @brief Refuse the request to remote control from the specified user.
 * @param userid The ID of demander.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)declineRemoteControlRequest:(unsigned int)userid;

/**
 * @brief Get back the authority of remote control.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)revokeRemoteControl;

/**
 * @brief Get the identity of current controller. 
 * @param userid The pointer to unsigned int. If the function calls successfully, it will return the user id of current remote controller.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)getCurrentRemoteController:(unsigned int*)userid;

/**
 * @brief Send remote control action. 
 * @param theEvent The mouse or keyboard event.
 * @param shareView The view that you want to control remotely.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)sendRemoteControlEvent:(NSEvent *)theEvent ShareView:(NSView*)shareView;
@end
