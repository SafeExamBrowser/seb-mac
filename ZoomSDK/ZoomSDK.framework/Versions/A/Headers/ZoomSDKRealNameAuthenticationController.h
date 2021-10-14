
#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"

typedef enum
{
    ZoomSDKSMSError_Unkunow,
    ZoomSDKSMSError_Success,
    ZoomSDKSMSError_Retrieve_SendSMSFailed,
    ZoomSDKSMSError_Retrieve_InvalidPhoneNum,
    ZoomSDKSMSError_Retrieve_PhoneNumAlreadyBound,
    ZoomSDKSMSError_Retrieve_PhoneNumSendTooFrequent,
    ZoomSDKSMSError_Verify_CodeIncorrect,
    ZoomSDKSMSError_Verify_CodeExpired,
    ZoomSDKSMSError_Verify_UnknownError,
}ZoomSDKSMSVerificationCodeError;

@interface ZoomSDKRetrieveSMSVerificationCodeController : NSObject

/**
 * @brief Send message to mobile phone.
 * @param code international area code for mobile phone number.
 * @param phoneNumber  user phone number.
 * @return If the function succeeds,will return ZoomSDKError_Success.
 */
- (ZoomSDKError)retriveWithCountryCode:(NSString *)code PhoneNum:(NSString *)phoneNumber;

/**
 * @brief Cancel and leave meeting.
 * @return If the function succeeds,will return ZoomSDKError_Success.
 */
- (ZoomSDKError)cancelAndLeaveMeeting;
@end

@interface ZoomSDKVerifySMSVerificationCodeController : NSObject

/**
 * @brief Verify SMS verification code.
 * @param country_Code international area code for mobile phone number.
 * @param number  user phone number.
 * @param code  the SMS verification code.
 * @return If the function succeeds,will return ZoomSDKError_Success.
 */
- (ZoomSDKError)verifyWithCountryCode:(NSString *)countryCode  withPhoneNumber:(NSString *)number  withCode:(NSString *)code;

/**
 * @brief Cancel and leave meeting.
 * @return If the function succeeds,will return ZoomSDKError_Success.
 */
- (ZoomSDKError)cancelAndLeaveMeeting;
@end

@interface ZoomSDKRealNameAuthCountryInfo : NSObject
/**
 * @brief Get the country ID of mobile phone number.
 * @return the mobile phone number country ID.
 */
- (NSString *)getCountryID;

/**
 * @brief Get the country Name of mobile phone number.
 * @return the mobile phone number country Name.
 */
- (NSString *)getCountryName;

/**
 * @brief Get the country code of mobile phone number.
 * @return the mobile phone number country code.
 */
- (NSString *)getCountryCode;
@end

@protocol ZoomSDKRealNameAuthenticationDelegate <NSObject>

/**
 * @brief Notify support the Real-name authentication
 * @param support_country_list  the sdk support country list.
 * @param privacy_url  the privacy url about Real-name authentication meeting
 * @param handler  object of ZoomSDKRetrieveSMSVerificationCodeController.
 */
-(void)onNeedRealNameAuthMeetingWithSupportCountryList:(NSArray *)supportCountryList  withPrivacyURL:(NSString *)privacyURL withRetrieveSMSVerificationCodeHandler:(ZoomSDKRetrieveSMSVerificationCodeController *)handler;

/**
 * @brief Notify the send MSM verification code result
 * @param result the MSM send is success or not.
 * @param handler the handle work only when the result is ZoomSDKSMSError_Success.
 */
-(void)onRetrieveSMSVerificationCodeResult:(ZoomSDKSMSVerificationCodeError)result  withVerifySMSVerificationCodeHandle:(ZoomSDKVerifySMSVerificationCodeController *)handler;

/**
 * @brief Notify the MSM verification code verify result.
 * @param reuslt the SMS verification code is correct or not.
 */
-(void)onVerifySMSVerificationCodeResult:(ZoomSDKSMSVerificationCodeError)reuslt;
@end

@interface ZoomSDKRealNameAuthenticationController : NSObject
{
    id<ZoomSDKRealNameAuthenticationDelegate> _delegate;
}
@property(nonatomic,assign)id<ZoomSDKRealNameAuthenticationDelegate>  delegate;

/**
 * @brief Enable to show the zoom Real-name authentication meeting UI
 * @param enable Yes means show the zoom Real-name authentication meeting UI,otherwise not.
 * @return If the function succeeds,will return ZoomSDKError_Success.
 */
-(ZoomSDKError)enableZoomAuthRealNameMeetingUIShown:(BOOL)enable;

/**
 * @brief Get the country for mobile phone number supported by the SDK.
 * @return If the function succeeds,will get the support country list.
 */
-(NSArray *)getSupportPhoneNumberCountryList;

/**
 * @brief  Get the resend Verification Code Controller.
 * @return An object of ZoomSDKRetrieveSMSVerificationCodeController.
 */
-(ZoomSDKRetrieveSMSVerificationCodeController *)resendSMSVerificationCodeController;

/**
 * @brief  Get the reVerify Code Controller.
 * @return An object of ZoomSDKVerifySMSVerificationCodeController.
 */
-(ZoomSDKVerifySMSVerificationCodeController *)reVerifySMSVerificationCodeController;

/**
 * @brief  Set the default cell phone information.
 * @return If the function succeeds, will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)setDefaultCellPhoneInfo:(NSString*)countryCode phoneNumber:(NSString*)phoneNumber;
@end

