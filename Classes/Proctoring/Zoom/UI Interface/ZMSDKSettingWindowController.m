//
//  ZMSDKSettingWindowController.m
//  ZoomSDKSample
//
//  Created by derain on 07/09/2018.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import "ZMSDKSettingWindowController.h"

@interface ZMSDKSettingWindowController ()
- (void)initPreViewFrame;
-(void)initSpeakerList;
-(void)initMicList;
-(void)initCameraList;
- (void)startTimer;
- (void)stopTimer;
- (void)onTimer:(NSTimer*)inTimer;

@end

@implementation ZMSDKSettingWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    [self initUI];
    [self initPreViewFrame];
    [self startTimer];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(void)cleanUp
{
    [self stopTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(_speakerDeviceHelper)
    {
        _speakerDeviceHelper.delegate = nil;
    }
    if(_microphoneDeviceHelper)
    {
        _microphoneDeviceHelper.delegate = nil;
    }
    if(_videoDeviceHelper)
    {
        _videoDeviceHelper.delegate = nil;
    }
    if(_audioSetting)
    {
        _audioSetting.delegate = nil;
    }
}
- (void)dealloc
{
    [self cleanUp];
}
- (id)init
{
    self = [super initWithWindowNibName:@"ZMSDKSettingWindowController" owner:self];
    if(self)
    {
        _audioSetting = [[[ZoomSDK sharedSDK] getSettingService] getAudioSetting];
        _videoSetting = [[[ZoomSDK sharedSDK] getSettingService] getVideoSetting];
        _speakerDeviceHelper = [_audioSetting getSettingSpeakerTestHelper];
        _microphoneDeviceHelper = [_audioSetting getSettingMicrophoneTestHelper];
        _videoDeviceHelper = [_videoSetting getSettingVideoTestHelper];
        _speakerDeviceHelper.delegate = self;
        _microphoneDeviceHelper.delegate =self;
        _videoDeviceHelper.delegate = self;
        _audioSetting.delegate = self;
        return self;
    }
    return nil;
}
-(void)awakeFromNib
{
    [self.window setReleasedWhenClosed:YES];
    [self updateAudioTab];
    [self updateVideoTab];
}
- (void)updateAudioTab
{
    ZoomSDKAudioSetting* audioSetting = [[[ZoomSDK sharedSDK] getSettingService] getAudioSetting];
    if(!audioSetting)
        return;
    [_joinAudioWhenJoinMeetingButton setState:[audioSetting isJoinAudoWhenJoinMeetingOn]];
    [_muteMicWhenJoinMeetingButton setState:[audioSetting isMuteMicWhenJoinMeetingOn]];
    [_enableStereoButton setState:[audioSetting isEnableStereoOn]];
    [_diablePromptJoinAudioDialogButton setHidden:![audioSetting isSupportPromptJoinAudioDialogWhenUse3rdPartyAudio]];
    [_diablePromptJoinAudioDialogButton setState:[audioSetting isPromptJoinAudioDialogWhenUse3rdPartyAudioDiable]];
    [_enableTemporarilyUnmuteButton setState:[audioSetting isTemporarilyUnmuteOn]];
    [_autoAdjustMicButton setState:[audioSetting isAutoAdjustMicOn]];
}
- (void)updateVideoTab
{
    ZoomSDKVideoSetting* videoSetting = [[[ZoomSDK sharedSDK] getSettingService] getVideoSetting];
    if(!videoSetting)
        return;
    [_enableHDButton setState:[videoSetting isCatchHDVideoOn]];
    [_enableMirrorEffectButton setState:[videoSetting isMirrorEffectEnabled]];
    [_touchUpAppearanceButton setState:[videoSetting isBeautyFaceEnabled]];
    [_displayParticipantNameButton setState:[videoSetting isdisplayUserNameOnVideoOn]];
    [_turnOffVideoButton setState:[videoSetting isMuteMyVideoWhenJoinMeetingOn]];
    [_hideNoVideoUserButton setState:[videoSetting isHideNoVideoUser]];
    [_spotlightMyVideoWhenISpeakerButton setState:[videoSetting isSpotlightMyVideoOn]];
    [_displayUpTo49ParticPerScreenButton setEnabled:[videoSetting isCanDisplayUpTo49InWallView]];
    [_displayUpTo49ParticPerScreenButton setState:[videoSetting isCanDisplayUpTo49InWallView] && [videoSetting isDisplayUpTo49InWallViewOn] ? NSOnState:NSOffState];
    
    BOOL isOriginalSize = [videoSetting isCaptureOriginalSize];
    if(isOriginalSize)
        [_16To9SizeMatrix selectCellWithTag:3];
    else
        [_16To9SizeMatrix selectCellWithTag:2];
}

- (void)relayoutWindowPosition
{
    [self.window setLevel:NSPopUpMenuWindowLevel];
    [self.window center];
    if([_settingTabView.selectedTabViewItem.identifier isEqualToString:@"video"])
    {
        SDKDeviceInfo *deviceInfo = [self getSelectedCamera];
        [_videoDeviceHelper StartPreview:[deviceInfo getDeviceID]];
    }
}
-(void)initUI
{
    [self initAudioUI];
    [self initVideoUI];
}
-(void)initAudioUI
{
    [self initMicList];
    [self initSpeakerList];
    ZoomSDKAudioSetting* audioSetting = [[[ZoomSDK sharedSDK] getSettingService] getAudioSetting];
    if(!audioSetting)
        return;
    [_joinAudioWhenJoinMeetingButton setState:[audioSetting isJoinAudoWhenJoinMeetingOn]];
    [_muteMicWhenJoinMeetingButton setState:[audioSetting isMuteMicWhenJoinMeetingOn]];
    [_enableStereoButton setState:[audioSetting isEnableStereoOn]];
    [_diablePromptJoinAudioDialogButton setHidden:![audioSetting isSupportPromptJoinAudioDialogWhenUse3rdPartyAudio]];
    [_diablePromptJoinAudioDialogButton setState:[audioSetting isPromptJoinAudioDialogWhenUse3rdPartyAudioDiable]];
    [_enableTemporarilyUnmuteButton setState:[audioSetting isTemporarilyUnmuteOn]];
    [_autoAdjustMicButton setState:[audioSetting isAutoAdjustMicOn]];
    
    [self updateMicVolumn];
    [self updateSpeakerVolumn];
}
-(void)initVideoUI
{
    [self initCameraList];
    
    ZoomSDKVideoSetting* videoSetting = [[[ZoomSDK sharedSDK] getSettingService] getVideoSetting];
    if(!videoSetting)
        return;
    [_enableHDButton setState:[videoSetting isCatchHDVideoOn]];
    [_enableMirrorEffectButton setState:[videoSetting isMirrorEffectEnabled]];
    [_touchUpAppearanceButton setState:[videoSetting isBeautyFaceEnabled]];
    [_displayParticipantNameButton setState:[videoSetting isdisplayUserNameOnVideoOn]];
    [_turnOffVideoButton setState:[videoSetting isMuteMyVideoWhenJoinMeetingOn]];
    [_hideNoVideoUserButton setState:[videoSetting isHideNoVideoUser]];
    [_spotlightMyVideoWhenISpeakerButton setState:[videoSetting isSpotlightMyVideoOn]];
    [_displayUpTo49ParticPerScreenButton setEnabled:[videoSetting isCanDisplayUpTo49InWallView]];
    [_displayUpTo49ParticPerScreenButton setState:[videoSetting isCanDisplayUpTo49InWallView] && [videoSetting isDisplayUpTo49InWallViewOn] ? NSOnState:NSOffState];
    
    BOOL isOriginalSize = [videoSetting isCaptureOriginalSize];
    if(isOriginalSize)
        [_16To9SizeMatrix selectCellWithTag:3];
    else
        [_16To9SizeMatrix selectCellWithTag:2];
}
- (void)initPreViewFrame
{
    ZoomSDKVideoSetting* videoSetting = [[[ZoomSDK sharedSDK] getSettingService] getVideoSetting];
    ZoomSDKSettingTestVideoDeviceHelper* videoDeviceHelper = [videoSetting getSettingVideoTestHelper];
    
    [videoDeviceHelper SetVideoParentView:_videoView VideoContainerRect:NSMakeRect(70, 10, 445, 250)];//(60, 20, 480, 240)
}
- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(nullable NSTabViewItem *)tabViewItem
{
    NSLog(@"willSelectTabViewItem tabViewItem.identifier = %@", tabViewItem.identifier);
    if([tabViewItem.identifier isEqualToString:@"audio"])
        [self updateAudioTab];
    else if([tabViewItem.identifier isEqualToString:@"video"])
        [self updateVideoTab];
}
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(nullable NSTabViewItem *)tabViewItem
{
    NSLog(@"didSelectTabViewItem tabViewItem.identifier = %@", tabViewItem.identifier);
    ZoomSDKVideoSetting* videoSetting = [[[ZoomSDK sharedSDK] getSettingService] getVideoSetting];
    ZoomSDKSettingTestVideoDeviceHelper* videoDeviceHelper = [videoSetting getSettingVideoTestHelper];
    if(!videoDeviceHelper)
        return;
    if([tabViewItem.identifier isEqualToString:@"video"])
    {
        SDKDeviceInfo *deviceInfo = [self getSelectedCamera];
        [videoDeviceHelper StartPreview:[deviceInfo getDeviceID]];
    }
    else
    {
        [videoDeviceHelper StopPreview];
    }
}
//audio
-(SDKDeviceInfo*)getSelectedMic
{
    ZoomSDKAudioSetting* audioSetting = [[[ZoomSDK sharedSDK] getSettingService] getAudioSetting];
    NSArray* micList = [audioSetting getAudioDeviceList:YES];
    if(!micList)
        return nil;
    NSUInteger micCount = micList.count;
    if(micCount <= 0)
        return nil;
    
    for(SDKDeviceInfo* info in micList)
    {
        if(!info)
            continue;
        if(info.isSelectedDevice)
           return info;
    }
    return nil;
}
-(SDKDeviceInfo*)getSelectedSpeaker
{
    ZoomSDKAudioSetting* audioSetting = [[[ZoomSDK sharedSDK] getSettingService] getAudioSetting];
    NSArray* speakerList = [audioSetting getAudioDeviceList:NO];
    if(!speakerList)
        return nil;
    
    NSUInteger count = speakerList.count;
    if(count <= 0)
        return nil;
    
    for(SDKDeviceInfo* info in speakerList)
    {
        if(!info)
            continue;
        if(info.isSelectedDevice)
            return info;
    }
    return nil;
}

-(void)initMicList
{
    [_micListPopupButton removeAllItems];
    
    NSArray* micList = [_audioSetting getAudioDeviceList:YES];
    if(!micList)
        return;
    NSUInteger micCount = micList.count;
    if(micCount <= 0)
        return;
    
    for(SDKDeviceInfo* info in micList)
    {
        if(!info)
            continue;
        NSString* deviceName = [info getDeviceName];
        if(deviceName)
            [_micListPopupButton addItemWithTitle:deviceName];
        if(info.isSelectedDevice)
           [_micListPopupButton selectItemWithTitle:[info getDeviceName]];
    }
}
-(void)initSpeakerList
{
    [_speakerPopupButton removeAllItems];
    
    NSArray* speakerList = [_audioSetting getAudioDeviceList:NO];
    if(!speakerList)
        return;
    NSUInteger count = speakerList.count;
    if(count <= 0)
        return;
    for(SDKDeviceInfo* info in speakerList)
    {
        if(!info)
            continue;
        NSString* deviceName = [info getDeviceName];
        if(deviceName)
            [_speakerPopupButton addItemWithTitle:deviceName];
        if(info.isSelectedDevice)
            [_speakerPopupButton selectItemWithTitle:[info getDeviceName]];
    }
}
-(IBAction)clickMicListMenu:(id)sender
{
    NSMenuItem* item = (NSMenuItem*)sender;
    NSString* deviceID = nil;
    
    NSArray* micList = [_audioSetting getAudioDeviceList:YES];
    if(!micList)
        return;
    NSUInteger count = micList.count;
    if(count <= 0)
        return;
    
    for(SDKDeviceInfo* info in micList)
    {
        if(!info)
            continue;
        if([[info getDeviceName] isEqualToString:item.title])
            deviceID = [info getDeviceID];
    }
    if(deviceID && item.title)
        [_audioSetting selectAudioDevice:YES DeviceID:deviceID DeviceName:item.title];
}
-(IBAction)clickSpaekerListMenu:(id)sender
{
    NSMenuItem* item = (NSMenuItem*)sender;
    NSString* deviceID = nil;
    
    NSArray* speakerList = [_audioSetting getAudioDeviceList:NO];
    if(!speakerList)
        return;
    NSUInteger count = speakerList.count;
    if(count <= 0)
        return;
    
    for(SDKDeviceInfo* info in speakerList)
    {
        if(!info)
            continue;
        if([[info getDeviceName] isEqualToString:item.title])
            deviceID = [info getDeviceID];
    }
    if(deviceID && item.title)
        [_audioSetting selectAudioDevice:NO DeviceID:deviceID DeviceName:item.title];
}
-(IBAction)clickStartTestSpeakerButton:(id)sender
{
    BOOL isSpeakerTesting = _speakerDeviceHelper.isSpeakerInTesting;
    SDKDeviceInfo* info = [self getSelectedSpeaker];
    NSString *deviceID = nil;
    if(info)
        deviceID = [info getDeviceID];
    NSLog(@"deviceID = %@", deviceID);
    if(!isSpeakerTesting && deviceID)
        [_speakerDeviceHelper SpeakerStartPlaying:deviceID];
}
-(IBAction)clickStopTestSpeakerButton:(id)sender
{
    BOOL isSpeakerTesting = _speakerDeviceHelper.isSpeakerInTesting;
    if(isSpeakerTesting)
        [_speakerDeviceHelper SpeakerStopPlaying];
}
-(IBAction)clickStartRecordMicButton:(id)sender
{
    ZoomSDKTestMicStatus micStatus = [_microphoneDeviceHelper getTestMicStatus];
    SDKDeviceInfo* info = [self getSelectedMic];
    NSString *deviceID = nil;
    if(info)
        deviceID = [info getDeviceID];
    if(testMic_Normal == micStatus && deviceID)
        [_microphoneDeviceHelper startRecordingMic:deviceID];
}
-(IBAction)clickStopRecordMicButton:(id)sender
{
    ZoomSDKTestMicStatus micStatus = [_microphoneDeviceHelper getTestMicStatus];
    if(testMic_Recording == micStatus)
        [_microphoneDeviceHelper stopRecrodingMic];
}
-(IBAction)clickPlayRecordedMicButton:(id)sender
{
    ZoomSDKTestMicStatus micStatus = [_microphoneDeviceHelper getTestMicStatus];
    if(testMic_RecrodingStoped == micStatus)
        [_microphoneDeviceHelper playRecordedMic];
}
-(IBAction)clickStopPlayRecordedMicButton:(id)sender
{
    ZoomSDKTestMicStatus micStatus = [_microphoneDeviceHelper getTestMicStatus];
    if(testMic_Playing == micStatus)
        [_microphoneDeviceHelper stopPlayRecordedMic];
}
-(IBAction)clickAutoAdjustMicButton:(id)sender
{
    BOOL isOn = _autoAdjustMicButton.state;
    [_audioSetting enableAutoAdjustMic:isOn];
}
-(IBAction)clickJoinAudioWhenJoinMeetingButton:(id)sender
{
    BOOL isOn = _joinAudioWhenJoinMeetingButton.state;
    [_audioSetting enableAutoJoinVoip:isOn];
}
-(IBAction)clickMuteMicWhenJoinMeetingButton:(id)sender
{
    BOOL isOn = _muteMicWhenJoinMeetingButton.state;
    [_audioSetting enableMuteMicJoinVoip:isOn];
}
-(IBAction)clickEnableStereoButton:(id)sender
{
    BOOL isOn = _enableStereoButton.state;
    [_audioSetting enableStero:isOn];
}

-(IBAction)clickDiablePromptJoinAudioDialogButton:(id)sender
{
    BOOL isOn = _diablePromptJoinAudioDialogButton.state;
    [_audioSetting disablePromptJoinAudioDialogWhenUse3rdPartyAudio:isOn];
}
-(IBAction)clickEnableTemporarilyUnmuteButton:(id)sender
{
    BOOL isOn = _enableTemporarilyUnmuteButton.state;
    [_audioSetting enablePushToTalk:isOn];
}
-(IBAction)clickMiceVolumeSliderButton:(id)sender
{
    float value = [_miceVolumeSlider floatValue];
    [_audioSetting setAudioDeviceVolume:YES Volume:value];
}
-(IBAction)clickSpeakerVolumeSliderButton:(id)sender
{
    float value = [_speakerVolumeSlider floatValue];
    [_audioSetting setAudioDeviceVolume:NO Volume:value];
}

//video
-(SDKDeviceInfo*)getSelectedCamera
{
    NSArray* cameraList = [_videoSetting getCameraList];
    NSUInteger count = cameraList.count;
    if(count <= 0)
        return nil;
    for(SDKDeviceInfo* info in cameraList)
    {
        if(!info)
            continue;
        if(info.isSelectedDevice)
            return info;
    }
    return nil;
}
-(void)initCameraList
{
    [_cameraListPopupButton removeAllItems];
    NSArray* cameraList = [_videoSetting getCameraList];
    NSUInteger count = cameraList.count;
    if(count <= 0)
        return;
    for(SDKDeviceInfo* info in cameraList)
    {
        if(!info)
            continue;
        NSString* deviceName = [info getDeviceName];
        if(deviceName)
            [_cameraListPopupButton addItemWithTitle:deviceName];
        if(info.isSelectedDevice)
            [_cameraListPopupButton selectItemWithTitle:[info getDeviceName]];
    }
}
-(IBAction)clickVideoSize16To9Matrix:(id)sender
{
    NSButtonCell* theCell = _16To9SizeMatrix.selectedCell;
    if(theCell.tag==2)//16To9
    {
        [_videoSetting onVideoCaptureOriginalSizeOr16To9:NO];
    }
    else if(theCell.tag==3)//original
    {
        [_videoSetting onVideoCaptureOriginalSizeOr16To9:YES];
    }
}
-(IBAction)clickEnableHDButton:(id)sender
{
    BOOL isOn = _enableHDButton.state;
    [_videoSetting enableCatchHDVideo:isOn];
}
-(IBAction)clickEnableMirrorEffectButton:(id)sender
{
    BOOL isOn = _enableMirrorEffectButton.state;
    [_videoSetting enableMirrorEffect:isOn];
}
-(IBAction)clickTouchUpAppearanceButton:(id)sender
{
    BOOL isOn = _touchUpAppearanceButton.state;
    [_videoSetting enableBeautyFace:isOn];
}
-(IBAction)clickDisplayParticipantNameButton:(id)sender
{
    BOOL isOn = _displayParticipantNameButton.state;
    [_videoSetting displayUserNameOnVideo:isOn];
}
-(IBAction)clickTurnOffVideoButton:(id)sender
{
    BOOL isOn = _turnOffVideoButton.state;
    [_videoSetting disableVideoJoinMeeting:isOn];
}
-(IBAction)clickHideNoVideoUserButton:(id)sender
{
    BOOL isOn = _hideNoVideoUserButton.state;
    [_videoSetting hideNoVideoUser:!isOn];
}
-(IBAction)clickSpotlightMyVideButton:(id)sender
{
    BOOL isOn = _spotlightMyVideoWhenISpeakerButton.state;
    [_videoSetting onSpotlightMyVideoWhenISpeaker:isOn];
}
-(IBAction)clickDisplayUpTo49ParticPerScreenButton:(id)sender
{
    BOOL isOn = _displayUpTo49ParticPerScreenButton.state;
    [_videoSetting onDisplayUpTo49InWallView:isOn];
}
-(IBAction)clickCameraListMenu:(id)sender
{
    NSMenuItem* item = (NSMenuItem*)sender;
    NSString* deviceID = nil;
    
    NSArray* cameraList = [_videoSetting getCameraList];
    NSUInteger count = cameraList.count;
    if(count <= 0)
        return;
    
    for(SDKDeviceInfo* info in cameraList)
    {
        if(!info)
            continue;
        if([[info getDeviceName] isEqualToString:item.title])
            deviceID = [info getDeviceID];
    }
    if(deviceID)
        [_videoSetting selectCamera:deviceID];
}
- (void)windowWillClose:(NSNotification *)notification
{
    [_videoDeviceHelper StopPreview];
    if(_speakerDeviceHelper.isSpeakerInTesting)
       [_speakerDeviceHelper SpeakerStopPlaying];
    
    if([_microphoneDeviceHelper getTestMicStatus] == testMic_Recording)
    {
       [_microphoneDeviceHelper stopRecrodingMic];
       [_microphoneDeviceHelper stopPlayRecordedMic];
    }
    else if([_microphoneDeviceHelper getTestMicStatus] == testMic_RecrodingStoped || [_microphoneDeviceHelper getTestMicStatus] == testMic_Playing)
    {
        [_microphoneDeviceHelper stopPlayRecordedMic];
    }
}
- (void)updateMicVolumn
{
    if ( ![self isWindowLoaded] )
        return;
    
    NSArray* deviceList = [_audioSetting getAudioDeviceList:YES];
    if(!deviceList || deviceList.count <= 0)
        return;
    int micVolume = [_audioSetting getAudioDeviceVolume:YES];
    [_miceVolumeSlider setNumberOfTickMarks:10];
    [_miceVolumeSlider setTickMarkPosition:NSTickMarkBelow];
    [_miceVolumeSlider setIntValue:micVolume];
}
- (void)updateSpeakerVolumn
{
    if ( ![self isWindowLoaded] )
        return;
    
    NSArray* deviceList = [_audioSetting getAudioDeviceList:NO];
    if(!deviceList || deviceList.count <= 0)
        return;
    int spaekerVolume = [_audioSetting getAudioDeviceVolume:NO];
    [_speakerVolumeSlider setNumberOfTickMarks:10];
    [_speakerVolumeSlider setTickMarkPosition:NSTickMarkBelow];
    [_speakerVolumeSlider setIntValue:spaekerVolume];
}


#pragma mark - timer
- (void)startTimer
{
    if(!_timer || ![_timer isValid])
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
}
- (void)stopTimer
{
    if(_timer && [_timer isValid])
    {
        [_timer invalidate];
        _timer = nil;
    }
}
- (void)onTimer:(NSTimer*)inTimer
{
    [self updateMicVolumn];
    [self updateSpeakerVolumn];
}

#pragma mark - delegate
- (void)onMicLevelChanged:(unsigned int)level
{
    [_micLevelIndicatorButton setIntValue:level];
}
- (void)onSpeakerLevelChanged:(unsigned int)level
{
    [_speakerLevelIndicatorButton setIntValue:level];
}
- (void)onMicDeviceStatusChanged:(ZoomSDKDeviceStatus)status
{
    switch (status) {
        case New_Device_Found:
        case Device_Error_Found:
        case No_Device:
        case Audio_No_Input:
        case Audio_Error_Be_Muted:
        case Device_List_Update:
        case Audio_Disconnect_As_Detected_Echo:
        {
            if([_microphoneDeviceHelper getTestMicStatus] == testMic_Recording)
            {
                [_microphoneDeviceHelper stopRecrodingMic];
                [_microphoneDeviceHelper stopPlayRecordedMic];
            }
            else if([_microphoneDeviceHelper getTestMicStatus] == testMic_RecrodingStoped || [_microphoneDeviceHelper getTestMicStatus] == testMic_Playing)
            {
                [_microphoneDeviceHelper stopPlayRecordedMic];
            }
            [self initMicList];
        }
            break;
        default:
            break;
    }
}
- (void)onSpeakerDeviceStatusChanged:(ZoomSDKDeviceStatus)status
{
    switch (status) {
        case New_Device_Found:
        case Device_Error_Found:
        case No_Device:
        case Audio_No_Input:
        case Audio_Error_Be_Muted:
        case Device_List_Update:
        case Audio_Disconnect_As_Detected_Echo:
        {
            if(_speakerDeviceHelper.isSpeakerInTesting)
                [_speakerDeviceHelper SpeakerStopPlaying];
            [self initSpeakerList];
        }
            break;
        default:
            break;
    }
}
- (void)onSelectedMicDeviceChanged
{
    if([_microphoneDeviceHelper getTestMicStatus] == testMic_Recording)
    {
        [_microphoneDeviceHelper stopRecrodingMic];
        [_microphoneDeviceHelper stopPlayRecordedMic];
    }
    else if([_microphoneDeviceHelper getTestMicStatus] == testMic_RecrodingStoped || [_microphoneDeviceHelper getTestMicStatus] == testMic_Playing)
    {
        [_microphoneDeviceHelper stopPlayRecordedMic];
    }
    [self initMicList];
}
- (void)onSelectedSpeakerDeviceChanged
{
    if(_speakerDeviceHelper.isSpeakerInTesting)
        [_speakerDeviceHelper SpeakerStopPlaying];
    [self initSpeakerList];
}
- (void)onCameraStatusChanged:(ZoomSDKDeviceStatus)status
{
    switch (status) {
        case New_Device_Found:
        case Device_Error_Found:
        case No_Device:
        case Device_List_Update:
        {
            ZoomSDKVideoSetting* videoSetting = [[[ZoomSDK sharedSDK] getSettingService] getVideoSetting];
            ZoomSDKSettingTestVideoDeviceHelper* videoDeviceHelper = [videoSetting getSettingVideoTestHelper];
            if(!videoDeviceHelper)
                return;
            
            [videoDeviceHelper StopPreview];
            [self initCameraList];
            if([_settingTabView.selectedTabViewItem.identifier isEqualToString:@"video"])
            {
                SDKDeviceInfo *deviceInfo = [self getSelectedCamera];
                [videoDeviceHelper StartPreview:[deviceInfo getDeviceID]];
            }
        }
            break;
        default:
            break;
    }
}
- (void)showWindow:(id)sender
{
    [self updateAudioTab];
    [self updateVideoTab];
    [self relayoutWindowPosition];
}
@end
