

#import "ZoomSDKErrors.h"

@protocol ZoomSDKPhoneHelperDelegate <NSObject>
/**
 * @brief Notify the callout status changes by inviting the specified user to join the meeting.
 * @param status The enum of PhoneStatus.
 * @param reason The reason for the failure to invite user by phone.
 */
-(void)onInviteCalloutUserStatus:(PhoneStatus)status FailedReason:(PhoneFailedReason)reason;

/**
 * @brief Notify the callout status changes by dialing out to Call Me.
 * @param status The enum of PhoneStatus.
 * @param reason The reason for the failure to invite user by phone.
 */
-(void)onCallMeStatus:(PhoneStatus)status FailedReason:(PhoneFailedReason)reason;
@end

@interface ZoomSDKPhoneSupportCountryInfo : NSObject
/**
 * @brief Get the ID of country where user can dial in.
 * @return The ID of country.
 */
-(NSString*)getCountryID;
/**
 * @brief Get the name of country.
 * @return The name of country.
 */
-(NSString*)getCountryName;
/**
 * @brief Get the code of country.
 * @return The code of country.
 */
-(NSString*)getCountryCode;
@end

@interface ZoomSDKCallInPhoneNumInfo : NSObject
/**
 * @brief Get the ID of country from which user calls in.
 * @return The country ID.
 */
-(NSString*) getID;
/**
 * @brief The code of country from where user calls in.
 * @return The code of country. 
 */
-(NSString*) getCode;
/**
 * @brief Get the name of country from where user calls in.
 * @return The name of country.	 
 */
-(NSString*) getName;
/** 
 * @brief Get the number for dialing in.
 * @return The number for dialing in.
 */
-(NSString*) getNumber;
/**
 * @brief Get the display number of the country.
 * @return The display number of the country.
 */
-(NSString*) getDisplayNumber;
/**
 * @brief Get the number type for dialing in.
 * @return The number type.
 */
-(CallInNumberType) getType;
@end

@interface ZoomSDKPhoneHelper : NSObject
{
    id<ZoomSDKPhoneHelperDelegate> _delegate;
    PhoneStatus _callMeStatus;
}
@property(nonatomic, assign)id<ZoomSDKPhoneHelperDelegate> delegate;
/**
 * @brief Determine if the user account supports to call out. 
 * @return YES means that client supports the feature of phone callout, otherwise not.
 */
-(BOOL)isSupportPhone;

/**
 * @brief Get the list of the countries which support to call out.
 * @return An NSArray contains ZoomSDKPhoneSupportCountryInfoList objects of all countries supporting to call out.  Otherwise nil.
 */
-(NSArray*)getSupportCountryInfo;

/**
 * @brief Invite the specified user to join the meeting by calling out.
 * @param userName User name to be displayed in the meeting.
 * @param number The phone number of destination.
 * @param countryCode The country code of the specified user must be in the support list. 
 * @return If the function succeeds, the return value is ZoomSDKError_Success. Otherwise failed. 
 */
-(ZoomSDKError)inviteCalloutUser:(NSString*)userName PhoneNumber:(NSString*)number CountryCode:(NSString*)countryCode;

/**
 * @brief Cancel the invitation that is being called out by phone.
 * @return If the function succeeds, the return value is ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)cancelCalloutUser;

/**
 * @brief Get the status of the invited user by calling out.
 * @return If the function succeeds, the return value is the current callout process.
 */
-(PhoneStatus)getInviteCalloutUserStatus;

/**
 * @brief Invite myself to join audio to the meeting by phone. 
 * @param number The phone number of the device.
 * @param countryCode The country code.
 * @return If the function succeeds, it will return ZoomSDKError_success, otherwise failed. 
 */
-(ZoomSDKError)callMe:(NSString*)number CountryCode:(NSString*)countryCode;

/**
 * @brief Cancel the current CALL ME action.
 * @return If the function succeeds, it will return ZoomSDKError_success, otherwise failed.
 */
-(ZoomSDKError)hangUp;

/**
 * @brief Get the status of myself by CALL ME.
 * @return If the function succeeds, the return value is the process of the invitation by CALL ME. 
 */
-(PhoneStatus)getCallMeStatus;

/**
 * @brief Get my participant ID to join meeting by calling in.  
 * @return If the function succeeds, the return value is the ID of participant.
 */
-(unsigned int)getCallInParticipantID;

/**
* @brief Get the information of number that user can call in to join meeting.
* @return If the function succeeds, it will return an array of ZoomSDKCallInPhoneNumInfo objects.
*/
-(NSArray*)getCallInNumberInfo;

@end
