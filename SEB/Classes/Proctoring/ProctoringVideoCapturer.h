//
//  ProctoringVideoCapturer.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 21.05.20.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <Foundation/Foundation.h>
#import <WebRTC.h>

NS_ASSUME_NONNULL_BEGIN

@class RTCAudioTrack;
@class RTCVideoTrack;

@protocol ProctoringStreamController <NSObject>

@property (strong, atomic) NSMutableArray<RTCVideoTrack *> *localRTCTracks;

- (BOOL) rtcAudioInputEnabled;
- (BOOL) rtcAudioReceivingEnabled;
- (BOOL) rtcVideoSendingEnabled;
- (BOOL) rtcVideoReceivingEnabled;
- (BOOL) rtcVideoTrackIsLocal:(RTCVideoTrack *)videoTrack;

- (void) detectFace:(CMSampleBufferRef)sampleBuffer;
- (RTCVideoFrame *) overlayFrame:(RTCVideoFrame *)frame;

@end


@interface RTCCameraVideoCapturer (ProctoringVideoCapturer)

+ (void)setupCaptureOutputHook;

- (void)newCaptureOutput:(AVCaptureOutput *)captureOutput
   didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
          fromConnection:(AVCaptureConnection *)connection;

@end


@interface RTCVideoSource (ProctoringVideoCapturer)

+ (void)setupCaptureVideoFrameHook;

- (void)newCapturer:(RTCVideoCapturer *)capturer didCaptureVideoFrame:(RTCVideoFrame *)frame;

@end


@interface RTCAudioSession (ProctoringVideoCapturer)

+ (void)setupIsAudioEnabledHook;

- (BOOL)newUseManualAudio;
- (BOOL)newIsAudioEnabled;
//- (float)newOutputVolume;
- (BOOL)newInputAvailable;

@end


@interface RTCMediaStreamTrack (ProctoringVideoCapturer)

+ (void)setupIsTrackEnabledHook;

- (BOOL)newIsEnabled;

- (void)newSetIsEnabled:(BOOL)isEnabled;

@end


@interface RTCMediaStream (ProctoringVideoCapturer)

+ (void)setupAudioTracksHook;

- (NSArray<RTCAudioTrack *> *)newAudioTracks;

- (NSArray<RTCVideoTrack *> *)newVideoTracks;

- (void)newAddVideoTrack:(RTCVideoTrack *)videoTrack;

- (void)newRemoveVideoTrack:(RTCVideoTrack *)videoTrack;

@end


@interface RTCVideoTrack (ProctoringVideoCapturer)

+ (void)setupVideoTrackHook;

- (instancetype)initWithFactory:(RTCPeerConnectionFactory *)factory
                         source:(RTCVideoSource *)source
                        trackId:(NSString *)trackId;

- (instancetype)newInitWithFactory:(RTCPeerConnectionFactory *)factory
                            source:(RTCVideoSource *)source
                           trackId:(NSString *)trackId;

@end
NS_ASSUME_NONNULL_END
