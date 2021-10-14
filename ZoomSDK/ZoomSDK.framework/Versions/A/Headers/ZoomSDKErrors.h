//
//  ZoomSDKErrors.h
//  ZoomSDK
//
//  Created by TOTTI on 7/18/16.
//  Copyright (c) 2016 Zoom Video Communications,Inc. All rights reserved.
//
#pragma once

/** 
 @brief An enumeration of user types. 
 */
typedef enum {
    //User logs in with working email.
    ZoomSDKUserType_ZoomUser    = 100,
    //Single-sign-on user.
    ZoomSDKUserType_SSOUser     = 101,
    //Users who are not logged in
    ZoomSDKUserType_WithoutLogin = 102,
}ZoomSDKUserType;

typedef enum {
	//API user.
    SDKUserType_APIUser,
	//User logs in with email.
    SDKUserType_EmailLogin,
	//User logs in with Facebook account.
    SDKUserType_FaceBook,
	//User logs in with Google authentication.
    SDKUserType_GoogleOAuth,
	//User logs in with SSO token.
    SDKUserType_SSO,
	//Unknown user type.
    SDKUserType_Unknown,
}SDKUserType;
/**
 @brief An enumeration of commands for leaving meeting.
 */
typedef enum {
    //Command of leaving meeting.
    LeaveMeetingCmd_Leave,
    //Command of ending Meeting.
    LeaveMeetingCmd_End,
}LeaveMeetingCmd;

/**
 @brief An enumeration of all the commands in the meeting.
 */
typedef enum{
    //Mute the video.
    ActionMeetingCmd_MuteVideo,
	//Unmute the video.
    ActionMeetingCmd_UnMuteVideo,
    //Mute the audio.
    ActionMeetingCmd_MuteAudio,
	//Unmute the audio.
    ActionMeetingCmd_UnMuteAudio,
    //Enable the feature that user can unmute himself when muted.
    ActionMeetingCmd_EnableUnmuteBySelf,
	//Disable the feature that user can not unmute himself when muted.
    ActionMeetingCmd_DisableUnmuteBySelf,
    //Mute all participants in the meeting, available only for the host/co-host. 
    ActionMeetingCmd_MuteAll,
    //Unmute all participants in the meeting, available only for the host/co-host. 
    ActionMeetingCmd_UnmuteAll,
    //Lock the meeting, available only for the host/co-host. Once locked, the new participants can no longer join the meeting/co-host.
    ActionMeetingCmd_LockMeeting,
	//Unlock the meeting, available only for the host/co-host. 
    ActionMeetingCmd_UnLockMeeting,
    //Put all participants' hands down, available only for the host/co-host.     
    ActionMeetingCmd_LowerAllHands,
    //Adjust the display size fit to the window.
    ActionMeetingCmd_ShareFitWindowMode,
	//Share in original size.
    ActionMeetingCmd_ShareOriginSizeMode,
    //Pause sharing.
    ActionMeetingCmd_PauseShare,
    //Resume sharing.
    ActionMeetingCmd_ResumeShare,
    //Join meeting by VoIP.
    ActionMeetingCmd_JoinVoip,
    //Disconnect VoIP from meeting.
    ActionMeetingCmd_LeaveVoip,
    
}ActionMeetingCmd;

/**
 @brief Get default information of meeting. 
 */
typedef enum {
	//The topic of meeting.
    MeetingPropertyCmd_Topic,
	//The template of email invitation.
    MeetingPropertyCmd_InviteEmailTemplate,
	//The title of email invitation.
    MeetingPropertyCmd_InviteEmailTitle,
	//The invitation URL.
    MeetingPropertyCmd_JoinMeetingUrl,
	//The default path to save the recording files.
    MeetingPropertyCmd_DefaultRecordPath,
	//The meeting number.
    MeetingPropertyCmd_MeetingNumber,
	//The tag of host.
    MeetingPropertyCmd_HostTag, 
	//Meeting ID.
    MeetingPropertyCmd_MeetingID,
    //Meeting password.
    MeetingPropertyCmd_MeetingPassword
}MeetingPropertyCmd;

/**
 @brief Type of annotation tools.
 */
typedef enum{
	//Switch to mouse cursor. For initialization.
    AnnotationToolType_None,
	//Pen
    AnnotationToolType_Pen,
	//Highlighter.
    AnnotationToolType_HighLighter,
	//A straight line changes automatically in pace with the mouse cursor.
    AnnotationToolType_AutoLine,
	//A rectangle changes automatically in pace with the mouse cursor.
    AnnotationToolType_AutoRectangle,
	//An ellipse changes automatically in pace with the mouse cursor.
    AnnotationToolType_AutoEllipse,
	//An arrow changes automatically in pace with the mouse cursor.
    AnnotationToolType_AutoArrow,
	//A filled rectangle.
    AnnotationToolType_AutoRectangleFill,
	//A filled ellipse.
    AnnotationToolType_AutoEllipseFill,
	//Laser pointer.
    AnnotationToolType_SpotLight,
	//An arrow.
    AnnotationToolType_Arrow,
	//An eraser.
    AnnotationToolType_ERASER,
}AnnotationToolType;

/**
 @brief Types of clearing annotations.
 */
typedef enum{
	//Clear all annotations.
    AnnotationClearType_All,
	//Clear only your own annotations.
    AnnotationClearType_Self,
	//Clear only others' annotations.
    AnnotationClearType_Other,
}AnnotationClearType;

/**
 @brief In-meeting UI components.
 */
typedef enum{
	//Meeting window.
    MeetingComponent_MainWindow,
	//Audio.
    MeetingComponent_Audio,
	//Chat.
    MeetingComponent_Chat,
	//Participants.
    MeetingComponent_Participants,
	//Main toolbar at the bottom of meeting window.
    MeetingComponent_MainToolBar,
	//Main toolbar for sharing on the primary view.
    MeetingComponent_MainShareToolBar,
	//Toolbar for sharing on the subview.
    MeetingComponent_AuxShareToolBar,
	//Setting components.
    MeetingComponent_Setting,
	//Window for sharing options. 
    MeetingComponent_ShareOptionWindow,
	//Thumbnail video layout.
    MeetingComponent_ThumbnailVideo,
	//Window for invite other into meeting.
    MeetingComponent_InviteWindow,
	//Window for sharing select.
    MeetingComponent_ShareSelectWindow,
}MeetingComponent;

/**
 * @brief Enumeration of Meeting settings.
 */
typedef enum{
	//Dual screen mode.
    MeetingSettingCmd_DualScreenMode,
	//Enter full screen mode when user joins the meeting.
    MeetingSettingCmd_AutoFullScreenWhenJoinMeeting,
	//Enable to play chime when user joins or exits the meeting.
    MeetingSettingCmd_EnablePlayChimeWhenEnterOrExit,
}MeetingSettingCmd;

/**
 * @brief Enumeration of common errors of SDK.
 */
