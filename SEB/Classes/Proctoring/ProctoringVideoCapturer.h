//
//  ProctoringVideoCapturer.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 21.05.20.
//

#import <Foundation/Foundation.h>
#import "RTCCameraVideoCapturer.h"
#import "RTCAudioSession.h"
#import "RTCMediaStreamTrack.h"
#import "RTCMediaStream.h"
#import "RTCAudioTrack.h"
#import "RTCVideoTrack.h"

NS_ASSUME_NONNULL_BEGIN

@class RTCAudioTrack;
@class RTCVideoTrack;


@interface RTCCameraVideoCapturer (ProctoringVideoCapturer)

+ (void)setupCaptureOutputHook;

- (void)newCaptureOutput:(AVCaptureOutput *)captureOutput
   didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
          fromConnection:(AVCaptureConnection *)connection;

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

@end


@interface RTCVideoTrack (ProctoringVideoCapturer)

+ (void)setupVideoTrackHook;

- (__kindof instancetype)initWithFactory:(RTCPeerConnectionFactory *)factory
                         source:(RTCVideoSource *)source
                        trackId:(NSString *)trackId;

- (instancetype)newInitWithFactory:(RTCPeerConnectionFactory *)factory
                            source:(RTCVideoSource *)source
                           trackId:(NSString *)trackId;

@end
NS_ASSUME_NONNULL_END
