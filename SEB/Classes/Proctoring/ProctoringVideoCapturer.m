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


@implementation RTCAudioSession (ProctoringVideoCapturer)

+ (void)setupIsAudioEnabledHook
{
    [self swizzleMethod:@selector(useManualAudio)
             withMethod:@selector(newUseManualAudio)];
    [self swizzleMethod:@selector(isAudioEnabled)
             withMethod:@selector(newIsAudioEnabled)];
//    [self swizzleMethod:@selector(outputVolume)
//             withMethod:@selector(newOutputVolume)];
    [self swizzleMethod:@selector(inputAvailable)
             withMethod:@selector(newInputAvailable)];
}

- (BOOL)newUseManualAudio
{
    return YES;
}

- (BOOL)newIsAudioEnabled
{
    BOOL overrideIsAudioEnabled = YES; //[[[MyGlobals sharedMyGlobals] sebViewController] rtcAudioEnabled];
    return overrideIsAudioEnabled;
}

//- (float)newOutputVolume
//{
//    return 0.0;
//}

- (BOOL)newInputAvailable
{
    return YES;
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
    [self swizzleMethod:@selector(initWithFactory:source:trackId:)
             withMethod:@selector(newInitWithFactory:source:trackId:)];
}

- (NSArray<RTCAudioTrack *> *)newAudioTracks
{
    NSArray<RTCAudioTrack *> *audioTracks = [self newAudioTracks];
    if (audioTracks.count > 0) {
        RTCAudioTrack *remoteAudioTrack = audioTracks[0];
        DDLogDebug(@"Muting remote RTCAudioTrack: %@", remoteAudioTrack);
        [remoteAudioTrack setIsEnabled:NO];
    }
    return audioTracks;
}

- (NSArray<RTCVideoTrack *> *)newVideoTracks
{
    NSArray<RTCVideoTrack *> *videoTracks = [self newVideoTracks];
    if (videoTracks.count > 0) {
        RTCVideoTrack *remoteVideoTrack = videoTracks[0];
        BOOL localTrack = remoteVideoTrack.source != nil;
        NSString *trackId = remoteVideoTrack.trackId;
        DDLogDebug(@"%@RTCVideoTrack: Id %@", localTrack ? @"Local " : @"Remote ", trackId);
        
        [remoteVideoTrack setIsEnabled:localTrack];
    }
    return videoTracks;
}

- (void)newAddVideoTrack:(RTCVideoTrack *)videoTrack
{
    DDLogDebug(@"Adding RTCVideoTrack: %@", videoTrack);
    [self newAddVideoTrack:videoTrack];
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