typedef enum{
	//Success.
    ZoomSDKError_Success,
	//Failed.
    ZoomSDKError_Failed,
	//SDK is not initialize.
    ZoomSDKError_Uninit,
	//Service is failed.
    ZoomSDKError_ServiceFailed,
	//Incorrect usage of the feature. 
    ZoomSDKError_WrongUsage,
	//Wrong parameter.
    ZoomSDKError_InvalidPrameter,
	//No permission.
    ZoomSDKError_NoPermission,
	//There is no recording in process.
    ZoomSDKError_NoRecordingInProgress,
    //Api calls are too frequent.
    ZoomSDKError_TooFrequentCall,
    //unsupported feature
    ZoomSDKError_UnSupportedFeature,
    //unsupport email login
    ZoomSDKError_EmailLoginIsDisabled,
    //Module load fail.
    ZoomSDKError_ModuleLoadFail,
    //No video data.
    ZoomSDKError_NoVideoData,
    //No audio data.
    ZoomSDKError_NoAudioData,
    //No share data.
    ZoomSDKError_NoShareData,
    //Not found video device.
    ZoomSDKError_NoVideoDeviceFound,
    //Device error.
    ZoomSDKError_DeviceError,
    //Not in meeting.
    ZoomSDKError_NotInMeeting,
    //Init device.
    ZoomSDKError_initDevice,
    //Can't change virtual device.
    ZoomSDKError_CanNotChangeVirtualDevice,
    //Preprocess rawdata error.
    ZoomSDKError_PreprocessRawdataError,
    //No license.
    ZoomSDKError_NoLicense,
    //Malloc failed.
    ZoomSDKError_Malloc_Failed,
    //ShareCannotSubscribeMyself.
    ZoomSDKError_ShareCannotSubscribeMyself,
    //Need user confirm record disclaimer.
    ZoomSDKError_NeedUserConfirmRecordDisclaimer,
    //Unknown error.
    ZoomSDKError_UnKnow,
}ZoomSDKError;

/**
 * @brief Enumeration of SDK authentication results.
 */
typedef enum {
    //Authentication is successful
    ZoomSDKAuthError_Success = 0,
    //Key or secret is wrong
    ZoomSDKAuthError_KeyOrSecretWrong,
    //Client account does not support
    ZoomSDKAuthError_AccountNotSupport,
    //Client account does not enable SDK
    ZoomSDKAuthError_AccountNotEnableSDK,
    //Auth timeout
    ZoomSDKAuthError_Timeout,
    //Network issue
    ZoomSDKAuthError_NetworkIssue,
    //Client incompatible
    ZoomSDKAuthError_Client_Incompatible,
    //The jwt token to authenticate is wrong.
    ZoomSDKAuthError_JwtTokenWrong,
    //The key or secret to authenticate is empty.
    ZoomSDKAuthError_KeyOrSecretEmpty,
    //Unknown error
    ZoomSDKAuthError_Unknown = 100,
}ZoomSDKAuthError;

/**
 * @brief Enumeration of SDK pre-meeting errors.
 */
typedef enum {
    //Calls SDK successfully.
    ZoomSDKPremeetingError_Success,
    //Calls SDK failed.
    ZoomSDKPremeetingError_Failed,
    //Timeout.
    ZoomSDKPremeetingError_TimeOut,
    //Unknown errors.
    ZoomSDKPremeetingError_Unknown = 100,
    
}ZoomSDKPremeetingError;

/**
 * @brief Enumeration of errors to start/join meeting.
 */
typedef enum {
    //Start/Join meeting successfully.
    ZoomSDKMeetingError_Success                         = 0,
    //Network issue, please check the network connection.
    ZoomSDKMeetingError_NetworkUnavailable              = 1,
    //Failed to reconnect the meeting.
    ZoomSDKMeetingError_ReconnectFailed                 = 2,
    //MMR issue, please check MMR configuration.
    ZoomSDKMeetingError_MMRError                        = 3,
    //The meeting password is incorrect.
    ZoomSDKMeetingError_PasswordError                   = 4,
    //Failed to create video and audio data connection with MMR.
    ZoomSDKMeetingError_SessionError                    = 5,
    //Meeting is over.
    ZoomSDKMeetingError_MeetingOver                     = 6,
    //Meeting is not started.
    ZoomSDKMeetingError_MeetingNotStart                 = 7,
    //The meeting does not exist.
    ZoomSDKMeetingError_MeetingNotExist                 = 8,
    //The amount of attendees reaches the upper limit.
    ZoomSDKMeetingError_UserFull                        = 9,
    //The ZOOM SDK version is incompatible.
    ZoomSDKMeetingError_ClientIncompatible              = 10,
    //No MMR is valid.
    ZoomSDKMeetingError_NoMMR                           = 11,
    //The meeting is locked by the host.
    ZoomSDKMeetingError_MeetingLocked                   = 12,
    //The meeting is restricted.
    ZoomSDKMeetingError_MeetingRestricted               = 13,
    //The meeting is restricted to join before host.
    ZoomSDKMeetingError_MeetingJBHRestricted            = 14,
    //Failed to request the web server.
    ZoomSDKMeetingError_EmitWebRequestFailed            = 15,
    //Failed to start meeting with expired token.
    ZoomSDKMeetingError_StartTokenExpired               = 16,
    //The user's video does not work.
    ZoomSDKMeetingError_VideoSessionError               = 17,
	//The user's audio cannot auto-start.
    ZoomSDKMeetingError_AudioAutoStartError             = 18,
	//The amount of webinar attendees reaches the upper limit.
    ZoomSDKMeetingError_RegisterWebinarFull             = 19,
    //User needs to register a webinar account if he wants to start a webinar.
    ZoomSDKMeetingError_RegisterWebinarHostRegister     = 20,
	//User needs to register an account if he wants to join the webinar by the link.
    ZoomSDKMeetingError_RegisterWebinarPanelistRegister = 21,
	//The host has denied your webinar registration.
    ZoomSDKMeetingError_RegisterWebinarDeniedEmail      = 22,
	//Sign in with the specified account to join webinar.
    ZoomSDKMeetingError_RegisterWebinarEnforceLogin     = 23,
    //The certificate of ZC has been changed.
    ZoomSDKMeetingError_ZCCertificateChanged            = 24,
    //Vanity conference ID does not exist.
    ZoomSDKMeetingError_vanityNotExist                  = 27,
    //Join webinar with the same email.
    ZoomSDKMeetingError_joinWebinarWithSameEmail        = 28,
    //Meeting settings is not allowed to start a meeting.
    ZoomSDKMeetingError_disallowHostMeeting             = 29,
    //Failed to write configure file.
    ZoomSDKMeetingError_ConfigFileWriteFailed           = 50,
    //Forbidden to join the internal meeting.
    ZoomSDKMeetingError_forbidToJoinInternalMeeting     = 60,
	// User is removed from meeting by host.
    ZoomSDKMeetingError_RemovedByHost                   = 61,
    //Host disallow outside user join.
    ZoomSDKMeetingError_HostDisallowOutsideUserJoin     = 62,
    //Unknown error.
    ZoomSDKMeetingError_Unknown                         = 100,
	//No error.
    ZoomSDKMeetingError_None                            = 101,
}ZoomSDKMeetingError;



