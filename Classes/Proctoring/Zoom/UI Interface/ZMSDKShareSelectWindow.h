//
//  ZMSDKShareSelectWindow.h
//  ZoomSDKSample
//
//  Created by derain on 19/12/2018.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ZoomSDK/ZoomSDK.h>

@class ZMSDKMeetingMainWindowController;

@interface ZMSDKShareSelectWindow : NSWindowController <ZoomSDKASControllerDelegate>
{
    IBOutlet NSButton* _shareDesktopButton;
    IBOutlet NSButton* _shareWhiteboradButton;
    IBOutlet NSButton* _shareFrameButton;
    IBOutlet NSButton* _shareSoundButton;
    IBOutlet NSButton* _shareCameraButton;
}
- (IBAction)onShareDesktopButtonClick:(id)sender;
- (IBAction)onShareWhiteboradButtonClick:(id)sender;
- (IBAction)onShareFrameButtonClick:(id)sender;
- (IBAction)onShareSoundButtonClick:(id)sender;
- (IBAction)onShareCameraButtonClick:(id)sender;
- (ZoomSDKError)stopShare;
- (void)setMeetingMainWindowController:(ZMSDKMeetingMainWindowController*)meetingMainWindowController;
@end
