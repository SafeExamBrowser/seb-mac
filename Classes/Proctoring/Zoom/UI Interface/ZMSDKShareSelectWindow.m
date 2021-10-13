//
//  ZMSDKShareSelectWindow.m
//  ZoomSDKSample
//
//  Created by derain on 19/12/2018.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import "ZMSDKShareSelectWindow.h"
#import "ZoomSDKWindowController.h"
#import "ShareContentView.h"
#import "ZMSDKMeetingMainWindowController.h"
#import "ZMSDKCommonHelper.h"
@interface ZMSDKShareSelectWindow ()
{
    ZoomSDKASController* asController;
    ZoomSDKWindowController* _shareCameraWindowCtrl;
    ZoomSDKWindowController* _shareContentWindowCtrl;
    ZMSDKMeetingMainWindowController* _meetingMainWindowController;
    NSMutableArray*          _screenArray;
}
@property (nonatomic, readwrite, strong)ZoomSDKShareElement* shareElement;
@end

@implementation ZMSDKShareSelectWindow

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
-(void)awakeFromNib
{
    [self initUI];
}
- (void)uninitNotification
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

- (id)init
{
    self = [super initWithWindowNibName:@"ZMSDKShareSelectWindow" owner:self];
    if(self)
    {
        [self initUI];
        _screenArray = [[NSMutableArray alloc] initWithCapacity:0];
        return self;
    }
    return nil;
}
- (void)cleanUp
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    if(meetingService)
    {
        asController = [meetingService getASController];
        asController.delegate = nil;
    }
    
    if (_shareElement)
    {
        NSView* shareView = [_shareElement shareView];
        [shareView removeFromSuperview];
        ZoomSDKShareContainer* shareContainer = [[[[ZoomSDK sharedSDK] getMeetingService] getASController] getShareContainer];
        [shareContainer cleanShareElement:_shareElement];
        [_shareContentWindowCtrl.window orderOut:nil];
        _shareElement = nil;
    }
    
    if (_shareCameraWindowCtrl)
    {
        _shareCameraWindowCtrl = nil;
    }
    if (_shareContentWindowCtrl)
    {
        _shareContentWindowCtrl = nil;
    }
    if(_screenArray)
    {
        [_screenArray removeAllObjects];
        _screenArray = nil;
    }
    [self uninitNotification];
}
- (void)dealloc
{
    [self cleanUp];
}
- (void)initUI
{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    if(meetingService)
    {
        asController = [meetingService getASController];
        asController.delegate = self;
    }
}
- (IBAction)onShareDesktopButtonClick:(id)sender
{
    if(!asController)
        return;
    if(![self getScreenDisplayArray])
        return;
    if([self getScreenDisplayArray].count > 0)
        [asController startMonitorShare:[(NSNumber*)[_screenArray objectAtIndex:0] intValue]];
}
- (IBAction)onShareWhiteboradButtonClick:(id)sender
{
    if(!asController)
        return;
    [asController startWhiteBoardShare];
}
- (IBAction)onShareFrameButtonClick:(id)sender
{
    if(!asController)
        return;
    [asController startFrameShare];
}
- (IBAction)onShareSoundButtonClick:(id)sender
{
    if(!asController)
        return;
    [asController startAudioShare];
}
- (IBAction)onShareCameraButtonClick:(id)sender
{
    if(!asController)
        return;
    
    ZoomSDKVideoSetting* _videoSetting = [[[ZoomSDK sharedSDK] getSettingService] getVideoSetting];
    NSArray* cameraList = [_videoSetting getCameraList];
    NSUInteger count = cameraList.count;
    if(count <= 0)
        return;
    SDKDeviceInfo* selectedDevice = nil;
    for(SDKDeviceInfo* info in cameraList)
    {
        if(!info)
            continue;
        if(info.isSelectedDevice)
            selectedDevice = info;
    }
    /****for share customized camera window begin****/
    _shareCameraWindowCtrl = [[ZoomSDKWindowController alloc] init];
    [_shareCameraWindowCtrl.window setFrame:NSMakeRect(300, 300, 800, 720) display:YES];
    [_shareCameraWindowCtrl.window setTitle:@"Share Camera"];
    [self.window orderOut:nil];
    /****for share customized camera window end****/
    
    [_shareCameraWindowCtrl showWindow:nil];
    [asController startShareCamera:[selectedDevice getDeviceID] displayWindow:_shareCameraWindowCtrl.window];
}
- (ZoomSDKError)stopShare
{
    if(!asController)
        return ZoomSDKError_ServiceFailed;
    ZoomSDKError ret = [asController stopShare];
    if(_shareCameraWindowCtrl)
        [_shareCameraWindowCtrl.window close];
    return ret;
}
-(NSMutableArray*)getScreenDisplayArray
{
    if(!_screenArray)
        _screenArray = [[NSMutableArray alloc] init];
    else
    {
        if(_screenArray.count > 0)
            [_screenArray removeAllObjects];
    }
    NSArray* allScreens = [NSScreen screens];
    if(!allScreens || allScreens.count<=0)
        return nil;
    for (int i = 0; i< allScreens.count; i++ ) {
        NSScreen* theScreen = [allScreens objectAtIndex:i];
        NSDictionary *screenDescription = [theScreen deviceDescription];
        NSNumber* screenIDNumber = [screenDescription objectForKey:@"NSScreenNumber"];
        [_screenArray addObject:screenIDNumber];
    }
    return _screenArray;
}