/**
 * @brief Enumeration of ZOOM SDK login status.
 */
typedef enum {
	//User does not login.
    ZoomSDKLoginStatus_Idle = 0,
	//Login successfully.
    ZoomSDKLoginStatus_Success = 1,
	//Login failed.
    ZoomSDKLoginStatus_Failed = 2,
	//Login in progress.
    ZoomSDKLoginStatus_Processing = 3
}ZoomSDKLoginStatus;


/**
 * @brief Enumeration of meeting status.
 */
typedef enum {
    //No meeting is running.
    ZoomSDKMeetingStatus_Idle             = 0,
    //Connecting to the meeting server.
    ZoomSDKMeetingStatus_Connecting       = 1,
    //Waiting for the host to start the meeting.
    ZoomSDKMeetingStatus_WaitingForHost   = 2,
    //Meeting is ready, in meeting status.
    ZoomSDKMeetingStatus_InMeeting        = 3,
    //Disconnect the meeting server, leave meeting status.
    ZoomSDKMeetingStatus_Disconnecting    = 4,
    //Reconnecting meeting server status.
    ZoomSDKMeetingStatus_Reconnecting     = 5,
    //Join/Start meeting failed.
    ZoomSDKMeetingStatus_Failed           = 6,
    //Meeting ends.
    ZoomSDKMeetingStatus_Ended            = 7,
    //Audio is connected.
    ZoomSDKMeetingStatus_AudioReady       = 8,
    //There is another ongoing meeting on the server. 
    ZoomSDKMeetingStatus_OtherMeetingInProgress = 9,
	//Participants who join the meeting before the start are in the waiting room.
    ZoomSDKMeetingStatus_InWaitingRoom      = 10,
    //End to end meeting. Available for Huawei
    ZoomSDKMeetingStatus_WaitExternalSessionKey =11,
    //Promote the attendees to panelist in webinar.
    ZoomSDKMeetingStatus_Webinar_Promote = 12,
    //Demote the attendees from the panelist.
    ZoomSDKMeetingStatus_Webinar_Depromote = 13,
    //Join breakout room.
    ZoomSDKMeetingStatus_Join_Breakout_Room = 14,
    //Leave breakout room.
    ZoomSDKMeetingStatus_Leave_Breakout_Room = 15,
    
}ZoomSDKMeetingStatus;

/**
 * @brief Enumeration of sharing status.
 */
typedef enum{
	//For initialization.
    ZoomSDKShareStatus_None,
	//The current user begins the share.
    ZoomSDKShareStatus_SelfBegin,
	//The current user ends the share.
    ZoomSDKShareStatus_SelfEnd,
	//Other user begins the share.
    ZoomSDKShareStatus_OtherBegin,
	//Other user ends the share.
    ZoomSDKShareStatus_OtherEnd,
	//The current user is viewing the share by others.
    ZoomSDKShareStatus_ViewOther,
	//The share is paused.
    ZoomSDKShareStatus_Pause,
	//The share is resumed.
    ZoomSDKShareStatus_Resume,
	//The sharing content changes.
    ZoomSDKShareStatus_ContentTypeChange,
	//The current user begins to share the sounds of computer audio.
    ZoomSDKShareStatus_SelfStartAudioShare,
	//The current user stops sharing the sounds of computer audio.
    ZoomSDKShareStatus_SelfStopAudioShare,
	//Other user begins to share the sounds of computer audio.
    ZoomSDKShareStatus_OtherStartAudioShare,
	//Other user stops sharing the sounds of computer audio.
    ZoomSDKShareStatus_OtherStopAudioShare,
    //The share is disconnected.
    ZoomSDKShareStatus_Disconnected,
}ZoomSDKShareStatus;

/**
 * @brief Enumeration of Audio status.
 */
typedef enum{
	//For initialization.
    ZoomSDKAudioStatus_None = 0,
	//The audio is muted.
    ZoomSDKAudioStatus_Muted = 1,
	//The audio is unmuted.
    ZoomSDKAudioStatus_UnMuted = 2,
	//The audio is muted by the host.
    ZoomSDKAudioStatus_MutedByHost = 3,
	//The audio is unmuted by the host.
    ZoomSDKAudioStatus_UnMutedByHost = 4,
	//Host mutes all participants.
    ZoomSDKAudioStatus_MutedAllByHost = 5,
	//Host unmutes all participants.
    ZoomSDKAudioStatus_UnMutedAllByHost = 6,
}ZoomSDKAudioStatus;

typedef enum{
    ZoomSDKVideoStatus_Off,
    ZoomSDKVideoStatus_On,
    ZoomSDKVideoStatus_MutedByHost,
    ZoomSDKVideoStatus_None,
}ZoomSDKVideoStatus;


typedef enum{
	//No audio.
    ZoomSDKAudioType_None = 0,
	//VoIP.
    ZoomSDKAudioType_Voip = 1,
	//Phone.
    ZoomSDKAudioType_Phone = 2,
	//Unknown audio type.
    ZoomSDKAudioType_Unknow = 3,
}ZoomSDKAudioType;
/**
 * @brief Enumeration of status of remote control.
 */
typedef enum{
	//For initialization.
    ZoomSDKRemoteControlStatus_None,
    //Viewer can request to control the sharer remotely.
    ZoomSDKRemoteControlStatus_CanRequestFromWho,
    //Sharer receives the request from viewer.
    ZoomSDKRemoteControlStatus_RequestFromWho,
    //Sharer declines your request to be remote controlled.
    ZoomSDKRemoteControlStatus_DeclineByWho,
    //Sharer is remote controlled by viewer
    ZoomSDKRemoteControlStatus_RemoteControlledByWho,
    //Notify user that controller of the shared content changes.
    ZoomSDKRemoteControlStatus_StartRemoteControllWho,
	//Remote control ends.
    ZoomSDKRemoteControlStatus_EndRemoteControllWho,
    //Viewer gets the privilege of remote control.
    ZoomSDKRemoteControlStatus_HasPrivilegeFromWho,
    //Viewer loses the privilege of remote control.
    ZoomSDKRemoteControlStatus_LostPrivilegeFromWho,
}ZoomSDKRemoteControlStatus;

/**
 * @brief Enumeration of Recording status.
 */
typedef enum{
	//For initialization.
    ZoomSDKRecordingStatus_None,
	//Start recording.
    ZoomSDKRecordingStatus_Start,
	//Stop recording.
    ZoomSDKRecordingStatus_Stop,
	//The space of storage is full.
    ZoomSDKRecordingStatus_DiskFull,
    //Pause recording.
    ZoomSDKRecordingStatus_Pause,
    //Connecting, only for cloud recording.
    ZoomSDKRecordingStatus_Connecting,
}ZoomSDKRecordingStatus;

/**
 * @brief Enumeration of connection quality.
 */
