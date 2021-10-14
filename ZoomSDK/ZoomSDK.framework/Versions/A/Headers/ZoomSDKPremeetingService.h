
#import <Foundation/Foundation.h>
#import "ZoomSDKErrors.h"


@interface ZoomSDKDirectShareHandler: NSObject
/**
 * @brief Input meeting number to share the screen directly. 
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed. 
 */
-(ZoomSDKError)inputMeetingNumber:(NSString*)meetingNumber;
/**
 * @brief Input pairing code in ZOOM Rooms to share the screen directly. 
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed. 
 */
-(ZoomSDKError)inputSharingKey:(NSString*)shareKey;
/**
 * @brief Designated to cancel input action.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)cancel;
@end

@interface ZoomSDKDirectShareSpecifyContentHandler: NSObject

/**
 * @brief Designated to get the supported direct share types.
 * @return If the function succeeds, it will return an array contains NSNumber with ZoomSDKShareContentType.
 */
- (NSArray<NSNumber *>*)getSupportedDirectShareType;

/**
 * @brief Designated to direct share application.
 * @param windowID The Application's window id to be shared.
 * @param shareSound Enable or disable share computer sound.
 * @param optimizeVideoClip Enable or disable optimizing for full screen video clip.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)tryShareApplication:(CGWindowID)windowID shareSound:(BOOL)shareSound optimizeVideoClip:(BOOL)optimizeVideoClip;

/**
 * @brief Designated to direct share desktop.
 * @param monitorID The ID of the monitor that to be shared.
 * @param shareSound Enable or disable share computer sound.
 * @param optimizeVideoClip Enable or disable optimizing for full screen video clip.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)tryShareDesktop:(CGDirectDisplayID)monitorID shareSound:(BOOL)shareSound optimizeVideoClip:(BOOL)optimizeVideoClip;

/**
 * @brief Designated to direct share frame.
 * @param shareSound Enable or disable share computer sound.
 * @param optimizeVideoClip Enable or disable optimizing for full screen video clip.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)tryShareFrame:(BOOL)shareSound optimizeVideoClip:(BOOL)optimizeVideoClip;

/**
 * @brief Designated to cancel the action.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)cancel;
@end

@protocol ZoomSDKDirectShareHelperDelegate<NSObject>
/**
 * @brief Notification if the status of direct sharing changes. 
 * @param status The status of direct sharing.
 * @param handler The handler works only when the value of status is DirectShareStatus_NeedMeetingIDOrSharingKey, DirectShareStatus_WrongMeetingIDOrSharingKey or DirectShareStatus_NeedInputNewPairingCode
 */
-(void)onDirectShareStatusReceived:(DirectShareStatus)status DirectShareReceived:(ZoomSDKDirectShareHandler*)handler;

/**
 * @brief Notification share specify share content.
 * @param handler The handler works only when the value of status is DirectShareStatus_Prepared
 */
-(void)onDirectShareSpecifyContent:(ZoomSDKDirectShareSpecifyContentHandler*)handler;
@end

@interface ZoomSDKDirectShareHelper: NSObject
{
    id<ZoomSDKDirectShareHelperDelegate> _delegate;
}
@property(nonatomic, assign) id<ZoomSDKDirectShareHelperDelegate> delegate;
/**
 * @brief Query if user can auto-share directly by using ultrasonic proximity signal.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed. 
 */
-(ZoomSDKError)canDirectShare;
/**
 * @brief Start direct sharing by using ultrasonic proximity signal. 
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed. 
 */
-(ZoomSDKError)startDirectShare;
/**
 * @brief Stop direct sharing by using ultrasonic proximity signal. 
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise failed. 
 */
-(ZoomSDKError)stopDirectShare;
@end


@interface ZoomSDKPremeetingService : NSObject
{
    ZoomSDKDirectShareHelper* _directShareHelper;
}

/**
 * @brief Turn on the video of participant when he joins the meeting. 
 * @param enable YES means enabled, otherwise not.
 */
- (void)enableForceAutoStartMyVideoWhenJoinMeeting:(BOOL)enable;

/**
 * @brief Turn off the video of participant when he joins the meeting.
 * @param enable YES means enabled, otherwise not.
 */
- (void)enableForceAutoStopMyVideoWhenJoinMeeting:(BOOL)enable;

/**
 * @brief Set the visibility of the dialog SELECT JOIN AUDIO when joining meeting. Default: enabled.
 * @param disable YES means disabled, otherwise not.
 */
- (void)disableAutoShowSelectJoinAudioDlgWhenJoinMeeting:(BOOL)disable;

/**
 * @brief Query if the current user is forced to enable video when joining the meeting.
 * @return YES means to force the current user to enable video, otherwise not. 
 */
- (BOOL)isUserForceStartMyVideoWhenInMeeting;

/**
 * @brief Query if the current user is forced to turn off video when joining the meeting.
 * @return YES means that the current user's video is forced to stop, otherwise not. 
 */
- (BOOL)isUserForceStopMyVideoWhenInMeeting;

/**
 * @brief Query if the feature that hide the dialog of joining meeting with audio in the meeting is enabled.
 * @return YES means hiding the dialog, otherwise not.
 */
- (BOOL)isUserForceDisableShowJoinAudioDlgWhenInMeeting;

/**
 * @brief Get the helper to share directly.
 * @return If the function succeeds, it will return a ZoomSDKDirectShareHelper object.
 */
- (ZoomSDKDirectShareHelper*)getDirectShareHelper;

/**
 * @brief Determine if the personal meeting ID is diabled or not.
 * @return YES means personal meeting ID is disabled, otherwise not.
 */
- (BOOL)isDisabledPMI;
@end