// #pragma ZoomSDKASControllerDelegate
- (void)onSharingStatus:(ZoomSDKShareStatus)status User:(unsigned int)userID
{
    if (status == ZoomSDKShareStatus_SelfBegin && [ZMSDKCommonHelper sharedInstance].isUseCutomizeUI) {
        NSString *chatPrompt = [[[[ZoomSDK sharedSDK]getMeetingService]getMeetingActionController] getChatLegalNoticesPrompt]?:@"";
        NSString *chatExplain = [[[[ZoomSDK sharedSDK]getMeetingService]getMeetingActionController] getChatLegalNoticesExplained]?:@"";
        NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"chat\nPrompt:%@\nexplain:%@",chatPrompt,chatExplain] defaultButton:@"ok" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@""];
        [alert beginSheetModalForWindow:_meetingMainWindowController.window completionHandler:nil];
    }
    
    ZoomSDKShareContainer* container = [[[[ZoomSDK sharedSDK] getMeetingService] getASController] getShareContainer];
    NSString* info = @"";
    switch (status) {
        case ZoomSDKShareStatus_SelfBegin:
        {
            info = @"I start share myself";
            if(_meetingMainWindowController)
               [_meetingMainWindowController onSelfShareStart];
        }
            break;
        case ZoomSDKShareStatus_SelfEnd:
        {
            info = @"I end share myself";
            if(_meetingMainWindowController)
                [_meetingMainWindowController onSelfShareStop];
        }
            break;
        case ZoomSDKShareStatus_OtherBegin:
        {
            //this will show waiting share view tip first
            info = [NSString stringWithFormat:@"%d start his share now", userID];
            if(!_shareContentWindowCtrl)
            {
                _shareContentWindowCtrl = [[ZoomSDKWindowController alloc] init];
                [_shareContentWindowCtrl.window setTitle:@"Share Window"];
            }
            NSRect contentRect = [_shareContentWindowCtrl.window contentRectForFrameRect:NSMakeRect(0, 0, 1100, 700)];
            NSLog(@"Demo share window content frame:%@", NSStringFromRect(contentRect));
            [_shareContentWindowCtrl.window makeKeyAndOrderFront:nil];
            ZoomSDKShareElement* tempShareElement = [[ZoomSDKShareElement alloc] initWithFrame:contentRect];
            [container createShareElement:&tempShareElement];
            self.shareElement = tempShareElement;
            _shareElement.userId = userID;
            _shareElement.viewMode = ViewShareMode_LetterBox;
            [_shareElement ShowShareRender:YES];
            NSView* shareView = [_shareElement shareView];
            ShareContentView* contentView = [[ShareContentView alloc] initWithFrame:contentRect];
            _shareContentWindowCtrl.window.contentView = contentView;
            contentView.shareView = shareView;
            NSLog(@"Demo share view frame:%@", NSStringFromRect([shareView frame]));
            contentView.userid = userID;
            [contentView addSubview:shareView];
            [_shareContentWindowCtrl showWindow:nil];
        }
            break;
        case ZoomSDKShareStatus_OtherEnd:
        {
            info = [NSString stringWithFormat:@"%d end his share now", userID];
            if(_shareElement.userId == userID)
            {
                [_shareElement ShowShareRender:NO];
                NSView* shareView = [_shareElement shareView];
                [shareView removeFromSuperview];
                [container cleanShareElement:_shareElement];
                [_shareContentWindowCtrl.window orderOut:nil];
                _shareElement = nil;
                [_shareContentWindowCtrl.window orderOut:nil];
            }
        }
            break;
        case ZoomSDKShareStatus_ViewOther:
        {
            //this will make waiting share view tip disappear and run into view share
            info = [NSString stringWithFormat:@"now u can view %d's share", userID];
            [_shareElement ShowShareRender:YES];
        }
            break;
        case ZoomSDKShareStatus_Pause:
            info = [NSString stringWithFormat:@"%d pause his share now", userID];
            break;
        case ZoomSDKShareStatus_Resume:
            info = [NSString stringWithFormat:@"%d resume his share now", userID];
            break;
        case ZoomSDKShareStatus_None:
            break;
        case ZoomSDKShareStatus_SelfStartAudioShare:
        {
            info = @"I start share audio";
            if(_meetingMainWindowController)
                [_meetingMainWindowController onSelfShareStart];
        }
            break;
        case ZoomSDKShareStatus_SelfStopAudioShare:
        {
            info = @"I stop share audio";
            if(_meetingMainWindowController)
                [_meetingMainWindowController onSelfShareStop];
        }
            break;
        default:
            break;
    }
}

-(void)onShareContentChanged:(ZoomSDKShareInfo *)shareInfo
{
    ZoomSDKShareContentType type = [shareInfo getShareType];
    NSString* info = nil;
    if (ZoomSDKShareContentType_DS == type)
    {
        CGDirectDisplayID displayID = 0;
        if (ZoomSDKError_Success == [shareInfo getDisplayID:&displayID])
        {
            info = [NSString stringWithFormat:@"Share content Change to Destop, display ID:%d", displayID];
        }
    }
    else if(ZoomSDKShareContentType_AS == type || ZoomSDKShareContentType_WB == type)
    {
        CGWindowID windowID = 0;
        if (ZoomSDKError_Success == [shareInfo getWindowID:&windowID])
        {
            info = [NSString stringWithFormat:@"Share content change to Application or Whiteboard, window ID:%d", windowID];
        }
    }
}
- (void)setMeetingMainWindowController:(ZMSDKMeetingMainWindowController*)meetingMainWindowController
{
    _meetingMainWindowController = meetingMainWindowController;
}


@end