typedef enum{
	//Unknown connection status.
    ZoomSDKConnectionQuality_Unknow,
	//The connection quality is very poor.
    ZoomSDKConnectionQuality_VeryBad,
	//The connection quality is poor. 
    ZoomSDKConnectionQuality_Bad,
	//The connection quality is not good.
    ZoomSDKConnectionQuality_NotGood,
	//The connection quality is normal.
    ZoomSDKConnectionQuality_Normal,
	//The connection quality is good.
    ZoomSDKConnectionQuality_Good,
	//The connection quality is excellent.
    ZoomSDKConnectionQuality_Excellent,
}ZoomSDKConnectionQuality;

/**
 * @brief Enumeration of H.323 device outgoing call status.
 * @note The order of enumeration members has been changed.H323CalloutStatus_Unknown has been moved.
 */
typedef enum
{
	//Call out successfully.
    H323CalloutStatus_Success,
	//In process of ringing.
    H323CalloutStatus_Ring,
	//Timeout.
    H323CalloutStatus_Timeout,
	//Failed to call out.
    H323CalloutStatus_Failed,
    //Unknown status.
    H323CalloutStatus_Unknown,
    //Busy
    H323CalloutStatus_Busy,
    //Decline
    H323CalloutStatus_Decline,
}H323CalloutStatus;

/**
 * @brief Enumeration of H.323 device pairing Status.
 */
typedef enum
{
	//Unknown status.
    H323PairingResult_Unknown,
	//Pairing successfully.
    H323PairingResult_Success,
	//Pairing meeting does not exist.
    H323PairingResult_Meeting_Not_Exist,
	//Pairing code does not exist.
    H323PairingResult_Paringcode_Not_Exist,
	//No pairing privilege.
    H323PairingResult_No_Privilege,
	//Other errors.
    H323PairingResult_Other_Error,
}H323PairingResult;

/**
 * @brief Enumeration of H.323 device types.
 */
typedef enum
{
	//Unknown types.
    H323DeviceType_Unknown,
	//H.323 device
    H323DeviceType_H323,
	//SIP
    H323DeviceType_SIP,
}H323DeviceType;

/**
 * @brief Enumeration of screen types for multi-sharing.
 */
typedef enum
{
  //Primary displayer.
  ScreenType_First,
  //Secondary displayer.
  ScreenType_Second,
}ScreenType;

/**
 * @brief Enumeration of video UI types in the meeting.
 */
typedef enum
{
   //No video in the meeting.
   MeetingUIType_None,
   //Video wall mode..
   MeetingUIType_VideoWall,
   //Display the video of active user. 
   MeetingUIType_ActiveRender,
}MeetingUIType;

/**
 * @brief Join meeting with required information.
 */
typedef enum
{
	//For initialization.
    JoinMeetingReqInfoType_None,
	//Join meeting with password.
    JoinMeetingReqInfoType_Password,
	//The password for join meeting is incorrect.
    JoinMeetingReqInfoType_Password_Wrong,
}JoinMeetingReqInfoType;

/**
 * @brief Enumeration of meeting types
 */
typedef enum
{
	//There is no meeting.
    MeetingType_None,
	//Normal meeting.
    MeetingType_Normal,
	//Breakout meeting.
    MeetingType_BreakoutRoom,
	//Webinar.
    MeetingType_Webinar,
}MeetingType;

/**
 * @brief Enumeration of user roles.
 */
typedef enum
{
	//For initialization.
    UserRole_None,
	//Host.
    UserRole_Host,
	//Co-host.
    UserRole_CoHost,
	//Attendee or webinar attendee.
    UserRole_Attendee,
	//Panelist.
    UserRole_Panelist,
	//Moderator of breakout room.
    UserRole_BreakoutRoom_Moderator,
}UserRole;

/**
 * @brief Enumeration of phone call status
 */
typedef enum
{
	//No status.
    PhoneStatus_None,
	//In process of calling out.
    PhoneStatus_Calling,
	//In process of ringing.
    PhoneStatus_Ringing,
	//The call is accepted.
    PhoneStatus_Accepted,
	//Call successful.
    PhoneStatus_Success,
	//Call failed.
    PhoneStatus_Failed,
	//In process of canceling the response to the previous state.
    PhoneStatus_Canceling,
	//Cancel successfully.
    PhoneStatus_Canceled,
	//Failed to cancel.
    PhoneStatus_Cancel_Failed,
	//Timeout.
    PhoneStatus_Timeout,
}PhoneStatus;

/**
 * @brief Enumeration of reasons of phone calls failed
 */
typedef enum
{
	//For initialization.
    PhoneFailedReason_None,
	//The telephone service is busy.
    PhoneFailedReason_Busy,
	//The telephone is out of service.
    PhoneFailedReason_Not_Available,
	//The phone is hung up.
    PhoneFailedReason_User_Hangup,
	//Other reasons.
    PhoneFailedReason_Other_Fail,
	//The call is not answered.
    PhoneFailedReason_No_Answer,
	//Disable the function of international callout before the host joins the meeting.
    PhoneFailedReason_Block_No_Host,
	//The call-out is blocked by the system due to the high cost.
    PhoneFailedReason_Block_High_Rate,
	//All the invitees invited by the call should press the button one(1) to join the meeting. In case that many invitees do not press the button that leads to time out, the call invitation for this meeting shall be banned.
    PhoneFailedReason_Block_Too_Frequent,
}PhoneFailedReason;

/**
 * @brief Enumeration of types of shared content.
 */
typedef enum
{
	//Type unknown.
    ZoomSDKShareContentType_UNKNOWN,
	//Type of sharing the application.
    ZoomSDKShareContentType_AS,
	//Type of sharing the desktop.
    ZoomSDKShareContentType_DS,
	//Type of sharing the white-board.
    ZoomSDKShareContentType_WB,
	//Type of sharing data from the device connected WIFI.
    ZoomSDKShareContentType_AIRHOST,
	//Type of sharing the camera.
    ZoomSDKShareContentType_CAMERA,
	//Type of sharing the data.
    ZoomSDKShareContentType_DATA,
	//Wired device, connect Mac and iPhone.
    ZoomSDKShareContentType_WIRED_DEVICE,
	//Share a portion of screen in the frame.
    ZoomSDKShareContentType_FRAME,
	//Share a document.
    ZoomSDKShareContentType_DOCUMENT,
	//Share only the audio sound of computer.
    ZoomSDKShareContentType_COMPUTER_AUDIO
}ZoomSDKShareContentType;

/**
 * @brief Enumeration of the number types for calling to join the audio into a meeting.
 */
typedef enum
{
	//For initialization.
    CallInNumberType_None,
	//Paid.
    CallInNumberType_Toll,
	//Free.
    CallInNumberType_TollFree,
}CallInNumberType;

/**
 * @brief Enumeration of in-meeting buttons on the toolbar.
 */
