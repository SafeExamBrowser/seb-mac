//
//  ProctoringVideoCapturer.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 21.05.20.
//

#import "ProctoringVideoCapturer.h"
#import "MethodSwizzling.h"


@implementation RTCCameraVideoCapturer (ProctoringVideoCapturer)

+ (void)setupCaptureOutputHook
{
    [self swizzleMethod:@selector(captureOutput:didOutputSampleBuffer:fromConnection:)
             withMethod:@selector(newCaptureOutput:didOutputSampleBuffer:fromConnection:)];
}

- (void)newCaptureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    [[[MyGlobals sharedMyGlobals] sebViewController] detectFace:sampleBuffer];
    [self newCaptureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
}

@end


@implementation RTCVideoSource (ProctoringVideoCapturer)

+ (void)setupCaptureVideoFrameHook
{
    [self swizzleMethod:@selector(capturer:didCaptureVideoFrame:)
             withMethod:@selector(newCapturer:didCaptureVideoFrame:)];
}

- (void)newCapturer:(RTCVideoCapturer *)capturer didCaptureVideoFrame:(RTCVideoFrame *)frame
{
    @synchronized(self) {
        RTCVideoFrame *modifiedFrame = [[[MyGlobals sharedMyGlobals] sebViewController] overlayFrame:frame];
        [self newCapturer:capturer didCaptureVideoFrame:modifiedFrame];
//        frame = [[[MyGlobals sharedMyGlobals] sebViewController] overlayFrame:frame];
//        [self newCapturer:capturer didCaptureVideoFrame:frame];
    }
}

@end


@implementation RTCAudioSession (ProctoringVideoCapturer)

+ (void)setupIsAudioEnabledHook
{
    [self swizzleMethod:@selector(useManualAudio)
             withMethod:@selector(newUseManualAudio)];
    [self swizzleMethod:@selector(isAudioEnabled)
             withMethod:@selector(newIsAudioEnabled)];
    [self swizzleMethod:@selector(inputAvailable)
             withMethod:@selector(newInputAvailable)];
}

- (BOOL)newUseManualAudio
{
    return NO;
}

- (BOOL)newIsAudioEnabled
{
    BOOL overrideIsAudioEnabled = YES;
    return overrideIsAudioEnabled;
}

- (BOOL)newInputAvailable
{
    return [[[MyGlobals sharedMyGlobals] sebViewController] rtcAudioInputEnabled];;
}

@end


@implementation RTCMediaStreamTrack (ProctoringVideoCapturer)

+ (void)setupIsTrackEnabledHook
{
    [self swizzleMethod:@selector(isEnabled)
             withMethod:@selector(newIsEnabled)];
    [self swizzleMethod:@selector(setIsEnabled:)
             withMethod:@selector(newSetIsEnabled:)];
}

- (BOOL)newIsEnabled
{
    BOOL isEnabled = [self newIsEnabled];
    return isEnabled;
}

- (void)newSetIsEnabled:(BOOL)isEnabled {
    [self newSetIsEnabled:isEnabled];
}

@end


@implementation RTCMediaStream (ProctoringVideoCapturer)

+ (void)setupAudioTracksHook
{
    [self swizzleMethod:@selector(audioTracks)
             withMethod:@selector(newAudioTracks)];
    [self swizzleMethod:@selector(videoTracks)
             withMethod:@selector(newVideoTracks)];
    [self swizzleMethod:@selector(addVideoTrack:)
             withMethod:@selector(newAddVideoTrack:)];
    [self swizzleMethod:@selector(removeVideoTrack:)
             withMethod:@selector(newRemoveVideoTrack:)];
}

- (NSArray<RTCAudioTrack *> *)newAudioTracks
{
    NSArray<RTCAudioTrack *> *audioTracks = [self newAudioTracks];
    if (audioTracks.count > 0) {
        RTCAudioTrack *remoteAudioTrack = audioTracks[0];
        BOOL rtcAudioReceivingEnabled = [[[MyGlobals sharedMyGlobals] sebViewController] rtcAudioReceivingEnabled];
        DDLogDebug(@"%@ remote RTCAudioTrack: %@", rtcAudioReceivingEnabled ? @"Unmuting" : @"Muting", remoteAudioTrack);
        [remoteAudioTrack setIsEnabled:rtcAudioReceivingEnabled];
    }
    return audioTracks;
}

- (NSArray<RTCVideoTrack *> *)newVideoTracks
{
    NSArray<RTCVideoTrack *> *videoTracks = [self newVideoTracks];
    if (videoTracks.count > 0) {
        RTCVideoTrack *videoTrack = videoTracks[0];
        BOOL isLocalVideoTrack = [[[MyGlobals sharedMyGlobals] sebViewController] rtcVideoTrackIsLocal:videoTrack];
        BOOL enableVideoTrack = isLocalVideoTrack ?
        [[[MyGlobals sharedMyGlobals] sebViewController] rtcVideoSendingEnabled] :
        [[[MyGlobals sharedMyGlobals] sebViewController] rtcVideoReceivingEnabled];

        NSString *trackId = videoTrack.trackId;
        DDLogDebug(@"%@ %@ RTCVideoTrack: Id %@", enableVideoTrack ? @"Enable" : @"Disable", isLocalVideoTrack ? @"local" : @"remote", trackId);
        [videoTrack setIsEnabled:enableVideoTrack];
    }
    return videoTracks;
}

- (void)newAddVideoTrack:(RTCVideoTrack *)videoTrack
{
    DDLogDebug(@"Adding local RTCVideoTrack: %@", videoTrack);
    [[[MyGlobals sharedMyGlobals] sebViewController].localRTCTracks addObject:videoTrack];
    [self newAddVideoTrack:videoTrack];
}

- (void)newRemoveVideoTrack:(RTCVideoTrack *)videoTrack
{
    DDLogDebug(@"Removing RTCVideoTrack: %@", videoTrack);
    [[[MyGlobals sharedMyGlobals] sebViewController].localRTCTracks removeObject:videoTrack];
    [self newRemoveVideoTrack:videoTrack];
}

@end


@implementation RTCVideoTrack (ProctoringVideoCapturer)


+ (void)setupVideoTrackHook
{
    [self swizzleMethod:@selector(initWithFactory:source:trackId:)
             withMethod:@selector(newInitWithFactory:source:trackId:)];
}

- (instancetype)newInitWithFactory:(RTCPeerConnectionFactory *)factory
 source:(RTCVideoSource *)source
trackId:(NSString *)trackId
{
    id newInstance = [self newInitWithFactory:factory source:source trackId:trackId];
    return newInstance;
}



@end
