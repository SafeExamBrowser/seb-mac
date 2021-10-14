
#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"
#import "ZoomSDKH323Helper.h"
#import "ZoomSDKPhoneHelper.h"
#import "ZoomSDKWaitingRoomController.h"
#import "ZoomSDKMeetingUIController.h"
#import "ZoomSDKMeetingConfiguration.h"
#import "ZoomSDKASController.h"
#import "ZoomSDKMeetingActionController.h"
#import "ZoomSDKLiveStreamHelper.h"
#import "ZoomSDKVideoContainer.h"
#import "ZoomSDKMeetingRecordController.h"
#import "ZoomSDKWebinarController.h"
#import "ZoomSDKCloseCaptionController.h"
#import "ZoomSDKRealNameAuthenticationController.h"
#import "ZoomSDKQAController.h"
#import "ZoomSDKNewBreakoutRoomController.h"
#import "ZoomSDKInterpretationController.h"
#import "ZoomSDKReactionController.h"
#import "ZoomSDKAppSignalController.h"

@interface ZoomSDKSecuritySessionKey : NSObject
{
    SecuritySessionComponet _component;
    NSData*                 _sessionKey;
    NSData*                 _iv;
}
@property(nonatomic, assign) SecuritySessionComponet component;
@property(nonatomic, retain) NSData* iv;
@property(nonatomic, retain) NSData* sessionKey;

@end

@interface ZoomSDKStartMeetingElements : NSObject
/**
 * @brief Set meetingNumber to 0 if you want to start a meeting with vanityID.
 */
@property(nonatomic, copy)NSString* vanityID;
/**
 * @brief It depends on the type of client account.
 */
@property(nonatomic, assign)ZoomSDKUserType userType;
/**
 * @brief It may be the number of a scheduled meeting or a Personal Meeting ID. Set it to 0 to start an instant meeting.
 */
@property(nonatomic, assign)long long meetingNumber;
/**
 * @brief Set it to YES to start sharing computer desktop directly when meeting starts.
 */
@property(nonatomic, assign)BOOL isDirectShare;
/**
 * @brief The APP to be shared.
 */
@property(nonatomic, assign)CGDirectDisplayID displayID;
/**
 * @brief Set it to YES to turn off the video when user joins meeting.
 */
@property(nonatomic, assign)BOOL isNoVideo;
/**
 * @brief Set it to YES to turn off the audio when user joins meeting.
 */
@property(nonatomic, assign)BOOL isNoAuido;
/**
 * @brief Customer Key the customer key of user.
 */
@property(nonatomic, copy)NSString* customerKey;
@end

@interface ZoomSDKStartMeetingUseZakElements : NSObject
/**
 * @brief Security session key got from web.
 */
@property(nonatomic, copy)NSString* zak;
/**
 * @brief User's screen name displayed in the meeting.
 */
@property(nonatomic, copy)NSString* displayName;
/**
 * @brief Set meetingNumber to 0 if you want to start a meeting with vanityID.
 */
@property(nonatomic, copy)NSString* vanityID;
/**
 * @brief User type.
 */
@property(nonatomic, assign)SDKUserType userType;
/**
 * @brief The ID of user got from ZOOM website.
 */
@property(nonatomic, copy)NSString* userId;
/**
 * @brief It may be the number of a scheduled meeting or a Personal Meeting ID. Set it to 0 to start an instant meeting.
 */
@property(nonatomic, assign)long long meetingNumber;
/**
 * @brief Set it to YES to start sharing computer desktop directly when meeting starts.
 */
@property(nonatomic, assign)BOOL isDirectShare;
/**
 * @brief The APP to be shared.
 */
@property(nonatomic, assign)CGDirectDisplayID displayID;
/**
 * @brief Set it to YES to turn off the video when user joins meeting.
 */
@property(nonatomic, assign)BOOL isNoVideo;
/**
 * @brief Set it to YES to turn off the audio when user joins meeting.
 */
@property(nonatomic, assign)BOOL isNoAuido;
/**
 * @brief Customer Key the customer key of user.
 */
@property(nonatomic, copy)NSString* customerKey;
@end

@interface ZoomSDKJoinMeetingElements : NSObject
/**
 * @brief Security session key got from web.
 */