typedef enum
{
	//Audio button: manage in-meeting audio of the current user.
    AudioButton,
	//Video button: manage in-meeting video of the current user.
    VideoButton,
	//Participant button: manage or check the participants.
    ParticipantButton,
	//Share button: share screen or application, etc.
    FitBarNewShareButton,
	//Remote control button when sharing or viewing the share. 
    FitBarRemoteControlButton,
	//Pause the share.
    FitBarPauseShareButton,
	//Annotation button.
    FitBarAnnotateButton,
	//Question and answer(QA) button. Available only in webinar.
    QAButton,
	//Broadcast the webinar so user can join the webinar.
    FitBarBroadcastButton,
	//Poll button: questionnaire.
    PollingButton,
	//More: other functions in the menu.
    FitBarMoreButton,
	//Exit full screen.
    MainExitFullScreenButton,
	//Button for getting host.
    ClaimHostButton,
	//Upgarde button of free meeting remain time tooltip view.
    UpgradeButtonInFreeMeetingRemainTimeTooltip,
    //Swap share and video button: swap to display share or video.
    SwapShareContentAndVideoButton,
    //Chat button: manage in-meeting chat of the current user.
    ChatButton,
    //Reaction Button on tool bar.
    ToolBarReactionsButton,
    //Share button on tool bar.
    ToolBarShareButton,
    //Recording button.
    RecordButton,
}SDKButton;

/**
 * @brief Enumeration of security session types.
 */
typedef enum
{
	//Unknown component
    SecuritySessionComponet_Unknown,
	//Chat.
    SecuritySessionComponet_Chat,
	//File Transfer.
    SecuritySessionComponet_FT,
	//Audio.
    SecuritySessionComponet_Audio,
	//Video.
    SecuritySessionComponet_Video,
	//Share application.
    SecuritySessionComponet_AS,
}SecuritySessionComponet;

/**
 * @brief Enumeration of warning types.
 */
typedef enum
{
	//No warnings.
    StatisticWarningType_None,
	//The quality of the network connection is very poor.
    StatisticWarningType_NetworkBad,
	//The CPU is highly occupied.
    StatisticWarningType_CPUHigh,
	//The system is busy.
    StatisticWarningType_SystemBusy,
}StatisticWarningType;

/**
 * @brief Enumeration of component types.
 */
typedef enum{
	//For initialization.
    ConnectionComponent_None,
	//Share.
    ConnectionComponent_Share,
	//Video.
    ConnectionComponent_Video,
	//Audio.
    ConnectionComponent_Audio,
}ConnectionComponent;

/**
 * @brief Enumeration of ending meeting errors.
 */
typedef enum{
	//For initialization.
    EndMeetingReason_None = 0,
	//The user is kicked off by the host and leaves the meeting.
    EndMeetingReason_KickByHost = 1,
	//Host ends the meeting.
    EndMeetingReason_EndByHost = 2,
	//Join the meeting before host (JBH) timeout.
    EndMeetingReason_JBHTimeOut = 3,
	//Meeting is ended for there is no attendee joins it.
    EndMeetingReason_NoAttendee = 4,
	//Host ends the meeting for he will start another meeting.
    EndMeetingReason_HostStartAnotherMeeting = 5,
	//Meeting is ended for the free meeting timeout.
    EndMeetingReason_FreeMeetingTimeOut = 6,
	//Meeting is ended for network broken.
    EndMeetingReason_NetworkBroken = 7,
}EndMeetingReason;

/**
 * @brief Enumeration of H.323/SIP encryption types. Available only for Huawei.
 */
typedef enum
{
	//Meeting room system is not encrypted.
    EncryptType_NO,
	//Meeting room system is encrypted.
    EncryptType_YES,
	//Meeting room system is encrypted automatically.
    EncryptType_Auto
}EncryptType;

/**
 * @brief Enumeration of connection types. 
 */
typedef enum{
	//Unknown connection types.
    SettingConnectionType_Unknow,
	//Peer to peer.
    SettingConnectionType_P2P,
	//Connect to the cloud.
    SettingConnectionType_Cloud,
}SettingConnectionType;

/**
 * @brief Enumeration of network types. 
 */
typedef enum{
	//Unknown network type.
    SettingNetworkType_Unknow,
	//Wired LAN
    SettingNetworkType_Wired,
	//WIFI
    SettingNetworkType_WiFi,
	//PPP
    SettingNetworkType_PPP,
	//3G
    SettingNetworkType_3G,
	//Other network types.
    SettingNetworkType_Other,
}SettingNetworkType;

/**
 * @brief Enumeration of video render element types.
 */
typedef enum{
	//For initialization.
    VideoRenderElementType_None,
	//Preview the video of user himself.
    VideoRenderElementType_Preview,
	//Render the video of active speaker.
    VideoRenderElementType_Active,
	//Render normal video. 
    VideoRenderElementType_Normal,
}VideoRenderElementType;

/**
 * @brief Enumeration of video render data types.
 */
typedef enum{
	//For initialization.
    VideoRenderDataType_None,
	//Video data.
    VideoRenderDataType_Video,
	//Avatar data.
    VideoRenderDataType_Avatar,
}VideoRenderDataType;

/**
 * @brief Enumeration of sharing modes.
 */
typedef enum{
	//The mode of shared content adaptive pattern in the view.
    ViewShareMode_FullFill,
	//Letterbox. It is the practice of transferring film shot in a widescreen aspect ratio to standard-width video formats while preserving the film's original aspect ratio. 
    ViewShareMode_LetterBox,
}ViewShareMode;

/**
 * @brief Enumeration of annotation status.
 */
typedef enum{
	//Ready to annotate.
    AnnotationStatus_Ready,
	//Annotation is closed.
    AnnotationStatus_Close,
	//For initialization.
    AnnotationStatus_None,
}AnnotationStatus;

/**
 * @brief Enumeration of live stream status.
 */
typedef enum{
	//Only for initialization.
    LiveStreamStatus_None,
	//Live stream in process.
    LiveStreamStatus_InProgress,
	//Be connecting.
    LiveStreamStatus_Connecting,
	//Connect timeout.
    LiveStreamStatus_StartFailedTimeout,
	//Connect failed to the live streaming. 
    LiveStreamStatus_StartFailed,
	//End.
    LiveStreamStatus_Ended,
}LiveStreamStatus;


typedef enum{
    FreeMeetingNeedUpgradeType_NONE,
    FreeMeetingNeedUpgradeType_BY_ADMIN,
    FreeMeetingNeedUpgradeType_BY_GIFTURL,
}FreeMeetingNeedUpgradeType;

/**
 * @brief Enumeration of direct sharing status.
 */
typedef enum{
	//For initialization.
    DirectShareStatus_None = 0,
	//Waiting for enabling the direct sharing.
    DirectShareStatus_Connecting = 1,
	//In direct sharing mode.
    DirectShareStatus_InProgress = 2,
	//End the direct sharing.
    DirectShareStatus_Ended = 3,
	//Input the meeting ID/pairing code.
    DirectShareStatus_NeedMeetingIDOrSharingKey = 4,
	//The meeting ID or pairing code is wrong.
    DirectShareStatus_WrongMeetingIDOrSharingKey = 5,
	//Network issue. Reconnect later. 
    DirectShareStatus_NetworkError = 6,
    //Need input new paring code.
    DirectShareStatus_NeedInputNewPairingCode,
    //Prepared.
    DirectShareStatus_Prepared,
	//Unknown share status.
    DirectShareStatus_Unknow = 100,

}DirectShareStatus;

