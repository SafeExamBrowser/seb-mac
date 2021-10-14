//
//  ZMUIInterfaceBridge.h
//  ZCommonUI
//
//  Created by Justin Fang on 6/6/14.
//  Copyright (c) 2014 zoom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZMRemoteControlConfActionProtocol.h"
#import "ZMPRemoteControlPTResponseProtocol.h"
#import "ZMPRemoteControlPTNotifyProtocol.h"
#import "ZMPRemoteControlMTResponseProtocol.h"
#import "ZMPRemoteControlMTNotifyProtocol.h"
#import "ZMPRemoteControlMTZRWRequestProtocol.h"
#import "ZMPConfDataProtocol.h"
#import "ZMRemoteControlCommonActionProtocol.h"
#import "ZMPPTDataProtocol.h"

typedef enum {
    ZZHostCallStateCalling      = 0,
    ZZHostCallStateInProgress   = 1,
    ZZHostCallStateDisconnected = 2,
    ZZHostCallStateHoldOn       = 3,
    ZZHostCallStateHoldOff      = 4,
    ZZHostCallStateHookOnFail   = 5,
    ZZHostCallStateFlas         = 6
} ZZHostCallState;

@protocol ZPAudioExternalDeviceProtocol <NSObject>//ZOOM-4319
- (void)setDeviceMicMuted:(BOOL)isMute;
- (BOOL)isDeviceMicMuted;
- (BOOL)updateDefaultMicName:(NSString*)micName;
- (BOOL)isUsingExternalDevice;
- (void)syncMeetingAudioStatus2Device;
- (void)setDeviceCallState:(ZZHostCallState)stateData;
- (void)syncDeviceState;
@end

@protocol ZPMainWinowControllerProtocol <NSObject>//ZOOM-5960
- (void)presentToRoomStatusUpdate:(int)status;
- (void)onUserLogin;
@end


@interface ZMUIInterfaceBridge : NSObject 

@property(nonatomic, readwrite, weak) id<ZMRemoteControlConfActionProtocol>               zmpRCConfAction;
@property(nonatomic, readwrite, weak) id<ZMPRemoteControlPTResponseProtocol>              zmpRCPTResponse;
@property(nonatomic, readwrite, weak) id<ZMPRemoteControlPTNotifyProtocol>                zmpRCPTNotify;
@property(nonatomic, readwrite, weak) id<ZMPRemoteControlMTResponseProtocol>              zmpRCMTResponse;
@property(nonatomic, readwrite, weak) id<ZMPRemoteControlMTNotifyProtocol>                zmpRCMTNotify;
@property(nonatomic, readwrite, weak) id<ZMPRemoteControlMTZRWRequestProtocol>            zmpRCMTZRWRequest;
@property(nonatomic, readwrite, weak) id<ZMPConfDataProtocol>                             zmpMTData;
@property(nonatomic, readwrite, weak) id<ZMRemoteControlCommonActionProtocol>             zmRCCommonAction;
@property(nonatomic, readwrite, weak) id<ZMPPTDataProtocol>                               zmPTData;
@property(nonatomic, readwrite, weak) id<ZPAudioExternalDeviceProtocol>                   zmZZHost;//ZOOM-4319
@property(nonatomic, readwrite, weak) id<ZPMainWinowControllerProtocol>                   zmPMainWindowController;//ZOOM-5960

+ (ZMUIInterfaceBridge*)sharedBridge;

@end
