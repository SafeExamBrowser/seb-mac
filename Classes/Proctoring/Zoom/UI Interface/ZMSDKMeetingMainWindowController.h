//
//  ZMSDKMeetingMainWindowController.h
//  ZoomSDKSample
//
//  Created by derain on 2018/12/3.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ZoomSDK/ZoomSDK.h>

@class ZMSDKMainWindowController;
@class ZMSDKTrackingButton;
@class ZMSDKHCPanelistsView;
@class ZMSDKThumbnailView;

enum MeetiongToolbarButtonTags
{
    BUTTON_TAG_OFFSET = 499,
    BUTTON_TAG_AUDIO,
    BUTTON_TAG_VIDEO,
    BUTTON_TAG_SHARE,
    BUTTON_TAG_PARTICIPANT,
    BUTTON_TAG_STOP_SHARE,
    BUTTON_TAG_ThUMBNAIL_VIEW,
    BUTTON_TAG_LEAVE_MEETING,
    BUTTON_TAG_CHAT
};

typedef enum
{
    Audio_Status_No = 0,
    Audio_Status_Muted,
    Audio_Status_UnMuted,
}SelfAudioStatus;


@interface ZMSDKMeetingMainWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
    NSButton*              _manegePanelistButton;
    NSButton*              _manegeShareButton;
    
    ZMSDKHCPanelistsView*  _panelistUserView;
    ZMSDKThumbnailView*    _thumbnailView;
}
@property(nonatomic, strong, readwrite)ZoomSDKActiveVideoElement* activeUserVideo;
@property(nonatomic, strong, readwrite)ZoomSDKPreViewVideoElement* preViewVideoItem;
@property(nonatomic, strong, readwrite)NSWindow* meetingMainWindow;
@property(nonatomic, assign, readwrite)SelfAudioStatus audioStatus;
@property(nonatomic, strong, readwrite)ZoomSDKUserInfo* mySelfUserInfo;

- (void)showSelf;
- (void)relayoutWindowPosition;
- (void)updateUI;

- (void)onUserJoin:(unsigned int)userID;
- (void)onUserleft:(unsigned int)userID;
- (void)onUserVideoStatusChange:(ZoomSDKVideoStatus)videoStatus UserID:(unsigned int)userID;
- (void)onUserAudioStatusChange:(NSArray*)userAudioStatusArray;
- (void)resetInfo;
- (void)updateInMeetingUI;
- (void)onSelfShareStart;
- (void)onSelfShareStop;
- (void)updateUIInWaitingRoom;
- (void)cleanUp;

- (void)showJoinMeetingAlert:(ZoomSDKJoinMeetingHelper *)joinMeetingHelper;
- (void)showWebinarRegisterAlert:(ZoomSDKWebinarRegisterHelper *)webinarRegisterHelper;
- (void)onChatMessageNotification:(ZoomSDKChatInfo*)chatInfo;
@end