@property(nonatomic, copy)NSString* zak;
/**
 * @brief It is indispensable for a panelist when user joins a webinar.
 */
@property(nonatomic, copy)NSString* webinarToken;
/**
 * @brief User's screen name displayed in the meeting.
 */
@property(nonatomic, copy)NSString* displayName;
/**
 * @brief Personal meeting URL, set meetingNumber to 0 if you want to start meeting with vanityID.
 */
@property(nonatomic, copy)NSString* vanityID;
/**
 * @brief It depends on the type of client account.
 */
@property(nonatomic, assign)ZoomSDKUserType userType;
/**
 * @brief Customer Key the customer key of user.
 */
@property(nonatomic, copy)NSString* customerKey;
/**
 * @brief The number of meeting that you want to join.
 */
@property(nonatomic, assign)long long meetingNumber;
/**
 * @brief Set it to YES to start sharing computer desktop directly when meeting starts.
 */
@property(nonatomic, assign)BOOL isDirectShare;
/**
 * @brief The APP to be shared.
 */
@property(nonatomic, assign)CGDirectDisplayID displayID;
/**
 * @brief Set it to YES to turn off the video when user joins meeting.
 */
@property(nonatomic, assign)BOOL isNoVideo;
/**
 * @brief Set it to YES to turn off the audio when user joins meeting.
 */
@property(nonatomic, assign)BOOL isNoAuido;
/**
 * @brief Meeting password. Set it to nil or @"" to remove the password.
 */
@property(nonatomic, copy)NSString *password;

@end

@protocol ZoomSDKMeetingServiceDelegate <NSObject>

@optional

/**
 * @brief Notify if ZOOM meeting status Changes.
 * @param state The status of ZOOM meeting.
 * @param error The enum of ZoomSDKMeetingError.
 * @param reason The enum of EndMeetingReason.
 */
- (void)onMeetingStatusChange:(ZoomSDKMeetingStatus)state meetingError:(ZoomSDKMeetingError)error EndReason:(EndMeetingReason)reason;

/**
 * @brief Notify that meeting needs external session key.
 * @param key The external session key
 */
- (void)onWaitMeetingSessionKey:(NSData*)key;

/**
 * @brief Notification of statistic warnings of Zoom Meeting.
 * @param type The statistic type.
 */
- (void)onMeetingStatisticWarning:(StatisticWarningType)type;

/**
 * @brief Designated for notify the free meeting need upgrade.
 * @param type The enumeration of FreeMeetingNeedUpgradeType, if the type is FreeMeetingNeedUpgradeType_BY_GIFTURL, user can upgrade free meeting through url. if the type is FreeMeetingNeedUpgradeType_BY_ADMIN, user can ask admin user to upgrade the meeting.
 * @param giftURL User can upgrade the free meeting through the url.
 */
- (void)onFreeMeetingNeedToUpgrade:(FreeMeetingNeedUpgradeType)type giftUpgradeURL:(NSString*)giftURL;

/**
 * @brief Designated for notify the free meeting which has been upgraded to free trail meeting has started.
 */
- (void)onFreeMeetingUpgradeToGiftFreeTrialStart;

/**
 * @brief Designated for notify the free meeting which has been upgraded to free trail meeting has stoped.
 */
- (void)onFreeMeetingUpgradeToGiftFreeTrialStop;

/**
 * @brief Designated for notify the free meeting has been upgraded to professional meeting.
 */
- (void)onFreeMeetingUpgradedToProMeeting;

/**
 * @brief Designated for notify the free meeting remain time has been stoped to count down.
 */
- (void)onFreeMeetingRemainTimeStopCountDown;

/**
 * @brief Inform user the remaining time of free meeting.
 * @param seconds The remaining time of the free meeting.
 */
- (void)onFreeMeetingRemainTime:(unsigned int)seconds;
@end

/**
 * @brief It is an implementation for client to start/join a Meeting.
 * @note The meeting service allows only one concurrent operation at a time, which means, only one API call is in progress at any given time.		 
 */
