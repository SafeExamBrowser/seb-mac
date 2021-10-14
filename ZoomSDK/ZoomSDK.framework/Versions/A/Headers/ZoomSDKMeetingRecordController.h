
#import "ZoomSDKErrors.h"
typedef enum
{
	// For initialization.
    RecordingLayoutMode_None = 0,
	// Only record active speaker's video.
    RecordingLayoutMode_ActiveVideoOnly = 1,
	// Video wall mode.
    RecordingLayoutMode_VideoWall = (1<<1),
	// Record shared content with participants' video.
    RecordingLayoutMode_VideoShare = (1<<2),
	// Record only the audio.
    RecordingLayoutMode_OnlyAudio = (1<<3),
	// Record only the shared content.
    RecordingLayoutMode_OnlyShare = (1<<4),
}RecordingLayoutMode;

@interface CustomizedRecordingLayoutHelper : NSObject
/**
 * @brief Get the layout mode supported by the current meeting.
 * @return If the function succeeds, it will return the layout mode. The value is the 'bitwise OR' of each supported layout mode.
 */
- (int)getSupportLayoutMode;
/** 
 * @brief Get the list of users whose video source is available.
 * @return The list of users. ZERO(0) indicates that there is no available video source of users. 
 */
- (NSArray*)getValidVideoSource;
/**
 * @brief Get available shared source received by users. 
 * @return If the function succeeds, it will return a NSArray including all valid shared source received by users.
 */
- (NSArray*)getValidRecivedShareSource;
/**
 * @brief Query if sending shared source is available. 
 * @return YES means available, otherwise not.
 */
- (BOOL)isSendingShareSourceAvailable;
/**
 * @brief Determine if there exists the active video source.
 * @return YES means existing, otherwise not.
 */
- (BOOL)haveActiveVideoSource;

/**
 * @brief Select layout mode for recording.
 * @param mode The layout mode for recording.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise not.
 */
- (ZoomSDKError)selectRecordingLayoutMode:(RecordingLayoutMode)mode;
/**
 * @brief Add the video source of specified user to the list of recorded videos.
 * @param userid The ID of specified user.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise not.
 */
- (ZoomSDKError)addVideoSourceToResArray:(unsigned int)userid;

/**
 * @brief Add active video source to the array.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise not.
 * @note It works only when RecordingLayoutMode is RecordingLayoutMode_VideoWall or RecordingLayoutMode_VideoShare.
 */
- (ZoomSDKError)selectActiveVideoSource;

/**
 * @brief Select shared source of the specified user.
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise not.
 * @note It works only when RecordingLayoutMode is RecordingLayoutMode_OnlyShare.
 */
- (ZoomSDKError)selectShareSource:(unsigned int)userid;
/**
 * @brief Select shared source of the current user. 
 * @return If the function succeeds, it will return ZoomSDKError_Success. Otherwise not.
 * @note It works only when RecordingLayoutMode is RecordingLayoutMode_OnlyShare.
 */
- (ZoomSDKError)selectSendShareSource;
@end



@protocol ZoomSDKMeetingRecordDelegate <NSObject>

/**
 * @brief Callback event of ending the conversion to MP4 format.
 * @param success YES means converting successfully, otherwise not. 
 * @param recordPath The path of saving the recording file.
 *
 */
- (void)onRecord2MP4Done:(BOOL)success Path:(NSString*)recordPath;

/**
 * @brief Callback event of the process to convert the recording file to MP4 format. 
 * @param percentage Percentage of conversion process. Range from ZERO(0) to ONE HUNDREAD(100).
 *
 */
- (void)onRecord2MP4Progressing:(int)percentage;

/**
 * @brief Callback event that the status of local recording changes.
 * @param status Value of recording status. 
 *
 */
- (void)onRecordStatus:(ZoomSDKRecordingStatus)status;

/**
 * @brief Callback event that the status of Cloud recording changes.
 * @param status Value of recording status.
 *
 */
- (void)onCloudRecordingStatus:(ZoomSDKRecordingStatus)status;

/**
 * @brief Callback event that the recording authority changes.
 * @param canRec YES means that it is able to record, otherwise not.
 *
 */
- (void)onRecordPrivilegeChange:(BOOL)canRec;

/**
 * @brief Callback event that the local recording source changes in the custom UI mode.
 * @param helper A CustomizedRecordingLayoutHelper pointer.
 *
 */
- (void)onCustomizedRecordingSourceReceived:(CustomizedRecordingLayoutHelper*)helper;

@end


@interface ZoomSDKMeetingRecordController : NSObject
{
    id<ZoomSDKMeetingRecordDelegate> _delegate;
}
@property(nonatomic, assign)id<ZoomSDKMeetingRecordDelegate> delegate;
/**
 * @brief Determine if the current user is enabled to start recording.
 * @param isCloud YES means to determine whether to enable the cloud recording. NO local recording.
 * @return If the value of cloud_recording is set to TRUE and the cloud recording is enabled, the return value is ZoomSDKError_Success. If the value of cloud_recording is set to FALSE and the local recording is enabled, the return value is ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)canStartRecording:(BOOL)isCloud;
/**
 * @brief Determine if the current user owns the authority to change the recording permission of the others.
 * @return If the user own the authority, the return value is ZoomSDKError_Success. Otherwise failed. 
 */
- (ZoomSDKError)canAllowDisallowRecording;

/**
 * @brief Start cloud recording.
 * @param start Set it to YES to start cloud recording, NO to stop recording.
 * @return If the function succeeds, the return value is ZoomSDKError_Success. Otherwise failed. 
 */
- (ZoomSDKError)startCloudRecording:(BOOL)start;

/**
 * @brief Start recording on the local computer.
 * @param startTimestamp The timestamps when start recording.
 * @return If the function succeeds, the return value is ZoomSDKError_Success. Otherwise failed.  
 */
- (ZoomSDKError)startRecording:(time_t*)startTimestamp;

/**
 * @brief Stop recording on the local computer.
 * @param stopTimestamp The timestamps when stop recording.
 * @return If the function succeeds, the return value is SDKErr_Success. Otherwise failed.
 */
- (ZoomSDKError)stopRecording:(time_t*)stopTimestamp;

/**
 * @brief Determine if the user owns the authority to enable the local recording.
 * @param userid Specify the user ID.
 * @return If the specified user is enabled to start local recording, the return value is ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)isSupportLocalRecording:(unsigned int)userid;

/**
 * @brief Give the specified user authority for local recording.
 * @param allow YES means allowing user to record on the local computer, otherwise not.
 * @param userid Specify the user ID.
 * @return If the specified user is enabled to start local recording, the return value is ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)allowLocalRecording:(BOOL)allow User:(unsigned int)userid;

/**
 * @brief Set whether to enable custom local recording notification.
 * @param request Set it to YES to receive callback of onCustomizedRecordingSourceReceived.	
 * @return If the specified user is enabled to start local recording, the return value is ZoomSDKError_Success. Otherwise failed.
 */
- (ZoomSDKError)requestCustomizedLocalRecordingNotification:(BOOL)request;

/**
 * @brief Pause cloud recording.
 * @return If the function succeeds, the return value is ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)pauseCloudRecording;
/**
 * @brief Resume cloud recording.
 * @return If the function succeeds, the return value is ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)resumeCloudRecording;
/**
 * @brief Pause local recording
 * @return If the function succeeds, the return value is ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)pauseLocalRecording;
/**
 * @brief Resume local recording.
 * @return If the function succeeds, the return value is ZoomSDKError_Success. Otherwise failed.
 */
-(ZoomSDKError)resumeLocalRecording;
@end