/**
 * @brief Enumeration of audio types when schedules a meeting.
 */
typedef enum{
	//Normal audio type.
    ScheduleMeetingAudioType_None = 0,
	//In telephone mode.
    ScheduleMeetingAudioType_Telephone = 1,  
	//In VoIP mode.
    ScheduleMeetingAudioType_Voip = 1<<1,  
	//Use telephone and VoIP.
    ScheduleMeetingAudioType_Both = 1<<2,  
	//Use the third party audio.
    ScheduleMeetingAudioType_3rd= 1<<3,  
}ScheduleMeetingAudioType;

/**
 * @brief Enumeration of meeting recording types.
 */
typedef enum{
	//For initialization.
    ScheduleMeetingRecordType_None = 0,
	//Local Recording
    ScheduleMeetingRecordType_Local = 1,
	//Cloud Recording
    ScheduleMeetingRecordType_Cloud = 1<<1,
}ScheduleMeetingRecordType;

/**
 * @brief Enumeration of types to register webinar.
 */
typedef enum
{
	//For initialization.
    WebinarRegisterType_None,
	//Register webinar with URL.
    WebinarRegisterType_URL,
	//Register webinar with email.
    WebinarRegisterType_Email,
}WebinarRegisterType;

/**
 * @brief Enumeration of microphone test types.
 */
typedef enum{
	//Normal status.
    testMic_Normal = 0,
	//Recording.
    testMic_Recording,
	//Stop recording.
    testMic_RecrodingStoped,
	//Playing.
    testMic_Playing,
}ZoomSDKTestMicStatus;

/**
 * @brief Enumeration of device status.
 */
typedef enum{
	//Unknown device.
    Device_Error_Unknow,
	//New device is detected by the system.
    New_Device_Found,
	//The device is not found.
    Device_Error_Found,
	//No device.
    No_Device,
	//No sound can be detected from the microphone.
    Audio_No_Input, 
	//The audio is muted. Press Command+Shift+A to unmute
    Audio_Error_Be_Muted, 
	//The device list is updated.
    Device_List_Update,
	//The audio is disconnected once detected echo.
    Audio_Disconnect_As_Detected_Echo,
}ZoomSDKDeviceStatus;

/**
 * @brief Enumerations of sharing types.
 */
typedef enum{
	//Anyone can share, but only one can share at a  moment, and only the host can start sharing when another user is sharing. The previous share will be ended once the host grabs the sharing.
    ShareSettingType_OnlyHostCanGrab = 0,
	//Only host can share.
    ShareSettingType_OnlyHostCanShare = 1,//Only host can start sharing when someone else is sharing.
	//Only one participant can share at a time. And anyone can start sharing when someone else is sharing.
    ShareSettingType_AnyoneCanGrab = 2,
	//Multi participant can share at a moment.
    ShareSettingType_MutiShare = 3,
    ShareSettingType_None = 4,
}ZoomSDKShareSettingType;

/**
 *@brief Enumerations of General setting about share
 */
typedef enum {
    //When user share screen will enter full screen
    shareSettingCmd_enterFullScreen,
    //When user to share screen will enter max window
    shareSettingCmd_enterMaxWindow,
    //When user user side to side mode
    shareSettingCmd_sideToSideMode,
    //Keep current size.
    shareSettingCmd_MaintainCurrentSize,
    //Scale to fit shared content to Zoom window
    shareSettingCmd_AutoFitWindowWhenViewShare,
}shareSettingCmd;

/**
 * @brief Enumerations of attendee view question type.
 */
typedef enum {
    //Attendee only view the answered question.
    ViewType_OnlyAnswered_Question = 0,
    //Attendee view the all question.
    ViewType_All_Question,
}AttendeeViewQuestionType;

/**
 * @brief Enumerations of question status.
 */
typedef enum {
    //The question state is init.
    QAQuestionState_Init = 0,
    //The question is sent.
    QAQuestionState_Sent,
    //The question is received.
    QAQuestionState_Received,
    //The question send fail.
    QAQuestionState_SendFail,
    //The question is sending.
    QAQuestionState_Sending,
    //The question state is unknow for init.
    QAQuestionState_Unknow,
}ZoomSDKQAQuestionState;

/**
 * @brief Enumerations of Q&A connect status.
 */
typedef enum {
    //The Q&A is connecting.
    QAConnectStatus_Connecting = 0,
    //The Q&A is connected.
    QAConnectStatus_Connected,
    //The Q&A is disonnected.
    QAConnectStatus_Disonnected,
    //The Q&A is disonnected conflict.
    QAConnectStatus_Disconnect_Conflict,
}ZoomSDKQAConnectStatus;

/**
 * @brief Enumerations of Audio action info.
 */
typedef enum {
    //The audio button action info is none.
    ZoomSDKAudioActionInfo_none = 0,
    //The audio button action info is need to join voip.
    ZoomSDKAudioActionInfo_needJoinVoip,
    //The audio button action info is need to mute/unmute audio.
    ZoomSDKAudioActionInfo_muteOrUnmenuAudio,
    //The audio button action info is no audio device connected.
    ZoomSDKAudioActionInfo_noAudioDeviceConnected,
    //The audio button action info is computer audio device error.
    ZoomSDKAudioActionInfo_computerAudioDeviceError,
}ZoomSDKAudioActionInfo;

/**
 * @brief Enumerations of breakout meeting status.
 */
typedef  enum{
    //the breakout meeting status is unknow.
    ZoomSDKBOUserStatus_Unknow = 0,
    //the breakout meeting status is unassigned.
    ZoomSDKBOUserStatus_UnAssigned,
    //the breakout meeting status is not join breakout meeting.
    ZoomSDKBOUserStatus_Assigned_Not_Join,
    //the breakout meeting status is in breakout meeting.
    ZoomSDKBOUserStatus_InBreakOutMeeting,
}ZoomSDKBOUserStatus;

/**
 * @brief Enumerations of limited FPS value.
 */
typedef enum {
    //The value is one.
    ZoomSDKFPSValue_One,
    //The value is two.
    ZoomSDKFPSValue_Two,
    //The value is four.
    ZoomSDKFPSValue_Four,
    //The value is six.
    ZoomSDKFPSValue_Six,
    //The value is eight.
    ZoomSDKFPSValue_Eight,
    //The value is ten.
    ZoomSDKFPSValue_Ten,
    //The value is fifteen.
    ZoomSDKFPSValue_Fifteen,
}ZoomSDKFPSValue;

/**
 * @brief Enumerations of attendee request for help result.
 */
