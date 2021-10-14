
#import "ZoomSDKErrors.h"
@interface ZoomSDKMeetingConfiguration :NSObject
{
    //The APP to be shared.
    CGDirectDisplayID  _displayAppID;
    //The monitor ID.
    CGDirectDisplayID  _monitorID;
    //The location of float video.
    NSPoint            _floatVideoPoint;
    //The visibility of toolbar when sharing.
    BOOL               _shareToolBarVisible;
    //The location of main interface of meeting.
    NSPoint            _mainVideoPoint;
    //The visibility of the window of waiting for the host.
    BOOL               _jbhWindowVisible;
    //Attendees join the meeting with audio muted.
    BOOL               _enableMuteOnEntry;
    //Play chime when user joins/leaves meeting
    BOOL               _enableChime;
    //Query whether to share screen or not.
    BOOL               _isDirectShareDesktop;
    //Enable auto-adjust the speaker volume when joining meeting.
    BOOL               _enableAutoAdjustSpeakerVolume;
    //Enable auto-adjust the microphone volume.
    BOOL                _enableAutoAdjustMicVolume;
    //Hide the prompt dialog of wrong password.
    BOOL                _disablePopupWrongPasswordWindow;
    //Auto-adjust speaker volume when joining meeting.  
    BOOL                _autoAdjustSpeakerVolumeWhenJoinAudio;
    //Auto adjust microphone volume when joining meeting.  
    BOOL                _autoAdjustMicVolumeWhenJoinAudio;
    //Disable the alert to end another ongoing meeting.
    BOOL                _disableEndOtherMeetingAlert;
    //Disable the prompt dialog to input password.
    BOOL                _disableInputPasswordWindow;
    //Disable the feature to enter full screen by double click.
    BOOL                _disableDoubleClickToFullScreen;
    //Hide the window of thumbnail video.
    BOOL                _hideThumbnailVideoWindow;
    //Huawei security APP name. 
    NSString*           _securityAppName;
    //Disable to rename in meeting
    BOOL                _disableRenameInMeeting;
    //Disable ZOOM original actions of clicking share button.
    BOOL                _disableShareButtonClickOriginAction;
    //Disable ZOOM original actions of clicking toolbar invite button.
    BOOL                _disableToolbarInviteButtonClickOriginAction;
    //Input meeting information in advance when user joins webinar.
    BOOL                _needPrefillWebinarJoinInfo;
    //Hide register webinar window when join webinar.
    BOOL                _hideRegisterWebinarInfoWindow;
    //Disable ZOOM original actions of clicking button participants.
    BOOL                _disableParticipantButtonClickOriginAction;
    //Hide the window of phone dialing in.
    BOOL                _hideTelephoneInAudiowWindow;
    //Hide the window of CALL ME.
    BOOL                _hideCallMeInAudioWindow;
    //Forbid multi-participants sharing at the same time.
    BOOL                _forceDisableMultiShare;
	//Disable custom live stream.
    BOOL                _disableCustomLiveStreamAction;
    //Set whether to disable ZOOM original reminder action for free user.
    BOOL                _disableFreeUserOriginAction;
    //Disable the ZOOM original notification of remaining time for meeting organized by free user.
    BOOL                _disableFreeMeetingRemainTimeNotify;
	//Hide the h323 call in tab on invite window.
    BOOL                _hideInviteInMeetingH323CallInTab;
	//Hide the h323 call out tab on invite window.
    BOOL                _hideInviteInMeetingH323CallOutTab;
    //Hide meeting static warning of bad network.
    BOOL                _hideMeetingStaticBadNetWorkWaring;
    //Hide meeting static warning of system busy.
    BOOL                _hideMeetingStaticSystemBusyWaring;
    //Hide switch camera button when sharing camera.
    BOOL                _hideSwitchCameraButton;
    //Disable opening recording file when meeting end.
    BOOL                _disableOpenRecordFileWhenMeetingEnd;
    //Hide 'show keypad' button on meeting window.
    BOOL                _hideShowKeypadButton;
    //Hide copy URL button when invite others join meeting
    BOOL                _hideCopyURLButtonWhenInviteOthers;
    //Hide copy Invitation button when invite others join meeting
    BOOL                _hideCopyInvitationButtonWhenInviteOthers;
    //Hide chat menu item in-meeting.
    BOOL                _hideChatItemInMeeting;
    //Hide remote control item on more menu.
    BOOL                _hideRemoteControlItemOnMoreMenu;
    //Hide choose save recording file path window.
    BOOL                _hideChooseSaveRecordingFilePathWindow;
    //Disable ZOOM original actions of clicking Audio button.
    BOOL                _disableAudioButtonClickOriginAction;
    //Disable audio menu item original action in-meeting.
    BOOL                _disableAudioSettingMenuButtonClickOriginAction;
    //Hide loading window when start meeting without login.
    BOOL                _hideLoadingWindow;
    //Disable ZOOM original actions of clicking button Breakout Rooms.
    BOOL                _disableBreakoutRoomsButtonClickOriginAction;
    //Hide meeting info button on video UI.
    BOOL                _hideMeetingInfoButtonOnVideo;
    //hide invited button on participants window.
    BOOL                _hideInvitButtonOnHCWindow;
    //Disable ZOOM original actions of clicking toolbar Leave button.
    BOOL                _disableToolbarLeaveButtonClickOriginAction;
    //Disable ZOOM original actions of clicking toolbar CloseCaption button.
    BOOL                _disableToolbarCloseCaptionButtonClickOriginAction;
    //hide invited link on meeting info window.
    BOOL                _hideInviteLinkOnMeetingUI;
}
@property(nonatomic, assign)CGDirectDisplayID displayAppID;
@property(nonatomic, assign)CGDirectDisplayID monitorID;
@property(nonatomic, assign)NSPoint floatVideoPoint;
@property(nonatomic, assign)NSPoint mainVideoPoint;
@property(nonatomic, assign)BOOL shareToolBarVisible;
@property(nonatomic, assign)BOOL jbhWindowVisible;
@property(nonatomic, assign)BOOL enableMuteOnEntry;
@property(nonatomic, assign)BOOL isDirectShareDesktop;
@property(nonatomic, assign)BOOL enableChime;
@property(nonatomic, assign)BOOL disablePopupWrongPasswordWindow;
@property(nonatomic, assign)BOOL autoAdjustSpeakerVolumeWhenJoinAudio;
@property(nonatomic, assign)BOOL autoAdjustMicVolumeWhenJoinAudio;
@property(nonatomic, assign)BOOL disableEndOtherMeetingAlert;
@property(nonatomic, assign)BOOL disableInputPasswordWindow;
@property(nonatomic, assign)BOOL disableDoubleClickToFullScreen;
@property(nonatomic, assign)BOOL hideThumbnailVideoWindow;
@property(nonatomic, retain)NSString* securityAppName;
@property(nonatomic, assign)BOOL disableRenameInMeeting;
@property(nonatomic, assign)BOOL disableShareButtonClickOriginAction;
@property(nonatomic, assign)BOOL disableToolbarInviteButtonClickOriginAction;
@property(nonatomic, assign)BOOL needPrefillWebinarJoinInfo;
@property(nonatomic, assign)BOOL hideRegisterWebinarInfoWindow;
@property(nonatomic, assign)BOOL disableParticipantButtonClickOriginAction;
@property(nonatomic, assign)BOOL hideTelephoneInAudiowWindow;
@property(nonatomic, assign)BOOL hideCallMeInAudioWindow;
@property(nonatomic, assign)BOOL forceDisableMultiShare;
@property(nonatomic, assign)BOOL disableCustomLiveStreamAction;
@property(nonatomic, assign)BOOL disableFreeUserOriginAction;
@property(nonatomic, assign)BOOL disableFreeMeetingRemainTimeNotify;
@property(nonatomic, assign)BOOL hideInviteInMeetingH323CallInTab;
@property(nonatomic, assign)BOOL hideInviteInMeetingH323CallOutTab;
@property(nonatomic, assign)BOOL hideMeetingStaticBadNetWorkWaring;
@property(nonatomic, assign)BOOL hideMeetingStaticSystemBusyWaring;
@property(nonatomic, assign)BOOL hideSwitchCameraButton;
@property(nonatomic, assign)BOOL disableOpenRecordFileWhenMeetingEnd;
@property(nonatomic, assign)BOOL hideShowKeypadButton;
@property(nonatomic, assign)BOOL hideCopyURLButtonWhenInviteOthers;
@property(nonatomic, assign)BOOL hideCopyInvitationButtonWhenInviteOthers;
@property(nonatomic, assign)BOOL hideChatItemInMeeting;
@property(nonatomic, assign)BOOL hideRemoteControlItemOnMoreMenu;
@property(nonatomic, assign)BOOL hideChooseSaveRecordingFilePathWindow;
@property(nonatomic, assign)BOOL disableAudioButtonClickOriginAction;
@property(nonatomic, assign)BOOL disableAudioSettingMenuButtonClickOriginAction;
@property(nonatomic, assign)BOOL hideLoadingWindow;
@property(nonatomic, assign)BOOL disableBreakoutRoomsButtonClickOriginAction;
@property(nonatomic, assign)BOOL hideMeetingInfoButtonOnVideo;
@property(nonatomic, assign)BOOL hideInvitButtonOnHCWindow;
@property(nonatomic, assign)BOOL disableToolbarLeaveButtonClickOriginAction;
@property(nonatomic, assign)BOOL disableToolbarCloseCaptionButtonClickOriginAction;
@property(nonatomic, assign)BOOL hideInviteLinkOnMeetingUI;
- (ZoomSDKError)prefillWebinarUserName:(NSString*)userName Email:(NSString*)email;
- (ZoomSDKError)hideSDKButtons:(BOOL)hide ButtonType:(SDKButton)button;

/**
 @brief Modify the DSCP of audio and video.
 @param videoDSCP Video values in the meeting.
 @param audioDSCP Audio values in the meeting.
 @note It is necessary to input both values of the videoDSCP and audioDSCP if you want to modify.
 */
- (ZoomSDKError)modifyVideoDSCP:(int)videoDSCP AudioDSCP:(int)audioDSCP;

/**
 @brief Reset all properties in this class.
 */
- (void)reset;

/**
 @brief Disable confidential watermark.
 @param disable Set it to Yes to disable use confidential watermark, otherwise not.
 @return If return YES means the confidential watermark is disabled, otherwise not.
 */
-(BOOL)disableConfidentialWatermark:(BOOL)disable;
@end