@interface ZoomSDKMeetingService : NSObject
{
    id<ZoomSDKMeetingServiceDelegate> _delegate;
    ZoomSDKMeetingUIController* _meetingUIController;
    ZoomSDKMeetingConfiguration* _meetingConfiguration;
    ZoomSDKH323Helper*           _h323Helper;
    ZoomSDKWaitingRoomController* _waitingRoomController;
    ZoomSDKPhoneHelper*           _phoneHelper;
    ZoomSDKASController*          _asController;
    ZoomSDKMeetingActionController*  _actionController;
    ZoomSDKLiveStreamHelper*         _liveStreamHelper;
    //customized UI
    ZoomSDKVideoContainer*           _videoContainer;
    ZoomSDKMeetingRecordController*  _recordController;
    ZoomSDKWebinarController*        _webinarController;
    ZoomSDKCloseCaptionController*   _closeCaptionController;
    ZoomSDKRealNameAuthenticationController*       _realNameController;
    ZoomSDKQAController*             _QAController;
    ZoomSDKNewBreakoutRoomController*  _newBOController;
    ZoomSDKInterpretationController *  _InterpretationController;
    ZoomSDKReactionController*         _reactionController;
    ZoomSDKAppSignalController*        _appSignalController;
}
/**
 * Callback of receiving meeting events.
 */
@property (assign, nonatomic) id<ZoomSDKMeetingServiceDelegate> delegate;

/**
 * @brief Get the meeting UI controller interface.
 * @return If the function succeeds, the return value is an object of ZoomSDKMeetingUIController. Otherwise returns nil.
 */
- (ZoomSDKMeetingUIController*)getMeetingUIController;

/**
 * @brief Get the configuration of the meeting.
 * @return If the function succeeds, the return value is an object of ZoomSDKMeetingConfiguration. Otherwise returns nil.
 */
- (ZoomSDKMeetingConfiguration*)getMeetingConfiguration;

/**
 * @brief Get the default H.323 helper of ZOOM meeting service. 
 * @return If the function succeeds, the return value is a ZoomSDKH323Helper object of H.323 Helper. 
 */
- (ZoomSDKH323Helper*)getH323Helper;

/**
 * @brief Get default Waiting Room Controller of ZOOM meeting service.
 * @return If the function succeeds, the return value is an object of ZoomSDKWaitingRoomController. Otherwise returns nil. 
 */
- (ZoomSDKWaitingRoomController*)getWaitingRoomController;

/**
 * @brief Get the default AS(APP share) Controller of ZOOM meeting service.
 * @return If the function succeeds, the return value is an object of ZoomSDKASController. Otherwise returns nil.  
 */
- (ZoomSDKASController*)getASController;

/**
 * @brief Get the  default Phone Callout Helper of Zoom meeting service.
 * @return If the function succeeds, the return value is an object of ZoomSDKPhoneHelper. Otherwise returns nil. 
 */
- (ZoomSDKPhoneHelper*)getPhoneHelper;

/**
 * @brief Get the default action controller(mute audio/video etc) of ZOOM meeting service.
 * @return If the function succeeds, the return value is an object of ZoomSDKMeetingActionController. Otherwise returns nil. 
 */
- (ZoomSDKMeetingActionController*)getMeetingActionController;

/**
 * @brief Get the default live stream helper of ZOOM meeting service.
 * @return If the function succeeds, the return value is an object of ZoomSDKLiveStreamHelper. Otherwise returns nil. 
 */
- (ZoomSDKLiveStreamHelper*)getLiveStreamHelper;

/**
 * @brief Get the custom video container of ZOOM SDK.
 * @return If the function succeeds, the return value is an object of ZoomSDKVideoContainer which allows user to customize in-meeting UI. Otherwise returns nil. 
 */
- (ZoomSDKVideoContainer*)getVideoContainer;

/**
 * @brief Get the custom recording object of ZOOM SDK.
 * @return If the function succeeds, the return value is an object of ZoomSDKMeetingRecordController which allows user to customize meeting recording. Otherwise returns nil. 
 */
- (ZoomSDKMeetingRecordController*)getRecordController;
/**
 * @brief Get the custom webinar controller.
 * @return If the function succeeds, the return value is an object of ZoomSDKWebinarController which allows you to customize webinar. Otherwise returns nil. 
 */
- (ZoomSDKWebinarController*)getWebinarController;

/**
 * @brief Get controller of close caption in Zoom meeting.
 * @return If the function succeeds, it will return a ZoomSDKCloseCaptionController object which you can use to handle close caption in meeting.
 */