typedef enum {
    //Host is handling other's request with the request dialog, no chance to show dialog for this request.
    ZoomSDKRequest4HelpResult_Busy,
    //Host click "later" button or close the request dialog directly.
    ZoomSDKRequest4HelpResult_Ignore,
    //Host already in your BO meeting.
    ZoomSDKRequest4HelpResult_HostAlreadyInBO,
    //For initialization (Host receive the help request and there is no other one currently requesting for help).
    ZoomSDKRequest4HelpResult_Idle,
}ZoomSDKRequest4HelpResult;


typedef enum
{
    ZoomSDKRawDataMemoryMode_Stack,
    ZoomSDKRawDataMemoryMode_Heap,
}ZoomSDKRawDataMemoryMode;

typedef enum
{
    ZoomSDKResolution_90P,
    ZoomSDKResolution_180P,
    ZoomSDKResolution_360P,
    ZoomSDKResolution_720P,
    ZoomSDKResolution_1080P,
    ZoomSDKResolution_NoUse = 100
}ZoomSDKResolution;

typedef enum
{
    ZoomSDKLOCAL_DEVICE_ROTATION_ACTION_UNKnown,
    ZoomSDKLOCAL_DEVICE_ROTATION_ACTION_0,
    ZoomSDKLOCAL_DEVICE_ROTATION_ACTION_CLOCK90,
    ZoomSDKLOCAL_DEVICE_ROTATION_ACTION_CLOCK180,
    ZoomSDKLOCAL_DEVICE_ROTATION_ACTION_ANTI_CLOCK90,
}ZoomSDKLocalVideoDeviceRotation;

typedef enum
{
    ZoomSDKRawDataType_Video = 1,
    ZoomSDKRawDataType_Share,
}ZoomSDKRawDataType;

/**
 * @brief Enumerations of the type for save screenshot file.
 */
typedef enum
{
    //The file type is PNG.
    ZoomSDKAnnotationSavedType_PNG,
    //The file type is PDF.
    ZoomSDKAnnotationSavedType_PDF
}ZoomSDKAnnotationSavedType;

/**
 * @brief Enumerations of the priviledge for attendee chat.
 */
typedef enum
{
    //Allow attendee to chat with everyone.[for webinar]
    ZoomSDKChatPriviledgeType_To_EveryOne,
    //Allow attendee to chat with all panelists only.[for webinar]
    ZoomSDKChatPriviledgeType_To_All_Panelist,
}ZoomSDKChatPriviledgeType;

/**
 * @brief Enumerations of the type for chat message.
 */
typedef enum
{
    //For initialize
    ZoomSDKChatMessageType_To_None,
    //Chat message is send to all in normal meeting ,also means to all panelist and attendees when webinar meeting.
    ZoomSDKChatMessageType_To_All,
    //Chat message is send to all panelists.
    ZoomSDKChatMessageType_To_All_Panelist,
    //Chat message is send to individual attendee and cc panelists.
    ZoomSDKChatMessageType_To_Individual_Panelist,
    //Chat message is send to individual user.
    ZoomSDKChatMessageType_To_Individual,
    //Chat message is send to waiting room user.
    ZoomSDKChatMessageType_To_WaitingRoomUsers,
}ZoomSDKChatMessageType;

typedef enum
{
    //For initialize
    ZoomSDKSuppressBackgroundNoiseLevel_None,
    ZoomSDKSuppressBackgroundNoiseLevel_Auto,
    ZoomSDKSuppressBackgroundNoiseLevel_Low,
    ZoomSDKSuppressBackgroundNoiseLevel_Medium,
    ZoomSDKSuppressBackgroundNoiseLevel_High,
}ZoomSDKSuppressBackgroundNoiseLevel;

/**
 * @brief Enumerations of the type for screen capture.
 */

typedef enum
{
    //Screen capture mode is automatically.
    ZoomSDKScreenCaptureMode_Auto,
    //Screen capture mode is legacy.
    ZoomSDKScreenCaptureMode_Legacy,
    //Screen capture mode is copy with window filter.
    ZoomSDKScreenCaptureMode_GPU_Copy_Filter,
    //Screen capture mode is advanced copy with window filter.
    ZoomSDKScreenCaptureMode_ADA_Copy_Filter,
    //Screen capture mode is advanced copy without window filter.
    ZoomSDKScreenCaptureMode_ADA_Copy_Without_Filter,
}ZoomSDKScreenCaptureMode;

/**
 * @brief Enumerations of the type for light adaption.
 */

typedef enum
{
    //Light adaption is none.
    ZoomSDKSettingVideoLightAdaptionModel_None,
    //Light adaption by automatically.
    ZoomSDKSettingVideoLightAdaptionModel_Auto,
    //Light adaption by manual.
    ZoomSDKSettingVideoLightAdaptionModel_Manual,
}ZoomSDKSettingVideoLightAdaptionModel;

typedef enum
{
    ZoomSDKSettingVBVideoError_None = 0,
    ZoomSDKSettingVBVideoError_UnknowFormat,
    ZoomSDKSettingVBVideoError_ResolutionBig,
    ZoomSDKSettingVBVideoError_ResolutionHigh720P,
    ZoomSDKSettingVBVideoError_ResolutionLow,
    ZoomSDKSettingVBVideoError_PlayError,
    ZoomSDKSettingVBVideoError_OpenError,
}ZoomSDKSettingVBVideoError;

typedef enum
{
    ZoomSDKVideoEffectType_None = 0,
    ZoomSDKVideoEffectType_Filter = 1,
    ZoomSDKVideoEffectType_Frame = 2,
    ZoomSDKVideoEffectType_Sticker = 4,
}ZoomSDKVideoEffectType;

typedef enum
{
    ZoomSDKUIAppearance_System,
    ZoomSDKUIAppearance_Light,
    ZoomSDKUIAppearance_Dark,
}ZoomSDKUIAppearance;

typedef enum
{
    ZoomSDKEmojiReactionType_Unknow = 0,
    ZoomSDKEmojiReactionType_Clap,
    ZoomSDKEmojiReactionType_Thumbsup,
    ZoomSDKEmojiReactionType_Heart,
    ZoomSDKEmojiReactionType_Joy,
    ZoomSDKEmojiReactionType_Openmouth,
    ZoomSDKEmojiReactionType_Tada,
}ZoomSDKEmojiReactionType;

typedef enum
{
    ZoomSDKEmojiReactionSkinTone_Unknow = 0,
    ZoomSDKEmojiReactionSkinTone_Default,
    ZoomSDKEmojiReactionSkinTone_Light,
    ZoomSDKEmojiReactionSkinTone_MediumLight,
    ZoomSDKEmojiReactionSkinTone_Medium,
    ZoomSDKEmojiReactionSkinTone_MediumDark,
    ZoomSDKEmojiReactionSkinTone_Dark,
}ZoomSDKEmojiReactionSkinTone;

/**
 * @brief Enumerations of the Echo Cancellation.
 */
typedef enum
{
    //The echo cancellation Level is automatically.
    ZoomSDKAudioEchoCancellationLevel_Auto = 0,
    //The echo cancellation Level is aggressive.
    ZoomSDKAudioEchoCancellationLevel_Aggressive,
}ZoomSDKAudioEchoCancellationLevel;

