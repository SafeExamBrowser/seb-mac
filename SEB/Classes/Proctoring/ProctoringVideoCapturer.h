//
//  ProctoringVideoCapturer.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 21.05.20.
//

#import <Foundation/Foundation.h>
#import <WebRTC.h>

NS_ASSUME_NONNULL_BEGIN

@class RTCAudioTrack;
@class RTCVideoTrack;


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
