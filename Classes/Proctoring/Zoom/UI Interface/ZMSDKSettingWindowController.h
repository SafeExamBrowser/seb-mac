//
//  ZMSDKSettingWindowController.h
//  ZoomSDKSample
//
//  Created by derain on 07/09/2018.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ZoomSDK/ZoomSDK.h>

@interface ZMSDKSettingWindowController : NSWindowController<NSTabViewDelegate, ZoomSDKSettingTestAudioDelegate, ZoomSDKSettingVideoDelegate, ZoomSDKSettingAudioDeviceDelegate>
{
    IBOutlet NSTabView*          _settingTabView;
    IBOutlet NSTabViewItem*      _settingAudioTabItem;
    IBOutlet NSTabViewItem*      _settingVideoTabItem;
    
    //setting audio
    IBOutlet NSView*             _audioView;
    IBOutlet NSButton*           _startTestSpeakerButton;
    IBOutlet NSButton*           _stopTestSpeakerButton;
    
    IBOutlet NSButton*           _startRecordMicButton;
    IBOutlet NSButton*           _stopRecordMicButton;
    IBOutlet NSButton*           _playRecordedMicButton;
    IBOutlet NSButton*           _stopPlayRecordedMicButton;
    IBOutlet NSButton*           _autoAdjustMicButton;
    
    IBOutlet NSPopUpButton*      _micListPopupButton;
    IBOutlet NSPopUpButton*      _speakerPopupButton;
    IBOutlet NSLevelIndicator*   _micLevelIndicatorButton;
    IBOutlet NSLevelIndicator*   _speakerLevelIndicatorButton;
    
    IBOutlet NSButton*           _joinAudioWhenJoinMeetingButton;
    IBOutlet NSButton*           _muteMicWhenJoinMeetingButton;
    IBOutlet NSButton*           _enableStereoButton;
    IBOutlet NSButton*           _diablePromptJoinAudioDialogButton;
    IBOutlet NSButton*           _enableTemporarilyUnmuteButton;
    
    IBOutlet NSSlider*           _miceVolumeSlider;
    IBOutlet NSSlider*           _speakerVolumeSlider;

    
    //setting video
    IBOutlet NSView*             _videoView;
    IBOutlet NSPopUpButton*      _cameraListPopupButton;
    IBOutlet NSButton*           _enableHDButton;
    IBOutlet NSButton*           _enableMirrorEffectButton;
    IBOutlet NSButton*           _touchUpAppearanceButton;
    IBOutlet NSButton*           _displayParticipantNameButton;
    IBOutlet NSButton*           _turnOffVideoButton;
    IBOutlet NSButton*           _hideNoVideoUserButton;
    IBOutlet NSButton*           _spotlightMyVideoWhenISpeakerButton;
    IBOutlet NSButton*           _displayUpTo49ParticPerScreenButton;
    IBOutlet NSMatrix*           _16To9SizeMatrix;
    
    ZoomSDKAudioSetting*         _audioSetting;
    ZoomSDKVideoSetting*         _videoSetting;
    ZoomSDKSettingTestSpeakerDeviceHelper* _speakerDeviceHelper;
    ZoomSDKSettingTestMicrophoneDeviceHelper* _microphoneDeviceHelper;
    ZoomSDKSettingTestVideoDeviceHelper* _videoDeviceHelper;
    NSTimer*                    _timer;
}

//audio
-(IBAction)clickMicListMenu:(id)sender;
-(IBAction)clickSpaekerListMenu:(id)sender;
-(IBAction)clickStartTestSpeakerButton:(id)sender;
-(IBAction)clickStopTestSpeakerButton:(id)sender;
-(IBAction)clickStartRecordMicButton:(id)sender;
-(IBAction)clickStopRecordMicButton:(id)sender;
-(IBAction)clickPlayRecordedMicButton:(id)sender;
-(IBAction)clickStopPlayRecordedMicButton:(id)sender;
-(IBAction)clickAutoAdjustMicButton:(id)sender;
-(IBAction)clickJoinAudioWhenJoinMeetingButton:(id)sender;
-(IBAction)clickMuteMicWhenJoinMeetingButton:(id)sender;
-(IBAction)clickEnableStereoButton:(id)sender;
-(IBAction)clickDiablePromptJoinAudioDialogButton:(id)sender;
-(IBAction)clickEnableTemporarilyUnmuteButton:(id)sender;
-(IBAction)clickMiceVolumeSliderButton:(id)sender;
-(IBAction)clickSpeakerVolumeSliderButton:(id)sender;


//video
-(IBAction)clickVideoSize16To9Matrix:(id)sender;
-(IBAction)clickEnableHDButton:(id)sender;
-(IBAction)clickEnableMirrorEffectButton:(id)sender;
-(IBAction)clickTouchUpAppearanceButton:(id)sender;
-(IBAction)clickDisplayParticipantNameButton:(id)sender;
-(IBAction)clickTurnOffVideoButton:(id)sender;
-(IBAction)clickHideNoVideoUserButton:(id)sender;
-(IBAction)clickSpotlightMyVideButton:(id)sender;
-(IBAction)clickDisplayUpTo49ParticPerScreenButton:(id)sender;
-(IBAction)clickCameraListMenu:(id)sender;


- (void)relayoutWindowPosition;
- (void)showWindow:(id)sender;
@end