/**
 * @brief Enumerations of the share option for setting Page share screen item.
 */
typedef enum
{
    //Share individual Window .Only for set share application.
    ZoomSDKSettingShareScreenShareOption_IndividualWindow,
    //Share all window from a application. Only for set share application.
    ZoomSDKSettingShareScreenShareOption_AllWindowFromApplication,
    //Automatically share desktop(for meeting share or direct share).
    ZoomSDKSettingShareScreenShareOption_AutoShareDesktop,
    //show all option (for meeting share or direct share).
    ZoomSDKSettingShareScreenShareOption_AllOption,
}ZoomSDKSettingShareScreenShareOption;

typedef enum
{
    ZoomSDKSpotlightResult_Success = 0,
    ZoomSDKSpotlightResult_Fail_NotEnoughUsers,  // user counts less than 2
    ZoomSDKSpotlightResult_Fail_ToMuchSpotlightedUsers, // spotlighted user counts is more than 9
    ZoomSDKSpotlightResult_Fail_UserCannotBeSpotlighted, // user in view only mode or silent mode or active
    ZoomSDKSpotlightResult_Fail_UserWithoutVideo, // user doesn't turn on video
    ZoomSDKSpotlightResult_Fail_NoPrivilegeToSpotlight,  // current user has no privilege to spotlight
    ZoomSDKSpotlightResult_Fail_UserNotSpotlighted, //user is not spotlighted
    ZoomSDKSpotlightResult_Unknown = 100,
}ZoomSDKSpotlightResult;

typedef enum
{
    ZoomSDKPinResult_Success = 0,
    ZoomSDKPinResult_Fail_NotEnoughUsers, // user counts less than 2
    ZoomSDKPinResult_Fail_ToMuchPinnedUsers, // pinned user counts more than 9
    ZoomSDKPinResult_Fail_UserCannotBePinned, // user in view only mode or silent mode or active
    ZoomSDKPinResult_Fail_VideoModeDoNotSupport, // other reasons
    ZoomSDKPinResult_Fail_NoPrivilegeToPin,  // current user has no privilege to pin
    ZoomSDKPinResult_Fail_MeetingDoNotSupport, // webinar and in view only meeting
    ZoomSDKPinResult_Unknown = 100,
}ZoomSDKPinResult;

typedef enum
{
    ZoomSDKLoginFailReason_None = 0,
    //Email login disabled.
    ZoomSDKLoginFailReason_EmailLoginDisabled,
    //User not exist.
    ZoomSDKLoginFailReason_UserNotExist,
    //Password is wrong.
    ZoomSDKLoginFailReason_WrongPassword,
    //Account is locked.
    ZoomSDKLoginFailReason_AccountLocked,
    //SDK need update.
    ZoomSDKLoginFailReason_SDKNeedUpdate,
    //Attemps too many times.
    ZoomSDKLoginFailReason_TooManyFailedAttempts,
    // SMS code error.
    ZoomSDKLoginFailReason_SMSCodeError,
    //SMS code expired.
    ZoomSDKLoginFailReason_SMSCodeExpired,
    //Phone number format invalid.
    ZoomSDKLoginFailReason_PhoneNumberFormatInValid,
    //Login token invalid.
    ZoomSDKLoginFailReason_LoginTokenInvalid,
    //User disagree login disclaimer.
    ZoomSDKLoginFailReason_UserDisagreeLoginDisclaimer,
    //Login fail other reason.
    ZoomSDKLoginFailReason_Other_Issue = 100,
}ZoomSDKLoginFailReason;


typedef enum{
    //General page view more setting button.
    ZoomSDKSettingPageURL_General_ViewMoreSetting,
    //Audio page learn more url.
    ZoomSDKSettingPageURL_Audio_LearnMore,
    //VB page learn more url.
    ZoomSDKSettingPageURL_VB_LearnMore,
    //Share screen page learn more url.
    ZoomSDKSettingPageURL_ShareScreen_LearnMore,
} ZoomSDKSettingPageURL;

typedef enum{
    //The pointer is null.
    ZoomSDKBOControllerError_Null_Pointer = 0,
    //Can't start/stop BO when start/stop already.
    ZoomSDKBOControllerError_Wrong_Current_Status,
    //BO token is not ready.
    ZoomSDKBOControllerError_Token_Not_Ready,
    //Only host have the privilege to create/start/stop BO.
    ZoomSDKBOControllerError_No_Privilege,
    //BO list is upload.
    ZoomSDKBOControllerError_BO_List_Is_Uploading,
    //Failed to upload BO list to conference attribute.
    ZoomSDKBOControllerError_Upload_Fail,
    //No user assigned to breakout room.
    ZoomSDKBOControllerError_No_One_Has_Been_Assigned,
    ZoomSDKBOControllerError_Unknow = 100,
} ZoomSDKBOControllerError;

/**
 * @brief Enum for video render resolution.
 */
typedef enum{
    ZoomSDKVideoRenderResolution_None = 0, /// <For initiation
    ZoomSDKVideoRenderResolution_90p,
    ZoomSDKVideoRenderResolution_180p,
    ZoomSDKVideoRenderResolution_360p,
    ZoomSDKVideoRenderResolution_720p,
    ZoomSDKVideoRenderResolution_1080p,
} ZoomSDKVideoRenderResolution;

/**
 * @brief Enum for BO stop countdown.
 */
typedef enum{
    ZoomSDKBOStopCountDown_Not = 0,
    ZoomSDKBOStopCountDown_Seconds_10,
    ZoomSDKBOStopCountDown_Seconds_15,
    ZoomSDKBOStopCountDown_Seconds_30,
    ZoomSDKBOStopCountDown_Seconds_60,
    ZoomSDKBOStopCountDown_Seconds_120,
} ZoomSDKBOStopCountDown;

/**
 * @brief Enum for BO status.
 */
typedef enum{
    //BO status is invalid.
    ZoomSDKBOStatus_Invalid = 0,
    //BO edit & assign.
    ZoomSDKBOStatus_Edit = 1,
    //BO is started.
    ZoomSDKBOStatus_Started = 2,
    //Stopping BO.
    ZoomSDKBOStatus_Stopping = 3,
    //BO is ended.
    ZoomSDKBOStatus_Ended = 4,
} ZoomSDKBOStatus;

typedef enum{
    ZoomSDKVideoSubscribe_Fail_None = 0,
    ZoomSDKVideoSubscribe_Fail_ViewOnly,
    ZoomSDKVideoSubscribe_Fail_NotInMeeting,
    ZoomSDKVideoSubscribe_Fail_HasSubscribe1080POr720P,
    ZoomSDKVideoSubscribe_Fail_HasSubscribe720P,
    ZoomSDKVideoSubscribe_Fail_HasSubscribeTwo720P,
    ZoomSDKVideoSubscribe_Fail_HasSubscribeExceededLimit,
} ZoomSDKVideoSubscribeFailReason;