- (ZoomSDKCloseCaptionController*)getCloseCaptionController;

/**
 * @brief Get object of controller ZoomSDKRealNameAuthenticationController.
 * @return If the function succeeds, it will return a ZoomSDKRealNameAuthenticationController object which you can use to Real-name authentication.
 */
-(ZoomSDKRealNameAuthenticationController *)getRealNameController;

/**
 * @brief Get object of ZoomSDKQAController.
 * @return If the function succeeds, it will return a ZoomSDKQAController object.
 */
-(ZoomSDKQAController *)getQAController;

/**
 *@brief Get object of ZoomSDKNewBreakoutRoomController.
 *@return If the function succeeds, it will return a ZoomSDKNewBreakoutRoomController object.
 */
-(ZoomSDKNewBreakoutRoomController *)getNewBreakoutRoomController;

/**
 *@brief Get object of ZoomSDKInterpretationController.
 *@return If the function succeeds, it will return a ZoomSDKInterpretationController object.
 */
-(ZoomSDKInterpretationController*)getInterpretationController;

/**
 *@brief Get object of ZoomSDKReactionController.
 *@return If the function succeeds, it will return a ZoomSDKReactionController object.
 */
-(ZoomSDKReactionController*)getReactionController;

/**
 *@brief Get object of ZoomSDKAppSignalController.
 *@return If the function succeeds, it will return a ZoomSDKAppSignalController object.
 */
-(ZoomSDKAppSignalController*)getAppSignalController;

/**
 * @brief Start a ZOOM meeting with meeting number for login user.
 * @param context It is a ZoomSDKStartMeetingElements class,contain all params to start meeting.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)startMeeting:(ZoomSDKStartMeetingElements *)context;
/**
 * @brief Start a ZOOM meeting with ZAK.
 * @note It is just for non-logged-in user. 
 * @param context It is a ZoomSDKStartMeetingUseZakElements class,contain all params to start meeting with zak.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed. 
 */
-(ZoomSDKError)startMeetingWithZAK:(ZoomSDKStartMeetingUseZakElements *)context;
/**
 * @brief Join a Zoom meeting.
 * @note toke4enfrocelogin/customerKey is for API user.
 * @param context It is a ZoomSDKJoinMeetingElements class,contain all params to join meeting.
 * @return If the function succeeds, it will return ZoomSDKError_Success. 
 */
-(ZoomSDKError)joinMeeting:(ZoomSDKJoinMeetingElements *)context;
/**
 * @brief End/Leave the current meeting.
 * @param cmd The command for leaving the current meeting. Only host can end the meeting.
 */
- (void)leaveMeetingWithCmd:(LeaveMeetingCmd)cmd;

/**
 * @brief Get the status of meeting.
 * @return The status of meeting. 
 */
- (ZoomSDKMeetingStatus)getMeetingStatus;

/**
 * @brief Get the property of meeting.
 * @param command Commands for user to get different properties.
 * @return If the function succeeds, it will return an NSString of meeting property, otherwise failed.
 */
- (NSString*)getMeetingProperty:(MeetingPropertyCmd)command;

/**
 * @brief Get the network quality of meeting connection.
 * @param component Video/audio/share.
 * @param sending Set it to YES to get the status of sending data, NO to get the status of receiving data.
 * @return If the function succeeds, it will return an enumeration of network connection quality, otherwise failed.
 */
- (ZoomSDKConnectionQuality)getConnectionQuality:(ConnectionComponent)component Sending:(BOOL)sending;
/**
 * @brief Get the type of current meeting.
 * @return If the function succeeds, it will return the type of meeting, otherwise failed.
 */
- (MeetingType)getMeetingType;

/**
 * @brief Determine whether the meeting is failover or not. Available only for Huawei.
 * @return YES means the current meeting is failover, otherwise not. 
 */

-(BOOL)isFailoverMeeting;

/**
 * @brief Handle the event that user joins meeting from web or meeting URL.
 * @param urlAction The URL string got from web.
 * @return If the function succeeds, it will return ZoomSDKError_Succuss, otherwise failed.
 */
- (ZoomSDKError)handleZoomWebUrlAction:(NSString*)urlAction;
@end





