

#import <Cocoa/Cocoa.h>
#import "ZoomSDKErrors.h"

@interface ZoomSDKAuthContext : NSObject

/**
 *@brief jwtToken The new auth token.
 */
@property(nonatomic, copy) NSString *jwtToken;

@end

@interface ZoomSDKWebinarRegistrationExplainInfo : NSObject

@property(nonatomic, copy,readonly) NSString *content;

@property(nonatomic, copy,readonly) NSString *accountOwnerLink;

@property(nonatomic, copy,readonly) NSString *termLink;

@property(nonatomic, copy,readonly) NSString *policyLink;

@end

@interface ZoomSDKAccountInfo : NSObject
/**
 * @brief Get user's screen name.
 * @return If the function succeeds, it will return user's screen name. 
 */
- (NSString*) getDisplayName;
/**
 * @brief Get the type of user.
 * @return If the function succeeds, it will return the type of the user,
 */
- (ZoomSDKUserType) getSDKUserType;
@end

@protocol ZoomSDKAuthDelegate;
/**
 * @brief Callback event of ZOOM SDK authorization. 
 * Authorize Zoom SDK and the custom application with the key/secret before usage. Once authorize successfully, ZoomSDKAuthDelegate will return ZoomSDKAuthError_Success via onZoomSDKAuthReturn.
 * @note You should authorize ZOOM SDK firstly before using it, or no, it may not work.
 */
@interface ZoomSDKAuthService : NSObject
{
    BOOL _isLogin;
    id<ZoomSDKAuthDelegate> _delegate;
}
@property (assign, nonatomic) id<ZoomSDKAuthDelegate> delegate;


/**
 * @brief Authenticate SDK.
 * @param key The key of your client, also known as API key. 
 * @param secret The secret of your client. DO NOT publish it.
 * @note If the client key or secret is empty, user will get error:ZoomSDKError_InvalidPrameter directly.
 * @return If the function succeeds, it will return ZoomSDKError_success, meanwhile it will return SDK auth when calling synchronously onZoomSDKAuthReturn. 
 */
- (ZoomSDKError)sdkAuth:(NSString*)key appSecret:(NSString*)secret;

/**
 @brief New authenticate SDK.
 @param jwttoken A Class object containing auth information.
 @return If the function succeeds, it will return ZoomSDKError_success.
 @note If the jwttoken expired,will return "onZoomAuthIdentityExpired" callback.
 */
- (ZoomSDKError)sdkAuth:(ZoomSDKAuthContext*)jwttoken;

/**
 * @brief Determine if SDK is authorized.
 * @return YES means that it is authorized, otherwise failed.
 */
- (BOOL)isAuthorized;
/**
 * @brief Login ZOOM with email.
 * @param userName The email for login.
 * @param password The password for login.
 * @param rememberMe Set it to YES so that user can login automatically next time, otherwise not.
 * @return If the function succeeds, it will return ZoomSDKError_success, meanwhile it will return SDK login result when calling asynchronously onZoomSDKLogin.
 */
- (ZoomSDKError)login:(NSString*)userName Password:(NSString*)password RememberMe:(BOOL)rememberMe;
/**
* @brief Generate SSO login web url.
* @param NSString The prefix of vanity url.
* @return If the function succeeds,will return url of can launch app.
*/
- (NSString*)generateSSOLoginWebURL:(NSString*)prefixOfVanityUrl;

/**
 * @brief Login ZOOM with uri protocol.
 * @param uriProtocol For the parameter to be used for sso account login.
 * @return If the function succeeds, it will return ZoomSDKError_success. Otherwise failed.
 */
- (ZoomSDKError)SSOLoginWithWebUriProtocol:(NSString*)uriProtocol;
/**
 * @brief Logout ZOOM.
 * @return If the function succeeds, it will return ZoomSDKError_success, meanwhile it will call asynchronously onZoomSDKLogout.
 */
- (ZoomSDKError)logout;

/**
 * @brief Get user's account information. 
 * @return When user logged in, it will return ZoomSDKAccountInfo object if the function calls successfully. Otherwise returns nil.
 */
- (ZoomSDKAccountInfo*)getAccountInfo;

/**
 * @brief Get SDK identity.
 * @return The SDK identity.
 */
- (NSString*)getSDKIdentity;
/**
 * @brief Determine if email login mode is enabled.
 * @return If the function succeeds, otherwise not.
 * @note You should call this APIs after you have receive callback of auth success event.
 */
- (ZoomSDKError)isEmailLoginEnabled:(BOOL*)isEnabled;

/**
 @brief Get the webinal legal notices prompt.
 @return If the function succeeds, it will return the webinal legal notices prompt. Otherwise nil.
 */
- (NSString *)getWebinarRegistrationLegalNoticesPrompt;

/**
 @brief Get the webinal legal notices explained.
 @return If the function succeeds, it will return the webinal legal notices explained. Otherwise nil.
 */
- (ZoomSDKWebinarRegistrationExplainInfo *)getWebinarRegistrationLegalNoticesExplained;

@end


@protocol ZoomSDKAuthDelegate <NSObject>

@required
/**
 * @brief Specify to get the response of ZOOM SDK authorization. 
 * @param returnValue Notify user that the authentication status changes.
 *
 */
- (void)onZoomSDKAuthReturn:(ZoomSDKAuthError)returnValue;

/**
 @brief Specify to get the response of ZOOM SDK authorization identity expired.
 */
 - (void)onZoomAuthIdentityExpired;

@optional
/**
 * @brief Specify to get the response of ZOOM SDK Login.
 * @param reason Notify user that the failed reason.
 * @param loginStatus Notify user of login status.
 */
- (void)onZoomSDKLoginResult:(ZoomSDKLoginStatus)loginStatus failReason:(ZoomSDKLoginFailReason)reason;
/**
 * @brief Specify to get the response of ZOOM SDK logout.
 */
- (void)onZoomSDKLogout;

/**
 * @brief Specify to get the response if ZOOM identity is expired.
 * @note User will be forced to logout once ZOOM SDK identity expired.
 */
- (void)onZoomIdentityExpired;

@end
